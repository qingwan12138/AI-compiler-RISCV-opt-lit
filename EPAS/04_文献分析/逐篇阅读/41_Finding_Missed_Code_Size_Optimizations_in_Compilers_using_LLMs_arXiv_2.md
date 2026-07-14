# 41. Finding Missed Code Size Optimizations in Compilers using LLMs. arXiv 2025.

> 主题分类：LLM + 编译器差分测试

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2501.00655](https://arxiv.org/abs/2501.00655)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\41-Finding Missed Code Size Optimizations in Compilers using LLMs. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：16
- 阅读状态：完整 PDF 阅读

完整 PDF，16 页；重点依据摘要、四类差分策略、误报控制和实验。

## 1. 研究问题与动机

编译器测试需要大量随机程序和语言专家维护的生成器；同时，传统差分测试更关注错误而非 missed optimization。

## 2. 方法与系统结构

使用 LLM 迭代生成/变异 C/C++ 程序，再用四种差分策略发现代码尺寸异常：死代码插入、迭代增加复杂度、编译器之间比较等；用 coverage、sanitizer、CompCert 和版本筛选降低误报。

## 3. 实验与主要发现

论文报告少于 150 行代码即可搭建流程，能够迁移到 Rust/Swift，并确认 24 个生产编译器 bug；重点是找出编译器漏掉的代码尺寸优化。

## 4. 局限与批判性阅读

使用代码尺寸作为复杂度和异常 proxy 可能漏报；LLM 生成的代码仍需验证；user-defined harness、编译器版本和 bug 去重影响结果。

## 5. 对当前研究方向的关系

它提供 failure-driven compiler research 的思路：先找后端/编译器失效案例，再把失败原因变成 Agent 的训练信号。

## 6. 可提炼的研究启发

与 CrossTune-RL 相比，它发现“编译器漏优化”，而不是直接学习最优 Pass；二者可结合形成困难样本或错误诊断集。

## 7. 一句话总结

与 CrossTune-RL 相比，它发现“编译器漏优化”，而不是直接学习最优 Pass；二者可结合形成困难样本或错误诊断集。
