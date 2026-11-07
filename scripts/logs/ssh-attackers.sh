#!/usr/bin/env bash
# S2.6 - Top 10 IPs attacking SSH, and the user names they try.
# Reads auth.log (current + rotated), or the ssh journal if there is no auth.log. Run with sudo.
set -u
if ls /var/log/auth.log* >/dev/null 2>&1; then
  # oldest file first (ls -tr), so the lines come in time order
  read_auth() { zcat -f $(ls -tr /var/log/auth.log*); }
else
  read_auth() { journalctl -u ssh --no-pager; }
fi
# Failed or aborted logins: unknown users, refused keys, connections closed before login
attempts() { read_auth | grep -E 'Invalid user|Failed (password|publickey)|\[preauth\]'; }

echo "## Period: $(attempts | head -1 | cut -c1-15) -> $(attempts | tail -1 | cut -c1-15)"
echo "## Failed or aborted login lines: $(attempts | wc -l)"
echo "## Different source IPs: $(attempts | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | wc -l)"

echo; echo "## Top 10 attacking IPs"
attempts | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn | head -10

echo; echo "## Top 10 user names tried"
read_auth | grep -oE 'Invalid user [^ ]+' | awk '{print $3}' | sort | uniq -c | sort -rn | head -10
