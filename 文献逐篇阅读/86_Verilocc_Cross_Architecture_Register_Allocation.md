# 86. Verilocc: Cross-architecture register allocation via LLM

> 主题分类：跨 GPU 寄存器分配

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2506.17506.pdf](https://arxiv.org/pdf/2506.17506.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\76-Verilocc Cross-Arch Register Alloc. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：11
- 阅读状态：完整 PDF 阅读

完整 PDF，11 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

能否把 LLM 与静态分析/验证器结合，跨 NVIDIA 与 AMD 学习可验证寄存器分配。

## 2. 方法与系统结构

将 MIR 归一化后微调模型生成目标寄存器映射，并用 verifier 引导重采样。

## 3. 实验与主要发现

GEMM/MHA 单次正确率 85–99%，pass@100 近 100%；个案运行时间超过 rocBLAS 10% 以上。

## 4. 局限与批判性阅读

集中于结构化 kernel；CPU/TPU 需额外适配，复杂 kernel 小模型下降，重采样增加延迟。

## 5. 对当前研究方向的关系

与 CABLE 高度相关，可作为跨架构后端任务基线，但尚未学习可解释的知识边界。

## 6. 可提炼的研究启发

静态归一化负责可迁移表示，验证器负责硬约束，真实性能负责最终选择。

## 7. 一句话总结

静态归一化负责可迁移表示，验证器负责硬约束，真实性能负责最终选择。
