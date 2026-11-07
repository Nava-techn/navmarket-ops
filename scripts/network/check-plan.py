#!/usr/bin/env python3
"""S3.1 - Check the NavMarket addressing plan: inside 10.10.0.0/16, no overlap."""
import ipaddress
import itertools
import sys

PLAN = {
    "Management": "10.10.0.0/24",
    "Lab LAN A": "10.10.1.0/24",
    "Lab LAN B": "10.10.2.0/24",
    "Web (DMZ)": "10.10.10.0/24",
    "Application": "10.10.20.0/24",
    "Data": "10.10.30.0/24",
    "Monitoring": "10.10.40.0/24",
    "Office": "10.10.100.0/22",
    "VPN": "10.10.200.0/24",
    "Transit": "10.10.255.0/30",
}
SUPERNET = ipaddress.ip_network("10.10.0.0/16")
nets = {zone: ipaddress.ip_network(cidr) for zone, cidr in PLAN.items()}  # strict: rejects bad boundaries
ok = True

print(f"{'Zone':<12} {'Subnet':<16} {'Hosts':>6}  {'First host':<14} {'Last host':<14} Broadcast")
for zone, net in nets.items():
    hosts = list(net.hosts())
    print(f"{zone:<12} {str(net):<16} {len(hosts):>6}  {str(hosts[0]):<14} {str(hosts[-1]):<14} {net.broadcast_address}")
    if not net.subnet_of(SUPERNET):
        print(f"ERROR: {zone} is outside {SUPERNET}")
        ok = False

for (a, na), (b, nb) in itertools.combinations(nets.items(), 2):
    if na.overlaps(nb):
        print(f"ERROR: {a} {na} overlaps {b} {nb}")
        ok = False

used = sum(n.num_addresses for n in nets.values())
print(f"\nAddresses planned: {used} of {SUPERNET.num_addresses} ({used * 100 / SUPERNET.num_addresses:.1f} %), the rest is reserved")
print("RESULT: OK, all subnets inside 10.10.0.0/16, no overlap" if ok else "RESULT: ERRORS FOUND")
sys.exit(0 if ok else 1)
