# 01. AutoPhase: Juggling HLS Phase Orderings in Random Forests with Deep Reinforcement Learning. MLSys 2020.

> 主题分类：LLVM/HLS + 深度强化学习

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2003.00671](https://arxiv.org/abs/2003.00671)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\01-AutoPhase Juggling HLS Phase Orderings in Random Forests with Deep Reinforcement Learning. MLSy`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点依据第 1、3、5、6 节及结论。

## 1. 研究问题与动机

编译优化 Pass 的顺序是组合爆炸且非交换的；固定的 -O3 无法针对每个 HLS 程序选择合适顺序。

## 2. 方法与系统结构

AutoPhase 将 LLVM/LegUp HLS 环境建模为 RL 环境，使用 56 维 IR 特征、已执行 Pass 直方图或二者组合表示状态；用随机森林估计 Pass 与程序特征的相关性以缩小搜索空间，再比较 PPO、A3C、ES 等策略。奖励来自 HLS 时钟周期，训练阶段用快速 profiler，最终用硬件仿真验证。

## 3. 实验与主要发现

在 9 个真实基准上相对 -O3 报告约 28% 电路性能改善；训练于约 100 个随机程序后，对真实基准和大量随机程序表现出泛化能力；作者强调样本数少于若干传统搜索方法。

## 4. 局限与批判性阅读

目标是 HLS 电路周期而不是通用 CPU 运行时间；依赖 LegUp 的固定频率和 profiler；状态是静态特征，难以表达后端微架构差异；跨 ISA 迁移没有研究。

## 5. 对当前研究方向的关系

它证明了“IR 特征 → Pass 决策 → 后端/硬件反馈”的闭环可行，是后续 CrossTune-RL 的 RL 基线；但你的工作应把 HLS 周期监督扩展为多平台真实后端反馈。

## 6. 可提炼的研究启发

最值得继承的是程序特征驱动的搜索空间压缩和快速代理评估，而不是直接照搬其 HLS 设定。

## 7. 一句话总结

最值得继承的是程序特征驱动的搜索空间压缩和快速代理评估，而不是直接照搬其 HLS 设定。
