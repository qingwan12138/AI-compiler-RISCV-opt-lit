# 10. Compiler Optimization via LLM Reasoning for Efficient Model Serving. arXiv 2025.

> 主题分类：LLM 推理 + MCTS 编译调优

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/2506.01374](https://arxiv.org/abs/2506.01374)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\10-Compiler Optimization via LLM Reasoning for Efficient Model Serving. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：27
- 阅读状态：完整 PDF 阅读

完整 PDF，27 页；重点依据摘要、第 2-4 节、消融和结论。

## 1. 研究问题与动机

神经网络模型服务的 tiling、fusion、layout 等变换相互依赖，随机搜索样本效率低且容易探索无效区域。

## 2. 方法与系统结构

REASONINGCOMPILER 不重新训练 LLM，而让 LLM 根据当前程序状态和历史性能反馈提出硬件相关变换；外层用结构化 Monte Carlo Tree Search 平衡探索和利用，搜索模型服务编译优化空间。

## 3. 实验与主要发现

论文报告在 AMD EPYC 等模型服务设置中，相比 MCTS 和神经编译基线取得更快运行时间和更少评测样本；历史轨迹深度和 LLM 选择会影响 sample efficiency。

## 4. 局限与批判性阅读

目标主要是神经模型/张量程序，不是通用 LLVM IR；“更快”与“更少样本”需要结合完整表格及硬件设置解释；无跨 ISA RISC-V 适应实验。

## 5. 对当前研究方向的关系

它是后端智能体如何利用历史轨迹和硬件上下文的强基线；CrossTune-RL 可以研究 LLM 在高层 IR 决策与目标后端搜索之间如何分工。

## 6. 可提炼的研究启发

可借鉴 LLM proposal + MCTS 的组合，但不能把 MCTS 加 LLM 本身作为多架构创新。

## 7. 一句话总结

可借鉴 LLM proposal + MCTS 的组合，但不能把 MCTS 加 LLM 本身作为多架构创新。
