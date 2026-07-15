# 26. IntrinTrans: LLM-based Intrinsic Code Translator for RISC-V Vector. arXiv 2025.

> 主题分类：LLM + RVV intrinsic 跨架构迁移

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2510.10119](https://arxiv.org/abs/2510.10119)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\26-IntrinTrans LLM-based Intrinsic Code Translator for RISC-V Vector. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：6
- 阅读状态：完整 PDF 阅读

完整 PDF，6 页；重点依据摘要、设计、实验表格和结论。

## 1. 研究问题与动机

Arm NEON/x86 intrinsic 代码难以直接迁移到 RVV；固定宽度 SIMD 与 RVV 的 sizeless、vector-length-agnostic 语义不一一对应。

## 2. 方法与系统结构

IntrinTrans 采用 Translator、Compilation Executor、Test Executor、Optimizer 四类 agent，由 FSM 组织；先 compile-and-test 修复正确性，再用 liveness analysis/register usage 反馈优化寄存器使用。

## 3. 实验与主要发现

在 VecIntrinBench 上用 9 个 LLM 评估，报告 pass rate 约 47%-100%，生成 RVV 实现性能约为 native implementation 的 0.85x-1.28x，部分可超过专家实现。

## 4. 局限与批判性阅读

任务是 50 个左右函数级 intrinsic 翻译，正确性主要依赖有限测试；性能受 LLM、编译器和目标 RVV 平台影响；没有形式验证和更广泛的多 ISA 迁移。

## 5. 对当前研究方向的关系

它是“编译器/测试反馈驱动的跨架构 agent”直接基线，可用于比较 Backend Agent 是否能从 IR/后端诊断中学习，而不只是生成代码。

## 6. 可提炼的研究启发

compile/test feedback + liveness feedback 是可复用的工具接口，但“多 agent + FSM”本身不应直接作为你的独立创新。

## 7. 一句话总结

compile/test feedback + liveness feedback 是可复用的工具接口，但“多 agent + FSM”本身不应直接作为你的独立创新。
