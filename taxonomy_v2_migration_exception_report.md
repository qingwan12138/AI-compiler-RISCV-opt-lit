# taxonomy v2 migration exception report

## Resolution status

**Resolved by owner instruction: the mapped 169-record migration proceeded; the unknown asset was retained and reported.**

## Unmapped asset

The frozen repository contains one local `paper.pdf` that is not represented by any of the 169 canonical `Paper_ID` rows or their `Old_PDF_Path` values. It has a different SHA256 from the mapped PDF for similarly titled Paper 39, so it cannot be assumed to be a duplicate, replacement, or supplementary version without human judgement.

| Unmapped PDF | SHA256 | Related evidence |
|---|---|---|
| `01_编译阶段排序与强化学习调优/39-Enhancing Translation Validation of Compiler Transformations with Large Language Models. arXiv 2025/paper.pdf` | `176a79a0b584c83f3302a1e6023179574916e83b268770f7a6d7c684b28d712c` | A historical screening list references this path; no canonical Paper_ID does. |

## Treatment

- Taxonomy map: 169 rows, no duplicate Paper_ID, no empty primary/secondary.
- Frozen PDF count: 164; canonical PDF sources referenced by map: 163; source-limited rows: 4.
- All mapped PDF directories and reading notes were relocated with `git mv`.
- This unmapped PDF was not moved, deleted, renamed, or overwritten.
- Markdown relative links were repaired by exact target resolution after migration.

## Safe next action for this asset

When the owner decides whether the unmapped 2025 PDF is (a) an additional corpus record with a new Paper_ID, (b) an auxiliary/obsolete file to archive, or (c) a replacement for an existing record, update the canonical source index and rerun the source audit before moving that asset.
