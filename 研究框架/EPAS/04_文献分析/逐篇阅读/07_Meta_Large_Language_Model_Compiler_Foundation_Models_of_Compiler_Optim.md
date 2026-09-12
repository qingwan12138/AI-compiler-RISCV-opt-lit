# 07. Meta Large Language Model Compiler: Foundation Models of Compiler Optimization. arXiv 2024.

> 主题分类：LLM 编译器基础模型

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2407.02524](https://arxiv.org/abs/2407.02524)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\07-Meta Large Language Model Compiler Foundation Models of Compiler Optimization. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：33
- 阅读状态：完整 PDF 阅读

完整 PDF，33 页；重点依据摘要、第 2-3 节和下游任务评估。

## 1. 研究问题与动机

通用代码 LLM 对 LLVM IR、汇编和编译优化知识不足，直接提示容易产生错误或低质量优化；从零训练编译专用模型成本很高。

## 2. 方法与系统结构

以 Code Llama 为基础，使用约 401B tokens 的 LLVM IR/assembly 预训练，再用约 145B tokens 做 compiler emulation；随后用 flag tuning 和 disassembly 数据继续微调，形成 7B/13B LLM Compiler 及 FTD 版本。

## 3. 实验与主要发现

模型能学习 IR/汇编之间的关系；在代码尺寸 flag tuning 上报告达到 autotuning 优化潜力的约 77%，并报告反汇编 round-trip 与 exact-match 指标；还提供 PassListEval 对候选 Pass 列表进行编译和测试。

## 4. 局限与批判性阅读

训练规模极大，主要数据集中于 x86-64 和 ARM，CUDA 仅占很小部分；下游任务主要优化代码尺寸，仍然需要外部编译和正确性检查；没有真实 RISC-V 或跨架构适应实验。

## 5. 对当前研究方向的关系

它提供强大的 LLM 编译器初始化模型，但 CrossTune-RL 不应把“使用更大的编译器 LLM”作为创新；应研究如何让模型从多平台后端反馈中学习可迁移策略。

## 6. 可提炼的研究启发

最有用的是 compiler emulation、PassListEval 和 IR/assembly 联合表示，可作为后端智能体的预训练或教师模型。

## 7. 一句话总结

最有用的是 compiler emulation、PassListEval 和 IR/assembly 联合表示，可作为后端智能体的预训练或教师模型。
