from __future__ import annotations

import csv
import json
import argparse
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path.cwd()
MAP = ROOT / "taxonomy_v2_migration_map.csv"
SOURCE_LIMITED = "SOURCE_LIMITED_NO_LOCAL_PDF"


def tracked(path: str) -> bool:
    result = subprocess.run(["git", "-C", str(ROOT), "ls-files", "--error-unmatch", "--", path], capture_output=True, text=True)
    return result.returncode == 0


def move(old: str, new: str) -> None:
    target = ROOT / new
    target.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(["git", "-C", str(ROOT), "mv", "--", old, new], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"git mv failed: {old} -> {new}\n{result.stderr}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--notes-only", action="store_true")
    args = parser.parse_args()
    with MAP.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    if len(rows) != 169:
        raise SystemExit(f"expected 169 migration rows; got {len(rows)}")
    if len({r['Paper_ID'] for r in rows}) != 169:
        raise SystemExit("duplicate Paper_ID in migration map")
    note_moves = [(r["Old_Note_Path"], r["New_Note_Path"]) for r in rows]
    pdf_groups: dict[str, set[str]] = defaultdict(set)
    for r in rows:
        if r["Old_PDF_Path"] != SOURCE_LIMITED:
            pdf_groups[r["Old_PDF_Path"]].add(r["New_PDF_Path"])
    if any(len(targets) != 1 for targets in pdf_groups.values()):
        raise SystemExit("a shared PDF source maps to more than one target")
    pdf_moves = [(old, next(iter(targets))) for old, targets in pdf_groups.items()]
    # Precheck every path before the first move, to avoid a partial move from a
    # missing source or untracked corpus asset.
    errors = []
    active_moves = note_moves if args.notes_only else [*pdf_moves, *note_moves]
    for old, new in active_moves:
        if not (ROOT / old).is_file():
            errors.append(f"missing source: {old}")
        if (ROOT / new).exists():
            errors.append(f"target already exists: {new}")
        if not tracked(old):
            errors.append(f"untracked source; refusing non-git move: {old}")
    if errors:
        raise SystemExit("\n".join(errors))
    if not args.notes_only:
        for old, new in pdf_moves:
            move(old, new)
    for old, new in note_moves:
        move(old, new)
    print(json.dumps({"pdf_dirs_moved": len(pdf_moves), "notes_moved": len(note_moves), "source_limited": sum(r['Old_PDF_Path'] == SOURCE_LIMITED for r in rows)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
