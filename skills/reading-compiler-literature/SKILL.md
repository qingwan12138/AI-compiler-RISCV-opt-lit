---
name: reading-compiler-literature
description: Use when reading one or more academic papers about compilers, LLVM, LLM-based optimization, reinforcement learning, formal verification, RISC-V/RVV, cross-ISA migration, or multi-hardware compilation, especially when producing standardized Chinese Markdown notes or updating a literature index.
---

# 编译器文献逐篇阅读

## 核心原则

以论文正文为事实依据，完整、通俗地说明论文做了什么，并把论文事实、阅读分析和后续建议严格分开。

开始任务前，必须完整读取 [references/requirements.md](references/requirements.md)。其中的章节格式、证据规则和自检清单是输出合同。

## 仓库语料库接口

当任务针对本仓库的现有语料时：

- 先按 `Paper_ID` 在 `taxonomy_v2.csv` 查找记录；`Primary_Category`、`Secondary_Category` 和 `Note_Path` 以该记录为准，不根据旧六类目录或笔记路径重新分类。
- 当前主类是 `SELECTOR`、`TRANSLATOR`、`GENERATOR`、`SUPPORTING`；目录名和索引文件名不替代总账字段。
- 阅读现有 PDF 并只创建或更新该记录的 `Note_Path` 笔记。不要由本技能直接改写 taxonomy、分类索引、年份清单或候选状态。
- 如果没有对应记录，输出论文阅读结果以及建议的主类/二级类，不自行分配正式路径或宣称已入库；将登记、路径分配和索引同步交给 `maintaining-compiler-literature-corpus`。
- 本仓库人类可读逐篇目录为 `文献逐篇阅读/00_逐篇阅读目录.md`。它包含历史六类分组；这些标题仅保留历史语境，不是当前分类依据。
- 如用户同时要求批量新增语料，先完成逐篇笔记，再把已完成/失败的 Paper_ID 和路径交给维护技能处理正式入库事务。

若任务是仓库之外的独立阅读，可按用户要求输出笔记；只有用户明确要求时才另建通用总目录，不将仓库的 taxonomy 同步职责带入独立任务。

## 工作流程

1. 清点输入 PDF、Paper_ID、已有笔记和目录文件，建立待处理清单；仓库语料任务先读取 taxonomy 中的分类和目标 `Note_Path`，并识别同一论文的重复副本。
2. 逐篇阅读摘要、引言、相关工作、方法、实验、消融、局限和结论。不能只看标题或摘要，也不能把旧笔记当作正文证据。
3. 先判断论文类型：研究论文、综述、工具/系统、数据集或技术资源。不存在的训练、奖励或实验内容使用要求文件规定的缺失说明，禁止补写。
4. 每篇生成独立 Markdown 文件，严格保留要求文件规定的 13 个一级章节。逐篇笔记不设计最小可行 Demo；该内容只在跨文献创新提炼阶段针对最终推荐方案集中设计。专业术语第一次出现时给出英文全称和白话解释。
5. 对关键结论标注章节、图或表的位置；对关键数字同时记录对比对象、数据集、指标、统计口径和数值含义。
6. 批量任务必须处理全部论文。仓库语料任务不直接更新总账或索引，完成后将处理结果交给维护技能；独立任务仅按用户要求更新总目录。中断后先比较待处理清单与已有输出，再从未完成项继续。
7. 完成前逐项检查事实、数字、标题层级、表格、代码块、本地链接、文件数量和目录覆盖率。

## 证据纪律

- PDF 未明确说明时写“论文中未明确说明。”
- PDF 内容不足以确认数字、公式或结果时写“当前 PDF 内容不足以确认该信息。”
- 不把语法正确写成语义等价，不把有限测试写成形式化证明，不把静态估计写成真实硬件时间。
- 不把作者未来工作或阅读后的建议写成论文已实现的贡献。
- 不因论文涉及 LLVM、RISC-V、LLM 或强化学习就扩大其适用范围。

## 完成报告

交付时摘要列出：输入论文数、独立论文数、完成笔记数、重复项、失败项、无法确认事项和关键目录文件。除非用户要求，不输出完整文件清单或大段 diff。只在数量一致且质量检查通过后声称完成。
