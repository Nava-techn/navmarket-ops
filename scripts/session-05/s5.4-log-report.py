#!/usr/bin/env python3
"""Nginx access log analysis with a JSON export (Session 5, lab S5.4).

The Python version of scripts/session-02/s2.5-nginx-report.sh (S2.5): reads Nginx logs in
the default "combined" format, plain or .gz, and writes a JSON report.

Usage:
    sudo python3 log_report.py /var/log/nginx/access.log*            # JSON on screen
    sudo python3 log_report.py /var/log/nginx/access.log* -o r.json --top 5 --mask

--mask hides the last part of each IP address (for reports that go to Git).
Exit codes: 0 OK, 2 no readable file.
"""
import argparse
import gzip
import json
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

# 1.2.3.4 - - [10/Nov/2026:17:03:54 +0000] "GET /index.html HTTP/1.1" 200 512 "-" "curl/8.5"
LINE = re.compile(
    r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>[A-Z]+) (?P<path>\S+) [^"]*" '
    r'(?P<status>\d{3}) (?P<bytes>\d+|-) "[^"]*" "(?P<agent>[^"]*)"'
)
# Paths that only scanners ask for on a static shop
SUSPICIOUS = re.compile(r"wp-|\.php|\.env|\.git|phpmyadmin|cgi-bin|/admin", re.I)


def open_log(path: Path):
    return gzip.open(path, "rt", errors="replace") if path.suffix == ".gz" else path.open(errors="replace")


def mask(ip: str) -> str:
    return re.sub(r"\.\d+$", ".x", ip) if "." in ip else ip.rsplit(":", 2)[0] + ":x"


def analyse(files: list[Path], top: int, hide: bool) -> dict:
    status, ips, paths, hours, bad_paths = Counter(), Counter(), Counter(), Counter(), Counter()
    total = unparsed = sent = 0
    first = last = None
    for f in files:
        with open_log(f) as fh:
            for raw in fh:
                m = LINE.match(raw)
                if not m:
                    unparsed += 1
                    continue
                total += 1
                ip = mask(m["ip"]) if hide else m["ip"]
                t = datetime.strptime(m["time"], "%d/%b/%Y:%H:%M:%S %z")
                first = t if first is None or t < first else first
                last = t if last is None or t > last else last
                status[m["status"]] += 1
                ips[ip] += 1
                paths[m["path"].split("?")[0]] += 1
                hours[t.strftime("%H:00")] += 1
                sent += 0 if m["bytes"] == "-" else int(m["bytes"])
                if SUSPICIOUS.search(m["path"]):
                    bad_paths[m["path"]] += 1
    errors = sum(n for s, n in status.items() if s[0] in "45")
    return {
        "files": [str(f) for f in files],
        "period": {"from": first.isoformat() if first else None, "to": last.isoformat() if last else None},
        "requests": total,
        "unparsed_lines": unparsed,
        "bytes_sent": sent,
        "error_rate_percent": round(100 * errors / total, 1) if total else 0,
        "status_codes": dict(sorted(status.items())),
        "top_ips": ips.most_common(top),
        "top_paths": paths.most_common(top),
        "requests_per_hour": dict(sorted(hours.items())),
        "suspicious_requests": sum(bad_paths.values()),
        "top_suspicious_paths": bad_paths.most_common(top),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Nginx access log report in JSON")
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("-o", "--output", help="JSON file to write (default: screen)")
    ap.add_argument("--top", type=int, default=5)
    ap.add_argument("--mask", action="store_true", help="hide the end of IP addresses")
    args = ap.parse_args()

    files = sorted((f for f in args.files if f.is_file()), key=lambda f: f.stat().st_mtime)  # oldest first
    if not files:
        print("ERROR: no readable log file", file=sys.stderr)
        return 2
    text = json.dumps(analyse(files, args.top, args.mask), indent=2)
    if args.output:
        Path(args.output).write_text(text + "\n")
        print(f"Written: {args.output}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
