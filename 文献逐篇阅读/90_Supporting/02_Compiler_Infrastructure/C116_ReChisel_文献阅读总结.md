# ReChisel 文献阅读总结

论文题目：**ReChisel: Effective Automatic Chisel Code Generation by LLM with Reflection**

作者：Juxin Niu、Xiangfeng Liu、Dan Niu、Xi Wang、Zhe Jiang、Nan Guan

发表时间：2025

发表平台：2025 62nd ACM/IEEE Design Automation Conference（DAC 2025）

论文链接或编号：DOI `10.1109/DAC63849.2025.11132940`；arXiv `2505.19734`

关键词：大语言模型（LLM）、Chisel、硬件描述语言（HDL）、反射式代码生成、编译反馈、仿真反馈、硬件设计自动化

> 本文档依据作者公开的 arXiv 正文 PDF 阅读。论文事实、阅读后的分析和后续建议分开描述；没有把有限测试通过率表述为形式化证明。

## 1. 研究背景

本文属于 LLM 辅助硬件设计和 HDL 代码生成。传统 Verilog 等 HDL 代码编写耗时，LLM 已被用于自然语言到 Verilog、调试和 PPA（功耗、性能、面积）优化，但论文指出已有工作主要聚焦 Verilog。

Chisel 是嵌入 Scala 的较高层次 HDL，支持面向对象、函数式编程、模块复用和参数化设计。Chisel 代码不会直接成为硬件实现，而是经 Chisel 库构造硬件设计图，再序列化为 FIRRTL（Flexible Intermediate Representation for RTL），经 FIRRTL 编译器优化并转成 Verilog（第 II-B 节）。它已用于 XiangShan、BOOM、RocketChip 等处理器以及 Gemmini 等加速器。

论文的动机是：Chisel 的抽象层次更高，可能让 LLM 聚焦复杂设计的高层逻辑；但 Chisel 公开代码量显著少于 Verilog，论文基于 2025 年 3 月 GitHub 搜索估计公开 Verilog/SystemVerilog 代码约 160 万行、导入 Chisel 扩展的 Scala 代码约 8.01 万行。因此，LLM 是否能有效生成 Chisel，不能从 Verilog 结果直接推断。

## 2. 论文要解决的问题

论文具体研究以下问题：

1. 在仅给定模块规格的 zero-shot 条件下，主流 LLM 生成正确 Chisel 的能力是否明显弱于生成 Verilog。
2. 能否利用 Chisel 编译器报告的语法/静态检查反馈，以及 Verilog 仿真中的功能反馈，迭代修正 Chisel 代码。
3. LLM 在反射式修正中可能反复回到同一组错误。如何识别这种 non-progress loop，并让后续修正跳出错误循环。
4. 经反馈驱动的 Chisel 生成系统，其成功率能否达到与面向 Verilog 的 agentic 系统 AutoChip 相近的水平。

## 3. 核心方法概述

ReChisel 是一个 LLM-based agentic system。输入是模块 specification 和 testbench，输出是通过编译并通过功能测试的 Chisel 代码。整体数据流为：

```text
Specification + Testbench
        -> Generator 生成 Chisel
        -> Chisel Compiler 将其转为 Verilog
        -> Simulator 对 DUT 与参考模块执行功能测试
        -> Inspector 维护历史反馈 trace
        -> Reviewer 生成 revision plan
        -> Generator 按计划修改 Chisel
        -> 重复，直到成功或达到最大迭代次数
```

三个 LLM agent 分别承担 Generator、Inspector 和 Reviewer；Compiler 与 Simulator 是外部工具，不是 LLM agent（第 IV-A 节）。

编译错误反馈包含错误位置、错误解释以及编译器可能给出的修复提示。论文把一部分编译期间发现的未初始化信号、组合环等静态逻辑错误也归入后文的“syntax error”统计。作者为常见错误预先整理原因和修复指导，并将其放入 prompt 中，属于 in-context learning（上下文学习），不是重新训练模型。

功能错误反馈来自仿真：DUT 与参考模块同时接收输入 stimulus，将输出逐点比较；对失败点抽取输入、期望输出和实际输出，形成 error list。Reviewer 根据代码和反馈为每个错误给出位置、原因分析和具体解决方案。

逃逸机制由 Inspector 监测 trace。若当前反馈与历史反馈在同一位置出现相同原因的错误，则将中间迭代识别为 non-progress loop，丢弃该循环中的迭代，并让 Reviewer 从循环前一步重新生成 revision plan。论文给出的例子是 LLM 反复尝试在 Chisel `switch` 中添加并不存在的 default 语法，正确修复其实是使用 `WireDefault`。

## 4. 实验框架与训练流程

本文没有训练一个新的基础 LLM，也没有 SFT（监督微调）或多阶段模型训练流程。实验是推理时的 agent 流程：给定规格和 testbench，生成代码，调用编译器和仿真器，再把反馈放回 prompt 中迭代。

实验框架包含三类基准来源：VerilogEval 的 Spec-to-RTL、AutoChip 的 HDLBits、RTLLM。论文从这些来源过滤掉不能适配 Chisel 的案例，例如要求 Chisel 不支持的某些 Verilog 参数化特性、缺失/错误参考代码的案例，以及原本专门用于 Verilog 调试或补全而无法改造成 Chisel 生成任务的案例，最后得到 216 个有效 test cases（第 V-A 节）。

每个 case 测试 10 次以处理 LLM 输出的随机性，使用 Pass@k；LLM 保持默认配置，未手动调 temperature 或 top-p。反射最大迭代次数设置为 10。论文还给出一个 GPT-4o 的案例：前两次遇到语法错误，第三次生成语法正确但功能错误的代码，随后修正循环逻辑并通过全部测试（第 V-D 节）。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数；也没有报告 SFT 损失、策略梯度损失或训练目标。

核心评价指标是 Pass@k：在 k 次生成尝试中至少有一次正确结果的概率/成功率。论文没有在正文中给出新的 Pass@k 推导公式，而是报告 Pass@1、Pass@5 和 Pass@10。表格中的 `n` 表示反射流程允许的最大迭代次数：`n=0` 是不反射的 baseline，`n=1、5、10` 是允许对应次数反射的结果。

正确性判据是：Chisel 成功编译为 Verilog，且编译生成的 Verilog 在仿真中通过测试点。该判据是基于编译与有限 testbench 的经验验证，不等同于形式化等价证明。

## 6. 实验设置

| 项目 | 论文设置 |
| --- | --- |
| 有效测试规模 | 216 个 module-level test cases |
| 基准来源 | VerilogEval Spec-to-RTL、AutoChip HDLBits、RTLLM |
| 被测模型 | GPT-4 Turbo（2024-04-09）、GPT-4o（2024-08-06）、GPT-4o mini（2024-07-18）、Claude 3.5 Sonnet（2024-10-22）、Claude 3.5 Haiku（2024-10-22） |
| 生成对象 | Chisel；baseline 还比较 Verilog |
| 抽样 | 每个 case 测试 10 次 |
| 指标 | Pass@1、Pass@5、Pass@10 |
| 推理参数 | 默认配置；未手动调整 temperature、top-p |
| 反射上限 | 最大 10 次迭代 |
| 对比系统 | AutoChip，面向直接生成 Verilog 的 LLM agentic system |
| 反馈来源 | Chisel 编译器、Verilog 仿真器、参考模块和 testbench |

论文没有报告独立的训练/验证/测试数据划分，也没有报告实际硬件综合后的 PPA、芯片面积、时序或真实硬件运行时间。评测对象是模块级代码生成是否编译并通过仿真。

## 7. 实验结果与结论

### 7.1 Chisel baseline 与 Verilog baseline

表 I 比较 zero-shot 生成 Chisel（CHS）与 Verilog（VRL）的成功率。以 Pass@1 为例：GPT-4 Turbo 为 CHS 45.54%、VRL 67.61%；GPT-4o 为 45.07% 对 69.48%；GPT-4o mini 为 11.27% 对 59.15%；Claude 3.5 Sonnet 为 33.33% 对 77.93%；Claude 3.5 Haiku 为 26.29% 对 75.59%。在该实验中，Chisel baseline 明显低于 Verilog baseline。

图 1 将 Chisel 输出分为 syntax error、functional error 和 success。不同模型的错误组成不同，但论文据此指出编译阶段错误占据相当比例，说明 zero-shot LLM 在 Chisel 语法和类型约束上存在困难。

### 7.2 ReChisel 迭代效果

表 III 在 216 个有效测试上报告不同最大迭代次数。以 Pass@1 为例，`n=0 -> n=10` 的结果为：GPT-4 Turbo 45.54% -> 73.24%，GPT-4o 45.07% -> 77.46%，GPT-4o mini 11.27% -> 40.38%，Claude 3.5 Sonnet 33.33% -> 84.98%，Claude 3.5 Haiku 26.29% -> 84.51%。这些数值是对应模型在测试集上的成功率，不是单个样例的最好值。

在最终 `n=10` 条件下，Claude 3.5 Sonnet 的 Pass@1 为 84.98%、Pass@5 为 92.49%、Pass@10 为 93.43%，是表 III 中该模型的三个最终成功率。GPT-4o 的对应值为 77.46%、85.45%、88.73%。论文观察到除 GPT-4o mini 外，多数模型大约在 4 次迭代后趋于平台；约有 10% 的 case 即使迭代后仍无法正确生成。

图 7 以 GPT-4o、Pass@1 为例，显示反射降低了 syntax error 和 functional error 的总体比例，但从第 9 到第 10 次迭代 syntax error 比例出现回升，说明修复功能错误可能重新引入语法错误。

### 7.3 与 AutoChip 的比较

表 IV 使用相同 benchmark 和参数比较 ReChisel 与 AutoChip。AutoChip 直接生成 Verilog。以 GPT-4o 为例，ReChisel 的 Pass@5/Pass@10 为 85.45%/88.73%，AutoChip 为 84.51%/87.79%，ReChisel 略高；但对 GPT-4 Turbo 和 Claude 3.5 Sonnet，AutoChip 在部分或全部指标上更高。例如 Claude 3.5 Sonnet 的 Pass@10 为 ReChisel 93.43%、AutoChip 97.65%。因此论文结论是 ReChisel 使 Chisel 生成达到“接近”Verilog agentic 生成的水平，而不是在所有模型和指标上超过 AutoChip。

## 8. 主要创新点

以下是根据正文方法与实验归纳的创新点：

1. 将 LLM 反射式生成流程应用到 Chisel，而不是只评估传统 Verilog 生成。
2. 设计编译错误与仿真功能错误的分流反馈：编译反馈强调位置、原因和类型/语法修复；仿真反馈提供失败输入、期望输出和实际输出。
3. 用 Generator、Inspector、Reviewer 三个 LLM 角色组织历史 trace、修订计划和代码修改，使反馈不只是把一条错误消息原样回传。
4. 增加基于历史反馈相似性的 non-progress loop 检测与 escape mechanism，处理 LLM 在相同错误修复策略上循环的问题。
5. 通过三类 benchmark、五个主流模型和 Pass@k 对比，量化反射迭代对 Chisel 代码生成成功率的影响，并与 AutoChip 作跨 HDL 对照。

这些创新主要是推理时系统设计和评测协议创新，不是新的 LLM 训练算法，也不是新的形式化验证算法。

## 9. 局限性

### 论文正文明确或直接呈现的边界

1. 约 10% 的 case 在最大迭代次数后仍无法正确生成；模型能力存在明显上限。
2. 反射迭代可能修复一个功能错误却重新引入语法错误，错误类型并非单调减少。
3. GPT-4o mini 的迭代收益较慢，说明不同模型的反射能力差异较大。
4. benchmark 经过适配和过滤，216 个 case 并不覆盖所有 Verilog 特性；尤其不包含不能映射到 Chisel 的部分参数化或不适配任务。

### 阅读后的限制分析

1. 论文把编译期间的未初始化信号、组合环等静态逻辑问题统称为 syntax error，便于统计但会混合语法、类型、静态语义和结构性错误，跨论文比较时需要谨慎。
2. 仿真通过只能说明通过所给 testbench 的行为检查，不能证明对所有输入都正确，也不能替代形式化等价检查或综合后验证。
3. 论文没有报告独立数据划分、数据泄漏检查、每个 benchmark 的单独结果、token/API 成本、编译/仿真时间开销，也没有硬件综合后的 PPA 结果。
4. 逃逸机制依赖 LLM 判断“同一位置、同一原因”，正文没有给出独立的 loop-detection 消融或错误识别精度，因此难以单独量化该组件的贡献。
5. 论文使用的模型版本和外部工具版本固定在 2024/2025 时间点，结果不能直接外推到其他模型、Chisel/FIRRTL 版本或大型工业设计。

## 10. 阅读后的研究方向反思

ReChisel 的核心价值在于把编译器和仿真器从“最终验收工具”变成生成过程中的反馈接口。对 AI 编译器研究而言，这说明有效的反馈不一定要先训练新模型；结构化的错误位置、错误类型、输入/期望/实际输出和历史 trace，也可以直接改变推理搜索行为。

但其正确性闭环仍然偏弱：编译成功和有限仿真通过只覆盖局部行为。若迁移到 LLVM IR、MLIR 或 RISC-V 代码生成，反馈接口需要增加 IR 验证、目标 ISA 约束、汇编器/链接器错误、性能计数器和跨编译器差分结果，并明确区分语法正确、语义等价、目标相关合法和真实性能改善。

## 11. 可进一步尝试的研究方向

以下是阅读后的建议，不是论文已经实现的内容：

1. 将反馈 trace 结构化为错误类别、程序位置、前置条件、尝试过的修复和验证结果，避免把整个历史上下文无界地放进 prompt。
2. 为 LLVM/MLIR pass 或 RISC-V 后端加入多层验证：解析/构建成功、IR verifier、Alive2 或等价性检查、目标汇编合法性、差分测试，最后再测真实硬件或可信模拟器上的性能。
3. 对 escape mechanism 做独立消融：比较无检测、仅按文本相似度检测、按位置与原因联合检测，并报告循环检测准确率、平均迭代次数和 API/编译成本。
4. 将 Pass@k 与成本、延迟、编译时间、仿真时间、失败类型转移矩阵同时报告，避免只优化成功率而忽略反馈闭环开销。
5. 对 Chisel/FIRRTL、LLVM IR、MLIR 和 RISC-V 汇编分别设计 benchmark，测试高层抽象迁移到低层代码生成时反馈是否仍然有效。

## 12. 与其他已读文献的关系

本 slot 仅完整通读并交付 ReChisel 一篇 DAC 2025 论文，因此不能虚构与同批次其他论文的事实级横向比较。就研究位置而言，ReChisel 更接近“LLM 直接生成硬件描述代码 + 编译/仿真反馈修正”的 TRANSLATOR 类工作；它不是 LLVM pass 选择器、LLVM/MLIR pass 生成器，也不是 RISC-V 专用后端优化器。

它与 AI 编译器主线的可连接点是反馈闭环：生成器提出代码，外部编译器/验证器返回证据，审查器规划下一次修改。不能据此直接声称 Chisel 的仿真反馈已经解决 LLVM 优化的语义等价或 RISC-V 跨架构性能迁移问题。

## 13. 一页式总结

| 项目 | 总结 |
| --- | --- |
| 论文做了什么 | 提出 ReChisel，用三个 LLM 角色和编译/仿真反馈迭代生成 Chisel |
| 解决的主要问题 | zero-shot Chisel 生成成功率低、类型/语法错误多、反射过程可能陷入错误循环 |
| 核心机制 | Compiler/Simulator 反馈、Inspector trace、Reviewer revision plan、escape mechanism |
| 数据与模型 | 3 个 benchmark 过滤得到 216 个 case；5 个 LLM；每个 case 10 次采样 |
| 主要结果 | Claude 3.5 Sonnet 在 `n=10` 时 Pass@1/5/10 为 84.98%/92.49%/93.43%；GPT-4o 的 ReChisel 在 Pass@5/10 略高于 AutoChip |
| 是否训练模型 | 否；论文没有 SFT、强化学习或奖励函数 |
| 是否形式化验证 | 否；使用编译检查和有限 testbench 仿真，不等同于形式化证明 |
| 主要创新 | Chisel 代码生成反馈闭环与非进展循环逃逸机制 |
| 主要局限 | benchmark 适配范围有限；仿真覆盖有限；没有综合 PPA、成本和独立 loop 检测消融 |
| 与 RISC-V 相关性 | 中等偏低：Chisel 已用于 RISC-V 处理器，但本文评测的是通用模块生成，不是 RISC-V ISA 或后端优化 |
| 最适合作为 | 反馈驱动代码生成、编译器/仿真器工具调用、错误分类与迭代修正的系统参考 |

这篇论文最值得学习的是把编译器和仿真器输出组织成可供 LLM 继续推理的结构化证据；最主要的局限是有限 testbench 不能替代语义证明或真实硬件性能验证。如果用于后续研究，合理做法是复用“生成—验证—反馈—修正”的接口思想，并补上 IR/ISA 级合法性、等价性和硬件性能证据，而不是直接把 Chisel 的 Pass@k 结果当成 LLVM 或 RISC-V 优化效果。
