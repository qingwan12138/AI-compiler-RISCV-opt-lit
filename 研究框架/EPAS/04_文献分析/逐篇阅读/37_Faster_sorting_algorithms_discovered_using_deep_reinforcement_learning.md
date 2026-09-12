# 37. Faster sorting algorithms discovered using deep reinforcement learning. Nature 2023.

> 主题分类：深度 RL 发现低级算法

## 阅读范围与证据边界

- 原始来源：[https://www.nature.com/articles/s41586-023-06004-9](https://www.nature.com/articles/s41586-023-06004-9)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\37-Faster sorting algorithms discovered using deep reinforcement learning. Nature 2023`
- 本地 PDF 文件数：1；提取页数：17
- 阅读状态：完整 PDF 阅读

完整 PDF，17 页；重点依据摘要、AssemblyGame、搜索算法、结果和讨论。

## 1. 研究问题与动机

一些高频基础算法已经难以靠人工继续优化；希望在真实 CPU 指令级 latency 上发现正确且更快的算法。

## 2. 方法与系统结构

AlphaDev 将组装短排序算法表述为 AssemblyGame，使用深度 RL 在低级指令空间搜索；用正确性测试和 CPU latency 作为约束/奖励，最终将发现的排序组件合入 LLVM C++ sort library。

## 3. 实验与主要发现

发现的小排序算法超过既有人工基准，并进入 LLVM 标准库；工作展示了 RL 可以把搜索结果转化为真实生产代码，而不只优化代理指标。

## 4. 局限与批判性阅读

搜索任务是特定的短排序/低级指令序列，验证依赖有限测试和搜索约束；跨 ISA、多平台迁移和高层 IR Pass 不在核心范围。

## 5. 对当前研究方向的关系

它说明真实指令级延迟可以作为最终 reward，并且发现的优化可以回流到编译器；对后端 Agent 的硬件闭环有启发。

## 6. 可提炼的研究启发

你的工作可把这种“真实后端 reward”向上连接到 IR 动作，并研究哪些收益能跨架构迁移。

## 7. 一句话总结

你的工作可把这种“真实后端 reward”向上连接到 IR 动作，并研究哪些收益能跨架构迁移。
