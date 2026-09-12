# 24. Tensor Program Optimization for the RISC-V Vector Extension Using Probabilistic Programs. arXiv 2025.

> 主题分类：RISC-V RVV + TVM/MetaSchedule

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2507.01457](https://arxiv.org/abs/2507.01457)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\24-Tensor Program Optimization for the RISC-V Vector Extension Using Probabilistic Programs. arXiv`
- 本地 PDF 文件数：1；提取页数：9
- 阅读状态：完整 PDF 阅读

完整 PDF，9 页；重点依据摘要、提案、评价和结论。

## 1. 研究问题与动机

RVV 硬件差异大，GCC/LLVM 自动向量化与手写库难以同时适应不同 SoC；需要硬件感知的 tensor program 搜索。

## 2. 方法与系统结构

把 RVV intrinsics 接入 TVM MetaSchedule，以 probabilistic program 采样和调度搜索探索 tensor mappings；在 FPGA 上实现多个 RVV 1.0 SoC，并在商业 RVV SoC 上验证。

## 3. 实验与主要发现

报告平均相对 GCC 自动向量化约 46% latency improvement、相对 muRISCV-NN 约 29%，商业 RVV 1.0 SoC 上平均比 LLVM mapping 快约 35%，并得到较小代码存储 footprint。

## 4. 局限与批判性阅读

面向 AI tensor program，不是通用 LLVM IR；搜索成本、硬件实现和 FPGA 配置会影响结果；没有 LLM 或跨架构知识迁移机制。

## 5. 对当前研究方向的关系

它是多架构后端调优的重要基线：可作为 Backend Agent 的搜索器/教师，帮助定义平台条件、调优预算和真实性能 reward。

## 6. 可提炼的研究启发

硬件感知搜索已有强基线，CrossTune-RL 若做多平台必须证明 LLM Agent 带来更好的迁移或搜索效率，而非重复 MetaSchedule。

## 7. 一句话总结

硬件感知搜索已有强基线，CrossTune-RL 若做多平台必须证明 LLM Agent 带来更好的迁移或搜索效率，而非重复 MetaSchedule。
