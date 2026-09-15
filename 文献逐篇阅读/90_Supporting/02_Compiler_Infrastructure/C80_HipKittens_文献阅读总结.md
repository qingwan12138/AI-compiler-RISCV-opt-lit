# HipKittens 文献阅读总结

论文题目：**HipKittens: Fast and Furious AMD Kernels**

作者：William Hu、Drew Wadsworth、Sean Siddens、Stanley Winata、Daniel Y. Fu、Ryan Swann、Muhammad Osama、Christopher Ré、Simran Arora

发表时间：2026

发表平台：Proceedings of Machine Learning and Systems 8，MLSys 2026 Conference

论文链接或编号：[MLSys 官方论文页](https://proceedings.mlsys.org/paper_files/paper/2026/hash/bc75fa9843a7905bbed9d83895a88f7f-Abstract-Conference.html)；官方 PDF：[HipKittens_MLSys2026.pdf](https://proceedings.mlsys.org/paper_files/paper/2026/file/bc75fa9843a7905bbed9d83895a88f7f-Paper-Conference.pdf)；同一工作的 arXiv 编号：2511.08083

关键词：AMD GPU、CDNA3/CDNA4、GPU kernel、tile-based programming、C++ embedded DSL、register scheduling、wave scheduling、chiplet cache reuse

> 本文档用于文献阅读、组会汇报和后续研究分析。论文事实与阅读后的研究思考分开描述。本文依据官方 13 页 PDF 正文；本论文不是 LLM 方法论文。

---

## 1. 研究背景

本文研究高性能机器学习 GPU kernel 的编程框架。论文第 1 节指出，AMD GPU 具有高峰值计算能力和内存带宽，但高性能 kernel 往往依赖少数专家编写的原始汇编，难以覆盖不断扩展的 AI workload。论文以 MI355X 为例，指出 AITER 与 PyTorch 的 Llama GQA backward 仅达到 SoTA 性能的 30% 和 24%（第 1 节）。

传统选择包括原始汇编、HIP/C++、Triton 等编译器或 DSL。原始汇编控制力强但开发和扩展成本高；Triton、TileLang、Mojo 等更易使用，但论文认为它们尚未提供可复用的 AMD 高性能 kernel 原语。论文第 2.2 节还报告，作者在 MI355X 上测得 Mojo 的 MHA kernel 受 bank conflict 影响，仅达到 peak kernel 性能约 50%。

ThunderKittens（TK）等 NVIDIA 方向工作用 tile（GPU 内存层次中可显式管理的数据块）、批量计算操作和异步执行来降低 kernel 编程难度。本文的问题是：这些编程原语是否能直接迁移到 AMD，还是需要根据 AMD 的寄存器、矩阵指令、共享内存和 chiplet cache 结构重新设计。

## 2. 论文要解决的问题

### 2.1 AMD kernel 的可编程高性能抽象

论文研究能否用一组简洁、可组合的 C++ embedded primitives，替代大量面向特定 kernel 的 AMD 原始汇编，同时保留接近 peak 的性能（第 1、3 节）。

### 2.2 可编程内存与矩阵布局

AMD CDNA 的 AGPR/VGPR 寄存器、MFMA 矩阵布局和共享内存 bank 行为使得 tile 的布局及寄存器生命周期难以由通用编译器自动处理。论文需要为这些硬件差异提供稳定的 tile、load/store 和显式寄存器接口（第 3.2 节）。

### 2.3 计算与内存的重叠，以及 chiplet cache reuse

NVIDIA 常见的 producer-consumer wave specialization 在 AMD 上会因静态寄存器分配降低输出 tile 大小和算术强度。论文还研究如何按 AMD 的 L2/LLC 层级安排 thread block，从而提高有效带宽（第 3.3、3.4 节）。

> 本文主要研究：如何针对 AMD CDNA3/CDNA4 的硬件差异，设计可复用的 tile、调度和 cache-aware kernel 编程原语，以较低开发复杂度实现高性能 AI kernels。

## 3. 核心方法概述

HipKittens（HK）是建立在 ThunderKittens 思路之上的 AMD C++ embedded 框架。它保留 tile 作为基本数据结构，并提供受 PyTorch/NumPy 启发的 `mma`、`exp`、`add` 等轻量 bulk operators；这些函数直接封装 AMD CDNA assembly/HIP，因此论文将其描述为不增加额外运行时开销的编程接口（第 3.1 节）。

```text
AI 算子 / kernel 设计
        ↓
HK tile 与 bulk operator
        ↓
显式寄存器、共享内存与全局内存访问
        ↓
8-wave ping-pong 或 4-wave interleave 调度
        ↓
XCD 分组与层次化窗口遍历
        ↓
AMD CDNA3/CDNA4 kernel
        ↓
真实 GPU 上的 TFLOPS、带宽、cache hit 与模型训练稳定性
```

HK 的三个主要设计是：

1. 对可编程 GPU memory 提供 tile 布局、bank-conflict-free shared-memory swizzle，以及可选的显式寄存器 pinning；
2. 用 8-wave ping-pong 和 4-wave interleave 替代不适合 AMD 的通用 wave specialization；
3. 用 XCD grouping 和 hierarchical windowed traversal 同时优化 L2 与 LLC reuse（第 3 节）。

本文没有让语言模型生成 kernel，也没有把模型作为 selector、translator 或 generator。按照 taxonomy v2，建议分类为 `SUPPORTING / B2_Compiler_Infrastructure`：HK 是可复用的 kernel 编程/编译基础设施，而不是 LM 最终输出的编译动作。

## 4. 实验框架与训练流程

### 4.1 框架构建与微实验

本文不涉及模型训练，主要采用硬件分析、手工实现 HK primitives、微基准和 kernel 对比实验。作者先分析 AMD CDNA3/CDNA4 的寄存器、MFMA、shared memory、SIMD/wave 和 chiplet cache，再实现 HK 的 tile、寄存器、调度与 cache 原语（第 2、3 节）。

### 4.2 调度与内存实验

作者通过不同 producer/consumer 比例、同步方式、pipeline depth 和输出 tile 大小比较 wave specialization；随后比较 8-wave ping-pong 与 4-wave interleave。对 cache 则比较 row-major、不同窗口高度 W 与 chunk 大小 C 的 XCD swizzle（第 3.3、3.4 节）。

### 4.3 端到端 kernel 评测

评测覆盖 BF16/FP8 GEMM、GQA/MHA attention forward/backward、RoPE、fused dropout-residual-layernorm 等 workload，平台为 AMD CDNA3 MI325X 和 CDNA4 MI355X。kernel 通过 Python bindings 或相应 HIP 接口运行，并与 PyTorch、AITER、Composable Kernel、ROCm Triton、HipBLASLT 等基线比较（第 4 节）。

### 4.4 模型训练稳定性检查

作者使用 HK kernel 预训练 Llama 1B 和 BERT 110M，在 The Pile 上训练 10B tokens，并报告其 perplexity 与 PyTorch/AITER 训练结果匹配（第 4 节）。这一步是 kernel 正确性/稳定性的应用检查，不是 HK 的模型训练阶段。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数、SFT、PPO、GRPO 或 LLM 损失函数。

论文第 3.4 节给出用于解释 cache-aware grid scheduling 的带宽关系：

```text
Bandwidth = LLC Bandwidth × LLC Hit% + L2 Bandwidth × L2 Hit%
```

其中 L2 和 LLC 分别是 AMD GPU 的两级 cache，hit% 表示相应层级的命中比例。该式用于说明不能只追求 L2 hit rate：L2 带宽约为 LLC 的 3 倍，调度需要同时考虑两级 cache 的数据复用（第 3.4 节）。

论文也将“输出 tile 大小”和“pipeline depth”作为调度分析的关键性能因素：更大的输出 tile 提高 arithmetic intensity，更深的 pipeline 隐藏内存加载延迟（第 3.3.1 节）。这些是实验分析原则，不是训练目标函数。

## 6. 实验设置

### 6.1 数据集来源

本文不是数据集论文。GEMM 实验使用从标准正态分布随机生成的输入张量；模型稳定性实验使用 The Pile，并以 Llama 1B、BERT 110M 进行 10B-token 预训练（第 4 节）。论文没有把训练数据进一步拆分为训练集、验证集和测试集，也没有报告数据清洗或泄漏分析；这些信息论文中未明确说明。

### 6.2 模型与工具

主要工具和基线包括 HK、PyTorch/SDPA、AMD AITER、Composable Kernel、ROCm Triton、HipBLASLT；相关对比还涉及 ThunderKittens、CUTLASS、Mojo 和 FlashAttention-3（第 2.2、3.3、4 节）。运行环境使用 AMD beta Docker 和 ROCm 7.0 preview 镜像；具体镜像字符串见第 4 节。

### 6.3 硬件

主要评测平台为 AMD MI325X（CDNA3）和 MI355X（CDNA4）。论文第 2 节说明 MI355X 有 256 个 CU，分布在 8 个 XCD，每个 XCD 共享一个 4MB L2；所有 CU 共享 HBM 与 LLC。硬件概览表还报告 MI355X 内存容量 288GB、带宽 8.0TB/s；B200 对照为 180GB、8.0TB/s（表 2 前的硬件概览）。

### 6.4 指标与测量方法

GEMM 和 attention 主要报告 TFLOPS；memory-bound workload 报告性能倍率；cache 实验报告 L2 hit%、LLC hit%、内存带宽和 TFLOPS。每个 kernel 先 warmup 500 次，再测量 100 次并报告平均 TFLOPS/s；输入为标准正态分布随机张量（第 4 节）。论文没有把静态估计冒充真实硬件时间，结果来自 AMD GPU 上的运行测量。

## 7. 实验结果与分析

### 7.1 寄存器显式调度

表 1 的 4-wave MHA non-causal backward 实验中，序列长度 4096 时，HK 为 855 TFLOPS，加入 pinned registers 后为 1024 TFLOPS，AITER 汇编为 1018 TFLOPS；序列长度 8192 时分别为 909、1091、1169 TFLOPS。该结果支持论文关于绕过 HIPCC、允许 AGPR 作为矩阵指令输入的设计（表 1）。

### 7.2 计算/内存调度

表 2 的 MI355X BF16 GEMM 实验显示，输出 tile 256×256 且无 producer 的 HK kernel 达到 1610 TFLOPS；带 4 个 producer、8 个 consumer 且输出 tile 128×256 时为 893 TFLOPS。论文据此认为 AMD 静态寄存器分配会让 producer 消耗寄存器但不直接贡献输出计算（表 2）。

表 3 中，FP8 GEMM 的 8-wave 与 4-wave 分别为 3222 和 3327 TFLOPS；MHA backward 分别为 894 和 1091 TFLOPS。8-wave 代码较短，4-wave 在不均衡 workload 上性能更高，体现了可编程性与性能之间的取舍（表 3）。

### 7.3 Cache-aware 调度

对于 M=N=K=9216、tile 192×256×64 的 BF16 GEMM，row-major 的 L2/LLC hit 为 55%/95%、带宽 15.1TB/s、性能 1113 TFLOPS；一种 XCD schedule 为 75%/93%、18.3TB/s、1145 TFLOPS。对于 M=N=K=14592，row-major 只有 36%/76%、10.7TB/s、900 TFLOPS，而 XCD W8/C64 达到 78%/55%、16.6TB/s、1068 TFLOPS（表 4）。这说明更高的单级 cache 命中率不必然带来更高总体性能，关键是两级 cache 与带宽的联合平衡。

### 7.4 Kernel 与基线比较

HK 的 BF16/FP8 GEMM 相比 Triton compiler 的提升为 1.3–3.0×（第 4 节）。attention forward 中，相对 AITER、PyTorch SDPA、CK 和 Triton 的倍率范围分别为 1.0–2.1×、1.3–4.5×、1.0–1.4× 和 1.2–4.5×；这些是图 8 在所列 batch 16、query heads 64、KV heads 8、head dim 64/128 设置下的跨 shape 结果范围。

GQA causal/non-causal backward 相对基线提升为 1.8–2.5×（图 9）；memory-bound fused dropout-residual-layernorm 与 RoPE 相对 AITER 和 PyTorch compiled kernel 提升为 1.1–2.2×（图 10）。论文还报告，在 10B tokens 训练后，HK kernel 的 Llama 1B 与 BERT 110M perplexity 与 PyTorch/AITER 匹配（第 4 节）。

### 7.5 消融与案例

本文没有以“移除一个模块”的标准消融表呈现所有组件，但表 1、表 2、表 3 和表 4 分别构成寄存器 pinning、producer/consumer 调度、wave pattern、cache schedule 的对比实验。论文没有提供失败案例的系统统计；未报告的内容不应推断为不存在失败。

## 8. 主要创新点

### 8.1 创新点一：面向 AMD 的 tile 编程框架

论文把 tile 和 PyTorch-inspired bulk operators 迁移到 AMD，并说明前端抽象可以保持相似，但具体 schedules、memory movement 和 cache optimization 必须按 AMD 硬件重构（第 5 节）。价值在于把底层 AMD 汇编经验封装为可组合接口；实验中该接口覆盖多类 AI kernel。

### 8.2 创新点二：8-wave ping-pong 与 4-wave interleave

论文不是简单复用 NVIDIA wave specialization，而是利用 AMD 同一 SIMD 上的 wave 并行：8-wave 让成对 wave 交替执行 compute/memory，4-wave 则让每个 SIMD 上一个 wave 细粒度交错两类指令（第 3.3.2 节）。表 3 和图 9 证明两种模式在不同 workload 上各有优势。

### 8.3 创新点三：可控寄存器与 AMD 布局封装

HK 允许开发者显式 pin tile registers，并为 AMD 不同 MFMA shape、共享内存 bank 行为和 HBM-to-shared 地址提供相应接口（第 3.2 节）。这不是“使用编译器”本身的创新，而是对 HIPCC 限制和 AMD layout 差异的具体封装。

### 8.4 创新点四：双层 cache-aware chiplet swizzling

HK 的 XCD grouping 和 hierarchical windowed traversal 同时考虑 L2 与 LLC，而不是只优化单一 cache 层。表 4 的带宽和 TFLOPS 对比支持该设计的收益。

## 9. 局限性

### 9.1 论文明确承认或显示的边界

论文聚焦 AMD CDNA3/CDNA4；它没有证明同一实现能直接迁移到 NVIDIA、TPU、CPU 或 RISC-V。4-wave pattern 代码更长、编程负担更高；8-wave 虽然更简洁，但在不均衡 workload 上不一定达到 4-wave 性能（第 3.3.2 节）。

HK 仍要求开发者理解 workload 和硬件，并在不同 MFMA shape、tile granularity、窗口 W/C 等设计点做选择。论文没有给出完整自动调优器，也没有报告从新 kernel 需求到实现的开发时间、代码总量或维护成本。

### 9.2 阅读后发现的潜在局限

实验主要是作者选取的代表性 kernel 和 AMD 平台，不能据此推断所有 AI workload 都获得同样倍率。性能结果依赖具体 ROCm 版本、Docker、shape、batch、head dimension 和基线版本；跨版本稳定性论文中未明确说明。模型训练只用 Llama 1B/BERT 110M 和 10B tokens 做稳定性检查，不等于完整应用级端到端吞吐评测。

HK 通过绕过部分编译器控制寄存器和汇编封装获得性能，这可能增加后端可移植性、调试和安全审计成本。论文没有提供形式化等价证明；perplexity 匹配也不能单独证明每个 kernel 的逐元素语义等价。

## 10. 阅读后的研究方向反思

值得借鉴的是“硬件差异先转化为可验证的编程原语，再由原语承载 kernel 生成/调度”的分层思路，以及同时记录性能、cache 命中和资源约束。对 LLVM/MLIR/RISC-V 研究，HK 更适合作为 GPU kernel 编译基础设施和硬件效应反馈的参考，而不是直接照搬到 RISC-V。

不能把平台从 AMD 换成 RISC-V 就视为新的研究贡献。若迁移到 RVV，应重新定义 vector length、寄存器压力、memory layout、cache/NUMA 和实际硬件反馈，并证明这些机制相对于 LLVM/MLIR 现有 lowering 的新增价值。本文没有涉及 RISC-V、LLVM pass 选择或 LLM agent。

## 11. 可进一步尝试的研究方向

### 11.1 方向一：面向 RVV 的 tile 原语与实测反馈

#### 研究问题

能否把 HK 的 tile/调度抽象改写为 RVV 可变向量长度和真实 cache 层次感知的 kernel 原语。

#### 与原论文的区别

不是替换硬件名称，而是研究 RVV 的 VLEN、LMUL、mask、寄存器组和编译器 lowering 如何改变 tile 与调度空间。

#### 可能的创新点

建立 tile 布局到 RVV intrinsic/MLIR vector dialect 的可验证映射，并用真实硬件性能反馈校准 cost model。

#### 实验框架

```text
RVV kernel/MLIR tile
 → lowering 与合法性检查
 → RVV 硬件运行
 → cycles、cache、向量利用率
 → 选择下一组 tile/layout/schedule
```

#### 可行性

需要 RVV 硬件或仿真器、LLVM/MLIR、GEMM/attention microbenchmarks 和可重复测量脚本。

#### 主要风险

不同 RVV 实现的 cache、VLEN 和 microarchitecture 差异可能使结论难以泛化。

### 11.2 方向二：HK 风格 kernel 生成的证据约束

#### 研究问题

能否让 LLM 只生成符合 tile API、寄存器约束和语义测试契约的候选 kernel，并把 HK 式 profiling 反馈用于选择。

#### 与原论文的区别

HipKittens 本身不是 LLM 系统；新方向引入 LLM 后，必须新增编译、正确性和性能证据链。

#### 可能的创新点

将 API schema、编译器错误、单元测试、硬件 counter 和性能回归规则共同作为候选晋级条件。

#### 实验框架

```text
参考 kernel + tile API
 → LLM 生成候选
 → 编译/正确性检查
 → GPU/RVV profiling
 → 约束过滤与性能选择
```

#### 可行性

可先在现有 HK 或 Triton kernel benchmark 上验证，再扩展到 RVV。

#### 主要风险

有限测试不能替代形式化证明，且硬件 profiling 成本可能限制搜索预算。

## 12. 与其他已读文献的关系

本批只完整阅读 HipKittens 一篇，因此本节不构造未经核验的横向比较。论文正文明确把 ThunderKittens、Triton、TileLang、Mojo、AITER、Composable Kernel、CUTLASS 和 FlashAttention-3 作为相关系统或实验基线：HK 延续 tile-based kernel 编程，但面向 AMD 重新设计寄存器、wave scheduling 和 chiplet cache。

与本仓库已占用的 CATWILD、Syncopate 等题名执行去重时，HipKittens 的规范化题名、官方 proceedings 路径和 arXiv ID 2511.08083 均不同；未发现同一工作版本关系。由于本 staging 任务只交付一篇，其他候选不进入本批正式笔记集合。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | AMD GPU 高性能 AI kernel 编程框架 |
| 核心问题 | 如何在降低汇编开发成本的同时接近 AMD peak performance |
| 输入 | AI kernel/算子设计、tile、硬件约束 |
| 输出 | HipKittens C++ embedded tile primitives 与 AMD kernels |
| 核心方法 | 显式寄存器、AMD tile layout、8-wave/4-wave 调度、XCD cache swizzling |
| 使用的模型 | 不涉及 LLM 模型训练；端到端稳定性用 Llama 1B、BERT 110M |
| 使用的编译器工具 | HIP/HIPCC、ROCm Triton、PyTorch、AITER、Composable Kernel、HipBLASLT |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；采用运行测量与模型训练稳定性检查 |
| 数据集规模 | 不是数据集论文；The Pile 上 10B tokens 的稳定性实验 |
| 主要指标 | TFLOPS、带宽、L2/LLC hit%、性能倍率、perplexity |
| 最重要实验结果 | 多项 kernel 接近或超过汇编基线；GQA backward 相对基线 1.8–2.5×；Triton GEMM 提升 1.3–3.0× |
| 核心创新 | 面向 AMD 的 tile 原语、wave 调度与双层 cache-aware swizzling |
| 主要局限 | 依赖 AMD CDNA 和硬件细节；缺少自动调优、形式化等价与广泛跨平台证明 |
| 与 RISC-V 研究的相关性 | 中：可借鉴硬件感知分层和实测反馈，但没有 RVV 实验，不能直接迁移 |
| 最适合作为 | GPU kernel 编译基础设施、硬件效应反馈和 kernel DSL 的方法参考 |

> 这篇论文最值得学习的是把 AMD 硬件差异具体化为 tile、寄存器、wave 和 cache 原语；最主要的局限是实现仍依赖特定 CDNA 结构和专家选择；如果用于后续研究，最合理的使用方式是作为硬件感知 kernel 编译/反馈的基础设施参考，而不是简单替换成 RISC-V 或把它描述成 LLM 优化系统。
