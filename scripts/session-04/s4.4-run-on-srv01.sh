#!/usr/bin/env bash
# Created in Session 4 (S4.4). Used by every server-side lab from S4.4 on.
# Copies a lab script to a server, runs it with sudo (password asked once,
# visibly), then brings the proofs file back into docs/ with the IP masked.
#
# Usage (from the repo root):  scripts/session-04/s4.4-run-on-srv01.sh <script> <proofs-path> [host] [VAR=value ...]
#   scripts/session-04/s4.4-run-on-srv01.sh scripts/session-04/s4.4-firewall.sh docs/session-04/S4.4-proofs.txt
set -euo pipefail

script=${1:?script to run}
proofs=${2:?local proofs file}
host=${3:-srv01}
name=$(basename "$script")
vars="${*:4}"            # extra VAR=value settings passed to the script (S4.6)
ip=$(ssh -G "$host" | awk '/^hostname /{print $2}')

scp -q "$script" "$host:/tmp/$name"
ssh -t "$host" "sudo PROOFS=/tmp/$name.proofs $vars bash /tmp/$name; rm -f /tmp/$name"
scp -q "$host:/tmp/$name.proofs" "$proofs"
sed -i "s/${ip//./\\.}/<VM_IP>/g" "$proofs"
echo "Proofs saved: $proofs"
