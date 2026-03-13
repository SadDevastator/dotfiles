#!/usr/bin/env zsh
set -e

zcompare() {
    if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc) ]]; then
        zcompile "$1" 2>/dev/null || true
    fi
}

typeset -A _seen
files=()

add_file() {
    local f="$1"
    [[ -n "$f" && -e "$f" && -s "$f" ]] || return 0
    if [[ -z "${_seen[$f]}" ]]; then
        files+=("$f")
        _seen[$f]=1
    fi
}

# Prevent concurrent runs: use flock if available, otherwise a pidfile lock.
LOCKFILE="${LOCKFILE:-${XDG_RUNTIME_DIR:-$HOME/.cache}/precompile_zsh.lock}"
mkdir -p "$(dirname "$LOCKFILE")" 2>/dev/null || true
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCKFILE"
    if ! flock -n 9; then
        echo "Another precompile run is in progress; exiting." >&2
        exit 0
    fi
else
    if [[ -f "$LOCKFILE" ]]; then
        pid=$(cat "$LOCKFILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            echo "Another precompile run (PID $pid) is in progress; exiting." >&2
            exit 0
        fi
    fi
    printf '%s' "$$" >"$LOCKFILE"
    trap 'rm -f "$LOCKFILE"' EXIT
fi

# Pre-populate `files` with predefined user files (no loop)
add_file "$HOME/.zshrc" || true
add_file "$HOME/.zlogin" || true
add_file "$HOME/.zshenv" || true
add_file "$HOME/.zprofile" || true
add_file "$HOME/.zlogout" || true
add_file "$HOME/.p10k.zsh" || true
add_file "$HOME/.zcompdump" || true
add_file "$0:A" || true

# Parallel discovery: each worker writes NUL-separated results to its own temp file.
tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t precompile)
workers=()
worker_files=()

# Allow skipping expensive system scans (set SKIP_SYSTEM=1 to skip)
SKIP_SYSTEM="${SKIP_SYSTEM:-0}"

# worker: expand ~/.zsh/*.zsh
wf="$tmpdir/w_zsh_glob"
worker_files+=("$wf")
( for f in "$HOME/.zsh"/*.zsh; do [[ -e "$f" ]] && printf '%s\0' "$f"; done >"$wf" ) &
workers+=("$!")

# worker: oh-my-zsh plugins
wf="$tmpdir/w_plugins"
worker_files+=("$wf")
( for _f in "${HOME}/.zsh/oh-my-zsh/plugins"/*/*.zsh; do [[ -e "${_f}" ]] && printf '%s\0' "${_f}"; done >"$wf" ) &
workers+=("$!")

# worker: custom plugins
wf="$tmpdir/w_custom_plugins"
worker_files+=("$wf")
( for _f in "${HOME}/.zsh/oh-my-zsh/custom/plugins"/*/*.zsh; do [[ -e "${_f}" ]] && printf '%s\0' "${_f}"; done >"$wf" ) &
workers+=("$!")

# worker: themes
wf="$tmpdir/w_themes"
worker_files+=("$wf")
( for _f in "${HOME}/.zsh/oh-my-zsh/themes"/*.zsh-theme; do [[ -e "${_f}" ]] && printf '%s\0' "${_f}"; done >"$wf" ) &
workers+=("$!")

if [[ "$SKIP_SYSTEM" != "1" ]]; then
    # system files (small list)
    wf="$tmpdir/w_systems"
    worker_files+=("$wf")
    ( printf '%s\0' /opt/anaconda/etc/profile.d/conda.sh 2>/dev/null; printf '%s\0' /usr/share/cachyos-zsh-config/cachyos-config.zsh 2>/dev/null ) >"$wf" &
    workers+=("$!")

    if command -v zoxide >/dev/null 2>&1; then
        wf="$tmpdir/w_zoxide"
        worker_files+=("$wf")
        ( [[ -e /usr/share/zoxide/zoxide.zsh ]] && printf '%s\0' /usr/share/zoxide/zoxide.zsh ) >"$wf" &
        workers+=("$!")
    fi

    # worker: find /usr/share (may be many files)
    # Use incremental scan when a stamp file exists to only find files newer than last run.
    # Prefer `fd` for speed when available and when not doing incremental runs.
    wf="$tmpdir/w_find"
    worker_files+=("$wf")
    STAMP="${STAMP:-${XDG_CACHE_HOME:-$HOME/.cache}/precompile_zsh.stamp}"
    mkdir -p "$(dirname "$STAMP")" 2>/dev/null || true
    if command -v fd >/dev/null 2>&1 && [[ ! -f "$STAMP" ]]; then
        ( fd -0 -t f -e zsh -e zsh-theme /usr/share 2>/dev/null >"$wf" ) &
    else
        ( if [[ -f "$STAMP" ]]; then
                find /usr/share -type f \( -name "*.zsh" -o -name "*.zsh-theme" \) -newer "$STAMP" -print0 2>/dev/null >"$wf"
            else
                find /usr/share -type f \( -name "*.zsh" -o -name "*.zsh-theme" \) -print0 2>/dev/null >"$wf"
            fi ) &
    fi
    workers+=("$!")
fi

# wait for discovery workers
for pid in "${workers[@]}"; do
    wait "$pid" 2>/dev/null || true
done

# Merge worker files into main list via serial add_file (safe for _seen and files arrays)
for wf in "${worker_files[@]}"; do
    [[ -f "$wf" ]] || continue
    while IFS= read -r -d '' sf; do
        add_file "$sf"
    done <"$wf"
done

# cleanup
rm -rf -- "$tmpdir"

# Concurrency for compilation: sensible default and an upper cap
DEFAULT_PARALLEL=$(nproc 2>/dev/null || echo 8)
MAX_PARALLEL=${MAX_PARALLEL:-32}
PARALLEL="${PARALLEL:-$DEFAULT_PARALLEL}"

# Validate and cap PARALLEL
if ! [[ "$PARALLEL" =~ ^[0-9]+$ ]]; then
    PARALLEL=$DEFAULT_PARALLEL
fi
if (( PARALLEL < 1 )); then
    PARALLEL=$DEFAULT_PARALLEL
fi
if (( PARALLEL > MAX_PARALLEL )); then
    PARALLEL=$MAX_PARALLEL
fi

# Try to run compilation with xargs -P for efficiency, falling back to per-job backgrounding.
files_list="$(mktemp)"
for f in "${files[@]}"; do
    printf '%s\0' "$f" >>"$files_list"
done

# Prepare ionice command - note: ionice must wrap the entire zsh process, not zcompile directly
USE_IONICE=0
if command -v ionice >/dev/null 2>&1; then
    USE_IONICE=1
fi

if command -v xargs >/dev/null 2>&1; then
    # Use xargs with parallelism; each worker runs zsh that calls zcompile under nice/ionice
    if (( USE_IONICE )); then
        xargs -0 -P "$PARALLEL" -n1 ionice -c2 -n7 nice -n 10 zsh -c 'zcompile "$1" 2>/dev/null || true' _ <"$files_list"
    else
        xargs -0 -P "$PARALLEL" -n1 nice -n 10 zsh -c 'zcompile "$1" 2>/dev/null || true' _ <"$files_list"
    fi
else
    # Fallback: spawn background jobs with simple semaphore
    pids=()
    for f in "${files[@]}"; do
        if (( USE_IONICE )); then
            ( [[ -s "$f" && ( ! -s "$f.zwc" || "$f" -nt "$f.zwc" ) ]] && ionice -c2 -n7 nice -n 10 zcompile "$f" 2>/dev/null || true ) &
        else
            ( [[ -s "$f" && ( ! -s "$f.zwc" || "$f" -nt "$f.zwc" ) ]] && nice -n 10 zcompile "$f" 2>/dev/null || true ) &
        fi
        pids+=("$!")
        while (( ${#pids[@]} >= PARALLEL )); do
            wait ${pids[0]} 2>/dev/null || true
            new=()
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new+=("$pid")
                fi
            done
            pids=("${new[@]}")
        done
    done
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
fi

# cleanup files list
rm -f -- "$files_list" 2>/dev/null || true

# Update stamp for incremental discovery
touch "$STAMP" 2>/dev/null || true

echo PRECOMPILE_DONE
