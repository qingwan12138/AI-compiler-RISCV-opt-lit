# 25. RISC-V LLVM backend optimization incubator / RVCC discussion.

> 主题分类：RISC-V LLVM 后端生态/验证基础设施

## 阅读范围与证据边界

- 原始来源：[https://discourse.llvm.org/t/rfc-rvcc-an-llvm-incubator-for-high-performance-risc-v-compiler-optimizations/90376](https://discourse.llvm.org/t/rfc-rvcc-an-llvm-incubator-for-high-performance-risc-v-compiler-optimizations/90376)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\25-RISC-V LLVM backend optimization incubator RVCC discussion`
- 本地 PDF 文件数：0；提取页数：0
- 阅读状态：源材料受限；已补充官方项目/规范页面

源材料受限；本地仅有 source.txt，另根据官方 LLVM 讨论页补充阅读。

## 1. 研究问题与动机

RISC-V 优化补丁分散在厂商分支，跨层影响、正确性验证和性能回归测试增加了上游 LLVM review 成本。

## 2. 方法与系统结构

RVCC RFC 提议建立高性能 RISC-V 优化的孵化/验证流程，整合 SPEC、TSVC、CoreMark、QEMU、真实 SiFive/SpacemiT/XuanTie 等平台，并为优化补丁提供分层测试和上游化路径。讨论后，提议方转向下游 staging repository，而不是在 LLVM 内建立正式 incubator。

## 3. 实验与主要发现

官方讨论页显示该提议的工程价值主要是标准化硬件与 benchmark 验证；社区意见担心形成 LLVM fork 或降低上游质量标准。

## 4. 局限与批判性阅读

这是 RFC/社区讨论，不是同行评审论文；其方案和治理状态会变化；不能把其设想当作已部署系统。

## 5. 对当前研究方向的关系

它为你的实验框架提供现实需求：多硬件、QEMU/实机、功能正确性、性能回归、可复现统计。CrossTune-RL 可以把智能体作为其中的调优层。

## 6. 可提炼的研究启发

多架构研究的难点不只是模型，而是可复现的后端评估基础设施；这一条对实验落地非常重要。

## 7. 一句话总结

多架构研究的难点不只是模型，而是可复现的后端评估基础设施；这一条对实验落地非常重要。
