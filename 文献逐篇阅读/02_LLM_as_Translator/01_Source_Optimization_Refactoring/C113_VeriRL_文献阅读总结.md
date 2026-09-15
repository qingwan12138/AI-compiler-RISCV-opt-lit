# VeriRL 文献阅读总结

论文题目：**VERIRL: Boosting the LLM-based Verilog Code Generation via Reinforcement Learning**

作者：Fu Teng、Miao Pan、Xuhong Zhang、Zhezhi He、Yiyao Yang、Xinyi Chai、Mengnan Qi、Liqiang Lu、Jianwei Yin

发表时间：2025

发表平台：2025 IEEE/ACM International Conference on Computer-Aided Design（ICCAD 2025），论文页码 1–9；本地全文为 arXiv 版本 v1（2025-08-25，12 页）。

论文链接或编号：[IEEE 记录](https://ieeexplore.ieee.org/abstract/document/11241003)、DOI `10.1109/ICCAD66269.2025.11241003`、[arXiv:2508.18462](https://arxiv.org/abs/2508.18462)；本地 PDF：[VERIRL_ICCAD2025.pdf](VERIRL_ICCAD2025.pdf)

关键词：Verilog 代码生成、硬件描述语言、强化学习、奖励模型、执行反馈、测试平台、LLM

> 本笔记基于本地 PDF 正文逐页阅读。论文事实与阅读后的分析分开记录；论文没有明确说明的事项不作推断。

## 1. 研究背景

本文属于大语言模型辅助硬件设计、Verilog/RTL 代码生成和强化学习后训练交叉领域。软件代码生成已经受益于 CodeLlama、Qwen2.5-Coder、DeepSeek-Coder 等代码模型，但作者指出，Verilog 同时包含并发语义、时序语义、严格语法和仿真依赖，不能只靠表面 token 模式生成可靠 RTL（第 1 节）。

已有 RTLFixer、OriGen、RTLCoder、AutoVCoder、HaVen、CraftRTL 等工作主要使用提示工程、代码到代码增强或监督微调（SFT）。作者认为，SFT 容易学习训练样本表面模式；当问题更复杂或分布变化时，模型可能生成语法看似合理但不能通过功能仿真的代码。Verilog 的正确性需要测试平台执行反馈，而不是只进行字符串匹配。

作者将困难归纳为两点：

1. 奖励稀疏且噪声大：大量初始生成结果编译失败或 pass rate 为 0，直接使用仿真反馈会产生近似二值、难以学习的信号。
2. 强化学习训练不稳定：稀疏奖励和小规模高质量数据可能导致过拟合、奖励方差升高和灾难性遗忘。

因此，本文引入面向 Verilog 的数据构造、奖励模型、Trace-back based Rescore（TbR，基于回溯的重评分）和 Sample-balanced Weighting（SbW，样本均衡加权）组合，试图让模型直接朝可执行、功能正确的 RTL 学习。

## 2. 论文要解决的问题

### 2.1 如何获得比二值仿真结果更有用的奖励信号

对一个 Verilog 问题，模型可能生成编译失败、部分正确或只在部分测试用例上正确的实现。论文研究如何利用失败样本中的中间推理和测试反馈进行再生成，构造更丰富的偏好数据，而不是直接丢弃所有低分候选（第 3.B、5 节）。

### 2.2 如何降低 Verilog 强化学习中的训练不稳定

论文研究如何依据策略生成概率和奖励模型分数对样本分类，并对不同类别施加不同的梯度权重，从而同时鼓励学习高价值样本、抑制噪声和限制策略偏移（第 3.C、6 节）。

### 2.3 如何验证方法是否改善了功能正确性

论文以 VerilogEval-human、RTLLM v1.1、VerilogEval v2 和 RTLLM v2 为主要评测集，用仿真通过率定义的 pass@1/pass@5 比较 VeriRL 与通用 LLM、Verilog 专用模型、SFT 和 DPO 方法。

> 本文主要研究：如何通过执行反馈驱动的奖励建模与强化学习，提高 LLM 从自然语言规格生成可仿真通过的 Verilog RTL 的能力。

## 3. 核心方法概述

VeriRL 是一个面向 Verilog 生成的四阶段训练框架。它先用冷启动 SFT 建立基本的推理和代码格式能力；然后用奖励模型和 SbW-enhanced Reinforce++ 进行第一次 RL；再把高通过率推理样本用于第二次 SFT；最后进行第二次 RL，得到最终模型。框架的两个主要专门机制是 TbR 和 SbW。

整体数据流如下：

```text
PyraNet 700K+ Verilog 问题
        ↓ 去重、编译过滤、质量/难度筛选
Veribench-53K 问题集
        ↓ GPT-4o-mini 重写题面 + 为每题生成约 5–10 个 testbench
CodeQwen2.5 生成多份 Verilog 候选
        ↓ 编译与 testbench 仿真，得到 pass rate
低分节点递归反思/再生成，形成 reward tree
        ↓ 子节点平均奖励回溯到父节点（TbR）
偏好对（正例 pass rate > 0.8，且与负例差距 > 0.4）
        ↓ Bradley–Terry 对比学习
Verilog 奖励模型
        ↓ 奖励 + 生成概率分类与样本加权（SbW）
Reinforce++ RL → 39K 高质量 CoT 样本 → SFT → 再次 RL
        ↓
Verilog 代码与功能仿真 pass@k
```

LLM 在系统中有三种角色：GPT-4o-mini 用于题面重写、测试平台生成和冷启动样本整理；CodeQwen2.5 等模型生成候选 Verilog 和奖励模型训练数据；Qwen2.5-Coder-7B-Instruct 或 DeepSeek-Coder-6.7B 作为 RL 策略模型。编译器/仿真器不只作为离线评测工具，也通过 testbench pass rate 给奖励模型提供功能反馈。论文中未明确说明具体 Verilog 编译器和仿真器名称。

## 4. 实验框架与训练流程

### 4.1 第一阶段：冷启动 SFT

默认基础模型为 Qwen2.5-Coder-7B。作者从 GPT-4o-mini 生成若干千条高质量 Chain-of-Thought（CoT，逐步推理）样本，并人工核验清晰性和正确性。每条样本使用 `<REASON>...</REASON><SOLUTION>...</SOLUTION>` 格式，目标是让模型先学会围绕 Verilog 规格进行推理并输出代码（第 3.A 节）。

### 4.2 第二阶段：带 SbW 的 Reinforce++ 与奖励模型

在第一阶段模型上执行 Reinforce++ RL。奖励不是简单使用测试平台通过率，而是由第五节训练的奖励模型给出。SbW 根据策略生成概率和奖励把样本划分为 High-quality、Overfitting、High-capacity、Noisy、Normal 五类，再调整策略损失中的学习权重和 KL 约束权重。

之后以 pass rate 大于 0.8 为条件进行 rejection sampling，得到约 39K 条高质量 CoT 样本。论文将这些样本用于下一阶段 SFT。

### 4.3 第三阶段：扩展推理数据上的 SFT

使用第二阶段产生的约 39K 高质量推理样本继续 SFT，形成 Checkpoint #2。该阶段的作用是巩固模型的推理基础，并为下一次 RL 提供更稳定的初始化。

### 4.4 第四阶段：最终 RL

从 Checkpoint #2 出发，再次使用带 SbW 的 Reinforce++。最终模型称为 VeriRL。论文强调它继承 DeepSeek-R1 的四阶段思路，但针对 Verilog 改造了奖励模型构造和策略更新方式。

### 4.5 奖励模型训练与推理配置

奖励模型使用 Qwen2.5-Coder-7B-Instruct 作为基础模型并进行全参数微调；训练使用 LlamaFactory、DeepSpeed Stage 3、bf16、1 个 epoch、学习率 `1×10^-5`、warmup ratio 0.1、batch size 128，约在 8 张 A100 上训练 24 小时。RL 使用 OpenRLHF、rollout batch size 256、每题采样 4 个解、training batch size 128、学习率 `5×10^-7`、1 个 episode，约在 8 张 A100 上训练 6 小时。

推理使用 vLLM、bf16、四设备 tensor parallelism、最大 token 数 4096、top-p 0.95、top-k 50，并报告温度 0.2、0.5、0.8 中的最优结果。

## 5. 奖励函数、损失函数或关键公式

### 5.1 通过率与偏好对选择

对问题 `q` 生成 `n=10` 个候选，每个候选在 5–10 个 testbench 上运行，得到 `r_i ∈ [0,1]` 的 pass rate。候选偏好对的条件为：

```text
positive if r_i > r_j + 0.4 and r_i > 0.8 and r_j > 0
```

其中 `r_i` 是正例通过率，`r_j` 是负例通过率。差距 0.4 用于避免近似同质量样本形成噪声监督；正例门槛 0.8 用于提高正例为功能正确实现的概率。

### 5.2 Bradley–Terry 奖励模型损失

论文对奖励模型 `R_φ` 使用 Bradley–Terry 对比损失。PDF 中公式的排版存在缺失符号，但正文含义是：对于偏好对 `(a_i, a_j)`，让 `R_φ(q,a_i)` 高于 `R_φ(q,a_j)`。其核心形式可读作：

```text
L_pair = -log σ(Rφ(q, ai) - Rφ(q, aj))
L(φ) = preference-pair loss 的平均值
```

`σ` 为 sigmoid，`φ` 为奖励模型参数。论文中未给出额外的稀疏奖励惩罚项；具体奖励来自 testbench pass rate 和 TbR 重评分。

### 5.3 TbR 重评分

reward tree 中低于 0.2 的节点进入最多两轮自反思。父节点触发反思后，论文用其子节点奖励的平均值替换父节点原始分数。这样，部分语法错误但能通过修复得到较好实现的候选不会被原始低分完全抹掉。

### 5.4 SbW-enhanced Reinforce++ 损失

论文给出的策略损失为：

```text
minθ L(q|θ) = β(q,a) KL(pπθ(a|q) || pπold(a|q))
              - α(q,a) min[r(θ)A, clip(r(θ), 1-ε, 1+ε)A]
```

其中：

| 符号 | 含义 |
| --- | --- |
| `πθ`、`πold` | 当前策略和旧策略 |
| `r(θ)` | 当前策略与旧策略的概率比 `pπθ(a|q)/pπold(a|q)` |
| `A` | advantage，表示样本相对平均水平的收益 |
| `ε` | PPO 风格的裁剪范围 |
| `α` | 鼓励从新知识中学习的权重 |
| `β` | KL 约束权重，用于限制策略偏移和遗忘 |

论文进一步定义：

```text
α(q,a) = max{ Pπθ(q,a)/μ[Pπθ(q,a)], Rφ(q,a)/μ[Rφ(q,a)] }
β(q,a) = min{ Pπθ(q,a)/μ[Pπθ(q,a)], Rφ(q,a)/μ[Rφ(q,a)] }
```

`Pπθ` 是策略生成概率，`Rφ` 是奖励模型分数，`μ` 是对应批次均值。直观上，`α` 让高概率或高奖励样本获得更强学习信号，`β` 让需要保守更新的样本获得更强约束。论文称均值归一化可降低极端值影响；但没有给出完整的梯度方差理论或独立的 reward-hacking 检验。

## 6. 实验设置

### 6.1 数据集来源

| 数据集/来源 | 论文中的用途与信息 |
| --- | --- |
| PyraNet | 超过 700K 个分层 Verilog 设计问题的开源语料，作为 Veribench-53K 的来源 |
| Veribench-53K | MinHash 去重、编译过滤、质量/难度筛选、题面重写和 testbench 生成后的训练/奖励数据集 |
| VerilogEval-human | 156 个人工编写问题，主评测集之一 |
| VerilogEval v2 | 基于 VerilogEval-human，并采用 chatbot-style 接口 |
| RTLLM v1.1 | 29 个 RTL 任务，其中算术 11 个、逻辑 18 个 |
| RTLLM v2 | 50 个 RTL 任务，覆盖 Arithmetic、Memory、Control、Miscellaneous |

Veribench-53K 的处理步骤是：MinHash Jaccard 阈值 0.9 去重；移除编译失败或依赖未解析样本；保留 GPT-4o-mini 评分至少 12 且难度为 Intermediate、Advanced 或 Expert 的样本；用 GPT-4o-mini 改写为 VerilogEval-human-style 问题；每个问题生成约 5–10 个覆盖边界、时序和功能的 testbench。论文将 Veribench-53K 称为 53K，但在正文中未给出最终各子集精确划分、去重前后每一步的样本数或独立人工审核比例，因此这些数字当前 PDF 内容不足以确认。

数据泄漏风险：论文说明评测集是独立 benchmark，但没有给出 Veribench-53K 与四个测试 benchmark 的逐题去重清单，也未报告训练/测试题面相似度分析，因此不能据此断言完全没有泄漏。

### 6.2 模型与工具

* 奖励模型基础模型：Qwen2.5-Coder-7B-Instruct。
* RL 策略模型：Qwen2.5-Coder-7B-Instruct、DeepSeek-Coder-6.7B。
* 数据生成/重写/测试平台生成：GPT-4o-mini；候选生成示例为 CodeQwen2.5。
* 训练框架：LlamaFactory、DeepSpeed Stage 3、OpenRLHF。
* 推理框架：vLLM。
* 硬件：训练奖励模型和 RL 时均使用 8×A100；推理使用四设备 tensor parallelism。
* 编译/仿真工具：论文只称通过编译和 testbench 仿真获得 pass rate，具体工具版本和名称论文中未明确说明。

### 6.3 对比方法

主要对比包括 GPT-3.5、GPT-4o、Starcoder、CodeLlama、DeepSeek-Coder、CodeQwen1.5、CodeQwen2.5，以及 Verilog 专用的 ChipNeMo、Thakur et al.、RTLCoder、BetterV、AutoVCoder、OriGen、HaVen、CraftRTL。训练范式对比还包括原始模型、SFT 和 DPO。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
| --- | --- | --- |
| `pass@1` | 每题生成 1 个候选时，至少一个候选通过功能验证的问题比例 | 越大越好 |
| `pass@5` | 每题从 `n=20` 个样本中取 5 个时，至少一个通过功能验证的问题比例 | 越大越好 |
| pass rate | 单个候选在该题多个 testbench 中通过的比例 | 越大越好 |

论文给出的 pass@k 估计为：`E[1 - C(n-c,k)/C(n,k)]`，其中 `n≥k` 为采样数，`c` 为正确输出数；实验按 VerilogEval 设定使用 `n=20`。本文主要关注功能正确性，不把语法正确率作为主要结果，也没有报告真实芯片 PPA 或硬件运行时间。

## 7. 实验结果与结论

### 7.1 主要结果

在 VerilogEval-human 和 RTLLM v1.1 上，VeriRL-CodeQwen2.5（7B）取得：

| 数据集 | pass@1 | pass@5 |
| --- | ---: | ---: |
| VerilogEval-human | 69.3% | 78.1% |
| RTLLM v1.1 | 58.2% | 66.0% |

在更具挑战性的 VerilogEval v2 和 RTLLM v2 上，VeriRL-CodeQwen2.5 取得 67.2%/76.1% 和 63.3%/70.3% 的 pass@1/pass@5。相对 HaVen-CodeQwen1.5，论文报告 VerilogEval v2 pass@5 提升 14.3 个百分点、RTLLM v2 pass@5 提升 8.6 个百分点。

### 7.2 与传统方法和其他 LLM 方法比较

在 VerilogEval-human pass@1 上，VeriRL-CodeQwen2.5 的 69.3% 高于 CraftRTL-DeepSeek-Coder 的 65.4%，在 RTLLM v1.1 pass@1 上为 58.2%，高于 CraftRTL-DeepSeek-Coder 的 53.1%。与 15B 的 CraftRTL-Starcoder2 相比，论文特别报告其 VerilogEval-human pass@5 高 5.7 个百分点（78.1% 对 72.4%）。这些是 benchmark 仿真通过率，不是实际硬件延迟或面积提升。

### 7.3 消融实验

VerilogEval v1 的增量消融如下：

| 变体 | pass@1 | pass@5 |
| --- | ---: | ---: |
| Reinforce++，无 TbR/SbW | 53.2% | 61.5% |
| 加 TbR | 65.3% | 73.3% |
| 加 SbW | 64.7% | 69.2% |
| TbR + SbW（本文） | 69.3% | 78.1% |

TbR 单独将 pass@1 从 53.2% 提高到 65.3%；SbW 单独提高到 64.7%；二者联合达到 69.3%/78.1%。

### 7.4 TbR 的数据扩展结果与案例

不使用 TbR 时，偏好对约 65K，VerilogEval pass@1 为 61.5%、RTLLM v1.1 pass@5 为 51.3%。TbR 第 1、2、3 轮后，偏好对分别扩大到 129K、210K、240K；对应论文报告 VerilogEval pass@1 为 69.8%、72.1%、76.3%，RTLLM v1.1 pass@5 为 58.4%、64.1%、66.0%。

案例中，初始实现可以编译，但复位行为只通过 3/10 个测试；TbR 识别出同步复位误写为异步复位的问题，将 `posedge rst` 从敏感列表中移除并把复位判断放入 `posedge clk`，修正版通过全部测试。该案例说明 TbR 能恢复部分语义正确但实现细节有误的候选，但它仍然是 testbench 有限覆盖下的功能验证，不是形式化证明。

### 7.5 SbW 稳定性与泛化

论文的 reward-probability 图将样本分为五类，训练曲线显示 SbW 具有更低的奖励方差和更稳定的收敛。对 CodeQwen2.5，VeriRL 在 VerilogEval 上为 69.3%/78.1%，在 RTLLM v1.1 上 pass@5 为 66.0%；对 DeepSeek-Coder 则为 66.7%/71.6% 和 62.4%。将方法迁移到 HaVen 后，论文报告 VerilogEval pass@5 为 79.0%、RTLLM pass@5 为 70.7%。这些结果支持方法对不同 backbone 的可迁移性，但论文没有提供多随机种子均值、方差或显著性检验。

## 8. 主要创新点

### 8.1 创新点一：面向 Verilog 的可执行反馈数据集构造

论文把 PyraNet 问题、结构化题面和多样 testbench 组合成 Veribench-53K，使候选代码能通过仿真得到 pass rate。价值不在于单独使用已有语料，而在于为奖励学习补齐了执行反馈。数据规模、生成方式和 benchmark 结果在正文中有所说明，但 testbench 的独立正确性没有单独人工/形式化验证。

### 8.2 创新点二：Trace-back based Rescore

TbR 用低奖励节点的自反思子节点平均奖励回溯更新父节点，并用奖励差距筛选偏好对。相对于直接丢弃低分输出，它保留了可修复候选中的学习信号。消融和多轮扩展实验支持它对 pass@1、偏好对数量的贡献。

### 8.3 创新点三：Sample-balanced Weighting

SbW 将策略概率和奖励联合用于样本分类，并在 Reinforce++ 损失中分别调节学习权重 `α` 与 KL 约束 `β`。这不是简单增加奖励，而是改变不同样本对策略梯度和遗忘约束的相对贡献。消融和训练曲线支持其稳定化作用，但论文没有给出与更多 RL 稳定化方法的系统比较。

### 8.4 创新点四：将 TbR、奖励模型和 SbW 组合为四阶段流程

论文的完整贡献是把冷启动 SFT、奖励模型、TbR、rejection sampling、二次 SFT 和 SbW-enhanced Reinforce++ 组织成面向 HDL 的训练闭环。单独使用 LLM、SFT、RL 或 testbench 都不是本文独立创新；组合方式和针对 Verilog 稀疏反馈的设计才是核心。

## 9. 局限性

### 9.1 论文明确承认或正文直接显示的局限

* 方法依赖可执行 testbench；没有 testbench 的规格难以提供同样的奖励信号。
* 论文主要评估 Verilog RTL 生成的功能通过率，没有报告综合后 PPA、时序闭合或真实硬件运行结果。
* 训练和奖励模型成本较高：奖励模型约 8×A100、24 小时，RL 约 8×A100、6 小时，且还要进行大量候选仿真。
* 论文使用 Reinforce++、SbW 和自建 reward model，但没有给出与 PPO、GRPO 等更多算法在完全相同预算下的全面比较。
* TbR 通过最多两轮反思生成树节点，论文没有给出树搜索计算量、每题平均节点数或仿真总成本。

### 9.2 阅读后的潜在局限

* pass@k 只证明抽样候选在给定 testbench 上通过；不能直接等价为完整语义等价或形式化验证。
* 训练集由 GPT-4o-mini 重写题面和生成 testbench，可能把生成器偏好带入奖励；论文未报告 testbench 的独立审核率和泄漏检测。
* Veribench-53K 的最终组成和训练/验证划分细节不够完整，复现时难以准确重建每个过滤阶段。
* 论文没有明确说明具体 Verilog 编译器、仿真器和版本，工具差异可能影响 pass rate。
* 代码生成任务主要是模块级 Verilog，论文没有证明方法适用于大型多模块 SoC、跨模块时序、模拟混合信号或复杂综合约束。
* 与本仓库关注的 LLVM/MLIR、RISC-V 后端优化相比，本文输出是 Verilog RTL，未研究 LLVM IR、机器码、RISC-V 指令选择或多架构迁移。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把编译/仿真工具的执行反馈纳入训练闭环，并把“失败但可修复”的样本与“完全无信息”的样本区分开。TbR 提供了一个通用的失败样本再利用思路；SbW 则提示在稀疏奖励任务中同时考虑模型置信度与外部验证分数。

### 10.2 不能直接照搬的部分

不能把 Verilog testbench pass rate 直接替换成 LLVM 优化收益，也不能把 pass@5 当成性能提升。LLVM/RISC-V 任务通常还需要语义等价、代码尺寸、指令数、真实硬件周期或 PPA 等约束；仅把输出语言换成 LLVM IR 或 RISC-V 汇编不足以构成同等研究贡献。

### 10.3 与 LLVM、RISC-V 和异构硬件的关系

本文更适合作为“编译器/硬件工具反馈驱动的代码生成”方法参考，而不是 RISC-V 论文。可迁移的是奖励树、反馈再评分和样本加权机制；需要重新研究的是 IR 级语义保持、目标相关指令选择、后端合法性和跨架构性能反馈。若把平台替换为 RISC-V，必须增加目标 ISA 合法性、机器码反汇编/验证、周期模型或真实板卡结果，才能形成新的研究问题。

### 10.4 在 Taxonomy v2 中的建议角色（仅供维护代理复核）

按“模型最终输出是什么”判断，本文模型直接输出 Verilog 代码，较接近 `TRANSLATOR`；但受控二级分类中没有单独的 HDL 代码生成项，正式主类/二级类应由维护代理依据现有词表复核。本 staging 笔记不分配 Paper_ID，也不写入正式 taxonomy。

## 11. 可进一步尝试的研究方向

### 11.1 方向一：RISC-V LLVM IR 的验证反馈重评分

#### 研究问题

能否把 TbR 从 testbench 通过率扩展为 LLVM IR 到 RISC-V 机器码的语义等价、目标合法性和编译器验证反馈？

#### 与原论文的区别

原论文生成 Verilog 并用 testbench 仿真；该方向生成或改写 LLVM IR/后端模式，并要求 Alive2、LLVM verifier、反汇编器或 ISA 模拟器共同给出反馈。

#### 可能的创新点

将“语法失败、验证失败、性能不佳”分层建模，构造能区分可修复 IR 与不可行 IR 的 reward tree。

#### 实验框架

```text
LLVM IR/优化目标
  ↓ LLM 生成候选变换
LLVM verifier + Alive2/等价检查 + RISC-V 编译
  ↓ 合法性、等价性、代码质量反馈
TbR 构造偏好对 → reward model → SbW-enhanced RL
```

#### 可行性

需要 LLVM、目标 RISC-V 后端、等价性工具和可复现实验 benchmark；不必一开始训练大模型，可先对开源代码模型做反馈式微调。

#### 主要风险

形式验证可能成为主要瓶颈；代码尺寸或静态代价模型也可能被模型投机，且语义等价不等于真实硬件性能。

### 11.2 方向二：面向 RISC-V 自定义扩展的多目标奖励

#### 研究问题

如何在保证 LLVM IR/机器码语义正确的同时，联合优化 RISC-V 自定义指令使用率、周期、代码大小和硬件资源约束？

#### 与原论文的区别

原论文的核心指标是 Verilog testbench 功能通过率；该方向面对软硬件协同设计的多目标 Pareto 权衡。

#### 可能的创新点

把合法 ISA、形式等价、周期模型和面积估计组织成分层奖励，并用 TbR 回收“功能正确但硬件代价超限”的候选。

#### 实验框架

```text
程序/LLVM IR + 自定义 RISC-V ISA 描述
  ↓ LLM 选择或生成后端变换
编译、模拟、形式检查、面积/周期估计
  ↓ 多目标反馈
偏好对与样本分类 → RL 优化
```

#### 可行性

可从 Spike/QEMU、LLVM RISC-V backend 和 FPGA/RTL 估计器组成最小闭环，再逐步加入真实板卡。

#### 主要风险

不同硬件估计器的误差会污染奖励；多目标冲突可能导致 SbW 的权重难以解释。

### 11.3 方向三：跨架构反馈迁移

#### 研究问题

能否让同一生成模型在 x86、ARM 和 RISC-V 目标间迁移编译优化知识，同时保持每个目标的合法性和性能约束？

#### 与原论文的区别

原论文只针对 Verilog 生成任务；该方向研究目标架构变化造成的反馈分布变化，不是简单把模型换成 RISC-V。

#### 可能的创新点

使用架构条件化 reward model，并研究 TbR 在不同目标反馈之间共享或隔离的策略。

#### 实验框架

```text
同一源程序/IR + 目标架构标签
  ↓ 生成目标相关候选
多架构编译器、验证器、模拟器和硬件测量
  ↓ 目标条件化 reward
跨架构偏好学习与 RL → 各架构候选
```

#### 可行性

可先使用 LLVM 多目标后端和标准 benchmark，再对 RISC-V 板卡做少量真实测量校准。

#### 主要风险

不同架构的性能指标未必可直接比较；训练数据和硬件预算会显著增加，且跨架构迁移容易造成目标特化能力下降。

## 12. 与其他已读文献的关系

本 slot-5 本轮只完成这一篇论文的 PDF 通读，因此没有另一篇“当前批次已读文献”可进行事实级横向比较。

就研究位置而言，VeriRL 更接近“生成模型 + 编译/仿真反馈 + 强化学习”的方法参考；它不是 LLVM pass 选择器、RISC-V 指令选择器、MLIR lowering pass 或形式化验证器。后续若与 CIDRE 等已经存在于正式 corpus 的 RISC-V 硬件/软件协同论文比较，应重点区分：VeriRL 生成 HDL 代码并优化功能通过率；CIDRE 类工作自动探索自定义指令并评估硬件/软件代价。两者可以在“硬件反馈闭环”层面组合，但不能把其中一个的实验结果当成另一个的证据。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 用强化学习提高 LLM 的 Verilog/RTL 功能正确生成能力 |
| 核心问题 | 仿真奖励稀疏噪声大，以及 RL 训练中的方差和灾难性遗忘 |
| 输入 | 自然语言 Verilog 规格、候选代码和 testbench 反馈 |
| 输出 | 可通过给定功能仿真的 Verilog 代码 |
| 核心方法 | Veribench-53K、TbR、奖励模型、SbW-enhanced Reinforce++、四阶段训练 |
| 使用的模型 | Qwen2.5-Coder-7B-Instruct、DeepSeek-Coder-6.7B、GPT-4o-mini、CodeQwen2.5 |
| 使用的编译器工具 | 编译和 testbench 仿真；具体工具与版本论文中未明确说明 |
| 是否使用强化学习 | 是；Reinforce++，结合 SbW |
| 是否使用形式化验证 | 否；使用 testbench 仿真功能反馈，不是形式化证明 |
| 数据集规模 | Veribench-53K；源自 PyraNet 700K+ 问题；偏好对约 240K（正文另报告 TbR 三轮达到 240K） |
| 主要指标 | pass@1、pass@5，`n=20` 采样，基于功能验证通过 |
| 最重要实验结果 | VeriRL-CodeQwen2.5 在 VerilogEval-human 为 69.3%/78.1%，RTLLM v1.1 为 58.2%/66.0% |
| 核心创新 | TbR 回收可修复失败样本；SbW 按奖励与生成概率调节学习/约束权重 |
| 主要局限 | 依赖 testbench，缺少真实硬件 PPA/时延和形式化等价证据，工具版本信息不完整 |
| 与 RISC-V 研究的相关性 | 中低；可迁移反馈式训练思想，但论文不研究 RISC-V/LLVM 后端 |
| 最适合作为 | 反馈驱动代码生成、奖励建模和 RL 训练方法参考 |

这篇论文最值得学习的是：把执行反馈转成可学习的奖励信号，并通过 TbR 保留可修复失败样本、通过 SbW 控制稀疏奖励下的策略更新。最主要的局限是：仿真通过率仍受 testbench 覆盖限制，不能等价为形式化正确性或真实硬件性能。如果用于后续 LLVM/RISC-V 研究，合理用法是借鉴“反馈再评分 + 样本加权”的训练框架，并重新设计语义等价、ISA 合法性和硬件性能反馈，而不是只把 Verilog 换成 RISC-V 汇编。
