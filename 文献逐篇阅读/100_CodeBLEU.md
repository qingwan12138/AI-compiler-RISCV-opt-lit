# 100. CodeBLEU: a method for automatic evaluation of code synthesis

> 主题分类：代码生成评价指标

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2009.10297.pdf](https://arxiv.org/pdf/2009.10297.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\06_多硬件编译_代价模型与IR基础设施\39-CodeBLEU Code Synthesis Eval. arXiv 2020`
- 本地 PDF 文件数：1；提取页数：8
- 阅读状态：完整 PDF 阅读

完整 PDF，8 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

BLEU 与 exact match 为何不能恰当评价语法不同但语义相近的代码。

## 2. 方法与系统结构

将 n-gram、加权 token、AST 语法和 data-flow 语义匹配组合成 CodeBLEU。

## 3. 实验与主要发现

在文本到代码、代码翻译、代码精炼三项任务上，与程序员评分相关性优于 BLEU 和 exact match。

## 4. 局限与批判性阅读

仍是静态代理指标，无法保证编译、功能等价或性能；权重和 parser 依赖语言。

## 5. 对当前研究方向的关系

CABLE 可用作辅助相似度，绝不能替代正确性与真实效应。

## 6. 可提炼的研究启发

代码评价应把文本相似、语法、语义和性能分层报告。

## 7. 一句话总结

代码评价应把文本相似、语法、语义和性能分层报告。
