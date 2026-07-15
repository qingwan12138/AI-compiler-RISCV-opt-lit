# 93. TFix: Learning to fix coding errors with text-to-text transformer

> 主题分类：Transformer 自动修复

## 阅读范围与证据边界

- 原始来源：[https://proceedings.mlr.press/v139/berabi21a/berabi21a.pdf](https://proceedings.mlr.press/v139/berabi21a/berabi21a.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\03_形式验证_超级优化与规则生成\47-TFix Text-Text Bug Fix. PMLR 2021`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

能否用统一文本到文本模型覆盖多类静态分析错误并保持准确率。

## 2. 方法与系统结构

从 GitHub 提取错误/修复对，微调 T5，同时学习 ESLint 的 52 类错误。

## 3. 实验与主要发现

约一半输出与人工修复完全一致，约 67% 能移除原错误，明显优于既有学习方法。

## 4. 局限与批判性阅读

移除静态错误不保证功能保持；研究集中于 JavaScript 与已知规则类型。

## 5. 对当前研究方向的关系

可作为 CABLE 失败修复的通用背景，但与性能知识边界间接相关。

## 6. 可提炼的研究启发

多错误联合训练能共享修复模式，但仍需回归测试和语义验证。

## 7. 一句话总结

多错误联合训练能共享修复模式，但仍需回归测试和语义验证。
