#!/usr/bin/env bash
# S2.5 - Top client IPs and top 404 URLs from the Nginx access logs.
# Reads the current log and the rotated ones (.1, .2.gz...). Run with sudo.
set -u
# oldest file first (ls -tr), so the lines come in time order
read_logs() { zcat -f $(ls -tr /var/log/nginx/access.log*); }

echo "## Log files"
ls -l /var/log/nginx/access.log*
echo; echo "## Requests analysed: $(read_logs | wc -l)"

echo; echo "## Status codes"
read_logs | awk '{print $9}' | sort | uniq -c | sort -rn

echo; echo "## Top 10 client IPs"
read_logs | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

echo; echo "## Top 10 URLs answered 404"
read_logs | awk '$9 == 404 {print $7}' | sort | uniq -c | sort -rn | head -10
