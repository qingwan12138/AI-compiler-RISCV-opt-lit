# 103. OMPar: Automatic Parallelization with AI-Driven Compilation

> 主题分类：LLM 源到源自动并行化

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2409.14771.pdf](https://arxiv.org/pdf/2409.14771.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\06_多硬件编译_代价模型与IR基础设施\42-OMPar AI Source-to-Source Parallel. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：13
- 阅读状态：完整 PDF 阅读

完整 PDF，13 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何自动判断 C/C++ 循环可并行性并生成正确 OpenMP pragma。

## 2. 方法与系统结构

OMPify 分类可并行循环，MonoCoder-OMP 生成 pragma，再编译、运行、扩线程和校验输出。

## 3. 实验与主要发现

ParEval 在编译运行复核后达到 87% 精确率、100% 召回；整体优于 AutoPar 与 ICPC，并获得多核加速。

## 4. 局限与批判性阅读

集中于 CPU OpenMP；数据竞争、输入覆盖和线程扩展限制结论，GPU 尚属未来工作。

## 5. 对当前研究方向的关系

与 CABLE 失配驱动修正相关，可把并行化视作带硬件边界的知识。

## 6. 可提炼的研究启发

并行化决定应同时记录合法性、线程扩展曲线和平台特定反例。

## 7. 一句话总结

并行化决定应同时记录合法性、线程扩展曲线和平台特定反例。
