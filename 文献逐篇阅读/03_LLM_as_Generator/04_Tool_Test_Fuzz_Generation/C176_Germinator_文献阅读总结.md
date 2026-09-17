# Germinator 文献阅读总结

论文题目：**Bootstrapping Fuzzers for Compilers of Low-Resource Language Dialects Using Language Models**
作者：Sairam Vaidya, Marcel Böhme, Loris D’Antoni
发表时间：2025
发表平台：arXiv，arXiv:2512.05887
论文链接或编号：[arXiv 摘要页](https://arxiv.org/abs/2512.05887)，本 staging PDF：`pdf/Germinator.pdf`
关键词：MLIR、低资源 dialect、编译器模糊测试、语法约束采样、覆盖率引导、语言模型、TableGen

## 1. 研究背景

论文关注可扩展编译器框架中的低资源语言 dialect 测试。MLIR 允许开发者在 IR 层快速定义领域 dialect、硬件目标和领域优化，但新 dialect 往往只有少量测试，导致验证器、转换和 lowering 组件存在未覆盖路径。论文将问题放在编译器模糊测试中：需要生成大量合法且具有代表性的程序，再通过覆盖率引导变异探索编译器实现。

传统语法模糊测试器能避免部分语法错误，但在低资源 dialect 中缺少高质量种子；手工 dialect-specific fuzzer 需要逐 dialect 编写规则；学习型生成器又依赖大量训练样本。论文因此使用预训练语言模型提供结构先验，并用从 TableGen 自动提取的 grammar 约束输出。

## 2. 论文要解决的问题

### 2.1 dialect-agnostic

测试器应尽量不为每个 dialect 手工添加生成器、类型规则或编码。

### 2.2 dialect-effective

测试器不仅要生成语法合法程序，还要覆盖 dialect 特有的结构、类型和边界行为，触发深层编译器缺陷。

### 2.3 核心总结

> 本文主要研究：如何从 MLIR dialect 规格自动获得约束，并结合语言模型生成少量高质量种子，再交给覆盖率引导 fuzzer 扩大探索。

## 3. 核心方法概述

Germinator 不是直接生成最终优化 pass，而是生成可复用的编译器测试/模糊测试工具组件，模型的直接产物是初始 seed 程序和部分 custom assembly grammar 规则。

```text
MLIR dialect 的 TableGen 定义与测试文件
        ↓
自动提取 CFG；custom format 由 LM 推断，失败时回退 generic format
        ↓
grammar-constrained LM sampling 生成 assembly/generic seeds
        ↓
MLIR verifier 做语义过滤；保留 strict-valid 与 soft-valid seeds
        ↓
SynthFuzz 做上下文相关变异
        ↓
mlir-opt 执行并收集 coverage/crash/verifier failure
        ↓
保留提升覆盖率的变体并报告候选缺陷
```

根据正文第 5 节，工具使用 vLLM 与 Guidance 进行 grammar-constrained sampling；根据第 5.3 节，SynthFuzz 负责学习并合成上下文相关 mutation。语言模型不是最终的 compiler transformation，而是 fuzzing seed generator。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT 或强化学习，主要采用预训练模型的提示推理和编译器反馈。

1. 从 TableGen 的 `assemblyFormat`、类型约束、属性约束和继承关系构造 CFG。
2. 对 `hasCustomAssemblyFormat = 1` 的操作，先从测试文件中的用法示例让 LM 推断 grammar；若推断失败，使用 MLIR generic format。
3. 有测试文件时自动选取 4 个覆盖不同 AST 深度/操作数的 few-shot 示例；无测试文件时使用 module skeleton、syntax scaffold 和 TableGen 提取的操作描述构造 zero-shot prompt。
4. 对生成结果进行 grammar 约束采样和语义过滤。正文第 5.2.3 节区分 strictly valid、soft-valid 和 rejected。
5. 将约 1,000 个 seeds 输入 SynthFuzz，使用 `mlir-opt` 执行覆盖率引导循环。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数。

论文第 3.1 节定义 coverage-weighted target distribution：

```text
cw(p) = Σ over e in Cov(p) of 1 / Pr[e ∈ Cov(p)]
P*(p) ∝ P_D(p) × cw(p)
```

其中 `P_D` 表示 dialect 程序分布，`Cov(p)` 是程序触发的覆盖事件集合。该定义表达了目标：保留真实程序结构先验，同时提高罕见覆盖行为的权重。正文还给出 grammar-constrained sampling 的条件分布，但它不是训练损失。

## 6. 实验设置

### 6.1 数据集来源

评测覆盖 6 个 MLIR 项目、91 个 dialect、1,338 个 operation：base MLIR、Torch-MLIR、IREE、CIRCT、Triton 和 HEIR。种子来源包括项目已有测试文件，另由 Germinator 自动生成 1,000 个 seeds。论文没有把这些项目声明为一个独立训练数据集；模型使用预训练知识和自动构造 prompt。

### 6.2 模型与工具

- 模型：Qwen-2.5-7B-Coder-Instruct。
- 推理/约束：vLLM、Guidance、llguidance 0.7.30。
- 编译器工具：MLIR、`mlir-opt`、SynthFuzz。
- 软件环境：Python 3.10.12、PyTorch 2.8.0、CUDA 12.8、Transformers 4.55.4。
- 硬件：Ubuntu 22.04，Intel Xeon Gold 6230，384 GB 内存，适用时使用 NVIDIA RTX A6000。

### 6.3 对比方法

Grammarinator、SynthFuzz；在 base MLIR 上另比较 MLIRSmith 和 MLIRod。FLEX 未纳入全量对比，因为论文认为其需要每个 dialect 进行大量 fine-tuning 和训练数据。

### 6.4 评价指标

| 指标 | 含义 |
|---|---|
| Line Coverage | 编译器实现被执行的代码行数 |
| Bug Discovery | 按 stack trace 去重并人工 triage 的独立缺陷数 |
| Syntax Valid | grammar 层面合法比例 |
| Strictly Valid | 通过 MLIR 语义 verifier 的比例 |
| Soft Valid | 未通过严格 verifier 但被判断为语义上有潜力的比例 |

## 7. 实验结果与结论

### 7.1 主要结果

根据第 6.2 节，24 小时实验中 Germinator 发现 88 个 unique bugs，SynthFuzz 发现 16 个，Grammarinator 发现 8 个；论文将其概括为相对最好 baseline 的 5.5× 累计提升。88 个中 40 个已确认、14 个已修复，剩余缺陷在论文提交时等待 triage。

### 7.2 种子质量

表 2 报告 assembly seeds 的 syntax validity 为 100%、strict validity 14.1%、soft validity 36.2%；generic seeds 的 strict validity 为 6.6%、soft validity 28.8%。生成 1,000 个 seeds 约需 6 分钟，而无约束 LM rejection sampling 约需 86–107 分钟。

### 7.3 覆盖率

相比最好 baseline，最终 line coverage 提升 10%–120%；Triton、HEIR、CIRCT 等测试基础设施较弱的项目收益更明显。IREE 中 Germinator 达到 74.6 KLOC，baseline SynthFuzz 为 65.0 KLOC。

### 7.4 消融与隔离

将 1,000 个 Germinator seeds 加入 baseline corpus 后，Grammarinator 覆盖率提高 3%–41%，SynthFuzz 提高 4%–43%；随机 CFG seeds 在部分项目中反而降低覆盖率，说明 seed 的语义/结构质量比单纯语法合法更重要。

### 7.5 缺陷类型

88 个缺陷中包括 type-system violation 26 个、dialect conversion error 20 个、optimization pass crash 16 个、verifier inconsistency 12 个、lowering failure 8 个和 memory-safety issue 6 个。论文还展示了 EmitC 中由 verifier 对 block argument 作错误假设导致的 crash。

## 8. 主要创新点

### 8.1 从 dialect 规格自动构造 grammar

利用 MLIR TableGen 作为机器可读的语法/类型来源，减少逐 dialect 手工工程；对 custom C++ format 提供 LM inference 和 generic-format fallback。

### 8.2 grammar-constrained LM seed generation

语言模型负责代表性和多样性，grammar parser 负责在 token 生成时排除明显非法延续，二者结合解决低资源 dialect 的 seed 冷启动。

### 8.3 seed generation 与 coverage-guided mutation 解耦

论文不是让 LM 直接承担全部 fuzzing，而是让 LM 生成少量高质量 seeds，随后由 SynthFuzz 低成本扩展到大量测试输入。

## 9. 局限性

### 9.1 论文明确承认的局限

- TableGen 信息不足或 custom C++ assembly format 复杂时会回退 generic syntax，seed 的 dialect-specific representativeness 下降。
- 不自动进行 test-case minimization，bug 报告仍需人工缩减。
- grammar 主要保证语法；SSA、类型一致性、dominance 和操作前置条件等深层语义仍依赖 LM、verifier 或后处理。
- 评测集中在 MLIR，迁移到其他编译器框架需要类似的声明式规格基础设施。

### 9.2 阅读后发现的潜在局限

覆盖率提升不等于语义 bug 发现率；soft-valid 样本由模型判断其潜力，可能带来判定偏差。论文也没有把 Germinator 作为 LLVM/RISC-V 优化 pass 生成器进行评测。

## 10. 阅读后的研究方向反思

Germinator 最适合作为 GENERATOR/G4 的 compiler testing component，而不是 SELECTOR 或 TRANSLATOR。对 RISC-V 的直接替换不足以形成新贡献；若迁移到 RISC-V，应增加 ISA-specific backend/MC 层的输入结构、差分 oracle 或代码生成错误分类，而不是仅把 MLIR dialect 名称替换为 RISC-V。

可借鉴的是“声明式规格 → 约束 grammar → LM seed → 传统 fuzz loop”的分层结构，以及把模型昂贵调用限制在 seed bootstrap 阶段。不能直接照搬的是 MLIR TableGen 假设、Qwen 模型设置和 coverage-only 评价。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 后端的规格驱动 seed generation

#### 研究问题

如何从 RISC-V TableGen、MC 层约束和 instruction itinerary 自动产生能覆盖后端合法化、寄存器分配和指令选择边界的 IR/MI seeds。

#### 与原论文的区别

从 MLIR dialect syntax 扩展到 LLVM backend 的低层语义和目标约束，不只测试 parser/verifier。

#### 可能的创新点

把 ISA feature、寄存器类和合法化约束共同编码进 grammar/oracle。

#### 实验框架

```text
RISC-V TableGen/LLVM backend specs → constrained seed generation → llc/opt → differential oracle
```

#### 可行性与主要风险

可复用 LLVM 现有工具链；风险是低层语义难以由 CFG 表达，且 coverage 与 miscompile 之间存在鸿沟。

### 11.2 面向编译器优化 pass 的 seed-to-bug 定向反馈

把 coverage 反馈扩展为 pass remarks、Alive2/translation validation 和 miscompile 分类反馈。区别在于反馈目标不只是代码行，而是特定优化组件的行为。

### 11.3 跨架构 compiler differential fuzzing

比较 x86、AArch64、RISC-V 或不同 LLVM target 的等价程序行为，研究如何区分目标硬件语义差异和真正的编译器错误。该方向需要严格的可执行语义 oracle。

## 12. 与其他已读文献的关系

与本批次 LLMCfuzz 相似之处是都属于 GENERATOR/G4，LLM 生成测试输入并使用编译器反馈；不同之处是 Germinator 面向 MLIR dialect 的通用 seed bootstrap，LLMCfuzz 面向航空发动机 C 交叉编译器的领域变异、变量追踪和静默误编译检测。ACT 则是非 LLM 的 backend generator，应归 SUPPORTING/B2，不能作为同类 Generator 直接合并。

与现有仓库中的 `Finding Missed Code Size Optimizations in Compilers using LLMs` 等测试生成工作可能存在任务层面的近邻关系；本篇的区别是重点在低资源 dialect 的 grammar extraction 和 coverage-guided seed bootstrapping。正式入库前应按题名、arXiv ID、DOI 和方法摘要再次查重。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 低资源 MLIR dialect 的 compiler fuzzing seed generation |
| 核心问题 | 无手工规则/大语料时同时实现 dialect-agnostic 与 dialect-effective |
| 输入 | TableGen dialect specs、测试文件、目标 MLIR 项目 |
| 输出 | grammar-constrained seeds、coverage-guided fuzzing corpus、bug reports |
| 核心方法 | CFG extraction + LM constrained sampling + SynthFuzz |
| 使用的模型 | Qwen-2.5-7B-Coder-Instruct |
| 使用的编译器工具 | MLIR、mlir-opt、SynthFuzz、TableGen |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用 verifier 和人工 triage，不等同形式化证明 |
| 数据集规模 | 6 项目、91 dialect、1,338 operations |
| 主要指标 | coverage、bug discovery、syntax/strict/soft validity |
| 最重要实验结果 | 88 bugs；相对最好 baseline 覆盖率提升 10%–120% |
| 核心创新 | 自动 grammar extraction 与约束 LM seed bootstrap |
| 主要局限 | 深层语义仍不完全由 grammar 保证，依赖 MLIR 声明式规格 |
| 与 RISC-V 研究的相关性 | 中：可借鉴后端 fuzzing 架构，但论文未直接研究 RISC-V |
| 最适合作为 | compiler testing 工具模块、G4 Generator baseline |

> 这篇论文最值得学习的是把 LLM 限制在高价值 seed bootstrap 环节，并用声明式 grammar 和传统 coverage-guided fuzzer 扩展规模；最主要的局限是对 MLIR/TableGen 生态依赖较强；如果用于后续研究，合理方式是扩展到后端语义和差分 oracle，而不是简单替换目标架构。
