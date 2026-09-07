#!/usr/bin/env python3
"""Validate the canonical taxonomy v2 CSV and its post-migration targets.

This validator intentionally performs no edits.  It is suitable for CI or a
manual pre-commit check after adding a new paper to the corpus.
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "taxonomy_v2.csv"

SECONDARIES = {
    "SELECTOR": {
        "S1_Pass_Phase_Flag_Selection", "S2_Schedule_Config_Autotuning",
        "S3_Search_RL_Policy", "S4_Agent_Tool_Action_Selection",
    },
    "TRANSLATOR": {
        "T1_Source_Optimization_Refactoring", "T2_IR_ASM_Optimization_Superoptimization",
        "T3_Translation_CrossLanguage_CrossISA", "T4_GPU_Kernel_Accelerator_Optimization",
        "T5_Repair_Compiler_Feedback", "T6_Decompilation_LowLevel_Recovery",
    },
    "GENERATOR": {
        "G1_Compiler_Pass_Generation", "G2_Optimization_Rule_Transform_Generation",
        "G3_Backend_Compiler_Component_Generation", "G4_Tool_Test_Fuzz_Generation",
    },
    "SUPPORTING": {
        "B1_Benchmark_Dataset", "B2_Compiler_Infrastructure", "B3_LLM_RL_Foundation",
        "B4_Traditional_ML_Compiler_Optimization", "B5_Hardware_ISA_Compiler_Background",
        "B6_Survey_Evaluation_Methodology",
    },
}
REQUIRED = {
    "Paper_ID", "Primary_Category", "Secondary_Category", "Classification_Confidence",
    "Classification_Rationale", "Needs_Review", "Old_PDF_Path", "Old_Note_Path",
    "Proposed_PDF_Path", "Proposed_Note_Path",
}


def exists_or_limited(value: str) -> bool:
    return value == "SOURCE_LIMITED_NO_LOCAL_PDF" or (ROOT / value).is_file()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pre-migration", action="store_true", help="validate old source paths instead of proposed paths")
    args = parser.parse_args()
    if not CSV_PATH.is_file():
        print(f"FAIL: missing {CSV_PATH.name}")
        return 2
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        missing_headers = REQUIRED - set(reader.fieldnames or [])
    errors: list[str] = []
    if missing_headers:
        errors.append("missing headers: " + ", ".join(sorted(missing_headers)))
    if len(rows) != 169:
        errors.append(f"expected 169 rows, got {len(rows)}")
    ids = [row.get("Paper_ID", "").strip() for row in rows]
    duplicates = sorted({paper_id for paper_id in ids if ids.count(paper_id) > 1})
    if duplicates:
        errors.append("duplicate Paper_ID: " + ", ".join(duplicates))
    for row in rows:
        paper_id = row.get("Paper_ID", "?")
        primary = row.get("Primary_Category", "")
        secondary = row.get("Secondary_Category", "")
        if primary not in SECONDARIES:
            errors.append(f"{paper_id}: invalid primary {primary!r}")
        elif secondary not in SECONDARIES[primary]:
            errors.append(f"{paper_id}: incompatible secondary {secondary!r}")
        if not row.get("Classification_Rationale", "").strip():
            errors.append(f"{paper_id}: empty rationale")
        if row.get("Classification_Confidence") not in {"HIGH", "MEDIUM", "LOW"}:
            errors.append(f"{paper_id}: invalid confidence")
        if row.get("Needs_Review") not in {"YES", "NO"}:
            errors.append(f"{paper_id}: invalid Needs_Review")
        note_field = "Old_Note_Path" if args.pre_migration else "Proposed_Note_Path"
        pdf_field = "Old_PDF_Path" if args.pre_migration else "Proposed_PDF_Path"
        note = row.get(note_field, "")
        pdf = row.get(pdf_field, "")
        if not note or not (ROOT / note).is_file():
            errors.append(f"{paper_id}: missing {note_field} {note!r}")
        if not pdf or not exists_or_limited(pdf):
            errors.append(f"{paper_id}: missing {pdf_field} {pdf!r}")
    if errors:
        print("FAIL")
        print("\n".join(f"- {error}" for error in errors))
        return 1
    distribution = {key: sum(row["Primary_Category"] == key for row in rows) for key in SECONDARIES}
    print("PASS")
    print(f"rows={len(rows)}; " + "; ".join(f"{key}={value}" for key, value in distribution.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
