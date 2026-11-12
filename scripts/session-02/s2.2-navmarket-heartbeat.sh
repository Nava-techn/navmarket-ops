#!/usr/bin/env bash
# S2.2 - NavMarket heartbeat: checks the storefront every 10 seconds.
# Each line goes to the systemd journal: journalctl -u navmarket-heartbeat
set -u
URL="${URL:-http://localhost/}"
while true; do
  code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$URL") || code=000
  echo "storefront $URL http=$code"
  sleep 10
done
