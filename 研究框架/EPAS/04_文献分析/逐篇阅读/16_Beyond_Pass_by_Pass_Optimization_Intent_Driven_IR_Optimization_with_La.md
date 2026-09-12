# 16. Beyond Pass-by-Pass Optimization: Intent-Driven IR Optimization with Large Language Models. arXiv 2026.

> 主题分类：意图驱动 IR 优化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2602.18511](https://arxiv.org/abs/2602.18511)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\16-Beyond Pass-by-Pass Optimization Intent-Driven IR Optimization with Large Language Models. arXi`
- 本地 PDF 文件数：2；提取页数：47
- 阅读状态：完整 PDF 阅读

完整 PDF，47 页；另有第 45 条重复/不同版本 PDF；重点依据摘要、第 3-4 节和结论。

## 1. 研究问题与动机

逐 Pass 优化可能出现局部收益阻塞全局收益；传统编译器把优化意图隐含在各个 Pass 中，LLM 端到端生成又把策略和低级变换混在一起。

## 2. 方法与系统结构

IntOpt 将 IR 优化拆成 intent formulation、intent refinement、intent realization 三阶段：LLM 先生成结构化整体策略，再检索编译器知识并运行分析，最后在约束下实现具体 IR 变换。

## 3. 实验与主要发现

在 200 个 LLVM IR 程序上报告 90.5% verified correctness、2.660x 平均 speedup；在 37 个基准上超过 LLVM -O3，并报告最高 272.60x 个别加速。

## 4. 局限与批判性阅读

这是 2026 年预印本，结果数字需要独立复现；LLM 负责的具体变换、验证覆盖和 benchmark 分布需要审查；主要仍停留在 IR 层，未将跨架构后端收益纳入意图。

## 5. 对当前研究方向的关系

它直接占据了此前设想的“Optimization Intent”空间，因此 CrossTune-RL 不宜再把“显式意图”作为唯一核心创新；更好的切口是后端 realization 和跨架构意图迁移。

## 6. 可提炼的研究启发

该文把“LLM 学 Pass”推进到“LLM 学全局优化策略”；你的新增问题应是同一意图在不同后端上是否实现、哪些意图可迁移。

## 7. 一句话总结

该文把“LLM 学 Pass”推进到“LLM 学全局优化策略”；你的新增问题应是同一意图在不同后端上是否实现、哪些意图可迁移。
