# 49. Towards LLM-based optimization compilers: peephole optimization

> 主题分类：LLM + AArch64 窥孔优化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2412.12163.pdf](https://arxiv.org/pdf/2412.12163.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\01_编译阶段排序与强化学习调优\41-Towards LLM Peephole Optimization. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：13
- 阅读状态：完整 PDF 阅读

完整 PDF，13 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

推理机制能否减少 LLM 学习单一 peephole 变换时的语法与语义错误。

## 2. 方法与系统结构

用 10 万个 AArch64 基本块微调 Llama2-7B，并在 2.4 万个基本块上与 GPT-4o、o1-preview 比较。

## 3. 实验与主要发现

未微调的 o1-preview 明显优于微调 Llama2 和 GPT-4o，作者将优势主要归因于链式推理。

## 4. 局限与批判性阅读

只研究一种简单变换；闭源模型、提示和输出验证使可复现性及因果归因有限。

## 5. 对当前研究方向的关系

提示 CABLE 的规则解释可用推理辅助，但规则适用边界必须由真实效应而非推理文本确定。

## 6. 可提炼的研究启发

小而可验证的优化规则更适合分析模型错误，并应配合符号或编译器校验。

## 7. 一句话总结

小而可验证的优化规则更适合分析模型错误，并应配合符号或编译器校验。
