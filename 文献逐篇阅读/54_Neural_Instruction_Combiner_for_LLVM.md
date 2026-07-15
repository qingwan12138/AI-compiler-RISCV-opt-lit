# 54. Learning to Combine Instructions in LLVM Compiler

> 主题分类：神经 LLVM InstCombine

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2202.12379.pdf](https://arxiv.org/pdf/2202.12379.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\01_编译阶段排序与强化学习调优\46-Learning Combine Instructions LLVM. arXiv 2022`
- 本地 PDF 文件数：1；提取页数：11
- 阅读状态：完整 PDF 阅读

完整 PDF，11 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

能否以 Seq2Seq 降低手工维护大量 InstCombine 规则的成本。

## 2. 方法与系统结构

从基本块提取精简 IR，模型生成优化序列，再由 LLVM 模块重建 IR 并接入标准流水线。

## 3. 实验与主要发现

与传统 InstCombine 输出的 exact match 为 72%，BLEU 为 0.94，证明端到端集成可行。

## 4. 局限与批判性阅读

文本相似和 exact match 不能证明语义等价或更快；论文没有完整解决错误输出的验证与回退。

## 5. 对当前研究方向的关系

适合作为 CABLE 规则候选生成对照，知识必须附带证明、后端效应与适用边界。

## 6. 可提炼的研究启发

神经规则生成应置于可验证的编译器外壳内，而不是直接信任模型输出。

## 7. 一句话总结

神经规则生成应置于可验证的编译器外壳内，而不是直接信任模型输出。
