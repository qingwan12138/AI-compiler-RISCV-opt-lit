# 35. MLIR: Scaling Compiler Infrastructure for Domain Specific Computation. CGO 2021.

> 主题分类：多层 IR 编译基础设施

## 阅读范围与证据边界

- 原始来源：[https://ieeexplore.ieee.org/document/9370308](https://ieeexplore.ieee.org/document/9370308)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\35-MLIR Scaling Compiler Infrastructure for Domain Specific Computation. CGO 2021`
- 本地 PDF 文件数：1；提取页数：21
- 阅读状态：完整 PDF 阅读

完整 PDF，21 页；重点依据摘要、设计原则和应用案例。

## 1. 研究问题与动机

不同领域需要不同抽象层和专用优化；如果每个领域独立开发 IR、parser、pass manager 和 lowering，工程成本和质量问题会迅速累积。

## 2. 方法与系统结构

MLIR 提供可扩展的多层 IR 基础设施、dialect、声明式 operation、SSA 数据结构、pass 管理、location tracking、并行编译和 lowering 组件。

## 3. 实验与主要发现

论文通过多个领域案例展示统一基础设施的可扩展性和可组合性，目标是让领域特定编译器更容易建立和演进。

## 4. 局限与批判性阅读

MLIR 是基础设施设计论文，不提供 CrossTune-RL 的学习算法或跨硬件性能结论；实际 lowering 和 dialect 质量仍需工程验证。

## 5. 对当前研究方向的关系

它可以承载“高层 IR 意图—低层目标 dialect—后端反馈”的分层 agent，尤其适合把 IR Agent 和 Backend Agent 的边界结构化。

## 6. 可提炼的研究启发

多层优化智能体应尽量对齐编译器已有抽象层，而不是把所有动作混成自然语言。

## 7. 一句话总结

多层优化智能体应尽量对齐编译器已有抽象层，而不是把所有动作混成自然语言。
