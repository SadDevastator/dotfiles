#!/usr/bin/env bash
# Renders the random Pokemon sprite for fastfetch, with the Pokemon's name
# centred UNDERNEATH the sprite. pokeget prints the name above the sprite and,
# importantly, writes the name to stderr while the sprite goes to stdout - so
# the two have to be captured separately to be recombined in the other order.
#
# pokeget sprites are a random 18-41 columns wide, so a fixed layout either
# wraps on narrow terminals or wastes space on wide ones. This script measures
# the sprite and drops it for the run when it would not leave enough width for
# the info column, and hands the measured width to footer.sh so the bottom rule
# can match it.

set -u

# Floor for the info column before the sprite is dropped entirely.
#
# fastfetch runs with line wrap disabled (display.disableLinewrap, default
# true), so a row that is wider than the space beside the sprite is clipped at
# the right edge -- it does NOT wrap onto the next line and collide with the
# sprite. Text therefore cannot disturb the image, and there is no need to
# sacrifice the sprite to keep long rows intact.
#
# This only guards the degenerate case: a terminal so narrow that the sprite
# would leave no usable room for text at all.
readonly INFO_MIN=20
# fastfetch adds logo.padding.left + logo.padding.right beside the logo block.
readonly LOGO_PADDING=3
# Rendered blank, but non-whitespace as far as fastfetch is concerned: emitting
# only spaces or newlines makes it fall back to the built-in distro logo.
readonly BLANK_LOGO=$'\u00a0'   # U+00A0: a plain space counts as empty and triggers the fallback

# logo.sh and footer.sh are run by separate shells, so $PPID differs between
# them. The controlling terminal is shared and is unique per terminal, which
# keeps concurrently starting shells from clobbering each other.
tty_key=unknown
if { exec 3</dev/tty; } 2>/dev/null; then
  tty_key=$(readlink /proc/self/fd/3 2>/dev/null) || tty_key=unknown
  exec 3<&-
fi
tty_key=${tty_key//\//-}
width_file="${XDG_RUNTIME_DIR:-/tmp}/fastfetch-logo-width.${tty_key}"
name_file="${XDG_RUNTIME_DIR:-/tmp}/fastfetch-pokename.${tty_key}"

# Drop any stale value from a previous run before doing anything else: pty
# device names get reused, so a leftover file would be read as this run's width.
rm -f "$width_file" 2>/dev/null

cols=$( { tput cols </dev/tty; } 2>/dev/null ) || cols=80
[[ $cols =~ ^[0-9]+$ ]] || cols=80

hide_logo() {
  printf '%s 0\n' "$cols" >"$width_file"
  printf '%s\n' "$BLANK_LOGO"
  exit 0
}

# Shiny odds mirror the games (1/4096). Two ways to force one:
#   POKEGET_SHINY=1 fastfetch   -- shiny for this run only
#   touch "$shiny_file"         -- shiny for the NEXT run, then clears itself
shiny_file="${XDG_RUNTIME_DIR:-/tmp}/fastfetch-force-shiny"
shiny=0
[[ ${POKEGET_SHINY:-0} == 1 ]] && shiny=1
if [[ -e $shiny_file ]]; then
  shiny=1
  rm -f "$shiny_file" 2>/dev/null
fi
if (( ! shiny )) && (( RANDOM % 4096 == 0 )); then
  shiny=1
fi

if (( shiny )); then
  sprite=$(pokeget random --shiny 2>"$name_file")
else
  sprite=$(pokeget random 2>"$name_file")
fi
name=$(cat "$name_file" 2>/dev/null) || name=""
rm -f "$name_file" 2>/dev/null

sprite=${sprite//$'\r'/}
sprite=${sprite%$'\n'}
name=${name//$'\r'/}
name=${name%%$'\n'*}

[[ -n $sprite ]] || hide_logo

sprite_w=$(printf '%s\n' "$sprite" | sed $'s/\033\\[[0-9;]*m//g' | wc -L)
[[ $sprite_w =~ ^[0-9]+$ ]] || sprite_w=0

(( sprite_w > 0 )) || hide_logo
(( cols - sprite_w - LOGO_PADDING >= INFO_MIN )) || hide_logo

# ---------------------------------------------------------------------------
# Caption: dex number + name, then the Pokemon's type(s) as Nerd Font glyphs.
#
# pokedex.tsv is generated once and shipped alongside this script, so the
# lookup is a single local awk pass with no network access at runtime.
# Columns: slug <TAB> dex <TAB> display name <TAB> comma-separated types.
# ---------------------------------------------------------------------------

readonly POKEDEX="${BASH_SOURCE[0]%/*}/pokedex.tsv"

# Nerd Font glyph + the canonical Pokemon type colour, per type.
declare -A TYPE_ICON=(
  [normal]=$'\U000F0765'    # md-circle
  [fire]=$'\U000F0238'      # md-fire
  [water]=$'\U000F058C'     # md-water
  [electric]=$'\U000F140B'  # md-lightning-bolt
  [grass]=$'\U000F032A'     # md-leaf
  [ice]=$'\U000F0717'       # md-snowflake
  [fighting]=$'\U000F0D43'  # md-boxing-glove
  [poison]=$'\U0000E231'    # fae-poison
  [ground]=$'\U000F0509'    # md-terrain
  [flying]=$'\U000F06DA'    # md-feather
  [psychic]=$'\U000F09D1'   # md-brain
  [bug]=$'\U000F00E4'       # md-bug
  [rock]=$'\U000F0293'      # md-diamond-stone
  [ghost]=$'\U000F02A0'     # md-ghost
  [dragon]=$'\U0000EEF8'    # fa-dragon
  [dark]=$'\U000F0594'      # md-weather-night
  [steel]=$'\U000F089A'     # md-anvil
  [fairy]=$'\U000F1844'     # md-magic-staff
)
declare -A TYPE_RGB=(
  [normal]='168;167;122'  [fire]='238;129;48'     [water]='99;144;240'
  [electric]='247;208;44' [grass]='122;199;76'    [ice]='150;217;214'
  [fighting]='194;46;40'  [poison]='163;62;161'   [ground]='226;191;101'
  [flying]='169;143;243'  [psychic]='249;85;135'  [bug]='166;185;26'
  [rock]='182;161;54'     [ghost]='115;87;151'    [dragon]='111;53;252'
  [dark]='112;87;70'      [steel]='183;183;206'   [fairy]='214;133;173'
)

# Visible width, ignoring ANSI SGR sequences.
#
# extglob's *([0-9;]) is required here. With a plain glob the trailing * is
# greedy, so it matches from the first ESC all the way to the last 'm' and
# swallows the text in between -- every caption measured as width 0, which
# made pad = sprite_w / 2 and started the text at the sprite's midpoint
# instead of centring it.
shopt -s extglob
vis_width() {
  local stripped=${1//$'\033'\[*([0-9;])m/}
  printf '%s' "${#stripped}"
}

# Normalise a display name to the key used for matching ("Farfetch'd" -> farfetchd).
norm_key() {
  local k=${1,,}
  printf '%s' "${k//[^a-z0-9]/}"
}

dex=""
types=""
if [[ -n $name && -r $POKEDEX ]]; then
  IFS=$'\t' read -r dex types < <(
    awk -F'\t' -v want="$(norm_key "$name")" '
      /^#/ { next }
      {
        n = tolower($3); gsub(/[^a-z0-9]/, "", n)
        s = tolower($1); gsub(/[^a-z0-9]/, "", s)
        if (n == want || s == want) { print $2 "\t" $4; exit }
      }' "$POKEDEX"
  ) || { dex=""; types=""; }
fi

# Line 1: dimmed #dex, then the name in bold.
# Shiny caption. A glyph on its own is easy to miss against a sprite you may
# not know the normal colours of, so the whole caption shifts to gold -- the
# colour change is what actually reads at a glance, the sparkle just names it.
sparkle=$'\U000F0674'          # md-creation
gold='38;2;255;215;0'

if (( shiny )); then
  if [[ -n $dex ]]; then
    line1=$(printf '\033[2;%sm#%03d\033[0m \033[1;%sm%s\033[0m \033[%sm%s\033[0m' \
      "$gold" "$dex" "$gold" "$name" "$gold" "$sparkle")
  else
    line1=$(printf '\033[1;%sm%s\033[0m \033[%sm%s\033[0m' "$gold" "$name" "$gold" "$sparkle")
  fi
elif [[ -n $dex ]]; then
  line1=$(printf '\033[2m#%03d\033[0m \033[1m%s\033[0m' "$dex" "$name")
else
  line1=$(printf '\033[1m%s\033[0m' "$name")   # unknown Pokemon: name only
fi

# Line 2: one coloured "<glyph> <Type>" per type, space separated.
line2=""
if [[ -n $types ]]; then
  IFS=',' read -ra type_list <<<"$types"
  for t in "${type_list[@]}"; do
    icon=${TYPE_ICON[$t]:-}
    rgb=${TYPE_RGB[$t]:-}
    [[ -n $icon && -n $rgb ]] || continue
    label=${t^}
    [[ -n $line2 ]] && line2+='  '
    line2+=$(printf '\033[38;2;%sm%s %s\033[0m' "$rgb" "$icon" "$label")
  done
fi

# The caption may be wider than the sprite; the box has to clear whichever is
# widest, so footer.sh gets the true block width.
block_w=$sprite_w
for l in "$line1" "$line2"; do
  [[ -n $l ]] || continue
  w=$(vis_width "$l")
  (( w > block_w )) && block_w=$w
done

printf '%s %s\n' "$cols" "$block_w" >"$width_file"

printf '%s\n' "$sprite"
for l in "$line1" "$line2"; do
  [[ -n $l ]] || continue
  w=$(vis_width "$l")
  pad=$(( (sprite_w - w) / 2 ))
  (( pad < 0 )) && pad=0
  printf '%*s%s\n' "$pad" '' "$l"
done
exit 0
