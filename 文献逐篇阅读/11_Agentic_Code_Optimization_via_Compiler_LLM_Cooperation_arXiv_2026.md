# 11. Agentic Code Optimization via Compiler-LLM Cooperation. arXiv 2026.

> 主题分类：多层次 LLM-Compiler Agent

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2604.04238](https://arxiv.org/abs/2604.04238)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\11-Agentic Code Optimization via Compiler-LLM Cooperation. arXiv 2026`
- 本地 PDF 文件数：1；提取页数：23
- 阅读状态：完整 PDF 阅读

完整 PDF，23 页；重点依据方法总览和结论；部分文本提取存在排版噪声。

## 1. 研究问题与动机

单一抽象层的 LLM 优化难以同时利用源代码语义、IR 结构和低级硬件信息；需要在正确性和搜索能力之间平衡。

## 2. 方法与系统结构

ACCLAIM 将源代码、IR 和汇编三个层级的 LLM 优化 agent 与现有编译器组件结合，并设置 guiding agent 在现有 compiler rewrites 和 LLM-based level-specific agents 之间选择，形成多层协作。

## 3. 实验与主要发现

结论报告整体平均约 1.25x speedup，并在个别输入上取得数量级提升；作者声称多层 cooperation 优于单层 LLM 或单纯编译器优化。

## 4. 局限与批判性阅读

多层 agent 的职责、评测预算和各层贡献需要细看实验；研究重点是多层协作而非跨架构迁移；若只添加一个后端 agent，容易与此类工作重叠。

## 5. 对当前研究方向的关系

它是 CrossTune-RL 双智能体框架需要正面比较的相邻工作。你的区别必须落在平台条件化、跨架构知识迁移和可验证的 IR—后端反馈机制。

## 6. 可提炼的研究启发

“多个层级”不是天然创新；应证明为何 IR 与目标后端的分层具有独立的状态、动作、时间尺度和迁移收益。

## 7. 一句话总结

“多个层级”不是天然创新；应证明为何 IR 与目标后端的分层具有独立的状态、动作、时间尺度和迁移收益。
