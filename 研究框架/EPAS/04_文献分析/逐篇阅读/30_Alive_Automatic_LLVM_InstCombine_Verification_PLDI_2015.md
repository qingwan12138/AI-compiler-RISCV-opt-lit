# 30. Alive: Automatic LLVM InstCombine Verification. PLDI 2015.

> 主题分类：LLVM InstCombine 形式验证

## 阅读范围与证据边界

- 原始来源：[https://dl.acm.org/doi/10.1145/2737924.2737965](https://dl.acm.org/doi/10.1145/2737924.2737965)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\30-Alive Automatic LLVM InstCombine Verification. PLDI 2015`
- 本地 PDF 文件数：1；提取页数：11
- 阅读状态：完整 PDF 阅读

完整 PDF，11 页；重点依据摘要、Alive DSL、验证和评价章节。

## 1. 研究问题与动机

LLVM peephole/InstCombine 优化容易因 UB、类型边界和内存语义产生错误；需要让开发者以较低成本编写并验证重写规则。

## 2. 方法与系统结构

Alive 是优化 DSL：开发者描述 LLVM IR peephole rewrite，工具使用 SMT 自动证明正确或生成 counterexample，并可自动生成接近手写 InstCombine 的 C++。

## 3. 实验与主要发现

论文翻译了 300 多个 LLVM 优化，发现其中 8 个错误；说明形式化规范既能验证现有规则，也能作为实现生成的中间层。

## 4. 局限与批判性阅读

早期 Alive 的语义和能力不如 Alive2 完整；重点是局部 peephole，不解决 Pass 排序、后端调度或多平台迁移。

## 5. 对当前研究方向的关系

可为“LLM 提出优化规则—Alive/Alive2 验证—后端评估”的安全流水线提供模板。

## 6. 可提炼的研究启发

这是把优化知识结构化、可验证化的重要前置工作，支持你把知识迁移对象从自然语言/Pass 改成 verified rewrite。

## 7. 一句话总结

这是把优化知识结构化、可验证化的重要前置工作，支持你把知识迁移对象从自然语言/Pass 改成 verified rewrite。
