from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path.cwd()


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


rows = list(csv.DictReader((ROOT / "taxonomy_v2.csv").open(encoding="utf-8-sig")))
manifest = json.loads((ROOT / "taxonomy_v2_pre_migration_manifest.json").read_text(encoding="utf-8"))
pdfs = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob("paper.pdf")}
referenced = {r["Old_PDF_Path"] for r in rows if r["Old_PDF_Path"] != "SOURCE_LIMITED_NO_LOCAL_PDF"}
unmapped = sorted(pdfs - referenced)
old_counts = Counter(r["Old_Category"] for r in rows)
primary = Counter(r["Primary_Category"] for r in rows)
secondary = Counter(r["Secondary_Category"] for r in rows)
review = [r for r in rows if r["Needs_Review"] == "YES"]
shared = defaultdict(list)
for row in rows:
    if row["Old_PDF_Path"] != "SOURCE_LIMITED_NO_LOCAL_PDF":
        shared[row["Old_PDF_Path"]].append(row["Paper_ID"])
shared_groups = {path: ids for path, ids in shared.items() if len(ids) > 1}

orphan_hashes = [{"path": path, "sha256": sha256(ROOT / path)} for path in unmapped]
(ROOT / "taxonomy_v2_migration_exception_report.md").write_text(
    "# taxonomy v2 migration exception report\n\n"
    "## BLOCKED_AT_STAGE\n\n"
    "**Stage 9 — Link Impact Dry Run / migration-source audit**\n\n"
    "## BLOCKING_REASON\n\n"
    "The frozen repository contains one local `paper.pdf` that is not represented by any of the 169 canonical `Paper_ID` rows or their `Old_PDF_Path` values. It has a different SHA256 from the mapped PDF for similarly titled Paper 39, so it cannot be assumed to be a duplicate, replacement, or supplementary version without human judgement. The unattended-migration instruction requires destructive migration to stop for an unexplained file/path inconsistency.\n\n"
    "| Unmapped PDF | SHA256 | Related evidence |\n|---|---|---|\n"
    + "\n".join(f"| `{item['path']}` | `{item['sha256']}` | A historical screening list references this path; no canonical Paper_ID does. |" for item in orphan_hashes)
    + "\n\n## Safe state retained\n\n"
    f"- Taxonomy map: 169 rows, no duplicate Paper_ID, no empty primary/secondary.\n- Frozen PDF count: {manifest['pdf_count']}; canonical PDF sources referenced by map: {len(referenced)}; source-limited rows: {sum(r['Old_PDF_Path'] == 'SOURCE_LIMITED_NO_LOCAL_PDF' for r in rows)}.\n- No PDF, reading note, legacy index, or old category directory was moved, deleted, renamed, or overwritten.\n- No Markdown links were rewritten.\n\n"
    "## SAFE_NEXT_COMMAND\n\n"
    "After the owner decides whether the unmapped 2025 PDF is (a) an additional corpus record with a new Paper_ID, (b) an auxiliary/obsolete file to archive, or (c) a replacement for an existing record, update the canonical source index and rerun the Stage 9 source audit before any `git mv`.\n",
    encoding="utf-8")

impact = "# taxonomy v2 link impact report\n\n"
impact += "## Dry-run status\n\n**BLOCKED — no physical migration was attempted.**\n\n"
impact += "| Check | Result |\n|---|---:|\n"
impact += f"| Markdown files scanned | {manifest['markdown_count']} |\n| Local relative Markdown links scanned | 1143 |\n| Pre-existing broken local links (baseline) | 195 |\n| Potential note-target collisions | 0 |\n| Shared canonical PDF source groups | {len(shared_groups)} |\n| Source-limited records | {sum(r['Old_PDF_Path'] == 'SOURCE_LIMITED_NO_LOCAL_PDF' for r in rows)} |\n| Unmapped local PDFs | {len(unmapped)} |\n"
impact += "\n## Blocking anomaly\n\n"
impact += "The following local PDF has no corresponding canonical map row. It is intentionally not assigned a proposed target.\n\n"
impact += "| Path | SHA256 |\n|---|---|\n" + "\n".join(f"| `{x['path']}` | `{x['sha256']}` |" for x in orphan_hashes) + "\n"
impact += "\n## Known shared canonical PDF records\n\n"
impact += "These are already represented by multiple Paper_ID records and have a single planned physical target each; they are not the blocking anomaly.\n\n"
impact += "| Source PDF | Paper_ID records |\n|---|---|\n" + "\n".join(f"| `{p}` | {', '.join(ids)} |" for p, ids in shared_groups.items()) + "\n"
(ROOT / "taxonomy_v2_link_impact_report.md").write_text(impact, encoding="utf-8")

(ROOT / "taxonomy_v2_link_validation_report.md").write_text(
    "# taxonomy v2 link validation report\n\n"
    "## Status\n\n"
    "Post-migration validation was **not run** because Stage 9 correctly blocked physical relocation. The baseline scan is retained at `tmp/taxonomy_v2_link_baseline.json`.\n\n"
    "| Metric | Value |\n|---|---:|\n| Baseline local relative Markdown links | 1143 |\n| Baseline broken links | 195 |\n| Migration-introduced broken links | 0 (no migration performed) |\n",
    encoding="utf-8")
(ROOT / "taxonomy_v2_legacy_path_residuals.md").write_text(
    "# taxonomy v2 legacy path residual audit\n\n"
    "**NOT EXECUTED.** Physical migration did not start because Stage 9 detected an unmapped PDF anomaly. Therefore all old-category assets remain in their pre-migration locations and this report must not be interpreted as a post-migration residual result.\n",
    encoding="utf-8")

report = "# taxonomy v2 migration report\n\n"
report += "## Overall\n\n**PARTIAL — non-destructive taxonomy preparation is complete; physical migration intentionally did not start.**\n\n"
report += "- Stage 0 preflight/freeze: PASS\n- Stages 1–8 taxonomy, audit, index, validation, and migration-map preparation: PASS\n- Stage 9 source/link dry-run: BLOCKED (one unmapped local PDF)\n- Stages 10–20: NOT EXECUTED\n\n"
report += "See [migration exception report](taxonomy_v2_migration_exception_report.md) for the exact blocking file and safe next step.\n"
(ROOT / "taxonomy_v2_migration_report.md").write_text(report, encoding="utf-8")

final = "# taxonomy v2 final validation report\n\n"
final += "## TAXONOMY V2 FINAL STATUS\n\n**Overall: PARTIAL**\n\n"
final += f"- Source commit: `{manifest['source_commit']}`\n- Total papers: **{len(rows)}**\n- Classified: **{len(rows)}**\n- Duplicate Paper_ID: **0**\n- Empty/invalid primary or secondary: **0**\n"
final += "- Physical migration: **0 papers moved / 0 PDF directories moved / 0 reading notes moved**\n"
final += "- Hash audit: **not applicable; no physical moves or content rewrites occurred**\n"
final += "- Link audit: **migration-introduced = 0 because no migration occurred**\n"
final += "- Legacy residual audit: **not applicable; no migration occurred**\n"
final += "- Blocking anomaly: **1 unmapped local PDF**; see migration exception report.\n\n"
final += "## Primary distribution\n\n" + "\n".join(f"- {k}: {primary[k]}" for k in ["SELECTOR", "TRANSLATOR", "GENERATOR", "SUPPORTING"]) + "\n"
final += "\n## Needs Review\n\n" + "\n".join(f"- {r['Paper_ID']}: {r['Title']}" for r in review) + "\n"
(ROOT / "taxonomy_v2_final_validation_report.md").write_text(final, encoding="utf-8")
print(json.dumps({"rows": len(rows), "unmapped_pdf": unmapped, "primary": primary, "secondary": secondary, "review": [r['Paper_ID'] for r in review]}, ensure_ascii=False, default=dict))
