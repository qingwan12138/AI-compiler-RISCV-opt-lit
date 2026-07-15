# 17. Souper: A Synthesizing Superoptimizer. arXiv 2017.

> 主题分类：SMT 合成超优化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/abs/1711.04422](https://arxiv.org/abs/1711.04422)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\17-Souper A Synthesizing Superoptimizer. arXiv 2017`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点依据摘要、第 1、3-4 节和结论。

## 1. 研究问题与动机

手写中端优化规则工程量大且容易遗漏；需要自动发现可证明、更短或更便宜的 LLVM IR 重写。

## 2. 方法与系统结构

Souper 使用接近纯函数 SSA 的领域 IR，从 LLVM bitcode 提取表达式，借助 SMT/程序合成发现更短的等价表达式；可离线给开发者建议，也可作为 LLVM pass 在线应用，并使用缓存降低重复成本。

## 3. 实验与主要发现

论文报告在构建 LLVM/Clang 时发现数千个优化机会；Souper 生成的 Clang 二进制约小 4.4%，但某些设置下性能略慢；初次编译开销约为普通优化的数倍，缓存后明显降低。

## 4. 局限与批判性阅读

重点是局部表达式和正确性，不是全程序 Pass 顺序或硬件平台迁移；SMT 搜索与缓存成本较高；“更小”不必然“更快”。

## 5. 对当前研究方向的关系

它是 CrossTune-RL 后端/IR 变换的可验证动作生成器候选：LLM 可以提出 intent 或候选，Souper/SMT 负责筛选可证明重写。

## 6. 可提炼的研究启发

Souper 暗示“可迁移的知识”可以保存为已验证 rewrite，而不是自然语言 Pass 序列。

## 7. 一句话总结

Souper 暗示“可迁移的知识”可以保存为已验证 rewrite，而不是自然语言 Pass 序列。
