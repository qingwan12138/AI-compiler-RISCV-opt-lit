# Translation Validation for LLVM’s AArch64 Backend 文献阅读总结

论文题目：**Translation Validation for LLVM’s AArch64 Backend**

作者：Ryan Berger、Mitch Briles、Nader Boushehrinejad Moradi、Nicholas Coughlin、Kait Lam、Nuno P. Lopes、Stefan Mada、Tanmay Tirpankar、John Regehr

发表时间：2025 年 10 月

发表平台：Proceedings of the ACM on Programming Languages，Volume 9，Issue OOPSLA2，Article 369

论文链接或编号：DOI [10.1145/3763147](https://doi.org/10.1145/3763147)；稳定正文来源：[作者公开 PDF](https://users.cs.utah.edu/~regehr/papers/arm-tv.pdf)

关键词：翻译验证（translation validation）、LLVM 后端、AArch64、Alive2、指令提升（lifting）、ABI、形式语义

> 本文档只把 PDF 正文明确支持的内容作为论文事实；第 10—11 节的判断属于阅读后的分析。

## 1. 研究背景

LLVM 后端不仅做寄存器分配和指令选择，还包含数据流分析、公共子表达式消除、循环不变代码外提以及机器 IR 上的优化。论文指出，LLVM 的 CodeGen 与 Target 子目录合计约有一百万行 C++，因此后端同样有复杂的正确性风险（第 1 节）。

传统做法是固定一个已知缺陷和规避方式明确的编译器版本；但安全关键系统又希望跟踪 LLVM 的最新版本。论文研究的直接背景是：如何在不修改 LLVM 的条件下，对某次具体的 LLVM IR 到 AArch64 机器码翻译检查其正确性。

论文采用“翻译验证”而不是只比较两个编译器输出。翻译验证检查一次实际转换是否满足 refinement（精化）：新程序的行为应是旧程序行为的子集。该性质可组合，因此若每个转换步骤都保持精化，整体编译也保持精化（第 1.2 节）。

## 2. 论文要解决的问题

### 2.1 后端翻译的形式正确性

需要验证 LLVM AArch64 后端生成的汇编代码是否精化原 LLVM IR，而不仅是检查语法、崩溃或某一条测试路径。论文用一个 `insertelement` 向量写回案例说明：LLVM IR 中越界索引会产生 poison，而后端生成的 `strb` 可能向无关内存写入；arm-tv 能够报告该 refinement 失败（第 1.3 节，问题后来以 LLVM issue #74248 修复）。

### 2.2 让验证能处理汇编风格的语义

AArch64 汇编会自由混合整数和指针，寄存器、栈、ABI 约束和内存行为也必须进入模型。论文需要扩展 Alive2 的内存与指针处理，并选择手写或由 ARM 机器可读架构描述派生指令语义（第 1.1、2.8—2.9 节）。

### 2.3 评估工具的可用性、性能和发现缺陷的能力

论文明确提出四个研究问题：RQ1，能否不修改 LLVM 构造实用的 AArch64 翻译验证工具；RQ2，能否优化 Alive2 以处理整数/指针混合的汇编式代码；RQ3，手写 AArch64 指令语义与从机器可读架构描述派生语义有何权衡；RQ4，能否发现 LLVM AArch64 后端的潜在错误（第 1.4 节）。

## 3. 核心方法概述

论文提出并实现 `arm-tv`。它不是语言模型或训练系统，而是一个基于形式语义、程序提升和 Alive2 refinement 检查的编译器基础设施工具。

```text
LLVM IR 函数
    ↓ LLVM AArch64 后端
AArch64 汇编
    ↓ 手写 lifter 或 ASLp 机械派生 lifter
带执行环境的 LLVM IR
    ↓ LLVM 中端优化
紧凑的 lifted LLVM IR
    ↓ 扩展后的 Alive2
refinement 成功 / 反例 / 不支持 / 超时
```

arm-tv 支持用户态整数、浮点、Neon 向量、内存操作和函数调用（第 1.1 节）。它把 AArch64 汇编提升到 LLVM IR，从而复用 LLVM 中端优化器和 Alive2 的 LLVM 语义与 SMT 验证能力；同时加入物理指针支持，以表示汇编中类似 64 位地址索引的指针行为。

工具还检查 ABI 级属性，例如被调用者保存寄存器是否被破坏，而不只检查返回值和内存效果。验证失败时会给出导致错误显现的内存状态和函数参数反例（第 3.2 节）。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT、强化学习、PPO、GRPO 或奖励模型，主要采用静态工具执行与 SMT 形式验证流程。

### 4.1 翻译验证执行流程

1. 调用 LLVM AArch64 后端，将待验证函数降低为汇编。
2. 用手写 lifter 或基于 ARM 机器可读架构描述的 ASLp lifter，将汇编提升为 LLVM IR，并保持精化。
3. 使用 LLVM 中端优化提升后的 IR，通常显著压缩表示。
4. 使用修改后的 Alive2 验证优化后 lifted IR 是否精化原始 LLVM IR（第 2 节，图 1）。

### 4.2 执行环境建模

lifted IR 为 29 个 64 位通用寄存器、栈指针、帧指针、链接寄存器、零寄存器、4 个 1 位条件码、32 个 128 位浮点/向量寄存器和 4 KB 栈分配 LLVM 层内存（第 2.1 节）。未使用的机器状态用 `freeze poison` 初始化，使 SMT 求解器可以对其进行对抗性选择，而不是因固定为零而漏掉依赖未初始化状态的错误。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数或训练损失函数。

### 5.1 关键正确性关系

论文把编译正确性的顶层目标表述为 refinement：

```text
行为(输出程序) ⊆ 行为(输入程序)
```

若每个编译步骤都保持该关系，则由精化的可组合性，整体编译也保持该关系（第 1.2 节）。论文的验证目标不是追求运行时间奖励，而是判定 lifted、优化后的 LLVM IR 是否精化原 LLVM IR；失败时返回反例。

### 5.2 SMT 与内存优化

实验运行时间主要由 Z3 可满足性检查决定（第 3.1 节）。作者在 Alive2 内存子系统中加入针对汇编物理指针和整数/指针混合行为的优化；这不是训练目标，而是降低验证条件生成和求解开销的工程机制（第 2.9、3.3 节）。

## 6. 实验设置

### 6.1 数据集来源

实验使用两组 LLVM IR 函数：

| 来源 | 规模与处理 |
| --- | --- |
| LLVM unit test suite | 过滤掉 upstream Alive2 不支持、或无法降低到 AArch64 的函数后，剩余 232,981 个函数 |
| SPEC CPU 2017 | 在基于 ARM 的 MacBook Pro 上用推荐 baseline 优化选项将 C/C++ 编译成 LLVM IR，得到 87,738 个可转成 ARM 指令的函数；未过滤 upstream Alive2 不支持的函数 |

LLVM 测试集代表 LLVM 社区已经纳入测试的、认为需要正确编译的函数；SPEC CPU 2017 被选作独立于本文工作的代表性软件集合（第 3.1 节）。缺少训练/验证/测试集划分，因为本文不是机器学习训练任务。

### 6.2 模型与工具

核心工具是 arm-tv、Alive2、LLVM 中端优化器、Z3、手写 AArch64 lifter 和 ASLp 派生 lifter。实验机器为 AMD EPYC 7502（Zen 2，64 个硬件线程，256 GB RAM），运行 Ubuntu Linux 24.04；每次 arm-tv 调用限制为 10 分钟 CPU 时间和 4 GB 虚拟内存（第 3.1 节）。论文还使用 YARPgen、alive-mutate、IRFuzzer 进行随机测试和变异测试（第 3.5 节）。

### 6.3 对比方法

主要对比包括：Alive2 内存优化前后；手写 lifter 与 ASLp 派生 lifter；LLVM unit tests 与 SPEC CPU 2017 两组函数。论文还把 translation validation 与常见的 differential testing 作方法定位上的比较，但没有把它们作为同一实验中的性能 baseline（第 1.1、3.3—3.4 节）。

### 6.4 评价指标

| 指标 | 含义 |
| --- | --- |
| successful verification | 在限制时间内完成且证明 refinement 的调用 |
| timeout | 达到 600 秒 CPU 时间上限仍未完成的调用 |
| unsupported | 因 arm-tv、Alive2 或输入特征不支持而不能处理的函数 |
| verification time | 单次验证完成时间；图 4 用 CDF 展示 |
| miscompilation bugs | arm-tv 报告并提交给 LLVM 开发者的错误数量；表 1 仅统计错误编译，不含崩溃 |

## 7. 实验结果与结论

### 7.1 工具实用性

arm-tv 可以直接接收 LLVM module 和函数名，自动降低、提升、优化并验证；出现 refinement 失败时生成具体反例（第 3.2 节）。图 3 按 AArch64 指令数分箱展示 LLVM unit tests 与 SPEC CPU 2017 的成功、unsupported 和 timeout 结果。SPEC 函数通常更大，也更常使用多级指针和函数指针，因此比相近大小的 LLVM unit test 更难验证。

### 7.2 Alive2 内存优化

在 LLVM unit test suite 上，加入面向汇编式物理指针的 Alive2 内存优化后，timeout 比例从 7.0% 降至 3.1%；在 SPEC CPU 2017 上则从 43% 降至 40%（第 3.3 节，图 4）。这说明优化对较简单测试函数更有效，而对更大、更依赖指针的 SPEC 函数收益有限。

### 7.3 指令语义来源的比较

手写 lifter 中负责单条 AArch64 指令的代码约 8.1 KLOC，arm-tv 总规模约 14.4 KLOC，支持约 1,400 条按 LLVM 分解统计的指令；ASLp 派生 lifter 约需 2 KLOC C++（第 3.4 节）。手写 lifter 在 LLVM unit tests 上缺少 641 条指令，ASLp lifter 只缺少 11 条，后者主要涉及线程同步、指针认证和处理器特性报告等 arm-tv 有意排除的功能。

经过优化后，两种 lifter 在 LLVM unit tests 上的 timeout 几乎不受选择影响；在 SPEC CPU 2017 上，ASLp lifter 额外造成约 2% 的 arm-tv 调用超时（第 3.4 节，图 5）。作者据此认为机械派生语义在充分优化后，其验证性能接近手写语义，同时覆盖性更高。

### 7.4 发现的 LLVM 错误

论文报告 arm-tv 在 2022 年 4 月至 2025 年 7 月的非控制性测试活动中发现并报告 45 个此前未知的 LLVM 误编译错误，其中 39 个已修复；表 1 还列出每个 GitHub issue、受影响操作、语义类别和修复状态（第 3.5 节，表 1）。测试主要结合 YARPgen、alive-mutate 和 IRFuzzer；SPEC CPU 2017 本身没有发现误编译。

论文展示的例子包括 `or`/`and` 常量组合导致的 AArch64 错误指令选择（issue #55284），以及 LLVM `i1` 参数的 `signext` 与 AArch64 ABI 零扩展规则交互导致的错误（issue #57181，第 3.5 节）。这些例子说明 ABI 约束、整数位宽、未定义行为、向量和内存语义都可能暴露后端错误。

### 7.5 局限性相关结果

LLVM unit tests 中常见的 unsupported 原因包括：向量参数 ABI 不稳定（55%）、非单精度/双精度浮点（14%）、不支持的参数类型（4%）、可变参数（4%）和结构体返回值（3%）。SPEC 中常见原因包括 Alive2 不支持的指令（通常是异常处理，47%）、可变参数（16%）、不支持的 personality function（9%）和别名元数据（7%）（第 3.2 节）。

## 8. 主要创新点

### 8.1 面向 LLVM AArch64 后端的完整翻译验证工具

论文把后端输出提升回 LLVM IR，并复用 Alive2 检查输入 IR 与输出 IR 的精化关系，形成不需要修改 LLVM 的端到端验证流程。其价值在于能够检查一次具体编译运行的语义，而非只依赖测试执行路径。

### 8.2 面向汇编代码的 Alive2 物理指针与内存优化

论文扩展 Alive2，使其能够处理汇编中常见的物理指针以及指针/整数自由混合，并针对这类代码优化内存系统。第 3.3 节的 timeout 变化支持了这些优化的实用价值。

### 8.3 ASL 机械派生语义与手写语义的实证比较

作者把 ARM 机器可读架构描述经 ASLp 专门化为用户态语义，并与手写约 1,400 条指令语义做 apples-to-apples 比较。论文报告：经过优化，机械派生语义的验证性能接近手写语义，同时支持的指令缺口明显更小。

### 8.4 将翻译验证用作强错误预言器

论文不只展示“没有发现错误”，而是把 arm-tv 与随机生成/变异测试结合，报告 45 个 LLVM 误编译错误，其中 39 个已修复。这把形式验证从发布前证明工具扩展为生产编译器缺陷挖掘基础设施。

## 9. 局限性

### 9.1 论文明确承认的局限

- arm-tv 主要面向顺序用户态代码，不支持处理器模式切换、特权指令、内联汇编、线程局部存储、C 风格可变参数、除 IEEE 754 单/双精度之外的浮点、非默认舍入模式，以及函数参数/返回值中的结构体（第 2.10 节）。
- 它继承 Alive2 对无界循环、异常处理和基于类型的别名信息的限制。
- 中大型函数仍容易超时；论文结论明确说，支持重度内联的大函数、并发以及 volatile、内联汇编和中断处理等系统级特征，才能实现最初面向安全关键嵌入式系统的 push-button 目标（第 4、6 节）。
- 当前实现没有在证明助手中形式化验证 arm-tv 自身；作者指出，如果要形式化证明 arm-tv，当前实现策略并不合适（第 4 节）。
- 45 个错误来自 2022—2025 年的机会式、非控制性测试活动，不是一个受控的缺陷发现实验（第 3.5 节）。

### 9.2 阅读后的潜在局限

- 由于验证链路包含 lifter、LLVM 中端和 Alive2，报告的失败不一定只来自 AArch64 后端；论文也记录过中端错误导致的 refinement 失败。因此使用者需要进一步定位失败来源。
- AArch64 的成功不能直接外推为所有 LLVM 后端或所有 ISA 的成功。论文只说明正在增加 RV64I 及 B/M 扩展支持，尚未支持 RISC-V 浮点/向量；Alive2 也不支持 RISC-V 可伸缩向量。
- 只验证单线程用户态函数，不能把结果表述为完整系统级或并发程序的形式化正确性证明。

## 10. 阅读后的研究方向反思

本文不是 LLM 编译优化论文，因此对“LLM 作为选择器/翻译器/生成器”的直接启发有限。它更适合作为 SUPPORTING/B2 编译器基础设施和形式验证底座。

值得借鉴的是“性能动作先过语义门控”的接口：如果后续 LLM 生成 LLVM IR 或 pass 配置，arm-tv/Alive2 式 refinement 检查可以作为后端翻译正确性或候选筛选的安全边界。但这只是组合建议，不是本文已经实现的 LLM 流程。

对 RISC-V 研究的相关性为中高：论文正文明确报告了 RV64I、B、M 扩展的进行中支持，以及对 RVV scalable vectors 的缺口。因此，把其验证架构迁移到 RISC-V 具有工程基础；但仅将 AArch64 换成 RISC-V 不足以构成新研究，真正的问题应放在 RVV 可伸缩向量、ABI/内存模型、跨 ISA 语义差异或多后端验证规模化上。

## 11. 可进一步尝试的研究方向

以下是基于论文局限提出的研究问题，不是本文已实现的功能。

### 11.1 RVV 可伸缩向量翻译验证

#### 研究问题

如何扩展 Alive2 与 lifter，使 LLVM IR 到 RVV scalable vector 的后端翻译可验证？

#### 与原论文的区别

原论文处理 AArch64 Neon 等固定宽度向量；该方向必须处理向量长度参数化、vtype/vl 状态和 scalable vector 语义。

#### 可能的创新点

建立面向 RVV 的参数化机器状态与 refinement 编码，并研究其对 SMT 求解的影响。

#### 实验框架

```text
LLVM IR → LLVM RV64/RVV 后端 → RVV 汇编 → RVV lifter → 参数化 Alive2 → 反例/证明
```

#### 可行性与主要风险

可复用 arm-tv 的提升和 ABI 建模思路；主要风险是 scalable vector 与 SMT 内存/位宽编码造成状态爆炸。

### 11.2 面向多后端的统一翻译验证

#### 研究问题

同一 LLVM IR 如何在 AArch64、标量 RV64 和 x86-64 后端上共享验证组件，并比较后端特定失败模式？

#### 与原论文的区别

原论文主要实现 AArch64，并只报告 RV64 支持进展；该方向研究跨 ISA 的统一接口和差异化语义。

#### 可能的创新点

以统一中间语义表示 ABI、寄存器状态和内存行为，减少每个后端重复实现。

#### 实验框架

```text
同一 LLVM IR → 多个后端 → 各 ISA lifter → 统一 refinement 检查 → 缺陷分类与迁移分析
```

#### 可行性与主要风险

标量 RV64 与 AArch64 的整数路径有可复用空间；主要风险是不同 ABI、浮点/向量模型和未定义行为规则不能被过度统一。

### 11.3 验证反馈驱动的编译优化候选生成

#### 研究问题

如何把 refinement 反例反馈给优化候选生成器，使其减少错误变换，同时保持后端性能收益？

#### 与原论文的区别

本文只把 arm-tv 用作验证器和 bug oracle，不训练生成模型，也没有性能奖励。

#### 可能的创新点

构造“正确性反例 + 架构性能”双反馈机制，并研究验证成本与候选收益的平衡。

#### 实验框架

```text
LLVM IR → 候选变换生成 → Alive2/arm-tv 门控 → 后端性能评估 → 保留正确且有益候选
```

#### 可行性与主要风险

可以用本文的验证接口作安全底座；主要风险是验证超时、性能噪声和把有限反例误当作完整证明。

## 12. 与其他已读文献的关系

本 staging 单篇任务只完整处理本文，因此不存在同批论文之间可据正文确认的横向实验比较。

就研究角色而言，本文属于 SUPPORTING/B2_Compiler_Infrastructure：它提供编译器后端的形式验证与错误检测基础设施，不是 LLM Selector、Translator 或 Generator。它与仓库中已知的 Alive2 工作在翻译验证主题上相邻，但本文新增的重点是 AArch64 后端、汇编提升、ABI 检查、ASL 机械派生语义和后端缺陷挖掘；本节不重新声称其他文献的实验结果。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 验证 LLVM AArch64 后端从 LLVM IR 到机器码的翻译精化关系 |
| 核心问题 | 如何在不修改 LLVM 的条件下处理汇编语义、ABI、物理指针并规模化验证 |
| 输入 | LLVM IR 函数 |
| 输出 | AArch64 汇编的 refinement 结论、反例、unsupported 或 timeout |
| 核心方法 | arm-tv：降低、提升、LLVM 中端优化、Alive2 验证 |
| 使用的模型 | 无机器学习模型；使用 LLVM、Alive2、Z3、ASLp |
| 使用的编译器工具 | LLVM AArch64 后端、LLVM 中端、arm-tv、YARPgen、alive-mutate、IRFuzzer |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 是，基于 Alive2/SMT 的 refinement 检查 |
| 数据集规模 | LLVM unit tests 232,981 个函数；SPEC CPU 2017 87,738 个函数 |
| 主要指标 | 成功验证、unsupported、timeout、验证时间、误编译错误数 |
| 最重要实验结果 | Alive2 内存优化使 LLVM unit tests timeout 从 7.0% 降到 3.1%；发现 45 个 LLVM 误编译错误，39 个已修复 |
| 核心创新 | AArch64 后端翻译验证、汇编物理指针优化、ASL 派生语义比较、形式验证驱动的 bug 挖掘 |
| 主要局限 | 大函数、并发、系统级特征和 RVV scalable vectors 尚未完整支持 |
| 与 RISC-V 研究的相关性 | 中高；正文报告了 RV64I/B/M 的进行中支持，但不支持 RVV scalable vectors |
| 最适合作为 | 编译器后端正确性 baseline、形式验证工具模块、跨 ISA 验证基础设施参考 |

> 这篇论文最值得学习的是把后端翻译验证、ABI 检查和缺陷挖掘放进同一条可执行流水线；最主要的局限是规模化、并发、系统级特征和可伸缩向量仍未解决。如果用于后续研究，合理方式是把它作为正确性门控和后端基础设施，而不是把 AArch64 验证流程简单改名为 RISC-V 或 LLM 优化器。
