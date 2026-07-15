# 92. Unsupervised binary code translation for vuln discovery

> 主题分类：无监督跨 ISA 二进制分析

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2023.findings-emnlp.971.pdf](https://aclanthology.org/2023.findings-emnlp.971.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\03_形式验证_超级优化与规则生成\46-Unsupervised Binary Code Security. EMNLP 2023`
- 本地 PDF 文件数：1；提取页数：12
- 阅读状态：完整 PDF 阅读

完整 PDF，12 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何把低资源 ISA 二进制迁移到高资源 ISA，以复用既有安全分析模型。

## 2. 方法与系统结构

把反汇编指令视作语言 token，训练无监督 x86↔ARM 翻译，再用于相似度与漏洞发现。

## 3. 实验与主要发现

在实验漏洞集上可跨 ISA 检出全部目标脆弱函数，并在两项下游任务保持较高准确率。

## 4. 局限与批判性阅读

只覆盖 x86/ARM 和有限任务；指令 token 化、语义保持和对其他 ISA 的外推未解决。

## 5. 对当前研究方向的关系

对 CABLE 的跨 ISA 表示学习有启发，但 RISC-V 和真实性能必须单独验证。

## 6. 可提炼的研究启发

低资源架构可借高资源表示迁移，但迁移有效边界本身需要实证学习。

## 7. 一句话总结

低资源架构可借高资源表示迁移，但迁移有效边界本身需要实证学习。
