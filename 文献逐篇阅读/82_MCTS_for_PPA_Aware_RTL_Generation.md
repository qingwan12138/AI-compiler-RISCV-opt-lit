# 82. Make every move count: LLM-based RTL code generation using MCTS

> 主题分类：MCTS + PPA 感知 RTL

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2402.03289.pdf](https://arxiv.org/pdf/2402.03289.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\72-Make Every Move LLM RTL MCTS. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：7
- 阅读状态：完整 PDF 阅读

完整 PDF，7 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何让 token 解码同时考虑编译、功能和 PPA，而非只追求语言概率。

## 2. 方法与系统结构

把 Verilog 生成建模为 MDP，以 MCTS lookahead、综合反馈和模块复用引导解码。

## 3. 实验与主要发现

对 16 位加法器，相对 VeriGen beam search 的面积-延迟积改善 31.8%，并提高功能正确性。

## 4. 局限与批判性阅读

设计规模较小，MCTS 成本高，目标平台/工艺变化会改变 PPA 结论。

## 5. 对当前研究方向的关系

可作为 CABLE 搜索基线；CABLE 仍需通过知识边界减少盲目树搜索。

## 6. 可提炼的研究启发

把真实工具目标纳入搜索比仅按模型概率解码更符合系统优化。

## 7. 一句话总结

把真实工具目标纳入搜索比仅按模型概率解码更符合系统优化。
