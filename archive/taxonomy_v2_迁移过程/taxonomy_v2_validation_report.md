# taxonomy v2 validation report (audit edition)

- Audit scope: taxonomy reliability, review preparation, and migration planning only.
- Reading notes consulted: **169/169**; focused boundary re-reads: **20**.
- Legacy content mutation: **none** — no existing PDF, reading note, legacy directory, or `00_分类索引.md` changed.

## Final validation

| Check | Result |
|---|---:|
| Total papers | 169 |
| Classified | 169 |
| Unclassified | 0 |
| Duplicate Paper_ID | 0 |
| Empty Primary_Category | 0 |
| Invalid Primary_Category | 0 |
| Invalid Secondary_Category | 0 |
| Empty Classification_Rationale | 0 |
| Empty Classification_Confidence | 0 |
| Needs_Review | 2 |
| Migration map rows | 169 |
| Validation status | PASS |

## Primary distribution

| Primary | Count |
|---|---:|
| SELECTOR | 12 |
| TRANSLATOR | 62 |
| GENERATOR | 10 |
| SUPPORTING | 85 |

## Secondary distribution

| Primary | Secondary | Count |
|---|---|---:|
| SELECTOR | S1_Pass_Phase_Flag_Selection | 3 |
| SELECTOR | S2_Schedule_Config_Autotuning | 4 |
| SELECTOR | S3_Search_RL_Policy | 3 |
| SELECTOR | S4_Agent_Tool_Action_Selection | 2 |
| TRANSLATOR | T1_Source_Optimization_Refactoring | 25 |
| TRANSLATOR | T2_IR_ASM_Optimization_Superoptimization | 7 |
| TRANSLATOR | T3_Translation_CrossLanguage_CrossISA | 9 |
| TRANSLATOR | T4_GPU_Kernel_Accelerator_Optimization | 8 |
| TRANSLATOR | T5_Repair_Compiler_Feedback | 6 |
| TRANSLATOR | T6_Decompilation_LowLevel_Recovery | 7 |
| GENERATOR | G1_Compiler_Pass_Generation | 1 |
| GENERATOR | G2_Optimization_Rule_Transform_Generation | 6 |
| GENERATOR | G3_Backend_Compiler_Component_Generation | 0 |
| GENERATOR | G4_Tool_Test_Fuzz_Generation | 3 |
| SUPPORTING | B1_Benchmark_Dataset | 9 |
| SUPPORTING | B2_Compiler_Infrastructure | 18 |
| SUPPORTING | B3_LLM_RL_Foundation | 9 |
| SUPPORTING | B4_Traditional_ML_Compiler_Optimization | 24 |
| SUPPORTING | B5_Hardware_ISA_Compiler_Background | 11 |
| SUPPORTING | B6_Survey_Evaluation_Methodology | 14 |

## Old category → new category migration matrix

| Old category | SELECTOR | TRANSLATOR | GENERATOR | SUPPORTING | Total |
|---|---:|---:|---:|---:|---:|
| 01 编译阶段排序与强化学习调优 | 7 | 5 | 1 | 15 | 28 |
| 02 LLM 编译优化智能体与反馈驱动 | 5 | 44 | 4 | 18 | 71 |
| 03 形式验证、超级优化与规则生成 | 0 | 10 | 5 | 17 | 32 |
| 04 向量化与跨 ISA 代码迁移 | 0 | 2 | 0 | 4 | 6 |
| 05 RISC-V、RVV 编译器与真实后端 | 0 | 0 | 0 | 9 | 9 |
| 06 多硬件编译、代价模型与 IR 基础设施 | 0 | 1 | 0 | 22 | 23 |

## Audit changes

- Primary-category corrections: **9** (42, 60, 68, 69, N05, N06, C17, 53, 54).
- Generator-secondary correction: **1** (41: G2 → G4).
- Previous review entries resolved from notes: **13**.
- New review entry added because its existing note is explicitly inferential: **08**.
- Remaining review entries: **2** (08, 15).

## Review queue coverage

- 08: present in [taxonomy_v2_review_queue.md](taxonomy_v2_review_queue.md).
- 15: present in [taxonomy_v2_review_queue.md](taxonomy_v2_review_queue.md).

## Generated planning artifacts

- [taxonomy_v2_boundary_cases.md](taxonomy_v2_boundary_cases.md) — 20 taxonomy regression cases.
- [taxonomy_v2_directory_migration_plan.md](taxonomy_v2_directory_migration_plan.md) — no-op migration protocol.
- [taxonomy_v2_migration_map.csv](taxonomy_v2_migration_map.csv) — 169 planned paper mappings.
- [taxonomy_v2_link_impact_report.md](taxonomy_v2_link_impact_report.md) — link/collision risks before any move.
