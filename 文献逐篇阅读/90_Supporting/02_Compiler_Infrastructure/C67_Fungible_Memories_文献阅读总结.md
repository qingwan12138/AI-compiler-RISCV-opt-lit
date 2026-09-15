# C67 Fungible Memories 文献阅读总结

论文题目：**Fungible Memories for Automated Technology Mapping and Retargeting**

作者：Zachary D. Sisco、Sijie Kong、Daniel Ruelas-Petrisko、Jingtao Xia、Julian Springer、Varun Rao、Spencer Wang、Gus Henry Smith、Ben Hardekopf、Jonathan Balkind

发表时间：2026

发表平台：PLDI 2026，Proceedings of the ACM on Programming Languages，Vol. 10，Article 216，24 页

论文链接或编号：DOI [10.1145/3808294](https://doi.org/10.1145/3808294)

关键词：硬件描述语言、memory technology mapping、hardware decompilation、equality saturation、PyRTL、RISC-V SoC

> 本文档依据论文正文整理。论文事实、阅读后的分析和后续建议分开描述。

## 1. 研究背景

论文研究 HDL（Hardware Description Language，硬件描述语言）编译与 technology mapping。芯片设计通常需要同时面向仿真、ASIC 和 FPGA；传统做法是在 HDL 中为不同技术分别编写行为等价但实现细节不同的 memory block，并用 `ifdef` 或厂商 IP 选择目标。论文第 1—2 节指出，这会造成重复代码、语义细节不一致、验证负担和设计变更成本。

memory inference 能在部分 FPGA 场景中根据模板推断 BRAM，但不能统一覆盖多种 FPGA/ASIC 技术，也容易受源代码写法影响。论文以具有多个读端口和写端口的寄存器文件为例，说明同一个抽象 memory 可能需要拆分为多块目标 memory，并处理 read/write forwarding、异步读等语义。

## 2. 论文要解决的问题

### 2.1 统一 memory 抽象

如何在 HDL 层表达 memory 的宽度、高度、端口和行为语义，使同一份设计可以被映射到不同技术后端，而不要求设计者手写每种技术的实现。

### 2.2 从已有网表恢复可重定向结构

已有 SoC 往往只有已经综合过的 gate-level netlist。论文研究如何从网表中识别寄存器、读端口和写端口，将它们提升回 fungible memory，从而继续做 technology retargeting。

> 本文主要研究：如何用保持行为等价的重写，把统一的 memory 抽象映射到多种目标技术，并把已有低层网表反向提升为可重定向 memory。

## 3. 核心方法概述

论文提出 fungible memory 抽象和 Memo 编译器。fungible memory 用 algebraic representation 表达 memory 的宽度、高度、端口组合、可选的 write-to-read forwarding 和异步读；目标技术的约束由重写规则表达。Memo 还包含一个从 netlist 反向识别 memory 的 decompiler。

```text
HDL/PyRTL 中的 fungible memory
        ↓
根据端口、宽度和技术约束进行行为保持重写
        ↓
目标技术专用 memory netlist / Verilog / Tcl / OpenRAM 配置

已有 gate-level netlist
        ↓
寄存器聚合、读端口识别、写端口识别
        ↓
equality saturation 与启发式调度
        ↓
fungible memory
        ↓
重新映射到另一种技术
```

论文中的实现基于 PyRTL，但作者说明该抽象原则上可以加入其他 HDL。equality saturation 是非破坏式重写的搜索表示；本文增加了结构感知调度、分阶段处理和面向大网表的优化。本文不使用 LLM；模型最终角色属于传统编译器/硬件基础设施，因此当前 taxonomy 分类为 SUPPORTING / B2。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT 或强化学习，主要采用静态编译、重写和网表反编译流程。

### 4.1 memory 编译

设计者使用单一 fungible memory 描述；Memo 按目标技术支持的 memory 形状和端口约束应用重写。例如，多读端口 memory 可以被拆分为多个较窄或较少端口的 memory，并补充 forwarding 等逻辑。

### 4.2 memory 反编译

对 gate-level netlist，Memo 依次进行 register aggregation、read-port identification、write-port identification 和 fungible-memory extraction。论文第 5 节展示了从 DFF、multiplexer tree 和 decoder tree 恢复 memory 结构的规则。

### 4.3 扩展性优化

论文第 6 节采用 structure-aware equality saturation、分阶段 e-graph 处理以及启发式缩小搜索空间，以处理包含数百万 gate 的网表。之后用 Memo 的后端生成或配置不同目标技术的实现。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有神经网络损失函数。核心是 memory 语法、行为保持重写和 technology constraint。

论文第 3 节给出 fungible memory grammar，抽象形式包括：

```text
mem ::= mem ⊕ mem | Mem(width, height, ports+) ◦ Fwd?
port ::= Read(...) | Write(...) | ReadWrite(...)
```

其中 `⊕` 表示并行组合，`Fwd` 表示可选的 write-to-read forwarding，`Async` 表示异步读。宽度/高度切分、端口拆分和连接变换必须保持 memory 的行为语义；论文第 3.2 节用 Lean 形式化了若干定理和 lemma 的证明。论文中未给出用于 runtime 优化的单一数值目标函数。

## 6. 实验设置

### 6.1 数据集来源

实验包含单 memory 微基准和真实开源 SoC 设计。大规模案例来自 OPDB，包括 OPDB FFT、l1.5 cache、l2 cache 和 SPARC core；另有 BlackParrot RISC-V multicore SoC。论文还使用 bsg_cache、bsg_fifo、bsg_mem_3r1w、nerv、pico、sparc_ffu 等微基准。

### 6.2 模型与工具

系统工具包括 Memo、PyRTL、Yosys、ABC、Verilator、Basejump STL、Vivado Tcl 和 OpenRAM；实验机器为 Intel i9-10850K、64 GB RAM。论文明确使用 equality saturation 和 Lean 形式化证明；没有 LLM 或训练模型。

### 6.3 对比方法

memory decompilation 与 Yosys 以及一个 proprietary synthesis toolchain 的 memory inference 比较。mapping 方面，论文验证生成结果能通过 Basejump STL、synthesizable BRAM、Vivado Tcl 和 OpenRAM 等后端工具链。

### 6.4 评价指标

| 指标 | 含义 |
|---|---|
| Decompiled | 是否恢复出预期 memory 及端口配置 |
| Time | 反编译耗时，秒 |
| Retargeted | 是否成功生成目标后端可接受的 memory 配置 |
| Gates | 输入网表规模，千或百万 gate |

## 7. 实验结果与结论

### 7.1 主要结果

在微基准上，Memo 能恢复预期 memory 配置；例如 bsg_cache 在基线重写下未恢复，但启发式版本成功，bsg_fifo 的 512×512 变体启发式耗时 23 秒，sparc_ffu 也能被恢复，而 Yosys 或 proprietary inference 至少有一个失败。

### 7.2 大规模案例

OPDB FFT、l1.5 cache、l2 cache 和 SPARC core 的预期 memory 均被识别并成功 retarget 到 Vivado Tcl 与 OpenRAM。BlackParrot 总计约 11.8 million gates，启发式 decompilation 在 373 秒内识别 92 个 memory block；论文报告基线在两小时后仍未完成，因此该结果不能解释为相同条件下的全面加速比。

### 7.3 结构与技术覆盖

Memo 能覆盖仿真、ASIC 和 FPGA 后端，并在 BlackParrot 中识别 instruction cache、data cache、BHT、BTB、RAS、整数/浮点 register file 和 FIFO 等结构。byte mask memory 被恢复成多个 1-byte-wide memory，这是从低层实现中恢复语义结构的例子。

### 7.4 消融与启发式效果

第 7 节的 Table 4 比较 baseline 与 heuristic 的阶段耗时。heuristic 主要减少大而杂的网表中 Write Ports 阶段的搜索；对几乎全是 memory 的网表，基线可能更快。论文没有把所有启发式拆成独立的统计消融实验。

## 8. 主要创新点

### 8.1 创新点一：fungible memory 抽象

把跨技术 memory mapping 中通常由专家手写的拆分、组合和端口变换提升为 HDL-level、行为保持的抽象；价值在于“一次描述，多目标映射”。

### 8.2 创新点二：双向 Memo 编译/反编译

同一套多层表示既能把 fungible memory 分解到低层技术实现，也能把已有网表提升回来，从而支持 retargeting。其区别于只做 HDL 模板推断的工具，是直接利用网表结构。

### 8.3 创新点三：面向大网表的结构感知 equality saturation

作者将分阶段处理、结构感知调度和启发式限制结合起来，使 memory decompilation 能扩展到百万级 gate，并在 BlackParrot 上运行。实验对这一扩展性给出了直接证据。

## 9. 局限性

### 论文明确承认的局限

- fungible memory 当前建模的 latency 主要为 0 或 1 cycle，不能直接自动 pipeline 多周期 read。
- memory banking、更加细粒度的 timing 优化和 cache banking 仍是后续方向。
- decompiler 依赖已有 rewrite rules；若激进逻辑优化隐藏了 memory 结构，或某种 memory feature 没有对应规则，可能无法识别。
- ASIC 目标仍依赖后端 memory compiler，例如 OpenRAM；Memo 不替代所有 foundry/compiler 细节。

### 阅读后发现的潜在局限

本文实验覆盖的 technology backend 和开源 SoC 很有价值，但不能据此推断对所有工艺节点、商业 IP 或复杂时序 memory 都同样有效。验证重点是配置恢复和后端接受，不等同于在真实芯片上完成 PPA 最优设计。

## 10. 阅读后的研究方向反思

值得借鉴的是“先把目标约束和语义放到中间表示，再用可验证变换连接多种后端”的思路。对 LLVM/RISC-V 研究，类似做法可用于把 ISA 特性、memory ordering 或 accelerator capability 显式化；但简单把目标从 FPGA/ASIC 换成 RISC-V 并不足以构成新贡献。本文的核心贡献是 hardware-level abstraction、双向 lifting 和可扩展重写，而不是 LLM 生成。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V memory/extension 的统一硬件-编译器抽象

#### 研究问题

如何让 RISC-V 扩展、cache/寄存器文件和不同实现约束在统一 IR 中表达并自动选择合法映射。

#### 与原论文的区别

扩展对象从 memory technology mapping 延伸到 ISA extension 与软件编译约束的协同，不只是换后端名称。

#### 可能的创新点

把 ISA 语义、端口资源和验证条件统一到可重写表示中，并验证生成代码/硬件接口的一致性。

#### 实验框架

```text
RISC-V/硬件设计描述 → 统一 IR → 约束驱动重写 → RTL/LLVM 后端 → 仿真与等价验证
```

#### 可行性

需要 LLVM/RISC-V 后端、RTL 仿真器、形式等价工具和若干开源 SoC。

#### 主要风险

ISA、RTL 和真实微架构约束之间的语义边界较难完整建模。

### 11.2 结构感知 equality saturation 的成本模型学习

研究问题是如何在不破坏等价性的前提下为 e-graph 调度和 extraction 学习硬件面积、时序或能耗成本。区别在于学习只影响搜索/提取策略，不替代论文已有的语义规则；风险是成本估计与真实 PPA 之间存在偏差。

## 12. 与其他已读文献的关系

与本轮的 “A Compiler for Fused Relational Operations on Multisets” 相比，两者都通过中间表示和结构化代码生成扩展编译器覆盖范围：Memo 面向硬件 memory 的跨技术映射与反编译，后者面向关系代数的融合与 C++ 代码生成。Memo 更接近硬件基础设施和 retargeting 工具；关系代数编译器更接近数据处理 DSL 编译器。两者都支持从高层语义到低层实现的系统化 lowering，但研究对象、评价基准和正确性边界不同，不能直接视为同一方法的重复。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 跨仿真、ASIC、FPGA 的 memory mapping 与 netlist decompilation |
| 核心问题 | 避免为每种技术重复手写 memory 实现，并恢复已有网表中的 memory |
| 输入 | HDL/PyRTL fungible memory 或 gate-level netlist |
| 输出 | 目标技术 memory 实现、后端配置或恢复的 fungible memory |
| 核心方法 | fungible memory、Memo、equality saturation、结构感知启发式 |
| 使用的模型 | 无神经模型；Lean 用于部分形式化证明 |
| 使用的编译器工具 | PyRTL、Yosys、ABC、Verilator、Vivado Tcl、OpenRAM |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 是，行为保持重写与 Lean 证明；实验也用工具链验证配置 |
| 数据集规模 | 微基准、4 个 OPDB 案例和 11.8M-gate BlackParrot |
| 主要指标 | memory 恢复、耗时、gate 数、后端 retarget 成功 |
| 最重要实验结果 | BlackParrot 373 秒识别 92 个 memory，多个后端 retarget 成功 |
| 核心创新 | 可重定向 memory 抽象、双向编译/反编译、可扩展结构感知重写 |
| 主要局限 | 多周期 latency、banking 和未覆盖 rewrite rule 仍有限 |
| 与 RISC-V 研究的相关性 | 中高：BlackParrot RISC-V SoC 是重要案例，但论文主题不是 RISC-V ISA 优化 |
| 最适合作为 | 硬件编译基础设施、retargeting 方法参考和 RISC-V SoC 工具模块 |

这篇论文最值得学习的是把跨后端差异提升为可验证的中间表示变换；最主要的局限是 timing 和未建模硬件特性仍依赖人工规则；如果用于后续研究，最合理的使用方式是借鉴其 abstraction/lifting 设计，而不是简单把平台替换成另一种 ISA。
