#!/usr/bin/env python3
"""Validate the canonical Taxonomy v2 ledger and its current corpus targets.

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
    "Paper_ID", "Year", "Title", "Primary_Category", "Secondary_Category",
    "Role", "Method", "Task", "Input_Level", "Output_Level", "Platform",
    "Feedback", "Verification", "Benchmark", "Tool", "Agentic", "Priority",
    "Classification_Confidence", "Classification_Rationale", "Needs_Review",
    "PDF_Path", "Note_Path",
}
LEGACY_FIELDS = {
    "Old_Category", "Old_PDF_Path", "Old_Note_Path",
    "Proposed_PDF_Path", "Proposed_Note_Path",
}
PRIMARY_DIRECTORIES = {
    "SELECTOR": "01_LLM_as_Selector",
    "TRANSLATOR": "02_LLM_as_Translator",
    "GENERATOR": "03_LLM_as_Generator",
    "SUPPORTING": "90_Supporting",
}


def exists_or_limited(value: str) -> bool:
    return value == "SOURCE_LIMITED_NO_LOCAL_PDF" or (ROOT / value).is_file()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.parse_args()
    if not CSV_PATH.is_file():
        print(f"FAIL: missing {CSV_PATH.name}")
        return 2
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        headers = set(reader.fieldnames or [])
        missing_headers = REQUIRED - headers
        legacy_headers = LEGACY_FIELDS & headers
    errors: list[str] = []
    if missing_headers:
        errors.append("missing headers: " + ", ".join(sorted(missing_headers)))
    if legacy_headers:
        errors.append("legacy migration headers are not allowed in the current ledger: " + ", ".join(sorted(legacy_headers)))
    if len(rows) != 171:
        errors.append(f"expected 171 rows, got {len(rows)}")
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
        note = row.get("Note_Path", "")
        pdf = row.get("PDF_Path", "")
        if not note or not (ROOT / note).is_file():
            errors.append(f"{paper_id}: missing Note_Path {note!r}")
        if not pdf or not exists_or_limited(pdf):
            errors.append(f"{paper_id}: missing PDF_Path {pdf!r}")
        expected_root = PRIMARY_DIRECTORIES.get(primary)
        if expected_root:
            note_parts = Path(note).parts
            secondary_key, _, secondary_label = secondary.partition("_")
            try:
                secondary_number = int(secondary_key[1:])
                expected_secondary_directory = f"{secondary_number:02d}_{secondary_label}"
            except (ValueError, IndexError):
                expected_secondary_directory = ""
            if pdf != "SOURCE_LIMITED_NO_LOCAL_PDF":
                pdf_parts = Path(pdf).parts
                if len(pdf_parts) < 3 or pdf_parts[0] != expected_root:
                    errors.append(f"{paper_id}: PDF_Path does not match {primary}: {pdf!r}")
                elif expected_secondary_directory and pdf_parts[1] != expected_secondary_directory:
                    errors.append(f"{paper_id}: PDF_Path secondary category mismatch: {pdf!r}")
            if len(note_parts) < 4 or note_parts[0] != "文献逐篇阅读" or note_parts[1] != expected_root:
                errors.append(f"{paper_id}: Note_Path does not match {primary}: {note!r}")
            if len(note_parts) >= 3 and expected_secondary_directory and note_parts[2] != expected_secondary_directory:
                errors.append(f"{paper_id}: Note_Path secondary category mismatch: {note!r}")
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
