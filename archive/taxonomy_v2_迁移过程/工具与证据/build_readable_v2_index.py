from __future__ import annotations

import csv
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path.cwd()
LEGACY = ROOT / "archive/taxonomy_v1/00_分类索引_v1_legacy.md"
TAXONOMY = ROOT / "taxonomy_v2.csv"
OUT = ROOT / "00_三大类分类索引_v2.md"

ORDER = {
    "SELECTOR": ["S1_Pass_Phase_Flag_Selection", "S2_Schedule_Config_Autotuning", "S3_Search_RL_Policy", "S4_Agent_Tool_Action_Selection"],
    "TRANSLATOR": ["T1_Source_Optimization_Refactoring", "T2_IR_ASM_Optimization_Superoptimization", "T3_Translation_CrossLanguage_CrossISA", "T4_GPU_Kernel_Accelerator_Optimization", "T5_Repair_Compiler_Feedback", "T6_Decompilation_LowLevel_Recovery"],
    "GENERATOR": ["G1_Compiler_Pass_Generation", "G2_Optimization_Rule_Transform_Generation", "G3_Backend_Compiler_Component_Generation", "G4_Tool_Test_Fuzz_Generation"],
    "SUPPORTING": ["B1_Benchmark_Dataset", "B2_Compiler_Infrastructure", "B3_LLM_RL_Foundation", "B4_Traditional_ML_Compiler_Optimization", "B5_Hardware_ISA_Compiler_Background", "B6_Survey_Evaluation_Methodology"],
}
PRIMARY_LABEL = {"SELECTOR": "LLM as Selector", "TRANSLATOR": "LLM as Translator", "GENERATOR": "LLM as Generator", "SUPPORTING": "Supporting Literature"}
SECONDARY_LABEL = {
    "S1_Pass_Phase_Flag_Selection": "Pass / Phase / Flag Selection", "S2_Schedule_Config_Autotuning": "Schedule / Config / Autotuning", "S3_Search_RL_Policy": "Search / RL / Policy", "S4_Agent_Tool_Action_Selection": "Agent / Tool Action Selection",
    "T1_Source_Optimization_Refactoring": "Source Optimization / Refactoring", "T2_IR_ASM_Optimization_Superoptimization": "IR / ASM Optimization / Superoptimization", "T3_Translation_CrossLanguage_CrossISA": "Translation / Cross-Language / Cross-ISA", "T4_GPU_Kernel_Accelerator_Optimization": "GPU Kernel / Accelerator Optimization", "T5_Repair_Compiler_Feedback": "Repair / Compiler Feedback", "T6_Decompilation_LowLevel_Recovery": "Decompilation / Low-Level Recovery",
    "G1_Compiler_Pass_Generation": "Compiler Pass Generation", "G2_Optimization_Rule_Transform_Generation": "Optimization Rule / Transform Generation", "G3_Backend_Compiler_Component_Generation": "Backend / Compiler Component Generation", "G4_Tool_Test_Fuzz_Generation": "Tool / Test / Fuzz Generation",
    "B1_Benchmark_Dataset": "Benchmark / Dataset", "B2_Compiler_Infrastructure": "Compiler Infrastructure", "B3_LLM_RL_Foundation": "LLM / RL Foundation", "B4_Traditional_ML_Compiler_Optimization": "Traditional ML Compiler Optimization", "B5_Hardware_ISA_Compiler_Background": "Hardware / ISA / Compiler Background", "B6_Survey_Evaluation_Methodology": "Survey / Evaluation / Methodology",
}


def clean(cell: str) -> str:
    return cell.strip()


legacy_rows = {}
for line in LEGACY.read_text(encoding="utf-8").splitlines():
    if not re.match(r"^\|\s*(?:\d+|N\d+|C\d+)\s*\|", line):
        continue
    cells = [clean(x) for x in line.split("|")[1:-1]]
    if len(cells) >= 8:
        legacy_rows[cells[0]] = {"venue": cells[5], "keywords": cells[6]}

rows = list(csv.DictReader(TAXONOMY.open(encoding="utf-8-sig")))
if len(rows) != 169 or set(legacy_rows) != {row["Paper_ID"] for row in rows}:
    missing = set(row["Paper_ID"] for row in rows) - set(legacy_rows)
    raise SystemExit(f"legacy field extraction mismatch: {sorted(missing)}")
groups = defaultdict(list)
for row in rows:
    groups[(row["Primary_Category"], row["Secondary_Category"])].append(row)

def sort_id(row: dict) -> tuple:
    value = row["Paper_ID"]
    match = re.match(r"([A-Z]*)(\d+)", value)
    return (match.group(1) if match else value, int(match.group(2)) if match else 0)

parts = ["# LLM Compiler 三大类文献索引\n", "> 分类原则：一级类别只回答“LLM 在编译系统中的最终角色”。Agent、RL、形式验证、平台等均为横向标签，不是一级分类。\n", ">\n", "> 字段沿用原索引：**编号、年份、类别、文献、PDF、发表渠道、关键词、优先级**。类别栏采用 `Primary / Secondary` 新分类。\n\n", f"- 条目总数：**{len(rows)}**；SELECTOR：**12**；TRANSLATOR：**62**；GENERATOR：**10**；SUPPORTING：**85**。\n", "- 旧六类索引见：[Legacy taxonomy v1](archive/taxonomy_v1/00_分类索引_v1_legacy.md)。完整机器可读标签见：[taxonomy_v2.csv](taxonomy_v2.csv)。\n\n"]
for index, primary in enumerate(["SELECTOR", "TRANSLATOR", "GENERATOR", "SUPPORTING"], 1):
    total = sum(len(groups[(primary, secondary)]) for secondary in ORDER[primary])
    parts.append(f"## {index}. {PRIMARY_LABEL[primary]}（{total} 篇）\n\n")
    for secondary in ORDER[primary]:
        subset = sorted(groups[(primary, secondary)], key=sort_id)
        parts.append(f"### {secondary}｜{SECONDARY_LABEL[secondary]}（{len(subset)} 篇）\n\n")
        if not subset:
            parts.append("_本分类暂无条目。_\n\n")
            continue
        parts.append("| 编号 | 年份 | 类别 | 文献 | PDF | 发表渠道 | 关键词 | 优先级 |\n|---|---:|---|---|---|---|---|---|\n")
        for row in subset:
            legacy = legacy_rows[row["Paper_ID"]]
            category = f"{row['Primary_Category']} / {row['Secondary_Category']}"
            note = row["Proposed_Note_Path"]
            if row["Proposed_PDF_Path"] == "SOURCE_LIMITED_NO_LOCAL_PDF":
                pdf = "资料受限（无本地 PDF）"
            else:
                pdf = f"[打开 PDF](<{row['Proposed_PDF_Path']}>)"
            review = " ⚠️" if row["Needs_Review"] == "YES" else ""
            parts.append(f"| {row['Paper_ID']} | {row['Year']} | {category} | [{row['Title']}]({note}){review} | {pdf} | {legacy['venue']} | {legacy['keywords']} | {row['Priority']} |\n")
        parts.append("\n")
parts.append("## NEEDS_REVIEW\n\n| 编号 | 文献 | 当前分类 | 说明 |\n|---|---|---|---|\n")
for row in rows:
    if row["Needs_Review"] == "YES":
        parts.append(f"| {row['Paper_ID']} | {row['Title']} | {row['Primary_Category']} / {row['Secondary_Category']} | 参见 `taxonomy_v2_review_queue.md`。 |\n")
OUT.write_text("".join(parts), encoding="utf-8")
print(f"wrote {OUT.name}: {len(rows)} rows")
