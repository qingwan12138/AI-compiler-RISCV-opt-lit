# 02. Compiler Phase-Ordering for High-Level Synthesis with Deep Reinforcement Learning. FCCM 2019 / arXiv.

> 主题分类：LLVM/HLS + 深度强化学习

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/1901.04615](https://arxiv.org/abs/1901.04615)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02-Compiler Phase-Ordering for High-Level Synthesis with Deep Reinforcement Learning. FCCM 2019 ar`
- 本地 PDF 文件数：1；提取页数：1
- 阅读状态：完整 PDF 阅读

完整 PDF，1 页会议摘要；证据集中在摘要和实验图表。

## 1. 研究问题与动机

早期工作探索如何用深度 RL 解决 HLS 中的编译阶段排序问题，并降低传统搜索的时间成本。

## 2. 方法与系统结构

使用 LLVM IR 的 56 个静态特征或已应用 Pass 的直方图作为状态，以 LegUp profiler 的时钟周期作为奖励；比较 Policy Gradient、DQN、随机搜索、贪心、遗传算法和 -O3。

## 3. 实验与主要发现

在 12 个 CHstone/LegUp HLS 基准上，RL 和遗传算法取得约 16% 的电路性能提升；RL 与遗传算法效果相近，但运行速度约快 3 倍，完整训练可在分钟级完成。

## 4. 局限与批判性阅读

这是初步短文，实验规模较小；没有系统研究跨程序、跨硬件或长序列信用分配；性能指标是 HLS 周期，不能直接外推到 RISC-V CPU。

## 5. 对当前研究方向的关系

可作为 AutoPhase 的前身基线，帮助区分“RL 搜索本身的贡献”和“多平台后端性能对齐”的新增贡献。

## 6. 可提炼的研究启发

该文的价值是建立了最小闭环：编译器状态、Pass 动作、快速性能反馈和 RL。

## 7. 一句话总结

该文的价值是建立了最小闭环：编译器状态、Pass 动作、快速性能反馈和 RL。
