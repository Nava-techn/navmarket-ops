#!/usr/bin/env bash
# S2.3 - Nightly backup of the NavMarket storefront and its Nginx site, 7 days kept.
# Run by cron (/etc/cron.d/navmarket-backup) as root.
set -euo pipefail

DEST=/var/backups/navmarket
KEEP_DAYS=7
STAMP=$(date +%F_%H%M)
ARCHIVE="$DEST/navmarket-$STAMP.tar.gz"

mkdir -p "$DEST"
chmod 700 "$DEST"                       # backups may contain config: root only

# -C / : store relative paths (srv/navmarket, not /srv/navmarket)
tar -czf "$ARCHIVE" -C / srv/navmarket etc/nginx/sites-available/navmarket

# Retention: delete archives older than KEEP_DAYS days (mtime +6 = 7 days or more)
deleted=$(find "$DEST" -name 'navmarket-*.tar.gz' -mtime +$((KEEP_DAYS - 1)) -print -delete | wc -l)

logger -t navmarket-backup "created $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1)), deleted $deleted old archive(s)"
