# 05. MileStone: A Multi-Objective Compiler Phase Ordering Framework. arXiv 2026.

> 主题分类：多目标编译阶段排序

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/html/2605.23435](https://arxiv.org/html/2605.23435)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\05-MileStone A Multi-Objective Compiler Phase Ordering Framework. arXiv 2026`
- 本地 PDF 文件数：1；提取页数：24
- 阅读状态：完整 PDF 阅读

完整 PDF，24 页；重点依据摘要、第 3-5 节及结论；数值需后续复现。

## 1. 研究问题与动机

运行时间、代码尺寸和能耗之间存在冲突，固定优化级别难以在不同程序和约束下提供 Pareto 最优方案。

## 2. 方法与系统结构

MileStone 用 CDFG/图表示程序，以 GNN 预测性能指标，使用 DQN/PPO 探索 Pass 序列，并通过 RL-based Database Generator 收集程序图、Pass 序列和指标，形成自演化数据库；策略可由能耗目标等用户约束驱动。

## 3. 实验与主要发现

论文报告在相同能耗预算下最多约 45% 的执行时间改善，并声称能发现时间、尺寸、能耗之间的 Pareto 方案；新 CDFG 可直接使用预训练模型，也可针对单个图微调。

## 4. 局限与批判性阅读

许多结果依赖预测的性能指标而非持续真实硬件测量；能耗建模、数据规模、基线和随机性需要复现核查；论文是较新的预印本，不能把报告数字直接当作已充分验证的事实。

## 5. 对当前研究方向的关系

它提示 CrossTune-RL 可将平台和目标约束显式放入状态与奖励，但你的核心应放在跨架构迁移和真实后端验证，而不是再做一个泛化的多目标 RL 框架。

## 6. 可提炼的研究启发

可借鉴其 Pareto/预算思想，作为后端智能体的目标约束或实验维度。

## 7. 一句话总结

可借鉴其 Pareto/预算思想，作为后端智能体的目标约束或实验维度。
