# Guaranteed Guess 文献阅读总结

论文题目：**Guaranteed Guess: A Language Modeling Approach for CISC-to-RISC Transpilation with Testing Guarantees**

作者：Ahmed Heakl；Sarim Hashmi；Chaimaa Abi；Celine Lee；Abdulrahman Mahmoud

发表时间：2025

发表平台：Findings of the Association for Computational Linguistics: EMNLP 2025，pp. 24474–24488

论文链接或编号：DOI `10.18653/v1/2025.findings-emnlp.1330`；arXiv `2506.14606`

关键词：CISC-to-RISC、汇编到汇编翻译、跨 ISA、LLM、测试驱动验证、ARM、RISC-V、tokenizer、RoPE 外推

> 本文档用于 staging 阶段阅读与复核，不代表正式入库。事实主要依据本地核验的 ACL 官方 PDF；阅读分析和后续建议单独标明。

## 1. 研究背景

论文研究的是不同指令集架构（ISA）之间的低级代码迁移，具体聚焦从 x86 这一复杂指令集架构（CISC）到 ARM 或 RISC-V 这类精简指令集架构（RISC）的汇编级翻译。作者指出，旧有 x86 二进制常常缺少可重新编译的源代码；Rosetta 2、QEMU 等动态翻译或虚拟化方案可以运行旧程序，但会引入持续的运行时、内存和能耗开销。直接跨 ISA 生成原生目标汇编，有机会把成本从每次运行时开销转为一次性翻译开销。

传统编译器通常依赖显式的源代码、IR 或人工编写的后端规则，而本文面对的是 x86 汇编到 ARM/RISC-V 汇编的结构性转换。CISC 与 RISC 在指令复杂度、寄存器—内存语义、控制流表达和代码长度上差异明显。作者还指出，通用代码 LLM 的 BLEU、困惑度等 NLP 指标不能替代功能正确性，因此需要把生成结果放入编译、链接和测试框架中评估。

## 2. 论文要解决的问题

### 2.1 CISC 到 RISC 的语义迁移

论文要解决 x86 汇编到 ARMv5、ARMv8 和 RISC-V64 汇编的跨 ISA 生成问题。目标不是恢复高级源代码，而是直接产生可汇编、可链接、可执行的目标 ISA 代码。

### 2.2 低级代码的功能验证

仅生成语法合法的目标汇编不足以保证程序行为正确。论文通过完整单元测试、程序级 coverage 和最终执行结果来筛选翻译结果，并将测试通过率作为翻译置信度的依据。

### 2.3 优化级别和上下文长度带来的困难

作者分别构造 `-O0` 和 `-O2` 编译结果，使模型接触未优化与优化后的 ISA 模式。论文报告 `-O2` 会引入指令重排、寄存器合并、折叠和 SIMD 等结构变化，导致翻译准确率明显下降；长的 BringupBench 工程还会受到输入加输出超出上下文窗口的影响。

> 本文主要研究：如何用面向 ISA 的小型代码 LLM，把 x86 汇编转换为 ARM/RISC-V 汇编，并通过测试驱动流程获得可量化的功能正确性信号。

## 3. 核心方法概述

Guaranteed Guess（GG）是一个两阶段的汇编到汇编跨 ISA 翻译管线。模型先根据 x86 汇编生成 ARM 或 RISC-V 汇编；随后将目标代码与测试、链接和执行流程结合，只有完整通过测试的结果才计为正确。

```text
AnghaBench / Stackv2 中的 C/C++ 程序
        ↓
去模板、去重、长度过滤
        ↓
用 GCC/Clang 编译为 x86 ↔ ARMv5/ARMv8/RISC-V 配对汇编
        ↓
扩展 ISA opcode/register tokenizer，训练 GG Guesser
        ↓
输入 x86 汇编，LLM 生成目标 ISA 汇编
        ↓
汇编、链接并运行测试；计算 coverage 与完整通过率
        ↓
pass@1 统计；必要时使用 beam search 生成候选
```

LLM 的角色是直接生成目标 ISA 代码，属于 TRANSLATOR，而不是只选择编译器 pass 的 selector。编译器、链接器和测试工具承担验证与执行反馈角色。GG 的“guarantee”不是形式化语义等价证明，而是由单元测试覆盖率和完整测试通过构成的工程置信度。

## 4. 实验框架与训练流程

### 4.1 数据构造与配对编译

训练数据来自 AnghaBench 和 The Stack v2。作者从 AnghaBench 采样约 1.01M 个程序、从 The Stack v2 采样约 306k 个程序，总计约 1.32M 个样本；去除模板代码、去重，并过滤少于 10 行或多于 16k 行的文件。程序分别编译为 x86、ARMv5、ARMv8 和 RISC-V64 汇编，并使用 `-O0` 与 `-O2` 两种优化级别。

### 4.2 模型训练

作者先在约 500k AnghaBench 子集上调超参数，再扩展到约 1.31M 样本训练。训练了 DeepSeek-Coder 1.3B、Qwen2.5-Coder 1.5B 和 Qwen2.5-Coder 0.5B 变体。训练使用 A100 40GB GPU、bfloat16、有效 batch size 2、2 个 epoch、学习率 `2×10^-5`、cosine schedule、weight decay 0.001 和 16k context window。

### 4.3 推理和验证

推理时使用 RoPE extrapolation 将上下文窗口扩展到 32.7k；使用 vLLM 部署，并在部分实验中使用 8-beam search。目标汇编随后被编译、链接并执行。HumanEval-C 要求所有测试通过；BringupBench 对多文件项目通过 Makefile、静态库、头文件和项目级脚本重建后比较预期输出。

### 4.4 工具与工程组件

论文使用 LLaMA-Factory、DeepSpeed ZeRO-3、liger kernels、FlashAttention2、vLLM、llama.cpp、GCC/Clang 和 gcov。本文没有使用强化学习；也没有把形式化验证器作为主验证闭环。论文尝试把 Guess & Sketch 的 Rosette/Z3 符号求解器作为输出修复环节，但报告其没有改善整体准确率。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数。PDF 中没有给出一个作为训练目标的自定义奖励公式；训练主要是代码模型的监督式语言建模，具体损失表达式未在正文中展开。

论文实际使用的评估判定可以概括为：

```text
Functional correctness = 1
当且仅当目标代码编译、链接，并通过该程序的全部测试
```

此外，作者用 gcov 统计 line coverage 和 program-counter coverage。coverage 是测试执行到的代码比例，不等价于形式化语义等价；论文第 7 节明确承认，测试覆盖不能保证完整语义正确性或最优性。

## 6. 实验设置

### 6.1 数据集来源

- AnghaBench：论文描述为约 1M 个可编译 C/C++ 程序，来自公开 GitHub 仓库。
- The Stack v2：论文使用其许可允许的代码子集，采样约 306k 个程序。
- HumanEval-C：由 LLM4Decompile 将 HumanEval 问题与测试转换为 C 版本，共 164 个编程问题。
- BringupBench：65 个裸机程序，规模约 85–5751 行，包含内部库、交叉链接和完整项目结构。

训练数据经过模板移除、去重和长度过滤。论文正文没有给出完整的跨数据集去污染审计，因此数据泄漏风险不能由当前 PDF 完全排除。

### 6.2 模型与工具

| 项目 | 设置 |
|---|---|
| 基础模型 | DeepSeek-Coder 1.3B；Qwen2.5-Coder 0.5B/1.5B |
| 训练硬件 | A100 40GB；bfloat16；有效 batch size 2 |
| 编译工具 | GCC、Clang；ARMv5/ARMv8/RISC-V 使用交叉编译或原生 ARM 工具链 |
| 推理 | vLLM；32.7k context；确定性输出；可用 8-beam search |
| 测试/覆盖率 | 单元测试、项目级执行、gcov；Apple M2 Pro 上用 powermetrics 测能耗 |
| 符号工具 | Rosette/Z3 作为对比/修复尝试，未改善整体准确率 |

### 6.3 对比方法

主要对比包括 GPT-4o、Qwen2.5-Coder、StarCoder2、DeepSeek-R1、DeepSeek-R1-Qwen，以及 RetDec 的 IR lifting + recompilation。真实设备案例将 GG 与 Rosetta 2 和原生 ARM 二进制比较。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
|---|---|---|
| pass@1 / exact functional accuracy | 最可能生成结果中完整通过测试的比例 | 越大越好 |
| line / PC coverage | 测试执行到的代码行或程序计数器比例 | 越大越好，但不等于证明 |
| CHRF | 汇编字符 n-gram 的表面相似度 | 越大表示表面更相似，不代表语义正确 |
| execution time | Apple M2 Pro 上的几何平均执行时间 | 越小越好 |
| CPU energy | `powermetrics` 测量的能耗 | 越小越好 |
| RAM usage | 运行期间内存占用 | 越小越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 HumanEval-C 的 `-O0` 翻译上，GG-1.5B 达到 ARMv8 99.39%、ARMv5 93.71%；在 RISC-V64 上作者报告 pass@1 为 89.63%。在 `-O2` 下，GG-1.5B 的 ARMv8 与 ARMv5 准确率分别降至 45.12% 和 50.30%，说明优化后结构对翻译明显更难。

在 BringupBench 上，GG-1.5B 的 `-O0` exact accuracy 为 49.23%；作者对超过 200 个单元测试二进制进行错误分析，报告约 17% 的失败与上下文截断有关。失败类型包括重复函数、栈/内存错误、缺失函数、寄存器标签错误和错误立即数。

### 7.2 与传统方法的比较

HumanEval-C 上，GG 报告 99.39%，RetDec 为 29.27%。但两者的系统假设并不完全相同：GG 直接生成目标汇编并用测试验证，RetDec 先进行 IR lifting 再重编译，因此不能把该数字解释为所有二进制翻译场景的普适优势。

### 7.3 与其他 LLM 方法的比较

表 3 中多数通用 LLM 在低级 ISA 翻译上接近 0%；GPT-4o 在不同任务上约为 0–10.3%。GG-1.5B 在 `-O0` 上显著高于这些 baseline，但在 `-O2` 和 BringupBench 上仍明显下降。作者将差距归因于架构感知训练、专用 tokenizer 和长上下文建模。

### 7.4 消融实验

在 ARMv8 HumanEval `-O0` 设置中，表 5 显示：增加 1M AnghaBench 数据使准确率从 0 提升到 93.94%；加入约 0.3M Stack v2 后为 95.38%；加入 RoPE extrapolation 后为 97.14%；扩展 tokenizer 后为 98.18%；8-beam search 后为 99.39%。该结果表明数据规模贡献最大，随后是上下文、tokenizer 与解码策略的累积贡献。

### 7.5 真实设备案例

在 Apple M2 Pro 上，作者比较原生 ARM、Rosetta 2 执行的 x86 和 GG 转换后的 ARM。100 次执行的几何平均结果显示，GG 相比 Rosetta 2 运行速度快 1.73 倍、CPU 能效好 1.47 倍、内存使用好 2.41 倍；GG 的内存约 1.03 MB，Rosetta 约 2.49 MB。该实验是特定硬件和工作负载下的案例，不是跨平台定律。

## 8. 主要创新点

### 8.1 创新点一：面向 CISC-to-RISC 的汇编级 Translator

论文把 LLM 直接用于 x86→ARM/RISC-V 汇编翻译，而不是先恢复高级源代码；这使其绕开了传统反编译再重编译的中间步骤。实验覆盖 ARMv5、ARMv8 和 RISC-V64，体现出跨 ISA 目标的明确设计。

### 8.2 创新点二：测试驱动的翻译置信度

GG 将候选目标汇编嵌入编译、链接和测试管线，并以完整测试通过作为功能正确样本。该设计把汇编翻译从单纯 token 相似度评价转为可执行行为评价，但作者自己也明确承认这不是形式化证明。

### 8.3 创新点三：ISA 感知的训练工程

扩展 tokenizer，把常见 opcode 和寄存器名组合为更合适的 token；再结合较长 context、RoPE extrapolation 和 beam search。消融实验显示，这些设计在专门数据规模基础上带来增量收益。

## 9. 局限性

### 9.1 论文明确承认的局限

- `-O2` 优化后的代码准确率显著下降。
- “guarantee” 受测试用例质量和 coverage 限制，不能保证完整语义等价或最优性。
- 实验主要覆盖 x86 到 ARM/RISC-V，其他 ISA 尚未实证。
- 在安全关键场景中，未经独立验证不应直接部署。

### 9.2 阅读后发现的潜在局限

- 训练数据通过 C/C++ 编译配对得到，覆盖的是可重编译源程序；与真实无源代码、带动态链接或异常控制流的二进制仍有差距。
- `-O0` 高准确率与 `-O2` 低准确率之间的落差说明模型可能学习了编译器/ISA 表面配对，而非充分的优化不变语义。
- BringupBench 的完整项目上下文会触及 32.7k 窗口，当前对更大工程、跨文件依赖和复杂系统调用的可扩展性仍不明确。
- 测试通过是有限行为采样，不应写成形式验证；真实设备结果只覆盖 Apple M2 Pro 的案例。

## 10. 阅读后的研究方向反思

本文对“大语言模型与编译器优化、LLVM IR、RISC-V、多架构优化”的直接启发是：跨 ISA Translator 需要把结构化架构知识、长上下文和可执行反馈结合起来。对于 RISC-V 研究，GG 已经直接覆盖 RISC-V64，因此简单地“把目标换成另一种 RISC-V 核”不足以形成新贡献。

值得借鉴的是：用编译器生成的配对数据进行训练、把测试/coverage 置于生成闭环、单独分析 `-O0` 与 `-O2` 的差异，以及用 tokenizer 适配 opcode/register 词汇。不能直接照搬的是其“testing guarantees”表述：有限测试只能提供经验置信度，不能代替 Alive2、符号执行或 ISA 语义验证。

就研究定位而言，GG 更适合作为跨 ISA Translator baseline 和测试驱动验证模块，而不是一个通用的后端优化器。对 LLVM IR 的启发主要是把 IR/机器指令的结构化语义作为额外输入，减少模型只依赖汇编表面模式的问题。

## 11. 可进一步尝试的研究方向

### 11.1 面向优化不变性的 IR/图增强跨 ISA 翻译

#### 研究问题

如何降低 `-O0` 与 `-O2` 之间的准确率落差，并保持跨 ISA 翻译后的行为一致。

#### 与原论文的区别

不只扩大汇编配对数据，而是引入 LLVM IR、控制流图、数据流图或符号执行摘要作为辅助条件。

#### 可能的创新点

设计 ISA 无关的语义锚点，并研究其对优化级别变化和目标 ISA 变化的鲁棒性。

#### 实验框架

```text
C/C++ → LLVM IR/CFG/DFG + x86 汇编 → Translator → ARM/RISC-V 汇编
                                      ↓
                             编译、测试、语义检查
                                      ↓
                              反馈到候选排序
```

#### 可行性

需要 LLVM、目标 ISA 交叉编译器、CFG/DFG 提取器和 HumanEval-C/BringupBench 类测试集。

#### 主要风险

图表示增加上下文和工程成本；如果只在合成 benchmark 上有效，可能不能说明真实二进制迁移能力。

### 11.2 测试反馈与形式语义检查的分层闭环

#### 研究问题

如何把 GG 的高覆盖率测试与局部符号验证或翻译验证结合，减少测试未覆盖路径造成的假阳性。

#### 与原论文的区别

原论文把 Rosette/Z3 作为有限输出修复尝试；新方向可让测试负责快速筛选、形式检查负责关键基本块或高风险差异。

#### 可能的创新点

提出按控制流风险分配验证预算的策略，并量化额外验证开销与错误漏检率。

#### 实验框架

```text
LLM 生成候选 → 快速编译/单元测试 → 风险定位
                                  ↓
                         对高风险片段做符号检查
                                  ↓
                         通过则输出，否则重生成
```

#### 可行性

需要目标 ISA 语义模型、符号执行/SMT 工具和可分解的跨 ISA 测试样本。

#### 主要风险

符号检查可能在循环、内存别名和系统调用上不可扩展；必须区分局部证明与全程序证明。

### 11.3 跨编译器后端的 RISC-V 迁移鲁棒性

#### 研究问题

GG 在 GCC/Clang 配对数据上训练，换用不同 LLVM/GCC 版本或不同 RISC-V 扩展后是否仍可靠。

#### 与原论文的区别

研究对象从“目标 ISA”扩展为“ISA + 编译器后端版本 + ABI/扩展组合”，重点测试工具链漂移。

#### 可能的创新点

构建 compiler-version/extension-aware 的翻译条件，并把 ABI 约束作为显式验证信号。

#### 实验框架

```text
多版本 GCC/LLVM 编译 → 同一源程序的多后端汇编对
        ↓
条件化 Translator → RISC-V 基础指令集/扩展目标
        ↓
ABI、链接、测试和性能联合评估
```

#### 可行性

需要多版本 LLVM/GCC、RISC-V 交叉工具链、模拟器或真实开发板，以及严格固定的 ABI 测试。

#### 主要风险

性能变化可能来自工具链而不是 Translator；必须报告编译器版本、扩展、调用约定和测试覆盖。

## 12. 与其他已读文献的关系

本批次阶段 2 只成功核验并阅读 Guaranteed Guess，因此这里不把其他队列条目写成已读事实。

与本仓库已有的 `Compiler generated feedback for Large Language Models` 相比，GG 的核心是跨 ISA 汇编翻译与测试验证，而不是 LLVM IR 代码尺寸优化；二者都使用编译/执行反馈，但输入层级、输出层级和评价目标不同。与本轮 staging 中的 Syzygy、VERT 等候选相比，GG 已有正式 Findings EMNLP 2025 venue，并且直接包含 x86→RISC-V/ARM 的实证；这些候选不能在本笔记中视为已完成的正文阅读。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | x86 汇编到 ARM/RISC-V 汇编的 CISC-to-RISC Translator |
| 核心问题 | 跨 ISA 结构差异、优化代码重排、测试覆盖和上下文限制 |
| 输入 | x86 汇编；训练阶段来自 C/C++ 编译配对数据 |
| 输出 | ARMv5/ARMv8/RISC-V64 汇编 |
| 核心方法 | GG Guesser + ISA tokenizer + RoPE 外推 + 测试驱动验证 |
| 使用的模型 | DeepSeek-Coder 1.3B；Qwen2.5-Coder 0.5B/1.5B |
| 使用的编译器工具 | GCC、Clang、vLLM、gcov、Rosette/Z3 对比尝试 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 主流程否；Rosette/Z3 尝试未改善整体准确率 |
| 数据集规模 | 约 1.32M 训练样本；HumanEval-C 164 题；BringupBench 65 个程序 |
| 主要指标 | 完整测试通过率、coverage、CHRF、运行时间、能耗、内存 |
| 最重要实验结果 | HumanEval-C ARMv8 `-O0` 99.39%；RISC-V64 89.63%；BringupBench `-O0` 49.23% |
| 核心创新 | 汇编级跨 ISA 翻译与测试置信度结合；架构感知 tokenizer/上下文设计 |
| 主要局限 | `-O2` 性能下降；测试不等于形式证明；真实系统覆盖有限 |
| 与 RISC-V 研究的相关性 | 高：正文直接评估 x86→RISC-V64，但尚未覆盖更广扩展/工具链漂移 |
| 最适合作为 | TRANSLATOR/T3 跨 ISA baseline 与测试验证模块 |

> 这篇论文最值得学习的是把 ISA 感知的源码配对训练、汇编级生成和可执行测试放进一个闭环；最主要的局限是“测试保证”仍受 coverage 和样本分布限制，且 `-O2` 鲁棒性不足；如果用于后续研究，最合理的使用方式是作为跨 ISA Translator baseline 和验证模块，而不是简单把目标架构替换后宣称已有新方法。
