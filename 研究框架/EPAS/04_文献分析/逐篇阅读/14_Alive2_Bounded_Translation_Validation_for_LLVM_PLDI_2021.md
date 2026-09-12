# 14. Alive2: Bounded Translation Validation for LLVM. PLDI 2021.

> 主题分类：LLVM 形式验证基础

## 阅读范围与证据边界

- 原始来源：[https://dl.acm.org/doi/10.1145/3453483.3454030](https://dl.acm.org/doi/10.1145/3453483.3454030)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\14-Alive2 Bounded Translation Validation for LLVM. PLDI 2021`
- 本地 PDF 文件数：1；提取页数：15
- 阅读状态：完整 PDF 阅读

完整 PDF，15 页；重点依据摘要、第 3-8 节和结论。

## 1. 研究问题与动机

LLVM 优化必须保持 refinement/equivalence，但 LLVM IR 有未定义行为、poison、浮点和内存语义，人工验证难以扩展。

## 2. 方法与系统结构

Alive2 是无需修改 LLVM 的 bounded translation validation 工具，用 SMT 编码 LLVM IR 语义，支持 UB、内存、循环有界展开、函数调用和 refinement；对编译器输入/输出进行逐次验证。

## 3. 实验与主要发现

在 LLVM 单元测试等场景中发现大量 refinement violations 和 LLVM bug，并推动 IR 语义文档修订；论文强调避免 false alarms，而不是追求无界证明。

## 4. 局限与批判性阅读

有界循环、未支持特性、SMT 超时和模型语义边界会产生 inconclusive 结果；它验证的是语义，不判断目标机器上的性能好坏。

## 5. 对当前研究方向的关系

Alive2 是 IR Agent 与后端 Agent 之间的安全闸门：不通过验证的候选不得进入真实性能奖励；它也能提供可用于训练的失败诊断。

## 6. 可提炼的研究启发

这篇论文解决正确性，不解决性能迁移；将两者结合比单独增加“验证模块”更有研究价值。

## 7. 一句话总结

这篇论文解决正确性，不解决性能迁移；将两者结合比单独增加“验证模块”更有研究价值。
