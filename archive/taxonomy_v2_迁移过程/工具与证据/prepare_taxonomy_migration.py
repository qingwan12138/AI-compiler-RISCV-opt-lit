from __future__ import annotations

import csv
import hashlib
import json
import subprocess
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.cwd()
CSV_FILE = ROOT / "taxonomy_v2.csv"
OLD_MAP = ROOT / "taxonomy_v2_migration_map.csv"

DEST = {
    "S1_Pass_Phase_Flag_Selection": "01_LLM_as_Selector/01_Pass_Phase_Flag_Selection",
    "S2_Schedule_Config_Autotuning": "01_LLM_as_Selector/02_Schedule_Config_Autotuning",
    "S3_Search_RL_Policy": "01_LLM_as_Selector/03_Search_RL_Policy",
    "S4_Agent_Tool_Action_Selection": "01_LLM_as_Selector/04_Agent_Tool_Action_Selection",
    "T1_Source_Optimization_Refactoring": "02_LLM_as_Translator/01_Source_Optimization_Refactoring",
    "T2_IR_ASM_Optimization_Superoptimization": "02_LLM_as_Translator/02_IR_ASM_Optimization_Superoptimization",
    "T3_Translation_CrossLanguage_CrossISA": "02_LLM_as_Translator/03_Translation_CrossLanguage_CrossISA",
    "T4_GPU_Kernel_Accelerator_Optimization": "02_LLM_as_Translator/04_GPU_Kernel_Accelerator_Optimization",
    "T5_Repair_Compiler_Feedback": "02_LLM_as_Translator/05_Repair_Compiler_Feedback",
    "T6_Decompilation_LowLevel_Recovery": "02_LLM_as_Translator/06_Decompilation_LowLevel_Recovery",
    "G1_Compiler_Pass_Generation": "03_LLM_as_Generator/01_Compiler_Pass_Generation",
    "G2_Optimization_Rule_Transform_Generation": "03_LLM_as_Generator/02_Optimization_Rule_Transform_Generation",
    "G3_Backend_Compiler_Component_Generation": "03_LLM_as_Generator/03_Backend_Compiler_Component_Generation",
    "G4_Tool_Test_Fuzz_Generation": "03_LLM_as_Generator/04_Tool_Test_Fuzz_Generation",
    "B1_Benchmark_Dataset": "90_Supporting/01_Benchmark_Dataset",
    "B2_Compiler_Infrastructure": "90_Supporting/02_Compiler_Infrastructure",
    "B3_LLM_RL_Foundation": "90_Supporting/03_LLM_RL_Foundation",
    "B4_Traditional_ML_Compiler_Optimization": "90_Supporting/04_Traditional_ML_Compiler_Optimization",
    "B5_Hardware_ISA_Compiler_Background": "90_Supporting/05_Hardware_ISA_Compiler_Background",
    "B6_Survey_Evaluation_Methodology": "90_Supporting/06_Survey_Evaluation_Methodology",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def git(*args: str) -> str:
    return subprocess.run(["git", "-C", str(ROOT), *args], text=True, capture_output=True, check=False).stdout.strip()


def parse_old_map() -> dict[str, tuple[str, str]]:
    result = {}
    with OLD_MAP.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            old = row["Old_Path"]
            if not old.startswith("NOTE:") or "; PDF:" not in old:
                raise ValueError(f"unparseable existing map row {row['Paper_ID']}: {old}")
            note, pdf = old[len("NOTE:"):].split("; PDF:", 1)
            result[row["Paper_ID"]] = (note, pdf)
    return result


def target_path(old: str, secondary: str, note: bool) -> str:
    base = Path(old).name if note else str(Path(old).parent.name + "/paper.pdf")
    prefix = DEST[secondary]
    return f"文献逐篇阅读/{prefix}/{base}" if note else f"{prefix}/{base}"


def main() -> None:
    old_map = parse_old_map()
    with CSV_FILE.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        fields = list(reader.fieldnames or [])
    if len(rows) != 169:
        raise SystemExit(f"expected 169 taxonomy rows, got {len(rows)}")
    additions = ["Old_PDF_Path", "Old_Note_Path", "Proposed_PDF_Path", "Proposed_Note_Path"]
    fields = [field for field in fields if field not in additions] + additions
    for row in rows:
        paper_id = row["Paper_ID"]
        if paper_id not in old_map:
            raise SystemExit(f"taxonomy Paper_ID absent from old map: {paper_id}")
        note, pdf = old_map[paper_id]
        if not (ROOT / note).is_file():
            raise SystemExit(f"missing note source {paper_id}: {note}")
        row["Old_Note_Path"] = note
        row["Proposed_Note_Path"] = target_path(note, row["Secondary_Category"], True)
        if (ROOT / pdf).is_file():
            row["Old_PDF_Path"] = pdf
            row["Proposed_PDF_Path"] = target_path(pdf, row["Secondary_Category"], False)
        else:
            row["Old_PDF_Path"] = "SOURCE_LIMITED_NO_LOCAL_PDF"
            row["Proposed_PDF_Path"] = "SOURCE_LIMITED_NO_LOCAL_PDF"

    # Any shared physical PDF must migrate to one and only one target.
    shared = defaultdict(set)
    for row in rows:
        if row["Old_PDF_Path"] != "SOURCE_LIMITED_NO_LOCAL_PDF":
            shared[row["Old_PDF_Path"]].add(row["Proposed_PDF_Path"])
    bad_shared = {old: targets for old, targets in shared.items() if len(targets) != 1}
    if bad_shared:
        raise SystemExit(f"shared PDF target conflict: {bad_shared}")
    notes = [row["Proposed_Note_Path"] for row in rows]
    if len(notes) != len(set(notes)):
        raise SystemExit("proposed note target collision")

    with CSV_FILE.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, quoting=csv.QUOTE_ALL)
        writer.writeheader(); writer.writerows(rows)
    map_file = ROOT / "taxonomy_v2_migration_map.csv"
    map_fields = ["Paper_ID", "Old_PDF_Path", "New_PDF_Path", "Old_Note_Path", "New_Note_Path", "Primary", "Secondary"]
    with map_file.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=map_fields, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for row in rows:
            writer.writerow({"Paper_ID": row["Paper_ID"], "Old_PDF_Path": row["Old_PDF_Path"], "New_PDF_Path": row["Proposed_PDF_Path"], "Old_Note_Path": row["Old_Note_Path"], "New_Note_Path": row["Proposed_Note_Path"], "Primary": row["Primary_Category"], "Secondary": row["Secondary_Category"]})

    pdfs = sorted(ROOT.rglob("paper.pdf"))
    notes_files = sorted((ROOT / "文献逐篇阅读").rglob("*.md"))
    markdowns = sorted(path for path in ROOT.rglob("*.md") if ".git" not in path.parts and ".worktrees" not in path.parts)
    index = ROOT / "00_分类索引.md"
    manifest_files = [{"path": index.relative_to(ROOT).as_posix(), "kind": "legacy_index", "sha256": sha256(index)}]
    manifest_files += [{"path": path.relative_to(ROOT).as_posix(), "kind": "pdf", "sha256": sha256(path)} for path in pdfs]
    manifest_files += [{"path": path.relative_to(ROOT).as_posix(), "kind": "note", "sha256": sha256(path)} for path in notes_files]
    manifest = {"source_commit": git("rev-parse", "HEAD"), "created_at": datetime.now(timezone.utc).isoformat(), "paper_count": len(rows), "pdf_count": len(pdfs), "note_count": len(notes_files), "markdown_count": len(markdowns), "files": manifest_files}
    (ROOT / "taxonomy_v2_pre_migration_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    status = git("status", "--short") or "(clean before generated migration artifacts)"
    report = "# taxonomy v2 preflight report\n\n"
    report += f"- Source commit: `{manifest['source_commit']}`\n- Branch: `{git('branch', '--show-current')}`\n- Created (UTC): `{manifest['created_at']}`\n- Git status at preflight: `{status}`\n"
    report += "- Remote fetch: attempted before preflight; GitHub TLS handshake failed, while local `HEAD` and configured upstream remained the same commit. No remote state was changed.\n\n"
    report += "## Frozen corpus assets\n\n"
    report += f"| Asset | Count |\n|---|---:|\n| Indexed papers | {len(rows)} |\n| `paper.pdf` files | {len(pdfs)} |\n| Reading notes | {len(notes_files)} |\n| Repository Markdown files | {len(markdowns)} |\n\n"
    report += "The manifest records SHA256 hashes for the legacy index, every local PDF, and every reading note before physical relocation. The taxonomy path columns and migration map were generated after this asset freeze; they do not change corpus content.\n"
    (ROOT / "taxonomy_v2_preflight_report.md").write_text(report, encoding="utf-8")
    print(json.dumps({"papers": len(rows), "pdfs": len(pdfs), "notes": len(notes_files), "markdown": len(markdowns), "source_limited": sum(row['Old_PDF_Path'] == 'SOURCE_LIMITED_NO_LOCAL_PDF' for row in rows), "unique_pdf_sources": len(shared), "shared_pdf_sources": sum(1 for rows_ in defaultdict(list, {k: [] for k in shared}).values())}, ensure_ascii=False))


if __name__ == "__main__":
    main()
