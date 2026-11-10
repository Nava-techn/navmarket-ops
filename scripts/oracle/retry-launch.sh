#!/usr/bin/env bash
# Retry creating an Oracle Cloud Always Free instance until capacity is available.
# Lab S1.5 (NavMarket). Settings are read from a private .env file, never stored here.
# Usage: ./retry-launch.sh   (or ENV_FILE=/path/to/file.env ./retry-launch.sh)
set -u

ENV_FILE="${ENV_FILE:-$HOME/oci-retry/navmarket.env}"
# shellcheck source=/dev/null
source "$ENV_FILE"                        # loads COMPARTMENT_ID, AD, SUBNET_ID, IMAGE_A1, IMAGE_E2

NAME="${NAME:-navmarket-vps01}"
SSH_PUBKEY="${SSH_PUBKEY:-$HOME/.ssh/navmarket_vps.pub}"
WAIT="${WAIT:-300}"                       # seconds between rounds: 5 minutes, polite to the API

log() { echo "$(date '+%F %T') $*"; }

launch() {                                # $1 = shape, $2 = image, $3 = shape config (optional)
  local extra=()
  [ -n "${3:-}" ] && extra=(--shape-config "$3")
  oci compute instance launch --compartment-id "$COMPARTMENT_ID" \
    --availability-domain "$AD" --subnet-id "$SUBNET_ID" \
    --shape "$1" --image-id "$2" "${extra[@]}" \
    --display-name "$NAME" --assign-public-ip true \
    --ssh-authorized-keys-file "$SSH_PUBKEY" 2>&1
}

success() {
  log "SUCCESS with $1"
  command -v notify-send >/dev/null && notify-send "Oracle Cloud" "$NAME created ($1)"
  exit 0
}

check() {                                 # retry only on capacity / rate-limit errors
  if echo "$1" | grep -qiE "capacity|TooManyRequests"; then
    log "$2: no capacity, next try in ${WAIT}s"
  else
    log "$2: unexpected error, stopping:"
    echo "$1"
    exit 1
  fi
}

while true; do
  # Safety: never create a second instance
  if ! count=$(oci compute instance list -c "$COMPARTMENT_ID" --display-name "$NAME" \
       --query "length(data[?\"lifecycle-state\"!='TERMINATED'])" --raw-output 2>&1); then
    log "list failed (network?), retry later"
    sleep "$WAIT"
    continue
  fi
  if [ "${count:-0}" != "0" ]; then
    log "$NAME already exists, nothing to do"
    exit 0
  fi

  if out=$(launch VM.Standard.A1.Flex "$IMAGE_A1" '{"ocpus":1,"memoryInGBs":6}'); then success A1; fi
  check "$out" A1

  if [ -n "${IMAGE_E2:-}" ]; then         # E2 only if its image ID is set
    if out=$(launch VM.Standard.E2.1.Micro "$IMAGE_E2"); then success E2; fi
    check "$out" E2
  fi

  sleep "$WAIT"
done
