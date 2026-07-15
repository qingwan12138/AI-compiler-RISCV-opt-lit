# 67. SLADE: A portable small language model decompiler

> 主题分类：小模型可移植反编译

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2305.12520.pdf](https://arxiv.org/pdf/2305.12520.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\57-SLADE Portable SLM Decompiler. arXiv 2024`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

能否用小型 Seq2Seq 与类型推断提高优化汇编的反编译正确性和可读性。

## 2. 方法与系统结构

在真实代码上训练无 dropout Transformer，使用专用 tokenizer 和外部类型推断，覆盖两 ISA 与两优化级别。

## 3. 实验与主要发现

在 4000 余个 ExeBench 函数上，准确率最高为 Ghidra 的 6×、ChatGPT 的 4×。

## 4. 局限与批判性阅读

仍是函数级受限任务，类型推断与测试 oracle 影响结果；不处理优化决策。

## 5. 对当前研究方向的关系

对 CABLE 主要是跨 ISA 表示/解释工具参考。

## 6. 可提炼的研究启发

小模型加确定性程序分析可胜过更大通用模型。

## 7. 一句话总结

小模型加确定性程序分析可胜过更大通用模型。
