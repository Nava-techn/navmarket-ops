# Session 5 - Scripting: Bash and Python for operations

**Session 5 / 24 · Automation 1** · One file for the whole session.

| Lab | What | Script | Status |
| --- | --- | --- | --- |
| S5.1 | Idempotent deploy, shellcheck clean | `scripts/deploy/deploy-storefront.sh` | written + tested, to run on servers |
| S5.2 | Health check with an exit code | `scripts/health/healthcheck.sh` | written + tested, to run |
| S5.3 | Navatech product inventory in Python | `scripts/python/inventory.py` | written + tested |
| S5.4 | Log analysis in Python, JSON export | `scripts/python/log_report.py` | written + tested, to run on real logs |

Tested on 10 Nov in a sandbox (sample data, local web servers). The proofs below must come from **my** servers.

---

## S5.1 Idempotent deploy: `deploy-storefront.sh`

**Idempotent** = running it twice gives the same result as once. The second run says *"Already live, nothing to do"*. That is what makes automation safe to re-run (CI, Ansible in session 6).

How it works:

1. Release name = version from `health.json` + Git commit (`v1.0.0-3f2a9c1`, `-dirty` if `site/` has uncommitted changes).
2. Upload a `.tgz`, unpack into `/srv/navmarket-releases/<release>`, rights set **before** going live.
3. `/srv/navmarket` becomes a **symlink**; `ln -sfn` + `mv -T` switch it **atomically** (better than the 2 `mv` of S1.5).
4. Health check: `health.json` must report the new version, otherwise **automatic rollback** and exit `1`.
5. Keeps the 3 newest releases (never deletes the live one).

Good Bash habits used: `set -euo pipefail`, `getopts`, quoted variables, `trap` cleanup, a function sent to the server with `declare -f`, `shellcheck` with **0 warnings**.

```bash
shellcheck scripts/deploy/deploy-storefront.sh          # nothing printed = clean
scripts/deploy/deploy-storefront.sh vps01               # 1st run: deploys
scripts/deploy/deploy-storefront.sh vps01               # 2nd run: "Nothing to do"
scripts/deploy/deploy-storefront.sh -r <srv01 root> srv01
```

## S5.2 Health check: `healthcheck.sh`

Per URL: HTTP `200`, `"status": "ok"` in `health.json`, response time, days left on the HTTPS certificate.

| Exit code | Meaning | Used by |
| --- | --- | --- |
| `0` | OK | cron, CI, monitoring (session 15) |
| `1` | WARNING (slow, certificate < 14 days) | |
| `2` | CRITICAL (down, wrong answer, expired) | |

```bash
scripts/health/healthcheck.sh https://www.navmarket.lan/health.json http://<VPS_IP>/health.json; echo "exit code: $?"
```

Sandbox test: `OK ... HTTP 200 in 3 ms` / `CRITICAL ... HTTP 404` → exit `2`; certificate check `valid for 396 more days`.

## S5.3 Inventory in Python: `inventory.py`

Reads `scripts/python/data/inventory.csv` (the 12 storefront products + stock), **checks every row** (bad numbers, duplicates: skipped and listed, exit `1`).

```bash
python3 scripts/python/inventory.py report        # units and stock value per category
python3 scripts/python/inventory.py low           # what to reorder
python3 scripts/python/inventory.py json -o /tmp/inventory.json
```

Sandbox output: 12 products, 589 units, **23,146 €** of stock; to reorder: Glide mouse (**out of stock**), Volt 20K, Nava Buds.

Python used: `argparse` sub-commands, `csv.DictReader`, `dataclass`, type hints, `json`, exit codes.

## S5.4 Log analysis: `log_report.py`

The Python version of `nginx-report.sh` (S2.5): `.log` and `.gz`, oldest first, regex on the "combined" format.
JSON: period, requests, status codes, error rate, top IPs, top paths, requests per hour, **suspicious paths** (`wp-`, `.php`, `.env`, `.git`...). `--mask` hides the end of IPs before anything goes to Git.

```bash
scp scripts/python/log_report.py srv01:/tmp/
ssh -t srv01 'sudo python3 /tmp/log_report.py /var/log/nginx/access.log* --mask -o /tmp/S5.4-report.json'
scp srv01:/tmp/S5.4-report.json docs/session-05/
```

**Bash or Python?** Bash to chain commands (S2.5). Python as soon as there is parsing, data structures or JSON: easier to read, test and extend.

---

## What I learned

- Idempotent + atomic + health check + rollback = a deploy I can run without fear.
- Exit codes are the language between scripts, cron and CI.
- shellcheck catches Bash bugs before they hit a server.
- Python for data: validate the input, keep going on bad rows, report them, export JSON.
