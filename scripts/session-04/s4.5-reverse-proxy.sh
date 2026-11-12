#!/usr/bin/env bash
# Created in Session 4, lab S4.5: Nginx reverse proxy in front of 2 web servers.
# Runs ON srv01 as root, after S4.3. From the workstation:
#   scripts/session-04/s4.4-run-on-srv01.sh scripts/session-04/s4.5-reverse-proxy.sh docs/session-04/S4.5-proofs.txt
#
# web1 and web2 are two small web servers (python http.server, systemd, DynamicUser)
# on 127.0.0.1:8081 and :8082. Nginx spreads https://www.navmarket.lan/lb/ across
# them (round robin) and stops sending traffic to one that is down.
set -uo pipefail
exec > >(tee "${PROOFS:-/tmp/S4.5-proofs.txt}") 2>&1
echo "# S4.5 proofs - $(date '+%F %T')"

# 1. The two backends
for i in 1 2; do
  install -d -m 755 /srv/navmarket-web$i
  printf '{"backend": "web%s", "status": "ok"}\n' "$i" > /srv/navmarket-web$i/health.json
  chmod 644 /srv/navmarket-web$i/health.json
done
cat > /etc/systemd/system/navmarket-web@.service <<'UNIT'
# Session 4, S4.5: backend web server number %i (port 808%i, local only)
[Unit]
Description=NavMarket backend web%i
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 808%i --bind 127.0.0.1 --directory /srv/navmarket-web%i
DynamicUser=yes
Restart=always

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now --quiet navmarket-web@1 navmarket-web@2

# 2. Nginx: the pool (http level) and the /lb/ location (inside the HTTPS site of S4.3)
cat > /etc/nginx/conf.d/navmarket-upstream.conf <<'NGX'
# Session 4, S4.5: the pool of backend web servers
upstream navmarket_backends {
    server 127.0.0.1:8081 max_fails=1 fail_timeout=10s;
    server 127.0.0.1:8082 max_fails=1 fail_timeout=10s;
}
NGX
install -d -m 755 /etc/nginx/navmarket-locations
cat > /etc/nginx/navmarket-locations/lb.conf <<'NGX'
# Session 4, S4.5: https://www.navmarket.lan/lb/ -> web1 or web2
location /lb/ {
    proxy_pass http://navmarket_backends/;        # the trailing / removes "/lb" from the path
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;       # the backend sees the real client IP
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_connect_timeout 2s;
    add_header X-Backend $upstream_addr always;    # shows which backend answered (lab only)
}
NGX
nginx -t 2>&1 | tail -1 && systemctl reload nginx
sleep 1
C="curl -s --resolve www.navmarket.lan:443:127.0.0.1 --cacert /etc/ssl/navmarket/navmarket.crt"
# the server cert is not a CA: trust the system store if the lab CA was installed, else skip checks
$C -o /dev/null https://www.navmarket.lan/ 2>/dev/null || C="curl -sk --resolve www.navmarket.lan:443:127.0.0.1"

echo; echo "## 1. Backends running, listening only on 127.0.0.1"
systemctl is-active navmarket-web@1 navmarket-web@2
ss -tln | grep -E ':808[12] '

echo; echo "## 2. Round robin: 4 requests through the proxy"
for _ in 1 2 3 4; do $C https://www.navmarket.lan/lb/health.json; done

echo; echo "## 3. web2 goes down: the proxy keeps answering with web1"
systemctl stop navmarket-web@2
for _ in 1 2 3 4; do $C -w "  HTTP %{http_code}\n" https://www.navmarket.lan/lb/health.json; done

echo; echo "## 4. web2 is back: traffic is shared again"
systemctl start navmarket-web@2; sleep 11
for _ in 1 2 3 4; do $C https://www.navmarket.lan/lb/health.json; done

echo; echo "## 5. The backend sees the proxy, the proxy logs the real client"
journalctl -u navmarket-web@1 -n 2 --no-pager -o cat
