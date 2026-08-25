#!/usr/bin/env bash
# Draws the bottom rule of the fastfetch box, sized to the width left beside the
# sprite, so it neither overflows the terminal nor falls short of the box.
#
# logo.sh records the sprite width keyed by the controlling terminal; see the
# comment there for why $PPID cannot be used.
#
# The leading ESC[2D cancels the two-column key separator fastfetch inserts
# before every module value, so the rule lines up with the │ rail above it.

set -u

readonly LOGO_PADDING=3
readonly MIN_RULE=14
# Widest line the module list produces (Disk (/mnt/DATA), 60 cols) plus 1, to
# offset the ESC[2D backstep below so the rule ends flush with the content.
# Without this the rule stretched from the sprite to the right edge of the
# terminal -- ~165 dashes on a 200 column window, dwarfing a 60 column box.
readonly RULE_MAX=61

tty_key=unknown
if { exec 3</dev/tty; } 2>/dev/null; then
  tty_key=$(readlink /proc/self/fd/3 2>/dev/null) || tty_key=unknown
  exec 3<&-
fi
width_file="${XDG_RUNTIME_DIR:-/tmp}/fastfetch-logo-width.${tty_key//\//-}"

cols=$( { tput cols </dev/tty; } 2>/dev/null ) || cols=80
[[ $cols =~ ^[0-9]+$ ]] || cols=80

# fastfetch may run this module concurrently with the logo command, so on a
# cold start (pokeget not yet in page cache) the width file can lag. Wait
# briefly; in the warm case the file is already there and this loop never runs.
tries=0
while [[ ! -s $width_file ]] && (( tries < 40 )); do
  sleep 0.01
  (( tries++ ))
done

stamp=$(cat "$width_file" 2>/dev/null) || stamp=""
rm -f "$width_file" 2>/dev/null

# logo.sh writes "<cols> <sprite_width>". Reject the value unless it was
# measured at the width we see now, so a stale file can never widen the rule.
logo_w=""
if [[ $stamp =~ ^([0-9]+)\ ([0-9]+)$ ]] && (( BASH_REMATCH[1] == cols )); then
  logo_w=${BASH_REMATCH[2]}
fi

if [[ $logo_w =~ ^[0-9]+$ ]]; then
  if (( logo_w > 0 )); then
    offset=$(( logo_w + LOGO_PADDING ))
  else
    offset=$(( 1 + LOGO_PADDING ))   # width of BLANK_LOGO in logo.sh
  fi
  # Leave the final column free so the rule never triggers the terminal's autowrap.
  avail=$(( cols - offset - 1 ))
  (( avail > RULE_MAX )) && avail=$RULE_MAX
  (( avail < MIN_RULE )) && avail=$MIN_RULE
else
  # Sprite width unknown (logo.sh raced, failed, or had no controlling tty).
  # Fall back to a short cap: it can never overflow, whatever the real offset is.
  avail=$MIN_RULE
fi

dashes=68
(( dashes < 1 )) && dashes=1

printf -v rule '%*s' "$dashes" ''
printf '\033[2D╰%s╯' "${rule// /─}"
