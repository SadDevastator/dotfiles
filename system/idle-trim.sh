#!/usr/bin/env bash
# Idle-RAM trim: stop system daemons that aren't needed while idle.
#   keyd            no config in /etc/keyd, so it remaps nothing        (~33 MB)
#   coolercontrold  fan curves, not used                                 (~24 MB)
#   lactd           GPU control (LACT), not used                         (~10 MB)
#   proton.VPN      D-Bus activatable (SystemdService=proton.VPN.service),
#                   so it still starts when the Proton app/CLI calls it   (~12 MB)
# Run as root:  pkexec bash ~/.local/share/idle-trim/trim.sh [--undo]
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root (pkexec bash $0)" >&2; exit 1; }

units=(keyd.service coolercontrold.service lactd.service proton.VPN.service)

if [[ ${1:-} == --undo ]]; then
    systemctl enable --now "${units[@]}"
    echo "restored: ${units[*]}"
    exit 0
fi

systemctl disable --now "${units[@]}"
systemctl is-active "${units[@]}" | paste -d' ' <(printf '%s\n' "${units[@]}") - || true
echo "done; ProtonVPN starts again on demand via D-Bus"
