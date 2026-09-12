# 42. CompilerGPT: Leveraging Large Language Models for Analyzing and Acting on Compiler Optimization Reports. arXiv 2025.

> 主题分类：编译器优化报告 + LLM

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2506.06227](https://arxiv.org/abs/2506.06227)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\42-CompilerGPT Leveraging Large Language Models for Analyzing and Acting on Compiler Optimization`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点依据摘要、workflow、实验和局限。

## 1. 研究问题与动机

Clang/GCC 的 optimization report 包含重要诊断，但信息复杂，程序员难以据此定位代码瓶颈和修改方向。

## 2. 方法与系统结构

CompilerGPT 让 LLM 读取编译器优化报告，并在用户测试/评估 harness 约束下迭代改写代码；使用 chain-of-thought、negative prompting 和多轮反馈，实验覆盖 GPT-4o/Claude 与 Clang/GCC。

## 3. 实验与主要发现

在五个 benchmark 上报告最高约 6.5x speedup，但结果并不稳定；报告摘要/优先级列表有助于把编译器诊断转换为可操作建议。

## 4. 局限与批判性阅读

需要用户提供测试，规模较大的代码需要人工选热点，LLM 输出跨运行不稳定；优化报告层级和真实机器性能的映射仍不完整。

## 5. 对当前研究方向的关系

它启发 Backend Agent 输出“可解释诊断”而不只是一个分数；CrossTune-RL 可将 spill、向量化失败、访存瓶颈等报告结构化返回 IR Agent。

## 6. 可提炼的研究启发

后端反馈的价值不仅是 reward，还包括能指导下一步动作的失败原因。

## 7. 一句话总结

后端反馈的价值不仅是 reward，还包括能指导下一步动作的失败原因。
