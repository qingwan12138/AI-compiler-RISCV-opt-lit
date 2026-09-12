---
name: developing-compiler-innovations
description: Use when extracting, reviewing, rewriting, or comparing compiler research innovations from a Taxonomy v2 literature corpus, especially role-based gap analysis, novelty collision checks, experiment design, minimum demos, or selecting one thesis main line across LLVM, LLM optimization, formal verification, RISC-V/RVV, cross-ISA, and multi-hardware compilation.
---

# 编译器科研创新点分析

## 核心原则

创新方向必须由可追溯的论文证据和可验证的研究空白推导。旧创新点文件只提供候选线索，不构成事实或预设结论。严格区分【论文事实】【合理推导】【候选创新】；证据不足时降低推荐等级，并列出待检索关键词。

开始分析前，必须完整读取 [references/requirements.md](references/requirements.md)。其中规定 Taxonomy v2 证据读取、三角色分析、横向标签、候选评价、实验门控和输出合同。

## 语料库证据接口

- 本仓库以 `taxonomy_v2.csv` 为当前分类和路径总账。通过 `Paper_ID` 定位论文，使用 `Primary_Category`、`Secondary_Category`、`Role`、`Note_Path` 等字段组织证据；按 `Note_Path` 读取笔记，并在结论关键处回查 PDF 正文。
- 当前四个主类是 `SELECTOR`、`TRANSLATOR`、`GENERATOR`、`SUPPORTING`。创新主体围绕前三个核心角色分析；`SUPPORTING` 用于提供基线、数据、工具、编译器基础设施、硬件背景或评价约束，不强行作为第四个 LLM 创新角色。
- RISC-V/RVV、LLVM/MLIR、形式验证、反馈、强化学习、Agent、多硬件等作为“横向标签”用于跨角色比较，不是互斥的主类。
- 旧逐篇目录的六类标题仅作历史导航；迁移快照仅在需要审计分类迁移时查阅。常规研究分析不重建迁移映射，也不以旧路径覆盖当前 taxonomy。
- 本技能负责研究分析，不直接改动 `taxonomy_v2.csv`、分类索引、逐篇目录、年份清单或论文文件。新论文正式登记交给 `maintaining-compiler-literature-corpus`。

## 证据读取顺序

1. 明确研究问题、分析范围、时间边界和用户期望的产物；读取 taxonomy、对应 Paper_ID 笔记及必要的 PDF。
2. 汇总每项工作解决的问题、机制、实验证据、局限和适用边界；不得仅凭目录、标签或笔记结论推断论文事实。
3. 对近期新颖性、撞车风险或“是否首次”进行可复现的文献检索，记录关键词、日期、来源和近邻论文；未检索不得使用优先权式表述。
4. 先在 SELECTOR、TRANSLATOR、GENERATOR 内部分别形成候选，再借助横向标签和 SUPPORTING 证据检查跨角色重叠、依赖与边界。
5. 比较机制增量和证据强弱，最终只推荐一条“唯一论文主线”；其他方向明确降为支撑模块、扩展、备选或暂缓。

## 创新边界与完成条件

- 换平台、换模型、增加 RAG/Agent/强化学习/LoRA/提示词、接入 Alive2、增加数据库、统计指令或在真实硬件运行，本身不构成创新。
- 候选必须说清研究对象、未解决的问题、新增机制、与近邻工作的区别，以及能否通过对照和消融验证。
- 最终推荐必须给出可执行的最小 Demo、正式实验设计、风险与降级方案，以及会否定该主张的可证伪条件。
- 使用简体中文；术语首次出现时给英文全称和白话解释。证据、引用和不确定性要与具体 Paper_ID 对应。
- 只有完成要求文件中的证据、碰撞、实验和自检后，才能报告结论；如检索、PDF 或硬件条件不足，明确标注未完成项，不要把计划写成结果。
