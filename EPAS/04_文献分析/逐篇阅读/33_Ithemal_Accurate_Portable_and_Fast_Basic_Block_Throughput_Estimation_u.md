# 33. Ithemal: Accurate, Portable and Fast Basic Block Throughput Estimation using Deep Neural Networks. ICML 2019.

> 主题分类：机器码吞吐量预测

## 阅读范围与证据边界

- 原始来源：[https://proceedings.mlr.press/v97/mendis19a.html](https://proceedings.mlr.press/v97/mendis19a.html)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\33-Ithemal Accurate, Portable and Fast Basic Block Throughput Estimation using Deep Neural Network`
- 本地 PDF 文件数：1；提取页数：11
- 阅读状态：完整 PDF 阅读

完整 PDF，11 页；重点依据摘要、模型、实验和结论。

## 1. 研究问题与动机

编译器需要知道一个 basic block 在特定微架构上的 throughput，但真实硬件测量昂贵、手工性能模型难覆盖复杂指令组合。

## 2. 方法与系统结构

Ithemal 使用深度神经网络从基本块的指令序列预测 throughput，学习指令上下文、数据依赖和微架构响应，以较快方式替代部分分析工具。

## 3. 实验与主要发现

论文报告在多个 x86 微架构上具有较高准确度和较快预测速度，并讨论跨微架构可移植性；它把机器指令序列直接作为性能模型输入。

## 4. 局限与批判性阅读

主要覆盖 basic block throughput，不等于全程序 runtime；训练平台和目标微架构分布影响迁移；没有 IR Pass 选择或 LLM 协作。

## 5. 对当前研究方向的关系

Ithemal 可作为 Backend Agent 的静态性能预测器，让 IR Agent 在较少真实硬件查询下估计候选收益。

## 6. 可提炼的研究启发

后端智能体不一定每一步都要上实机，可用机器码级 predictor 做低成本筛选，再将高不确定候选交给真实平台。

## 7. 一句话总结

后端智能体不一定每一步都要上实机，可用机器码级 predictor 做低成本筛选，再将高不确定候选交给真实平台。
