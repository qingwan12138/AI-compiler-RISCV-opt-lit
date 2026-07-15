---
name: maintaining-compiler-literature-corpus
description: Use when expanding a compiler research direction into a maintained 2024–2026 literature corpus, especially when keyword generation, online paper discovery, metadata verification, categorized PDF downloads, standardized Chinese reading notes, or synchronized literature indexes are requested.
---

# 编译器文献语料库全流程维护

## 核心原则

把“发现、下载、阅读、入库”视为一个有状态事务。论文文件、阅读笔记、逐篇目录、分类索引和年份清单全部一致之前，任务仍未完成。

开始前完整读取 [references/corpus-contract.md](references/corpus-contract.md)。该文件规定分类、关键词、证据、命名、状态和索引格式。

## 工作流程

1. **重建现状**：清点六类目录、PDF、笔记、`00_分类索引.md`、`文献逐篇阅读/00_逐篇阅读目录.md` 和年份筛选清单。以文件系统为准，不依赖聊天记忆。
2. **扩展关键词**：把用户研究方向拆为主题、编译对象、方法、证据和硬件/IR 五维矩阵，生成同义词和英文组合；不得围绕预设框架定向搜证。
3. **联网检索**：必须搜索互联网，只纳入首次公开或正式发表时间为 2024–2026 的成果。优先论文主页、正式 proceedings、出版社、arXiv、ACL Anthology、OpenReview 和作者主页。
4. **核验与去重**：核对题名、作者、年份、渠道、DOI/arXiv ID、摘要、PDF 链接和正式版关系；用规范化题名、DOI、arXiv ID 三重去重。
5. **先登记候选**：将合格候选写入年份筛选清单，分配未使用编号并标记 `元数据已核验` 或明确失败状态。此时不能写成已下载或已阅读。
6. **分类下载**：按唯一主类别创建论文目录，保存为 `paper.pdf`；检查 `%PDF-` 签名并用 PDF 解析器读取页数，成功后推进状态。
7. **逐篇阅读**：**REQUIRED SUB-SKILL:** 使用 `reading-compiler-literature`。只以 PDF 正文为事实依据生成统一 14 节中文笔记；正文不可得时不得伪装为全文阅读。
8. **同步入库**：同一批次更新逐篇阅读目录、分类索引、年份候选状态，以及分类、完整 PDF、源材料受限和优先级统计。两个索引都必须提供可点击的笔记和本地 PDF 链接。
9. **验证交付**：运行 `scripts/validate_literature_corpus.ps1 -Root <语料库根目录>`。只有退出码为 0 才能报告完成。

## 中断续跑

- 已有有效 PDF 不重复下载；已有合格 14 节笔记不重写。
- 每次恢复时按状态机找第一个未完成阶段，从那里继续。
- 单篇失败不阻塞其他论文，但必须在年份清单和最终报告中保留原因。
- 正式版与预印本为同一工作时只保留一个语料条目，并同时记录首次公开年份与正式渠道。

## 完成报告

列出检索关键词组、发现数、去重后候选数、下载成功数、有效 PDF 数、完成笔记数、三文件新增数、失败项及验证摘要。数量不一致时报告实际状态，不声称完成。
