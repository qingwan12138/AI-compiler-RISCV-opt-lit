# 20. Minotaur: A SIMD-Oriented Synthesizing Superoptimizer. 2024.

> 主题分类：SIMD 合成超优化

## 阅读范围与证据边界

- 原始来源：[https://dl.acm.org/doi/10.1145/3689766](https://dl.acm.org/doi/10.1145/3689766)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\20-Minotaur A SIMD-Oriented Synthesizing Superoptimizer. 2024`
- 本地 PDF 文件数：1；提取页数：25
- 阅读状态：完整 PDF 阅读

完整 PDF，25 页；重点依据工作流、第 3-5 节和结论。

## 1. 研究问题与动机

LLVM 自动向量化后仍会留下冗余 shuffle、比较和标量/向量表达式，需要在 SIMD IR 片段内发现编译器漏掉的重写。

## 2. 方法与系统结构

Minotaur 从 LLVM IR 中提取局部 cuts，枚举候选重写，使用 Alive2 做翻译验证、字面量合成和成本检查，并将已验证收益缓存后接入 LLVM pipeline；重点覆盖 LLVM portable vector ops 和 x86 SIMD intrinsic。

## 3. 实验与主要发现

在 Intel Cascade Lake 上，GMP benchmark 平均 speedup 约 7.3%、最高 13%；SPEC CPU 2017 平均约 1.5%、最高 4.5%；所有生成优化都声称经过形式验证，并有部分进入 LLVM。

## 4. 局限与批判性阅读

作用范围是单次循环迭代内的局部片段，依赖上游向量化/展开先创造机会；目标以 x86 为主，不研究 LLM 或跨 ISA；合成和验证成本仍需控制。

## 5. 对当前研究方向的关系

它为“后端性能智能体”提供了可验证的 SIMD 变换样例，也说明平台特定收益必须在目标微架构上测量。

## 6. 可提炼的研究启发

可迁移知识不仅是 Pass 序列，也包括经验证、经成本检查的低级 rewrite。

## 7. 一句话总结

可迁移知识不仅是 Pass 序列，也包括经验证、经成本检查的低级 rewrite。
