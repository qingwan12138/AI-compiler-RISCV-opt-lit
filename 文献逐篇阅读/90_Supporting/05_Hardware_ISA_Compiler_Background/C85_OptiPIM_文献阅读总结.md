# OptiPIM 文献阅读总结

论文题目：**OptiPIM: Optimizing Processing-in-Memory Acceleration Using Integer Linear Programming**

作者：Jiantao Liu、Minxuan Zhou、Yue Pan、Chien-Yi Yang、Lana Josipović、Tajana Rosing

发表时间：2025 年

发表平台：Proceedings of the 52nd Annual International Symposium on Computer Architecture（ISCA ’25），Tokyo，2025-06-21 至 2025-06-25，pp. 867–883

论文链接或编号：DOI `10.1145/3695053.3731041`；ETH Research Collection 永久标识 `10.3929/ethz-b-000744757`

关键词：Processing-in-Memory（PIM）、整数线性规划（ILP）、MLIR、张量程序映射、数据布局、异构硬件、代码生成

> 本文档基于公开 PDF 全文整理。论文事实依据正文、图表和附录；“阅读后的分析”和“可进一步尝试的方向”不等同于论文已实现的功能。

## 1. 研究背景

Processing-in-Memory（PIM，存内/近存计算）通过在内存内部或附近执行计算，减少处理器与内存之间的数据搬运，目标是缓解传统系统的 memory wall。PIM 对数据在 bank、row、column、寄存器或位级存储位置上的布局有严格要求，因此同一算子存在大量不同的计算调度、数据布局和数据搬运组合。

论文重点讨论数字 PIM，覆盖两类代表性架构：HBM-PIM 的 near-bank processing（NBP）和 SIMDRAM 的 bit-serial processing using memory（PuM）。DNN 的卷积、全连接、批量矩阵乘法等算子通常可表示为嵌套循环，但传统 ASIC 映射工具主要描述计算调度和层次化存储访问，不能充分表达 PIM 的细粒度布局约束。已有 PIM 工作则多采用人工启发式、遗传算法或穷举/随机搜索，可能得到次优映射或产生较长优化时间（第 1、2、3 节）。

因此，论文把“嵌套循环算子如何映射到特定 PIM 组织结构”作为编译器/系统优化问题，试图同时考虑计算、输入加载、输出汇聚、数据布局和容量约束。

## 2. 论文要解决的问题

### 2.1 如何表达 PIM 特有的映射空间

现有 ASIC 映射表达主要关心循环分块、循环顺序和计算单元分配，不能直接表示 PIM 内存中的细粒度行列布局；一些合法的布局也因固定 stride-1 索引而被排除。论文需要一种同时描述 PU 分配、column 分配、计算调度和索引函数的表示（第 3.2、4 节）。

### 2.2 如何准确估计布局相关成本

PIM 的输入加载、权重/操作数存储、输出读取和部分结果汇聚均受布局影响。论文指出，直接将相关循环界相乘会显著高估唯一输入元素数；在随机样本中，COSA 风格方法对输入列数量的估计误差通常超过 70%，而论文提出的估计方法平均误差约 3.2%（图 7、第 5.3 节）。

### 2.3 如何在可接受时间内找到高质量或最优映射

需要在不同 PIM 架构、算子形状和多算子内存分配下，联合满足布局/容量约束并最小化执行成本。论文主要研究：如何用布局感知的嵌套循环表示和 ILP，在数字 PIM 上生成面向算子与硬件的低成本映射。

## 3. 核心方法概述

OptiPIM 将原始嵌套循环变换为三段连续层次：PU allocation、column allocation、computation scheduling；同时为每个原始循环变量选择合法的分块界和数据索引系数组合。随后，系统把硬件参数、算子结构、数据布局约束和成本模型编码为 ILP，并由 Gurobi 求解。

```text
PyTorch 计算图
      ↓ Torch-MLIR
MLIR Linalg 方言
      ↓ OptiPIM lowering / ILP pass
布局感知的三层嵌套循环 + 索引函数
      ↓ Gurobi MILP/ILP 优化
最优或低成本映射
      ↓ 架构专用 codegen
HBM-PIM / SIMDRAM 的内存分配与硬件指令
      ↓ 分析模型或 Ramulator 2 扩展模拟器
执行周期、加载成本、输出汇聚成本
```

论文的模型抽象了 PIM unit、局部内存、层次化互连、带宽、计算吞吐、数据精度和操作延迟，因此可以通过改变参数实例化 HBM-PIM 与 SIMDRAM。输出包括映射、数据分配信息和内存操作/指令生成结果（第 4、6.1 节）。

本文不使用 LLM、工具调用式代理、SFT、强化学习或形式化验证；编译器工具的作用是降低表示、求解映射并生成目标 PIM 代码。

## 4. 实验框架与训练流程

### 4.1 编译器执行流程

本文不涉及模型训练。Torch-MLIR 将 PyTorch workload 降低到 Linalg；OptiPIM 的 ILP 优化 pass 读取 Linalg，并生成上述三层映射表示。随后进行递归 induction-variable analysis，以从紧凑表示恢复时空数据空间，再执行架构相关 codegen（图 8、第 6.1 节）。

### 4.2 架构专用代码生成

SIMDRAM codegen 按位串行原地计算的限制分配 operand/result 缓冲行，并生成 activate-activate-precharge（AAP）操作。HBM-PIM codegen 为权重分配内存、为输入和输出分配寄存器，并按嵌套循环顺序分配 8 个输入通用寄存器和 8 个输出通用寄存器；二者都生成主机通信的读写操作。

### 4.3 多算子优化

对一个 workload 中的多个算子，ILP 可以联合决定每个算子所使用的 PU 数量，使所有算子的 PU 数量总和不超过系统容量，并最小化各算子目标之和（第 5.6 节）。

### 4.4 求解与评估

ILP 使用 Gurobi 11.03。单个机器学习算子的最大优化时间在作者测试环境 AMD Ryzen 7 Pro 7840U（3.2 GHz）、32 GB RAM 上低于 4 分钟；最优性实验报告单算子 1–209 秒。性能评估使用分析模型，并用扩展 Ramulator 2 的周期精确模拟器交叉验证。

## 5. 奖励函数、损失函数或关键公式

本文没有强化学习奖励函数，也没有神经网络损失函数。核心是 ILP 变量、约束和成本最小化目标。

### 5.1 索引函数

三层循环下，原始循环变量 `x` 的数据索引可写为：

```text
F(x2, x1, x0) = d*x2 + e*x1 + g*x0
```

系数必须构成双射并覆盖 `[0, Lx-1]`。论文证明三层情况下有 6 种合法系数组合，并推广为 `Numcoeff = l!`，其中 `l` 是变换后的循环层数（式 1–4）。

### 5.2 唯一输入元素估计

对于卷积输入索引 `a*o0 + b*f0`，论文提出：

```text
Num_col_input = min(
  (a*(Lo,0-1) + b*(Lf,0-1)) / gcd(a,b) + 1,
  Lo,0*Lf,0
)
```

它用于估计一个 PU column 中需要存储的唯一输入数量，并避免简单乘积造成的过估计（式 11）。

### 5.3 总成本目标

论文将总目标写为：

```text
Obj = Cost_compute + Cost_output + Cost_input
```

其中计算成本依赖每 column 的乘法数、归约数、PIM 技术对应的 row 操作成本；输出成本由各 PU 需要传输的输出/部分结果大小除以对应带宽得到；输入成本由各 PU 所需输入数量、数据精度和带宽决定（式 17–20）。ILP 最小化 `Obj`。

## 6. 实验设置

### 6.1 数据集来源

论文使用算子/模型 workload，而非传统监督学习数据集。测试包括 AlexNet、ResNet-50、ResNet-152、UNet、VGG、BERT-base、Llama-3 8B、Llama-3 14B，以及 Stencil 嵌套循环；全部 workload 使用 16-bit 数据精度（第 6.3 节）。附录说明模型来自 torchvision 和 Hugging Face，经 Torch-MLIR 前端提取卷积与全连接层。论文中未报告训练集、验证集或测试集划分，因为本文不训练模型。

### 6.2 模型与工具

- 编译/中间表示：MLIR、Linalg、Torch-MLIR、nested affine loops。
- 优化器：Gurobi 11.03。
- 模拟：扩展 Ramulator 2；论文以 HBM2E 为基础架构。
- HBM-PIM：每 channel 32 banks、每 stack 16 channels、每 bank 32 MB、row size 1 kB、256-bit DQ；主机带宽 500 GB/s。
- 数据类型：HBM-PIM 使用 16-bit floating point；SIMDRAM 使用 16-bit fixed point。
- 运行环境：AMD Ryzen 7 Pro 7840U 3.2 GHz、32 GB RAM；穷举对比使用 AMD EPYC 7713 3.6 GHz 的 70 个并行核心。

### 6.3 对比方法

1. HBM-PIM 的 weight-parallel heuristic：按 bank、column、row 分配权重 tile。
2. PIM-DL 风格 genetic/random search：每算子将遗传算法运行时间限制为 1 小时。
3. ASIC-based COSA ILP：移植到 PIM，但不包含 PIM 细粒度布局成本和约束。
4. exhaustive search：主要用于验证 OptiPIM 的最优性，不作为常规高效基线。

### 6.4 评价指标

| 指标 | 含义 |
| --- | --- |
| 执行周期/Latency | 分析模型或周期精确模拟器估计的执行成本，越低越好 |
| Speedup | 相对于指定 baseline 的加速比，越高越好 |
| 优化时间 | 求解一个算子映射所需时间，越低越好 |
| 估计误差 | 分析模型相对理想/模拟结果的误差，越低越好 |
| `R²` | 分析模型与 Ramulator 2 周期结果的相关性，越接近 1 越好 |

## 7. 实验结果与结论

### 7.1 分析模型验证

对所有 benchmark 随机生成 12,000 个合法映射，并与扩展 Ramulator 2 的结果比较。HBM-PIM 的 `R²=0.993`，SIMDRAM 的 `R²=1.000`（图 9），说明该论文的分析模型在所测试配置上与周期精确模拟结果高度一致。

### 7.2 与基线比较

在 SIMDRAM 上，OptiPIM 相比 heuristic 平均加速 2.3×，相比 PIM-DL 随机搜索平均加速 2.0×，相比 ASIC mapping 平均加速 1.1×（图 10a–b）。SIMDRAM 主要由位串行的内存内计算成本主导，因此布局成本被忽略时的差距相对较小。

在 HBM-PIM 上，OptiPIM 相比 HBM-PIM heuristic、PIM-DL 和 ASIC mapping 的报告加速比分别为 72.8×、1.8× 和 25.4×（图 10c–d）。论文解释，原始 heuristic 主要针对矩阵向量乘法；用于卷积时，输入错位导致大量重复加载。ASIC baseline 虽能降低计算成本，但忽略布局相关的输入加载成本，整体反而较慢。

### 7.3 算子和案例分析

ResNet-50 与 BERT 的代表性算子分析显示，OptiPIM 在不同算子类型上整体更稳定。ResNet-50 Conv12 案例中，OptiPIM 的 HBM-PIM 映射显式平衡输入加载、计算和输出归约；heuristic 虽计算成本低，却产生极高输入加载成本；ASIC mapping 的计算成本最低，但由于未考虑布局造成的加载开销，整体不优（图 12）。

### 7.4 消融实验

在 UNet 的 HBM-PIM 实验中，准确成本估计结合 Base Index 和 OptiPIM Index 分别带来 4.8× 和 6.6× 加速；在 VGG16 上分别为 3.5× 和 3.5×。SIMDRAM 上收益较小，因为内存内计算占主导。综合索引在 UNet 上使用 Base Estimate 和 OptiPIM Estimate 时分别带来 1.2× 和 1.6× 加速；VGG16 因多数相关循环的 gcd 为 1，收益很小（图 13、第 7.5 节）。

### 7.5 最优性、容量与模型规模

OptiPIM 在测试 workload 上均找到最优结果，单算子用时 1–209 秒；并行穷举在 EPYC 服务器上平均需要 9,800 秒（约 2.7 小时）评估一个算子的所有映射。多算子容量实验中，相对平均分配内存的 heuristic，OptiPIM 在 SIMDRAM 上对 8/16/32 GB 分别快 43.6%、30.6%、28.7%，在 HBM-PIM 上分别快 18.5%、7.3%、1.4%（图 14）。对 128 GB、8-stack HBM-PIM 的 Llama-3 prefill，Llama-3 8B 可整体放入设备，14B 被分成可容纳的算子组顺序执行（图 15）。

## 8. 主要创新点

### 8.1 布局感知的三层嵌套循环表示

论文不是简单把现有 ASIC mapping 的目标硬件替换为 PIM，而是把 PU allocation、column allocation、computation scheduling 明确分层，并用索引函数表达 PIM 内部布局。该设计直接对应 PIM 的空间并行、行列容量和时间调度约束。

### 8.2 可扩展的完整索引空间

论文将索引系数组合纳入优化变量，在三层情况下只需考虑 6 种合法组合，在保证循环语义的同时扩大可探索布局空间。这是对固定 stride-1 索引表示的结构性改进。

### 8.3 PIM 专用精确成本模型与 ILP 联合优化

论文把计算、输入加载、输出汇聚和布局容量统一放入可配置 ILP，并针对线性组合索引推导唯一元素估计。实验的模型误差、消融结果和基线比较支持该联合建模设计的有效性。

### 8.4 面向两类数字 PIM 的 MLIR 实现

OptiPIM 在 MLIR/Torch-MLIR 中实现，并对 HBM-PIM 与 SIMDRAM 生成不同的代码和内存操作；这使论文从抽象优化模型延伸到可执行的编译流程与开源 artifact。

## 9. 局限性

### 9.1 论文明确承认的局限

- OptiPIM 是编译时静态优化框架，要求静态 shape；动态 shape 优化不在当前范围内。
- 目标是具有 uniform computation pattern 的 nested affine-loop operators，论文没有证明对任意控制流或任意程序都适用。
- 论文主要面向数字 PIM，不直接覆盖模拟 crossbar PIM；正文明确将 CiMLoop 等工作区分开来。
- LLM generation 阶段的动态矩阵形状需要预优化若干选择的 shape 或运行时 padding，论文将这类支持留在现有 ML 编译器风格的扩展方向中。

### 9.2 阅读后的潜在局限

- 主要性能结果来自分析模型和模拟器交叉验证，而不是 HBM-PIM/SIMDRAM 实物芯片上的端到端测量；不能把模拟 latency 直接等同于真实硬件时间。
- ILP 的规模和求解时间可能随循环变量、算子数量、架构层级及合法索引组合增加而增长；论文报告的“最优”只针对给定表示、约束和测试配置。
- 代码生成中对固定寄存器分配策略、16-bit 数据类型和 HBM2E 配置的依赖，可能影响迁移到其他 PIM 组织或 RISC-V 加速器的成本模型有效性。
- 论文聚焦算子映射，没有把更高层的图重写、算子融合、运行时调度或动态 batch 作为主要优化对象。

## 10. 阅读后的研究方向反思

最值得借鉴的是“硬件约束可表达化”：先设计能完整描述目标硬件合法空间的 IR/循环表示，再做搜索或优化，而不是直接对固定 pass 或启发式参数调优。该思想可作为 MLIR dialect、RISC-V 向量扩展 mapping 或异构内存 codegen 的方法参考。

OptiPIM 的核心贡献是 PIM 特有的布局表示、索引组合和 ILP 成本模型；仅把 HBM-PIM 改为 RISC-V、或只替换一个模拟器，不足以形成同等创新。若迁移到 RISC-V，应新增可验证的 ISA-aware 资源模型，例如 RVV 向量长度、寄存器压力、bank conflict、DMA/缓存一致性和自定义扩展指令的联合约束，并证明这些新约束改变了可行映射空间或优化质量。

由于本文没有 LLM，按 Taxonomy v2 规则不应归入 SELECTOR、TRANSLATOR 或 GENERATOR 的 LLM 角色；更适合作为 SUPPORTING 的传统编译优化/异构硬件映射参考，也可作为后续 LLM 编译器工作中的硬件感知 cost model 或 codegen backend 工具模块。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 向量 PIM/近存扩展的统一映射模型

#### 研究问题

如何在统一表示中同时刻画 RVV 向量长度、寄存器分配、PIM bank 布局和自定义近存指令的成本？

#### 与原论文的区别

不只是替换目标 ISA，而是把 RVV 的动态 `VL`、向量寄存器压力、访存对齐和 bank 级并行冲突纳入新的可行性约束。

#### 可能的创新点

建立 RVV/PIM 混合 dialect；证明向量语义和 PIM 布局之间的约束保持；比较 ILP 与启发式在跨算子 workload 上的质量和求解代价。

#### 实验框架

```text
Tensor/affine loop → MLIR dialect → RVV/PIM-aware ILP → LLVM/RISC-V lowering
                   → gem5/RTL/真实开发板 → 周期、能耗、代码大小
```

#### 可行性

需要 MLIR/LLVM RISC-V backend、RVV 模拟器或开发板、PIM/内存模型和可复现算子基准。

#### 主要风险

若只有模拟器或只改变目标硬件，创新性和真实硬件可信度可能不足；ILP 规模也可能成为瓶颈。

### 11.2 ILP 约束与学习型搜索的混合编译器

#### 研究问题

能否让学习模型预测搜索优先级或缩小候选空间，同时让 ILP 保持布局与资源约束的可证明满足？

#### 与原论文的区别

OptiPIM 使用精确 ILP；新方向增加学习型候选排序/松弛引导，但不把生成结果的正确性直接交给模型。

#### 可能的创新点

约束安全的候选剪枝、跨架构迁移的 cost-model 预训练、求解时间与最优性差距的联合评估。

#### 实验框架

```text
合法映射空间 → 学习模型排序/剪枝 → ILP 求解剩余空间 → 代码生成与模拟验证
```

#### 可行性

可复用 OptiPIM artifact、MLIR 表示和已有 workload；需要记录 ILP 搜索轨迹并建立训练/测试划分。

#### 主要风险

学习模型可能剪掉全局最优；必须报告最优性 gap、失败率和不同架构上的泛化，而不能只报告平均 speedup。

### 11.3 动态 shape 的分层映射与运行时选择

#### 研究问题

如何为 LLM generation 等动态 shape 场景，离线生成有限候选映射并在运行时低开销选择？

#### 与原论文的区别

原论文主要优化静态 shape；新方向需要处理 shape 变化、缓存映射、权重重载和运行时选择成本。

#### 可能的创新点

shape 聚类、鲁棒布局、运行时 cost model 和映射切换策略的联合设计。

#### 实验框架

```text
历史 shape/profile → 离线生成候选映射 → 运行时 shape 识别
                  → 选择/切换映射 → 真实或周期级执行
```

#### 可行性

可从 Llama-3 prefill/decode 的静态与动态形状开始，并复用 MLIR lowering 和 PIM 模型。

#### 主要风险

候选映射切换和权重加载可能抵消算子级收益；必须把切换、padding 和重配置成本计入总目标。

## 12. 与其他已读文献的关系

本 slot 当前只完成 OptiPIM 一篇论文，因此没有同批次内可进行事实级横向比较的其他论文。就仓库现有主题而言，OptiPIM 与传统张量编译、硬件映射和 MLIR codegen 工作相近，而不是 LLM 生成源代码/IR、LLM pass 选择或形式化验证论文。

建议将本文作为：

- `SUPPORTING / B4_Traditional_ML_Compiler_Optimization` 的异构硬件映射与传统编译优化参考；
- 未来 PIM/RISC-V/加速器论文的 cost model、约束表示和 codegen baseline；
- LLM 编译器系统中的硬件后端工具模块或 oracle/teacher mapping 生成器。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 数字 PIM 加速器上的算子映射优化 |
| 核心问题 | 同时处理 PIM 数据布局、循环调度、数据搬运和容量约束 |
| 输入 | PyTorch workload，经 Torch-MLIR 转为 Linalg/嵌套 affine loops |
| 输出 | HBM-PIM/SIMDRAM 的布局、循环映射、内存操作和硬件指令 |
| 核心方法 | 布局感知三层嵌套循环 + 完整索引组合 + ILP |
| 使用的模型 | 非神经优化模型；Gurobi ILP 求解器 |
| 使用的编译器工具 | MLIR、Torch-MLIR、Linalg、Gurobi、架构专用 codegen |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用分析模型与周期精确模拟器交叉验证 |
| 数据集规模 | 不适用；使用 7 类神经网络模型、Stencil 等 workload |
| 主要指标 | 周期/latency、speedup、优化时间、估计误差、R² |
| 最重要实验结果 | SIMDRAM 平均相对 heuristic/PIM-DL 加速 2.3×/2.0×；HBM-PIM 相对三类 baseline 报告 72.8×/1.8×/25.4×；单算子优化低于 4 分钟 |
| 核心创新 | PIM 布局可表达化、索引空间完整化、布局感知成本 ILP 化 |
| 主要局限 | 静态 shape、数字 PIM、规则嵌套 affine loop；主要依赖模拟/分析模型 |
| 与 RISC-V 研究的相关性 | 中：可借鉴约束表示和 codegen 思路，但论文未研究 RISC-V，迁移需要新的 RVV/ISA 约束与实测验证 |
| 最适合作为 | 传统编译优化 baseline、硬件映射方法参考、MLIR/PIM codegen 工具模块 |

> 这篇论文最值得学习的是把 PIM 的细粒度布局约束提升为可求解的编译器表示和成本模型；最主要的局限是静态数字 PIM 与模拟评估范围有限；如果用于后续研究，最合理的使用方式是作为硬件感知映射与 cost model 基线，而不是简单替换成 RISC-V 或把 ILP 结果直接宣称为真实硬件最优。
