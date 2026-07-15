# 61. Iterative refinement with compiler feedback for code generation

> 主题分类：项目上下文编译反馈

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2024.findings-acl.138.pdf](https://aclanthology.org/2024.findings-acl.138.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\51-Iterative Refinement Compiler Feedback. ACL 2024`
- 本地 PDF 文件数：1；提取页数：18
- 阅读状态：完整 PDF 阅读

完整 PDF，18 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何利用编译错误定位并补齐 LLM 缺失的仓库级上下文。

## 2. 方法与系统结构

静态分析生成代码与项目接口的失配，从仓库检索相关类、方法和结构，迭代修复。

## 3. 实验与主要发现

对依赖项目上下文的函数生成，相对原始 LLM 的 pass rate 提升超过 80%。

## 4. 局限与批判性阅读

编译通过不保证运行正确、安全或满足任务；研究限于 Python 项目级生成。

## 5. 对当前研究方向的关系

可借鉴为 CABLE 工具反馈接口，但最终必须增加执行、性能和硬件证据。

## 6. 可提炼的研究启发

编译器诊断最适合用来检索精确上下文，而不是只作为自然语言提示。

## 7. 一句话总结

编译器诊断最适合用来检索精确上下文，而不是只作为自然语言提示。
