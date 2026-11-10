#!/usr/bin/env python3
"""Navatech product inventory (Session 5, lab S5.3).

Reads a CSV of products (sku, name, category, price, stock, reorder_level),
checks every row, then prints a report, the products to reorder, or a JSON export.

Usage:
    python3 scripts/python/inventory.py report
    python3 scripts/python/inventory.py low
    python3 scripts/python/inventory.py json -o inventory.json
    python3 scripts/python/inventory.py --file other.csv report

Exit codes: 0 OK, 1 invalid rows found (they are skipped and listed on stderr),
2 file missing or unreadable.
"""
import argparse
import csv
import json
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

DEFAULT_FILE = Path(__file__).parent / "data" / "inventory.csv"
COLUMNS = ["sku", "name", "category", "price", "stock", "reorder_level"]


@dataclass
class Product:
    sku: str
    name: str
    category: str
    price: float
    stock: int
    reorder_level: int

    @property
    def value(self) -> float:
        """Money tied up in stock for this product."""
        return self.price * self.stock

    @property
    def to_reorder(self) -> bool:
        return self.stock <= self.reorder_level


def load(path: Path) -> tuple[list[Product], list[str]]:
    """Return the valid products and one error message per invalid row."""
    products, errors, seen = [], [], set()
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames != COLUMNS:
            raise ValueError(f"expected columns {COLUMNS}, got {reader.fieldnames}")
        for line, row in enumerate(reader, start=2):      # line 1 is the header
            try:
                p = Product(row["sku"].strip(), row["name"].strip(), row["category"].strip(),
                            float(row["price"]), int(row["stock"]), int(row["reorder_level"]))
                if not p.sku or p.price < 0 or p.stock < 0:
                    raise ValueError("empty sku or negative number")
                if p.sku in seen:
                    raise ValueError(f"duplicate sku {p.sku}")
            except (ValueError, TypeError, AttributeError) as e:
                errors.append(f"line {line}: {e}")
                continue
            seen.add(p.sku)
            products.append(p)
    return products, errors


def report(products: list[Product]) -> None:
    cats: dict[str, list[Product]] = {}
    for p in products:
        cats.setdefault(p.category, []).append(p)
    print(f"{'category':<12}{'products':>9}{'units':>8}{'stock value':>14}")
    for cat in sorted(cats):
        items = cats[cat]
        print(f"{cat:<12}{len(items):>9}{sum(p.stock for p in items):>8}"
              f"{sum(p.value for p in items):>13.2f}€")
    print(f"{'TOTAL':<12}{len(products):>9}{sum(p.stock for p in products):>8}"
          f"{sum(p.value for p in products):>13.2f}€")


def low(products: list[Product]) -> None:
    rows = sorted((p for p in products if p.to_reorder), key=lambda p: p.stock)
    if not rows:
        print("Nothing to reorder.")
    for p in rows:
        flag = "OUT OF STOCK" if p.stock == 0 else "low"
        print(f"{p.sku:<14}{p.name:<28} stock {p.stock:>3} / reorder at {p.reorder_level:<4} {flag}")


def export(products: list[Product], out: str | None) -> None:
    data = {
        "products": [asdict(p) | {"value": round(p.value, 2), "to_reorder": p.to_reorder}
                     for p in products],
        "total_value": round(sum(p.value for p in products), 2),
    }
    text = json.dumps(data, indent=2, ensure_ascii=False)
    if out:
        Path(out).write_text(text + "\n", encoding="utf-8")
        print(f"Written: {out} ({len(products)} products)")
    else:
        print(text)


def main() -> int:
    ap = argparse.ArgumentParser(description="Navatech product inventory")
    ap.add_argument("--file", type=Path, default=DEFAULT_FILE, help="CSV file to read")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("report", help="units and stock value per category")
    sub.add_parser("low", help="products at or under their reorder level")
    j = sub.add_parser("json", help="export everything as JSON")
    j.add_argument("-o", "--output", help="file to write (default: screen)")
    args = ap.parse_args()

    try:
        products, errors = load(args.file)
    except (OSError, ValueError) as e:
        print(f"ERROR: {args.file}: {e}", file=sys.stderr)
        return 2
    {"report": report, "low": low}.get(args.cmd, lambda p: export(p, args.output))(products)
    for err in errors:
        print(f"SKIPPED {err}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
