# 04. Compiler-R1: Towards Agentic Compiler Auto-tuning with Reinforcement Learning. arXiv 2025.

> 主题分类：LLM + LLVM Pass 自动调优

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2506.15701](https://arxiv.org/abs/2506.15701)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\04-Compiler-R1 Towards Agentic Compiler Auto-tuning with Reinforcement Learning. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：16
- 阅读状态：完整 PDF 阅读

完整 PDF，16 页；重点依据第 1、3、4、5 节和结论。

## 1. 研究问题与动机

传统 Pass 搜索组合爆炸，已有 LLM 方法缺少高质量工具交互轨迹，难以根据编译环境反馈自我修正。

## 2. 方法与系统结构

Compiler-R1 先用 Pass 协同关系构造候选，再以 19,603 条交互式推理样本进行 SFT，教会模型遵循 thought–tool call–feedback 协议；之后用 PPO、GRPO 或 REINFORCE++ 与 instrcount、find_best_pass_sequence 工具交互强化。动作空间含 124 个 LLVM opt Pass，主要输入为 AutoPhase 特征和初始指令数。

## 3. 实验与主要发现

在七个 LLVM 数据集上报告 GRPO-7B 平均相对 opt -Oz 的 IR 指令数改善约 8.46%，并报告约 96.71% 的交互成功率；SFT+RL 优于只做 SFT 或只做 RL 的设置。

## 4. 局限与批判性阅读

主要奖励是 IR 指令数，未证明与真实目标 CPU/RISC-V 运行时间一致；工具内部的搜索算法可能承担了较多优化工作；论文的成功率与性能指标并非同一概念；硬件反馈、后端诊断和平台迁移未被建模。

## 5. 对当前研究方向的关系

它是 CrossTune-RL 最直接的 LLM 基线。你的差异不应只是把 -Oz 换成 RISC-V，而应引入后端状态、平台条件和跨层性能监督，并做工具贡献消融。

## 6. 可提炼的研究启发

论文最重要的启发是 SFT 负责交互协议、RL 负责策略改进；最明显的空白是 IR 代理奖励没有真正回传到目标后端。

## 7. 一句话总结

论文最重要的启发是 SFT 负责交互协议、RL 负责策略改进；最明显的空白是 IR 代理奖励没有真正回传到目标后端。
