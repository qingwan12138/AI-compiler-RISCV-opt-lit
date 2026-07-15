# 85. Insights from verification: Training Verilog LLM with RL

> 主题分类：验证反馈 Verilog RL

## 阅读范围与证据边界

- 原始来源：[https://arxiv.org/pdf/2504.15804.pdf](https://arxiv.org/pdf/2504.15804.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\75-Insights Verification Verilog RL. arXiv 2025`
- 本地 PDF 文件数：1；提取页数：10
- 阅读状态：完整 PDF 阅读

完整 PDF，10 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何把 testbench 结果转成偏好数据，使 Verilog 模型直接对齐功能正确性。

## 2. 方法与系统结构

自动生成并用 VCS 迭代修正 testbench，再按测试结果构造偏好对，以 DPO 训练生成模型。

## 3. 实验与主要发现

在多个 VerilogEval 与 RTLLM benchmark 上持续超过已有开源基线。

## 4. 局限与批判性阅读

自动测试可能保留共同盲点；偏好学习只对齐可观测测试，未覆盖 PPA 与形式完备性。

## 5. 对当前研究方向的关系

说明验证结果可进入训练，但 CABLE 的奖励还必须包含真实后端效应。

## 6. 可提炼的研究启发

先提高验证数据质量，再做偏好训练，比直接从编译成功构造奖励更可靠。

## 7. 一句话总结

先提高验证数据质量，再做偏好训练，比直接从编译成功构造奖励更可靠。
