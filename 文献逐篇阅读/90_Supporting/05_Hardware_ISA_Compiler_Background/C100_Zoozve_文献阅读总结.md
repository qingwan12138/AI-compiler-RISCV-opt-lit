# Zoozve 文献阅读总结

论文题目：**Zoozve: A Strip-Mining-Free RISC-V Vector Extension with Arbitrary Register Grouping Compilation Support (WIP)**

作者：Siyi Xu、Limin Jiang、Yintao Liu、Yihao Shen、Yi Shi、Shan Cao、Zhiyuan Jiang

发表时间：2025 年

发表平台：LCTES ’25（第 26 届 ACM SIGPLAN/SIGBED International Conference on Languages, Compilers, and Tools for Embedded Systems）；WIP 论文，ACM 会议版本 6 页

论文链接或编号：[DOI 10.1145/3735452.3735526](https://doi.org/10.1145/3735452.3735526)；[arXiv:2504.15678](https://arxiv.org/abs/2504.15678)

关键词：RISC-V、RVV、向量处理、LLVM、编译器后端、任意寄存器分组、strip-mining、硬件实现

> 本笔记依据 staging 中的正文 PDF `Zoozve_LCTES25.pdf`（arXiv v2，6 页）通读整理。论文事实、阅读分析和后续建议分开描述；本文不分配正式 Paper_ID，也不代表已同步正式 taxonomy。

---

## 1. 研究背景

本文属于嵌入式系统中的向量 ISA 与编译器后端协同设计。现代向量扩展（如 ARM SVE 与 RISC-V V/RVV）允许向量长度动态变化，相比固定长度向量寄存器具有更好的硬件/软件适配性。论文将问题聚焦到 RVV 在超长向量和不规则工作负载上的限制。

RVV 的向量寄存器组（register group，RG）受固定寄存器数量和二次幂 LMUL 分组约束。较大的 LMUL 可以容纳更多元素，但会减少可分配的寄存器组并增加寄存器压力与 spill；较小的 LMUL 又会导致更多 strip-mining（把长向量切成多段、在循环中逐段处理）。论文引言和第 2 节指出，这种折中会增加动态指令、尾部数据处理与编程调优复杂度，尤其影响无线通信、人工智能等超长向量应用。

因此，作者尝试同时改变 ISA、寄存器分组策略和 LLVM 编译流程，使超长向量可以在更少的 strip-mining 迭代中完成。

## 2. 论文要解决的问题

### 2.1 RVV 固定寄存器分组造成的利用率问题

RVV 的 power-of-two RG 可能无法精确匹配程序的向量长度。第 2 节给出的两类情况是：

1. 对较短向量，向量长度可能落在两个可用 LMUL 容量之间，从而造成寄存器未充分利用。
2. 对较长向量，strip-mining 的尾部数据可能占用较高 LMUL 的寄存器组，带来额外开销。

### 2.2 编译器如何支持非标准向量类型和连续寄存器组

如果 ISA 允许任意寄存器分组，LLVM 仍需解决：如何从高层 vector type 产生可管理的 IR、如何保证相关虚拟寄存器连续分配、以及如何把拆分后的指令重新合并为一条 Zoozve 指令。

### 2.3 总体研究问题

> 本文主要研究：如何通过一种支持任意寄存器分组且免 strip-mining 的 RISC-V 向量扩展，并配套 LLVM intrinsic splitting、live interval 修改和 assembly coalescing，使超长向量 kernel 减少动态指令开销。

## 3. 核心方法概述

Zoozve 是一个面向 RISC-V 的向量指令扩展。它使用可扩展的向量寄存器访问方式、由数据类型决定的任意寄存器组和异构长度的 gather/scatter 指令，以减少 RVV 的分段循环。论文同时给出 LLVM 编译支持和 SystemVerilog 硬件原型。

```text
C 程序 / Zoozve builtin
        ↓
Clang intrinsic library mapping
        ↓
LLVM IR
        ↓ intrinsic splitting + delimiter 标记
        ↓ live interval modification + register allocation
        ↓ assembly coalescing
Zoozve 汇编 / 可执行文件
        ↓
Spike 或自定义 Zoozve simulator 统计动态指令
```

方法要点如下：

* 指令使用 `v_head` 表示向量寄存器起始位置，`rs_avl` 表示目标向量长度；论文称这种编码可访问最多 `2^13` 个向量寄存器，并可通过 `vsetcsr` 扩展控制信息。
* Zoozve 的 RG 由编译器分配的 `RG_head` 与高层 vector type 决定，`RG_tail = RG_head + RG_type / VLEN`。
* 对不同源/目的长度，scatter 可执行 `vd[vs2[i]] ← vs1[i]`，gather 可执行 `vd[i] ← vs1[vs2[i]]`；这与 RVV `vrgather` 要求源和目的使用相同 VL 的方式不同。
* LLVM pass 先拆分 intrinsic，再保持连续寄存器的生命周期，最后合并连续且 mnemonic、参数、VL 相同的 Zoozve assembly。

论文不把 LLM、强化学习或自动代理作为系统组件；核心是 ISA—LLVM—硬件协同设计。

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用静态编译流程、模拟器执行统计和硬件综合。

### 4.1 编译执行流程

1. Clang builtin 为程序员提供 Zoozve 操作接口，并显式指定 vector value type。
2. builtin 通过 intrinsic library mapping 转换为 LLVM intrinsic；高层变量经 SSA 转换为虚拟寄存器。
3. intrinsic splitting pass 把原始 intrinsic 拆成具有具体 value type 的多个 IR，并插入 delimiter intrinsic，指导后续寄存器连续分配。
4. 在 lifetime analysis 与 register allocation 之间执行 live interval modification，使 split virtual registers 保持期望的生命周期并进入指定分配队列。
5. assembly coalescing pass 检测连续向量寄存器、相同 mnemonic、相同参数和相同 VL 的连续指令，将其合并为 Zoozve 指令。
6. 生成机器码并用 Spike、自定义 Zoozve simulator 或硬件原型评估。

### 4.2 Artifact 工作流

附录 A 说明 artifact 可通过 GitHub、Zenodo Docker 环境或 Google Drive 获取。示例工作流为 `C → clang → test.0.ll → opt → test.split.ll → llc → assembly/machine code`。论文称当前实现只运行 debug mode，约需 100 GB 磁盘空间；推荐 Ubuntu 22.04 Docker 环境。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数，也没有神经网络训练损失函数。

论文中的关键编译计算包括：

```text
RG_type = L × VEW
RG_tail = RG_head + RG_type / VLEN
VTYPE_SPLIT_NUM = ceil(VTYPE / VLEN)
```

其中：

| 符号 | 含义 |
| --- | --- |
| `L` | 编程语言中声明的向量长度 |
| `VEW` | 向量元素位宽 |
| `VLEN` | 单个硬件向量寄存器的位宽 |
| `RG_head` | 寄存器分配得到的起始寄存器 |
| `RG_tail` | 根据 vector type 计算出的寄存器组末端 |
| `VTYPE` | LLVM intrinsic 中的逻辑向量类型 |

这些式子服务于寄存器组范围计算和 intrinsic 拆分，不是优化目标函数。论文没有给出额外的代价函数、奖励冲突或奖励投机分析。

## 6. 实验设置

### 6.1 数据集来源

本文没有机器学习数据集。实验 kernel 包括：

* `dotproduct` 与 `axpy`，来源为 OpenBLAS；
* 手工实现的 `fft` kernel。

这些程序被作者用于代表科学计算、信号处理和机器学习工作负载。论文没有报告训练/验证/测试集划分，也没有给出数据泄漏分析。

### 6.2 模型与工具

本文不使用模型。工具和平台包括：

* LLVM 15.6.0；
* Clang、`opt`、`llc`、`llvm-objdump`；
* Spike RISC-V ISA simulator；
* 自定义 Zoozve simulator；
* SystemVerilog 硬件原型；
* SMIC 40 nm 工艺，400 MHz 综合条件；
* 64 lanes、1024 registers 的硬件配置。

附录表 1 列出 `venusbuiltin.h`、`venustype.h`、`test.0.ll`、`test.split.ll`、`test_before_merge.s`、`test.s`、可执行文件和反汇编文件等产物。

### 6.3 对比方法

主要 baseline 是 RVV，包括不同 LMUL 设置下的 RVV strip-mining 实现。实验中的 Zoozve 配置包括 FFT 的 LMUL=64、dotproduct 的 LMUL=1024，以及 axpy 中的 LMUL=16 和 LMUL=1024 对照。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Dynamic instruction count | kernel 动态执行的指令数量 | 越少越好 |
| Instruction-count speedup/ratio | RVV 动态指令数相对 Zoozve 的比值 | 越大越好 |
| Strip-mining iterations | 分段向量循环的迭代次数 | 越少越好 |
| Synthesis/layout area | 硬件综合面积与布局面积 | 需结合性能权衡 |
| Area overhead | 相对基线硬件的面积增加比例 | 越小越好 |

论文没有把动态指令数直接等同于真实芯片运行时间；该指标主要反映指令流和 strip-mining 开销。

## 7. 实验结果与结论

### 7.1 主要结果

根据第 4.2 节和图 3，Zoozve 在三个 kernel 上都减少了动态指令和 strip-mining：

* FFT：数据规模 32 到 2048 points 时，动态指令比值从 10.10× 增至 344.44×。Zoozve 避免了 RVV 的 LMUL 限制和分段循环。
* dotproduct：数据规模 512 到 16,384 时，RVV 指令数从 52 增长到 1292，strip-mining 从 8 次增至 256 次；Zoozve 保持 17 条指令，最高达到 76×。
* axpy：数据规模 512 到 16,384 时，RVV 指令数从 25 增至 707，strip-mining 从 2 次增至 64 次；Zoozve 在对应配置下保持 12 条指令，最高达到 58.92×。图 3 还展示了 LMUL=16 的另一组 Zoozve 曲线，需与 LMUL=1024 曲线区分。

### 7.2 与传统 RVV 方法的比较

Zoozve 的主要优势来自消除 strip-mining 和更精确的寄存器复用，而非某个传统 LLVM pass 的单独改进。实验对比的是 RVV kernel 与 Zoozve kernel 的动态指令流，不是完整应用的端到端墙钟时间。

### 7.3 与其他 LLM 方法的比较

不适用。本文没有 LLM baseline。

### 7.4 消融实验

论文没有报告独立的模块消融表。正文展示了三类 kernel、不同向量规模和 LMUL 设置，但不足以把任意寄存器分组、异构 gather/scatter、intrinsic splitting 与 assembly coalescing 的贡献逐项分离。

### 7.5 硬件与 artifact 结果

硬件 proof-of-concept 在控制路径加入 RG 范围比较与 hazard 检测，在数据路径加入由 crossbar 和多个 processing elements 构成的 shuffle engine，以支持 lane 间非对称操作。64-lane、1024-register 配置在 SMIC 40 nm、400 MHz 条件下得到 7.2 mm² synthesis area 和 11.9 mm² layout area，论文报告整体面积开销为 5.2%。该结果证明了实现可行性，但不是完整芯片流片结果。

## 8. 主要创新点

### 8.1 创新点一：免 strip-mining 的向量 ISA 设计

现有 RVV 通过动态 VL 与循环 strip-mining 处理超出寄存器容量的数据。Zoozve 扩大向量寄存器访问范围并允许按应用配置寄存器数量和维度，使长向量可以减少分段循环。图 3 的动态指令结果支持这一设计在三个 kernel 上有效。

### 8.2 创新点二：任意且数据自适应的寄存器分组

RVV 的 RG 主要受二次幂 LMUL 限制；Zoozve 依据 `RG_head` 和 vector type 计算寄存器范围，允许非二次幂分组，并通过寄存器起止范围比较进行 hazard 检测。这是 ISA 设计、编译器寄存器分配和硬件控制协同的关键机制。

### 8.3 创新点三：配套 LLVM 编译支持

论文不是只提出硬件扩展，而是给出了 intrinsic splitting、delimiter 引导的连续寄存器分配、live interval modification 和 assembly coalescing。这样高层 builtin 才能落到可执行的 Zoozve 指令流。论文的实验和 artifact appendix 对该编译链给出了可复现产物说明。

### 8.4 创新点四：源/目的向量长度不对称的 gather/scatter

Zoozve 允许源向量与目标向量具有不同 VL，减少长度差异较大时的寄存器浪费。论文将其作为面向不规则向量数据处理的 ISA 能力，而不是单纯复制 RVV `vrgather`。

## 9. 局限性

### 9.1 论文明确承认或正文直接显示的局限

* 论文标题标注 WIP，篇幅为 6 页，实验和硬件设计属于初步结果。
* 实验只覆盖 FFT、dotproduct 和 axpy 三个 kernel；对复杂控制流、跨函数优化、真实应用和更多向量数据类型的表现，论文中未明确说明。
* 论文使用 Spike 和自定义 simulator 统计动态指令；正文没有给出真实 Zoozve 芯片上的端到端运行时间、功耗或能效测量。
* artifact 说明当前实现只运行 debug mode，约需 100 GB 磁盘空间；这会提高复现实验的资源门槛。
* 论文没有报告系统性的编译时间、代码尺寸、功耗、频率收益或异常/中断语义分析。

### 9.2 阅读后发现的潜在局限

* Zoozve 引入非标准 RISC-V custom opcode 和更大寄存器访问空间，生态兼容性、上下文切换、ABI、调试器和操作系统支持仍需验证；论文正文未展开这些问题。
* 5.2% 面积开销与动态指令下降之间的能效关系不能仅由面积和模拟器指令数推出，需要真实微架构执行、内存系统和功耗评估。
* 任意寄存器组与 live interval 修改可能使寄存器分配、调用约定和寄存器压力在大型程序中变复杂；论文没有提供大规模程序上的编译稳定性数据。
* 论文未给出与 RVV 1.0 兼容性、迁移成本或 fallback 路径的详细设计，因此不能直接推断其可替代通用 RVV 后端。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把“硬件能力—IR 表示—寄存器分配—最终指令合并”作为一个闭环处理。对于 LLVM/RISC-V 研究，若只改后端 pattern 而不处理 vector type、live interval 和 assembly 组织，往往无法实现真正的 ISA 能力。

### 10.2 不能简单照搬的部分

直接把 Zoozve 的 custom opcode 或寄存器数量搬到另一种 RISC-V 核心，不足以构成新的研究贡献。需要回答兼容性、面积/功耗、编译器退化路径和真实负载收益等问题。

### 10.3 与 AI 编译器方向的关系

论文不是 AI 方法论文，但它为 AI kernel 编译提供了可研究的后端能力：任意分组可以降低超长张量向量化的寄存器浪费，异构 gather/scatter 可表达不规则数据布局。相关性主要体现在代码生成和硬件协同，不应将本文描述成 LLM 或自动调优工作。

### 10.4 适合作为哪类研究基础

本文更适合作为 RISC-V 向量后端、ISA/编译器协同设计的 baseline 或工具模块；若研究目标是 LLM 编译优化，它可以作为目标后端、结构化反馈源或验证对象，而不是现成的训练方法。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的兼容式任意分组后端

#### 研究问题

能否在保留 RVV fallback 的前提下，让 LLVM 根据向量长度、寄存器压力和目标核心能力选择标准 RVV 或 Zoozve-like 扩展路径？

#### 与原论文的区别

重点从“提出一个扩展”转向“可移植、可退化的多目标后端决策”。

#### 可能的创新点

目标特性检测、代价模型、标准 RVV 与扩展指令的混合代码生成，以及调用边界上的状态管理。

#### 实验框架

```text
LLVM IR → 目标特性/寄存器压力分析 → RVV 或扩展路径选择
        → codegen → Spike/RTL/真实 RVV 硬件对比
```

#### 可行性

可从 LLVM RISC-V 后端、Spike 和 Zoozve artifact 开始，逐步加入 RVV 1.0 硬件或 RTL 模拟。

#### 主要风险

扩展指令的 ABI、上下文保存和混合执行语义可能比 kernel 级实验复杂。

### 11.2 面向不规则张量 kernel 的结构化编译反馈

#### 研究问题

如何把寄存器组利用率、strip-mining 次数、动态指令和验证结果组合成可供自动优化器使用的结构化反馈？

#### 与原论文的区别

原论文提供静态编译机制和模拟评估；该方向研究反馈驱动的 pass/代码生成选择。

#### 可能的创新点

将 RG 利用率与真实硬件计数器、编译合法性和内存访问行为联合建模，而不是只优化单一指令数。

#### 实验框架

```text
张量 kernel → LLVM 编译候选 → RVV/扩展模拟或硬件
        → 正确性检查 + 性能/能效反馈 → pass 或配置更新
```

#### 可行性

适合使用 MLIR/LLVM、OpenBLAS/常见张量 kernel、Spike/RTL 和少量真实板卡数据。

#### 主要风险

模拟器指标与真实硬件性能可能不一致，且多目标反馈容易出现优化冲突。

### 11.3 Zoozve-like 向量语义的验证与 fuzzing

#### 研究问题

如何验证任意寄存器组、非对称 gather/scatter、hazard 检测和 LLVM lowering 在边界 VL 下的语义一致性？

#### 与原论文的区别

原论文主要验证可编译和指令数量收益；该方向增加 translation validation、差分执行和 fuzzing。

#### 可能的创新点

构造高层向量语义、LLVM IR、Zoozve simulator、RTL 之间的多层差分 oracle，并覆盖寄存器重叠和尾部元素。

#### 实验框架

```text
随机/变形向量程序 → Clang/LLVM lowering → simulator 与 RTL 双执行
        → RVV/reference 结果比较 → 自动缩减失败样例
```

#### 可行性

可复用 LLVM、Spike、硬件仿真器和现有 compiler fuzzing 框架。

#### 主要风险

需要先定义清晰的未定义行为、异常和内存别名语义，否则差分失败难以归因。

## 12. 与其他已读文献的关系

本批次当前只完成 Zoozve 一篇论文，因此没有另一篇已通读文献可进行事实层面的横向比较，也不虚构外部论文的实验内容。

从研究角色看，Zoozve 位于“代码生成/编译器后端 + RISC-V 向量硬件协同”交叉点：它不是 pass 选择器、LLM IR 改写器、形式化验证器或训练数据集。后续若与这些方向组合，Zoozve 最自然的角色是目标 ISA、后端工具链和可测量的硬件反馈环境。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 为超长向量设计免 strip-mining 的 RISC-V 向量扩展及 LLVM 支持 |
| 核心问题 | RVV 固定寄存器数、二次幂 LMUL 和尾部 strip-mining 带来的寄存器浪费与动态指令开销 |
| 输入 | C 程序、Zoozve builtin、LLVM IR |
| 输出 | Zoozve LLVM IR、汇编、机器码和硬件原型 |
| 核心方法 | 任意寄存器分组、非对称 gather/scatter、intrinsic splitting、live interval 修改、assembly coalescing |
| 使用的模型 | 不使用机器学习模型 |
| 使用的编译器工具 | LLVM 15.6.0、Clang、opt、llc、llvm-objdump |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；提供 simulator 与硬件 proof-of-concept，但不是形式化证明 |
| 数据集规模 | 无机器学习数据集；3 类 kernel：FFT、dotproduct、axpy |
| 主要指标 | 动态指令数、instruction-count ratio、strip-mining 次数、面积 |
| 最重要实验结果 | FFT 32–2048 points 达到 10.10×–344.44×；dotproduct 最高 76×；axpy 最高 58.92×；硬件面积开销 5.2% |
| 核心创新 | ISA、LLVM 寄存器分配和硬件共同支持任意寄存器分组并减少 strip-mining |
| 主要局限 | WIP 初步工作；kernel 数量少；主要依赖模拟器；缺少真实硬件性能/功耗与生态兼容性评估 |
| 与 RISC-V 研究的相关性 | 高：论文直接提出并实现 RISC-V 向量扩展与 LLVM 后端 |
| 最适合作为 | RISC-V 向量代码生成 baseline、ISA/编译器协同设计参考、后端工具模块 |

> 这篇论文最值得学习的是把向量 ISA 的寄存器组织问题落实到 LLVM IR 拆分、生命周期处理和最终指令合并；最主要的局限是实验规模小且动态指令模拟不能替代真实硬件性能与能效验证；如果用于后续研究，最合理的使用方式是作为 RISC-V 向量后端和验证对象，而不是简单复制 custom opcode 或把平台名称替换成另一种硬件。
