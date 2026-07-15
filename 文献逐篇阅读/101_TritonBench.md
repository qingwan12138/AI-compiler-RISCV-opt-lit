# 101. TritonBench: Benchmarking LLM for Triton operators

> 主题分类：Triton 生成与性能 benchmark

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2025.findings-acl.1183.pdf](https://aclanthology.org/2025.findings-acl.1183.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\06_多硬件编译_代价模型与IR基础设施\40-TritonBench Triton Operators. ACL 2025`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何同时评价 LLM 生成 Triton operator 的正确性和 GPU 效率。

## 2. 方法与系统结构

构建 184 个 GitHub 实际算子与 166 个 PyTorch 对齐任务，测 CodeBLEU、调用/执行正确、加速与 GPU 效率。

## 3. 实验与主要发现

最佳执行准确率在两通道仅 23.91% 和 53.01%；正确候选最佳加速 1.56× 与 1.91×。

## 4. 局限与批判性阅读

初始硬件主要是 A100，后来补 H100；任务和参考实现会影响速度结论。

## 5. 对当前研究方向的关系

是 CABLE 多维真实评测设计的重要参考，可用于 GPU 支线而非 RISC-V 主线。

## 6. 可提炼的研究启发

只有同时通过执行并优于同平台参考，才应计为有效优化。

## 7. 一句话总结

只有同时通过执行并优于同平台参考，才应计为有效优化。
