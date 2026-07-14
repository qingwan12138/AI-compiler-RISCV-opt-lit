# 32. Learning to Optimize Tensor Programs. NeurIPS 2018.

> 主题分类：张量程序学习型 cost model

## 阅读范围与证据边界

- 原始来源：[https://proceedings.neurips.cc/paper/2018/hash/8b5700012be65c9da25f49408d959ca0-Abstract.html](https://proceedings.neurips.cc/paper/2018/hash/8b5700012be65c9da25f49408d959ca0-Abstract.html)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\32-Learning to Optimize Tensor Programs. NeurIPS 2018`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点依据第 2-4、6-7 节。

## 1. 研究问题与动机

张量程序有数十亿种实现，手工库只覆盖少数硬件；需要用学习模型提高搜索样本效率并迁移已有经验。

## 2. 方法与系统结构

学习 domain-specific statistical cost model 预测候选 schedule 的性能，用探索模块搜索程序变体，并通过 transfer learning 从已有 workload/硬件的测量结果初始化新任务。

## 3. 实验与主要发现

在低功耗 CPU、移动 GPU 和服务器 GPU 上达到接近手工库的性能；transfer learning 能降低新 workload 的搜索成本。

## 4. 局限与批判性阅读

面向张量程序，cost model 依赖目标硬件测量；迁移单位是 schedule/cost model，不是通用 LLVM Pass 或 LLM 的语义知识。

## 5. 对当前研究方向的关系

它是“多平台快速适应”的传统强基线，可借鉴跨平台共享模型、少量测量和不确定性驱动搜索。

## 6. 可提炼的研究启发

如果 CrossTune-RL 只说“共享策略+Adapter”，会与这类工作相似；必须明确编译 IR 与后端协同的新增内容。

## 7. 一句话总结

如果 CrossTune-RL 只说“共享策略+Adapter”，会与这类工作相似；必须明确编译 IR 与后端协同的新增内容。
