# 19. STOKE: Stochastic Superoptimization. ASPLOS 2013.

> 主题分类：随机超优化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/1211.0557](https://arxiv.org/abs/1211.0557)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\19-STOKE Stochastic Superoptimization. ASPLOS 2013`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点依据摘要、成本函数、验证、评估和局限章节。

## 1. 研究问题与动机

传统编译器把指令选择、寄存器分配和目标优化拆开，可能错过只有联合考虑才出现的高质量低级代码。

## 2. 方法与系统结构

STOKE 把 loop-free x86 binary superoptimization 表述为随机搜索，用 MCMC 探索程序空间；成本函数同时编码测试正确性、性能和其他约束，并使用 test cases 验证候选。

## 3. 实验与主要发现

从 LLVM -O0 的 x86-64 二进制出发，STOKE 在若干 Hacker's Delight、SAXPY 和手写汇编案例上达到或超过 GCC -O3，部分代码可比专家汇编更好。

## 4. 局限与批判性阅读

方法不完备，依赖测试而非形式证明；面向 x86 loop-free binary，难以直接迁移到 LLVM IR/RVV；随机搜索开销和局部最优问题明显。

## 5. 对当前研究方向的关系

它是目标后端智能体的历史基线：真实性能可以直接监督低级搜索，但 CrossTune-RL 要解决跨层 IR 动作如何影响后端空间。

## 6. 可提炼的研究启发

STOKE 提醒我们，IR 层“更少”并不等于机器码更快；后端性能应回到最终指令级或硬件执行。

## 7. 一句话总结

STOKE 提醒我们，IR 层“更少”并不等于机器码更快；后端性能应回到最终指令级或硬件执行。
