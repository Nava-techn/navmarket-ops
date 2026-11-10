#!/usr/bin/env bash
# Created in Session 5, lab S5.1: idempotent deploy of the storefront (site/), shellcheck clean.
# It automates the manual "atomic swap" of S1.5, with releases and an automatic rollback.
#
# Usage (from the repo root):
#   scripts/deploy/deploy-storefront.sh [-r web_root] [-k releases_to_keep] [-u health_url] <ssh-host>
#   scripts/deploy/deploy-storefront.sh vps01
#   scripts/deploy/deploy-storefront.sh -r /var/www/navmarket srv01
#
# On the server:
#   /srv/navmarket-releases/v1.0.0-3f2a9c1/   one folder per release (version + Git commit)
#   /srv/navmarket -> navmarket-releases/...  a symlink: Nginx serves the live release
#
# Idempotent: run it twice with the same commit and the second run changes nothing.
# Safe: the symlink is switched atomically; if the health check fails, the previous
# release comes back automatically. Exit codes: 0 deployed or nothing to do, 1 failed.
set -euo pipefail

root=/srv/navmarket keep=3 url=http://127.0.0.1/health.json
usage() { echo "Usage: $0 [-r web_root] [-k keep] [-u health_url] <ssh-host>" >&2; exit 1; }
while getopts "r:k:u:h" opt; do
  case $opt in r) root=$OPTARG ;; k) keep=$OPTARG ;; u) url=$OPTARG ;; *) usage ;; esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage
host=$1

[ -f site/health.json ] || { echo "Run me from the repo root (site/ not found)" >&2; exit 1; }
version=$(grep -oP '"version":\s*"\K[^"]+' site/health.json)
commit=$(git rev-parse --short HEAD)
git diff --quiet HEAD -- site || commit="$commit-dirty"   # uncommitted changes are visible in the name
release="v$version-$commit"
echo "Deploying $release to $host:$root"

# The part that runs on the server, as root. Arguments: release root keep url version
remote() {
  set -euo pipefail
  local release=$1 root=$2 keep=$3 url=$4 version=$5
  local releases=$root-releases new=$root-releases/$release prev=""

  if [ "$(readlink -f "$root")" = "$new" ]; then
    echo "Already live: $release. Nothing to do."; rm -f "/tmp/$release.tgz"; return 0
  fi
  install -d -m 755 "$releases"
  if [ ! -d "$new" ]; then                         # unpack next to the live site, rights included
    rm -rf "$new.tmp"; mkdir -p "$new.tmp"
    tar -xzf "/tmp/$release.tgz" -C "$new.tmp"
    chown -R root:root "$new.tmp"
    find "$new.tmp" -type d -exec chmod 755 {} +
    find "$new.tmp" -type f -exec chmod 644 {} +
    mv "$new.tmp" "$new"
  fi
  rm -f "/tmp/$release.tgz"

  if [ -L "$root" ]; then
    prev=$(readlink -f "$root")
  elif [ -d "$root" ]; then                        # first run: the old folder becomes a release
    prev=$releases/legacy-$(date +%Y%m%d-%H%M%S)
    mv "$root" "$prev"
  fi
  ln -sfn "$new" "$root.next" && mv -T "$root.next" "$root"   # atomic switch
  echo "Live: $root -> $new"

  sleep 1
  if curl -fsS -m 5 "$url" | grep -q "\"version\": *\"$version\""; then
    echo "Health check OK: $url reports version $version"
  else
    echo "Health check FAILED on $url"
    if [ -n "$prev" ]; then
      ln -sfn "$prev" "$root.next" && mv -T "$root.next" "$root"
      echo "Rolled back to $prev"
    fi
    return 1
  fi

  # keep the newest releases, never the live one
  find "$releases" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2- \
    | grep -vxF "$new" | tail -n +"$keep" | xargs -r rm -rf
  echo "Releases kept:"; ls -1t "$releases"
}

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
tar -czf "$tmp/$release.tgz" -C site .
{ declare -f remote; echo 'remote "$@"'; } > "$tmp/deploy-remote.sh"
scp -q "$tmp/$release.tgz" "$tmp/deploy-remote.sh" "$host:/tmp/"
# -t: sudo can ask for a password (srv01); on vps01 sudo needs none
ssh -t "$host" "sudo bash /tmp/deploy-remote.sh '$release' '$root' '$keep' '$url' '$version'; rc=\$?; rm -f /tmp/deploy-remote.sh; exit \$rc"
