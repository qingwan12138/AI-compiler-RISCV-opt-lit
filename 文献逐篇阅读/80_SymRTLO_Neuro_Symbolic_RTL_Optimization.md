# 80. SymRTLo: Enhancing RTL optimization with LLMs and symbolic reasoning

> 主题分类：神经符号 RTL 优化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2504.10369.pdf](https://arxiv.org/pdf/2504.10369.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\70-SymRTLo RTL LLM Symbolic Reasoning. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：17
- 阅读状态：完整 PDF 阅读

完整 PDF，17 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何兼顾 LLM 重写能力、FSM 符号优化和 RTL 功能正确性。

## 2. 方法与系统结构

用检索规则与 AST 模板优化数据流，符号模块处理 FSM 控制流，最后结合形式等价和测试验证。

## 3. 实验与主要发现

在 RTL-Rewriter 上，相对强基线的功耗、性能、面积最高改善 43.9%、62.5%、51.1%。

## 4. 局限与批判性阅读

结果依赖综合工具、目标库和 benchmark；“最高”值不能代表三目标同时或跨工艺稳定收益。

## 5. 对当前研究方向的关系

其“规则 + 符号 + 双验证”结构对 CABLE 有启发，但对象是 RTL/PPA。

## 6. 可提炼的研究启发

优化目标冲突时必须保存分维度效应，而不是压成单一分数。

## 7. 一句话总结

优化目标冲突时必须保存分维度效应，而不是压成单一分数。
