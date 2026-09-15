# HaVen 文献阅读总结

论文题目：**HaVen: Hallucination-Mitigated LLM for Verilog Code Generation Aligned with HDL Engineers**

作者：Yiyao Yang、Fu Teng、Pengju Liu、Mengnan Qi、Chenyang Lv、Ji Li、Xuhong Zhang、Zhezhi He

发表时间：2025

发表平台：2025 Design, Automation & Test in Europe Conference (DATE 2025)，论文正文为 arXiv:2501.04908 v1（2025-01-09）

论文链接或编号：DOI `10.23919/DATE64628.2025.10993072`；arXiv `2501.04908`

关键词：Verilog 代码生成、LLM、硬件描述语言、幻觉、链式思维、数据增强、RTL

> 本笔记依据公开 PDF 全文（7 页）整理。论文事实、阅读分析和后续建议分开表述；未在正文明确给出的内容写明“论文中未明确说明”。

---

## 1. 研究背景

本文属于大语言模型辅助硬件设计与 Verilog/RTL 代码生成。软件代码生成受益于大量代码和文档数据，而 Verilog 还涉及时序、并发、复位、边沿触发和硬件设计约定，普通 LLM 容易生成语法、功能或逻辑错误。论文将问题归纳为三类幻觉：符号幻觉（无法正确理解状态图、波形图、真值表等符号输入）、知识幻觉（不熟悉数字设计约定或 Verilog 特性）和逻辑幻觉（不能忠实实现条件、逻辑表达式或边界情况）。

论文指出，已有工作常用公开 Verilog 代码配合通用自然语言描述，或由通用闭源模型补写指令；这些描述可能过于简单、偏离 HDL 工程师的实际提问方式。因而，单纯扩大代码量并不能保证模型学习到工程化的规格表达和硬件逻辑。

## 2. 论文要解决的问题

### 2.1 符号输入理解

如何把状态图、波形图和真值表转换为 CodeGen-LLM 更容易可靠处理的结构化自然语言，减少符号幻觉。

### 2.2 HDL 工程知识对齐

如何构造包含 FSM、分频器、计数器、移位寄存器、ALU、同步/异步复位和高/低有效使能等内容的指令-代码对，使模型遵循 HDL 工程实践。

### 2.3 逻辑正确性与模型性能

如何通过逻辑增强样本和推理阶段的符号解释，提高 Verilog 生成的语法正确性与功能正确性。

> 本文主要研究：如何通过符号解释式 CoT、HDL 知识增强数据和逻辑增强数据，降低 LLM 生成 Verilog 时的三类幻觉。

## 3. 核心方法概述

HaVen 将推理提示处理与模型微调结合。用户的 Verilog 需求先由符号解释式链式思维（SI-CoT，Symbolic Interpretation based Chain-of-Thought）处理；若包含状态图、波形图或真值表，系统分别解析或转写为结构化指令，再交给 CodeGen-LLM 生成 Verilog。模型训练使用知识增强数据集 K-dataset 与逻辑增强数据集 L-dataset 的合并集 KL-dataset。

```text
用户 Verilog 需求
        ↓
SI-CoT 判断是否包含符号输入
        ↓
解析真值表/波形，或转写状态图；补全模块头
        ↓
CodeGen-LLM 生成 Verilog
        ↓
Verilog 编译器过滤错误样本（数据构建阶段）
        ↓
得到可评测的 RTL 代码
```

LLM 在系统中直接输出 Verilog，因此按 Taxonomy v2 建议归为 `TRANSLATOR`；本文不是让模型选择既有 compiler pass，也不是生成可复用的编译器后端组件。推理阶段使用同一预训练模型承担 SI-CoT 和代码生成，正文未报告自动迭代修复或运行时性能搜索。

## 4. 实验框架与训练流程

### 4.1 SI-CoT 推理流程

第一步识别输入是否含符号表示；第二步对真值表和波形图用外部 parser 转成统一格式，对状态图由 CoT 模型列出状态、输出和转移规则；第三步检查模块头是否完整，不完整时补充模块名、输入和输出。该流程用于生成更清晰的 CodeGen prompt。

### 4.2 知识增强数据构建

作者先从教材习题和人工设计例子整理 HDL 高质量 exemplars，再从公开 GitHub 约 550,000 个 Verilog 样本出发，由 GPT-3.5 生成 vanilla 指令。parser slang 用于识别主题和属性，并与 exemplars 匹配；GPT-3.5 重写指令使其符合 HDL 工程语境；最后用工业级 Verilog 编译器验证并过滤错误指令-代码对。

### 4.3 逻辑增强数据构建

作者脚本生成逻辑表达式及输入输出映射，把它们嵌入代码模板和指令模板，再用 instruction evolution 产生语言变体。正文说明改写限制为增删不超过 10 个词，以保持逻辑结构。

### 4.4 微调与推理

约 43k 个有效 vanilla 对、14k 个 HDL 对和 5k 个逻辑对组成 KL-dataset，用于微调 CodeGen-LLM。实验中 CodeLlama-7B-Instruct、DeepSeek-Coder-6.7B-Instruct 和 CodeQwen1.5-7B-Chat 分别作为基座；每个模型同时用于 SI-CoT、微调和生成。微调 3 个 epoch，使用两张 NVIDIA A100-80GB；论文没有采用 PPO、GRPO 或 RLHF。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数。训练损失的具体公式未在正文中展开；实验只说明使用 AdamW、余弦学习率调度器、15 次 warm-up 和初始学习率 `5e-5`。

论文明确给出的评价公式是 pass@k：

```text
pass@k = E[1 - C(n-c, k) / C(n, k)]
```

其中 `n` 是每个问题的总采样次数，`c` 是通过功能检查的样本数，实验设 `n=10`，`k` 取 1 或 5。它衡量每个任务的 k 次尝试中至少有一次通过的估计比例，不等同于单次生成准确率。

## 6. 实验设置

### 6.1 数据集来源

训练数据包含约 550,000 个来自公开 GitHub 的 Verilog 样本，经过生成、主题匹配、重写和编译过滤后形成约 43k 有效 vanilla 对、14k K-dataset 对和 5k L-dataset 对。论文未给出 GitHub 仓库的完整清单，也未定量分析训练集与评测集的重复率，因此数据泄漏风险未被充分确认。

评测集为 VerilogEval v1、RTLLM v1.1 和 VerilogEval v2。VerilogEval-machine 有 143 个 GPT 生成任务，VerilogEval-human 有 156 个人工任务；RTLLM v1.1 有 29 个 RTL 设计任务；VerilogEval v2 扩展了人工规格到 RTL 任务。符号专项测试从 VerilogEval-human 取 44 个任务：10 个真值表、13 个波形图、21 个状态图。

### 6.2 模型与工具

模型：CodeLlama-7B-Instruct、DeepSeek-Coder-6.7B-Instruct、CodeQwen1.5-7B-Chat；训练硬件：两张 NVIDIA A100-80GB；优化器：AdamW；推理温度尝试 0.2、0.5、0.8 并报告最佳结果。工具包括 GPT-3.5、slang parser 和工业级 Verilog 编译器。具体编译器名称、版本和硬件仿真器在正文中未明确说明。

### 6.3 对比方法

主要比较 GPT-3.5、GPT-4、StarCoder、CodeLlama、DeepSeek-Coder、CodeQwen、ChipNeMo、Thakur 等通用或 Verilog 生成模型，以及 RTLCoder、OriGen、BetterV 和 AutoVCoder。符号专项还比较 DeepSeek-Coder-V2。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Syntax pass@k | 生成 Verilog 通过语法检查的比例 | 越大越好 |
| Functional pass@k | 生成 RTL 通过功能检查的比例 | 越大越好 |
| pass@1 / pass@5 | 1 次/5 次采样中至少一次通过的任务比例 | 越大越好 |

## 7. 实验结果与结论

### 7.1 主要结果

表 IV 中 HaVen-DeepSeek 在 VerilogEval-machine 的功能 pass@1/pass@5 为 78.8%/84.5%，在 VerilogEval-human 为 57.3%/64.2%。正文明确叙述的比较结果是：HaVen-DeepSeek 相比 OriGen 在 VerilogEval-machine 的 pass@1/pass@5 高 4.7/2.1 个百分点；HaVen-CodeQwen 相比 OriGen 在 VerilogEval-human 高 6.7/4.7 个百分点。

HaVen-CodeQwen 在 VerilogEval-human 达到功能 pass@1=54.6%、pass@5=62.9%；HaVen-DeepSeek 在 VerilogEval v2 达到 pass@1=58.3%、pass@5=63.4%。在 RTLLM v1.1 上，HaVen-DeepSeek 的功能 pass@5 为 66.0%，正文称其比 OriGen 和 GPT-4 高 0.5 个百分点。表 IV 的模型行同时报告语法 pass@5，但语法与功能列必须结合表头解读，不能把所有数字都当成功能正确率。

### 7.2 与其他 LLM 方法的比较

论文称 HaVen 在三个 benchmark 的功能正确性上表现最好；在 VerilogEval-human 这一更贴近 HDL 工程师描述方式的集合上，HaVen-CodeQwen 的功能结果高于 OriGen 和 AutoVCoder 等对比方法。AutoVCoder 使用约百万 Verilog 模块和 50,000 个合成样本，而 HaVen 约用 62,000 个样本，语法 pass@5 低约 4–6 个百分点。

### 7.3 符号输入实验

44 个符号任务上，HaVen-CodeQwen 的总体 pass@1 为 47.4%（表 V 的表格值）；正文段落又写为 47.7%，存在排版/四舍五入不一致，应以正式出版版复核。按表格，真值表、波形图、状态图分别为 60.0%、30.8%、52.4%。它高于 RTLCoder、OriGen、GPT-4 和 DeepSeek-Coder-V2 的总体结果。

### 7.4 消融实验

在 VerilogEval-human 上，Base、vanilla 微调、vanilla+SI-CoT、vanilla+KL 和 vanilla+SI-CoT+KL 逐步比较。对三个基座模型，单独加入 SI-CoT 平均使 pass@1/pass@5 提升约 3.6/6.6 个百分点；KL-dataset 平均提升约 12.3/8.7 个百分点；两者结合仍有提升。K-dataset 与 L-dataset 的混合比例实验表明二者都有效，K-dataset 的收益较大，论文将其部分归因于样本量更多。

### 7.5 商业模型上的 SI-CoT

在同一 44 个符号任务上，表 VI 使用相同的 CodeQwen 生成的 SI-CoT 指令测试 GPT-4o mini、GPT-4 和 DeepSeek-Coder-V2。表格数据显示加入 SI-CoT 后的 pass@1 反而低于不加 SI-CoT 的数值；论文正文称 SI-CoT 直接帮助 CodeGen LLM，这与表 VI 的列标/解释存在明显不一致，不能据此做强结论。

## 8. 主要创新点

### 8.1 创新点一：面向 Verilog 的三类幻觉 taxonomy

论文把符号、知识和逻辑幻觉分别对应到输入理解、HDL 约定和逻辑实现问题，为后续方法模块提供诊断框架。价值在于它没有把所有错误都归入“语法错误”；表 II 还区分状态图误读、复位/边沿/使能误用、逻辑表达式和边界条件错误。

### 8.2 创新点二：SI-CoT 符号解释流程

SI-CoT 将不规则符号输入统一为可读指令，并补齐模块头，使代码模型不必直接从图表或转移表示中猜测逻辑。44 个符号任务上的专项结果支持该组件的有效性，但商业模型表 VI 的结果解释不一致，证据应谨慎。

### 8.3 创新点三：HDL 对齐的 K/L 数据构建

K-dataset 用人工/教材 exemplars 和主题匹配把通用指令改写成 HDL 工程风格；L-dataset 以逻辑表达式、输入输出映射和模板覆盖逻辑推理。该设计将数据质量与工程表达形式同时纳入训练，而不是只增加 Verilog 代码数量。

## 9. 局限性

### 9.1 论文明确或正文可见的局限

论文没有完整列出数据来源仓库、训练/测试去重协议、工业编译器名称版本，也未给出统一的真实硬件生成或综合 PPA 评估。SI-CoT 只覆盖真值表、波形图和状态图等输入形式；更复杂的时序约束、跨模块接口和综合后性能未被充分验证。论文的训练数据依赖 GPT-3.5 改写，可能把生成模型偏差带入数据。

### 9.2 阅读后的潜在局限

Verilog 编译通过只说明语法/部分 elaboration 有效，不能替代功能等价证明；benchmark 的 pass@k 也不保证综合后的时序、功耗和面积。方法主要提升规格到 RTL 的生成正确性，不能直接推导到 LLVM IR、RISC-V 汇编或其他硬件后端。表 IV、V、VI 中存在列解析和正文叙述不一致，复现时需要以原始脚本和正式版 PDF 为准。

## 10. 阅读后的研究方向反思

值得借鉴的是“错误类型—数据构建—推理前处理—评测切片”的闭环：先定义可观察的错误类别，再让数据和提示分别对症处理。不能简单照搬的是 GPT-3.5 重写和 Verilog benchmark；如果只把 Verilog 替换为 RISC-V 汇编，仍然只是语言/平台迁移，除非增加 ISA 语义、寄存器约束、调用约定和机器验证闭环。

按 Taxonomy v2，它更适合作为 `TRANSLATOR / T1_Source_Optimization_Refactoring` 的代码生成基线或数据构建参考，横向标签可记录 LLM、CoT、Compiler_Feedback、Verilog/RTL、Data_Augmentation；不应归为 pass selector 或 compiler generator。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 自定义扩展的符号-语义代码生成

#### 研究问题

让模型把 ISA 表、指令编码、伪代码和约束转换成可验证的 RISC-V 汇编或 LLVM intrinsic。

#### 与原论文的区别

输出从 Verilog RTL 变为带 ABI/寄存器约束的低层代码，并加入语义验证，不只是替换提示词。

#### 可能的创新点

以指令语义图和约束表为 SI-CoT 输入，使用 LLVM/Alive2 或 ISA 模拟器检查语义与编码一致性。

#### 实验框架

```text
ISA/伪代码/约束
 → 符号语义解析
 → LLM 生成 intrinsic/汇编
 → 编译器与模拟器验证
 → 反例反馈与候选筛选
```

#### 可行性

需要 RISC-V LLVM、Spike/QEMU 或 RTL 模拟器，以及小规模人工标注的指令语义集。

#### 主要风险

有限模拟测试可能被误写成形式化证明；自定义扩展的真实硬件性能数据也可能不足。

### 11.2 面向 MLIR 方言的工程化生成

#### 研究问题

从张量算子规格生成合法 MLIR 方言代码，并确保类型、shape、memory space 和 lowering 约束满足。

#### 与原论文的区别

将 HDL 工程约定替换为 MLIR verifier、dialect trait 与 lowering contract，并评估多级 IR。

#### 可能的创新点

把 verifier 诊断分类为类型、shape、合法化和后端约束四类，构造对应的错误驱动数据集。

#### 实验框架

```text
自然语言/算子图
 → 结构化 MLIR 规格
 → LLM 生成方言 IR
 → mlir-opt verifier/lowering
 → 诊断反馈与语义/性能评估
```

#### 可行性

可基于公开 MLIR dialect 和小规模算子 benchmark，先从 CPU/GPU 后端开始。

#### 主要风险

verifier 通过不代表 kernel 在真实设备上高效；需要把 correctness 与 latency 分开报告。

### 11.3 规格表示的跨模态数据泄漏审计

#### 研究问题

研究由 LLM 自动生成指令和人工规格混合训练时，重复代码、模板和 benchmark 泄漏如何影响 pass@k。

#### 与原论文的区别

重点从“提高分数”转为可审计的数据生成与隔离协议。

#### 可能的创新点

对代码、自然语言描述、逻辑表和图结构同时做近重复检测，并提供跨仓库时间切分。

#### 实验框架

```text
公开代码/人工规格
 → 结构与文本去重
 → 时间切分训练/测试
 → 多模型生成
 → 泄漏前后 pass@k 对比
```

#### 可行性

可以复用 HaVen 的公开代码与数据处理思路，但必须重新核验许可证和样本来源。

#### 主要风险

结构等价但文本不同的样本难以完全识别，且去重阈值会影响数据规模。

## 12. 与其他已读文献的关系

本批次仅完成这一篇论文，因此不存在可以依据正文直接建立的横向组合关系。与仓库中已有的 Verilog/RTL 生成论文相比，HaVen 的区别是把错误 taxonomy、符号解释和 HDL 对齐数据放在同一框架中；它可作为代码生成基线或数据构建参考。与 LLVM IR 优化论文不能直接合并结论：HaVen 的输出是 Verilog RTL，未研究 LLVM pass、IR 重写、RISC-V 后端或真实硬件代码生成。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 面向 HDL 工程实践的 Verilog 代码生成 |
| 核心问题 | 符号、知识、逻辑三类幻觉 |
| 输入 | 自然语言、状态图、波形图、真值表等规格 |
| 输出 | Verilog/RTL 代码 |
| 核心方法 | SI-CoT + K-dataset + L-dataset/KL-dataset |
| 使用的模型 | CodeLlama-7B、DeepSeek-Coder-6.7B、CodeQwen1.5-7B |
| 使用的编译器工具 | slang parser、工业级 Verilog 编译器；具体版本未说明 |
| 是否使用强化学习 | 否；没有强化学习奖励函数 |
| 是否使用形式化验证 | 否；使用编译/功能检查，但正文未给出形式化等价证明 |
| 数据集规模 | 约 43k vanilla、14k K、5k L；原始 GitHub 样本约 550k |
| 主要指标 | syntax/functional pass@1、pass@5 |
| 最重要实验结果 | HaVen-CodeQwen 在 VerilogEval-human 功能 pass@1/pass@5 为 54.6%/62.9%；HaVen-DeepSeek 在 VerilogEval v2 为 58.3%/63.4% |
| 核心创新 | 三类幻觉 taxonomy、SI-CoT、HDL 对齐数据增强 |
| 主要局限 | 数据去重/泄漏协议、工具版本、综合后 PPA 与跨架构迁移不足 |
| 与 RISC-V 研究的相关性 | 中：可借鉴规格解析与错误分类，但论文未研究 RISC-V |
| 最适合作为 | Verilog/RTL 代码生成 baseline、数据构建和提示方法参考 |

这篇论文最值得学习的是把符号输入处理、领域知识数据和逻辑数据增强拆成可消融模块；最主要的局限是验证仍主要停留在 benchmark 的语法/功能通过率，不能直接等同于形式化正确或综合后硬件质量。如果用于后续 RISC-V/MLIR 研究，合理做法是迁移“错误 taxonomy + 结构化规格 + 工具检查”的方法论，并增加 ISA/IR 语义验证，而不是简单替换目标语言。
