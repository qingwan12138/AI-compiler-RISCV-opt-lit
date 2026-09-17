# TLM 文献阅读总结

论文题目：**Enabling Tensor Language Model to Assist in Generating High-Performance Tensor Programs for Deep Learning**

队列简称：TLM: A Tensor Language Model for Optimizing Tensor Programs（用户队列别名；非 PDF 标题）

作者：Yi Zhai、Sijia Yang、Keyu Pan、Renwei Zhang、Shuo Liu、Chao Liu、Zichun Ye、Jianmin Ji、Jie Zhao、Yu Zhang、Yanyong Zhang

发表时间：2024

发表平台：18th USENIX Symposium on Operating Systems Design and Implementation (OSDI 2024)，pp. 289–305

论文链接或编号：[USENIX 官方论文页](https://www.usenix.org/conference/osdi24/presentation/zhai)；[官方 PDF](https://www.usenix.org/system/files/osdi24-zhai.pdf)；DOI：论文 PDF 中未给出独立 DOI；arXiv：未发现匹配记录

关键词：tensor compiler、tensor program、schedule、autotuning、language model、GPT-2、TVM、Ansor、MetaSchedule、GPU

> 本文档只记录本轮从官方 PDF 正文核验到的事实，并把阅读后的分析与建议单独标出。PDF 已保存到本 staging 目录；未同步正式 taxonomy、索引、年份清单或候选缓存。

## 1. 研究背景

本文研究深度学习张量编译器中的 tensor program exploration。高层工作负载经过 graph processor 划分为 subgraphs 后，tensor compiler 需要把每个 subgraph 映射成面向硬件的低层 tensor program；最终由 code generator 生成 executable（第 1 节、图 1）。

传统 tensor compiler 在 exploration space 中作多项决策，包括循环轴的 tiling size、unroll step、算子计算位置、parallelization、vectorization，以及 GPU 上的 thread binding（第 1 节、第 4.1 节）。这些选项的组合构成巨大的决策空间：论文估计单个 subgraph 在 CPU 上约为 10^6 规模，在 GPU 上约为 10^9 规模（第 4.1 节）。

论文对比的传统路线有两类：

1. 启发式约束路线，例如模板、polyhedral model 或硬件形状约束，能缩小搜索空间和编译成本，但可能提前删掉高性能方案。
2. 大搜索空间路线，例如 Ansor 和 MetaSchedule，保留更多可能性，但依靠随机采样和代价模型，需要大量编译/测量，编译时间很长。论文报告 BERT-base 在 NVIDIA V100 上使用 Ansor 收敛需要 21.6 小时、在 Intel i7-10510U CPU 上需要 13.1 小时（第 2.1 节）。

本文引入语言模型的动机不是直接生成长篇 tensor program 源码。论文指出这类源代码可能超过一万 token，且必须满足严格语法；因此把语言模型限制在一个更短的 tensor language sentence 上，让模型帮助预测编译器决策，而由 tensor compiler 构造完整 program（第 1 节、第 4.2 节）。

## 2. 论文要解决的问题

### 2.1 保留大探索空间

如果用过强启发式约束缩小空间，可能丢失高性能 tensor program。论文希望保留较大的 exploration space，使高性能方案仍然存在（第 3 节、第 4.1 节）。

### 2.2 改善大空间中的探索效率

Ansor/MetaSchedule 的随机采样对每个决策的初始概率近似均匀，很多采样结果质量低；代价模型要等到采样并测量之后才提供反馈。论文希望使用离线数据中的结构知识和当前已生成决策，提高当前决策空间中高质量选择的概率（第 2.1 节、第 5.2 节）。

### 2.3 在性能与编译开销之间取得平衡

论文将目标表述为：在保持接近搜索型方法的执行性能的同时，减少达到高质量 tensor program 所需的测量次数和编译时间（第 1 节、第 6 节）。

> 本文主要研究：如何把 tensor program exploration 表述为受编译器约束的语言模型决策过程，并用离线学习和当前决策上下文辅助选择高性能 schedule。

## 3. 核心方法概述

论文提出 TLM framework，由两个解耦组件组成：space builder 和 generator（第 3 节、图 1、图 4）。space builder 负责保留并构造探索空间；generator 使用 TLM 在该空间中逐步预测决策。

```text
深度学习 workload
        ↓
Graph processor：图优化、算子融合/划分
        ↓
输入 subgraph + 硬件信息
        ↓
Space builder：建立决策空间与探索空间
        ↓
Tensor language：记录 subgraph、硬件、决策信息
        ↓
TLM：按上下文逐 token 预测 schedule 决策
        ↓
合法性检查；非法决策丢弃并重新采样
        ↓
Tensor compiler：应用 tile/unroll/parallel/vectorize 等决策
        ↓
Tensor program → code generator → executable
        ↓
真实编译/执行测量，用于离线 demonstration data 的迭代更新
```

### 3.1 输入

输入包括 workload 经 graph processor 得到的 subgraph、算子类型和形状信息，以及硬件规格，例如处理器核心数和支持的向量指令（第 4.1、4.2 节）。

### 3.2 Tensor language

一个 tensor sentence 记录输入 subgraph、硬件规格和决策信息，并与一个 tensor program 唯一对应。论文将 sentence 长度限制在不超过 1024 token，以避免直接生成一万 token 以上的 tensor program 源代码（第 1、4.2 节）。它被定义为记录 tensor program 的自然语言式表示，不是独立的通用编程语言（第 4.2 节）。

### 3.3 TLM 的最终系统角色

根据第 5.2 节 Algorithm 2，TLM 接收当前 tokens，预测如 `i.0=32`、`i.1=1` 等下一决策 token；`ConvertTokensToTiles` 将结果转成 tile 决策，随后 `program.apply(...)` 由编译器把决策应用到 tensor program。TLM 不直接输出完整源代码，也不负责最终 code generation。

因此，本论文在本仓库 taxonomy 中的最终角色确认为：

- `Primary_Category = SELECTOR`
- `Secondary_Category = S2_Schedule_Config_Autotuning`
- 角色说明：语言模型选择/采样编译器定义的 schedule/config 决策；编译器负责将这些决策物化为 tensor program 并生成可执行文件。

这不是 `TRANSLATOR`：输入不是要求模型改写源代码或 IR，输出也不是修复后的源码/IR。它也不是独立的 `GENERATOR`：虽然论文把整个框架称为 generation framework，但最终低层 program 由 tensor compiler 根据 TLM 决策构造，TLM 的局部职责是选择决策。

## 4. 实验框架与训练流程

论文不是直接调用通用 ChatGPT API，而是训练一个约 100M 参数的 GPT-2 Small 风格 causal language model（第 5.1 节）。

### 4.1 第一阶段：构造探索空间

space builder 依据输入 subgraph、硬件和已有框架的决策空间，确定 tile size、unroll、计算位置、并行化、向量化、thread binding 等决策。论文复用 Ansor、MetaSchedule、AKG、AKG-MLIR 的决策空间，没有把扩大探索空间本身作为本论文的主要技术贡献（第 3、4.1 节）。

### 4.2 第二阶段：无标签大规模采样与预训练

论文从 PyTorch Vision Model Zoo 和 HuggingFace Transformer Model Zoo 取得工作负载，调整输入形状，形成 138 个 workloads；其中 12 个 workload 留作测试，剩余 workload 约产生 3K subgraphs（第 4.3 节）。

对约 3K subgraphs 进行大规模随机采样，得到 2 million 条 tensor sentences。该阶段不测量 execution latency，因此这些数据是无标签结构数据，主要让 TLM-base 学习 tensor language 的结构、词汇和有效决策形式（第 4.3 节）。

TLM-base 使用 GPT-2 Small 架构进行 causal language modeling 预训练：约 100M 参数、12 个 Transformer layers、每层 12 个 attention heads、768 个 hidden units。预训练 2 epochs，使用 4 张 NVIDIA V100，论文报告约需 10 小时（第 5.1 节）。

### 4.3 第三阶段：以 measured latency 为依据的 SFT

在 TLM-base 之后，论文选择每个 subgraph 中 execution latency 较低的 tensor sentences 作为 demonstration data，约 3K 条，每个 subgraph 选择一条最优记录用于 SFT。SFT 的目的，是让模型在给定 prompt 下更倾向生成高性能决策，而不只是生成形式有效的 sentence（第 5.1 节）。

每轮 SFT 约需 10 分钟，使用 4 张 NVIDIA V100。论文明确把 measured latency 视作 demonstration 选择依据，而不是训练一个单独 reward model（第 5.1 节）。

### 4.4 第四阶段：迭代优化 demonstration data

论文将每个 subgraph 对应的 prompt 分成若干 batch，循环进行：

```text
当前 TLM 生成多个候选 sentence
        ↓
Tensor compiler 转换/编译候选
        ↓
并行测量 execution latency
        ↓
每个 subgraph 保留当前已测记录中的最低 latency sentence
        ↓
用新的 demonstration data 从 TLM-base 重新 SFT
        ↓
得到下一轮 TLM，继续生成候选
```

论文特别说明每轮 TLM 都从 TLM-base 重新训练，而不是从上一轮 TLM 连续累积，以避免梯度训练导致的累计误差影响后续轮次（第 5.3 节）。

### 4.5 推理阶段

推理时 TLM 按 Algorithm 2 在每个 decision space 中生成部分决策，例如一个 tile split 的多个 tile size；生成后检查是否属于合法决策空间。若非法，则丢弃该 tensor program 并重新生成。论文报告生成一个合法 tensor program 平均不超过 1.1 次调用（第 5.2 节）。

### 4.6 训练范式判定

- 使用 causal language model 预训练。
- 使用监督微调（SFT）。
- 使用真实 execution latency 选择 demonstration data。
- 不使用 PPO、GRPO 或其他强化学习算法。论文明确说没有采用 RL，原因是 RL 超参数和收敛较难控制，而多轮 SFT 已足够（第 5.1 节）。
- 不使用形式化验证器；正文描述的是决策空间合法性检查和真实编译/执行测量。

## 5. 奖励函数、损失函数或关键公式

### 5.1 语言模型训练目标

论文将 TLM 视为 causal language model，让模型根据 prompt 预测下一个 token。正文没有给出独立的数值损失函数展开式；训练过程遵循语言模型的 next-token prediction 和梯度下降描述（第 2.2、5.1 节）。

论文中未明确说明具体 token-level loss 的完整公式、优化器超参数或学习率。

### 5.2 探索空间大小

论文在第 4.1 节将 tensor layer exploration space 表示为：

```text
S = { s(n) | s(i) = apply(s(i-1), di), di ∈ Di, 1 ≤ i ≤ n }
|S| = |D1| × |D2| × ... × |Dn|
```

其中：

| 符号 | 含义 |
|---|---|
| `S` | 输入 subgraph 对应的全部可能 tensor programs 的探索空间 |
| `s(0)` | 输入 subgraph 的初始 program |
| `di` | 第 `i` 个决策空间 `Di` 中采样到的决策 |
| `apply` | 将决策应用到当前 program |
| `Di` | 第 `i` 个决策空间 |

### 5.3 演示数据目标

第 5.3 节给出所有 subgraphs 的 demonstration latency：

```text
latency_total = Σ over subgraphs si [ min(all recorded latencies of si) ]
```

该目标在每个 subgraph 上保留已测记录中的最低 execution latency。它不是神经网络 reward，也不是 RL objective；它用于选择下一轮 SFT 的 demonstration sentences。论文以单调不增且有物理下界来解释该指标的收敛趋势（第 5.3 节）。

### 5.4 编译时间测量

附录 A 将总时间拆为：

```text
Ttotal = Texploration + Tpost-exploration compilation
Texploration = Σk (c × Tsample + Tmeasurement)
Tmeasurement = Tcompilation + Texecution
```

其中 `c` 是每个测量对应的采样系数。论文报告 Ansor/MetaSchedule 的 `c` 约为 128，而 TLM 不超过 1.1；论文用 measurement times 作为编译开销比较的稳定代理指标（附录 A）。

本文没有强化学习奖励函数；论文将真实 execution latency 用作 demonstration data 的筛选信号，而非 RL reward。

## 6. 实验设置

### 6.1 数据集来源

- 工作负载来源：PyTorch Vision Model Zoo、HuggingFace Transformer Model Zoo（第 4.3 节）。
- 总工作负载：138 个；12 个 held-out test workloads；其余约 3K subgraphs。
- 预训练数据：2 million 条随机采样 tensor sentences；无 execution latency 标签。
- SFT demonstration data：约 3K 条，来源于对 subgraph 候选进行真实测量后选出的低 latency sentence。
- 收敛实验：使用 126 workloads，TLM-Ansor-GPU、TLM-Meta-GPU、TLM-Ansor-CPU、TLM-Meta-CPU 分别对应 2169、3120、2169、2657 个 subgraphs（第 6.2 节）。
- 测试 workload：ResNet-50、DenseNet-121、MobileNet-V2、BERT-large、ResNeXt-50、Wide-ResNet-50、BERT-base、ResNet3D-18、BERT-tiny、DCGAN、GPT-2、LLAMA（表 1）。
- 数据泄漏风险：论文没有报告额外的数据泄漏审计。训练 workload 与 held-out workload 都来自两个 model zoo，具体模型级划分由表 1 和正文给出；不能据此断言完全不存在分布相似性。

### 6.2 模型与工具

- 模型：GPT-2 Small 风格 TLM，约 100M 参数；12 层、12 heads、768 hidden units。
- 支持的决策空间实现：Ansor V0.12、MetaSchedule V0.12、AKG V2.1、AKG-MLIR V0.1；实验集中在 TLM-Ansor 和 TLM-Meta（第 6.1 节）。
- 相关编译框架：TVM；TLM-Ansor/TLM-Meta 约 10K 行 Python/C++ 实现。
- GPU：48-core Intel Xeon Gold 6226、376GB 内存、4 张 32GB NVIDIA Tesla V100，Ubuntu 20.04，CUDA 11.6，cuDNN 8.4.0。
- CPU：4-core Intel Core i7-10510U，AVX2，16GB 内存，Ubuntu 20.04。
- Roller 对照环境：Ubuntu 16.04、CUDA 10.2、cuDNN 7.6.5，使用其 Docker image。
- 其他对照工具：TensorRT 8.6、PyTorch 1.13.1；Ansor V0.8 用于与 Roller 的桥接比较。

### 6.3 对比方法

| 对比方法 | 代表路线 |
|---|---|
| Ansor | 大探索空间、随机采样与代价模型 |
| MetaSchedule | 新一代 TensorIR/MetaSchedule 搜索路线 |
| Roller | 通过硬件形状约束缩小搜索空间的高效启发式编译器 |
| TensorRT | 静态高性能 kernel library/编译系统 |
| PyTorch | 静态 kernel library 支撑的深度学习执行路线 |
| TenSet/TLP | 论文相关工作中讨论的离线数据/代价模型路线，非所有实验的直接 baseline |

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| Execution latency | tensor program 在目标硬件上的执行延迟；每个 subgraph 取测量记录中的最低值 | 越低越好 |
| Overall speedup | 论文定义的 subgraph/workload 聚合性能比 | 越高越好 |
| Measurement count | 为发现高性能 program 所需的真实测量次数 | 越低越好 |
| Compilation speedup | 以测量次数作为主要时间代理时，相对 baseline 的编译探索加速 | 越高越好 |
| Profit threshold | 20K 新测量带来的性能增益低于 1% 或 1‰，用于定义 demonstration data 收敛 | 越早达到越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 23 个 TLM-Ansor subgraphs 和 40 个 TLM-Meta subgraphs 上，TLM 在相同 measurement count 下可以达到或超过 Ansor/MetaSchedule 的聚合性能（表 2、表 3）。例如：

- TLM-Ansor-1K 相对 Ansor-1K 为 1.13×；TLM-Ansor-10K 相对 Ansor-10K 为 1.08×。
- TLM-Meta-1K 相对 MetaSchedule-1K 为 1.02×。
- 在正文总结中，TLM-Ansor-32 达到相对 Ansor-10K 的 1.06×，TLM-Meta-32 达到相对 MetaSchedule-10K 的 1.00×。

这些数字表示论文定义的 subgraph 聚合 speedup，不能理解为每个 workload 或每个算子都固定获得相同加速。

### 7.2 与 Ansor/MetaSchedule 的比较

GPU 端到端实验中，TLM-Ansor-20K 相对 Ansor-20K 的平均 speedup 为 1.08；TLM-Meta-20K 相对 MetaSchedule-20K 的平均 speedup 为 1.04，范围分别为 0.99–1.38 和 0.98–1.14（第 6.4.1 节）。

在减少测量次数的设置中，TLM 用 1×g、10×g、32×g measurement 与 20K baseline 比较：

- 1×g measurements 时，TLM 达到 Ansor/MetaSchedule 性能的约 80% 平均水平。
- 10×g measurements 时，TLM 平均接近 Ansor/MetaSchedule。
- 在论文的统计表述中，不进行测量时，TLM 仍可达到约 83% 的 Ansor/MetaSchedule 性能；这只是该实验设置下的平均现象，不是无测量必然成立的保证。

### 7.3 编译时间与测量收敛

在 12 个 GPU test workloads 上，TLM-Ansor-10×g 达到与 Ansor-20K 相当的性能，同时论文报告编译探索加速约 95×；TLM-Meta-10×g 相对 MetaSchedule-20K 的探索加速约 61×（第 6.4.1 节）。

收敛实验把连续 20K measurements 带来的改进低于 1% 作为一个收敛标准。不同 CPU/GPU、Ansor/MetaSchedule 组合平均需要每个 subgraph 69–145 次测量，对应总测量量约 213K–344K；达到更严格的 1‰ 阈值时，总量约 467K–963K（第 6.2 节）。

### 7.4 与 Roller 的比较

在排除软件版本差异、使用相同环境的直接比较中，TLM-Ansor-10×g 相对 Roller-10×g 的 speedup 范围为 1.28–4.23×，平均 2.25×（第 6.4.2 节）。论文将差异归因于 Roller 为追求编译效率而显著裁剪探索空间。

### 7.5 与 TensorRT/PyTorch 的比较

在 NVIDIA V100 上，TLM-Ansor-10×g 相对 TensorRT 的 speedup 范围为 0.38–1.89×，平均 1.04；相对 PyTorch 的范围为 0.21–12.92×，平均 3.42（第 6.4.3 节）。TensorRT 在 BERT-tiny、BERT-base、BERT-large、GPT-2、LLAMA、DCGAN 等工作负载上优于 TLM；论文解释为静态 kernel library 对常见算子进行了更深度的专门优化。

### 7.6 消融实验

论文没有提供一个以“去掉 TLM、去掉 space builder、去掉 SFT、去掉迭代优化”命名的完整模块消融表。论文主要通过不同 measurement budgets、Ansor/MetaSchedule 后端、CPU/GPU 环境和不同 baseline 做比较。

因此，关于每个模块独立贡献的结论只能写为：论文中未提供完整模块级消融，当前 PDF 内容不足以把总体增益唯一归因于某一模块。

### 7.7 案例与失败行为

论文用矩阵乘法的 `m=1024, n=512, k=1024` 例子展示 TLM 逐 token 生成 tile sizes（图 7）。若生成决策不属于当前 decision space，系统丢弃该 program 并重新生成；论文报告平均不超过 1.1 次调用即可得到合法 program（第 5.2 节）。

论文没有系统报告失败样本的语义错误分类，也没有把合法性检查等同于形式化语义等价证明。

## 8. 主要创新点

### 8.1 创新点一：面向 tensor program 的短序列表示

现有 tensor program 源代码很长且需要满足严格语法。本文设计 tensor language sentence，把 subgraph、硬件规格和 schedule decisions 压缩为不超过 1024 token 的序列，使 causal language model 可以处理编译器决策。实验和系统流程证明该表示可以连接模型预测与 tensor compiler 的决策空间（第 1、4.2 节）。

### 8.2 创新点二：把语言模型放在编译器决策选择位置

论文不是让语言模型直接写完整 tensor program，而是让 TLM 逐步预测 tile、unroll、parallelization 等决策，再由编译器应用这些决策。这个分工保留了编译器的结构约束，并把模型错误限制在可检查的 decision space 中（第 5.2 节）。

### 8.3 创新点三：离线预训练 + measured-latency SFT

论文用 2 million 条无标签 sentence 学习结构，再用低 execution latency 的约 3K 条 demonstration data 做 SFT，并通过多轮真实测量持续更新 demonstration data。该方式把部分搜索成本转成离线数据收集与监督微调成本（第 4.3、5.1、5.3 节）。

### 8.4 不应单独视为创新的内容

使用 GPT-2、使用 tensor compiler、使用 SFT、使用 Ansor/MetaSchedule 的 decision space 本身不是独立创新。论文也明确说明其 decision spaces 大多适配自已有框架，主要创新集中在 tensor language 和 TLM 的决策辅助方式（第 1 节）。

## 9. 局限性

### 9.1 论文明确承认的局限

1. **训练分布依赖**：目标 workload 与训练数据分布差异较大时，需要增加训练数据才能获得较好性能（第 8 节）。
2. **预编译成本**：TLM 把部分 compile-time search 成本转移到训练和 demonstration data 收集；预训练可耗时数十小时，若只编译一个或少量模型，经济性可能不如传统方式（第 8 节）。
3. **模型规模成本**：约 100M 参数带来训练与推理时间/硬件开销，作者将缩小模型或扩大模型/数据规模列为 future work（第 8 节）。
4. **探索空间范围**：本文主要处理 tensor layer 的 exploration space，作者认为未来还可以加入 graph layer 的决策空间（第 4.1、8 节）。
5. **硬件覆盖**：实验硬件主要是 Intel CPU 与 NVIDIA V100 GPU；论文没有给出 RISC-V、AMD GPU、TPU 或其他目标架构的实证。

### 9.2 阅读后的潜在局限

1. 论文使用 measurement count 作为编译时间代理，并在附录说明其理由；这对真实端到端编译成本是合理但非完全等价的度量，尤其当采样、模型推理或后处理成本在不同硬件上占比变化时。
2. tensor sentence 依赖离线词汇和训练分布。新硬件、新算子或未见的 schedule token 可能无法生成；论文没有给出针对 OOV/新指令集的系统解决方案。
3. 合法 decision-space 检查不等于完整语义等价验证。论文测量的是可编译、可执行程序的性能，没有提供形式化 correctness proof。
4. TLM 的“高性能”依赖真实测量挑选 demonstration data，因此对测量噪声、编译器版本、硬件状态和 measurement budget 敏感。
5. 论文的 TLM 是约 100M 参数的领域语言模型。若按当前严格定义区分 LM 与大型通用 LLM，本文更准确的称呼是 domain-specific language model，而不是大规模通用指令 LLM。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

- 让模型只输出受编译器约束的决策 token，把 program construction 和 correctness-sensitive lowering 留给确定性编译器。
- 将“候选动作表示”设计成短、结构化、可逆映射到编译器 IR/配置的序列，这比要求模型直接生成长源码更容易验证。
- 用真实执行反馈选择 SFT demonstration data，避免把静态 proxy 当成最终性能证据。

### 10.2 不能简单照搬的部分

- 把 CUDA/V100 换成 RISC-V 并不能单独形成新贡献；需要证明 RISC-V 的 vector length、LMUL、cache、memory hierarchy 或自定义扩展改变了决策空间与迁移问题。
- 直接复用 2 million tensor sentences 和约 3K demonstration data 不保证跨硬件泛化；数据需要覆盖目标 ISA、后端约束和工作负载分布。
- “语法/空间合法”不能直接等同于 RISC-V 后端的语义正确或性能可靠。

### 10.3 与本仓库方向的关系

本文最适合作为 `SELECTOR / S2_Schedule_Config_Autotuning` 的代表性 baseline。它展示了 LM 最终选择 schedule/config、编译器负责物化和真实测量闭环的完整模式；与 LLVM pass/flag selector 相比，它的动作空间位于 tensor compiler 的 schedule layer，不能直接视为 LLVM pass ordering 方法。

## 11. 可进一步尝试的研究方向

以下是阅读后的研究建议，不是本文已经实现的工作。

### 11.1 面向 RISC-V Vector 的约束感知 schedule selector

#### 研究问题

如何让语言模型在 RISC-V Vector 的 vector length、LMUL、尾部处理、对齐与 cache 约束下选择 tensor schedule，并在硬件迁移时减少重新测量？

#### 与原论文的区别

不只是把实验平台换成 RISC-V，而是把 RVV 的动态向量长度和后端合法性约束编码进 decision space，并研究跨 `VLEN` 或微架构迁移。

#### 可能的创新点

硬件约束 token、跨 VLEN 的条件化 selector、真实硬件测量与静态合法性检查联合的迁移策略。

#### 实验框架

```text
Tensor subgraph + RVV/VLEN/cache metadata
        ↓
RVV-aware decision space
        ↓
LM 预测 tile/vector/unroll/layout
        ↓
RISC-V backend 编译 + 仿真/真实板卡执行
        ↓
性能与合法性反馈
```

#### 可行性

需要 TVM/MLIR 或自定义 tensor compiler 的 RVV 后端、RISC-V 模拟器或真实开发板、可重复的 kernel benchmark 和 measurement harness。

#### 主要风险

真实 RVV 硬件数量有限，仿真时间可能成为主要成本；还需避免把仿真 latency 当作真实硬件结果。

### 11.2 不确定性驱动的测量预算分配

#### 研究问题

TLM 的采样概率和编译器反馈如何共同决定哪些 subgraph 值得继续测量？

#### 与原论文的区别

原论文主要按 batch 迭代和最低 latency 选择 demonstration；新方向加入预测不确定性、跨 subgraph 迁移收益和测量成本。

#### 可能的创新点

把 LM token-level uncertainty 转换为 subgraph-level measurement priority，并用真实测量结果校准选择器。

#### 实验框架

```text
LM 生成候选及不确定性
        ↓
候选价值/测量成本排序
        ↓
选择少量候选真实编译执行
        ↓
更新 demonstration 与预算策略
```

#### 可行性

可复用本文的 tensor sentence 表示和 TVM 后端，先在 CPU/GPU 上验证，再迁移到 RISC-V。

#### 主要风险

不确定性可能只反映 token 概率而不反映真实性能；必须用 hold-out workload 和真实测量检验校准效果。

### 11.3 跨后端 schedule sentence 的可迁移表示

#### 研究问题

如何区分通用 schedule 结构与硬件专属参数，使同一 selector 能在不同后端之间迁移？

#### 与原论文的区别

原论文把硬件信息和决策放在同一 tensor sentence 中，但没有系统研究跨后端迁移的性能与负迁移。

#### 可能的创新点

将 schedule token 分解为硬件无关结构、硬件条件和可调参数，并设计受约束的适配/再训练机制。

#### 实验框架

```text
多后端 tensor sentence
        ↓
结构/硬件/参数字段分解
        ↓
共享 LM + 后端条件化适配器
        ↓
少量目标后端测量
        ↓
跨后端性能与负迁移评估
```

#### 可行性

需要至少两个 ISA/加速器后端、统一的 tensor IR 表示和相同 workload 的可比较执行指标。

#### 主要风险

不同后端的 decision space 可能不具有同构结构，简单 token 对齐会导致错误的迁移结论。

## 12. 与其他已读文献的关系

本轮阶段 2 只完成 A1-01，因此横向关系以本仓库已核验记录和当前队列元数据为限。

- 与本仓库已有 `Compiler Optimization via LLM Reasoning for Efficient Model Serving`（Paper 10）相比：两者都让 LM 参与编译优化选择，但 A1-01 使用领域 GPT-2、tensor sentence 和 SFT；Paper 10 使用 LLM reasoning + MCTS 探索模型服务的 tensor transformation/configuration，不能合并为同一方法。
- 与已有 DeCOS 相比：DeCOS 是 LLM 先验点火的 RL-based compiler optimization selection；A1-01 明确不使用 RL，而是预训练 + measured-latency SFT + 迭代 demonstration data。
- 与已有 `Large Language Models for Compiler Optimization`（2023）相比：后者主要是 LLVM compiler flags/pass ordering；A1-01 选择的是 tensor compiler schedule/config，层级不同。
- 与本阶段备选 A1-02 COMPASS、A1-03 LLM-Powered Compiler Autotuning 的关系：A1-02 预计关注 MLIR pass pipeline arrangement，A1-03 关注通用 compiler autotuning；二者未在本轮阅读，不能把其方法或实验细节与 A1-01 直接合并。A1-01 是当前队列中唯一已完成正文核验的论文。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 用语言模型辅助深度学习 tensor compiler 的 schedule exploration |
| 核心问题 | 大探索空间带来高性能潜力，但随机搜索带来巨大编译/测量开销 |
| 输入 | workload graph 划分出的 subgraph、算子/形状、硬件规格、当前决策上下文 |
| 输出 | tile、unroll、parallelization、vectorization、thread binding 等 schedule decisions |
| 核心方法 | space builder + tensor language + GPT-2 Small TLM + measured-latency SFT |
| 使用的模型 | GPT-2 Small 风格 causal LM，约 100M 参数 |
| 使用的编译器工具 | TVM 生态、Ansor、MetaSchedule、AKG、AKG-MLIR；对照 TensorRT/PyTorch/Roller |
| 是否使用强化学习 | 否；论文明确放弃 RL，采用多轮 SFT |
| 是否使用形式化验证 | 否；有 decision-space 合法性检查，不是形式化语义证明 |
| 数据集规模 | 138 workloads；12 个测试；约 3K subgraphs；2M 无标签 sentences；约 3K SFT demonstrations |
| 主要指标 | execution latency、measurement count、聚合 speedup、编译探索加速 |
| 最重要实验结果 | TLM-Ansor-10×g 相对 Ansor-20K 约 95× 探索加速；TLM-Meta-10×g 相对 MetaSchedule-20K 约 61×；TLM-Ansor-10×g 相对 Roller-10×g 平均 2.25× |
| 核心创新 | 用短 tensor language 表示编译决策，并让 LM 选择受约束 schedule、由编译器物化 program |
| 主要局限 | 强依赖训练/目标分布，预训练和测量成本高，硬件覆盖有限，合法性检查不等于形式化验证 |
| 与 RISC-V 研究的相关性 | 中：方法可迁移到 RVV schedule selection，但论文未做 RISC-V 实验，直接换平台不足以形成新贡献 |
| 最适合作为 | `SELECTOR / S2_Schedule_Config_Autotuning` baseline 与方法参考 |

> 这篇论文最值得学习的是把 LM 限制在编译器可检查的 schedule 决策空间，并用真实执行延迟选择 SFT demonstration；最主要的局限是训练分布、预编译成本和硬件泛化约束；如果用于后续研究，最合理的使用方式是作为 schedule selector baseline 和决策表示参考，而不是简单把 GPU 后端替换成 RISC-V 就宣称产生了新方法。
