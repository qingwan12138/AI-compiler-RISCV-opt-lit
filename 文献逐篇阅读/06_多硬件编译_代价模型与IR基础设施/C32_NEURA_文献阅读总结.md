# NEURA 文献阅读总结

论文题目：**NEURA: A Unified and Retargetable Compilation Framework for Coarse-Grained Reconfigurable Architectures**

作者：Shangkun Li、Jinming Ge、Diyuan Tao、Zeyu Li、Jiawei Liang、Linfeng Du、Jiang Xu、Wei Zhang、Cheng Tan

发表时间：2026

发表平台：PLDI 2026

论文链接或编号：DOI `10.1145/3808285`；arXiv `2604.04236`

关键词：CGRA、数据流 IR、谓词类型、MLIR、可重定向编译、控制流扁平化

> 本文档用于文献阅读、组会汇报和后续研究分析。论文事实与阅读后的研究思考需要分开描述。

## 1. 研究背景

粗粒度可重构阵列（Coarse-Grained Reconfigurable Architecture，CGRA）在专用加速器性能和通用处理器可编程性之间折中。其计算阵列天然执行数据流图（DFG），而源程序和 LLVM/MLIR 前端通常表达为带循环、分支的控制数据流图（CDFG）。论文第 1、2 节指出，依赖主机控制器、逐基本块重配置或有限 if-conversion 的方案会产生串行化、控制开销和层级谓词丢失。

## 2. 论文要解决的问题

### 2.1 消除控制流与数据流执行模型的语义鸿沟

复杂嵌套循环和循环内分支需要同时表达控制上下文、数据依赖和状态访问；传统 CDFG 表示不能把层级谓词显式传播到每个值。

### 2.2 同一编译表示支持不同 CGRA

空间型和时空型 CGRA 的执行模型、微架构和专用功能单元不同。论文希望让内核表示与硬件执行模型解耦，同时仍能利用硬件特定优化。

> 本文主要研究：如何在 MLIR 上构建带层级谓词的纯数据流 IR，将复杂控制流扁平化为统一 DFG，并重定向到空间型和时空型 CGRA。

## 3. 核心方法概述

NEURA 为每个值增加一个布尔有效谓词，把控制上下文作为数据的一部分。`<τ, i1>` 表示载荷类型为 `τ`、谓词为 `i1` 的值；谓词管理操作把分支和循环条件变成显式数据依赖。NEURA 先将 LLVM/MLIR CDFG 规范化，再提升为谓词值、生成统一 DFG，随后执行硬件无关和硬件特定优化，最后映射到目标 CGRA。

```text
C/C++ 或 MLIR 高层内核
        ↓
MLIR 前端与 LLVM/arith/memref 表示
        ↓
NEURA CDFG IR：规范化 CFG、显式活跃值和边
        ↓
谓词类型提升 + 控制流扁平化
        ↓
NEURA Dataflow IR：单一统一 DFG
        ↓
硬件无关优化 + 硬件特定优化
        ↓
解释器/映射器
        ↓
空间型或时空型 CGRA 的配置与周期级模拟
```

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT 或强化学习，主要采用 MLIR 编译 passes、IR 语义规则、硬件映射和周期精确模拟。

### 4.1 IR 构造与降低

输入先被表示为函数形式，消除不能直接携带值的活跃边。NEURA CDFG IR 作为 LLVM 风格的规范化中间层，显式记录块参数和控制依赖。随后 `leverage-predicated-value` 将普通 SSA 值转换为带谓词类型的值，谓词管理操作将 CFG 边和层级控制转换为数据依赖。

### 4.2 硬件无关优化

论文第 6.1 节实现类型宽度规范化、常量折叠等优化，减少冗余转换、常量计算节点和谓词管理开销。这些优化不绑定具体 CGRA。

### 4.3 硬件特定优化与映射

第 6.2 节针对目标微架构加入计算模式融合、地址计算与访存融合、循环流式化等变换。映射器根据执行模型、硬件资源和 II（Initiation Interval，启动间隔）寻找映射结果，并可输出周期级模拟配置或 bitstream。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数。核心形式化对象是谓词类型和操作语义：

```text
PredType(τ) = (d : τ, p : i1)
```

其中 `d` 是数据载荷，`p` 表示该值在当前执行路径上是否有效。对计算操作，输出谓词通常由输入谓词合取得到；对 `grant_predicate(val, cond)`，输出谓词由 `val` 的谓词与 `cond` 的谓词合取产生。论文用大步结构操作语义描述这些操作，保证无效谓词不会错误触发状态访问。

实验优化目标主要是降低周期级执行延迟和 II，同时观察 IPC、性能/面积和能耗；不是一个训练损失函数。

## 6. 实验设置

### 6.1 数据集来源

内核来自 PolyBench、MachSuite、CGRA-Bench 和 CHStone，覆盖机器学习、线性代数、信号处理和图算法，包含嵌套循环、循环内分支和长数据依赖。应用级测试包括来自 PyTorch-Geometric 的两层 GCN，以及来自 CGRA-Bench 的 LU 分解。

### 6.2 模型与工具

NEURA 在 MLIR 基础设施上实现约 15K 行 C++。作者实现两种 RTL 原型：空间型 `NEURA-SO` 与时空型 `NEURA-ST`，都使用 6×6 tile 阵列、King Mesh NoC 和最小 ISA 扩展。周期精确模拟器计入主机—CGRA 通信；面积用 Synopsys Design Compiler 和 TSMC 22nm ULL library、800MHz 评估。

### 6.3 对比方法

三类主要 baseline 是 Marionette（CDFG/控制器策略）、RipTide（steering control、空间型策略）和 ICED（有限谓词策略）。各框架使用自己的编译器生成表示，再使用相同映射算法，并统一到 800MHz 和 6×6 阵列。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
|---|---|---|
| Speedup | 相对架构基线的执行速度 | 越大越好 |
| IPC | tile 执行总数除以执行延迟，表示 ILP 利用 | 越大越好 |
| Perf/Area | 性能与芯片面积的比值 | 越大越好 |
| Area overhead | ISA 扩展相对 vanilla 设计的面积增加 | 越小越好 |
| Energy/Execution time | 空间型 CGRA 的能耗或执行时间 | 依目标而定 |

## 7. 实验结果与结论

### 7.1 硬件开销

6×6 阵列综合结果显示，NEURA-SO 的 ISA 扩展面积增加 1.89%，NEURA-ST 增加 1.39%，两者仍保持 800MHz。

### 7.2 时空型 CGRA

在内核 benchmark 上，NEURA-ST 相对 Marionette、ICED、RipTide 的几何平均 speedup 分别为 2.20×、2.24×、2.42×；对具有层级嵌套控制流的 benchmark，相对 ICED 为 2.50×；对长数据依赖 benchmark，相对 RipTide 为 3.59×。相对 Marionette 的几何平均 Perf/Area 为 6.40×，相对 ICED 为 2.15×。

### 7.3 空间型 CGRA与优化消融

NEURA-SO 在低功耗空间型场景与 RipTide 具有竞争力，但某些带专用 merge 操作的 benchmark 上 RipTide 能耗更低。硬件无关的类型对齐和常量折叠带来 1.69× 几何平均 speedup；加入计算模式融合后为 1.79×，再加入循环流式化后相对未优化表示为 2.19×。

### 7.4 可扩展性与真实应用

同一 NEURA Dataflow IR 从 4×4 扩展到 6×6 NEURA-ST，在测试 benchmark 上得到 1.34× 几何平均 speedup。GCN 和 LU 分解应用上，NEURA-ST 相对所有 baseline 的几何平均 speedup 分别为 2.57× 和 2.71×；NEURA-SO 则与低功耗 RipTide 接近。

## 8. 主要创新点

### 8.1 带谓词类型的纯数据流 IR

将控制上下文嵌入每个值，而不是把控制留给外部控制器，使复杂嵌套控制流可表示为单一 DFG。论文用类型、操作表和结构操作语义明确描述该设计。

### 8.2 面向多执行模型的可重定向框架

同一 IR 可分别降低到空间型和时空型 CGRA，并通过硬件特定 pattern rewriting 加入微架构能力，兼顾通用表示和专用优化。

### 8.3 编译器与硬件开销的协同设计

只增加少量 predicate 相关 ISA 指令和位传播机制，在低面积开销下消除控制器串行化；实验结果支持其性能/面积收益。

## 9. 局限性

### 9.1 论文明确或实验暴露的限制

实验使用作者设计的两种 CGRA 原型和周期精确模拟，论文没有提供通用商用 CGRA 真机结果。NEURA-SO 在部分具有专用选择/合并硬件的 benchmark 上能耗不如 RipTide。6×6 阵列在许多 benchmark 上已被迭代依赖限制，资源扩展收益不是线性的。

### 9.2 阅读后的潜在限制

框架当前主要从 C/C++ 和 MLIR 内核出发，论文中对 PyTorch 支持仍写为计划扩展；对复杂内存别名、动态形状和跨 kernel 全局调度的适用范围，当前 PDF 内容不足以确认。谓词位的传播和映射还依赖目标 CGRA 支持相应 ISA 扩展，不能直接等同于普通 CPU/RISC-V 后端方案。

## 10. 阅读后的研究方向反思

NEURA 的核心价值在于把硬件控制语义提升为可优化的 IR 属性，并以同一表示承载多种执行模型。它适合作为多硬件编译、IR 设计和真实后端映射的基础设施参考。将 NEURA 直接移植到 RISC-V 并不足以形成新贡献；更有潜力的方向是研究 RVV 的谓词/向量长度语义、RISC-V 加速器协同接口，或把其可重定向 IR 与真实硬件反馈结合。Poseidon 的数值反馈闭环可作为上层优化模块，但二者的直接组合尚未由论文验证。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV/CGRA 协同的谓词向量 IR

#### 研究问题

如何在同一 IR 中同时表示 RVV mask、可变向量长度和 CGRA 层级谓词，并保持 lowering 语义清晰。

#### 与原论文的区别

目标从 CGRA 内部执行模型扩展到 RISC-V 主机与可重构加速器协同，不是仅复现 NEURA 的 predicate type。

#### 可能的创新点

设计统一 predicate/vector type，研究跨 ISA 的代价模型和数据搬运优化。

#### 实验框架

```text
MLIR kernel → 统一谓词向量 IR → RVV/CGRA lowering → 真实后端 → 性能与能耗反馈
```

#### 可行性

需要 MLIR、LLVM RVV、CGRA 模拟器或 FPGA 原型，以及小型控制流 benchmark。

#### 主要风险

两种执行模型的同步、内存一致性和 mask 语义可能造成复杂的验证负担。

### 11.2 反馈驱动的可重定向映射选择

#### 研究问题

如何根据周期级模拟或真实硬件反馈选择加速粒度、tile 大小和硬件特定 rewrite。

#### 与原论文的区别

将 NEURA 的静态映射流程扩展为跨硬件反馈优化，并显式处理编译时间成本。

#### 可能的创新点

建立统一的 latency/area/energy 代价模型，支持不同 CGRA 与 RISC-V 主机的迁移。

#### 实验框架

```text
候选 IR/映射 → 周期模拟或板卡运行 → 代价模型更新 → 选择粒度与优化组合
```

#### 可行性

论文已提供 MLIR passes、映射器思路和开源项目线索，可作为实现起点。

#### 主要风险

硬件反馈昂贵，且不同架构的代价不可直接比较。

## 12. 与其他已读文献的关系

本批次 Poseidon 关注浮点表达式的数值反馈和重写，NEURA 关注控制流扁平化、数据流 IR 和 CGRA 映射；二者分别位于编译优化决策和后端基础设施层。NEURA 可作为多硬件 IR/真实后端参考，Poseidon 可作为上层数值优化 baseline。当前批次没有证据表明二者存在重复实现。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 面向 CGRA 的统一可重定向编译 |
| 核心问题 | 控制流与数据流执行模型不匹配 |
| 输入 | C/C++、LLVM/MLIR 内核 |
| 输出 | 目标 CGRA 的统一 DFG、映射结果和配置 |
| 核心方法 | 谓词类型、控制流扁平化、分层优化 |
| 使用的模型 | 无机器学习模型 |
| 使用的编译器工具 | MLIR、LLVM dialect、NEURA passes、mapper |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 使用结构操作语义描述 IR，但非完整程序形式化验证 |
| 数据集规模 | PolyBench、MachSuite、CGRA-Bench、CHStone 及 GCN/LU |
| 主要指标 | speedup、IPC、Perf/Area、面积、能耗 |
| 最重要实验结果 | 内核相对 Marionette 2.20×，应用最高 2.71×几何平均 speedup |
| 核心创新 | 带层级谓词的纯数据流 IR与多执行模型 retargeting |
| 主要局限 | 原型/模拟评估，动态场景与真机覆盖有限 |
| 与 RISC-V 研究的相关性 | 中高；适合研究 RISC-V/加速器协同 IR，但非 RISC-V 论文 |
| 最适合作为 | 多硬件编译 IR 与后端基础设施参考 |

这篇论文最值得学习的是把控制语义直接嵌入可优化的数据值，并以此统一多个 CGRA 执行模型；最主要的局限是硬件评估依赖原型和模拟器；如果用于后续研究，合理方式是扩展 RVV/加速器协同和反馈映射，而不是简单把 CGRA 替换成 RISC-V。
