# 31. TVM: An Automated End-to-End Optimizing Compiler for Deep Learning. OSDI 2018.

> 主题分类：跨硬件深度学习编译器

## 阅读范围与证据边界

- 原始来源：[https://www.usenix.org/conference/osdi18/presentation/chen](https://www.usenix.org/conference/osdi18/presentation/chen)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\31-TVM An Automated End-to-End Optimizing Compiler for Deep Learning. OSDI 2018`
- 本地 PDF 文件数：1；提取页数：17
- 阅读状态：完整 PDF 阅读

完整 PDF，17 页；重点依据摘要、系统设计、自动优化和评价章节。

## 1. 研究问题与动机

深度学习需要部署到 CPU、GPU、FPGA、ASIC 等异构平台，而 vendor library 和手工 operator tuning 难以覆盖新后端。

## 2. 方法与系统结构

TVM 统一 graph-level 与 operator-level 优化，使用 tensor expression、schedule space、tensorization、memory latency hiding 和学习型 cost model；通过 device pool/RPC 自动搜索不同硬件的高性能实现。

## 3. 实验与主要发现

在低功耗 CPU、移动 GPU、服务器 GPU 和 FPGA 等平台上达到与手工库竞争的性能，并展示新增 accelerator backend 的可扩展性。

## 4. 局限与批判性阅读

主要针对 tensor/DL workloads，搜索依赖人工定义的 schedule space 和 cost model；不是通用 LLVM IR 或 LLM agent；跨平台共享不是通过显式知识分解实现。

## 5. 对当前研究方向的关系

TVM 是多架构后端调优的核心基线。CrossTune-RL 应说明自己为何处理通用 IR/编译 Pass，并与 schedule-based autotuning 的层级区别。

## 6. 可提炼的研究启发

它证明硬件条件化 cost model 和自动搜索可提升性能，但也提示真实硬件测量成本是核心约束。

## 7. 一句话总结

它证明硬件条件化 cost model 和自动搜索可提升性能，但也提示真实硬件测量成本是核心约束。
