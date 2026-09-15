# UniNDP 文献阅读总结

论文题目：**UniNDP: A Unified Compilation and Simulation Tool for Near DRAM Processing Architectures**

作者：Tongxin Xie、Zhenhua Zhu、Bing Li、Yukai He、Cong Li、Guangyu Sun、Huazhong Yang、Yuan Xie、Yu Wang

发表时间：2025

发表平台：2025 IEEE International Symposium on High Performance Computer Architecture（HPCA 2025），pp. 624–640

论文链接或编号：DOI [10.1109/HPCA61900.2025.00054](https://doi.org/10.1109/HPCA61900.2025.00054)

关键词：Near-DRAM Processing（近 DRAM 处理）、Processing-in-Memory、NDP compiler、DRAM hierarchy、cycle-accurate simulation、ML workload mapping、hardware/software co-design

> 本笔记依据作者公开的 17 页正式全文 PDF（PDF 首页标注 DOI，正文页码 624–640）撰写。论文事实与阅读后的研究思考分开描述；本文没有把该工作扩展为 LLVM、RISC-V 或 LLM 方法。

---

## 1. 研究背景

本文属于近 DRAM 处理（Near-DRAM Processing，NDP）编译与体系结构协同优化。NDP 把处理单元（Processing Unit，PU）放在 DRAM 层级附近，使计算可以利用 DRAM 内部带宽，减少主机处理器与 DRAM 之间的数据搬运。引言指出，机器学习模型规模和数据传输量持续增长，而计算性能的增长快于 DRAM 带宽，传统 von Neumann 架构中的数据访问可能成为主要瓶颈；论文引用的背景估计是数据移动可占传统架构延迟的 60% 以上（第 I 节）。

NDP 不是单一硬件形态。论文按 PU 所处的 DRAM 层级讨论 bank-level、device-level、rank-level 和 channel-level NDP，也指出一个系统可以在多个层级放置 PU。不同 DRAM 技术、PU 数量和位置、局部/全局 buffer、可见地址空间以及时序参数，会改变最优的部署方式。

因此，NDP 软件栈至少要共同优化三件事：

1. 数据分区：按 PU 数量和内存容量拆分工作，保持负载均衡。
2. 数据映射：决定数据放在哪个 DRAM 层级、bank、行和列，以接近消费者 PU，并减少 row-buffer miss。
3. 工作负载调度：决定输入来源、输出去向以及数据访问和计算的流水关系，降低 PU 等待。

传统编译器把 DRAM 当成整体内存，无法描述多个独立 PU 与内存单元的并发；已有 NDP 编译器和模拟器又大多针对某一种架构，难以在 DDR、GDDR、HBM 等不同组织之间迁移（第 I–II 节）。UniNDP 的目标是用同一套硬件抽象、指令集、模拟器和编译器支持多种 NDP 架构。

## 2. 论文要解决的问题

### 2.1 统一表示不同 NDP 架构

不同 DRAM 层级和 PU 位置会改变可见内存、并行度、buffer 共享方式及指令可行性。论文要解决如何用一个可配置表示覆盖多种 NDP 架构，而不是为每个架构单独开发工具（第 II-A、IV-A 节）。

### 2.2 对编译策略进行可信的性能评估

NDP 的计算与 DRAM 命令紧密耦合，需要考虑 ACT、READ、WRITE、PRE 及其时序约束，还要跟踪 PU、buffer、总线和 row-buffer 状态。论文要解决如何在支持指令依赖、局部并发和 out-of-order issue 的同时，得到周期级性能估计（第 II-B、V 节）。

### 2.3 在巨大搜索空间中寻找分区、映射和调度策略

矩阵在多个 DRAM 层级切分、数据块映射到行列、主机与 NDP 间搬运以及工作负载调度共同形成巨大搜索空间。论文要解决如何剪枝并快速选出候选，再用较准确的模拟器完成最终选择（第 III、VI 节）。

> 本文主要研究：如何针对给定的 ML 算子和 NDP 硬件配置，统一搜索并验证数据分区、数据映射和工作负载调度策略。

## 3. 核心方法概述

UniNDP 是一个面向 NDP 架构和 ML 算子的编译—模拟一体化工具。论文并不提出 LLM，也不做模型训练；它把 ONNX 输出的算子级 IR 和详细 DRAM/NDP 配置作为输入，通过策略编码、硬件状态剪枝、快速性能预测和周期精确模拟，输出最优的分区、映射、调度策略及对应指令序列（第 III 节图 2）。

```text
ONNX 算子级 IR + NDP/DRAM 硬件配置
          ↓
编码数据分区、数据映射和工作负载调度搜索空间
          ↓
硬件状态上界剪枝
          ↓
DRAM 时序参数驱动的快速性能预测，保留 top-K
          ↓
生成统一 NDP 指令序列
          ↓
指令驱动、周期精确的 NDP 模拟器
          ↓
选择最佳编译策略并输出分区/映射/调度结果
```

方法的关键组件如下：

- 树形硬件抽象：每个层级表示 channel、rank、device、bank 等 DRAM 层级，节点可包含 memory、PU 和 buffer。
- 统一 NDP 指令集：包括 MAC-DRAM、MAC-GB、MAC-LB 等计算指令，buffer/DRAM/寄存器间数据移动，以及主机侧读写指令（表 II）。
- 指令驱动模拟器：不逐 DRAM cycle 更新整个状态，而是在每次发射新指令时更新状态；作者报告相对逐 cycle 模拟可减少 10–300 倍模拟时间（第 V-A 节）。
- 硬件状态剪枝：使用 DRAM 访问数、row miss、PU 计算并行度等指标估计性能上界，跳过不可能达到阈值的策略。
- 快速预测器：根据短指令片段中的 READ/WRITE、row miss 和 buffer/register 搬运估计延迟，用于早期筛选；最终排名仍由周期精确模拟器确认。

## 4. 实验框架与训练流程

本文不涉及模型训练、预训练、SFT、PPO、GRPO、强化学习、奖励模型或形式化验证。它是一个静态编译搜索和性能模拟系统，执行流程如下。

### 4.1 输入与策略编码

输入包括 ONNX 框架产生的算子级 IR，以及描述 NDP 架构和 DRAM 时序参数的硬件配置。论文重点处理矩阵乘法（MM）、矩阵向量乘法（MVM），并在实验中扩展到 softmax、normalization、非线性函数和逐元素加法等算子（第 III、VII-A 节）。

对矩阵乘法 `O = W × A`，分区编码允许在多个 DRAM 层级沿 M、K、N 维度切分，而不是只沿 M 维切分。映射编码进一步描述 weight、input activation 和 output 的数据块如何映射到 DRAM 行列以及 burst length 约束下的同一行。

### 4.2 硬件状态剪枝

编译器先利用计算并行度、K 维 reduction 单元和读写复用等启发式约束映射编码范围。随后使用性能上界动态剪枝：

```text
Perf_max = DRAM Access / Bandwidth
         + RowMiss × tRP
         + Workload / (#PU × PerfPU)
```

该上界故意不包括某些额外的 PU、buffer 和主机数据移动。如果上界已经慢于阈值，则对应策略不再进入后续评估（第 VI-D 节）。

### 4.3 预测器筛选与精确模拟

对剩余策略，编译器生成局部指令片段，用 DRAM 时序参数预测数据移动延迟，再保留 top-K 候选生成完整指令序列。周期精确模拟器的虚拟内存控制器（VMC）根据数据依赖和硬件状态，决定每条候选指令的最早可发射时间，并支持指令重排和 out-of-order issue。最终以模拟延迟选择最佳策略。

### 4.4 模拟器执行

每轮模拟包含四步：指令队列筛出无未满足依赖的指令；VMC 计算各候选的最早发射时间；硬件状态直接推进到最早时间；内存控制器发射该指令并更新相关资源倒计时。重复至所有指令完成（第 V-A 节图 4）。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数，也没有神经网络训练损失。关键公式是编译剪枝和性能估计公式。

### 5.1 性能上界

```text
Perf_max = #DRAM Access / Bandwidth
         + #RowMiss × tRP
         + Workload / (#PU × PerfPU)
```

其中 `#DRAM Access` 是访问量，`Bandwidth` 是可用带宽，`#RowMiss` 是 row-buffer miss 数，`tRP` 是 row precharge 时间，`Workload` 是计算工作量，`#PU` 是 PU 数量，`PerfPU` 是单 PU 计算能力。该式用于快速排除不可能超过阈值的候选，不是完整的周期精确延迟模型，因为它不包含额外数据移动（第 VI-D 节）。

### 5.2 局部指令片段预测器

```text
Lat_partial = tCCD × (#READ + #WRITE)
            + #RowMiss(READ) × tRowChange(READ)
            + #RowMiss(WRITE) × tRowChange(WRITE)
            + LatBuffer/Reg(Host)

TotalLat = #Loops × Lat_partial
```

其中 `tCCD` 是连续列访问间隔；`#READ` 和 `#WRITE` 是计算、数据移动及主机指令产生的 DRAM 读写数；`#RowMiss` 和 `tRowChange` 表示 row miss 数及其额外时延；`LatBuffer/Reg(Host)` 表示主机指令对数据总线的影响；`#Loops` 是局部指令模式在完整程序中的重复次数。论文用它做候选的相对排序，不把它当成最终精确模拟。

### 5.3 指令发射时间

论文给出 global buffer 操作的到达时间和计算开始时间：

```text
TA(GB) = max(TF(GB) + RL(GB), TF(BUS))
TS = max{TA(GB), TA(BK0), TA(BK1), ..., TF(PU)}
```

`TA` 是操作数到达时间，`TF` 是资源空闲/释放时间，`RL` 是读取延迟，`TS` 是计算启动时间。VMC 依据这些时间和 DRAM PRE/ACT/READ/WRITE 约束决定最早发射指令（第 V-D 节）。

## 6. 实验设置

### 6.1 数据集来源

论文没有使用独立机器学习训练数据集，而是使用从 CNN 和 LLM 工作负载中选取的算子。CNN 包括 AlexNet、ResNet-18、VGG-16；卷积层通过 `img2col` 转换为 MVM，实验还改变 stride、padding 和 batch size。LLM 使用 Llama2-7B、Llama2-13B、Llama2-34B 的 MM 和 MVM 算子，并使用最大输入长度 4096（第 VII-A 节表 IV）。

表 IV 给出的部分算子规模包括：Llama2-7B 的 MM 维度如 `(4096,4096,4096)` 和 `(11008,4096,4096)`，MVM 维度如 `(4096,4096)` 和 `(11008,4096)`；Llama2-13B 和 34B 使用与模型层形状对应的更大维度。论文没有把这些算子称为训练集、验证集和测试集，也未给出数据泄漏分析；因此不能把它们解释为监督学习数据集。

### 6.2 模型与工具

硬件实验覆盖五种配置（第 VII-A 节表 III）：

| 配置 | NDP 层级 | PU 数量 | 主要 DRAM 技术 |
| --- | --- | ---: | --- |
| Arch 1 | bank-level | 每 bank 1 个 | DDR4，20 channels |
| Arch 2 | device-level | 每 device 16 个 | GDDR6 |
| Arch 3 | device-level | 每 device 8 个 | GDDR6 |
| Arch 4 | device-level | 每 device 8 个 | Samsung HBM2 |
| Arch 5 | rank-level | 每 rank 4 个 | DDR4，20 channels |

Arch 1 参考 UPMEM-PIM 的 20-channel 设计，并将 RISC-V core 简化为 ML workload 的 MAC 单元。Arch 2 参考 SK hynix AiM，Arch 4 参考 HBM-PIM，Arch 5 结合 UPMEM-PIM 内存系统与 DIMMining 的 rank-level 假设。所有 PU 使用相同计算并行度和频率以保持比较公平。DRAM 时序参数参考 Samsung PIMSimulator、DRAMSim3 和 Ramulator2。

对比/验证工具包括作者的 UniNDP simulator、Samsung PIMSimulator 以及论文所述的已有 AiM/HBM-PIM 分区和映射策略。全文没有报告 LLVM、MLIR、GCC、Clang、Alive2 或 RISC-V 编译器后端的使用。

### 6.3 对比方法

主要 baseline 是 AiM 和 HBM-PIM 相关已有分区、映射策略。这些策略倾向于沿 M 维分区，并把映射到 DRAM 行的 K 维块设得尽可能大。模拟器验证以 Samsung PIMSimulator 为参照，在相同 DRAM 时序、架构设计和编译策略下比较。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Speedup | baseline 延迟除以 UniNDP 延迟 | 越大越好 |
| Clock cycles | 算子在模拟器中的时钟周期数 | 越小越好 |
| DRAM access/row change | DRAM 访问与 row-buffer 切换相关命令量 | 通常越少越好 |
| Simulation time | 模拟器完成同一工作负载所需时间 | 越小越好 |
| R² | 预测器结果与周期精确模拟结果的决定系数 | 越接近 1 越好 |
| Compilation time | 搜索和评估编译策略的时间 | 越小越好 |

## 7. 实验结果与结论

### 7.1 主要结果

与已有 NDP 分区和映射策略相比，UniNDP 在不同架构和工作负载上达到 1.05–3.43× 的端到端加速；论文进一步拆分为 CNN 的 1.86–3.43× 和 LLM 的 1.05–1.49×（摘要、第 I 节和第 VII-B 节）。MM 算子平均 speedup 在 Arch 1–5 分别为 1.49×、1.21×、1.16×、1.07×、1.15×；MVM 平均分别为 1.62×、1.23×、1.26×、1.10×、1.50×（表 V、VI）。这些数字是周期模拟结果，相对于论文定义的 baseline，不是真实芯片实测时间。

论文报告 UniNDP 最多可减少 86% 的 DRAM 访问相关命令和 DRAM row change；第 VII-B 节将收益主要归因于减少主机与 NDP 之间通信，以及减少行激活。CNN 改善通常高于 LLM，因为滑动窗口带来的输入矩阵相对更大，原有策略需要较多主机侧指令处理输入。

### 7.2 与传统方法的比较

在 Llama2-34B 的 attention 相关 MM2/MVM2 算子上，表 V、VI 给出较高收益：不同架构的 MM2 speedup 为 1.46–1.85×，MVM2 speedup 为 1.23–2.20×。论文解释为 UniNDP 同时考虑了 weight、activation 的维度以及 M、N、K 多维分区，而 baseline 主要依赖 M 维分区。

Arch 1 的优化空间较大，因为可以在多个 DRAM 层级逐 bank 优化分区和映射；Arch 2/3 受 global buffer 和电路设计约束，已有策略已较有效，因此收益较小。channel-level NDP 的额外收益只有约 0.1–2%，因为其行为更接近把多个 rank 当作整体的传统内存系统。

### 7.3 与其他 LLM 方法的比较

本文没有使用 LLM 作为编译器主体、搜索代理或 baseline，因此不存在与其他 LLM 编译方法的比较。Llama2 在本文中只是被评估的 ML 工作负载来源，不是被训练或调用的模型。

### 7.4 消融与效率实验

- 模拟器验证：UniNDP 与 Samsung PIMSimulator 的结果偏差为 6–8%。论文认为主要原因是 DRAM refresh mechanism 的建模仍需细化，并称该误差不影响排序比较。
- 模拟速度：相比逐 cycle 分析的 PIMSimulator，UniNDP 指令驱动模拟器把一个示例的时间从 30.89 s 降到 18.28 s，speedup 为 1.62–1.82×。
- 搜索剪枝：对 Arch 2/3 的 Llama2-7B MM 示例，剪枝把平均编译时间从 5,640 s 降至 1,475 s，搜索效率提升 3.82×；其中 top-K 预测筛选阶段从 4,200 s 降至 35 s。
- 预测器：在 Arch 1、2、3、5 上，预测器与精确模拟的 R² 分别为 0.9551、0.9896、0.9889、0.9986；每个策略预测约需 66 µs。论文同时明确指出，预测器不能精确排序 top-K，若完全去掉模拟器只用预测器，性能会下降约 15%，所以精确模拟仍是最终选择环节。

### 7.5 设计洞察与案例

论文提出四类 NDP 设计洞察：通信量减少在被计算完全覆盖后会出现边际收益递减，继续优化应关注 row activation；增大输入 buffer 可提升数据复用，但输出 buffer 需求较低；在总 buffer 相同时，device-level NDP 的跨 PU 共享 buffer 可比 bank-level 获得最高约 39% 性能改善；数据布局应结合 buffer 大小和共享关系，在输入 buffer 替换前让权重尽量位于同一 DRAM 行，输入矩阵较大时优先沿输入维度切分以避免额外归约（第 VII-G 节）。

## 8. 主要创新点

### 8.1 创新点一：可配置的树形 NDP 硬件抽象

论文把 DRAM 的 channel、rank、device、bank 等层级建模为可扩展树，并允许每层配置 memory、PU 和 buffer。该设计的价值在于把不同 DRAM 技术和 PU 布局统一到同一编译/模拟接口。实验覆盖 bank、device、rank 三种层级，证明了跨架构适配能力；它不是单纯“使用编译器”，而是把硬件层级差异显式放进编译策略空间。

### 8.2 创新点二：统一 NDP 指令集与指令驱动周期精确模拟

统一指令集把计算、NDP 内数据移动和主机侧操作分开，并由虚拟内存控制器展开为 DRAM 命令。指令队列按局部数据依赖组织不同 bank/PU 的指令组，允许并行与 out-of-order issue。该机制兼顾了周期精确性和 NDP 中局部并发，实验以 PIMSimulator 的 6–8% 偏差和较低模拟时间支持其有效性。

### 8.3 创新点三：硬件状态感知的编译搜索

论文没有对完整组合空间盲目模拟，而是用 DRAM 访问、row miss、PU 并行度构造性能上界，再用 DRAM 时序参数和局部指令模式预测候选。这是针对 NDP 硬件状态的搜索缩减机制；预测器本身不能替代精确模拟，论文的实验也验证了这一边界。

### 8.4 创新点四：多维、多层级的分区与映射编码

相对于主要沿 M 维分区的已有策略，UniNDP 允许在多个 DRAM 层级沿 M、K、N 维度共同分区，并分别编码 weight、activation、output 的行列布局。表 V、VI 和 CNN/LLM 实验表明，这个编码空间能在若干 attention、滑动窗口和输入较大的算子上暴露 baseline 未利用的优化空间。

## 9. 局限性

### 9.1 论文明确承认的局限

- 预测器不能精确排序 top-K；只用预测器会导致约 15% 性能下降，因此仍需周期精确模拟。
- UniNDP 与 Samsung PIMSimulator 偏差为 6–8%，论文把 DRAM refresh 建模列为需要改进之处。
- 论文当前重点是 ML workload，结论主要来自 MM、MVM 及少量向量/逐元素算子；结论末尾将支持更多非 ML workload 和通用计算列为未来工作。
- channel-level NDP 可利用的编译优化空间较小，工具在这种架构上的额外收益有限。

### 9.2 阅读后发现的潜在局限

- 主要结果来自仿真和架构假设，不是五种架构上的真实芯片测量；因此 speedup 不能直接当作实机运行时间提升。
- 编译器输入是 ONNX 算子级 IR，论文没有展示从一般源代码、LLVM IR 或多算子全图到该 IR 的完整 lowering、内存分配和运行时集成流程。
- 搜索和性能模型依赖 DRAM 时序参数、buffer 和 PU 模型；迁移到尚未覆盖的 DRAM 技术、非 MAC 操作或复杂运行时行为需要重新验证。
- 论文以算子和固定形状为主，跨算子融合、动态形状、控制流、稀疏性和端到端模型调度的支持在正文中未充分展开。
- 论文没有提供与 LLVM/MLIR、TVM 或通用自动调优框架的统一实验比较，因此不能据此断言它优于这些编译器生态。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把“硬件状态—候选编译策略—可验证性能”连成闭环：先用便宜的上界和预测器缩小空间，再用可信度更高的执行模型确认。这一思想可作为硬件感知编译优化的搜索骨架。

### 10.2 不能简单照搬的部分

树形抽象、统一指令集和 DRAM 模型是 UniNDP 在多种 NDP 层级上的核心贡献。仅把其硬件配置替换成 RISC-V 或把算子替换成 LLVM IR，并不能自动形成同等创新；需要证明新的 ISA、内存模型或验证约束带来了新的研究问题。

### 10.3 与 LLVM/MLIR、RISC-V 的关系

本文与 LLVM/MLIR 的直接关系有限：论文使用的是 ONNX 算子级 IR 和自定义 NDP 指令，而不是 LLVM IR/MLIR 方言。与 RISC-V 的关系也有限，只有 Arch 1 的背景描述把 UPMEM-PIM 的 RISC-V core 简化为 MAC unit；它不是 RISC-V ISA 代码生成或 RISC-V 后端优化论文。更合适的用法是把 UniNDP 作为硬件感知调度、模拟和搜索的参考框架，再研究如何把 MLIR/NPU/NDP 方言 lowering 到可验证的 NDP 指令。

### 10.4 适合作为哪类材料

对当前研究，它更适合作为“硬件状态反馈驱动的编译搜索工具模块”和硬件软件协同 baseline，而不是 LLM 训练方法、形式化验证方法或完整的 RISC-V 代码生成框架。

## 11. 可进一步尝试的研究方向

### 11.1 MLIR-NDP 多层级 lowering 与状态反馈

#### 研究问题

如何把 MLIR 中的张量/内存层级信息逐步 lowering 为 UniNDP 类分区、映射和调度指令，并把 DRAM row/buffer 状态反馈回编译决策。

#### 与原论文的区别

不是只复用 UniNDP 的自定义 IR，而是增加标准化多层级 IR、合法性约束和跨算子 lowering。

#### 可能的创新点

设计 NDP memory-space/placement 方言；让跨算子融合和 buffer 生命周期参与搜索；用精确模拟器检查 lowering 后指令依赖。

#### 实验框架

```text
MLIR tensor/affine IR → NDP memory-space lowering → 状态感知候选生成
→ UniNDP 类预测器筛选 → 周期精确模拟 → 端到端算子图比较
```

#### 可行性

需要 MLIR、ONNX/StableHLO 到 NDP 方言的转换、UniNDP 或等价模拟器以及至少一种 NDP 仿真环境。

#### 主要风险

跨算子内存别名、动态形状和模拟器建模误差可能使局部最优策略不再适用于全图。

### 11.2 RISC-V NDP 指令与语义约束的协同生成

#### 研究问题

在 RISC-V 主机加近存 PU 的系统中，如何联合决定 host-side 指令、NDP offload 指令和内存可见性，且保证数据依赖与一致性。

#### 与原论文的区别

原文只把某个 PU 简化为 MAC 单元，并未做 RISC-V ISA 扩展或代码生成；新方向需要处理真实 ISA、ABI、DMA/内存模型和主机运行时。

#### 可能的创新点

定义可验证的 NDP 扩展指令；从 MLIR/LLVM 生成 host/NDP 双侧代码；用模拟器和一致性测试验证依赖。

#### 实验框架

```text
算子 IR → RISC-V/NDP 双侧划分 → 指令选择与地址映射
→ ISA/内存模型检查 → cycle-accurate 仿真 → 性能与正确性评估
```

#### 可行性

需要 RISC-V 工具链、模拟器或 FPGA 原型、NDP 运行时以及可复现的内存一致性测试。

#### 主要风险

仿真器中的强假设可能掩盖真实总线、缓存、异常和同步开销；形式化证明范围也必须明确限定。

### 11.3 预测器—精确模拟器的主动搜索

#### 研究问题

如何根据预测器不确定性选择需要精确模拟的候选，使 top-K 质量和编译时间同时改善。

#### 与原论文的区别

原论文固定采用预测器选 top-K，再用模拟器确认；新方向让精确评估预算随预测误差、架构和候选多样性动态调整。

#### 可能的创新点

不确定性感知的候选采样、排序稳定性估计、硬件架构变化下的迁移预测器以及错误排序的可解释诊断。

#### 实验框架

```text
策略空间 → 轻量预测器 → 预测不确定性分析 → 选择少量精确模拟点
→ 更新排序/模型 → 预算内输出最优策略
```

#### 可行性

可直接复用论文报告的 5 类配置、MM/MVM 工作负载和周期精确模拟器，先验证搜索时间与 top-K 召回率。

#### 主要风险

若候选空间存在分布外策略，预测器可能过度自信；仅依赖 R² 不能保证 top-K 排序正确。

## 12. 与其他已读文献的关系

本轮 slot-5 只完成 UniNDP 一篇论文的独立阅读，没有把正式 corpus 中其他 HPCA 论文当作本轮已读文献，因此不建立未经本轮正文核对的横向方法比较。

从任务定位看，UniNDP 是支持 NDP 编译、模拟和硬件软件协同评估的编译基础设施。它研究的是数据布局/映射/调度与后端硬件状态，不是 pass 选择、LLVM IR 改写、代码修复、LLM 代码生成或形式化验证。与后续工作组合时，它最适合作为性能反馈和候选验证模块；任何组合都需要重新核验 IR 语义、指令依赖和真实硬件可执行性。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 面向多种 NDP 架构的统一编译、模拟与数据部署优化 |
| 核心问题 | 如何共同优化数据分区、映射、调度并快速、准确评估 |
| 输入 | ONNX 算子级 IR、NDP 架构与 DRAM 时序配置 |
| 输出 | NDP 指令序列，以及最优分区/映射/调度策略 |
| 核心方法 | 树形硬件抽象、统一指令集、周期精确模拟、状态剪枝、性能预测器 |
| 使用的模型 | CNN 算子；Llama2-7B/13B/34B 工作负载，不训练 LLM |
| 使用的编译器工具 | UniNDP 自定义编译器与 NDP simulator；参考 PIMSimulator 等 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用周期精确模拟和 simulator 对比验证 |
| 数据集规模 | 无训练数据集；表 IV 给出 CNN/LLM 算子形状 |
| 主要指标 | speedup、clock cycles、simulation/compilation time、R²、DRAM 命令与 row change |
| 最重要实验结果 | 跨架构 CNN/LLM 端到端 1.05–3.43×；预测器每策略 66 µs，但不能替代精确模拟 |
| 核心创新 | 统一多层级 NDP 抽象与硬件状态反馈驱动的编译搜索 |
| 主要局限 | 依赖仿真与硬件假设；refresh 建模有 6–8% 偏差；预测器单独使用会降约 15% |
| 与 RISC-V 研究的相关性 | 低到中；有 RISC-V PU 背景，但没有 RISC-V ISA/后端研究 |
| 最适合作为 | 硬件感知编译搜索、NDP simulator 和硬件软件协同 baseline |

> 这篇论文最值得学习的是把多层级硬件状态、候选编译策略和性能反馈统一到一个可搜索闭环中；最主要的局限是结果主要来自仿真且输入抽象停留在算子级。如果用于后续研究，最合理的使用方式是作为 MLIR/RISC-V/NDP 的性能反馈与候选验证模块，而不是简单替换硬件名称或把仿真 speedup 直接当作真实芯片收益。

---

### 一手来源与核验记录

- 正式 venue/DOI：HPCA 2025，DOI `10.1109/HPCA61900.2025.00054`；DOI 与论文 PDF 首页一致。
- 作者机构全文：<https://nicsefc.ee.tsinghua.edu.cn/%2Fnics_file%2Fpdf%2Fd356f1fd-6204-4b21-8849-a9c3b2e15065.pdf>
- 作者/机构元数据页：<https://researchportal.hkust.edu.hk/en/publications/unindp-a-unified-compilation-and-simulation-tool-for-near-dram-pr/>
- PDF 核验：17 页、`%PDF-1.4`、可解析正文；本 staging 槽位另存正式全文与抽取文本。
- 去重依据：已检查 `taxonomy_v2.csv`、当前角色索引、逐篇阅读目录、年份清单及 `tmp/subagent-staging/batch-9`；未发现 DOI `10.1109/HPCA61900.2025.00054`、题名或版本关系重复项。正式 corpus 中已有的 HPCA 2025 预取论文和 HPCA 2026 HERO-Sign 不同题名、DOI 和研究工作，未重复使用。
