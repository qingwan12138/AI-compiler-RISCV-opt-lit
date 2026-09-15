# PS-PDG 文献阅读总结

论文题目：**The Parallel-Semantics Program Dependence Graph for Parallel Optimization**

作者：Yian Su、Brian Homerding、Haocheng Gao、Federico Sossai、Yebin Chon、David I. August、Simone Campanoni

发表时间：2026 年

发表平台：CGO 2026（2026 IEEE/ACM International Symposium on Code Generation and Optimization）正式论文，pp. 348–361

论文链接或编号：DOI [10.1109/CGO68049.2026.11395217](https://doi.org/10.1109/CGO68049.2026.11395217)；[CGO 2026 官方论文页](https://2026.cgo.org/details/cgo-2026-papers/27/The-Parallel-Semantics-Program-Dependence-Graph-for-Parallel-Optimization)；[作者公开 PDF](https://yiansu.com/files/papers/PSPDG_CGO_2026.pdf)

关键词：LLVM、MLIR omp dialect、程序依赖图、并行语义、OpenMP、Cilk、并行计划优化、向量化

> 本文档只记录论文正文事实；阅读后的分析和后续方向单独标注。正文依据本地 14 页 PDF，页码按论文印刷页 348–359 计。

---

## 1. 研究背景

论文研究共享内存并行程序的编译优化。OpenMP、Cilk 等并行编程模型允许开发者在源代码中显式指定哪些循环并行、采用何种执行模型以及如何同步。现有 Clang/GCC 流程通常在前端把这些并行语义直接降低为运行时调用，随后中端只能遵守开发者原先指定的并行执行计划。

根据第 1–2 节，问题在于：开发者计划可能不是目标硬件上的最优计划；例如某些循环更适合 SIMD，某些小循环在线程化后只增加线程管理开销，而数组私有化、归约和 critical 区域又会影响可扩展性。传统 PDG 主要为顺序程序设计，不能完整表达 OpenMP/Cilk 中的 `private`、`firstprivate`、`lastprivate`、`reduction`、原子性、无序执行和动态实例数据选择等语义。

因此，论文希望保留开发者提供的并行正确性约束，同时允许编译器在语义等价的计划空间中重新选择更适合目标机器的线程化或向量化方案。

## 2. 论文要解决的问题

### 2.1 现有 lowering pipeline 丢失并行语义

现有流程把 OpenMP 并行计划较早降低为运行时调用，导致中端无法再访问“循环迭代独立”“变量可私有化并归约”“critical 区域只要求互斥但不要求固定顺序”等信息。论文第 II-C、II-D 节将其概括为并行语义在前端丢失且不可恢复。

### 2.2 PDG 无法表示并行程序的完整约束

仅靠传统 PDG，编译器不能安全地区分不同的并行计划和数据关系，也无法表达某些优化所需要的变量私有化、归约函数和动态 producer/consumer 选择。

### 2.3 编译器需要探索替代并行计划

论文要解决的是如何从 OpenMP/Cilk 源程序构建一种同时保存开发者语义和编译器分析结果的抽象，并据此生成可能不同于开发者原计划、但仍然合法且更高效的并行二进制。

> 本文主要研究：如何用 PS-PDG 表示并行语义约束，使 LLVM 编译器能够在保持正确性的前提下重新选择线程化和向量化执行计划。

## 3. 核心方法概述

论文提出 Parallel-Semantics Program Dependence Graph（PS-PDG），并实现 LLVM-based 编译器 GINO。PS-PDG 在 PDG 基础上加入层次节点、节点 traits、上下文、无向依赖、带 data-selector 的有向依赖、并行语义变量及 use/def 关系。GINO 从保留 OpenMP 语义的 MLIR `omp` dialect 构建 PS-PDG，再以 profile-guided heuristic 选择线程化/向量化计划，最后降低到 LLVM IR 并使用 Clang 后端生成二进制。

```text
OpenMP C/C++ 源代码
        ↓ Clang 生成保留语义的 MLIR omp dialect
MLIR AliasAnalysis / MemoryEffects + OpenMP 属性
        ↓
NOELLE-PSPDG 构建 PS-PDG
        ↓
GINO 按热点比例和机器配置选择并行/向量化计划
        ↓
降低到 LLVM IR，插入向量化元数据
        ↓
Clang/LLVM 后端生成并行二进制
        ↓
在 56 核或单核环境执行并测量运行时间
```

LLM、SFT、强化学习、工具调用和奖励模型均未出现在论文方法中；这是传统编译器基础设施与启发式优化系统。系统的最终编译器角色不是 LLM Selector/Translator/Generator，而是传统 compiler infrastructure。

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用静态图构建、编译期启发式计划选择和实机运行评测。

### 4.1 PS-PDG 构建

根据第 V-A 节，GINO 扩展 NOELLE 的 PDG 抽象，并让 NOELLE 接收由 Clang 生成的 MLIR `omp` dialect。构建过程先按循环分配节点，使用 NOELLE 的 Forest 按函数组织层次结构；再为 `omp.parallel`、`omp.wsloop`、`omp.critical` 等操作创建嵌套节点。

### 4.2 依赖与语义抽取

顶层节点使用 MLIR AliasAnalysis 和 MemoryEffects 做数据依赖分析。`omp.wsloop` 的 OpenMP worksharing 语义已经保证不存在循环携带依赖，因此不再计算这类依赖。critical 区域中的操作之间加入无向依赖以保证串行互斥；SSA 已隐含表示寄存器 def-use 关系。`private`、`firstprivate`、`reduction` 等属性从 omp 操作参数中抽取为并行语义变量。

### 4.3 计划选择与 lowering

GINO 使用 profile-guided heuristic：运行时间占比低于 1.2% 的循环仅向量化；高于该阈值的循环同时尝试多线程化和向量化；若编译期检测到单核，则仅向量化。选定计划后，GINO 将其降低为 LLVM IR，并调用现成 Clang 后端生成代码。没有 SFT、PPO、GRPO 或多阶段训练流程。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有训练损失函数。核心形式化对象是第 III 节表 I 的 PS-PDG：

```text
PS-PDG ::= (Node+, Edge*, Variable*, VariableAccess*)
Node ::= (Instruction | HierarchicalNode, Trait*)
Edge ::= DirectedEdge | UndirectedEdge
Variable ::= Privatizable | Reducible
```

主要语义元素如下：

| 元素 | 论文中的作用 |
| --- | --- |
| Hierarchical node | 将一个代码区域作为整体节点，承载区域级并行属性 |
| Atomic / Unordered / Singular trait | 分别表达原子执行、实例间无序和仅由单个实例执行 |
| Context | 指定某个并行语义在哪个嵌套代码区域中有效 |
| Undirected edge | 表示两个计算不能重叠，但执行先后顺序可以互换 |
| Any/Last/All data-selector | 表示允许哪个动态 producer 实例向 consumer 提供数据 |
| Privatizable / Reducible variable | 表示变量可复制为私有副本以及如何合并私有副本 |

这些不是奖励函数，而是保证并行变换合法并扩大可优化计划空间的中间表示语义。

## 6. 实验设置

### 6.1 数据集来源

实验使用 NAS Parallel Benchmark Suite 的 NPB 3.0-OMP C 版本中的 8 个 benchmark。BT 和 FT 使用输入规模 B；其余 benchmark 使用规模 C。论文没有将其称为训练集/验证集/测试集，也没有使用 LLM 数据集。实验程序是并行 C benchmark，而不是作者构建的机器学习数据集。

### 6.2 模型与工具

| 项目 | 论文设置 |
| --- | --- |
| 编译器基础设施 | LLVM 14；GINO 基于扩展后的 NOELLE |
| 并行 IR | MLIR `omp` dialect |
| 后端 | Clang/LLVM 后端 |
| 对比系统 | NOELLE-par、OpenCilk-2.0、OpenMP、GINO |
| 编译选项 | `-O3 -march=native` |
| 操作系统 | Linux kernel 4.18.0 |
| 硬件 | 两颗 Intel Xeon Gold 6258R，共 56 核，2.7 GHz |
| 运行控制 | 关闭 hyperthreading 和 turbo boost；结果取 30 次运行的 median |
| Artifact | LLVM 14.0.6、GLLVM、OpenCilk-2.0；Docker/Make workflow；约 10 GB 磁盘，默认约 30 小时 |

### 6.3 对比方法

- 开发者原始 OpenMP 并行计划：衡量 GINO 是否能找到更好的语义等价计划。
- OpenMP：在相同开发者计划下作为生产级基线。
- OpenCilk-2.0/TAPIR：另一种并行优化编译基础设施，采用 work-stealing。
- NOELLE-par：仅基于传统 PDG，在 DOALL、HELIX、DSWP 等计划中选择。
- NOELLE-par 的增强版本：额外利用 worksharing pragma 减少一部分保守依赖，但不具备完整 PS-PDG 语义。

### 6.4 评价指标

主要指标是运行时间转换得到的 speedup。论文报告 56 核运行结果，也单独报告单核 BT 结果；每个数值应理解为特定 NAS benchmark、输入规模、硬件和编译器组合下的运行性能，而不是静态 IR 指标或形式化证明通过率。

## 7. 实验结果与结论

### 7.1 主要结果

根据摘要和第 V-C 节，GINO 在 8 个 NAS benchmark、56 核环境下把相对顺序基线的平均 speedup 从 6.8× 提高到 7.8×，即平均提升 15%。CGO 官方页面也确认“最高 46.6%、平均 15%”的摘要结论。

### 7.2 GINO 相对开发者计划

- EP 提升 17.2%，IS 提升 13.2%。主要原因是识别数组归约模式，使用按线程分块且 cache-line 对齐的私有数组，由主线程做最终归约，减少 critical 区域锁竞争和跨核 cache coherence 流量。
- 在开发者已经并行化的循环上，GINO 继续向量化：FT +44.1%、BT +16.6%、CG +16.5%。
- MG 提升 24.6%；对于大量反复调用的小循环，GINO 以向量执行替代线程化，降低线程管理开销。
- 单核 BT 案例中，OpenMP 原计划没有超过顺序基线，而 GINO 选择向量化，报告 59% 性能提升。

### 7.3 与 OpenCilk 和 OpenMP 比较

GINO 总体比 OpenCilk 高 37%；即使 GINO 遵循开发者原始计划，也比 OpenCilk 高 20%。论文将差异归因于 OpenMP 的静态大块调度和数据局部性更适合规则 NAS loop nests，而 OpenCilk 的细粒度 work-stealing 会带来 stealing 开销和局部性损失。

在遵循开发者原始计划的对比中，GINO 在 CG 上比 OpenMP 高 17%，原因包括 LLVM 自动向量化；在 FT 上比 OpenMP 低 35.8%，论文指出 Clang OpenMP 前端拥有 GINO 当前没有的并行区域合并等专门优化。

### 7.4 消融/必要性分析

第 IV 节不是传统数值消融，而是逐项移除 PS-PDG 组件，构造在简化抽象下不可区分的程序对。论文说明：去掉层次节点/无向边会丢失 orderless critical 语义；去掉 traits 会丢失 singular 等区域属性；去掉 contexts 会丢失嵌套循环中的语义适用范围；去掉 data-selector edges 会丢失 any/last producer 差别；去掉 parallel semantic variables/use-def 会丢失私有化与归约信息。

### 7.5 与 PDG 比较

在 8 个 benchmark、56 核下，GINO 平均达到 7.8× speedup，并一致超过 NOELLE-par。即便给 NOELLE 的 PDG 加入 worksharing pragma 以消除部分假依赖，其性能仍明显落后，因为传统 PDG 不能表达 `private`、`firstprivate`、`lastprivate` 等并行语义。

## 8. 主要创新点

### 8.1 创新点一：把并行语义与可优化计划解耦

现有 parallel IR 往往编码一个编译器必须遵守的固定计划。PS-PDG 改为表示开发者计划隐含的精确约束，让编译器在约束允许的多个计划之间选择。第 II-D、III 节给出了这一设计的动机和定义，实验表明它能支持不同于开发者原计划的更快实现。

### 8.2 创新点二：PS-PDG 的组合式语义扩展

层次节点、traits、contexts、无向依赖、data-selectors 和并行语义变量不是单个工程开关，而是共同解决不同信息丢失问题的图抽象。第 IV 节用不可区分程序对说明各组件的必要性。

### 8.3 创新点三：面向 LLVM/MLIR 的可运行实现 GINO

论文不仅提出抽象，还将其落地到 NOELLE/LLVM，使用 MLIR `omp` dialect 保留前端并行语义，之后生成 LLVM IR 和二进制。第 V 节在真实 56 核 CPU 上展示了跨线程化、向量化、私有化和归约的组合优化。

### 8.4 非创新项的边界

LLVM、MLIR、PDG、OpenMP、LLVM 自动向量化和 NAS benchmark 本身不是本文单独提出的创新。GINO 的启发式阈值和具体 lowering 是实现设计；其价值来自在 PS-PDG 语义下把这些现有能力连接起来。

## 9. 局限性

### 9.1 论文明确承认或实验中显示的限制

- 论文没有单独的“Limitations”章节；正文明确指出 GINO 当前缺少 Clang OpenMP 前端的并行区域合并等专门优化，因此在 FT 上比 OpenMP 低 35.8%。
- GINO 当前实现面向 OpenMP 和 Cilk 所需的 traits/data-selectors，并非对所有并行语言语义的完整覆盖；论文明确说 Cilk 的逐项必要性分析未在正文中展开。
- 实验只覆盖 8 个 NAS benchmark，运行平台是单一的双路 Intel Xeon 56 核系统；没有 GPU、RISC-V、异构加速器或跨编译器版本实验。
- 计划选择采用固定的 1.2% profile 阈值和单核特判，论文没有证明该阈值对其他 workload 或硬件普遍最优。

### 9.2 阅读后发现的潜在限制

- 运行时间结果是实机经验测量，不是对所有输入规模和线程调度的形式化性能保证；PS-PDG 主要解决语义可表达性，不能自动保证启发式选择最优。
- OpenMP 语义由 MLIR `omp` dialect 和属性保留，前端、dialect lowering、NOELLE、LLVM 版本之间的兼容性可能影响可复现性。
- 论文展示了 x86 固定宽度 SIMD 路径；把固定向量宽度与启发式直接迁移到 RISC-V/RVV 需要重新设计向量长度、尾部处理、线程/向量成本模型和后端 lowering，不能仅替换 `-march`。

## 10. 阅读后的研究方向反思

PS-PDG 对 LLVM/MLIR 研究最值得借鉴的是“保留高层语义直到优化决策完成”的 compiler IR 设计。它与简单地把 OpenMP 直接 lower 成 runtime call 相比，给 parallel optimizer 留出了明确的合法计划空间。

对 RISC-V 的相关性是中等：论文不是 RISC-V 论文，但 PS-PDG 的语义层可以作为 RISC-V CPU/RVV 后端上层的并行计划表示；真正需要新增的是面向 RVV 的 vector-length-agnostic lowering、硬件反馈和成本模型。现有 GINO 更适合作为传统编译器 baseline/工具模块，而不是 LLM 方法 baseline。

不能直接照搬的部分包括 1.2% 阈值、x86 SIMD 宽度、OpenMP runtime 假设和 56 核 CPU 的 speedup 结论。论文贡献本身是 PS-PDG/GINO，不应把“换成 RISC-V”表述为新贡献。

## 11. 可进一步尝试的研究方向

### 11.1 RVV 感知的 PS-PDG 计划选择

#### 研究问题

PS-PDG 的并行语义能否与 RVV 的向量长度无关执行模型结合，在不同 `VLEN`、核心数和内存层次下选择线程化/向量化计划？

#### 与原论文的区别

不只是移植 GINO，而是加入 RVV-specific cost model、向量长度探测和尾部/掩码语义。

#### 可能的创新点

让同一个 PS-PDG 计划在不同 RVV 实现上生成可迁移代码，并比较固定 x86 SIMD 与 RVV VLA lowering 的差异。

#### 实验框架

```text
OpenMP/MLIR omp → PS-PDG → RVV cost model → plan selection
                 → LLVM RVV IR → Spike/QEMU/真实 RISC-V → runtime feedback
```

#### 可行性与风险

需要 LLVM RISC-V backend、RVV 仿真器或硬件、NAS/PolyBench 等程序。主要风险是仿真性能慢、真实硬件可得性和 RVV 后端版本差异。

### 11.2 语义证据驱动的跨硬件计划选择

#### 研究问题

能否将 PS-PDG 的合法计划空间与真实硬件计数器、内存带宽和线程开销反馈结合，减少固定阈值导致的错误选择？

#### 与原论文的区别

从静态 profile-guided heuristic 扩展为可审计的多信号成本决策，并要求每个计划保留语义证据。

#### 可能的创新点

建立“PS-PDG 约束—候选计划—硬件观测—回退计划”的闭环；研究性能收益与编译时间之间的权衡。

#### 实验框架

```text
PS-PDG 合法计划枚举 → 编译候选 → 硬件运行/计数器
                    → 成本模型更新 → 选择并缓存计划
```

#### 可行性与风险

需要 perf/硬件计数器、可重复运行协议和跨平台测试；噪声、过拟合 workload 及编译开销是主要风险。

### 11.3 面向 MLIR 多 dialect 的并行语义保持 lowering

#### 研究问题

PS-PDG 目前由 `omp` dialect 承载；当程序经过 Linalg、Vector、GPU 或自定义 accelerator dialect 多级 lowering 时，如何保持并行语义并避免过早丢失？

#### 与原论文的区别

把单一 OpenMP/LLVM pipeline 扩展为可验证的 MLIR multi-level lowering contract。

#### 可能的创新点

为每次 dialect conversion 定义语义保持检查，允许在 higher-level IR 和 target-specific IR 之间回溯合法并行计划。

#### 实验框架

```text
Linalg/omp/Vector IR → dialect-specific semantic preservation
                    → PS-PDG view → target lowering → CPU/RVV/GPU
```

#### 可行性与风险

需要 MLIR pass pipeline、dialect conversion 和测试程序；难点在于不同 dialect 的同步与内存语义并不完全同构。

## 12. 与其他已读文献的关系

本次并行子任务只完整阅读并确认了这一篇论文，未建立同批次横向阅读集，因此不对其他论文的具体方法、数字或重复关系作事实性比较。

从研究定位看，本文属于传统 LLVM/MLIR 编译器基础设施与并行优化，适合作为 PS-PDG 表示、并行计划重构和 lowering pipeline 的方法参考；它不提供 LLM 训练、LLM pass 生成或 LLM IR 翻译基线。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | LLVM/MLIR 中面向并行程序的执行计划优化 |
| 核心问题 | 现有 lowering 丢失 OpenMP/Cilk 并行语义，PDG 表达能力不足 |
| 输入 | OpenMP C/C++，经 Clang 生成 MLIR `omp` dialect |
| 输出 | 选择后的并行 LLVM IR 与二进制 |
| 核心方法 | PS-PDG + GINO；保留语义并重新选择线程化/向量化计划 |
| 使用的模型 | 无机器学习模型、无 LLM |
| 使用的编译器工具 | LLVM 14、Clang、MLIR omp、NOELLE、OpenMP/OpenCilk |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用语义必要性分析和实机性能评测 |
| 数据集规模 | NAS NPB 3.0-OMP C 的 8 个 benchmark；非训练数据集 |
| 主要指标 | 运行时间、speedup；30 次运行取 median |
| 最重要实验结果 | 56 核平均 speedup 6.8×→7.8×（+15%）；最高摘要报告 +46.6% |
| 核心创新 | 用 PS-PDG 表示并行语义约束，使编译器可选择替代合法计划 |
| 主要局限 | 单一 x86 平台、8 个 NAS benchmark、启发式阈值、当前缺少部分 OpenMP 专门优化 |
| 与 RISC-V 研究的相关性 | 中；可借鉴语义保持和计划抽象，但 RVV 成本模型与 lowering 需重新设计 |
| 最适合作为 | LLVM/MLIR 并行优化的 baseline、IR/工具模块和方法参考 |

> 这篇论文最值得学习的是把“开发者表达的并行约束”和“编译器选择的执行计划”分离，并通过 PS-PDG 在 LLVM/MLIR pipeline 中保留二者；最主要的局限是实验范围集中于 LLVM 14、x86 56 核和 NAS benchmark。用于后续 RISC-V 研究时，合理做法是把 PS-PDG 作为语义与计划层，再增加 RVV-aware lowering、成本模型和硬件反馈，而不是简单替换目标架构。
