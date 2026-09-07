# taxonomy v2 link impact report

> Planning analysis only. No link, PDF, note, or legacy directory has been edited.

## Inventory

- Markdown files scanned: **382**
- Markdown files containing legacy category-path references: **37**
- Legacy category-path reference occurrences: **1322**
- Legacy index rows: **169**
- Rows with a local PDF link: **165**
- Rows without a local PDF link: **4** (18, 28, 25, 29)
- Unique referenced PDF paths: **163**
- Shared PDF reference groups: **2**
- Duplicate note basenames: **0**
- Migration rows with Chinese, spaces, or parentheses in legacy artifact paths: **169**

## Markdown/indexes requiring rewrite in a future move

- `00_分类索引.md` — every local note/PDF link uses the legacy six-category paths.
- `文献逐篇阅读/00_逐篇阅读目录.md` — mirrors the legacy note and PDF paths.
- `00_三大类分类索引_v2.md` — links directly to the legacy reading-note paths.
- Any note named below that contains category-relative references must be rewritten after its source/target path changes.

## Shared PDF references

| Existing PDF path | Paper IDs | Handling |
|---|---|---|
| 01_编译阶段排序与强化学习调优/43-Problem-Oriented Code Optimization. arXiv 2024/paper.pdf | 51, 43 | Keep one physical PDF and retain distinct metadata/notes; do not duplicate blindly. |
| 02_LLM编译优化智能体与反馈驱动/16-Beyond Pass-by-Pass Optimization Intent-Driven IR Optimization with Large Language Models. arXi/paper.pdf | 16, 45 | Keep one physical PDF and retain distinct metadata/notes; do not duplicate blindly. |

## Collision and path-safety findings

- Every PDF leaf is named `paper.pdf`; a flat migration would therefore collide. The proposed map preserves each current paper-folder basename under its new secondary directory.
- No duplicate note basenames were detected.
- 169 planned paths contain Chinese characters, spaces, or parentheses. Future move scripts must use literal paths, quoted arguments, and Markdown destinations wrapped in angle brackets where necessary.
- Existing duplicate PDF references (2 group(s)) must be handled as version/duplicate metadata relationships rather than independent file moves.
- The 4 rows without a local PDF link must remain note-only/source-limited until a separate, approved acquisition pass.

## Affected Markdown files detected

- 00_三大类分类索引_v2.md
- 00_分类索引.md
- 08_六类论文创新点提炼/00_六类论文创新点总览.md
- 09_LLM_AI编译器低开销创新框架/02_信息价值门控的自适应反馈LLM智能体/信息价值反馈门控框架_修订版/preexperiment/README.md
- 09_LLM_AI编译器低开销创新框架/02_文献证据矩阵与创新碰撞检查.md
- 09_LLM_AI编译器低开销创新框架/03_完成报告与下一步.md
- 09_LLM_AI编译器低开销创新框架/05_三创新点同步改写实施计划.md
- 09_LLM_AI编译器低开销创新框架/99_材料生成实施计划.md
- CABLE/04_Demo升级设计/CABLE_Demo升级设计.md
- CABLE/README.md
- docs/superpowers/plans/2026-07-16-hardware-aware-llm-agent-materials.md
- docs/superpowers/plans/2026-07-16-six-compiler-innovations-08.md
- EPAS/01_核心研究框架/00_六类论文创新点总览.md
- EPAS/02_其余五类候选创新/01_Pass调优_跨架构效应解耦的少样本策略迁移.md
- EPAS/02_其余五类候选创新/02_编译智能体_真实后端实现对齐的意图反馈学习.md
- EPAS/02_其余五类候选创新/04_代码翻译_向量语义中间层驱动的可伸缩跨ISA迁移.md
- EPAS/03_设计与实施计划/EPAS_效应保持编译知识特化文档重构实施计划.md
- EPAS/03_设计与实施计划/效应保持的最小架构增量编译知识特化设计.md
- EPAS/04_文献分析/研究方向综合分析.md
- EPAS/04_文献分析/逐篇阅读/00_逐篇阅读目录.md
- EPAS/99_历史版本/通用—架构特化双层编译优化知识重构实施计划.md
- FACT_反馈驱动的可审计编译调优框架/README.md
- skills/maintaining-compiler-literature-corpus/references/corpus-contract.md
- taxonomy_v2_directory_migration_plan.md
- taxonomy_v2_link_impact_report.md
- 可执行证据契约驱动的LLM编译优化智能体/00_材料索引与使用说明.md
- 多平台自适应编译优化框架/04_实验进展/01_P0候选管线与正确性记录/01_P0候选管线与正确性记录_DeepSeek反馈.md
- 多平台自适应编译优化框架/04_实验进展/01_P0候选管线与正确性记录/01_P0候选管线与正确性记录_实施计划.md
- 多平台自适应编译优化框架/04_实验进展/02_P0补齐与规范化/02_P0补齐与规范化_DeepSeek反馈.md
- 多平台自适应编译优化框架/04_实验进展/02_P0补齐与规范化/02_P0补齐与规范化_实施计划.md
- 多平台自适应编译优化框架/04_实验进展/03_P0输入隔离与证据链修复/03_P0输入隔离与证据链修复_DeepSeek反馈.md
- 多平台自适应编译优化框架/04_实验进展/03_P0输入隔离与证据链修复/03_P0输入隔离与证据链修复_实施计划.md
- 多平台自适应编译优化框架/04_实验进展/04_P0证据持久化与TSVC执行/04_P0证据持久化与TSVC执行_DeepSeek反馈.md
- 多平台自适应编译优化框架/04_实验进展/04_P0证据持久化与TSVC执行/04_P0证据持久化与TSVC执行_实施计划.md
- 文献逐篇阅读/00_逐篇阅读目录.md
- 文献逐篇阅读/2024-2026_文献年份筛选清单.md
- 文献逐篇阅读/2026-09-07_LLM编译器近年文献增补验收.md
