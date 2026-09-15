# CINM（Cinnamon）文献阅读总结

论文题目：**CINM (Cinnamon): A Compilation Infrastructure for Heterogeneous Compute In-Memory and Compute Near-Memory Paradigms**

Paper_ID：C72

作者：Asif Ali Khan、Hamid Farzaneh、Karl F. A. Friebel、Clément Fournier、Lorenzo Chelini、Jeronimo Castrillon

发表时间：2025

发表平台：ASPLOS 2025，Proceedings of the 29th ACM International Conference on Architectural Support for Programming Languages and Operating Systems，Volume 4，pp. 31–46

论文链接或编号：[ASPLOS 2025 官方议程](https://www.asplos-conference.org/asplos2025/program.html)；[ACM DOI](https://doi.org/10.1145/3622781.3674189)；[arXiv:2301.07486](https://arxiv.org/abs/2301.07486)

关键词：MLIR、多级中间表示、CINM、计算存储器（CIM）、近存计算（CNM）、UPMEM、memristor、异构编译

> 本文档依据本地 16 页 PDF 的正文阅读整理。论文事实、阅读后的分析和后续建议分开描述；实验数字均保留论文的对比对象、配置和统计口径。

---

## 1. 研究背景

论文关注数据密集型应用在传统 von Neumann 架构上的数据搬移瓶颈。引言指出，处理器与内存之间的窄通道会限制性能和能效；论文引用的移动设备研究称，仅数据移动就可能占系统总能耗的 62%。计算近存（Compute Near-Memory，CNM）把计算单元放到内存附近，计算存储器（Compute In-Memory，CIM）则利用存储器物理特性直接在存储阵列内执行部分计算。

CIM/CNM 设备的计算能力、存储层次、可重配置粒度和可支持操作差异很大。UPMEM 需要程序员处理大量 DPU 的负载均衡、CPU/WRAM/MRAM 之间的数据移动和同步；memristor crossbar 等 CIM 设备又有固定阵列尺寸、写入代价和设备寿命约束。现有软件栈通常暴露设备专用的低层 API，或者只面向单一架构/单一应用领域，难以支持未来由 CPU、GPU、DPU、CIM 和 CNM 组成的异构系统。

论文因此引入基于 MLIR（Multi-Level Intermediate Representation，多级中间表示）的统一编译基础设施，通过逐级 lowering（逐级降低抽象层次）在设备无关和设备相关层次分别进行优化。

## 2. 论文要解决的问题

### 2.1 跨 CIM/CNM 设备的统一编程抽象

论文要解决不同 CIM/CNM 架构使用不同低层库和编程接口的问题，使输入程序不必直接编码设备 API、线程编号和物理内存细节。

### 2.2 在不同抽象层执行设备相关优化

论文希望在高层计算模式、中层内存/并行层次和低层设备接口之间保留足够信息，从而支持目标选择、tiling（分块）、循环变换、数据布局和设备资源映射。

### 2.3 面向未来异构系统的可扩展 lowering

论文希望新增设备时主要添加设备方言和转换 pass，而不是修改所有高层表示。当前工作重点是 memristor-based CIM 和 UPMEM CNM，论文将更完整的自动代价模型、搜索和多设备实测留作后续工作。

> 本文主要研究：如何用 MLIR 的分层抽象，把高层程序渐进降低为面向多个 CIM/CNM 目标的可执行代码，并在 lowering 过程中实施设备无关和设备感知优化。

## 3. 核心方法概述

CINM（Cinnamon）以 `cinm` 方言作为跨设备抽象入口，接收 `linalg`、TOSA 或 Torch 等高层表示，再根据目标设备降低到 `cim`、`cnm`、`affine` 等方言。设备方言负责把公共操作转换为 UPMEM runtime/API 或 memristor 设备函数调用，最后通过 `scf`、LLVM 方言和 host/device backend 生成目标代码。

```text
高层输入（linalg / TOSA / torch）
        ↓
cinm：统一操作集合、候选目标选择、重写
        ↓
cnm / cim / affine：设备范式抽象、工作组/设备资源、分块与专用优化
        ↓
设备方言（UPMEM / memristor）
        ↓
scf / LLVM IR / host backend + device API
        ↓
CPU+UPMEM 代码或 CPU+memristor-CIM 代码
```

`cinm` 暴露加减乘除、位运算、GEMV/GEMM、转置、归约、scan、top-k、相似度搜索等可被 CIM/CNM 共同或分别支持的操作。复杂操作可以先改写，例如卷积通过 im2col、collapse 和 GEMM 变成更适合 CIM/CNM 的形式。`cnm` 抽象工作组、层次化内存、scatter/gather、launch 和同步；`cim` 抽象设备 acquire、read/write、execute、barrier、release，并针对固定 crossbar 尺寸进行分块。

论文的最终系统角色不是语言模型输出，而是传统编译器基础设施。因此按 taxonomy v2 归入 `SUPPORTING / B2_Compiler_Infrastructure`。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT、PPO、GRPO 或其他强化学习训练，主要采用 MLIR 编译流程、规则化 lowering、设备方言转换和运行/仿真评测。

### 4.1 编译执行流程

1. 从 `linalg`、TOSA、Torch 等高层表示进入 `cinm`；不支持的高层操作先做 canonicalization 或重写。
2. `cinm` 根据用户目标或当前实现的启发式分析选择 offloading 目标。论文给出的当前机制是：大尺寸 matmul-like 操作或可重写为 matmul 的操作贪心选择 CIM；卷积/contract 使用 OCC 的识别算法；其他操作默认选择 UPMEM。
3. `cinm` 降低到 `cnm`、`cim` 或 `affine`。`cnm` 处理工作组、层次化内存和数据搬移；`cim` 处理设备占用、固定阵列分块、写入与执行。
4. 设备方言应用 tiling、循环展开、循环交换、局部性和写次数优化，并发出设备库调用或 host 指令。
5. 通过 `scf` 和 LLVM 方言生成低层代码，链接 host backend、device API 和 runtime。

### 4.2 代价模型与自动策略状态

论文设计了可注册的 cost-model 接口，使设备方言可以向 `cinm` 提供目标选择和优化代价估计。但论文明确说明，当前工作没有实现 policy automation；由于目标设备缺少可比较的 cost model，现有 offloading 仍使用用户指定目标或启发式规则。自动搜索和更细粒度的多设备映射属于未来方向。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数，也没有模型训练损失函数。

论文中一个关键的工作组重排例子是：对

```text
x[i,j,k] = A[i,r] * B[r,j,k] + C[j,k]
```

原始工作组维度 `(i, j, k)` 可以合并/交换为 `(h, i)`，其中 `h = coalesce(j, k)`。论文称该变换把工作集内存占用从 `M(P + N O (P + 1))` 改为 `N O (M P + P + 1)`，其价值取决于 `M、N、O、P` 和目标设备内存层次。

论文还报告了设备相关的固定约束：CIM crossbar 的阵列尺寸决定 compulsory tiling；NVM 写入通常慢且影响寿命，因此 tiled loop interchange 可减少写次数；UPMEM 的 tasklet 数量与 WRAM 分配会影响运行性能。

## 6. 实验设置

### 6.1 数据集来源

论文没有使用机器学习训练数据集。实验使用两组程序基准：

| 基准 | 来源与内容 | 用途 |
|---|---|---|
| OCC/CIM workloads | 沿用 OCC 的 memristor-CIM 相关 ML 和张量内核，包括矩阵乘、连续矩阵乘、卷积、contraction、MLP 等 | 比较 CIM 代码和 ARM host baseline，观察 tiling、减少写入和并行展开的影响 |
| PrIM | 论文引用的公开 CNM 基准套件，覆盖线性代数、数据库、数据分析、图处理、生物信息和图像处理 | 在真实 UPMEM 系统上与手工优化的 PrIM 代码比较 |

PrIM 共涉及 9 个类别；作者为减少工程工作，从 7 个类别各选一个 benchmark，未处理生物信息和稀疏矩阵乘法两个只含单个 benchmark 的类别。非 PrIM 工作负载主要从 PyTorch 通过 `torch-mlir` 进入 MLIR；部分非 idiomatic PrIM benchmark 采用手工翻译。所有工作负载使用 INT32。论文没有把这些基准描述为训练/验证/测试划分，也没有给出数据泄漏分析。

### 6.2 模型与工具

论文使用的硬件和工具包括：

- host：Intel Xeon E5-2630 v2 @ 2.60 GHz，2 个 socket、每 socket 6 核、128 GB DRAM、Ubuntu 22.04；CPU baseline 使用 Intel oneAPI DPC++/C++ Compiler 2023.1.0，并开启 loop unrolling、tiling、vectorization 和 parallelization。
- CNM：真实 UPMEM 机器，16 个 DIMM；每个 DIMM 16 个芯片，每芯片 128 个 DPU；每个 DPU 为 350 MHz、64 MB MRAM 和 64 kB WRAM，使用 16 tasklets 的配置参与主要比较。
- CIM：扩展 gem5 全系统仿真；四个 64×64 PCM-based memristor tiles，使用 ARMv8-A in-order host core，读写延迟和能耗取自论文引用的器件研究。
- 编译基础设施：MLIR、`linalg`、TOSA、Torch/Torch-MLIR、`scf`、LLVM 方言、UPMEM SDK/API、OCC 的转换和分析流程。

### 6.3 对比方法

- `cpu-opt`：启用多种传统编译优化的 Intel CPU host baseline。
- `cinm-nd`：CINM 生成的 UPMEM 代码，进行并行 DPU 执行和基础 tiling。
- `cinm-opt-nd`：在 CINM 中增加面向 WRAM 局部性的 tiling 和 tiled-loop interchange。
- `prim-nd`：PrIM 论文提供的手工优化 DPU 代码。
- CIM 侧的 `cim`、`cim-min-writes`、`cim-parallel`、`cim-opt`：依次加入固定阵列 tiling、减少写入的循环交换、内层循环展开，以及全部 CIM 优化。

### 6.4 评价指标

- 执行时间：毫秒或秒；越小越好，图 11/12 对部分结果使用对数坐标。
- Speedup：相对于图中指定 CPU 或配置的执行时间比；越大越好。
- Energy consumption：相对于 host CPU 的能耗比；越小越好。
- LoC：CINM MLIR 与 UPMEM C/C++ 实现的代码行数对比，用于展示编程生产率，不等价于严格的开发成本测量。
- 统计口径：论文称结果为 10 次执行的 geometric mean；仿真和真实机器结果必须按各自配置理解，不能混称为统一真实硬件测量。

## 7. 实验结果与结论

### 7.1 CIM 主要结果

在论文 Figure 10 的 CIM 工作负载、相对于 ARM host CPU 的几何平均结果中：

- 基础 `cim` 配置相对 CPU 达到约一个数量级的性能提升。
- `cim-min-writes` 将写入次数降低约 7 倍，并报告平均 12.4× 的性能增益。
- 同时启用循环交换与循环展开的 `cim-opt` 报告 30× 性能增益。
- `cim-opt` 相对 host CPU 的几何平均能耗降低 5×；但 `mv`、`conv` 等操作因操作数搬移较慢、阵列复用不足，能耗分别比 CPU baseline 高 30% 和 40%。

这些 CIM 结果来自 gem5 中的 PCM-based memristor 加速器配置，不是统一的真实 CIM 芯片实测。

### 7.2 UPMEM 设备感知优化

Figure 11 比较了 `cinm-nd` 与 `cinm-opt-nd`。在 4、8、16 个 DIMM 配置下，`cinm-opt` 相对各自基础 `cinm-nd` 的几何平均执行时间分别快 47%、42% 和 40%。论文指出，3mm 相比 2mm 的增益较小，原因是第三个 GEMM 依赖前两个 GEMM 的结果，需要 host 在 offloading 前插入同步屏障。

### 7.3 与 CPU 和 PrIM 的比较

在 Figure 12 的 PrIM 工作负载比较中，`prim-4d`、`prim-8d`、`prim-16d` 相对于 `cpu-opt` 的执行时间分别约为 1/1.9、1/3.1、1/5.1。

相对于相同 DIMM 数的 `prim-nd`，CINM 生成代码的平均执行时间分别少约 1.6×、1.9×、2×（4、8、16 DIMM）。总体上 `cinm-nd` 平均约比 `prim-nd` 好 1.23×；在 histogram-long（`hst-l`）上，CINM 的 4/8/16 DIMM 执行时间为 0.623/0.311/0.155 s，平均比对应 PrIM 配置少约 3.7×。作者把优势主要归因于对 WRAM 的更有效利用、分块形状和 partial-result accumulation。

### 7.4 编程生产率与消融性质的比较

Table 4 给出 16 个应用的代码行数对比。按论文的平均统计，idiomatic CINM 表示比低层 UPMEM C/C++ 代码约简洁 15×；例如 `conv` 为 5 行对 203 行，`mm` 为 7 行对 180 行。作者同时提醒，不同编程模型之间直接比较 LoC 可能会误导。

论文没有给出传统意义上独立命名的消融表，但 Figure 10 的 `cim`、`cim-min-writes`、`cim-parallel`、`cim-opt` 逐步加入写入减少和并行展开，可视为设备优化组件的分阶段比较。论文没有比较 LLM 方法。

## 8. 主要创新点

### 8.1 创新点一：跨 CIM/CNM 的 MLIR 分层编译框架

以往相关工作通常针对单一设备、单一领域或单一设备库。CINM 用 `cinm`、`cim` 和 `cnm` 方言把共同操作、范式级资源和设备级实现分层，允许同一高层输入面向 memristor CIM 与 UPMEM CNM 走不同 lowering 路径。论文的 Table 5 将这种设备无关输入、层次化和可复用性作为与既有系统的差异维度。

### 8.2 创新点二：把设备感知变换放入对应抽象层

`cnm` 层处理工作组和层次内存，`cim` 层处理 crossbar tiling、写入次数和并行 tile，设备方言再把抽象操作映射到具体 API。这样既避免把设备细节暴露给高层输入，又保留了执行设备相关优化所需的信息。

### 8.3 创新点三：面向扩展的设备方言接口

论文说明，加入例如 FIMDRAM 的新目标主要需要新增设备方言及其从 `cnm` 的转换；如果新设备已有 `cinm` 操作覆盖，较高层抽象无需修改。这是编译器基础设施的可复用性设计，而不是已经覆盖所有 CIM/CNM 设备的实现结果。

### 8.4 创新点四：在真实 UPMEM 和 CIM 仿真上验证统一框架

论文不只展示 IR，还在真实 UPMEM 机器和 gem5 CIM 仿真上评测生成代码，并相对 CPU、OCC 和 PrIM 给出性能、能耗和代码行数结果，说明该抽象可以落到具体 runtime/backend。

## 9. 局限性

### 9.1 论文明确承认的局限

- 当前实现只覆盖 memristor-based CIM 和 UPMEM CNM；选择这些目标受可用于评测的开源基础设施限制。
- 作者明确说当前没有实现 policy automation；`cinm` 的自动目标选择依赖启发式规则，完整 cost model 和搜索机制留作未来研究。
- 实验系统是 host CPU 加一个 CIM/CNM 目标，作者明确说明没有可用于评测的多设备异构 setup，因此尚未展示 CPU、GPU、DPU、CIM/CNM 同时协同执行的实测。
- 复杂操作的目标选择需要识别、重写和比较代码变体；在没有 cost model 时，当前机制不能证明是全局最优映射。
- PrIM 中一部分非 idiomatic benchmark 需要手工翻译，且作者只选择 7/9 类，覆盖范围并非完整套件。

### 9.2 阅读后发现的潜在局限

- `cinm` 目标选择的默认策略把不能识别或不能改写的操作放到 UPMEM，可能偏向当前实现可表达的 kernel，而不是对任意程序保持公平比较。
- CIM 结果依赖 gem5、器件延迟/能耗参数和特定四 tile 结构，不能直接等价为真实芯片上的端到端收益。
- 代码行数减少反映抽象层次和 API 细节隐藏，不足以单独证明调试、编译时间、运行时维护成本降低。
- 论文主要验证 tensor/数据密集型和若干 PrIM workload；对复杂控制流、跨函数优化、动态形状和更广泛编程语言的支持，论文中未明确说明。
- 论文提出可扩展到更多设备，但新增设备所需的具体工程量、自动验证方式和跨设备 cost-model 标定过程，当前 PDF 内容不足以确认。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把硬件差异放在分层 IR 和设备方言中，而不是把目标设备 API 直接暴露给源程序；这对 LLVM/MLIR 上的多硬件 lowering、RISC-V 后端扩展和异构 runtime 接口设计都有参考价值。另一个可借鉴点是让 cost model 作为可注册接口参与目标选择，而不是把映射启发式写死在高层编译器中。

### 10.2 不能简单照搬的部分

把 UPMEM 换成 RISC-V 或把 memristor 换成另一种加速器，本身只是平台迁移，不足以构成新的方法贡献。CINM 的核心贡献是抽象边界、方言职责和 lowering 机制；后续工作需要在新的内存一致性、数据布局、能耗/寿命约束或跨设备调度问题上提出可验证的新机制。

### 10.3 与现有研究方向的关系

论文与 LLVM/MLIR、异构编译和多硬件 lowering 直接相关，与 LLM 编译优化没有直接关系。它适合作为 `SUPPORTING / B2_Compiler_Infrastructure` 中的多硬件编译框架参考，或作为后续 selector/cost-model 研究的目标执行基础设施，而不是 LLM baseline。

## 11. 可进一步尝试的研究方向

### 11.1 面向 CIM/CNM/RISC-V 的可校准跨设备代价模型

#### 研究问题

如何用统一的计算、数据移动、同步、能耗和 NVM 写入寿命特征，在不同 CIM/CNM/RISC-V 设备间做可解释的 kernel/region 映射。

#### 与原论文的区别

CINM 只提供 cost-model 接口，当前主要使用启发式 offloading；该方向把接口落实为可校准模型，并研究模型误差对映射的影响。

#### 可能的创新点

构建跨设备特征规范、将写入寿命和同步开销纳入统一目标、并用真实硬件/仿真联合校准。

#### 实验框架

```text
MLIR/CINM IR → 静态特征提取 → 设备代价预测 → 目标/分块选择
        → 真实硬件或周期级仿真 → 误差反馈与模型校准
```

#### 可行性

可复用 MLIR 方言、UPMEM 和 gem5/CIM 环境，并加入 RISC-V CPU 或加速器后端。

#### 主要风险

不同设备指标不可直接比较；真实器件参数、动态 contention 和 cost-model 数据规模可能不足。

### 11.2 细粒度多设备异构 lowering 与运行时调度

#### 研究问题

如何把一个 kernel 内不同 region 同时映射到 CPU、RISC-V、UPMEM 和 CIM/CNM，而不是只选择一个 offloading 目标。

#### 与原论文的区别

原论文提出这种扩展方向但没有多设备实测；该方向需要处理跨设备同步、数据一致性、分片和 runtime 调度。

#### 可能的创新点

让 `cinm`/`cnm`/`cim` 的 lowering 产出显式通信图，并联合优化 kernel 分割、数据放置和同步。

#### 实验框架

```text
高层 IR → region 划分 → 多设备代价搜索 → 通信/同步图生成
        → 设备方言 lowering → 异构 runtime 执行 → 端到端性能评测
```

#### 可行性

可先从 CPU+RISC-V+UPMEM 的可控组合开始，再加入 CIM 仿真。

#### 主要风险

跨设备通信可能抵消加速收益；正确性和同步 bug 难以通过局部测试发现。

### 11.3 面向 NVM 写入寿命的编译优化

#### 研究问题

在满足执行时间约束的同时，如何系统性降低 CIM NVM 写入次数并平衡阵列寿命、能耗和性能。

#### 与原论文的区别

原论文通过 tiled-loop interchange 展示减少写入的效果，但没有建立寿命感知的长期优化目标。

#### 可能的创新点

把写入次数、写入位置不均衡、可靠性和性能纳入 MLIR pass 的联合 cost model，并提供可解释的变换选择。

#### 实验框架

```text
CIM IR → 写入/复用分析 → 候选 loop/layout 变换
       → 性能与写入寿命估计 → Pareto 选择 → 设备仿真验证
```

#### 可行性

可基于论文的 `cim` 方言和四 tile 仿真配置实现原型。

#### 主要风险

器件寿命模型和写入能耗参数可能不稳定；减少写入可能增加数据搬移和计算时间。

## 12. 与其他已读文献的关系

本批次只有 C72 一篇论文，因此没有其他“当前批次已读文献”可以建立实证性的横向比较。就论文正文的相关工作而言，CINM 与 MLIR 及多级 IR 方向关系最直接；与 OCC、C4CAM、PIMFlow、XLA-NDP、Infinity Stream 等系统相比，论文强调其同时覆盖 CIM/CNM、提供多个抽象层并支持设备方言扩展。上述比较是论文作者在 Related Work 和 Table 5 中的定位，不代表本笔记对这些相关工作的独立全文复核。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 为异构 CIM/CNM 设备建立基于 MLIR 的端到端编译基础设施 |
| 核心问题 | 设备专用低层 API 难编程，现有编译器难跨设备复用和做设备感知优化 |
| 输入 | `linalg`、TOSA、Torch 等高层/领域 IR；部分工作负载由 PyTorch 进入 MLIR |
| 输出 | UPMEM CNM 代码、memristor-CIM host/device 代码和设备 API 调用 |
| 核心方法 | `cinm`/`cnm`/`cim` 方言、渐进式 lowering、设备方言、tiling/loop interchange/unrolling |
| 使用的模型 | 无机器学习模型；本文不涉及模型训练 |
| 使用的编译器工具 | MLIR、Torch-MLIR、LLVM 方言、UPMEM SDK、OCC、gem5 |
| 是否使用强化学习 | 否；不存在强化学习奖励函数 |
| 是否使用形式化验证 | 论文中未明确说明形式化验证；主要使用运行/仿真和基准比较 |
| 数据集规模 | 无训练数据集；使用 OCC/CIM workloads 和 PrIM 基准，PrIM 选取 7/9 类代表 workload |
| 主要指标 | 执行时间、speedup、能耗、代码行数；性能结果通常为 10 次运行的几何平均 |
| 最重要实验结果 | CIM `cim-opt` 相对 ARM host 报告 30×性能增益和 5×能耗降低；UPMEM 上 CINM 平均比 PrIM 快约 1.6×/1.9×/2×（4/8/16 DIMM） |
| 核心创新 | 用可复用的 MLIR 分层抽象统一 CIM/CNM，并把设备相关优化隔离在对应 lowering 层 |
| 主要局限 | 当前没有完整 cost model、自动策略或多设备异构实测；目标设备和 benchmark 覆盖有限 |
| 与 RISC-V 研究的相关性 | 中：论文不以 RISC-V 为主，但其 MLIR 方言、设备 lowering 和 CNM 内存层次可作为 RISC-V 异构后端基础设施参考 |
| 最适合作为 | 多硬件编译框架、MLIR 方言设计和异构 cost-model 研究的基础设施参考 |

这篇论文最值得学习的是如何用分层 IR 隔离设备差异并保留设备感知优化空间；最主要的局限是自动目标选择和真正多设备异构执行仍未完成。如果用于后续研究，最合理的方式是把 CINM 的抽象和 lowering 作为基础设施，再研究可校准代价模型、跨设备调度或 NVM 寿命约束，而不是简单替换成另一种硬件平台。
