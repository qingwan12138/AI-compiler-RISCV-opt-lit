# 12. LLM-VeriOpt: Verification-Guided Reinforcement Learning for LLM-Based Compiler Optimization. CGO 2026.

> 主题分类：验证引导的 LLM 编译优化

## 阅读范围与证据边界

- 原始来源：[https://2026.cgo.org/details/cgo-2026-papers/37/LLM-VeriOpt-Verification-Guided-Reinforcement-Learning-for-LLM-Based-Compiler-Optimi](https://2026.cgo.org/details/cgo-2026-papers/37/LLM-VeriOpt-Verification-Guided-Reinforcement-Learning-for-LLM-Based-Compiler-Optimi)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\12-LLM-VeriOpt Verification-Guided Reinforcement Learning for LLM-Based Compiler Optimization. CGO`
- 本地 PDF 文件数：1；提取页数：16
- 阅读状态：完整 PDF 阅读

完整 PDF，16 页；重点依据摘要、Alive2/GRPO 方法和实验结论。

## 1. 研究问题与动机

LLM 生成的 IR 可能不可编译或改变语义；仅用 I/O 测试无法提供编译变换的严格等价保证。

## 2. 方法与系统结构

LLM-VeriOpt 用 Alive2 对 LLVM IR 变换做语义等价检查，把验证结果、错误类型和诊断反馈加入 GRPO；采用诊断增强样本生成、正确性导向训练和延迟优化三个阶段，模型为 Qwen-3B。

## 3. 实验与主要发现

论文报告可验证输出约 90%，成功修改代码数量相对基础 Qwen-3B 提升约 5.4x；相对 O0 约 2.3x speedup，并在部分案例中超过手写 instcombine。

## 4. 局限与批判性阅读

Alive2 是 bounded validation，超时或不支持的语义不等于正确；验证主要发生在 LLVM IR 层；没有直接把真实目标平台运行性能作为训练信号。

## 5. 对当前研究方向的关系

它提供 CrossTune-RL 必须采用的正确性底座：任何 IR Agent 动作都应先通过语义门控，再进入后端性能评估。

## 6. 可提炼的研究启发

验证反馈可以解决“能不能安全做”，但还没有解决“在不同硬件上是否值得做”；这正是后端性能与多架构方向的切入口。

## 7. 一句话总结

验证反馈可以解决“能不能安全做”，但还没有解决“在不同硬件上是否值得做”；这正是后端性能与多架构方向的切入口。
