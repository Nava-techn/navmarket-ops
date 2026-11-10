#!/usr/bin/env bash
# Created in Session 5, lab S5.2: health check of the storefront, with an exit code.
#
# Checks each URL: HTTP 200, "status": "ok" for health.json, response time,
# and days left on the HTTPS certificate. One line per check, then the exit code
# tells a script, cron or CI what happened:
#   0 = OK, 1 = WARNING, 2 = CRITICAL (the usual monitoring convention)
#
# Usage: scripts/health/healthcheck.sh [-t timeout_s] [-w warn_ms] [-d cert_days] URL...
#   scripts/health/healthcheck.sh https://www.navmarket.lan/health.json http://<VPS_IP>/
set -uo pipefail

timeout=5 warn_ms=800 cert_days=14 worst=0

usage() { echo "Usage: $0 [-t timeout_s] [-w warn_ms] [-d cert_days] URL..." >&2; exit 2; }
while getopts "t:w:d:h" opt; do
  case $opt in
    t) timeout=$OPTARG ;; w) warn_ms=$OPTARG ;; d) cert_days=$OPTARG ;; *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || usage

# report LEVEL URL MESSAGE: prints one line and keeps the worst level
report() {
  local code=0
  case $1 in WARNING) code=1 ;; CRITICAL) code=2 ;; esac
  (( code > worst )) && worst=$code
  printf '%-8s %s - %s\n' "$1" "$2" "$3"
}

check_url() {
  local url=$1 body out rc http secs ms
  body=$(mktemp)
  out=$(curl -s -o "$body" -m "$timeout" -w '%{http_code} %{time_total}' "$url"); rc=$?
  read -r http secs <<< "$out"
  ms=$(awk -v s="$secs" 'BEGIN{printf "%d", s*1000}')

  if [ "$http" = "000" ]; then
    report CRITICAL "$url" "no HTTP answer (curl error $rc: 6 = DNS, 7 = refused, 28 = timeout, 60 = certificate)"
  elif [ "$http" != "200" ]; then
    report CRITICAL "$url" "HTTP $http"
  elif [[ $url == *health.json ]] && ! grep -qE '"status": *"ok"' "$body"; then
    report CRITICAL "$url" "health.json does not say \"status\": \"ok\""
  elif (( ms > warn_ms )); then
    report WARNING "$url" "slow: ${ms} ms (limit ${warn_ms} ms)"
  else
    report OK "$url" "HTTP 200 in ${ms} ms"
  fi
  rm -f "$body"
}

check_cert() {
  local url=$1 hostport host end left
  hostport=${url#https://}; hostport=${hostport%%/*}; host=${hostport%%:*}
  [[ $hostport == *:* ]] || hostport="$hostport:443"
  end=$(echo | timeout "$timeout" openssl s_client -connect "$hostport" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$end" ]; then report CRITICAL "$url" "no TLS certificate read"; return; fi
  left=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
  if (( left < 0 )); then report CRITICAL "$url" "certificate EXPIRED"
  elif (( left < cert_days )); then report WARNING "$url" "certificate expires in $left days"
  else report OK "$url" "certificate valid for $left more days"; fi
}

for url in "$@"; do
  check_url "$url"
  [[ $url == https://* ]] && check_cert "$url"
done
exit "$worst"
