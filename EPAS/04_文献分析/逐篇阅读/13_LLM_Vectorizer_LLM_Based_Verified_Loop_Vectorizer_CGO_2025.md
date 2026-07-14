# 13. LLM-Vectorizer: LLM-Based Verified Loop Vectorizer. CGO 2025.

> 主题分类：LLM + 向量化 + 形式验证

## 阅读范围与证据边界

- 原始来源：[https://dl.acm.org/doi/10.1145/3696443.3708929](https://dl.acm.org/doi/10.1145/3696443.3708929)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\13-LLM-Vectorizer LLM-Based Verified Loop Vectorizer. CGO 2025`
- 本地 PDF 文件数：1；提取页数：13
- 阅读状态：完整 PDF 阅读

完整 PDF，13 页；重点依据摘要、FSM、验证和结果章节。

## 1. 研究问题与动机

编译器因别名、复杂控制流和保守 cost model 而漏掉向量化机会；手写 SIMD intrinsic 又复杂且容易出错。

## 2. 方法与系统结构

LLM-Vectorizer 使用有限状态机组织多个 agent，把标量 C 转成向量 intrinsic；先用 checksum 测试筛选，再用 Alive2 做 bounded equivalence checking，并通过 C-level unrolling、空间 case splitting 等技术扩展验证能力。

## 3. 实验与主要发现

在 TSVC 上报告 1.1x-9.4x 的运行时加速范围，38.2% 的向量化结果被 Alive2 验证为正确；多 agent FSM 用较少调用完成修复和重试。

## 4. 局限与批判性阅读

验证覆盖率受 Alive2 规模和表达能力限制；目标主要是 x86 SIMD intrinsic；动态测试和 bounded proof 都不能等同于任意输入上的绝对正确性。

## 5. 对当前研究方向的关系

它说明 LLM 可以负责高层变换候选，编译器和形式验证负责安全闭环；CrossTune-RL 可把这一原则扩展到 RVV、ARM SVE 和 x86 的后端实现反馈。

## 6. 可提炼的研究启发

对你的方向最有价值的是“候选生成—编译/验证—性能评估—修复”的 agent loop，而不是其具体 x86 intrinsic。

## 7. 一句话总结

对你的方向最有价值的是“候选生成—编译/验证—性能评估—修复”的 agent loop，而不是其具体 x86 intrinsic。
