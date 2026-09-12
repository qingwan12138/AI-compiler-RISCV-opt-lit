# 03. CompilerGym: Robust, Performant Compiler Optimization Environments for AI Research. CGO 2022.

> 主题分类：编译器 AI 基础设施

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2109.08267](https://arxiv.org/abs/2109.08267)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\03-CompilerGym Robust, Performant Compiler Optimization Environments for AI Research. CGO 2022`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点依据 API、数据集、验证和 lazy/batched 操作章节。

## 1. 研究问题与动机

编译器优化研究缺少统一、可复现、可扩展的 AI 环境，导致算法、奖励、数据集和正确性验证难以公平比较。

## 2. 方法与系统结构

提出 CompilerGym，采用类似 OpenAI Gym 的环境接口，定义 action/observation/reward space、step/reset；提供可扩展 benchmark 数据集、状态序列化与重放、差分测试和 sanitizer 验证，并支持 lazy/batched 操作和多种编译器环境。

## 3. 实验与主要发现

重点贡献是环境和 API，而非某个最优 RL 算法；示例包括 LLVM Autophase instruction-count 环境、数据集管理和与 RLlib 等工具的集成。

## 4. 局限与批判性阅读

环境提供的 reward 可以是确定的、非确定的或平台相关的，但环境本身不会自动解决奖励与真实性能的错位；其经典 LLVM 环境仍主要使用 IR 指令数或二进制大小等代理指标。

## 5. 对当前研究方向的关系

CrossTune-RL 应把 CompilerGym 式接口作为实验基座，新增平台条件、后端静态特征、真实硬件测量、正确性和评测预算等空间。

## 6. 可提炼的研究启发

如果没有可复现的环境和状态序列化，双智能体或跨架构结果很难可信；CompilerGym 是实验框架层面的关键基线。

## 7. 一句话总结

如果没有可复现的环境和状态序列化，双智能体或跨架构结果很难可信；CompilerGym 是实验框架层面的关键基线。
