#!/usr/bin/env python3
"""Audit repository-local Markdown links without modifying documents.

Use --baseline before a migration and --report after it.  Links inside the
immutable v1 archive are reported separately and never treated as migration
regressions, because the archive deliberately preserves original content.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"(?<!!)\[[^\]]*\]\((?:<([^>]+)>|([^\s)]+)(?:\s+[^)]*)?)\)")
SKIP_PREFIXES = ("#", "http://", "https://", "mailto:", "tel:", "data:")
ARCHIVE_PREFIX = "archive/taxonomy_v1/"


def key(source: Path, destination: str) -> str:
    return f"{source.relative_to(ROOT).as_posix()}::{destination}"


def scan() -> tuple[list[dict], int]:
    broken: list[dict] = []
    total = 0
    for source in ROOT.rglob("*.md"):
        if any(part in {".git", ".worktrees"} for part in source.parts):
            continue
        text = source.read_text(encoding="utf-8", errors="replace")
        for match in LINK.finditer(text):
            destination = (match.group(1) or match.group(2) or "").strip()
            if not destination or destination.startswith(SKIP_PREFIXES):
                continue
            destination = destination.split("#", 1)[0]
            if not destination:
                continue
            total += 1
            target = (source.parent / destination).resolve()
            try:
                target.relative_to(ROOT.resolve())
            except ValueError:
                continue
            if not target.exists():
                broken.append({"key": key(source, destination), "source": source.relative_to(ROOT).as_posix(), "destination": destination})
    return broken, total


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    broken, total = scan()
    current = {item["key"] for item in broken}
    baseline: set[str] = set()
    if args.baseline and args.baseline.is_file():
        payload = json.loads(args.baseline.read_text(encoding="utf-8"))
        baseline = set(payload.get("broken_keys", []))
    archive = [item for item in broken if item["source"].startswith(ARCHIVE_PREFIX)]
    enforceable = [item for item in broken if item not in archive]
    introduced = sorted(set(item["key"] for item in enforceable) - baseline)
    payload = {"total_local_relative_links": total, "broken": broken, "broken_keys": sorted(current), "archive_exempt": archive, "migration_introduced": introduced}
    creating_baseline = args.baseline and not args.baseline.exists()
    if creating_baseline:
        args.baseline.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        baseline = current
        introduced = []
    if args.report:
        md = "# taxonomy v2 link validation report\n\n"
        md += f"- Local relative Markdown links scanned: **{total}**\n"
        md += f"- Current broken links: **{len(broken)}**\n"
        md += f"- Legacy archive exemptions: **{len(archive)}**\n"
        md += f"- Migration-introduced broken links: **{len(introduced)}**\n\n"
        md += "## Migration-introduced broken links\n\n"
        md += "None.\n" if not introduced else "\n".join(f"- `{item}`" for item in introduced) + "\n"
        md += "\n## Current broken-link inventory\n\n"
        md += "| Source | Destination | Status |\n|---|---|---|\n"
        for item in broken:
            status = "LEGACY_ARCHIVE_EXEMPT" if item in archive else ("MIGRATION_INTRODUCED" if item["key"] in introduced else "PRE_EXISTING_BROKEN")
            md += f"| `{item['source']}` | `{item['destination']}` | {status} |\n"
        args.report.write_text(md, encoding="utf-8")
    print(json.dumps({"links": total, "broken": len(broken), "archive_exempt": len(archive), "introduced": len(introduced)}, ensure_ascii=False))
    return 0 if not introduced else 1


if __name__ == "__main__":
    raise SystemExit(main())
