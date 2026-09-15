# DialEgg 文献阅读总结

论文题目：**DialEgg: Dialect-Agnostic MLIR Optimizer using Equality Saturation with Egglog**

作者：Abd-El-Aziz Zayed、Christophe Dubach

发表时间：2025

发表平台：CGO ’25，Proceedings of the 23rd ACM/IEEE International Symposium on Code Generation and Optimization，pp. 271–283

论文链接或编号：DOI [10.1145/3696443.3708957](https://doi.org/10.1145/3696443.3708957)；作者公开 PDF：[zayedcgo24.pdf](https://azizzayed.com/publications/dialegg/zayedcgo24.pdf)

关键词：MLIR、Egglog、等价饱和（equality saturation）、e-graph、重写规则、编译器优化

> 本文档用于文献阅读、组会汇报和后续研究分析。论文事实与阅读后的研究思考严格分开。

## 1. 研究背景

LLVM IR 以单一抽象支持可复用的优化，但面向领域专用硬件和语言时，单一抽象会限制高层语义的表达。MLIR（Multi-Level Intermediate Representation，多层中间表示）通过 dialect（方言）让高层矩阵/卷积、中层循环和低层硬件指令共存，因此适合构建领域专用编译器。

论文指出，MLIR 优化存在两个主要困难：不同抽象层的 pass 可能以不可预测的方式相互作用；传统 pass 通常用局部贪心启发式，难以解决全局最优和 phase ordering problem（优化阶段排序问题）。

等价饱和把多个等价程序同时保存在 e-graph 中，用重写规则持续扩展等价类，最后依据 cost model（代价模型）抽取代价最低的表达式。论文的研究动机是把这种能力与 MLIR 的多方言、多层级表示结合起来。

## 2. 论文要解决的问题

### 2.1 以统一方式表示多种 MLIR 方言

现有等价饱和系统往往绑定某个专用 IR 或某个方言。论文要解决的是：如何在 Egglog 中表达 MLIR 的 operation、type、attribute、value、block 和 region，并允许未显式支持的构造保留在程序中。

### 2.2 降低跨方言优化规则的表达成本

优化规则需要能够跨越多个抽象层和方言组合使用，并支持条件匹配、属性匹配、递归重写以及依赖张量形状的代价模型。

### 2.3 在全局搜索能力与 MLIR 兼容性之间取得平衡

论文要验证 DialEgg 是否能把 MLIR 转换到 Egglog、执行等价饱和并转回有效 MLIR，同时在小型基准上达到不劣于传统 MLIR 优化流水线的运行性能。

> 本文主要研究：如何用方言无关的 MLIR–Egglog 双向桥接，把等价饱和和用户定义的重写/代价模型用于多方言 MLIR 优化。

## 3. 核心方法概述

DialEgg 是一个开源、方言无关的 MLIR 优化工具。它预定义常见 MLIR 构造的 Egglog 表示，允许用户补充自定义类型、属性和操作；用户随后用 Egglog 重写规则描述等价变换，用 cost model 指导 e-graph 抽取。

```text
输入 MLIR 程序
        ↓
准备预定义/用户定义的 Egglog 构造、重写规则和代价模型
        ↓
MLIR → Egglog：递归遍历操作、类型、属性、值、区域
        ↓
Egglog 等价饱和：应用重写规则并合并等价表达式
        ↓
按固定或类型/形状相关代价抽取表达式
        ↓
Egglog → MLIR：恢复操作、SSA 值、blocks 和 regions
        ↓
MLIR lowering → LLVM IR → -O3 二进制并运行评测
```

MLIR 的 SSA（Static Single Assignment，静态单赋值）值被建模为 Egglog let-binding；未声明的操作被当作带唯一标识符的 opaque construct，因此不会被重写但会在结果中保留。自定义类型/属性在论文版本中需要用户提供 eggifier 和 de-eggifier 两个 C++ 函数。

## 4. 实验框架与训练流程

### 4.1 系统执行流程

本文不涉及模型训练，主要采用静态重写系统和等价饱和搜索。用户先声明方言构造，再提供 Egglog rewrite rules 与 cost model；DialEgg 完成双向翻译、饱和与抽取。

### 4.2 规则与代价模型

论文展示了固定操作代价、依赖张量维度的变量代价、条件重写、属性匹配和递归重写。等价饱和同时保留多个候选，而不是像局部贪心 MLIR pass 那样立即丢弃其他等价表达式。

### 4.3 运行时评测流程

五个 MLIR 基准经 DialEgg 或 MLIR canonicalization 处理后，统一 lowering 到 LLVM dialect 和 LLVM IR，并用 LLVM `-O3` 生成二进制。每项实验报告 11 次运行的中位数，且论文说明会验证输出。

不存在 SFT、预训练、提示词推理、PPO、GRPO、工具反馈训练或多阶段训练流程。

## 5. 奖励函数、损失函数或关键公式

本文不涉及强化学习奖励函数，也没有神经网络损失函数。核心优化目标是从饱和 e-graph 中抽取代价最低的等价表达式。

### 5.1 固定代价

论文示例把 `arith.divsi` 的代价设为 2，把 `arith.shrsi` 的代价设为 1；未指定时默认代价为 1。抽取时会偏好右移而不是整数除法，但前提是重写规则已声明二者等价。

### 5.2 矩阵乘法形状代价

对于矩阵 `X(a×b)`、`Y(b×c)`，论文使用近似标量乘法次数的代价；三矩阵关联时：

```text
cost((X Y) Z) = a*b*c + b*c*d
cost(X (Y Z)) = b*c*d + a*b*d
```

该目标让 Egglog 根据张量类型的行列维度选择更低复杂度的关联方式。

### 5.3 多项式代价

论文示例把乘法代价设为 100，把幂运算代价设为 100000，加法保持默认代价，促使抽取结果减少幂运算和乘法，并趋向 Horner 形式。论文没有把这些代价解释为真实硬件周期，也没有使用学习得到的代价模型。

## 6. 实验设置

### 6.1 数据集来源

论文使用五个手写 MLIR 基准，不是从公开大规模数据集训练或采样得到的数据：

| 基准 | 输入规模/任务 | 主要方言或目的 |
|---|---|---|
| Image conversion | 3840×2160×3 RGB 图像转灰度 | `scf`、`func`、`tensor`、`arith`；测试除以 2 的幂 |
| Vector norm | 1,000,000 个 3D 向量 | `math` 等；测试 fast inverse square root |
| Polynomial | 1,000,000 个三次多项式 | 测试 Horner 重写 |
| 2MM | `A=100×10`、`B=10×150`、`C=150×8` | 测试矩阵乘法结合律 |
| 3MM | `A=200×175`、`B=175×250`、`C=250×150`、`D=250×10` | 测试更长矩阵链的全局关联 |

论文明确说明 benchmark 数据均为手写并包含在 artifact 中。训练集、验证集、测试集划分和数据泄漏分析不适用；artifact appendix 也将其描述为 handwritten datasets。

### 6.2 模型与工具

论文不使用基础模型或训练框架。实验使用 LLVM 18.1.4 中的 MLIR、Egglog、DialEgg、LLVM lowering 与 `-O3`。论文正文的运行环境是 macOS 14.5、Apple M1 Pro；每个 benchmark 运行 11 次并取中位数。artifact appendix 进一步说明实验在 10 核 M1 Pro、16 GB RAM 上完成，artifact 通过 Docker 提供。

### 6.3 对比方法

主要比较对象包括：无 MLIR 优化 baseline、MLIR 默认 canonicalization、canonicalization + DialEgg，以及在 2MM/3MM 上额外比较的手写 MLIR C++ pass。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| Speedup | 相对无优化 baseline 的运行加速比 | 越大越好 |
| Compilation time | MLIR→Egglog、Egglog 饱和、Egglog→MLIR 等阶段时间 | 越小越好 |
| Saturation time | Egglog 在 e-graph 中执行饱和的时间 | 越小越好 |
| Output verification | 运行结果是否通过论文所述输出验证 | 越高越好；论文未给出独立通过率表 |
| Number of rules/operations | 每个基准的规则数和相关 MLIR 操作数 | 描述性指标 |

## 7. 实验结果与结论

### 7.1 主要结果

图 3 报告相对无优化 baseline 的运行 speedup。Image conversion 上，DialEgg 达到约 1.14×–1.20×；canonicalization 本身没有带来 speedup。Vector norm 中，DialEgg 约为 1.08×。Polynomial 在 canonicalization + DialEgg 组合下为 1.12×。2MM 和 3MM 的提升最大，但论文明确提醒其数值受矩阵尺寸影响，不能脱离输入规模解释。

2MM 的具体案例从 270,000 次标量乘法降到 20,000 次，原因是选择了不同的矩阵关联顺序。这个数字是代价模型和给定矩阵形状下的算法运算量，不是单独的实测硬件周期。

### 7.2 与传统方法的比较

在 2MM 上，手写 MLIR pass 与 DialEgg 性能相当；在 3MM 上，手写 pass 未达到 DialEgg 水平。论文将差异归因于手写 pass 以局部、贪心方式处理三个矩阵，而等价饱和可以考虑所有关联方式并找到全局结果。

对 12 行 Egglog 矩阵结合规则，论文估计手写 MLIR 版本需要超过 120 行 C++，包括新 pass、rewrite pattern 和注册优化驱动。这是表达成本比较，不是运行时间比较。

### 7.3 与其他 LLM 方法的比较

本文没有 LLM baseline，也没有与 LLM 编译优化方法比较。论文的比较对象是 MLIR canonicalization 和手写 MLIR pass。

### 7.4 消融实验

论文没有以机器学习意义上的模块消融实验。不同配置（仅 DialEgg、仅 canonicalization、二者组合）可视为优化流水线对照；2MM/3MM 的手写 pass 对照用于观察全局等价饱和和局部贪心的差异。

### 7.5 编译时间与扩展性

表 2 显示，大部分 DialEgg 编译时间来自 Egglog 饱和。80MM 链中，MLIR→Egglog 为 0.5 ms，Egglog saturation 为 4939.3 ms，Egglog→MLIR 为 3732 ms，canonicalization 为 6.8 ms，手写 C++ pass 为 1.3 ms。论文的 3MM 链扩展实验显示，随着矩阵操作数增加，饱和时间呈指数增长，而贪心 MLIR C++ pass 近似线性增长。

## 8. 主要创新点

### 8.1 创新点一：方言无关的 MLIR–Egglog 集成

论文不是只为一个专用 IR 写 e-graph，而是把 MLIR 的操作、类型、属性、SSA 值、blocks 和 regions 映射到 Egglog，并提供双向翻译。该设计使同一套框架可组合多个 MLIR dialect。

### 8.2 创新点二：用声明式重写表达跨层优化

用户可以以 Egglog rewrite rule 表达条件重写、属性匹配、递归规则和跨方言规则，避免为每个优化手工编写完整 C++ pass。该价值由矩阵结合、Horner 规则和 fast inverse square root 案例说明。

### 8.3 创新点三：把 MLIR 类型信息接入代价模型

通过 `type-of`、张量维度提取和 `unstable-cost`，代价可以依赖输入形状，而不是固定操作计数。这使矩阵关联优化能够以给定张量形状为依据选择全局较优表达式。

### 8.4 创新点四：开源且可复现的工具/工件

论文提供开源 DialEgg 工具和 artifact，artifact appendix 给出 Docker、构建和 benchmark 命令，并记录了环境、资源需求及已知结果差异。开源本身不是算法创新，但增强了工程可复现性。

## 9. 局限性

### 9.1 论文明确承认的局限

1. 当前 DialEgg 不支持 MLIR interfaces；论文认为可用类似属性的方式扩展。
2. 正确性依赖用户编写不破坏语义的重写规则。涉及有副作用的 opaque 操作（例如 load/store）时尤其敏感；论文提出未来可利用 `MemoryEffectsOpInterface` 条件启用规则。
3. 更复杂的代价行为，例如 cache 相关的循环性能，难以仅用当前代价模型表达，可能仍需 MLIR affine 等传统流水线。
4. 等价饱和存在已知的扩展性代价：实验中饱和时间随矩阵链长度快速增长。
5. artifact appendix 说明，artifact 容器环境与论文原始 macOS/ARM 运行环境不同，且 Vector Norm 与 Polynomial 的规模为减少虚拟化噪声改成了 100,000,000，可能导致结果差异。

### 9.2 阅读后发现的潜在局限

1. 五个手写基准规模较小，不能据此推断对真实大型模型编译、复杂控制流或跨函数优化的普适收益。
2. 论文称翻译保持语义并将结果验证，但没有给出独立形式化验证器的覆盖率或等价证明统计；“由构造保证有效”仍依赖规则正确、翻译器无 bug 的假设。
3. 运行性能由 lowering 后的 LLVM `-O3` 二进制测得，不能直接等同于 RISC-V、GPU 或其他目标硬件上的收益。
4. cost model 主要使用操作数、类型形状和手写权重，没有展示真实硬件反馈或自动学习代价模型。

## 10. 阅读后的研究方向反思

值得借鉴的是“保留多种等价候选，再由可解释代价模型选择”的结构，以及把 IR 类型/形状作为优化决策输入。对 LLVM/MLIR 研究而言，DialEgg 更适合作为可组合的 GENERATOR/基础设施参考，而不是 LLM 训练方法或完整的 AI 编译器框架。

不能把它简单改成 RISC-V 就称为新研究：仅替换目标后端属于平台迁移。更有价值的延伸是把 RISC-V/RVV 指令代价、向量长度、寄存器压力、真实计数器和语义约束纳入可审计 cost model，并证明在新架构上规则不会破坏语义。论文的等价饱和也不能直接称为形式化验证；它只在用户提供正确等价规则且实现无 bug 的条件下工作。

本文未使用 LLM，因此与“LLM 输出 pass/IR/规则”的主线关系有限。它可以作为：

* MLIR/LLVM 变换候选的结构化执行器；
* 规则生成或 LLM 提议后的验证/筛选后端；
* 多方言重写和硬件感知代价实验的 baseline。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的硬件反馈等价饱和

#### 研究问题

如何把 RVV 向量长度、指令延迟、寄存器压力和真实硬件计数器纳入 MLIR→Egglog 的代价模型。

#### 与原论文的区别

不只是把 LLVM `-O3` 换成 RISC-V，而是让静态形状代价与真实 RVV 硬件反馈联合决定抽取结果。

#### 可能的创新点

设计可解释的多目标 cost model，并记录每次抽取的规则、代价和硬件证据。

#### 实验框架

```text
MLIR/RVV 方言 → DialEgg 饱和 → RVV lowering → 仿真器/真实板卡 → 反馈代价 → 抽取比较
```

#### 可行性

需要 MLIR/RVV 后端、QEMU 或真实 RISC-V 板卡、perf/硬件计数器以及小型矩阵和向量基准。

#### 主要风险

测量噪声和长时间饱和可能使反馈成本高；动态硬件行为也可能无法由单一静态代价解释。

### 11.2 LLM 规则提议与可执行等价饱和筛选

#### 研究问题

LLM 生成的 MLIR/Egglog 重写规则如何在进入优化流水线前被约束、测试和筛选。

#### 与原论文的区别

DialEgg 的规则由用户手写；新方向研究 LLM 作为规则提议器，而不是让 LLM 直接生成未经约束的最终程序。

#### 可能的创新点

用类型约束、随机测试、MLIR verifier、内存效应检查和饱和成本预算组成证据契约。

#### 实验框架

```text
MLIR 方言/规则模板 → LLM 提议 Egglog 规则 → 语法/类型检查 → 等价测试与副作用检查 → 饱和/抽取 → 性能评测
```

#### 可行性

需要 DialEgg、MLIR verifier、规则语料和一个可调用的代码模型；不必先训练专用模型。

#### 主要风险

有限测试不能替代形式化证明；规则爆炸可能加剧 e-graph 和编译时间问题。

### 11.3 饱和预算感知的多级优化调度

#### 研究问题

如何在有限编译时间下决定何时停止饱和、何时转回传统 MLIR pass。

#### 与原论文的区别

原论文展示了饱和时间的扩展性瓶颈；新方向把编译时间预算作为一等优化目标。

#### 可能的创新点

建立基于 e-graph 大小、候选收益上界和历史硬件收益的停止策略。

#### 实验框架

```text
输入 MLIR → 估计饱和收益/预算 → DialEgg 部分饱和或 MLIR pass → LLVM lowering → 运行时间与编译时间联合评测
```

#### 可行性

可直接复用论文 artifact 和五个 benchmark，再扩展矩阵链长度与真实工作负载。

#### 主要风险

收益上界难以准确估计，早停可能错过全局重写带来的算法复杂度收益。

## 12. 与其他已读文献的关系

本槽位本轮只完成一篇 CGO 2025 论文，因此没有另一篇同时通读并可用于横向比较的论文。根据正文中的 related work，DialEgg 与 SEER 都使用 e-graph 优化，但 SEER 面向 affine/scf 的高层综合，DialEgg 目标是更广泛的 MLIR 方言；与 MLIR Transform Dialect 相比，DialEgg 更强调声明式等价规则和自动处理变换交互；与 LLVM equality-based translation validation 工作相比，DialEgg 的核心是优化集成，不是独立翻译验证器。

去重依据：正式 corpus 的 `taxonomy_v2.csv`、`00_三大类分类索引_v2.md`、逐篇阅读目录和年份清单均未发现 `DialEgg`、规范化题名或 DOI `10.1145/3696443.3708957`；本轮已跳过已有的 CGO 2025 `LLM-Vectorizer`、RISC-V 多层后端和自动调优论文。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 将 MLIR 与 Egglog 等价饱和整合为方言无关优化器 |
| 核心问题 | 解决多方言优化规则表达、优化交互和局部贪心局限 |
| 输入 | MLIR 程序、方言构造、Egglog 重写规则、代价模型 |
| 输出 | 优化后的 MLIR，之后可 lowering 为 LLVM IR/二进制 |
| 核心方法 | MLIR↔Egglog 双向翻译 + e-graph 饱和 + 代价抽取 |
| 使用的模型 | 无神经模型、无 LLM |
| 使用的编译器工具 | MLIR/LLVM 18.1.4、Egglog、DialEgg、LLVM `-O3` |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；论文报告输出验证，但没有独立形式化等价证明流程 |
| 数据集规模 | 5 个手写 MLIR benchmark；无训练/验证/测试集划分 |
| 主要指标 | speedup、编译时间、饱和时间、规则/操作数 |
| 最重要实验结果 | 图像转换约 1.14×–1.20×，向量范数约 1.08×，多项式组合约 1.12×；2MM 运算量由 270,000 降至 20,000 |
| 核心创新 | 方言无关表示、双向翻译、类型感知代价模型和声明式规则 |
| 主要局限 | 规则正确性依赖用户、接口支持不完整、饱和时间快速增长、硬件代价建模有限 |
| 与 RISC-V 研究的相关性 | 中；可借鉴多层 IR 与可解释代价模型，但论文未做 RISC-V 实验 |
| 最适合作为 | MLIR 编译基础设施/规则执行 baseline、LLM 规则提议后的筛选工具 |

> 这篇论文最值得学习的是把“等价候选保留”和“可解释代价抽取”嵌入 MLIR 多方言体系；最主要的局限是规则安全性和 e-graph 扩展性依赖人工与预算控制；如果用于后续研究，最合理的使用方式是作为结构化变换执行器或 baseline，而不是简单地把目标平台替换为 RISC-V 就宣称产生了新方法。
