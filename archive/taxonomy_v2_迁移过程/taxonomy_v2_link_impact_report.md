# taxonomy v2 link impact report

## Dry-run status

**PASS WITH INVENTORIED EXCEPTION — the 169 mapped records were migrated; one unmapped PDF was intentionally retained in place.**

| Check | Result |
|---|---:|
| Markdown files scanned | 383 |
| Local relative Markdown links scanned | 1143 |
| Pre-existing broken local links (baseline) | 195 |
| Potential note-target collisions | 0 |
| Shared canonical PDF source groups | 2 |
| Source-limited records | 4 |
| Unmapped local PDFs | 1 |

## Unmapped-PDF inventory

The following local PDF has no corresponding canonical map row. By explicit owner instruction it was not guessed, reclassified, moved, or deleted. It remains an inventory exception rather than a canonical residual.

| Path | SHA256 |
|---|---|
| `01_编译阶段排序与强化学习调优/39-Enhancing Translation Validation of Compiler Transformations with Large Language Models. arXiv 2025/paper.pdf` | `176a79a0b584c83f3302a1e6023179574916e83b268770f7a6d7c684b28d712c` |

## Known shared canonical PDF records

These are represented by multiple Paper_ID records and have a single physical target each; they are not the unmapped exception.

## Exact path-rewrite result

- Markdown files changed: **3**
- Relative Markdown links rewritten: **513**
- Migration-introduced broken links: **0**

| Source PDF | Paper_ID records |
|---|---|
| `01_编译阶段排序与强化学习调优/43-Problem-Oriented Code Optimization. arXiv 2024/paper.pdf` | 51, 43 |
| `02_LLM编译优化智能体与反馈驱动/16-Beyond Pass-by-Pass Optimization Intent-Driven IR Optimization with Large Language Models. arXi/paper.pdf` | 16, 45 |
