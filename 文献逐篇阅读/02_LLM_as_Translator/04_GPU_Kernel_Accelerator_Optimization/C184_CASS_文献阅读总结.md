# CASS 文献阅读总结

论文题目：**CASS: Nvidia to AMD Transpilation with Data, Models, and Benchmark**

作者：Ahmed Heakl、Gustavo Bertolo Stahl、Sarim Hashmi、Seung Hun Eddie Han、Mukul Ranjan、Arina Kharlamova、Salman Khan、Abdulrahman Mahmoud

发表时间：2026

发表平台：Proceedings of the 64th Annual Meeting of the Association for Computational Linguistics，Volume 1: Long Papers，pp. 34489–34508

论文链接或编号：ACL Anthology `2026.acl-long.1592`；DOI `10.18653/v1/2026.acl-long.1592`；早期版本 arXiv `2505.16968`

关键词：CUDA、HIP、NVIDIA SASS、AMD RDNA3、GPU 代码翻译、跨 ISA、跨微架构、CASS-Bench、Qwen2.5-Coder、指令监督微调

> 本文档严格依据 A4 staging 中的 ACL 2026 正式 PDF 撰写。论文事实、阅读后的分析和后续建议分开描述。PDF 页码以论文印刷页/章节为准；PDF 摘要、正文与 ACL 元数据在“运行时/内存匹配比例”上存在口径差异，已明确标出。

## 1. 研究背景

GPU 软件生态存在明显的厂商锁定。CUDA 是 NVIDIA 的主流 GPU 编程模型，但其程序依赖 NVIDIA 的硬件与编译栈；AMD 侧提供 HIP/ROCm 作为相近的 C++ GPU 编程接口。传统 HIPIFY 主要在源代码层做 CUDA 到 HIP 的转换，无法直接处理已经编译的 CUDA 二进制，也难以覆盖内联 PTX、warp 大小、架构相关预处理宏和特殊 intrinsic 等需要语义判断的情况（第 1 节）。

更低层的 SASS→RDNA3 翻译更加困难：NVIDIA 使用包含隐式 stall 信息的 SASS 指令，AMD RDNA3 使用显式的 `s_waitcnt`、标量/向量流水线和不同的寄存器/操作数约束。两者不仅指令名称不同，执行模型、寄存器分配和调度方式也不同。现有 GPU 数据集通常只覆盖 CUDA 源码或运行时性能，缺少 CUDA/HIP 与 SASS/RDNA3 的语义对齐样本（第 2 节）。

论文因此把问题定位为跨厂商、跨层级的 GPU 代码迁移：既要支持 CUDA→HIP 源到源翻译，也要支持 NVIDIA SASS→AMD RDNA3 的汇编到汇编翻译，并用编译与执行结果确认输出是否可用。

## 2. 论文要解决的问题

### 2.1 缺少跨厂商、跨表示层级的训练数据

公开数据缺少同一 GPU 程序在 CUDA/HIP 源码、主机汇编和设备汇编之间的成对对应关系，导致模型无法学习跨 runtime 与跨 ISA 的映射。论文提出 CASS 数据集和生成管线来填补这一缺口。

### 2.2 通用 LLM 缺少 GPU 汇编先验

通用代码模型在 SASS 与 RDNA3 上的预训练暴露有限，容易产生未知指令、无效操作数、寄存器对齐错误和控制流标签错误。论文研究领域专用模型是否能通过对齐训练数据改善这些低层错误。

### 2.3 缺少可执行的跨架构评测基准

既有数据集很少同时覆盖 CUDA→HIP 与 SASS→RDNA3，也缺少编译、执行和输出等价检查。论文构建 CASS-Bench，用真实 GPU 执行和差分测试评估翻译结果。

> 本文主要研究：如何构建经编译/执行验证的 CUDA–HIP、SASS–RDNA3 对齐语料，并训练模型直接输出跨架构 GPU 源码或汇编翻译结果。

## 3. 核心方法概述

CASS 是一个数据集、基准和模型套件的组合。模型采用 Qwen2.5-Coder 进行指令监督微调，分别训练源代码翻译模型和汇编翻译模型。模型输入 CUDA 源码或 NVIDIA SASS，输出 HIP 源码或 AMD RDNA3 汇编；传统编译器、汇编器和运行测试负责检查输出是否可编译、是否产生等价结果。

```text
Stackv2 CUDA 文件 + Qwen2.5-Coder 合成 CUDA 文件 + OpenCL 文件
        ↓
过滤、去重、HIPIFY 转换
        ↓
分别通过 NVIDIA 与 AMD 编译管线生成主机/设备代码
        ↓
保留两端都能编译的 CUDA-HIP / SASS-RDNA3 对齐样本
        ↓
划分 CASS 训练集与 CASS-Bench 测试集
        ↓
Qwen2.5-Coder 1.5B/3B/7B 指令监督微调
        ↓
输出 HIP 或 RDNA3 汇编
        ↓
编译 + 执行 + 输出等价检查 + runtime/memory 对比
```

LLM 在本文中有两个角色：一是使用 Qwen2.5-Coder-32B 按模板合成 CUDA 样本；二是作为被微调的跨架构代码翻译器。它不是 pass 选择器，也不是只生成编译器规则。方法不使用运行时迭代修复或强化学习闭环；评测阶段只执行一次输入到输出的翻译，再进行编译和执行验证。

## 4. 实验框架与训练流程

### 4.1 数据收集与合成

论文从 Stackv2 中选择 CUDA 文件数量最多的前 200 个仓库，保留仓库结构以提高相对 include 和依赖的可编译性。过滤掉超过 7k 行、少于 10 行、模板化样例以及不含 CUDA kernel 的文件，得到 24k 个可用真实样本；正文后续数据表将 Stack 子集最终统计为 34.1k。

为增加架构和语义多样性，作者用 Qwen2.5-Coder-32B 根据变量化 persona 模板合成 85.5k 个 CUDA 样本。模板覆盖矩阵运算、图算法、科学计算、机器学习、稀疏操作、模拟、图像/信号处理、优化算法、密码学和数据结构等。合成样本经过编译、语法和内存操作过滤，最终保留 20.6k 个有效 synthetic 样本，成功率约 49.1%。

### 4.2 跨栈翻译与编译

作者使用 HIPIFY 将 CUDA 转成 HIP。约 43.9% 的文件无法通过转换而被丢弃。随后使用 `-Os` 编译以减少代码大小；论文报告相对于 `-O3` 平均减少约 9.3% token。NVIDIA 栈使用 `nvcc`、二进制/`cuobjdump` 等步骤提取 SASS；AMD 栈使用 `hipcc` 与 ROCm 工具生成 RDNA3，并修改设备二进制注入顺序以独立提取主机与设备汇编。

最终还加入约 5.9k 个 OpenCL 样本：NVIDIA 侧经 OpenCL→PTX→CUDA 栈生成设备汇编，AMD 侧由 clang 直接生成 LLVM/设备汇编。三类来源合计 60,694 个对齐样本。

### 4.3 指令监督微调

作者对 Qwen2.5-Coder 1.5B、3B、7B 进行 Instruction-Supervised Fine-Tuning（指令监督微调）。源和汇编翻译分别训练模型。CUDA 汇编输入去除冗余空白和注释，使 token 数约减少 15%；HIP 汇编不做该预处理，因为空白变化可能影响解析。

训练使用 4 张 A100、batch size 4、gradient accumulation 32、有效 batch size 512、learning rate `1×10^-5`、16k context window 和 2 个 epoch。实现使用 DeepSpeed、Liger Kernel、Paged Adam 与 LLaMA-Factory；推理时使用 RoPE extrapolation 将上下文扩展到约 32.7k token。

### 4.4 评测流程

CASS-Bench 含 369 个任务，覆盖 18 个 GPU 域。每个任务都要求 CUDA→HIP 或 SASS→RDNA3 输出能在两端编译并执行，且通过自动差分测试检查输出等价。作者还按输入 token 长度分为 easy（<9k）、medium（9k–12k）和 hard（>12k）进行分层评测。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有 PPO、GRPO 或其他策略优化。主要训练目标是指令监督微调的语言模型目标，但 PDF 未给出可独立核验的完整 token-level loss 公式，因此不能补写具体损失表达式。

评测中的“正确性”不是训练奖励，而是后验判定：

```text
Test Accuracy = 编译成功且执行输出与参考结果完全匹配的任务数 / CASS-Bench 任务总数
```

论文表 3 将 `Test Acc.` 定义为严格端到端准确率，即 compile + exact output match；`Compile Rate` 只表示能否成功编译；`chrF` 衡量字符级 n-gram 相似度。runtime 和 memory 对比是性能/行为分析，不是形式化等价证明。

## 6. 实验设置

### 6.1 数据集来源

| 数据/子集 | 来源与处理 | 规模 |
| --- | --- | ---: |
| Stack | Stackv2 的 CUDA 仓库样本，仓库级下载、过滤、去重 | 最终 34.1k |
| Synthetic | Qwen2.5-Coder-32B 按变量化模板生成并编译过滤 | 最终 20.6k |
| OpenCL | Stack 数据中的 OpenCL，经 NVIDIA/AMD 两条管线编译 | 最终约 5.9k |
| CASS | 对齐的 CUDA/HIP、主机汇编和设备汇编 | 60,694 |
| CASS-Bench | 与训练集去重、双端可编译执行、差分测试通过 | 369，18 个域 |

数据由公开代码、模型合成和编译产物组合而成。作者说明进行 prompt-space 与 output-space 去重，并用 AST/opcode 相似度过滤合成近重复；但数据泄漏风险不能由论文实验完全排除，因为 Stackv2 和基础模型预训练语料的重叠程度未被完全证明。CASS-Bench 通过与训练集严格去重降低了直接重叠风险。

### 6.2 模型与工具

- 基础模型：Qwen2.5-Coder 1.5B、3B、7B；合成 CUDA 使用 Qwen2.5-Coder-32B。
- 编译与转换：HIPIFY、`nvcc`、`cuobjdump`、`hipcc`、clang、ROCm/NVIDIA 编译栈。
- 硬件：NVIDIA A100 80GB（sm80 数据/训练主平台）、NVIDIA RTX 4090（sm89 泛化测试）、AMD Radeon RX 7900 XT（RDNA3）；微调使用 4×A100 40GB。
- 软件框架：DeepSpeed、Liger Kernel、Paged Adam、LLaMA-Factory、Docker。
- 验证：编译、执行、差分输出、运行时间和内存分析；未使用 Alive2、SMT 或其他形式化验证器。

### 6.3 对比方法

表 3 的主要比较对象包括：

- 工具：ZLUDA、HIPIFY；分别代表 LLVM IR 层运行时/二进制翻译和源级规则转换。
- 通用/推理模型：GPT-5-mini、Claude-Haiku-4.5、Gemini-2.5-Flash、GPT-5.1、Gemini-2.5-Pro、Olmo-3.1-32B、DeepSeek-R1-Qwen-14B 等。
- 代码模型：LLaMA-3.1-8B、Gemma-3-27B、Qwen3-30B-A3B、Qwen3-Coder-30B-A3B、Qwen2.5-Coder-32B、DeepSeek-Coder-V2-Lite。
- 本文模型：CASS-sm89-1.5B/3B、CASS-sm80-1.5B/3B/7B。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
| --- | --- | --- |
| Test Accuracy | 编译成功且执行输出完全匹配的比例 | 越大越好 |
| Compile Rate | 生成代码成功编译的比例 | 越大越好 |
| chrF | 字符级 n-gram 相似度 | 越大越好，但不等于语义等价 |
| Runtime difference | 翻译结果与 ground truth 的运行时间差 | 越接近 0 越好 |
| Memory difference | 翻译结果与 ground truth 的内存使用差 | 越接近 0 越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 CASS-Bench 的 369 个任务上，最佳本文模型 CASS-sm80-7B 达到 69.11% assembly Test Accuracy、90.24% Compile Rate 和 81.28 chrF；source Test Accuracy 为 88.17%，Compile Rate 为 98.92%。这里的 assembly 结果对应 SASS→RDNA3，source 结果对应 CUDA→HIP。

### 7.2 与传统方法的比较

ZLUDA 的 assembly Test Accuracy 为 7.86%，source Test Accuracy 为 19.24%；HIPIFY 的 source Test Accuracy 为 87.46%、Compile Rate 为 92.95%。因此，CASS-sm80-7B 的 source accuracy 88.17% 仅比 HIPIFY 高 0.71 个百分点，但其价值主要在于统一支持更低层的 SASS→RDNA3 翻译，而 HIPIFY 不处理该任务。

### 7.3 与其他 LLM 方法的比较

GPT-5.1 在 assembly 上为 22.22% Test Accuracy、25.20% Compile Rate；Qwen2.5-Coder-32B 为 5.42%、6.50%。CASS-sm80-7B 的 69.11% assembly accuracy 明显高于这些通用或代码专用模型。正文将差距归因于 CASS 对厂商特定指令、寄存器和操作数约束的领域适配，而不是通用代码生成能力。

### 7.4 消融实验

表 4 采用累积加入设置：Stack 子集 assembly accuracy 为 48.24%；加入 synthetic 数据后为 59.89%，绝对提升 11.65 个百分点；加入 OpenCL 后为 65.23%，再提升 5.34 个百分点；加入 RoPE extrapolation 后为 69.11%，再提升 3.88 个百分点。论文因此认为合成数据提供的架构/语义多样性贡献最大。

### 7.5 跨微架构与失败案例

在 A100 sm80 上训练的 CASS-sm80-7B 迁移到 RTX 4090 sm89↔RX7900 XT 时，assembly accuracy 从 69.11% 降至 32.5%。这说明即使都属于 NVIDIA，sm80 与 sm89 的指令、stall、寄存器分配和缓存特征差异也会显著影响泛化。

附录 A.6 统计失败案例中：100% 涉及控制流，75% 访问全局内存，62.07% 使用同步，10.34% 使用原子操作，6.82% 使用共享内存，11.36% 含局部数组；这些类别可重叠。附录 A.9 展示了寄存器对齐、VGPR bank、幻觉指令、literal operand、缺失标签和操作数类型等六类具体错误。

### 7.6 运行时/内存结果的口径说明

PDF 摘要和结论写“超过 95%”样本在 runtime/memory 上匹配或保留 native behavior，图 5/10 进一步报告超过 95% 样本的 runtime 差异在 ±0.5 秒内、memory 差异低于 ±0.3 MB。ACL Anthology 元数据摘要曾写为 85%。本笔记以正式 PDF 正文为主，但将该不一致保留为后续复核项；无论哪一口径，都不能将其解释为形式化语义等价证明。

## 8. 主要创新点

### 8.1 创新点一：跨源代码与 GPU 汇编的对齐语料管线

相较于只收集 CUDA 源码或只测运行时性能的既有数据，CASS 同时保留 CUDA/HIP 源、主机汇编和 SASS/RDNA3 设备汇编，并通过双端编译与执行形成配对样本。价值在于把跨 runtime 和跨 ISA 翻译放到同一数据接口中。数据管线是本文的核心贡献之一。

### 8.2 创新点二：CASS-Bench 的端到端执行评测

CASS-Bench 将 369 个任务分布到 18 个 GPU 域，并要求编译成功、执行成功且输出匹配。它比单纯 BLEU/chrF 或源代码相似度更接近真实翻译可用性，但仍是有限任务集合上的动态验证。

### 8.3 创新点三：面向 GPU ISA 约束的领域模型

CASS 模型用对齐 CUDA/HIP 与 SASS/RDNA3 数据微调 Qwen2.5-Coder，使模型学习寄存器、操作数、同步和指令编码约束。实验显示这对 assembly 翻译的提升明显，但其训练范式本身是标准指令监督微调，不应把“使用 Qwen2.5-Coder”单独视为创新。

### 8.4 创新点四：把微架构泛化暴露为独立问题

sm80→sm89 的明显性能下降显示 GPU 汇编翻译不仅是跨厂商问题，也是同一厂商内部的跨微架构问题。该分析为后续加入多代 GPU、可迁移表示或架构条件控制提供了直接证据。

## 9. 局限性

### 9.1 论文明确承认的局限

- HIPIFY 对 WMMA、cuBLAS TensorOp 和其他矩阵/ Tensor Core 原语支持不足，导致相关 kernel 难以进入最终数据集。
- 数据和实验主要覆盖 NVIDIA A100/RTX 4090 与 AMD RX 7900 XT，未证明对其他 GPU、其他 RDNA 代际或其他加速器有效。
- 输入较长时翻译质量急剧下降；附录 A.7 显示 assembly accuracy 随 easy/medium/hard 长度分层为 35.0%、33.33%、17.65%。
- 领域模型仍会产生大量无效指令、操作数约束和控制流错误。

### 9.2 阅读后发现的潜在局限

- `Test Accuracy` 基于有限输入和差分执行，不能替代全输入域语义等价证明；论文没有使用形式化验证。
- source accuracy 高度受 CUDA/HIP 表面相似性帮助，不能直接外推到语义差异更大的 ISA 或编程模型。
- 训练语料中 synthetic CUDA 由 LLM 生成，虽有编译过滤和去重，但生成分布可能影响模型对真实工程 kernel 的覆盖。
- 论文报告的 runtime/memory“匹配”与 ACL 页面摘要的 85%/正文的 95% 存在不一致，需要在正式入库前核对最终勘误或作者仓库。
- 论文称“not optimization-aware yet”，因此 CASS 更准确地是翻译/可移植性基础，不是已经解决跨 GPU 性能优化的系统。

## 10. 阅读后的研究方向反思

CASS 对本仓库研究方向最直接的价值是提供了一个 `TRANSLATOR/T4` 案例：模型直接生成 GPU 目标代码，编译器和真实硬件反馈只负责验证输出。它适合作为跨架构 GPU 翻译的 baseline、数据构建参考和错误分类参考，不应被重新解释为 SELECTOR。

值得借鉴的是“源、IR/汇编、硬件执行结果对齐”的证据链，以及把编译失败细分为 ISA 约束、寄存器、同步、标签和操作数错误。不能直接照搬的是 CUDA/HIP 的 API 相似性和 A100/RDNA3 的具体管线；只把 CUDA/HIP 替换成 RISC-V/CUDA 并不会自动形成创新。

如果迁移到 RISC-V，更有价值的问题应是：如何用可验证的 IR/ISA 中间层处理 GPU/CPU 后端差异，如何把 RISC-V 向量/矩阵扩展约束显式编码进翻译过程，以及如何在有限硬件上进行跨 ISA 的编译—执行—修复闭环。CASS 本身更适合作为数据管线和评测设计参考，而不是直接复现的完整研究框架。

## 11. 可进一步尝试的研究方向

### 11.1 方向一：约束感知的跨 ISA 翻译

#### 研究问题

能否将目标 ISA 的寄存器配对、bank、literal、同步和控制流约束显式提供给模型，降低“可生成但不可汇编”的错误？

#### 与原论文的区别

原论文主要依赖监督语料学习约束；新方向把 ISA 约束编码为可检查的中间表示或解码约束。

#### 可能的创新点

约束抽取、结构化表示、编译器错误到约束修复建议的映射。

#### 实验框架

```text
CUDA/SASS 输入 → 约束抽取 → LLM 生成 RDNA3 候选 → 汇编器诊断
        ↓                                      ↑
     约束库更新 ← 错误分类与修复候选 ← 编译/执行检查
```

#### 可行性

可复用 CASS-Bench、LLVM/ROCm 工具链和现有 CASS 模型；需要目标 GPU 或可用的汇编编译环境。

#### 主要风险

静态约束不足以保证动态语义；不同 GPU 代际的约束库维护成本高。

### 11.2 方向二：跨微架构的条件化 GPU 翻译

#### 研究问题

能否在同一个模型中显式条件化 sm80、sm89 和 RDNA3，减少 A100→RTX 4090 的泛化下降？

#### 与原论文的区别

原论文分别训练/测试特定后端并观察泛化损失；新方向把微架构作为输入条件和评测维度。

#### 可能的创新点

微架构 token、硬件特征检索、跨代 instruction mapping 和小样本适配。

#### 实验框架

```text
源代码/源汇编 + 目标微架构描述
        ↓
条件化翻译模型
        ↓
目标汇编 → 编译/执行 → 跨代准确率与性能泛化
```

#### 可行性

可从 CASS 的 sm80/sm89/RDNA3 数据开始；需要补充至少一代新 GPU 或模拟/汇编级评测。

#### 主要风险

目标微架构信息可能泄漏到训练样本；性能差异未必能由文本条件解释。

### 11.3 方向三：RISC-V 向量后端的可验证翻译

#### 研究问题

能否将 CASS 的跨架构数据—编译—执行框架迁移到 CUDA/HIP→RISC-V Vector 或 LLVM IR→RVV 汇编，并引入等价性检查？

#### 与原论文的区别

不是简单更换目标 ISA，而是加入 RVV 的向量长度、mask、tail policy 和调用约定等结构化约束，以及更强的语义验证。

#### 可能的创新点

RVV-aware 中间表示、编译器错误反馈、差分执行与形式化/符号检查的组合。

#### 实验框架

```text
CUDA/HIP 或 LLVM IR → RVV-aware LLM 翻译 → LLVM/GCC 编译
        ↓                         ↓
   语义/ABI 检查 ← 仿真器或真实 RVV 硬件 ← 运行时结果
```

#### 可行性

需要 LLVM/RVV 后端、Spike/QEMU 或真实 RVV 平台，以及可控的 kernel 子集。

#### 主要风险

GPU kernel 与 RVV 执行模型不完全同构；模拟器性能不能替代真实硬件评测。

## 12. 与其他已读文献的关系

本批次当前只完成 CASS 一篇全文阅读，因此不对备选的 Dart 反编译或 PReMM 做已读文献事实比较。与 A4 阶段 1 中已发现的 `QiMeng-NeuComBack` 相比，CASS 同样属于 `TRANSLATOR`，但输入输出不同：NeuComBack 处理 LLVM IR→CPU assembly，CASS 处理 CUDA/HIP 源和 SASS/RDNA3 GPU 代码；两者都依赖编译/执行反馈，但 CASS 更强调数据集和跨硬件对齐，NeuComBack 更强调 IR→ASM 生成与 prompt 演化。

与仓库已有的通用 LLM Compiler、SuperCoder 或 GPU kernel 优化工作存在研究邻近性，但 CASS 的正式贡献边界是跨 vendor GPU 翻译数据与评测，不应重复计入“超级优化”或“GPU 性能优化 agent”。本条后续最适合作为 GPU/accelerator translator 的数据与评测基线。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | CUDA/HIP 源到源、SASS/RDNA3 汇编到汇编翻译 |
| 核心问题 | 缺少跨 vendor、跨表示层级的 GPU 对齐数据与可执行评测 |
| 输入 | CUDA 源码或 NVIDIA SASS；目标架构条件 |
| 输出 | HIP 源码或 AMD RDNA3 汇编 |
| 核心方法 | CASS 数据管线 + CASS-Bench + Qwen2.5-Coder 指令监督微调 |
| 使用的模型 | Qwen2.5-Coder-32B 合成数据；1.5B/3B/7B 翻译模型 |
| 使用的编译器工具 | HIPIFY、nvcc、cuobjdump、hipcc、clang、ROCm/NVIDIA 栈 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；采用编译、执行和差分测试 |
| 数据集规模 | CASS 60,694 对齐样本；CASS-Bench 369 任务、18 个域 |
| 主要指标 | Test Accuracy、Compile Rate、chrF、runtime/memory difference |
| 最重要实验结果 | CASS-sm80-7B：source accuracy 88.17%，assembly accuracy 69.11%；sm80→sm89/RDNA3 泛化降至 32.5% |
| 核心创新 | 跨 CUDA/HIP 与 SASS/RDNA3 的对齐语料和端到端执行评测 |
| 主要局限 | Tensor Core 覆盖不足、长上下文退化、有限硬件与无形式化证明 |
| 与 RISC-V 研究的相关性 | 中；可借鉴跨 ISA 数据/验证框架，但 CUDA/HIP 与 RVV 执行模型不同 |
| 最适合作为 | GPU translator 的 baseline、数据管线和评测设计参考 |

> 这篇论文最值得学习的是把源代码、低层汇编、编译结果和真实执行结果放到同一条可审计链路中；最主要的局限是它仍依赖有限硬件与动态测试，且对 Tensor Core 等复杂指令覆盖不足；如果用于后续研究，最合理的使用方式是作为跨架构翻译的数据/评测基线，而不是简单把目标平台替换成另一种 ISA。
