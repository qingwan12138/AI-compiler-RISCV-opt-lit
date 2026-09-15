# CODO 文献阅读总结

论文题目：**CODO: An Automated Compiler for Comprehensive Dataflow Optimization**

作者：Weichuang Zhang、Yiquan Wang、Xinzhou Zhang、Chi Zhang、Yu Feng、Xiaofeng Hou、Chao Li、Jieru Zhao、Minyi Guo

发表时间：2026

发表平台：ISCA 2026（第 53 届 ACM/IEEE International Symposium on Computer Architecture）；当前通读版本为作者公开的 arXiv 版本，含 artifact appendix。

论文链接或编号：[arXiv:2604.12618](https://arxiv.org/abs/2604.12618)；DOI：10.1109/ISCA66397.2026.00018

关键词：MLIR、FPGA、数据流编译器、HLS、FIFO、乒乓缓冲、自动调度、DNN 加速器、GPT-2

> 事实主要依据作者公开 PDF 正文。本文是 ISCA 2026 范围内的新候选，不分配正式 Paper_ID，不修改 taxonomy、索引或年份清单。

## 1. 研究背景

CODO 研究 FPGA 上的数据流加速器编译。数据流架构通过任务级流水，让不同函数或循环重叠执行，并用片上通信减少外部内存访问。FPGA 的可重构逻辑和可定制数据路径适合实现流式、流水化计算，但直接用 HDL 开发复杂且耗时，因此实践中常用高层综合（High-Level Synthesis，HLS）把 C/C++ 转为硬件实现。

论文指出，HLS 并没有消除高效数据流设计的主要困难。商业 HLS 工具提供 `dataflow` pragma，但要求输入代码满足严格的单生产者-单消费者结构、顺序访问和计数一致性。现实中的 DNN、线性代数和图像处理代码经常违反这些条件，导致设计只能串行执行、产生流水线气泡、出现 FIFO 死锁，甚至综合失败。开发者需要手工重构代码、指定缓冲区和调度策略，过程容易出错。

已有 FPGA 编译器分别改善 DSL 表达、循环优化、数据流或自动调度，但通常把正确性、通信和并行性分开处理。论文的核心判断是：三者存在代码级耦合，单独优化一个方面可能破坏另一个方面。例如，为了满足数据流约束而改写循环可能使访存低效；并行化或缓冲优化也可能重新引入数据流违规。

## 2. 论文要解决的问题

### 2.1 粗粒度数据流违规

商业 HLS 工具倾向于要求单生产者-单消费者。真实程序可能出现单生产者多消费者、多生产者单消费者和多生产者多消费者。论文要自动识别这些访问图模式，并通过节点插入、缓冲复制或节点融合等方式消除违规。

### 2.2 细粒度数据流违规

即使任务图满足粗粒度约束，生产者和消费者仍可能以不同顺序或不同次数访问同一个数组。FIFO 要求顺序访问、读写计数一致，否则可能出现数据丢失、FIFO 上溢/下溢或死锁。论文要自动分析和改写归约循环及循环嵌套顺序，使相邻任务能够使用 FIFO。

### 2.3 通信和并行性协同优化

论文还要自动选择 FIFO 或乒乓缓冲，生成复用缓冲区，管理 HBM 到片上存储的数据传输，并在循环分块、流水化、展开和数组分区之间搜索资源受限的并行方案，同时避免破坏之前修复的数据流约束。

> 本文主要研究：如何以 MLIR 为基础，将输入的 C++/PyTorch 计算程序自动转换为满足数据流正确性、通信效率和资源约束的 FPGA HLS 加速器。

## 3. 核心方法概述

CODO 是一个端到端的自动编译器。它先把 C/C++ kernel 或 PyTorch 模型转换到 MLIR，再以 affine dialect 为主要优化表示。编译器用模式感知变换修复粗粒度违规，用归约重写和 permutation map 修复细粒度违规；随后选择通信缓冲、生成 line/window reuse buffer、管理 HBM burst transfer，最后做资源感知的数据流调度和跨任务协同。

```text
C++ kernel / PyTorch model
        ↓ Polygeist / Torch-MLIR
MLIR linalg / affine IR
        ↓ 粗粒度违规消除
        ↓ 细粒度违规消除：归约重写 + 循环排列映射
FIFO / ping-pong 缓冲决定
        ↓ 复用缓冲区生成 + HBM 数据传输管理
资源感知并行探索：tiling / pipeline / unroll / array partition
        ↓ 跨任务策略传播并再次检查违规
MLIR lowering
        ↓
HLS C++ kernel + host code
        ↓ Vitis HLS / Vivado 综合与板上执行
FPGA 数据流加速器
```

LLM 在本文中不是系统组件；GPT-2 只是被编译和评测的工作负载。编译器工具包括 MLIR、Polygeist、Torch-MLIR、Vitis HLS 和 Vivado。CODO 的 `codo-opt` 命令执行完整优化流程，用户可以指定最大并行度和 tiling 参数。

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用静态编译、代码变换、设计空间探索（Design Space Exploration，DSE）和 HLS/FPGA 执行评测。

### 4.1 前端与 IR 转换

C/C++ kernel 通过 Polygeist 转为 MLIR affine dialect；PyTorch 模型通过 Torch-MLIR 进入 linalg dialect，先使用 MLIR 的算子融合和 bufferization，再 lower 到 affine dialect。CODO 主要面向常量循环边界的 affine 程序，覆盖卷积、attention、ReLU、GeLU、矩阵乘、点积等模式。

### 4.2 正确性与通信阶段

编译器依次执行粗粒度违规消除、细粒度违规消除、通信缓冲决定和复用缓冲生成。复用缓冲生成后会重新调用正确性 pass，避免新的数据流违规。CODO 默认在没有细粒度违规时优先使用 FIFO；无法消除的违规则退回乒乓缓冲。

### 4.3 并行搜索与代码生成阶段

并行探索分三步：先基于 profiling 性能模型分配初始并行度；再提升瓶颈循环的并行度；最后下调明显过度优化的循环以降低资源使用。之后把瓶颈循环的 tiling、unroll 和 array partition 策略传播到相连生产者/消费者，并重新检查违规。最终输出 host code 和 HLS C++ kernel。

### 4.4 验证方式

MLIR 内置验证检查 dominance、SSA 一致性和类型正确性；`canonicalize` 与 CSE 消除死代码和冗余计算。功能正确性沿用 StreamHLS 的验证流水线，自动生成 testbench，并将加速器输出与原始程序的 golden result 比较。论文还报告 AMD Alveo U280 的板上执行结果。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数、PPO、GRPO 或 SFT 损失函数。核心优化目标是编译器 DSE 中的延迟、资源和数据流可行性之间的工程权衡，而不是一个由神经网络训练的统一损失。

论文明确给出的关键计算定义包括：

| 项目 | 论文中的含义 |
| --- | --- |
| Latency speedup | Vitis HLS 优化代码的时钟周期数除以框架优化代码的时钟周期数；越大越好 |
| FIFO / ping-pong 选择 | 无法消除细粒度违规时使用 ping-pong，否则优先 FIFO；FIFO 通常延迟更低、片上存储需求更小 |
| 并行度阈值 `n` | 上调或下调循环并行度时的平衡阈值，论文经验设置为 2.0 |
| 资源感知搜索 | 在 DSP、BRAM、FF、LUT 资源约束下搜索 tiling、pipeline、unroll、array partition 组合 |

并行探索先用 profiling 得到基本操作的延迟和资源参数，再按循环延迟比例分配并行度；论文没有给出一个需要训练的显式总目标函数。对于更细的 DSE 打分公式，当前 PDF 内容不足以确认该信息。

## 6. 实验设置

### 6.1 数据集来源

本文使用程序和模型工作负载，而非训练数据集。典型 kernel 来自 PolyBench，并加入常见深度学习模型；DNN 评测包括 ResNet-18、VGG-16、MobileNet、ZFNet 和 YOLO；LLM 评测使用 GPT-2 Medium。论文未报告训练集、验证集或测试集规模，也没有数据清洗流程。输入路径包含 C/C++ kernel、PyTorch 模型、MLIR affine IR 和生成的 HLS C++。

### 6.2 模型与工具

主要环境如下：

| 项目 | 设置 |
| --- | --- |
| 编译基础设施 | MLIR；Polygeist；Torch-MLIR |
| HLS/综合工具 | Xilinx Vitis HLS 2023.2、Vivado 2023.2 |
| FPGA | AMD Alveo U280；9024 DSP、2.6M FF、1.3M LUT、4032 BRAM18K |
| 目标频率 | 300 MHz；GPT-2 对比中其他框架使用各自报告的平台频率 |
| 运行环境（artifact appendix） | Ubuntu 20.04.6 LTS；CMake 3.20.3 或兼容版本 |
| 设计输出 | HLS C++ kernel、host code、FIFO/乒乓缓冲和 HBM burst 传输 |

### 6.3 对比方法

综合和模型实验比较 ScaleHLS、POM、Allo、HIDA、StreamHLS、StreamTensor；GPT-2 还比较 DFX。它们分别代表 MLIR/HLS 框架、循环与资源优化、FIFO 数据流、层次化数据流、自动数据流优化、LLM 数据流优化和手工优化的 FPGA 实现。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Latency / cycles | HLS 综合报告中的周期数或板上执行延迟 | 越小越好 |
| Speedup | 相对于指定 baseline 或比较框架的加速比 | 越大越好 |
| Compilation time | 优化、DSE 和代码生成总时间 | 越小越好 |
| DSP、BRAM、FF、LUT utilization | FPGA 资源占用率 | 在性能足够时越低越好 |
| Power / energy | 板上功耗与能耗 | 越低越好 |
| GPT-2 TTFT | 首 token 时间 | 越低越好 |
| GPT-2 decoding speed | token/s | 越高越好 |
| FIFO percentage | 工作负载中使用 FIFO 的比例 | 越高通常说明可流式化程度越高 |

## 7. 实验结果与结论

### 7.1 主要结果

在典型 kernel 级应用上，表 II 报告的几何平均 speedup 为：CODO 292.1×、StreamHLS 200.9×、Allo 64.7×、HIDA 91.8×。该 speedup 是各框架优化代码相对于 Vitis HLS baseline 的周期数比值，所有框架使用 DSP=900 的相同资源预算。

在 DNN 综合实验中，论文报告 CODO 相对于 ScaleHLS、POM、Allo 和 HIDA 的平均 speedup 分别为 33.8×、13.6×、3.7× 和 7.1×。表 III 使用 3×32×32 输入，表 IV 使用 3×224×224 输入（YOLO 为 3×1280×384）。例如表 IV 的 ResNet-18 中，CODO 为 4.76M cycles、466.5× speedup，HIDA 为 74.85M cycles、29.7×；VGG-16 中 CODO 为 7.85M cycles、601.8×，HIDA 为 56.93M cycles、83.0×。

### 7.2 与传统编译器/框架的比较

CODO 的优势来自联合处理正确性、通信和并行性。ScaleHLS/HIDA 主要使用乒乓数据流，可能错过 FIFO；Allo 的调度依赖用户手工指定，复杂模型上容易出现次优 pipeline；StreamHLS 不能消除大型模型的全部违规；StreamTensor 在遇到细粒度违规时保守地退回乒乓缓冲。

在表 III/IV 中，CODO 通常以较低或相近资源占用取得更低延迟。论文将原因归结为 FIFO 只存储在途数据、比乒乓缓冲更节省 BRAM，以及下调非关键循环的并行度减少冗余资源。

### 7.3 板上评测

在 U280 板上，表 V 报告 CODO 相对于 baseline 的整体 speedup：ResNet-18（3×32×32）69.2×、VGG-16 51.0×、MobileNet 9.6×；在 3×224×224 输入下，ResNet-18 100.6×、VGG-16 127.5×、MobileNet 43.8×、ZFNet 110.7×。相对于 HIDA，CODO 在这些大输入模型上也更快。论文报告 CODO 平均能效相对于 baseline 和 HIDA 分别为 77.1× 和 9.2×，这里的能效比较来自板上功耗与执行时间测量。

YOLO 因 Vitis HLS 资源估计不准确而未能完成实现。StreamHLS 对评测工作负载不能生成有效设计；Allo 在部分场景因细粒度数据流违规死锁；ScaleHLS 因内存使用过高失败。

### 7.4 GPT-2 结果

GPT-2 Medium 的板上比较使用 DFX、Allo、StreamTensor 和 CODO。CODO 相对于 DFX、Allo 和 StreamTensor 的整体结果分别达到 3.54×、2.07× 和 1.23× 的速度优势（论文摘要强调 GPT-2 平均 2.07×，具体对比依赖平台和指标）。表 VI 中，在输入/输出长度 128/128 时，CODO TTFT 为 110.40 ms、解码速度为 231.48 token/s；对应 StreamTensor 为 125.35 ms、224.05 token/s，Allo 为 325.98 ms、204.05 token/s，DFX 为 692.80 ms、185.19 token/s。

### 7.5 消融实验

表 VII 的 Opt1-Opt5 逐步加入模块：Opt1 只有细粒度违规消除；Opt2 只有粗粒度违规消除；Opt3 加入高效数据通信；Opt4 再加入完整细粒度违规消除；Opt5 最后加入自动数据流调度。仅有细粒度优化时速度收益很小，因为粗粒度违规仍使数据流无效；粗粒度修复可带来 2.5×–9.7× 初始收益；复用缓冲对 ResNet-18、YOLO 等高数据复用工作负载有效；完整 FIFO 化最高可带来 105.8× speedup；Opt5 通过资源感知并行和跨任务优化进一步改善瓶颈不均衡。

### 7.6 案例与复现信息

表 VIII 给出的 FIFO 使用比例为：Gesummv 100%、Residual Block 100%、Multi-Head Attention 84%、MobileNet 100%、ResNet-18 100%、GPT-2 89%。论文解释 attention 和 GPT-2 的部分策略冲突会退回乒乓缓冲。artifact appendix 声明可复现表 II、III、IV 和图 11，共 82 个实验；所有综合实验约需 20 小时，且需要 Vitis/Vivado 工具和较大磁盘空间。板上全部 bitstream 的 artifact 评测不执行，因为生成所有 bitstream 需要超过两周和正确配置的 U280 环境。

## 8. 主要创新点

### 8.1 创新点一：粗粒度违规的模式感知变换

CODO 遍历缓冲区，收集所有访问节点并识别三类生产者-消费者模式，再选择节点插入、缓冲复制或节点融合。这个机制把原本需要开发者手工重构的任务图变换纳入编译器。论文通过复杂 DNN 和 GPT-2 的数据流结果证明其工程价值，但并未把这些变换宣称为对任意程序的完备证明。

### 8.2 创新点二：细粒度读写协调

论文把访问计数不一致归因到归约循环，把访问顺序不一致转化为循环深度映射问题。归约重写把归约维度移到内层并用临时数组聚合；permutation map 先对循环和数组维度建立深度映射，再排列目标循环。二者共同把更多连接转化为可用 FIFO，而不是发现违规后直接回退乒乓缓冲。

### 8.3 创新点三：无违规复用缓冲和通信协同

CODO 自动识别卷积、矩阵乘等计算密集模式，生成 line buffer 和 window buffer，并在生成后重新运行正确性 pass。复用缓冲不只是局部访存优化，而是和 FIFO 访问维度、后续并行化耦合。

### 8.4 创新点四：瓶颈中心的资源感知数据流调度

三阶段 PA/UP/DP 搜索先构造平衡的初始设计，再上调瓶颈循环，最后下调过度优化循环。跨任务优化会传播相邻 FIFO 端的策略并重新修复违规；策略无法兼容时，局部退回乒乓以保存其余 FIFO 数据流。论文的创新不在“使用 MLIR”本身，而在于把正确性、通信和并行性放在一个可回查的编译流程中协同处理。

## 9. 局限性

### 9.1 论文明确或实验暴露的局限

- CODO 目标是 affine 程序和常量循环边界，论文没有证明它能覆盖任意动态控制流、指针别名或复杂跨函数程序。
- YOLO 的板上实现因 Vitis HLS 资源估计不准确而失败，说明工具链估计误差仍会影响部署。
- 部分 attention 和 GPT-2 连接因优化策略冲突退回乒乓，FIFO 化不是普遍可达。
- artifact appendix 的完整综合复现需要 Vitis/Vivado、约 20 GB Docker 镜像、约 120 GB 工具空间，并可能耗时约 20 小时；板上全量复现未作为 artifact 评测执行。
- 论文对通用动态数据结构、非规则访存和运行时形状的支持范围未明确说明。

### 9.2 阅读后的潜在局限

- 论文主要用 U280 和 Xilinx 工具评估，跨 FPGA 厂商、跨 HLS 方言或 ASIC 后端的可迁移性尚未得到验证。
- MLIR 内置验证保证 IR 结构和类型合法，但这不等价于自动证明所有 FIFO 死锁不存在；功能正确性仍依赖 testbench 与 golden result，不能写成形式化语义证明。
- HLS synthesis latency、板上执行时间和综合 speedup 的口径不同，跨表比较时必须保持指标和 baseline 一致。
- 论文没有报告对输入形状、循环边界、别名或数据分布变化的系统鲁棒性分析，也没有把调度策略学习化，因此其适应性主要来自规则和搜索空间设计。

## 10. 阅读后的研究方向反思

CODO 对 AI 编译器研究的直接启发是：高层 IR 变换的正确性、通信结构和后端资源配置不应被当成互不相关的三个阶段。其 MLIR pass 化设计适合作为编译器基础设施参考，尤其适合研究“变换后重新检查约束”的闭环。

但 CODO 本身不是 LLM 编译器，也没有训练或智能体反馈。不能仅把 U280 替换成 RISC-V 加速器就声称形成新工作；这只是平台迁移。若用于 RISC-V，真正需要研究的是如何把 FIFO/片上 buffer/parallelism 约束映射到 RVV、定制扩展、DMA 或异构核，并用真实硬件验证后端代码生成与性能模型是否仍成立。

在 Taxonomy v2 语境中，它更适合作为 GENERATOR 的后端编译器组件生成/代码生成参考，或作为 SUPPORTING 的 MLIR 编译器基础设施参考；它不是 LLM selector，也不是形式化验证论文。由于论文的最终产物是 HLS kernel 和 host code，和“代码生成、异构硬件编译、MLIR”相关性高，与 RISC-V 的直接相关性为低到中：方法可迁移，但正文没有 RISC-V 实验。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 向量/定制扩展的约束闭环编译

#### 研究问题

如何把 CODO 的数据流违规分析和缓冲协同优化扩展到 RISC-V CPU、RVV 或带 DMA/定制矩阵指令的异构系统。

#### 与原论文的区别

不是只替换目标平台，而是新增 ISA 约束、寄存器压力、向量长度和 DMA 同步语义，并重新设计后端代价模型。

#### 可能的创新点

建立 MLIR buffer/dataflow 约束到 RVV 指令选择、向量化、DMA 分块和核间同步的统一映射；检测编译器变换是否改变同步顺序或访存可见性。

#### 实验框架

```text
PyTorch/C++ → MLIR → 数据流/缓冲分析 → RVV/定制 dialect
        → LLVM/RISC-V lowering → 仿真器与真实开发板 → 性能/正确性反馈
```

#### 可行性

需要 MLIR、LLVM RISC-V backend、Spike/QEMU 或真实 RVV 板、DMA 运行时和一组可重复的 kernel。

#### 主要风险

真实硬件资源和内存系统可能使静态 FIFO 模型失效；跨核同步正确性不能仅用 IR 验证替代。

### 11.2 由形式化翻译验证约束的 FIFO 变换

#### 研究问题

如何证明归约重写、循环置换、buffer duplication 等变换保持数组访问语义，并尽早排除 FIFO 读写计数不一致。

#### 与原论文的区别

原论文使用 MLIR 合法性检查和输出对拍；新方向要对关键变换建立等价性或约束证明。

#### 可能的创新点

把 loop access map、读写计数和 FIFO 前缀约束编码为 SMT/符号执行问题，并把证明失败转成编译器回退信号。

#### 实验框架

```text
MLIR pass → 生成 access relation → SMT/符号检查
        → 通过则 FIFO lowering；失败则 ping-pong 或报告不可证
```

#### 可行性

适合从常量边界 affine loop 开始，使用 MLIR affine analysis、SMT solver 和小规模 kernel。

#### 主要风险

复杂循环和非线性索引可能导致求解超时；有限范围验证仍不能直接等同于完整程序证明。

### 11.3 跨 FPGA 与 RISC-V 异构硬件的可迁移代价模型

#### 研究问题

如何让并行度、buffer 类型和数据搬运决策适配不同 FPGA、RVV 核和片上存储，而不依赖单一 U280 的 profiling 参数。

#### 与原论文的区别

从固定经验阈值 `n=2.0` 和单平台模型，扩展到硬件条件输入、跨平台校准和不确定性分析。

#### 可能的创新点

使用硬件计数器与 HLS/LLVM 静态特征联合校准代价模型，并让编译器显式管理模型误差和资源估计失败。

#### 实验框架

```text
程序特征 + 硬件描述 → 代价模型 → 多平台 DSE
        → 综合/真实运行 → 误差校准 → 下一轮搜索
```

#### 可行性

需要至少两种 FPGA 或 FPGA+RISC-V 平台，以及统一的 kernel 与测量接口。

#### 主要风险

不同工具链的 latency、资源和频率口径可能不一致；模型校准成本可能超过编译收益。

## 12. 与其他已读文献的关系

本批次只确认并通读 CODO 一篇论文，因此没有足够正文证据建立与其他本批次论文的横向事实比较。仓库中已有的 OptiPIM（ISCA 2025）是内存/处理器内映射优化，属于本任务明确排除的内存优化方向，且与 CODO 不是同一论文；因此不把它作为 CODO 的方法 baseline。

从研究角色看，CODO 可作为 MLIR/异构加速器编译器基础设施和后端代码生成的参考；若与 LLM 代码生成论文组合，CODO 更适合充当生成结果的约束化 lowering、验证和性能评测后端，而不是把 CODO 描述为 LLM 方法。与 RISC-V 翻译验证或 RVV fuzzing 工作的潜在组合属于后续研究建议，不是 CODO 已完成的实验。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 自动生成 FPGA 数据流加速器的 MLIR 编译器 |
| 核心问题 | 联合解决数据流正确性、通信效率和资源受限并行调度 |
| 输入 | C/C++ kernel 或 PyTorch 模型 |
| 输出 | HLS C++ kernel、host code、可部署数据流加速器 |
| 核心方法 | 粗/细粒度违规消除、FIFO 优先、复用缓冲、HBM 管理、资源感知 DSE |
| 使用的模型 | GPT-2 Medium 作为评测工作负载；无训练模型 |
| 使用的编译器工具 | MLIR、Polygeist、Torch-MLIR、Vitis HLS、Vivado |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用 MLIR IR 检查和 testbench/golden-result 对拍 |
| 数据集规模 | 不适用；使用 PolyBench kernel 和 DNN/ GPT-2 工作负载 |
| 主要指标 | cycles、latency speedup、编译时间、DSP/BRAM/FF/LUT、功耗、能耗、TTFT、token/s |
| 最重要实验结果 | DNN 综合中相对 ScaleHLS/POM/Allo/HIDA 平均 33.8×/13.6×/3.7×/7.1×；GPT-2 板上相对 DFX/Allo/StreamTensor 为 3.54×/2.07×/1.23×级别的优势 |
| 核心创新 | 把粗细粒度数据流修复、通信和并行调度放入协同 MLIR 编译闭环 |
| 主要局限 | affine/常量循环范围有限；单 FPGA 工具链；部分场景退回乒乓；YOLO 部署失败 |
| 与 RISC-V 研究的相关性 | 中：编译闭环和 buffer/并行分析可迁移，但正文无 RISC-V 实验 |
| 最适合作为 | MLIR 编译器基础设施、异构代码生成和自动调度的方法参考 |

这篇论文最值得学习的是把数据流正确性、片上/片外通信和资源感知并行化作为互相反馈的编译问题；最主要的局限是支持范围和验证范围仍受 affine 程序、Xilinx 工具链与平台资源模型限制。如果用于后续研究，最合理的使用方式是把它作为 MLIR 后端和协同 DSE baseline，再加入 RISC-V/RVV 目标约束、形式化变换验证或跨平台代价模型，而不是简单把 FPGA 平台名称替换成 RISC-V。
