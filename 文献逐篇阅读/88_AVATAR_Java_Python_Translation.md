# 88. AVATAR: A parallel corpus for Java-Python program translation

> 主题分类：程序翻译数据集

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2023.findings-acl.143.pdf](https://aclanthology.org/2023.findings-acl.143.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\78-AVATAR Java-Python Translation. ACL 2023`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何为 Java–Python 程序翻译提供平行语料和功能正确性评测。

## 2. 方法与系统结构

汇聚 9515 个题目及多份 Java/Python 解，其中 250 个带单元测试，并微调多个预训练模型。

## 3. 实验与主要发现

模型在词法指标上较好，但功能正确性明显不足，揭示文本指标的局限。

## 4. 局限与批判性阅读

仅两种高级语言，数据偏算法题，测试只覆盖少部分样本，缺少项目 API 情境。

## 5. 对当前研究方向的关系

为 CABLE 提供“文本相似不等于语义正确”的旁证，直接相关性较弱。

## 6. 可提炼的研究启发

代码迁移 benchmark 必须以执行/测试为主指标，而不是 BLEU。

## 7. 一句话总结

代码迁移 benchmark 必须以执行/测试为主指标，而不是 BLEU。
