# 62. LLM4Decompile: Decompiling binary code with LLMs

> 主题分类：大模型二进制反编译

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2024.emnlp-main.203.pdf](https://aclanthology.org/2024.emnlp-main.203.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\52-LLM4Decompile Decompiling Binary. EMNLP 2024`
- 本地 PDF 文件数：1；提取页数：15
- 阅读状态：完整 PDF 阅读

完整 PDF，15 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何提高二进制到可执行、可读 C 代码的反编译质量。

## 2. 方法与系统结构

训练 1.3B–33B 端到端反编译模型，并训练 Ref 模型精炼 Ghidra 输出。

## 3. 实验与主要发现

6.7B 模型在 HumanEval/ExeBench 为 45.4%/18.0%，较 Ghidra 和 GPT-4o 提升逾一倍；精炼再提升 16.2%。

## 4. 局限与批判性阅读

仅覆盖 C/x86；测试与重执行率不能还原全部语义，训练成本和滥用风险较高。

## 5. 对当前研究方向的关系

主要提供二进制语义恢复背景，与 CABLE 核心问题间接相关。

## 6. 可提炼的研究启发

传统分析器与 LLM 精炼组合通常比纯端到端替代更可靠。

## 7. 一句话总结

传统分析器与 LLM 精炼组合通常比纯端到端替代更可靠。
