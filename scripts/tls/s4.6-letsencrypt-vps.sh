#!/usr/bin/env bash
# Created in Session 4, lab S4.6: real domain name, Let's Encrypt HTTPS and fail2ban on vps01.
# Runs ON vps01 as root. Before: the domain points to vps01's public IP, and TCP 443 is
# open in Oracle's security list (console). From the workstation:
#   scripts/run-on-srv01.sh scripts/tls/s4.6-letsencrypt-vps.sh docs/session-04/S4.6-proofs.txt \
#       vps01 DOMAIN=navmarket.duckdns.org EMAIL=me@example.com
set -uo pipefail
exec > >(tee "${PROOFS:-/tmp/S4.6-proofs.txt}") 2>&1
: "${DOMAIN:?DOMAIN=... missing}" "${EMAIL:?EMAIL=... missing}"
SITE=/etc/nginx/sites-available/navmarket
echo "# S4.6 proofs - $(date '+%F %T')"

echo; echo "## 1. The domain points to this server"
apt-get install -y -qq bind9-dnsutils >/dev/null
me=$(curl -s4 https://api.ipify.org); dns=$(dig +short "$DOMAIN" A | tail -1)
echo "$DOMAIN -> $dns"
if [ "$me" = "$dns" ]; then echo "matches this server's public IP"; else echo "DOES NOT match this server: fix DNS first"; exit 1; fi

echo; echo "## 2. Port 443 open in iptables (inserted above the final REJECT, like port 80 in S1.5)"
if ! iptables -C INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT 2>/dev/null; then
  n=$(iptables -L INPUT --line-numbers -n | awk '$2=="REJECT"{print $1; exit}')
  iptables -I INPUT "${n:-1}" -m state --state NEW -p tcp --dport 443 -j ACCEPT
  netfilter-persistent save >/dev/null 2>&1
fi
iptables -L INPUT -n | grep -E "dpt:(80|443)"

echo; echo "## 3. Nginx answers to the domain name, then certbot gets the certificate"
sed -i "s/server_name _;/server_name $DOMAIN;/" "$SITE"
nginx -t 2>&1 | tail -1 && systemctl reload nginx
apt-get install -y -qq certbot python3-certbot-nginx fail2ban >/dev/null
certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --no-eff-email --redirect -n 2>&1 | tail -4

echo; echo "## 4. HTTPS from the Internet, trusted by everyone"
curl -sI "https://$DOMAIN/" | grep -iE "^HTTP|^strict|^server"
curl -sI "http://$DOMAIN/" | grep -iE "^HTTP|^location"
echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | grep -E "^issuer=|Verify return"
certbot certificates 2>/dev/null | grep -E "Domains|Expiry"

echo; echo "## 5. Automatic renewal"
systemctl list-timers certbot.timer --no-pager | head -2
certbot renew --dry-run 2>&1 | grep -iE "success|fail" | head -2

echo; echo "## 6. fail2ban: 5 failed SSH logins in 10 min = banned for 1 hour"
cat > /etc/fail2ban/jail.d/navmarket.local <<'JAIL'
# Session 4, S4.6
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
backend = systemd
JAIL
systemctl enable --quiet fail2ban; systemctl restart fail2ban; sleep 3
fail2ban-client status sshd
