---
name: maintaining-compiler-literature-corpus
description: Use when discovering, verifying, downloading, classifying, or adding compiler papers to a maintained literature corpus with PDF files, reading notes, and synchronized indexes.
---

# 编译器文献语料库维护

把新论文从候选到正式入库视为一个状态事务。当前分类依据和文件位置以仓库中的 `taxonomy_v2.csv` 为准；分类规则见 `docs/taxonomy/taxonomy_v2_rules.md`，具体字段与更新约定见 [references/corpus-contract.md](references/corpus-contract.md)。开始前读取这两份文件并检查当前工作区状态。

## 当前仓库入口

- 机器可读总账：`taxonomy_v2.csv`
- 当前角色索引：`00_三大类分类索引_v2.md`
- 阅读笔记目录：`文献逐篇阅读/00_逐篇阅读目录.md`
- 候选状态：`文献逐篇阅读/2024-2026_文献年份筛选清单.md`
- 可选处理日志：`文献逐篇阅读/候选处理缓存.jsonl`
- PDF 和笔记按 `SELECTOR`、`TRANSLATOR`、`GENERATOR`、`SUPPORTING` 主类镜像存放。

`taxonomy_v2.csv` 是主类、二级类、Paper_ID 和本地路径的权威来源。Agent、RL、形式验证、LLVM/MLIR、RISC-V/RVV、GPU 与反馈属于横向标签，不替代主类。

## 工作流程

1. 按用户给定的研究方向生成多维关键词并联网检索。候选须主题直接相关、年份与当前筛选范围相符、元数据可核验且正文可获得；按 DOI、arXiv ID 和规范化题名检查重复。
2. 依据论文中语言模型的最终编译系统角色提出一个 `Primary_Category` 和一个兼容的 `Secondary_Category`。对不确定条目设置 `Needs_Review=YES`，并记录证据与置信度。
3. 先在年份清单登记候选及精确状态；分配未用的 Paper_ID。重复或不合格条目保留原因，不进入本地 PDF 和笔记路径。
4. 下载前预检 PDF 响应；保存到目标二级分类目录的 `paper.pdf`，验证 PDF 签名和可解析页数。复用已有有效文件。
5. **REQUIRED SUB-SKILL:** 对可获得的正文使用 `reading-compiler-literature` 生成 13 节笔记。只依据正文记录论文事实；源材料受限时明确标注。
6. 将完整新条目同步至 `taxonomy_v2.csv`、当前角色索引和年份清单；同时把笔记加入逐篇阅读目录。旧六类目录中的历史行按现有内容保留；新笔记目录行放入文献阅读目录的 Taxonomy v2 新增区，并以 taxonomy 的主类/二级类标注。
7. 运行 taxonomy、索引链接、候选缓存和语料库验证。任何 Paper_ID、分类、PDF、笔记或链接不一致时，修复后再报告完成。
8. Git 提交或推送只在用户明确要求时进行；只暂存本批次文件，提交信息遵守仓库 `AGENTS.md` 约定。

## 完成报告

报告检索关键词组、发现与去重数量、成功/失败项、PDF 和笔记计数、四个状态文件的变化、验证结果，以及尚需人工复核事项。未通过校验时清楚报告失败阶段，不声称入库完成。
