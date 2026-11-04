#!/usr/bin/env bash
# Swap the login screen: Plasma Login -> noctalia-greeter (on greetd).
# Takes effect at next boot; the current session is not touched.
#
# If the greeter fails to appear: press Ctrl+Alt+F2, log in on the text
# console, and run:  sudo bash ~/.local/share/greeter-swap/swap.sh --undo
#
# Run as root:  pkexec bash ~/.local/share/greeter-swap/swap.sh [--undo]
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root (pkexec bash $0)" >&2; exit 1; }

CONF=/etc/greetd/config.toml

if [[ ${1:-} == --undo ]]; then
    systemctl disable greetd.service
    systemctl enable plasmalogin.service
    [[ -f $CONF.bak ]] && cp -a "$CONF.bak" "$CONF"
    echo "restored Plasma Login (takes effect at next boot)"
    exit 0
fi

# Package's own setup: greetd PAM gets pam_systemd (proper login sessions),
# greeter folders, and the synced appearance config
bash /usr/share/noctalia-greeter/setup_greeter_system.sh

# Recommended config from noctalia-greeter-print-greetd-config
cp -a "$CONF" "$CONF.bak"
cat >"$CONF" <<'EOF'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
EOF

# Only one display manager may own display-manager.service: drop the old one first
systemctl disable plasmalogin.service
systemctl enable greetd.service
systemctl is-enabled plasmalogin.service greetd.service | paste -d' ' <(printf 'plasmalogin\ngreetd\n') - || true
echo "done: noctalia-greeter takes over at next boot (backup: $CONF.bak)"
