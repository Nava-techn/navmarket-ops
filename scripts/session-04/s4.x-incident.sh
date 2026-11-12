#!/usr/bin/env bash
# Created in Session 4, incident S4.x: "the name no longer resolves, wrong gateway".
# Runs ON srv01 as root, in the S3 network lab (lab-netns.sh) with the DHCP/DNS of S4.2.
# From the workstation:
#   scp scripts/session-03/s3.2-lab-netns.sh srv01:/tmp/
#   scripts/session-04/s4.4-run-on-srv01.sh scripts/session-04/s4.x-incident.sh docs/session-04/S4.x-proofs.txt
set -uo pipefail
exec > >(tee "${PROOFS:-/tmp/S4.x-proofs.txt}") 2>&1
L=/tmp/s3.2-lab-netns.sh
[ -f $L ] || { echo "Missing $L (scp it first)"; exit 1; }
command -v dig >/dev/null || apt-get install -y -qq bind9-dnsutils >/dev/null

# Lab: LAN A (client) - router - LAN B (web server 10.10.2.10, name web.navmarket.lan)
pkill -F /tmp/lab-dnsmasq.pid 2>/dev/null
bash $L down >/dev/null 2>&1; bash $L up >/dev/null
ip netns exec router sysctl -qw net.ipv4.ip_forward=1
ip -n lan-a route replace default via 10.10.1.1
ip -n lan-b route replace default via 10.10.2.1
ip netns exec router dnsmasq --conf-file=/dev/null --interface=r-a --bind-interfaces --except-interface=lo \
  --local=/navmarket.lan/ --domain=navmarket.lan --host-record=web.navmarket.lan,10.10.2.10 \
  --pid-file=/tmp/lab-dnsmasq.pid --no-resolv
mkdir -p /etc/netns/lan-a                       # "ip netns exec" uses this file as resolv.conf
echo "nameserver 10.10.1.1" > /etc/netns/lan-a/resolv.conf
A="ip netns exec lan-a"
test_all() {
  $A ping -c1 -W1 10.10.2.10 >/dev/null && echo "ping web server by IP: OK" || echo "ping web server by IP: FAILED"
  r=$($A dig +short +time=1 +tries=1 web.navmarket.lan 2>/dev/null | grep -E '^[0-9.]+$')
  [ -n "$r" ] && echo "resolve web.navmarket.lan: OK ($r)" || echo "resolve web.navmarket.lan: FAILED"
}

echo "# S4.x proofs - $(date '+%F %T')"
echo; echo "## 1. Normal state"; test_all

echo; echo "## 2. Incident: a bad change sets the wrong gateway and the wrong DNS server"
ip -n lan-a route replace default via 10.10.1.254
echo "nameserver 10.10.1.53" > /etc/netns/lan-a/resolv.conf
test_all

echo; echo "## 3. Diagnosis, layer by layer"
echo "-- a) my own IP and routes:"; ip -n lan-a -br addr show veth-a; ip -n lan-a route
echo "-- b) can I reach my gateway?"
$A ping -c1 -W1 10.10.1.254 >/dev/null || echo "10.10.1.254 does not answer"
$A ip neigh show 10.10.1.254
echo "-- c) the real router answers:"; $A ping -c1 -W1 10.10.1.1 | grep -E "bytes from|loss"
echo "-- d) which DNS server am I using?"; cat /etc/netns/lan-a/resolv.conf
echo "-- e) ask the real DNS server directly:"; $A dig +short @10.10.1.1 web.navmarket.lan
echo "=> Cause 1: default route via 10.10.1.254, a host that does not exist (ARP INCOMPLETE or FAILED)."
echo "=> Cause 2: resolv.conf points to 10.10.1.53, no DNS server there."

echo; echo "## 4. Fix"
ip -n lan-a route replace default via 10.10.1.1
echo "nameserver 10.10.1.1" > /etc/netns/lan-a/resolv.conf
ip -n lan-a route | grep default

echo; echo "## 5. Check after the fix"; test_all

pkill -F /tmp/lab-dnsmasq.pid; rm -rf /etc/netns/lan-a; bash $L down >/dev/null 2>&1
echo; echo "Lab cleaned."
