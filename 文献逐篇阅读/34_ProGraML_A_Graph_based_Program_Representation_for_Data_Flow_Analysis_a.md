# 34. ProGraML: A Graph-based Program Representation for Data Flow Analysis and Compiler Optimizations. ICML 2021.

> 主题分类：程序图表示学习

## 阅读范围与证据边界

- 原始来源：[https://proceedings.mlr.press/v139/cummins21a.html](https://proceedings.mlr.press/v139/cummins21a.html)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\34-ProGraML A Graph-based Program Representation for Data Flow Analysis and Compiler Optimizations`
- 本地 PDF 文件数：1；提取页数：10
- 阅读状态：完整 PDF 阅读

完整 PDF，10 页；重点依据摘要、图表示方法、任务和评价章节。

## 1. 研究问题与动机

源代码或简单统计特征难以保留控制流、数据流和指令语义；编译优化模型需要能表达程序结构的统一表示。

## 2. 方法与系统结构

ProGraML 将程序表示为带节点和边类型的图，融合控制流、数据流和调用等关系，用图神经网络学习表示，并用于数据流分析和编译优化相关任务。

## 3. 实验与主要发现

论文展示图表示可以支持多种编译器分析/优化学习任务，并改善跨程序表示能力；重点在数据集、图构造和任务泛化。

## 4. 局限与批判性阅读

图表示仍可能丢失目标微架构、完整常量或后端实现信息；不是 LLM Agent 或真实性能闭环；跨架构适应不属于其核心实验。

## 5. 对当前研究方向的关系

可作为 IR Agent 的结构化状态编码器，与平台行为表示、MIR/ASM 特征拼接，避免仅依赖 AutoPhase 统计特征。

## 6. 可提炼的研究启发

程序表示是跨架构迁移的基础，但不能把更复杂的表示直接等同于更好的真实性能。

## 7. 一句话总结

程序表示是跨架构迁移的基础，但不能把更复杂的表示直接等同于更好的真实性能。
