# 23. Closer in the Gap: Towards Portable Performance on RISC-V Vector Processors. arXiv 2026.

> 主题分类：RVV 编译器与真实性能分析

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2605.10860](https://arxiv.org/abs/2605.10860)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\23-Closer in the Gap Towards Portable Performance on RISC-V Vector Processors. arXiv 2026`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点依据摘要、第 1-6 节和结论。

## 1. 研究问题与动机

RVV 1.0 硬件和编译器支持仍在演进；predication、stride load、VL/LMUL 选择和性能计数器可靠性会影响可移植性能。

## 2. 方法与系统结构

设计 RVV 汇编 microbenchmarks 校准 BananaPi-F3 等硬件的性能计数器，比较 GCC 15 与 Clang 21 在六个科学/ML proxy applications 上的代码生成，并实现 Qsim 的 RVV backend。

## 3. 实验与主要发现

摘要报告 predication overhead 和 stride load 是当前 cost model 未充分捕获的瓶颈；GCC 15 在 6 个 benchmark 中 4 个更稳定/高效，Clang 在 SGEMM/DGEMM 上更好；默认 LMUL 多数情况下接近最优，但 GCC 对更大 LMUL 有更多收益空间。

## 4. 局限与批判性阅读

硬件平台和 perf 事件具有设备特异性；比较结果依赖编译器版本、VLEN/LMUL 和 benchmark；论文主要是测量/分析，不是 LLM 调优方法。

## 5. 对当前研究方向的关系

它直接支持“IR 优化—后端实现—真实 RVV 性能”的研究动机：同一 IR 变化可能被 GCC/Clang 以不同方式降低，静态 IR 指标不能替代后端反馈。

## 6. 可提炼的研究启发

真实性能闭环必须记录编译器版本、硬件计数器可用性和重复测量噪声。

## 7. 一句话总结

真实性能闭环必须记录编译器版本、硬件计数器可用性和重复测量噪声。
