# REASONING COMPILER 文献阅读总结

论文题目：**REASONING COMPILER: LLM-Guided Optimizations for Efficient Model Serving**

作者：Annabelle Sujun Tang、Christopher Priebe、Rohan Mahapatra、Lianhui Qin、Hadi Esmaeilzadeh

发表时间：2025

发表平台：NeurIPS 2025（第 39 届 NeurIPS）

论文链接或编号：[NeurIPS 正式 PDF](https://papers.nips.cc/paper_files/paper/2025/file/99e49b207cb4f5c3b4c3b7da0261e8af-Paper-Conference.pdf)；[代码仓库](https://github.com/he-actlab/REASONING_COMPILER)

关键词：LLM-guided compiler optimization、Monte Carlo Tree Search、TVM、tensor-program scheduling、sample efficiency、model serving

> 本文档只记录当前正文 PDF 可确认的事实；第 10—11 节为阅读后的分析，第 12 节仅说明本 staging 批次的文献关系。

---

## 1. 研究背景

论文研究神经网络模型服务中的编译优化，具体关注 Llama、DeepSeek-R1、FLUX 等模型层或端到端模型在不同 CPU 平台上的 tensor-program 调度。模型服务的推理成本受运行时间和硬件资源限制，编译器优化可降低部署成本。

论文指出，神经工作负载的合法变换空间很大且高度相互依赖，涉及 tiling、fusion、layout change、vectorization 等选择。一个决定会影响后续决定的可行性和收益。传统规则依赖手工启发式，可能针对某个工作负载或硬件过拟合；TVM 等神经编译器通常使用 evolutionary search 等黑盒搜索，能够找到高质量配置，但样本效率低，且没有显式利用变换历史中的结构关系。

论文引入未经再训练的 LLM，目标不是让 LLM 直接生成任意源代码，而是让它作为候选变换提议器，在 MCTS 中结合当前程序状态、祖先变换轨迹和性能反馈，改善编译搜索的样本效率。

## 2. 论文要解决的问题

### 2.1 组合变换空间中的搜索效率

给定程序 `p0`、可用变换集合 `O` 和最大序列长度 `T`，论文要寻找一个变换序列，使目标平台上的性能目标最大。问题难点是变换的组合效应和非局部依赖会使穷举、随机或局部策略浪费大量评估样本。

### 2.2 如何利用上下文而不训练编译策略模型

论文研究：不进行额外训练或任务特定微调时，LLM 能否利用当前程序、父节点/祖父节点的变换轨迹和成本反馈，提出更有希望的后续变换，并与结构化搜索配合。

### 2.3 一句话总结

> 本文主要研究：如何把 LLM 的上下文推理作为候选提议机制嵌入 MCTS，以较少的程序评估样本搜索神经模型 tensor program 的高性能变换序列。

## 3. 核心方法概述

REASONING COMPILER 将编译优化建模为有限时域 MDP：状态是当前程序变体，动作是对其应用一个合法编译变换，奖励是目标平台上的性能目标值。MCTS 用 UCT 选择节点并管理探索/利用，LLM 根据当前节点、父节点和更深的历史轨迹生成一个或多个变换建议；TVM 的 cost model 评估候选，再把结果用于树更新。

```text
初始 TVM tensor program
        ↓
MCTS 按 UCT 选择待扩展叶节点
        ↓
构造当前节点、父/祖父节点、变换轨迹和预测分数
        ↓
LLM 通过提示生成候选变换序列
        ↓
合法性检查；必要时回退到非 LLM 扩展
        ↓
TVM cost model 评估候选，并加入 MCTS 树
        ↓
执行/测量候选，回传性能分数并更新树
        ↓
输出高性能 schedule / transformed tensor program
```

LLM 的角色是 SELECTOR：它从提供的变换集合中提出下一步或一段变换序列；它不直接输出任意用户源代码。论文示例中的可用变换包括 `TileSize`、`Parallel`、`ComputeLocation` 和 `Unroll`。MCTS 负责结构化的选择、扩展、模拟和回传；TVM 负责调度执行和成本评估。

## 4. 实验框架与训练流程

### 4.1 模型与推理阶段

本文不涉及模型训练，主要采用提示式推理。主实验使用 OpenAI GPT-4o mini 生成变换建议；消融还测试 OpenAI o1-mini、Llama3.3-Instruct 70B、DeepSeek-Distill-Qwen 32B、Llama3.1-Instruct 8B 和 DeepSeek-Distill-Qwen 7B。论文通过 OpenAI 和 Hugging Face API 访问模型。

### 4.2 MCTS 搜索

论文使用 UCT，主实验探索参数 `c = √2`，分支因子 `B = 2`。提示包含当前节点和祖先节点的代码、变换轨迹及预测分数；历史深度消融比较“父节点 + 祖父节点”和再增加“曾祖父节点”。LLM 输出变换序列后，系统检查名称和使用上下文等基本合法性。

### 4.3 反馈与回退

有效候选进入 cost model 和 MCTS 树。若一次扩展中所有 LLM 候选均无效，系统回退到默认的非 LLM 扩展策略。正文说明：商业模型 GPT-4o mini 和 o1-mini 的 fallback rate 为 0%；Llama3.3-Instruct 70B 为 0.08%，DeepSeek-Distill 32B 为 0.17%，Llama3.1-Instruct 8B 为 10.50%，DeepSeek-Distill 7B 为 17.20%。这些是候选扩展回退率，不是语义等价证明率。

## 5. 奖励函数、损失函数或关键公式

### 5.1 优化目标

论文将程序变换序列写成：

```text
Sopt = argmax over S'⊆O*, |S'|≤T of f((o'k ∘ ... ∘ o'1)(p0))
```

其中 `p0` 是初始程序，`O` 是变换集合，`T` 是最大序列长度，`f` 是目标平台上的性能目标函数，例如 latency、power 或 utilization。状态是当前程序，动作是应用一个变换；确定性转移把当前程序变成变换后的程序。

### 5.2 MDP 奖励

正文定义：`R(st, at) = s · f(at(pt))`，其中 `s ∈ {+1, -1}` 用于把不同优化目标统一为“奖励越大越好”。论文没有提出 PPO、GRPO 或其他策略梯度训练，也没有单独的 LLM 损失函数。这里的 MCTS reward 是性能目标值，不应表述为训练奖励。

### 5.3 正确性边界

论文把动作限制在已知的有限合法变换集合中，主要错误来源被描述为命名或使用上下文不合规。正文没有给出独立的形式化等价验证器或形式化证明；cost model 的性能估计和后续执行反馈也不等于语义等价证明。

## 6. 实验设置

### 6.1 数据集来源

论文没有使用传统训练/验证/测试数据集。实验 workload 是来自生产模型的五类代表性计算层：Llama-3-8B self-attention、DeepSeek-R1 MoE layer、FLUX self-attention、FLUX convolution、Llama-4-Scout MLP；另有 Llama-3-8B 端到端评估。论文没有报告一个用于训练 LLM 的数据集划分，因为 LLM 未在本文中训练。

### 6.2 模型与工具

| 项目 | 论文明确内容 |
| --- | --- |
| 编译器 | Apache TVM v0.20.0 |
| 搜索基线 | TVM MetaSchedule 的 Evolutionary Search；无 LLM 的 MCTS |
| 主 LLM | OpenAI GPT-4o mini |
| 消融 LLM | OpenAI o1-mini、Llama3.3-Instruct 70B、DeepSeek-Distill-Qwen 32B、Llama3.1-Instruct 8B、DeepSeek-Distill-Qwen 7B |
| 主要平台 | Amazon Graviton2、AMD EPYC 7R13、Apple M2 Pro、Intel Core i9、Intel Xeon E3 |
| 主环境 | Intel Core i9 工作站，固定软硬件栈；论文未在正文给出该工作站的全部硬件配置细节 |
| 重复次数 | 每项实验重复 20 次并报告均值 |

### 6.3 对比方法

- TVM MetaSchedule / Evolutionary Search：代表现有神经编译器的进化搜索。
- MCTS：相同 MCTS 框架但不使用 LLM 提议，用于隔离 LLM 引导作用。
- REASONING COMPILER：LLM-guided MCTS。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Speedup | 未优化代码执行时间 ÷ 优化代码执行时间 | 越大越好 |
| Samples | 已评估的变换提议/调度数量 | 越少达到目标越好 |
| Sample efficiency | `Speedup / # samples` | 越大越好 |
| Fallback rate | 一次扩展中所有 LLM 提议无效、触发非 LLM 路径的比例 | 越低越好 |
| API cost | 完整实验调用 LLM API 的美元成本 | 越低越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 5 个 workload、5 个硬件平台的 25 个平台—算子组合上，REASONING COMPILER 的几何平均结果为：达到 5.0× speedup，使用的 samples 比 TVM 少 5.8×，sample efficiency 提升 10.8×。这是跨平台—算子均值/几何平均口径，不是每个 workload 都达到相同数值。

端到端 Llama-3-8B 上，REASONING COMPILER 达到 4.0× speedup，使用 3.9×更少的 samples，sample efficiency 的几何平均提升为 5.6×。各平台的端到端 speedup 为 2.2×（AMD EPYC 7R13）到 5.1×（Amazon Graviton2）。

### 7.2 与传统方法的比较

在 Llama-3-8B attention layer 上，REASONING COMPILER 用 36 个 samples 达到 7.08× speedup；TVM 达到类似收益需要约 72 个 samples。FLUX attention layer 上，REASONING COMPILER 用 36 个 samples 达到 2× speedup，而 TVM 需要超过 600 个 samples。Llama-4-Scout MLP layer 上，REASONING COMPILER 在 20 个 samples 达到 12.7× speedup，而 TVM 即使 3000 个 samples 也未达到该数值。

表 1 的具体示例：在 Intel Core i9 的 Llama-4-Scout MLP layer 上，TVM 使用 230 个 samples 达到 5.6×，REASONING COMPILER 使用 20 个 samples 达到 12.7×，样本减少 11.5×、sample efficiency 提升 26.1×。这是特定平台和算子的结果，不能推广为所有硬件或程序的固定收益。

### 7.3 与其他 LLM 方法的比较

论文没有把其他 LLM 编译优化系统作为主要数值 baseline；主要比较的是不同 LLM 作为同一 proposal engine 时的效果。Llama3.3-Instruct 70B 在 Llama-3-8B attention layer 上 36 个 samples 达到 9.68×，GPT-4o mini 同条件为 7.08×；但不同模型的 API 成本、可用样本数和 benchmark 条件也不同。

### 7.4 消融实验

- LLM 选择：较大、instruction-tuned 模型通常收敛更快；开源模型在适当规模和指令调优下可与商业模型竞争。
- 历史深度：Llama-3-8B attention layer 上，72 个 samples 时“父+祖父+曾祖父”达到 11.36×，而“父+祖父”为 8.38×；600 个 samples 时分别为 11.87×和 11.33×。
- 分支因子：主设置 `B=2` 通常比 `B=4` 更具样本效率；更大的分支因子扩大每次搜索覆盖需求。
- API 成本：GPT-4o mini 的单个 layer 完整实验成本约 0.88–1.12 美元；o1-mini 约 6.47–8.25 美元；具体取决于 workload。成本结果来自正文表 7。

### 7.5 案例分析

附录给出一个 DeepSeek-R1 MoE 层的提示和 LLM 输出示例。LLM 根据当前/父节点的 tile 决策、预测分数和可用变换，提出 TileSize、ComputeLocation、Parallel、Unroll 等序列。该示例展示了上下文提议形式，不是一个单独的统计实验。

## 8. 主要创新点

### 8.1 创新点一：把 LLM 作为 MCTS 的上下文感知 proposal engine

已有随机或进化搜索主要依赖搜索策略和成本模型。本文让 LLM 查看变换历史、程序结构和性能趋势，提出后续变换序列，再由 MCTS 管理探索与利用。论文的消融结果支持历史上下文有助于样本效率。

### 8.2 创新点二：LLM 推理与结构化树搜索的组合

LLM 本身不负责最终搜索保证，MCTS 也不再完全盲目地从所有动作中随机扩展。二者的分工是“LLM 提议候选，MCTS 评估和回传”。这比仅报告“用 LLM 生成提示”更具体，也是论文对 S3 Search/RL/Policy 的主要归类依据。

### 8.3 创新点三：不进行编译任务特定再训练

系统用提示式 API 调用直接生成候选，在不训练编译策略模型的条件下获得样本效率收益。该设计降低了训练成本，但也把性能和成本依赖转移到所选 LLM、提示上下文和 API 上。

## 9. 局限性

### 9.1 论文明确或正文可确认的限制

- 评估集中在 TVM tensor-program scheduling、神经网络层和 Llama-3-8B 端到端模型，不能直接代表传统 C/C++、LLVM IR 或 RISC-V 后端。
- LLM API 调用有实际费用；正文表 7 显示不同模型成本差距明显。
- 小模型 fallback rate 更高，说明候选合法性和稳定性依赖模型能力。
- 论文没有给出独立形式化语义等价验证结果；合法动作集合和成本模型约束了候选，但不等于完整形式化验证。
- 论文使用固定的 `B=2`、`c=√2` 等搜索设置；更广泛的搜索超参数迁移仍需额外验证。

### 9.2 阅读后的潜在限制

- 速度收益依赖 TVM cost model、目标平台和可表达的变换集合；若变换集合不含目标后端关键动作，LLM 只能在受限空间内选择。
- 论文的主要数字以样本数为搜索成本，未把所有 API 延迟、编译时间和硬件执行时间统一成端到端调优墙钟成本。
- LLM 输出的 chain-of-thought 被用于提议，但论文没有证明文本推理本身是必要因素；可能存在结构化提示、候选格式或模型先验的混合作用。
- 论文没有在 RISC-V、LLVM pass pipeline 或跨 ISA 场景上做实验，因此迁移到这些方向需要重新定义状态、动作和反馈。

## 10. 阅读后的研究方向反思

值得借鉴的是“受约束动作空间 + 编译器反馈 + 历史上下文 + 结构化搜索”的组合，而不是单纯把 GPT 接到编译器前面。对 RISC-V 研究而言，最有价值的迁移点是让 LLM 选择已验证的 RVV schedule、LLVM pass 片段或后端配置，并让 QEMU、Spike、真实 RVV 硬件和性能计数器提供反馈。

但仅把硬件平台替换成 RISC-V 不足以形成新贡献。新的研究问题可以是：如何在 VLEN/LMUL、缓存、分支代价和不同微架构之间建模可迁移的上下文；如何把编译正确性检查与性能搜索同时纳入；如何在有限硬件测量预算下校准 cost model。REASONING COMPILER 更适合作为 SELECTOR baseline 或搜索策略参考，不宜直接当作 RISC-V 完整优化框架。

## 11. 可进一步尝试的研究方向

### 11.1 RVV 感知的 LLM-MCTS schedule 选择

#### 研究问题

LLM 是否能利用 RVV 的 VLEN、SEW、LMUL、访存模式和真实硬件反馈，在有限测量预算内选择更好的 LLVM/MLIR/RVV schedule？

#### 与原论文的区别

从 TVM/CPU 神经 tensor scheduling 扩展到 RISC-V Vector 后端，并显式处理跨 VLEN 和微架构迁移。

#### 可能的创新点

硬件特征条件化提示、跨设备历史轨迹复用、正确性门控和成本模型校准。

#### 实验框架

```text
RVV IR/schedule → LLM 提议 pass/schedule → LLVM/RVV 编译 → QEMU/真实板卡执行
→ 性能与正确性反馈 → MCTS 更新
```

#### 可行性

需要 LLVM RISC-V 工具链、RVV 模拟器或硬件、性能计数器和有限的 benchmark 集合。

#### 主要风险

真实硬件测量噪声、不同 VLEN 的动作可迁移性，以及语义等价和 ABI 约束。

### 11.2 正确性—性能双信号的 Selector

#### 研究问题

如何在每个候选 pass 或 schedule 进入 MCTS 前，用 Alive2、差分执行或 RVV 专用验证器阻止错误变换，同时保留性能探索？

#### 与原论文的区别

原论文主要依赖合法变换集合和 cost model；该方向把机器可检查的语义门控作为一等反馈。

#### 可能的创新点

将验证失败分类、修复/回退策略和性能收益联合到搜索策略中。

#### 实验框架

```text
候选 schedule → 语义验证/差分测试 → 通过才测性能 → 双信号回传 MCTS
```

#### 可行性

可从 LLVM IR 小程序和 RVV intrinsic 测试开始，不需要训练新 LLM。

#### 主要风险

验证器覆盖不足、验证成本过高，以及把测试通过误解为形式化证明。

### 11.3 面向调优墙钟成本的工具调用策略

#### 研究问题

在 LLM API 成本、编译时间和硬件执行时间共同受限时，如何选择何时调用 LLM、何时使用默认 MCTS 或已有 cost model？

#### 与原论文的区别

原论文报告 API 费用但没有将其作为搜索决策目标；该方向把调用预算显式纳入 Selector policy。

#### 可能的创新点

基于不确定性的 LLM 调用门控、缓存相似程序的历史轨迹、成本—收益多目标搜索。

#### 实验框架

```text
当前搜索状态 → 估计继续调用 LLM 的信息价值 → LLM/MCTS/default 三路选择
→ 编译与执行 → 墙钟成本和性能回传
```

#### 可行性

可复用 TVM 或 LLVM 调优框架及本文公开代码思路。

#### 主要风险

API 延迟和硬件噪声会使预算比较不稳定，且信息价值估计可能偏向短期收益。

## 12. 与其他已读文献的关系

本 staging 子批次只完成 REASONING COMPILER 一篇论文的正文阅读，因此不存在可以依据本批次正文建立的横向事实比较。按仓库现有总账的去重检查，Compiler-R1、DeCOS、ECCO、AutoPass、HintPilot、Agentic Auto-Scheduling 等 S3/S4 条目已经存在；REASONING COMPILER 的规范化标题和 NeurIPS 正式 PDF 文件未在现有 `taxonomy_v2.csv` 或本地正式 PDF/笔记目录中发现。

在研究任务上，REASONING COMPILER 应与上述已有 Selector 工作进行后续人工横向审计：它的区分点是 LLM-guided MCTS 和 tensor-program schedule 搜索；本文没有将这些已有论文的实验内容写入本笔记。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 神经模型服务中的编译变换序列搜索 |
| 核心问题 | 组合且有依赖的优化空间样本效率低 |
| 输入 | TVM tensor program、当前 schedule、历史变换和性能分数 |
| 输出 | 高性能变换序列 / schedule |
| 核心方法 | LLM proposal engine + MCTS/UCT + TVM cost model |
| 使用的模型 | GPT-4o mini 主实验；多种开源/商业模型消融 |
| 使用的编译器工具 | Apache TVM v0.20.0 |
| 是否使用强化学习 | 否；使用 MCTS 搜索，不训练策略模型 |
| 是否使用形式化验证 | 否；正文未报告独立形式化等价验证 |
| 数据集规模 | 无传统训练数据集；5 类层级 workload + 端到端 Llama-3-8B |
| 主要指标 | Speedup、samples、sample efficiency、fallback rate、API cost |
| 最重要实验结果 | 25 个平台—算子组合几何平均 5.0× speedup、5.8×更少 samples、10.8× sample-efficiency gain；端到端几何平均 4.0× speedup、5.6× gain |
| 核心创新 | 用历史上下文感知的 LLM 提议增强 MCTS 搜索 |
| 主要局限 | TVM/神经 workload 范围有限；无独立形式化验证；API 和硬件成本依赖明显 |
| 与 RISC-V 研究的相关性 | 中：Selector/搜索框架可迁移，但正文未评估 RISC-V/RVV |
| 最适合作为 | S3 Selector baseline、搜索策略参考、后续 RISC-V 适配的起点 |

这篇论文最值得学习的是把 LLM 的上下文提议限制在编译器可表达的动作空间内，再由 MCTS 和性能反馈负责搜索；最主要的局限是实验集中于 TVM 神经 workload，且没有独立形式化验证。用于后续研究时，合理做法是把它作为受约束搜索 baseline，并补充 RISC-V/RVV、正确性门控和真实调优成本评估，而不是只替换目标硬件名称。

