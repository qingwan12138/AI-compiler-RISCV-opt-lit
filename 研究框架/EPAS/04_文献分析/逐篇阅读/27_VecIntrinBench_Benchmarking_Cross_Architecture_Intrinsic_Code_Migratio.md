# 27. VecIntrinBench: Benchmarking Cross-Architecture Intrinsic Code Migration for RISC-V Vector. arXiv 2025.

> 主题分类：RISC-V intrinsic 迁移 benchmark

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2511.18867](https://arxiv.org/abs/2511.18867)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\27-VecIntrinBench Benchmarking Cross-Architecture Intrinsic Code Migration for RISC-V Vector. arXi`
- 本地 PDF 文件数：1；提取页数：5
- 阅读状态：完整 PDF 阅读

完整 PDF，5 页；重点依据 benchmark 构建、评价和讨论。

## 1. 研究问题与动机

缺少包含 RVV 的系统性 intrinsic migration benchmark，导致 NEON/x86 到 RVV 的规则映射和 LLM 方法无法公平比较。

## 2. 方法与系统结构

构建 VecIntrinBench，包含 50 个函数级任务，每个任务提供 scalar、RVV、Arm NEON、x86 intrinsic 实现及功能/性能测试；比较规则映射、LLM 生成和迁移策略。

## 3. 实验与主要发现

报告先进 LLM 在正确性上与规则映射相近，但性能可能更好；benchmark 还分析了不同迁移失败原因并开放数据。

## 4. 局限与批判性阅读

数据规模仍较小，任务主要来自开放源代码函数；短文实验不能代表整个 RVV 生态；需要明确各平台编译器和硬件环境。

## 5. 对当前研究方向的关系

它适合直接作为 CrossTune-RL 的跨架构迁移评测集，尤其用于验证平台条件、后端反馈和少样本适应。

## 6. 可提炼的研究启发

多架构方法需要同时报告语义正确、编译通过、性能和代码可维护性；只报 pass rate 不够。

## 7. 一句话总结

多架构方法需要同时报告语义正确、编译通过、性能和代码可维护性；只报 pass rate 不够。
