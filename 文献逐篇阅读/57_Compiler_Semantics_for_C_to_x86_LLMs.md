# 57. Introducing compiler semantics into LLMs as PL translators

> 主题分类：编译器语义增强神经编译

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2024.findings-emnlp.55.pdf](https://aclanthology.org/2024.findings-emnlp.55.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\47-Introducing Compiler Semantics LLMs. EMNLP 2024`
- 本地 PDF 文件数：1；提取页数：16
- 阅读状态：完整 PDF 阅读

完整 PDF，16 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何处理 C 到 x86 翻译中的数值表示和长尾语义映射。

## 2. 方法与系统结构

对数值做符号转换、规范化 switch-case，并根据失败样本自动重采样和增强。

## 3. 实验与主要发现

13B 模型行为准确率超过 91%，高于 GPT-4 Turbo 的 40.85% 和仅微调基线的 59.87%。

## 4. 局限与批判性阅读

只覆盖 C→x86 非优化编译；LoRA、测试覆盖与数据分布会影响结果，跨 ISA 泛化有限。

## 5. 对当前研究方向的关系

证明显式编译语义可大幅改善模型，但 CABLE 更关注既有后端上的优化效应边界。

## 6. 可提炼的研究启发

把模型不擅长的精确语义运算交给符号预处理，是可靠系统的重要设计原则。

## 7. 一句话总结

把模型不擅长的精确语义运算交给符号预处理，是可靠系统的重要设计原则。
