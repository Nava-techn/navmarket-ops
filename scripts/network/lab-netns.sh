#!/usr/bin/env bash
# S3.2 to S3.4 - A small network lab built with Linux network namespaces.
# Each namespace = an isolated network stack (interfaces, IPs, routes), like a mini machine.
#
#   lan-a (10.10.1.10) --veth-- router (10.10.1.1 | 10.10.2.1) --veth-- lan-b (10.10.2.10)
#
# Usage: sudo bash lab-netns.sh up | down | status
# "up" creates the namespaces, links and addresses only: routes and forwarding are
# added by hand during the lab, to see what each one changes.
set -euo pipefail

up() {
  for ns in lan-a router lan-b; do ip netns add "$ns"; ip -n "$ns" link set lo up; done

  # A veth pair is a virtual cable: what goes in one end comes out of the other
  ip link add veth-a type veth peer name r-a
  ip link add veth-b type veth peer name r-b
  ip link set veth-a netns lan-a;  ip link set r-a netns router
  ip link set veth-b netns lan-b;  ip link set r-b netns router

  ip -n lan-a  addr add 10.10.1.10/24 dev veth-a   # client in Lab LAN A (S3.1 plan)
  ip -n router addr add 10.10.1.1/24  dev r-a      # router, gateway of LAN A
  ip -n router addr add 10.10.2.1/24  dev r-b      # router, gateway of LAN B
  ip -n lan-b  addr add 10.10.2.10/24 dev veth-b   # server in Lab LAN B

  ip -n lan-a link set veth-a up; ip -n router link set r-a up
  ip -n router link set r-b up;   ip -n lan-b link set veth-b up
  echo "lab up"
}

down() {
  for ns in lan-a router lan-b; do ip netns del "$ns" 2>/dev/null || true; done   # deleting a namespace deletes its veths
  echo "lab down"
}

status() {
  for ns in lan-a router lan-b; do
    echo "== $ns"; ip -n "$ns" -br addr; ip -n "$ns" route
  done
}

case "${1:-}" in
  up) up ;; down) down ;; status) status ;;
  *) echo "usage: $0 up|down|status"; exit 1 ;;
esac
