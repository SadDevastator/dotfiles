#!/usr/bin/env bash
# Start tailscaled and warp-svc on demand (systemd socket proxy).
#
# Neither daemon supports socket activation, so a .socket unit owns each
# daemon's public control socket; the first client (tailscale, warp-cli, a tray
# app) starts systemd-socket-proxyd, which pulls in the real daemon on a private
# socket and forwards to it. The proxy exits after 60 s idle; the daemon keeps
# running until `systemctl stop tailscaled` / `systemctl stop warp-svc`.
#
# Trade-off: the daemons see every client as root (the proxy), so their
# per-user permission checks no longer apply.
#
# Run as root:  pkexec bash ~/.local/share/vpn-on-demand/install.sh [--uninstall]
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root (pkexec bash $0)" >&2; exit 1; }

U=/etc/systemd/system
PROXYD=/usr/lib/systemd/systemd-socket-proxyd

if [[ ${1:-} == --uninstall ]]; then
    systemctl disable --now tailscaled-proxy.socket warp-svc-proxy.socket 2>/dev/null || true
    systemctl stop tailscaled-proxy.service warp-svc-proxy.service tailscaled.service warp-svc.service 2>/dev/null || true
    rm -f "$U"/tailscaled-proxy.{socket,service} "$U"/warp-svc-proxy.{socket,service}
    rm -rf "$U"/tailscaled.service.d/on-demand.conf "$U"/warp-svc.service.d/on-demand.conf
    rmdir "$U"/tailscaled.service.d "$U"/warp-svc.service.d 2>/dev/null || true
    systemctl daemon-reload
    echo "uninstalled; start the daemons normally with systemctl start tailscaled / warp-svc"
    exit 0
fi

# Daemons must not be running while their sockets move
systemctl stop tailscaled.service warp-svc.service 2>/dev/null || true

# --- Tailscale: real socket in /run/tailscale-real -------------------------
mkdir -p "$U/tailscaled.service.d"
cat >"$U/tailscaled.service.d/on-demand.conf" <<'EOF'
# On-demand via tailscaled-proxy.socket: the public socket belongs to the proxy
[Service]
RuntimeDirectory=
RuntimeDirectory=tailscale-real
ExecStart=
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale-real/tailscaled.sock --port=${PORT} $FLAGS
EOF

cat >"$U/tailscaled-proxy.socket" <<'EOF'
[Unit]
Description=Tailscale control socket (starts tailscaled on demand)

[Socket]
ListenStream=/run/tailscale/tailscaled.sock
SocketMode=0666
DirectoryMode=0755

[Install]
WantedBy=sockets.target
EOF

cat >"$U/tailscaled-proxy.service" <<EOF
[Unit]
Description=Forward the Tailscale control socket to tailscaled (on demand)
Requires=tailscaled.service tailscaled-proxy.socket
After=tailscaled.service tailscaled-proxy.socket

[Service]
ExecStartPre=/bin/sh -c 'for i in \$(seq 100); do [ -S /run/tailscale-real/tailscaled.sock ] && exit 0; sleep 0.1; done; exit 1'
ExecStart=$PROXYD --exit-idle-time=60s /run/tailscale-real/tailscaled.sock
EOF

# --- Cloudflare WARP: warp-svc has no socket option, so give it a private
# /run/cloudflare-warp via a bind mount; the public one belongs to the proxy --
mkdir -p "$U/warp-svc.service.d"
cat >"$U/warp-svc.service.d/on-demand.conf" <<'EOF'
# On-demand via warp-svc-proxy.socket: warp-svc sees a private /run/cloudflare-warp
[Service]
RuntimeDirectory=
RuntimeDirectory=cloudflare-warp-real
BindPaths=/run/cloudflare-warp-real:/run/cloudflare-warp
EOF

cat >"$U/warp-svc-proxy.socket" <<'EOF'
[Unit]
Description=Cloudflare WARP control socket (starts warp-svc on demand)

[Socket]
ListenStream=/run/cloudflare-warp/warp_service
SocketMode=0666
DirectoryMode=0755

[Install]
WantedBy=sockets.target
EOF

cat >"$U/warp-svc-proxy.service" <<EOF
[Unit]
Description=Forward the WARP control socket to warp-svc (on demand)
Requires=warp-svc.service warp-svc-proxy.socket
After=warp-svc.service warp-svc-proxy.socket

[Service]
ExecStartPre=/bin/sh -c 'for i in \$(seq 150); do [ -S /run/cloudflare-warp-real/warp_service ] && exit 0; sleep 0.1; done; exit 1'
ExecStart=$PROXYD --exit-idle-time=60s /run/cloudflare-warp-real/warp_service
EOF

systemctl daemon-reload
# Daemons themselves stay disabled: only the sockets start at boot
systemctl disable tailscaled.service warp-svc.service 2>/dev/null || true
systemctl enable --now tailscaled-proxy.socket warp-svc-proxy.socket
systemctl --no-pager --lines=0 status tailscaled-proxy.socket warp-svc-proxy.socket | grep -E '●|Active:|Listen:'
echo "installed: tailscale / warp-cli now start their daemons on first use"
