# T-MAC 文献阅读总结

论文题目：**T-MAC: CPU Renaissance via Table Lookup for Low-Bit LLM Deployment on Edge**

作者：Jianyu Wei、Shijie Cao、Ting Cao、Lingxiao Ma、Lei Wang、Yanyong Zhang、Mao Yang

发表时间：2025

发表平台：Twentieth European Conference on Computer Systems（EuroSys ’25），第 278–292 页

论文链接或编号：DOI `10.1145/3689031.3696099`；arXiv `2407.00088`（公开正文 PDF）

关键词：低比特 LLM、混合精度矩阵乘法、查找表、CPU 推理、TVM、LLVM、边缘设备、内核优化

> 本笔记依据 staging 中的 15 页 PDF 正文撰写。论文事实与阅读后的分析分开表述；本文没有把 T-MAC 扩大解释为 LLM 编译器或 RISC-V 系统。

---

## 1. 研究背景

本文研究低比特大语言模型（Large Language Model, LLM）在边缘设备上的推理系统。边缘部署受内存容量、内存带宽、单请求低批量推理以及能耗约束；论文第 2.1 节指出，LLM 的 prefill 阶段偏矩阵-矩阵乘法，decode 阶段通常反复加载模型并执行矩阵-向量乘法，后者容易成为内存受限瓶颈。

权重量化可以将模型压缩到 4、3、2 甚至 1 bit，但激活通常仍保持较高精度。因此实际计算是低比特权重与高精度激活之间的混合精度 GEMM/GEMV（mixed-precision General Matrix/Vector Multiplication）。论文第 1、2.3 节指出，常见 CPU/GPU/NPU 硬件并不原生支持任意这种不对称位宽，现有系统往往先把权重反量化到 INT8/FP16，再执行高精度矩阵乘法，反量化开销可能抵消降位宽收益。

这还造成工程复杂度：不同权重位宽需要不同的数据布局、解包方式、交错/重排方式和计算内核。论文的目标是让低比特权重的混合精度计算绕过反量化，使用统一、可扩展且能在普通 CPU 上运行的内核。

## 2. 论文要解决的问题

### 2.1 直接支持混合精度计算

如何在低比特权重和高精度激活之间直接进行 mpGEMM/mpGEMV，而不把低比特权重恢复成高精度数据再乘法计算？

### 2.2 支持多种权重位宽

如何避免为 W4A16、W3A16、W2A16、W1A16 等组合分别设计完全不同的布局和内核，并使性能随位宽降低而可扩展？

### 2.3 控制查找表的内存和访问代价

位级查找表（Lookup Table, LUT）会引入随机访问、更大的片上存储占用和中间结果保存压力。如何让 LUT 尽量驻留在寄存器等快速存储中，同时减少溢出和访存开销？

> 本文主要研究：如何通过位串行分解、LUT 计算和硬件感知布局，在通用 CPU 上高效执行低比特 LLM 的混合精度矩阵计算。

## 3. 核心方法概述

T-MAC 将传统“按数据类型做乘法”的计算改写为“按权重位平面查表并累加”。对于 n-bit 权重，论文第 3.1 节给出：

```text
A × W = A × (Σ(i=0..n-1) 2^i W_i)
      = Σ(i=0..n-1) 2^i (A × W_i)
```

每个 `W_i` 是一位权重矩阵。将若干位组成大小为 `g` 的组后，可以预先计算激活向量与全部 `2^g` 个位模式的结果，推理时用权重位模式索引 LUT，再进行加法聚合，从而消除主循环中的乘法。

```text
低比特权重 W
        ↓ 离线拆分、打包、置换、交错
位平面 W_i / 1-bit 索引
        ↓
高精度激活 A ──→ 预计算 LUT（位模式对应的 A 与模式乘积）
        ↓                         ↑
   LUT 查找 + 低位累加 ←──────────┘
        ↓ 位串行聚合、量化缩放和偏置恢复
输出矩阵/向量
        ↓
TVM + LLVM 生成 CPU 内核，接入 llama.cpp
        ↓
边缘设备上的端到端 token 生成
```

系统设计包括：

1. LUT-centric data layout：通过轴重排和 tiling 复用 LUT，并把 LUT 放到寄存器等片上存储。
2. Weight permutation：离线重排权重，使 tile 的加载更接近连续内存访问。
3. Weight interleaving：离线交错打包权重，降低小端 CPU 上解包所需的额外重排。
4. Mirror consolidation：利用 LUT 值的正负对称性，只保存一半表项并在需要时取负。
5. Table quantization：对 LUT 值进行更细粒度的动态量化，论文示例为 FP16 LUT 量化为 INT8 并配合缩放因子。
6. 硬件内建指令：在 ARM NEON 使用 `TBL`，在 x86 AVX2 使用 `PSHUFB`；聚合可使用低位加法或可选的快速 8-bit aggregation。

T-MAC 不是语言模型，也没有让 LLM 生成代码。它是一个传统的编译器/运行时内核系统：TVM + LLVM 负责针对形状和硬件生成代码，AutoTVM 用于自动调优，最终生成的单线程代码块由 llama.cpp 的线程池调度。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT、强化学习或在线策略更新，主要采用静态内核生成、离线权重预处理和推理阶段执行。

### 4.1 离线权重与代码准备

权重先按位拆分为一位矩阵，并按选定的 tile 访问顺序执行 permutation/interleaving。TVM + LLVM 生成不同矩阵形状、目标硬件和指令集的 C/C++ 内核；TVM Tensorize 用于嵌入硬件 intrinsic，AutoTVM 用于调优配置。

### 4.2 推理阶段

给定激活后，系统构造 LUT；对于每个权重位平面，根据索引查表并累加，再按位权重、量化缩放和偏置恢复输出。论文算法 1 给出了 `Precompute`、`PreprocessWeights`、逐位查表和最终聚合流程。

### 4.3 系统集成

论文第 4 节说明，直接同时使用 TVM 线程池和 llama.cpp 线程池会产生资源竞争。因此作者让 TVM 生成不依赖 TVM runtime/threadpool 的可移植 C++ 函数；每个函数只处理一个 threadblock，再由 llama.cpp 线程池分配。

### 4.4 测量流程

内核级测试先 warmup 10 次，再运行 100 次取平均延迟。模型级测试把 T-MAC 内核接入 llama.cpp，每次生成 64 个 token，重复 20 次测量 token generation throughput。功耗实验在 M2 Ultra 上以 500 ms 采样间隔持续生成至少 120 秒，并通过功率积分估算总能耗。

## 5. 奖励函数、损失函数或关键公式

本文没有强化学习奖励函数，也没有模型训练损失函数。

### 5.1 位串行分解

```text
A × W = Σ(i=0..n-1) 2^i (A × W_i)
```

其中 `A` 是激活矩阵，`W` 是 n-bit 权重矩阵，`W_i` 是第 i 个权重位平面。该等式将不同权重位宽统一成一系列一位矩阵计算。

### 5.2 LUT 计算流程

论文算法 1 的抽象形式为：

```text
LUT = Precompute(A)
R_i[n,m] = Σ_k Look-up(LUT, W_i, n, m, k)
R = Σ_i α_i R_i + R_β
```

`α_i` 是位串行变换后的系数，`R_β` 是偏置相关项。LUT 的分组大小 `g` 决定每个表的 `2^g` 个模式；`g` 越大，理论上可减少查表组数，但表和寄存器压力也会指数增加。

### 5.3 线性位值变换

论文第 4 节将原始 0/1 位值变换为 `-1/+1`，并用系数和偏置恢复原始结果：

```text
W = Σ(i=0..b-1) α_i 2^i W'_i + B
```

这样可使用加减指令进行 LUT 构造，论文称经验上 `s0=-1, s1=1` 能减小 LUT 数值范围。快速 8-bit aggregation 还可能引入数值误差，因此被设为可选项。

## 6. 实验设置

### 6.1 数据集来源

本文不是数据集论文，使用真实量化 LLM 和来自 Llama 模型的矩阵形状：

| 对象 | 论文中的来源/用途 |
| --- | --- |
| Llama-2-7B、Llama-2-13B | 提取矩阵形状用于 mpGEMV/mpGEMM 内核测试 |
| 4-bit Llama | GPTQ 量化模型 |
| 3-bit、2-bit Llama | BitDistiller 模型 |
| 1-bit Llama | OneBit 模型 |
| BitNet 1-bit、1.58-bit | 从头训练的低比特模型；1.58-bit ternary 权重按 2-bit 处理并拆成两个 1-bit 矩阵 |
| Llama-2-7B GGUF | 用于模型级误差和质量测试 |

论文中未报告统一的训练集、验证集和测试集规模；该系统实验主要是内核、端到端推理和模型质量评测。论文未进行训练数据泄漏分析。

### 6.2 模型与工具

硬件包括 Apple M2 Ultra、Raspberry Pi 5（ARM Cortex-A76）、NVIDIA Jetson AGX Orin（ARM Cortex-A78AE + GPU）、Surface Book 3（Intel Core i5-1035G7）；第 5.7 节还报告 Surface Laptop 7、OnePlus 12 和 Jetson Orin NX 上的 CPU/GPU/NPU 对比。软件工具包括 TVM、LLVM、AutoTVM、llama.cpp、PyTorch/Numpy/DLPack 接口以及 ARM NEON 和 x86 AVX2 intrinsic。

论文明确记录 llama.cpp baseline 版本为 b2794（2024 年 5 月发布）。其余未明确给出的工具版本不作补充推断。

### 6.3 对比方法

主要 baseline 是 llama.cpp 的针对各硬件优化的混合精度内核；mpGEMM 还比较 llama.cpp 使用 Accelerate 或 OpenBLAS 的 BLAS 实现。端到端推理将 T-MAC 内核集成到 llama.cpp 后，与原始 llama.cpp 对比。第 5.7 节还与 llama.cpp 的 CPU/GPU 后端和 Qualcomm AI Hub 提供的 NPU 数据比较。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
| --- | --- | --- |
| Kernel latency | mpGEMV/mpGEMM 单次执行时间 | 越小越好 |
| Speedup | 相对 baseline 的性能比 | 越大越好 |
| Tokens/sec | 端到端 token 生成吞吐 | 越大越好 |
| Power | 运行时平均功率 | 越小越好 |
| J/token | 每个生成 token 的能耗 | 越小越好 |
| NMSE | 与未量化 FP16 GEMV 输出的归一化均方误差 | 越小越好 |
| Perplexity | WikiText-2、LAMBADA 上的困惑度 | 越小越好 |
| WinoGrande accuracy | 问答准确率 | 越大越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在第 5.2 节的 Llama-2-7B/13B 矩阵形状内核测试中，T-MAC 的单线程 mpGEMV 最大加速比分别为 1/2/3/4 bit 的 11.2×、5.8×、4.7×、3.1×；多线程 2-bit mpGEMV 在 M2 Ultra、Raspberry Pi 5、Jetson Orin、Surface Book 3 上报告的加速比分别为 4.0×、4.0×、5.3×、2.5×。具体数值是相对于各设备上的 llama.cpp 内核，不代表所有模型端到端都达到相同加速。

在端到端测试中，Raspberry Pi 5 单线程三个模型的加速比分别为 2.8×、6.7×、5.8×；多线程 M2 Ultra 上为 1.1×、2.3×、1.7×。BitNet-3B 在 M2 Ultra 可达到峰值 71 tokens/s，在 Raspberry Pi 5 达到 11 tokens/s（论文摘要写作 11 tokens/s；正文表述为约 11.1 tokens/s）。

### 7.2 能耗结果

M2 Ultra 上，Llama-2-7B-4bit、Llama-2-7B-2bit、BitNet-3B 的功耗下降分别为 10.3%、10.3%、17.3%；总能耗下降分别为 20.6%、61.2%、51.3%。Jetson AGX Orin 上，Llama-2-7B-2bit 的 T-MAC CPU 端到端吞吐为 15.62 tokens/s、功耗 10.4 W、能耗 0.66 J/token；相对 llama.cpp CPU 的 7.08 tokens/s、15.0 W、2.12 J/token，T-MAC 达到约 2.2× 吞吐和约 3.2× 能效。

### 7.3 与 GPU/NPU 的比较

在 Jetson Orin NX、OnePlus 12 和 Surface Laptop 7 上，T-MAC 使用较少 CPU 核心即可超过部分 GPU/NPU 结果。例如 Surface Laptop 7 的 Llama-2-7B-2bit 为 31.83 tokens/s，表 7 中对应 NPU 推断值为 10.40 tokens/s；OnePlus 12 的 2-bit 为 16.62 tokens/s，对应 NPU 推断值为 11.30 tokens/s；Jetson Orin NX 的 2-bit 为 11.41 tokens/s，对应 llama.cpp GPU 为 7.94 tokens/s。NPU 的 2-bit 数值是由 4-bit 数据推断得到并标注为推断值，不能当作直接测量。

### 7.4 消融实验

第 5.5 节从 TM-base 逐步加入优化：表量化使性能接近 llama.cpp；tiling 最大带来 1.45×；置换再带来 1.39×；权重交错带来 1.42×；可选快速聚合最高可再提升 1.29×，但会带来明显精度代价。作者指出不同优化并非完全独立，例如 permutation 依赖 tiling。

### 7.5 误差与模型质量

第 5.6 节中，T-MAC 与 llama.cpp 相比的内核 NMSE 差异很小；加入快速聚合后 NMSE 约增至原来的 2.5 倍。Llama-2-7B-4bit 单线程 M2 Ultra 上，llama.cpp 为 5.65 tokens/s、T-MAC 为 7.34 tokens/s；WikiText-2 困惑度均为 5.96，LAMBADA 困惑度均为 12.95，WinoGrande 准确率均为 70.8。开启快速聚合后为 8.97 tokens/s，但困惑度变为 6.38、13.99，准确率降至 67.8%。因此默认 T-MAC 的表量化误差对模型质量影响很小，而快速聚合应按精度需求选择。

## 8. 主要创新点

### 8.1 创新点一：位串行 LUT 统一混合精度内核

现有实现围绕硬件数据类型和具体位宽设计解包、布局及乘法内核。T-MAC 用位平面分解把任意 n-bit 权重统一为一位矩阵计算，再以查表加法代替主路径乘法。论文的实验表明，这种统一设计在 1–4 bit 范围内能随位宽下降获得较好的内核扩展性。

### 8.2 创新点二：面向 LUT 的片上存储与布局协同

T-MAC 并非只提出数学上的查表替换，而是用轴重排、tiling、权重置换、权重交错解决随机访问、寄存器压力和内存事务问题。性能提升来自算法分解与数据布局/硬件指令的共同设计。

### 8.3 创新点三：可部署的 TVM/LLVM + llama.cpp 集成

论文将 TVM/LLVM 代码生成、AutoTVM 调优和 llama.cpp 线程池连接起来，并显式处理双线程池冲突，提供 C++/Python API 和去除 TVM runtime 依赖的可移植代码。这是可复用的系统工程贡献，但“使用 TVM/LLVM”本身不应单独算作创新。

## 9. 局限性

### 9.1 论文明确承认或实验直接显示的局限

1. 快速 8-bit aggregation 会引入不可忽略的数值误差，虽然能提高吞吐，但可能降低困惑度和准确率，因此只作为可选优化。
2. 多线程性能常受内存带宽限制，端到端加速低于单个 mpGEMV/mpGEMM 内核加速。
3. M2 Ultra 的 AMX 等硬件会使 T-MAC 在部分 mpGEMM 场景的优势缩小。
4. LUT 大小随分组大小 `g` 指数增长，过多 LUT 会导致寄存器溢出；最优 `g` 和 tile 配置依赖具体硬件。
5. 论文主要评估低比特 Llama/BitNet 及若干边缘硬件，未证明对任意模型、任意量化格式或任意架构都同样有效。

### 9.2 阅读后发现的潜在局限

1. 论文把权重置换和交错作为离线预处理，动态权重更新或频繁切换模型时的预处理成本没有被系统评估。
2. NPU 2-bit 对比部分使用由 4-bit 数据推断的数值，真实 NPU 端到端 2-bit 测量仍有限。
3. 当前实现依赖 TVM/LLVM 生成 CPU 代码和特定 ARM/x86 intrinsic；迁移到 RISC-V 需要新的查表/向量指令映射和寄存器压力评估，不能只替换目标三元组。
4. 论文以实测设备和固定模型形状为主，尚未给出跨编译器版本、跨 OS 或跨量化训练流程的系统复现敏感性分析。

## 10. 阅读后的研究方向反思

T-MAC 最值得借鉴的是“数学分解—数据布局—硬件指令—运行时集成”联动的方法，而不是简单把 LUT 机制搬到另一种 ISA。它适合作为低比特推理内核、TVM/LLVM 后端优化和 CPU/GPU/NPU 对比的 baseline 或工具模块。

对于“大语言模型与编译器优化”方向，T-MAC 的最终系统角色不是 LLM Selector、Translator 或 LLM-generated Generator，而是传统编译器/运行时生成并执行高性能内核。将平台替换成 RISC-V 本身创新性有限；有潜力的研究问题应包括：RISC-V Vector Extension（RVV）下的可变向量长度 LUT 映射、寄存器分块与 mask 处理、查表指令缺失时的替代实现，以及编译器自动选择位分组和内核布局。

论文没有提供形式化语义验证，因此其“正确性”主要由代数等价、数值误差和模型质量实验支持，不能表述为形式化证明。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的可变向量长度 LUT 内核

#### 研究问题

如何在 RVV 的可变向量长度和不同实现宽度下，自动选择 LUT 分组、tile 形状、寄存器驻留策略和聚合精度？

#### 与原论文的区别

不是把 ARM NEON/AVX2 intrinsic 逐条替换为 RVV intrinsic，而是建立面向 VLEN、LMUL、寄存器压力和内存带宽的编译器代价模型。

#### 可能的创新点

RVV-aware LUT layout、动态 VLEN 代码生成、跨芯片自动调优和无快速聚合精度损失的聚合策略。

#### 实验框架

```text
低比特模型与矩阵形状
        ↓
RVV LUT layout / tile / group-size 搜索
        ↓
LLVM/RVV 代码生成
        ↓
真实 RVV 硬件或 cycle-accurate 环境
        ↓
吞吐、能耗、NMSE、模型质量
```

#### 可行性

需要 LLVM/RVV、TVM 或自定义后端、低比特 Llama/BitNet、至少一种 RVV 平台和基于 llama.cpp 的推理接入。

#### 主要风险

RVV 实现之间的 cache、向量宽度和查表能力差异较大，可能需要把“可移植性”与“峰值性能”分开评估。

### 11.2 编译器驱动的 LUT 分组与精度选择

#### 研究问题

能否由编译器根据目标 CPU 的寄存器容量、查表吞吐和允许的模型误差，联合决定 `g`、LUT 量化位宽和是否启用快速聚合？

#### 与原论文的区别

原论文主要通过硬件经验和调优寻找配置；新方向将性能—精度约束显式纳入编译器决策。

#### 可能的创新点

多目标 cost model、按层选择 LUT 配置、误差预算传播和自动生成运行时配置。

#### 实验框架

```text
模型层与硬件特征
        ↓
编译器 cost model 选择 g / 量化 / 聚合
        ↓
生成内核并测量
        ↓
性能—能耗—困惑度 Pareto 前沿
```

#### 可行性

可从现有 T-MAC kernel 和 TVM/AutoTVM 调优接口开始，使用论文相同模型和设备复现实验。

#### 主要风险

层级误差可能累积，单个 GEMV 的 NMSE 不一定能预测完整模型质量。

### 11.3 CPU 与异构加速器的运行时切分

#### 研究问题

当 CPU LUT 内核、GPU/NPU 内核和内存带宽共享时，运行时如何按层、位宽和 batch/sequence 状态选择执行设备？

#### 与原论文的区别

T-MAC 主要证明 CPU 内核在若干设备上有优势；新方向关注在线设备选择和异构资源协同，而不是单一 CPU 内核加速。

#### 可能的创新点

考虑统一内存、功耗上限、热状态和 token 阶段的运行时调度器，并用实测反馈更新选择策略。

#### 实验框架

```text
模型层 / 位宽 / token 阶段 / 设备状态
        ↓
运行时估计 CPU LUT、GPU、NPU 成本
        ↓
分层执行与内存复用
        ↓
在线测量吞吐、延迟、能耗和质量约束
```

#### 可行性

需要 T-MAC CPU 后端、至少一个 GPU/NPU 后端、统一内存设备和可重复的功耗采样接口。

#### 主要风险

设备切换和数据搬运可能抵消内核收益；NPU 性能数据若来自厂商报告，也必须与实测分开。

## 12. 与其他已读文献的关系

本 slot 本轮只完成 T-MAC 一篇全文阅读，未在同一批次内完成另一篇 EuroSys 2025/2026 论文的全文核验。因此不能据此虚构与其他论文的实验或方法关系。

与仓库中已有的 TVM 论文相比，T-MAC 是面向低比特 LLM CPU 推理的具体内核与系统集成案例；与已有 GPU/NPU kernel 论文的潜在关系只能作为后续横向比较方向，当前笔记不把它们写成已完成的对照实验。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 低比特 LLM 的 CPU 混合精度推理内核与系统 |
| 核心问题 | 绕过反量化，统一支持多位宽权重与高精度激活 |
| 输入 | 低比特权重、较高精度激活、模型矩阵形状 |
| 输出 | LUT 查表加法形式的 CPU GEMV/GEMM 内核和端到端推理系统 |
| 核心方法 | 位串行分解、LUT、片上布局、tiling、置换、交错、TVM/LLVM 代码生成 |
| 使用的模型 | Llama-2 低比特模型、BitNet、Llama-2-7B GGUF |
| 使用的编译器工具 | TVM、LLVM、AutoTVM、llama.cpp |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用代数等价、NMSE 和模型质量评测 |
| 数据集规模 | 训练数据集规模不适用；评测使用模型和矩阵形状，具体形状见正文图 6/7 |
| 主要指标 | kernel latency、tokens/s、功耗、J/token、NMSE、困惑度、准确率 |
| 最重要实验结果 | 内核最高 11.2× 加速；端到端最高报告 6.7×；M2 Ultra 部分模型能耗下降 61.2% |
| 核心创新 | 面向 CPU 的统一位级 LUT 混合精度计算与编译器/运行时集成 |
| 主要局限 | LUT/寄存器压力、带宽瓶颈、快速聚合精度损失、对特定 CPU intrinsic 依赖 |
| 与 RISC-V 研究的相关性 | 中：可启发 RVV LUT 后端，但论文没有 RISC-V 实验，不能直接声称可迁移 |
| 最适合作为 | 传统编译器/运行时内核优化 baseline、TVM/LLVM 后端参考和异构推理工具模块 |

> 这篇论文最值得学习的是把位级代数变换、缓存/寄存器布局、硬件 intrinsic 和运行时集成作为一个整体设计；最主要的局限是效果依赖设备微架构、带宽和可用查表指令。用于后续研究时，最合理的方式是把它作为低比特内核与编译器后端 baseline，再研究 RVV 或异构运行时中的新代价模型，而不是简单把 CPU 平台名称替换为 RISC-V。
