# First-Class Verification Dialects for MLIR 文献阅读总结

论文题目：**First-Class Verification Dialects for MLIR**

作者：Mathieu Fehr、Yuyou Fan、Hugo Pompougnac、John Regehr、Tobias Grosser

发表时间：2025 年

发表平台：Proceedings of the ACM on Programming Languages，Vol. 9，PLDI，Article 206，25 页

论文链接或编号：[DOI 10.1145/3729309](https://doi.org/10.1145/3729309)；[PLDI 2025 官方论文页](https://pldi25.sigplan.org/details/pldi-2025-papers/60/First-Class-Verification-Dialects-for-MLIR)；作者公开 PDF：[pldi25.pdf](https://users.cs.utah.edu/~regehr/papers/pldi25.pdf)

关键词：MLIR、CIRCT、形式语义、SMT、翻译验证、peephole 重写、数据流分析、RISC-V 硬件编译

> 本笔记基于作者公开 PDF 正文通读整理。论文事实与阅读后的分析分开描述；本文不把 MLIR 验证基础设施误写成 LLM 编译器方法。

---

## 1. 研究背景

中间表示（Intermediate Representation，IR）是编译器内部用于分析和变换程序的专用语言。MLIR（Multi-Level Intermediate Representation）通过 dialect 机制支持可组合、可扩展的 IR，适合机器学习、硬件设计和其他快速变化的领域。它提供解析、打印、pass 管理和重写等通用基础设施，但论文指出，MLIR 的现有设计主要关注语法：dialect 中没有直接表达操作语义的通用机制。

因此，依赖语义的优化器、分析器、验证器和变换器通常需要针对每个 dialect 手工实现。不同工具之间也很难复用语义。LLVM 的外部形式化工作曾暴露 `undef`、`poison` 等语义歧义和缺陷，说明如果 IR 语义晚于工具才补充，代价会很高。

论文的动机是把形式语义尽早、以 MLIR 原生方式纳入 IR 生态：编译器开发者用熟悉的 MLIR lowering 描述语义，SMT 专家负责高效编码，工具开发者构建与具体 dialect 无关的验证工具。

## 2. 论文要解决的问题

### 2.1 如何在开放的 MLIR 生态中表达 dialect 语义

MLIR 允许未来出现大量新的、领域特定的 dialect，不能为每个 dialect 重新设计一套独立验证器。论文要解决的是如何提供分层、可组合、可复用的语义表示，并处理内存、未定义行为和 poison 等难点。

### 2.2 如何复用语义构建多种验证工具

论文希望同一套语义既能支撑翻译验证，也能支撑 peephole 重写验证和数据流传递函数验证，避免每个工具重复实现方言语义。

### 2.3 如何让 SMT 查询可处理且足够高效

直接把高层内存语义编码成 SMT-LIB 会使编译器开发者负担过重，也可能造成求解性能问题。论文研究如何在高层语义 dialect、低层 SMT dialect 和查询优化之间分离职责。

> 本文主要研究：如何在 MLIR 框架内部以语义 dialect 表达 IR 语义，并从同一语义基础派生可复用的翻译验证、重写验证和数据流分析验证工具。

## 3. 核心方法概述

论文提出一组“语义 dialect”（semantic dialects），把 MLIR dialect 的语义逐级 lowering 到 SMT-LIB。低层 dialect 对接 SMT-LIB 的布尔、位向量、数组、代数数据类型等机制；高层 dialect 显式表示 poison、内存和未定义行为。编译器开发者只需为目标 dialect 提供到这些语义 dialect 的转换。

整体数据流：

```text
MLIR 程序 dialect（arith / func / builtin / memref / comb）
        ↓
目标 dialect 的语义 lowering
        ↓
高层语义 dialect（poison / effect / ub_effect / mem_effect / memory）
        ↓
SMT-LIB 相关 dialect（布尔、位向量、数组、ADT）
        ↓
域相关语义优化与 SMT 查询生成
        ↓
Z3 等求解器
        ↓
翻译验证 / peephole 重写验证 / 数据流传递函数验证
```

论文实现了三类与具体 dialect 解耦的工具：

1. 翻译验证：检查目标程序是否细化源程序。
2. peephole 重写验证：以 PDL（Pattern Descriptor Language）表达可参数化重写，并对所有可行位宽逐一验证。
3. 数据流分析验证：用 transfer dialect 描述抽象传递函数，把同一描述 lowering 到 C++ 和 SMT，分别用于编译器执行和形式验证。

论文不使用 LLM，也不涉及 SFT、强化学习、奖励函数或模型推理。其“智能”部分来自 SMT 求解、编译器变换和静态分析，而不是机器学习模型。

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用语义建模、编译 lowering、SMT 验证和编译器测试。

### 4.1 语义构建流程

论文为 `arith`、`func`、`builtin`、`memref` 和 `comb` 等关键 MLIR dialect 定义语义 lowering。评测中具体覆盖 `arith` 的 26 个整数操作和 `comb` 的 20 个操作，不覆盖浮点操作；主要对象是无控制流操作。

### 4.2 翻译验证流程

```text
源程序 + 目标程序
        ↓
分别 lowering 到语义 dialect
        ↓
合并状态细化关系和结果细化关系
        ↓
生成 SMT 查询
        ↓
Z3 判断目标是否细化源
```

状态细化检查最终内存和未定义行为标志；结果细化关系可按函数结果类型提供，整数和 poison 类型有默认关系。

### 4.3 重写与数据流验证流程

PDL 重写先匹配 SSA 值、属性和操作，再将 `pdl.replace` 转换为语义细化检查。对于未知位宽，工具枚举不超过配置上限的可行位宽；论文还实现了使用两个 SMT 整数表示值和位宽的位宽无关版本。

对于数据流分析，transfer dialect 同时提供两条路径：一条 lowering 到 C++ 并接入 MLIR dataflow framework，另一条 lowering 到 SMT 并证明 soundness、precision 或 maximal precision。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有神经网络损失函数。关键形式化目标如下。

### 5.1 翻译验证

目标是证明目标程序结果和状态满足源程序到目标程序的 refinement relation。具体细化关系依赖结果类型；状态关系统一检查内存和 UB 状态。

### 5.2 known bits 分析的 soundness

known bits 抽象值由 `(zeroes, ones)` 两个位向量组成。表示合法性为：

```text
wellFormed(a) = (a.zeroes & a.ones) = 0
```

具体值 `x` 被抽象值 `a` 包含的条件为：

```text
includes(a, x) = ((~x | a.zeroes) = ~x) AND ((x | a.ones) = x)
```

二元操作传递函数的 soundness 要求：任意满足抽象表示约束、且被输入抽象值包含的具体输入，经具体操作得到的结果，必须被抽象操作结果包含。

### 5.3 demanded bits 分析

论文定义：

```text
isSame(a, x1, x2) = (a & x1) = (a & x2)
```

如果两个具体输入在抽象 demanded mask 下不可区分，则经过具体操作后也必须在输出 mask 下不可区分。这一条件用于证明 backward demanded-bits transfer function 的 soundness。

### 5.4 查询优化目标

论文没有优化模型，而是优化 SMT 查询。重点 pass 去除在 SMT 中代价较高的代数数据类型 tuple，同时保留对编译器开发者友好的高层表示。

## 6. 实验设置

### 6.1 数据集来源

翻译验证测试由程序生成得到：对最多两个操作的 `arith` 和 `comb` 函数进行有界穷举，常量限制为 `-1、0、1、INT_MAX、INT_MIN`，得到 443,106 个 MLIR 函数；另加入 100,000 个最多 100 个操作的随机函数。三类 pass 总计运行约 1.6 百万次验证测试。

数据流分析实验使用两个开源 RISC-V 处理器设计：Rocket 和 BOOM。Rocket 有 small、medium、large 三个版本；BOOM 有 small、medium、large、mega 四个版本。它们来自 Chisel，经 FIRTL 和 CIRCT RTL dialect 流程生成。

### 6.2 模型与工具

本文无基础模型、参数规模或训练框架。主要工具和环境为：Z3 4.12.1、CIRCT commit `6133e783`、xDSL 0.22.0；性能实验运行在 AMD Ryzen 9 5950X 16 核 CPU、64 GB DRAM 上。翻译验证测试还使用 32 核机器，单测试超时为 32 秒；SMT 查询基准的小程序和大程序超时分别为 8 秒和 32 秒。

### 6.3 对比方法

主要比较对象包括：

* MLIR 原有的 `canonicalize`、`arith-expand`、`arith-unsigned-when-equivalent` pass；
* CIRCT 原有的 known-bits 分析；
* SMT 查询经过和未经过 tuple/data-type elimination pass 的版本；
* 固定位宽逐一验证与位宽无关 SMT 语义版本。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
| --- | --- | --- |
| Miscompilation bugs | 验证发现的错误变换数量 | 越多表示发现能力越强 |
| Timeout rate | 验证测试超过时限的比例 | 越低越好 |
| Known bits | 静态确定为恒定 0/1 的位数 | 越多越精确 |
| Soundness / precision | 传递函数是否安全、是否接近最精确 | soundness 必须满足，precision 越高越好 |
| SMT total runtime | 批量查询总耗时 | 越低越好 |
| Speedup | 相对未优化查询的加速 | 越高越好 |

## 7. 实验结果与结论

### 7.1 主要结果：发现 MLIR 误编译

翻译验证结合系统生成和随机测试，检查了三个 C++ pass：`canonicalize`、`arith-expand` 和 `arith-unsigned-when-equivalent`。测试总量约 1.6 百万，整体运行约 8.5 小时。验证器发现 `canonicalize` 中 5 个会引入 poison 的误编译 bug，论文报告这些 bug 已在上游 MLIR 修复。

### 7.2 测试规模与超时

在有界穷举的最多两操作程序上，`canonicalize`、`arith-expand`、`arith-unsigned-when-equivalent` 的超时率分别为 0.04%、0.29%、0.00%；在最多 100 操作的 100,000 个随机程序上，分别为 0.49%、1.29%、0.01%。这些数字是验证工具的超时统计，不是编译器运行时间提升。

### 7.3 Peephole 重写验证

论文用 PDL 重写了 `arith` canonicalize pass 中 31 个 peephole 规则和 `comb` canonicalize pass 中 35 个规则，并对最多 64 位的所有可行位宽进行验证。论文证明了从已修复 MLIR 版本提取的规则在所定义语义下保持语义；其中许多规则也可用位宽无关版本证明。涉及 `arith.extsi` 和 `arith.trunci` 的复杂规则可能每条耗时约 3 分钟。

### 7.4 RISC-V 数据流分析结果

论文新增并验证 known bits 与 demanded bits transfer functions。11 个 transfer function 中有 8 个被证明为 maximally precise；`mul` 和 `shl` 没有达到最大精度，作者认为完全精确的版本可能过于复杂。

与 CIRCT 默认 known-bits 分析相比，作者分析在 Rocket/BOOM 设计上检测到的 known bits 增幅为 25.5%–55.0%：Rocket small/medium/large 分别为 32.6%、30.1%、25.5%；BOOM small/medium/large/mega 分别为 33.6%、41.0%、38.5%、55.0%。BOOM Mega 中，作者方法确定 362,412 位，CIRCT 默认方法确定 233,865 位，总可能位数为 1,947,627。

作者实现了 13 个利用 known/not-demanded bits 的优化，并在生成的 RISC-V 处理器模拟中确认 Dhrystone 可以继续正确运行。论文报告的是硬件设计编译与仿真正确性，不是实际芯片上的运行时间加速。

### 7.5 SMT 查询优化结果

tuple/data-type elimination pass 在小程序基准上把未超时查询总耗时从 6050 秒降至 4853 秒，加速 24.6%；在大程序基准上从 3746 秒降至 2349 秒，加速 59.5%。超时比例也分别从 0.26% 降到 0.22%，以及从 2.29% 降到 1.50%。该 pass 当时用 Python 实现，作者测得其自身开销为 6684 秒和 1542 秒，并指出迁移到 C++ 后预计会显著降低开销。

## 8. 主要创新点

### 8.1 创新点一：把形式语义做成 MLIR 一等方言

现有 MLIR 主要提供语法和通用 IR 基础设施。论文将语义也表示为可变换的 MLIR dialect，让开发者使用已有 pass 和 rewrite 机制描述语义。价值在于语义不再是外部、孤立的附加证明系统。

### 8.2 创新点二：高层语义到 SMT-LIB 的分层职责分离

论文用 poison、effect、undefined behavior 和 memory 等高层 dialect 隔离编译器语义描述与 SMT 低层编码。这样编译器专家不必直接处理复杂内存 SMT 编码，SMT 专家也能复用和优化通用 lowering。

### 8.3 创新点三：从同一语义基础派生三种通用工具

翻译验证、PDL 重写验证和 transfer function 验证共享 dialect 语义，工具自身尽量不依赖具体 program dialect。论文的实验证据是：发现 5 个上游 MLIR bug、验证一整组 canonicalization 重写，以及证明 CIRCT 分析传递函数。

### 8.4 创新点四：将已验证的分析用于 RISC-V 编译优化

known bits/demanded bits 的 transfer function 既由 SMT 证明 soundness，又 lowering 到 C++ 接入实际 CIRCT 编译流程，形成“形式验证—分析精度—优化触发—RISC-V 仿真”的闭环。这不是简单的验证 demo，而是把证明结果用于硬件编译器中的位级优化。

## 9. 局限性

### 9.1 论文明确承认或实验中体现的局限

* 评测中的语义主要覆盖控制流无关操作；论文表示可扩展到无循环控制流，但并未在本文中完成完整覆盖。
* `arith` 浮点操作未定义语义。
* 当前内存模型不处理向内存写入指针和 sub-byte memory access。
* SMT 求解器通常不能直接处理参数化位宽，因此固定位宽验证需要枚举；位宽无关版本进入不可判定片段，实践中并非所有查询都能解决。
* data-type elimination pass 当时由 Python 编写，转换本身可能带来很大开销。
* `pdl.apply_native_constraint` 和 `pdl.apply_native_rewrite` 依赖用户提供正确的 SMT 语义实现；工具无法自动证明任意外部 native 代码与其编码一致。

### 9.2 阅读后发现的潜在局限

* 论文的 5 个 bug 和 1.6 百万测试体现了发现能力，但翻译验证仍受生成空间、语义覆盖和超时约束，不能等同于对所有 MLIR 程序的完整证明。
* RISC-V 结果主要是 CIRCT/Chisel 硬件设计的静态位分析和仿真正确性，不能直接推出所有 RISC-V 软件程序或真实芯片性能收益。
* 语义 lowering 的工程成本仍由各 dialect 开发者承担；“工具可复用”不等于新 dialect 不需要语义建模。
* 论文不涉及 LLM，因此不能直接支持 LLM 生成优化或自动修复；若与 LLM 结合，需要额外的候选约束、调用接口和失败处理。

## 10. 阅读后的研究方向反思

论文最值得借鉴的是“把语义、验证和优化放在同一个可变换 IR 中”的架构，以及把 soundness 证明结果直接接入优化器。对 AI 编译器而言，语义 dialect 可以作为生成式优化候选的验证边界：模型可以提出候选，但最终必须由语义 lowering、SMT 或 translation validation 检查。

这些内容不能简单照搬为“把 LLVM 换成 RISC-V”。论文的核心贡献是 MLIR 框架级语义复用和工具派生机制；仅更换目标 ISA 不会形成同等创新。RISC-V 的关系较强但具体：RISC-V 处理器设计是 CIRCT known/demanded bits 评测载体，而不是论文为 RISC-V 专门设计的 ISA 优化器。

更合适的定位是：

* 作为 MLIR/CIRCT 形式验证基础设施的 baseline；
* 作为 LLM 编译优化系统的 verifier/tool module；
* 作为“可证明分析结果驱动硬件编译优化”的方法参考；
* 不是 LLM 训练方法、奖励设计或端到端自动调优框架。

## 11. 可进一步尝试的研究方向

以下是阅读后的建议，不是本文已经实现的工作。

### 11.1 语义约束的 LLM 优化候选生成

#### 研究问题

LLM 能否生成 MLIR peephole 或 lowering 候选，并由语义 dialect 自动判定 poison、内存和位宽条件下的正确性？

#### 与原论文的区别

原论文的重写由 PDL 和人工语义定义；新方向研究模型生成候选及其反馈闭环。

#### 可能的创新点

将可解析的 PDL/MLIR 生成、SMT 反例摘要、候选修复和规则去重结合起来。

#### 实验框架

```text
MLIR/LLVM IR 片段 → LLM 生成 PDL/变换候选 → 语义 dialect lowering
                 → SMT/translation validation → 反例反馈 → 候选修复与排序
```

#### 可行性与主要风险

可复用本文的 semantic dialect 和 PDL 工具；风险是模型输出难以解析、SMT 成本高、native rewrite 语义可能不完整。

### 11.2 面向 RISC-V/CIRCT 的证明驱动位级优化

#### 研究问题

在不同 RISC-V 扩展或硬件后端下，如何利用已证明 sound 的 demanded-bits/known-bits 信息选择更合适的位级变换？

#### 与原论文的区别

原论文验证和实现了通用 comb transfer functions；新方向研究目标硬件配置、后端代价和可迁移性之间的联合决策。

#### 可能的创新点

把证明证书、位级精度、指令选择和硬件代价模型联合起来，而不是只追求静态 known bits 数量。

#### 实验框架

```text
CIRCT/MLIR comb IR → verified bit analyses → RISC-V target-aware rewrites
                    → RTL/Verilog lowering → 仿真与综合成本评估
```

#### 可行性与主要风险

Rocket/BOOM 和 CIRCT 已提供起点；风险是 RTL 综合结果与静态位分析收益不总是相关，且不同扩展需要额外语义。

### 11.3 自动发现 semantic dialect 的缺失语义

#### 研究问题

能否从 differential testing、SMT 反例和上游 bug 中发现 dialect 语义规格的缺口？

#### 与原论文的区别

原论文假设开发者提供语义 lowering；新方向把语义审计和缺失操作发现作为自动化目标。

#### 可能的创新点

构建“操作覆盖—语义覆盖—反例分类”的证据图，区分实现 bug、错误 rewrite 和语义未定义。

#### 实验框架

```text
上游 MLIR/CIRCT pass → 程序生成与变异 → translation validation
                      → 反例分类 → 语义缺口/实现 bug 报告
```

#### 可行性与主要风险

可从本文的 arith/comb 测试流程扩展；风险是反例可能来自工具编码错误，必须维护可信的语义 TCB。

## 12. 与其他已读文献的关系

本 staging 槽位本轮只处理这一篇论文，因此没有另一篇可据正文比较的当前批次文献。与语料库中已有的 Alive/Alive2 类工作相比，本文的差异是把语义和验证工具提升到 MLIR 框架级，并强调跨 dialect 复用；与一般 LLM 编译优化工作相比，本文不生成代码、不选择 pass，也不使用语言模型。

按研究角色划分，本文最适合作为 `SUPPORTING / Compiler Infrastructure` 类基础设施论文：它提供验证器、语义 IR 和可复用的优化/分析证明机制，而不是 SELECTOR、TRANSLATOR 或 GENERATOR 的核心模型。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 为 MLIR dialect 建立一等形式语义和通用验证工具 |
| 核心问题 | 如何复用 MLIR 语义支持翻译验证、重写验证和数据流证明 |
| 输入 | MLIR program dialect、PDL 重写、transfer function、CIRCT 设计 |
| 输出 | 语义 dialect、SMT 查询、验证结论、C++ 分析实现 |
| 核心方法 | 分层 semantic dialect + SMT lowering + dialect-agnostic tools |
| 使用的模型 | 无机器学习模型 |
| 使用的编译器工具 | MLIR、CIRCT、xDSL、PDL、Z3、SMT-LIB |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 是，SMT-based translation validation、重写和 transfer function 验证 |
| 数据集规模 | 443,106 个有界穷举函数 + 100,000 个随机函数；另有 Rocket/BOOM RISC-V 设计 |
| 主要指标 | bug 数、超时率、known bits 数、soundness/precision、SMT 总耗时 |
| 最重要实验结果 | 发现 5 个 MLIR 误编译 bug；RISC-V known bits 提升 25.5%–55.0%；SMT 查询加速 24.6%/59.5% |
| 核心创新 | 将形式语义作为 MLIR dialect，并从同一语义基础派生三类验证工具 |
| 主要局限 | 语义覆盖有限、位宽枚举成本高、native 语义依赖人工、无真实芯片性能评测 |
| 与 RISC-V 研究的相关性 | 中高：在 Rocket/BOOM 的 CIRCT 编译流程上验证并使用位级分析，但不是 RISC-V ISA 专用优化器 |
| 最适合作为 | MLIR/CIRCT 验证基础设施、LLM 编译优化的 verifier 模块、RISC-V 硬件编译 baseline |

> 这篇论文最值得学习的是把“语义定义—形式验证—编译优化”统一到 MLIR 可变换的表示中；最主要的局限是语义覆盖和 SMT 成本仍受限制。如果用于后续研究，最合理的使用方式是作为可信验证和分析基础设施，再研究模型生成、目标硬件代价或自动语义发现，而不是简单地把平台名称替换成 RISC-V 或把 SMT 验证误写成机器学习能力。
