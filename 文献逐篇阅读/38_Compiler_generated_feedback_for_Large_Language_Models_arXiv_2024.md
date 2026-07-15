# 38. Compiler generated feedback for Large Language Models. arXiv 2024.

> 主题分类：编译器反馈驱动 LLM

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2403.14714](https://arxiv.org/abs/2403.14714)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\38-Compiler generated feedback for Large Language Models. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：10
- 阅读状态：完整 PDF 阅读

完整 PDF，10 页；重点依据摘要、feedback workflow、采样实验和局限。

## 1. 研究问题与动机

LLM 生成的优化 Pass、指令数和 IR 可能不一致；需要把编译器实际结果反馈给模型进行迭代修正。

## 2. 方法与系统结构

模型从未优化 LLVM IR 生成优化 Pass、预测指令数和优化 IR；编译器检查 Pass 有效性、编译结果、指令数和 BLEU 一致性，再把反馈放回 prompt，进行单轮或迭代重试。

## 3. 实验与主要发现

单次 feedback 相对原始模型从约 2.87% 提升到约 3.4%（相对 -Oz 的报告口径）；但当采样次数达到 10 或更多时，简单 sampling 可能超过 feedback。

## 4. 局限与批判性阅读

反馈字段与最终真实性能之间仍有距离；采样成本高；BLEU 不是语义或性能保证；迭代 feedback 的边际收益不稳定。

## 5. 对当前研究方向的关系

它是 CrossTune-RL 的直接反馈基线，也提醒我们：增加反馈信息不一定带来更好的样本效率，必须设计能改变策略的后端诊断和预算机制。

## 6. 可提炼的研究启发

反馈必须与明确的决策和 reward 对齐，而不是把更多编译器日志堆进上下文。

## 7. 一句话总结

反馈必须与明确的决策和 reward 对齐，而不是把更多编译器日志堆进上下文。
