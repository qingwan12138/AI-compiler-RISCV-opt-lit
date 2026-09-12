from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path.cwd()
MAP = ROOT / "taxonomy_v2_migration_map.csv"
ARCHIVE = ROOT / "archive" / "taxonomy_v1" / "00_分类索引_v1_legacy.md"
LINK = re.compile(r"(?<!!)\[([^\]]*)\]\((?:<([^>]+)>|([^\s)]+)(\s+[^)]*)?)\)")
SKIP = ("#", "http://", "https://", "mailto:", "tel:", "data:")


def rel_link(source: Path, target: Path, wrapped: bool) -> str:
    value = Path(__import__('os').path.relpath(target, source.parent)).as_posix()
    return f"<{value}>" if wrapped or " " in value else value


def main() -> None:
    with MAP.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    old_to_new = {}
    for row in rows:
        old_to_new[row["Old_Note_Path"]] = row["New_Note_Path"]
        if row["Old_PDF_Path"] != "SOURCE_LIMITED_NO_LOCAL_PDF":
            old_to_new[row["Old_PDF_Path"]] = row["New_PDF_Path"]
    changed_files = 0
    replacements = 0
    for source in ROOT.rglob("*.md"):
        if any(part in {".git", ".worktrees"} for part in source.parts) or source == ARCHIVE:
            continue
        text = source.read_text(encoding="utf-8", errors="replace")
        def replace(match: re.Match[str]) -> str:
            nonlocal replacements
            label, bracketed, bare, suffix = match.groups()
            dest = (bracketed or bare or "").strip()
            if not dest or dest.startswith(SKIP):
                return match.group(0)
            base_dest, anchor = (dest.split("#", 1) + [""])[:2] if "#" in dest else (dest, "")
            resolved = (source.parent / base_dest).resolve()
            try:
                old_rel = resolved.relative_to(ROOT.resolve()).as_posix()
            except ValueError:
                return match.group(0)
            new_rel = old_to_new.get(old_rel)
            if not new_rel:
                return match.group(0)
            replacements += 1
            new_dest = rel_link(source, ROOT / new_rel, bracketed is not None)
            if anchor:
                new_dest += "#" + anchor
            return f"[{label}]({new_dest}{suffix or ''})"
        rewritten = LINK.sub(replace, text)
        if rewritten != text:
            source.write_text(rewritten, encoding="utf-8")
            changed_files += 1
    print(f"changed_files={changed_files}; rewritten_links={replacements}")


if __name__ == "__main__":
    main()
