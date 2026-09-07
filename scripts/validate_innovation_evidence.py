#!/usr/bin/env python3
"""Validate the literature-only innovation evidence layer without editing it."""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

REQUIRED_FILES = (
    "05_创新证据矩阵.md",
    "06_局限与反例证据表.md",
    "07_创新机会观察区.md",
    "08_近邻工作与创新边界表.md",
    "09_机制增量与可做性门控.md",
)
PAPER_RE = re.compile(r"\bPAPER-([A-Z]?\d{2,3})\b")
MATRIX_RE = re.compile(r"^## PAPER-([A-Z]?\d{2,3})[：:]", re.MULTILINE)
LIM_RE = re.compile(r"^## LIM-(\d{2,3})[：:]", re.MULTILINE)
OPP_RE = re.compile(r"^## OPP-(\d{2,3})[：:]", re.MULTILINE)
NEIGHBOR_RE = re.compile(r"^## OPP-(\d{2,3})[：:].*近邻", re.MULTILINE)
GATE_RE = re.compile(r"^## OPP-(\d{2,3})[：:].*机制", re.MULTILINE)


def blocks(text: str, matcher: re.Pattern[str]) -> list[str]:
    matches = list(matcher.finditer(text))
    return [text[m.start(): matches[index + 1].start() if index + 1 < len(matches) else len(text)]
            for index, m in enumerate(matches)]


def paper_ids(repo: Path) -> set[str]:
    with (repo / "taxonomy_v2.csv").open(encoding="utf-8-sig", newline="") as handle:
        return {row["Paper_ID"].strip().upper() for row in csv.DictReader(handle)}


def check_references(text: str, known_ids: set[str], label: str, errors: list[str]) -> None:
    unknown = sorted({match.group(1).upper() for match in PAPER_RE.finditer(text)} - known_ids)
    if unknown:
        errors.append(f"{label}: unknown Paper_ID references: {', '.join(unknown)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    repo = args.repo.resolve()
    errors: list[str] = []
    contents: dict[str, str] = {}
    for name in REQUIRED_FILES:
        path = repo / name
        if not path.is_file():
            errors.append(f"missing required evidence file: {name}")
        else:
            contents[name] = path.read_text(encoding="utf-8")
    taxonomy = repo / "taxonomy_v2.csv"
    if not taxonomy.is_file():
        errors.append("missing taxonomy_v2.csv")
    if errors:
        print("FAIL")
        print("\n".join(f"- {item}" for item in errors))
        return 1

    known_ids = paper_ids(repo)
    for name, content in contents.items():
        check_references(content, known_ids, name, errors)

    matrix = contents["05_创新证据矩阵.md"]
    matrix_ids = [match.group(1).upper() for match in MATRIX_RE.finditer(matrix)]
    if not 25 <= len(matrix_ids) <= 35:
        errors.append(f"matrix paper blocks must be 25-35, got {len(matrix_ids)}")
    duplicates = sorted({paper_id for paper_id in matrix_ids if matrix_ids.count(paper_id) > 1})
    if duplicates:
        errors.append("matrix duplicate Paper_ID blocks: " + ", ".join(duplicates))
    for block in blocks(matrix, MATRIX_RE):
        for marker in ("证据类型", "证据位置", "事实/推导", "证据强度"):
            if marker not in block:
                errors.append(f"matrix block missing {marker}: {block.splitlines()[0]}")

    limitations = contents["06_局限与反例证据表.md"]
    lim_blocks = blocks(limitations, LIM_RE)
    if not lim_blocks:
        errors.append("no LIM blocks found")
    for block in lim_blocks:
        for marker in ("支持证据", "已有解决路线", "事实/推导结论"):
            if marker not in block:
                errors.append(f"limitation block missing {marker}: {block.splitlines()[0]}")
        if not PAPER_RE.search(block):
            errors.append(f"limitation block has no Paper_ID: {block.splitlines()[0]}")

    opportunities = contents["07_创新机会观察区.md"]
    opp_blocks = blocks(opportunities, OPP_RE)
    if not opp_blocks:
        errors.append("no OPP blocks found")
    allowed_states = {"观察", "证据补充中", "待人工判断"}
    for block in opp_blocks:
        for marker in ("已有工作边界", "未解决机制", "证据清单", "证据不足处", "待检索关键词", "状态"):
            if marker not in block:
                errors.append(f"opportunity block missing {marker}: {block.splitlines()[0]}")
        if not re.search(r"\bLIM-\d{2,3}\b", block):
            errors.append(f"opportunity block has no LIM reference: {block.splitlines()[0]}")
        ids = {match.group(1).upper() for match in PAPER_RE.finditer(block)}
        if len(ids) < 2 and "系统性评测证据" not in block:
            errors.append(f"opportunity needs two Paper_ID references or system evidence: {block.splitlines()[0]}")
        state = re.search(r"### 状态\s*\n([^\n]+)", block)
        if not state or state.group(1).strip() not in allowed_states:
            errors.append(f"opportunity has invalid state: {block.splitlines()[0]}")

    expected_opp_ids = {"01", "02", "03", "04", "05"}
    found_opp_ids = {match.group(1) for match in OPP_RE.finditer(opportunities)}
    if found_opp_ids != expected_opp_ids:
        errors.append("opportunity IDs must be OPP-01 through OPP-05")

    neighbor_audits = contents["08_近邻工作与创新边界表.md"]
    neighbor_blocks = blocks(neighbor_audits, NEIGHBOR_RE)
    neighbor_ids = [match.group(1) for match in NEIGHBOR_RE.finditer(neighbor_audits)]
    if set(neighbor_ids) != expected_opp_ids or len(neighbor_ids) != len(expected_opp_ids):
        errors.append("nearest-work audits must contain OPP-01 through OPP-05 exactly once")
    for block in neighbor_blocks:
        for marker in ("近邻论文", "尚未覆盖的条件", "重合风险", "事实/推断", "人工复核重点"):
            if marker not in block:
                errors.append(f"nearest-work block missing {marker}: {block.splitlines()[0]}")
        ids = {match.group(1).upper() for match in PAPER_RE.finditer(block)}
        if not 3 <= len(ids) <= 5:
            errors.append(f"nearest-work block needs 3-5 distinct Paper_ID references: {block.splitlines()[0]}")

    gates = contents["09_机制增量与可做性门控.md"]
    gate_blocks = blocks(gates, GATE_RE)
    gate_ids = [match.group(1) for match in GATE_RE.finditer(gates)]
    if set(gate_ids) != expected_opp_ids or len(gate_ids) != len(expected_opp_ids):
        errors.append("mechanism gates must contain OPP-01 through OPP-05 exactly once")
    final_states = {"保留观察", "证据不足", "近邻重合高"}
    for block in gate_blocks:
        for marker in ("共同输入与输出", "最低独立机制判据", "退化为的最近工作", "公开核验条件", "可证伪指标", "门控结果"):
            if marker not in block:
                errors.append(f"mechanism gate block missing {marker}: {block.splitlines()[0]}")
        gate_state = re.search(r"### 门控结果\s*\n([^\n]+)", block)
        if not gate_state or gate_state.group(1).strip() not in final_states:
            errors.append(f"mechanism gate has invalid state: {block.splitlines()[0]}")

    for block in opp_blocks:
        heading = block.splitlines()[0]
        if "框架审计状态" not in block:
            errors.append(f"opportunity missing framework audit status: {heading}")
        if "08_近邻工作与创新边界表.md" not in block or "09_机制增量与可做性门控.md" not in block:
            errors.append(f"opportunity missing gate links: {heading}")
        audit_state = re.search(r"### 框架审计状态\s*\n([^；\n]+)", block)
        if not audit_state or audit_state.group(1).strip("` ") not in final_states:
            errors.append(f"opportunity has invalid framework audit state: {heading}")

    if errors:
        print("FAIL")
        print("\n".join(f"- {item}" for item in errors))
        return 1
    print("PASS")
    print(
        f"matrix_papers={len(matrix_ids)}; limitations={len(lim_blocks)}; "
        f"opportunities={len(opp_blocks)}; neighbor_audits={len(neighbor_blocks)}; "
        f"mechanism_gates={len(gate_blocks)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
