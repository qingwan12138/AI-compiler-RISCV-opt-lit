# 73. DeepSeekMath: Pushing Limits of Mathematical Reasoning in LLMs

> 主题分类：GRPO 推理训练基础

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2402.03300.pdf](https://arxiv.org/pdf/2402.03300.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\63-DeepSeekMath Mathematical Reasoning. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：30
- 阅读状态：完整 PDF 阅读

完整 PDF，30 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何用高质量数学语料和低内存策略优化提升 7B 模型的数学推理。

## 2. 方法与系统结构

继续预训练 120B 数学 token，并提出无需独立 critic、按组内相对回报优化的 GRPO。

## 3. 实验与主要发现

MATH 单样本 51.7%，64 样本自一致性 60.9%；代码预训练对数学推理有正向作用。

## 4. 局限与批判性阅读

它不是编译研究，数学 benchmark 收益不能直接外推到代码语义或真实性能。

## 5. 对当前研究方向的关系

仅作为 Compiler-R1 等采用 GRPO 的算法背景；CABLE 是否使用 RL 需由实验必要性决定。

## 6. 可提炼的研究启发

通用 RL 算法应被视为实现工具，而不是编译优化领域创新。

## 7. 一句话总结

通用 RL 算法应被视为实现工具，而不是编译优化领域创新。
