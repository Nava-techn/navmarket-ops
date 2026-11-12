#!/usr/bin/env bash
# Created in Session 4, lab S4.4: firewall on srv01, only ports 22, 80, 443 open.
# Runs ON srv01 as root. From the workstation, use:
#   scp scripts/session-04/s4.4-navmarket-srv01.nft srv01:/tmp/
#   scripts/session-04/s4.4-run-on-srv01.sh scripts/session-04/s4.4-firewall.sh docs/session-04/S4.4-proofs.txt
#
# Safety net: a rollback timer removes the firewall after 120 s unless it is
# cancelled. If a rule ever locks SSH out, waiting 2 minutes is enough.
set -uo pipefail
exec > >(tee "${PROOFS:-/tmp/S4.4-proofs.txt}") 2>&1

RULES=/tmp/s4.4-navmarket-srv01.nft
[ -f "$RULES" ] || { echo "Missing $RULES (scp it first)"; exit 1; }

echo "# S4.4 proofs - $(date '+%F %T')"
echo; echo "## 1. Listening ports BEFORE (everything that could be reached)"
ss -tlnu | awk 'NR==1 || /LISTEN|UNCONN/ {print $1, $5}' | sort -u

systemctl stop navmarket-fw-rollback.timer 2>/dev/null
systemd-run --quiet --on-active=120 --unit=navmarket-fw-rollback nft delete table inet navmarket_fw
nft -f "$RULES" || { echo "Rules rejected, nothing applied"; exit 1; }

echo; echo "## 2. Rules loaded"
nft list table inet navmarket_fw

echo; echo "## 3. Test: a service on port 8081 is reachable locally, not from outside"
python3 -m http.server 8081 --bind 0.0.0.0 >/dev/null 2>&1 & web=$!
sleep 1
curl -s -o /dev/null -w "from srv01 itself (lo): HTTP %{http_code}\n" http://127.0.0.1:8081/
ip netns add fwtest 2>/dev/null; ip link add fw-h type veth peer name fw-n netns fwtest
ip addr add 192.168.250.1/30 dev fw-h; ip link set fw-h up
ip -n fwtest addr add 192.168.250.2/30 dev fw-n; ip -n fwtest link set fw-n up
for port in 22 80 443 8081; do
  if ip netns exec fwtest timeout 3 bash -c "</dev/tcp/192.168.250.1/$port" 2>/dev/null
  then echo "from another machine, port $port: OPEN"
  else echo "from another machine, port $port: BLOCKED"; fi
done
ip netns del fwtest; kill $web

echo; echo "## 4. Dropped packets are logged"
journalctl -k --since "-2min" --no-pager | grep -m3 "nft-drop:" || echo "(no drop logged yet)"

echo; echo "## 5. Persistence: loaded again at boot by nftables.service"
install -D -m 644 "$RULES" /etc/nftables.d/navmarket.nft
grep -q 'nftables.d/navmarket.nft' /etc/nftables.conf || echo 'include "/etc/nftables.d/navmarket.nft"' >> /etc/nftables.conf
nft -c -f /etc/nftables.conf && echo "/etc/nftables.conf: syntax OK"
systemctl enable --quiet nftables && systemctl is-enabled nftables
systemctl stop navmarket-fw-rollback.timer && echo "Rollback timer cancelled: SSH still works, the firewall stays"
rm -f "$RULES"
