# ClozeMaster 文献阅读总结

论文题目：**ClozeMaster: Fuzzing Rust Compiler by Harnessing LLMs for Infilling Masked Real Programs**
作者：Hongyan Gao、Yibiao Yang、Maolin Sun、Jiangchang Wu、Yuming Zhou、Baowen Xu
发表时间：2025（ICSE 2025；arXiv 开放版本提交于 2026-05-01）
发表平台：IEEE/ACM International Conference on Software Engineering (ICSE 2025)
论文链接或编号：DOI 10.1109/ICSE55347.2025.00175；arXiv:2605.00413
关键词：Rust 编译器、LLM、代码填空、编译器 fuzzing、历史 bug 输入、ICE、Hang

> 本笔记依据 staging 中 14 页 PDF 及其正文 HTML 交叉阅读。论文事实与阅读后的研究思考分开记录。

## 1. 研究背景

论文研究 Rust 编译器测试。Rust 的所有权、借用、生命周期、宏、trait、异步和不稳定 feature 使测试程序具有较复杂的语法和语义约束。传统生成式 fuzzer 依赖随机语法规则或模板，变异式 fuzzer 依赖手工 mutation template；随着 Rust 语言和编译器持续演进，这些规则的覆盖维护成本较高。

作者指出，直接让通用 LLM 从提示生成 Rust 测试程序会产生较多无效代码；而历史上真正触发编译器 bug 的代码片段包含了领域知识，可能更适合用作生成起点。初步研究收集了 2019 年 1 月至 2023 年 8 月的 rustc issue：7,474 个 issue 中，3,819 个已解决 issue 提取出 6,088 个代码片段；其中 2,016 个片段含 `#![feature(...)]`，且历史 bug 代码大量使用括号结构。

## 2. 论文要解决的问题

### 2.1 Rust 测试程序有效率不足

通用代码模型对 Rust 的训练覆盖相对不足，直接生成的程序容易无法编译，因而难以持续进入编译器内部路径。

### 2.2 历史 bug 经验如何转化为新测试

历史 bug-triggering code 具有较强的触发潜力，但若只重复使用原始片段，容易产生重复 bug。论文研究如何保留原始上下文，同时通过局部生成扩展测试空间。

### 2.3 论文主要研究

> 本文主要研究：如何利用历史上触发 Rust 编译器 bug 的真实代码片段，通过括号结构遮蔽和 LLM 填空，生成有效且具有 bug 触发潜力的新 Rust 测试程序。

## 3. 核心方法概述

ClozeMaster 由 clozeMask、Incoder 微调、LLM infilling、ICE/Hang oracle 和重复 bug 过滤组成。它不是为用户目标程序生成一个优化版本，而是持续产生可以复用的编译器测试输入和 fuzzing 工具能力，因此按 taxonomy v2 建议归类为 `GENERATOR / G4_Tool_Test_Fuzz_Generation`。

```text
Rust 编译器历史 issue 与代码片段
        ↓
提取括号结构并遮蔽代码片段
        ↓
用历史 bug 片段构造/增强训练集，微调 Incoder
        ↓
LLM 对 mask 进行一次或多次填空
        ↓
rustc / mrustc 编译执行
        ↓
ICE、Hang、覆盖率与重复 bug 过滤
        ↓
保留新测试程序并报告潜在编译器 bug
```

LLM 的最终产物是可重复运行的 Rust compiler fuzzer 所使用的测试程序；CLOZEMASTER 原型本身也作为可复用测试工具实现。该输出符合 Generator，而不是 Selector 或 Translator。

## 4. 实验框架与训练流程

### 4.1 数据收集与增强

作者从 rustc issue 中抓取代码片段，重点关注 `C-bug` 和 `T-compiler` 标签。原始代码数据集包含 25,248 个代码片段。数据增强包括：以 `p=0.2` 的概率在代码片段级别随机删除 token，以及随机交换语句位置，最终扩展到 100,000 个代码片段。

### 4.2 Incoder 微调

论文采用开源 Incoder 作为代码填空模型，以 BPE 编码代码片段，训练最后几层，使模型最大化下一个 token 的预测概率；使用 Adam 优化器，重新训练超过 48 小时。论文没有使用 PPO、GRPO 或其他强化学习。

### 4.3 clozeMask 与推理

算法通过 DFS/栈遍历 `()`、`{}`、`[]`、`<>` 等括号结构，将括号内部或特定 feature block 的代码替换为 mask。特殊 mask 可在不同随机温度下多次填充；普通 mask 按给定温度填充。若填充结果与原始代码完全相同，则丢弃。

### 4.4 编译器执行与去重

生成程序交给 rustc 或 mrustc 编译。ICE 通过错误输出、栈信息和异常终止识别；Hang 通过编译持续时间识别，论文将 Rust 的 Hang 阈值设为 180 秒。对 ICE 收集 stack trace，对 Hang 收集时间经过信息，并用这些特征匹配 bug 数据集，过滤重复故障。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数。训练目标是代码 token 的自回归预测概率；运行阶段主要是生成—编译—oracle 过滤流程。

论文中可明确概括的判定逻辑为：

```text
若生成代码 != 原始代码，则保留候选；
若触发 ICE 或超过 Hang 阈值，则进入 bug 去重；
若 stack trace / elapsed-time 特征不匹配已有记录，则标记为新 bug。
```

论文没有给出一个统一的连续 reward 用于更新模型。代码覆盖率用于评价和对比，不应表述成训练奖励。

## 6. 实验设置

### 6.1 数据集来源

- 历史 bug 数据：rustc issue，2019-01 至 2023-08；7,474 个 issue，3,819 个已解决 issue，提取 6,088 个代码片段。
- 微调数据：原始 25,248 个代码片段，经随机删除与随机交换扩展到 100,000 个。
- 额外模型选择测试：Rust 官方 tutorial 数据集 nomicon、rust-by-example、rust-cookbook；从中随机选 100 个代码片段进行填空。
- 数据泄漏控制：在 bug 发现对比中使用 rustc 1.73；训练用的历史 bug 主要早于该版本报告和解决。

### 6.2 模型与工具

- 模型：Incoder；另评估 StarCoder、CodeShell，并额外尝试 GPT-4o 直接生成。
- 编译器：rustc v1.72、v1.73、v1.74 stable；mrustc v1.29.100。
- 软件：PyTorch 2.1.0、CUDA 12.1；实现结合 Rust 与 Python，核心代码约 500 行。
- 硬件：20 核 CPU、4 张 Tesla V100-SXM2-32GB、216GB RAM、Ubuntu 18.04、Linux kernel 4.15。
- 评价 oracle：ICE 与 Hang；覆盖率采用 rustc instrumentation。

### 6.3 对比方法

RustSmith、Rustlantis 是生成式 Rust fuzzer；SPE 是基于 Skeletal Programs Enumeration 的变异式方法，作者为 Rust 重新实现 SPE，并使用相同 seed 程序以保证公平。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| Code coverage | 测试程序在 rustc 中覆盖的代码比例 | 越大越好 |
| Reported/Confirmed/Fixed bugs | 报告、开发者确认、已修复的 ICE/Hang 数量 | 新 bug 越多越好，但需人工确认 |
| Pass rate | 填充后的程序成功编译/执行比例 | 越大越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 rustc 和 mrustc 的实际 hunting campaign 中，ClozeMaster 报告 37 个 bug，27 个得到开发者确认，其中 10 个已修复。论文正文表格给出 rustc 17 个 ICE、15 个 Hang，mrustc 5 个 ICE；确认数分别为 rustc ICE 9、rustc Hang 15、mrustc ICE 3。

### 7.2 与传统 fuzzer 比较

在 rustc 1.73、每种方法 10,000 个测试程序的覆盖率对比中，RustSmith 为 32.84%，Rustlantis 为 29.55%，SPE 为 62.02%，ClozeMaster 为 64.34%。在 24 小时 bug-finding 对比中，ClozeMaster 找到 11 个 bug，为比较方法中最高。

### 7.3 不同 LLM 比较

在 100 个 Rust tutorial 片段上，StarCoder pass rate 为 2.00%、coverage 为 10.8%；CodeShell 为 3.00%、15.6%；Incoder 为 11.00%、36.1%。GPT-4o 在 24 小时生成 11,883 个测试程序，编译通过率为 32.22%，但该实验没有发现 bug；这说明一般生成能力不能直接等价为 compiler bug-finding 能力。

### 7.4 消融实验

论文构造了五类变体，分别去除历史 bug 片段、clozeMask、微调、数据增强，或改为从零生成。结果用于分析历史代码、括号遮蔽、微调和增强数据的贡献；当前可确认的正文片段未给出所有变体的完整表格数值，因此不补写具体百分比。

### 7.5 案例分析

论文展示的案例包括 feature declaration 与 async trait、const evaluation、宏递归等复杂组合，说明局部填空可保留上下文并构造深层嵌套或不常见特征交互。案例事实表明它擅长发现 ICE 和 Hang，不等于已经覆盖语义错误或错误代码生成。

## 8. 主要创新点

### 8.1 创新点一：历史 bug 代码的括号级 clozeMask

与从零生成或简单随机变异不同，ClozeMaster 先从真实 bug-triggering code 中抽取上下文，再以括号结构为边界局部遮蔽。这样既保留已有触发线索，又允许 LLM 改变局部结构。论文的 bug 数量和覆盖率实验支持其有效性。

### 8.2 创新点二：面向 Rust 的生成器训练和工具化

作者把历史 bug 片段、数据增强、Incoder 微调和 fuzzing oracle 组合成可运行的 CLOZEMASTER 原型。真正的 Generator 价值不在于一次性生成代码，而在于形成可持续产生测试输入的 compiler testing tool。

### 8.3 创新点三：ICE/Hang 与重复故障联合过滤

论文没有只按“是否编译成功”评价，而是把内部编译器错误和超时作为 oracle，并通过栈/时间特征去重，使发现结果更接近可报告 bug。

## 9. 局限性

### 论文明确承认或正文直接显示的局限

- 主要针对 Rust 编译器，泛化到其他语言和 compiler 未在本文验证。
- 主要 oracle 是 ICE 和 Hang，不覆盖完整的差分语义错误或错误优化。
- mrustc 只支持 Rust 语法子集，实验重点仍是 rustc。
- LLM 选择和微调成本较高，Incoder 重新训练超过 48 小时。

### 阅读后的潜在局限

- 括号边界是强先验，可能遗漏需要跨括号、跨函数或跨模块构造的 bug。
- 通过 stack trace 和时间信息去重只能近似 bug identity，不能替代开发者确认。
- 论文的覆盖率是编译器代码覆盖率，不是 IR 路径覆盖或真实硬件执行覆盖。
- 结果依赖历史 issue 数据的质量和时间切分，迁移到新语言 feature 时可能需要重新维护数据集。

## 10. 阅读后的研究方向反思

ClozeMaster 最适合作为 GENERATOR/G4 的 compiler testing baseline 或工具模块。它证明“历史故障上下文 + 局部结构化生成”比单纯 prompt 生成更适合 Rust 这类长尾语言，但论文核心贡献已经是 clozeMask 和 Rust fuzzing 组合，不能仅把目标换成 RISC-V 就声称创新。

对 RISC-V 的直接相关性有限：论文不是后端优化，也不测量 RISC-V 指令性能；可借鉴的是把编译器 issue、失败轨迹或异常 IR 作为生成先验，再把 RISC-V 后端的 ICE、miscompile 或 assembler failure 纳入 oracle。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 后端的结构化故障生成

#### 研究问题

历史 RISC-V backend issue 中哪些指令选择、寄存器约束和 LLVM IR 结构能形成可扩展测试模板？

#### 与原论文的区别

从 Rust 前端括号结构转向 LLVM IR/MC/汇编约束和后端故障上下文，不只是换编译器名称。

#### 可能的创新点

把 IR pattern、目标 feature、汇编约束和失败栈联合编码为 mask 单元，并分别评估前端、后端和汇编器路径。

#### 实验框架

```text
RISC-V issue/回归测试 → IR/MC 结构抽取 → 约束填空 → LLVM/RISCV 编译 → 差分/崩溃去重
```

#### 可行性

需要 LLVM、RISC-V toolchain、历史 issue/回归测试和一个可填空的代码模型。

#### 主要风险

后端故障稀疏，且单纯崩溃 oracle 可能漏掉语义错误。

### 11.2 将填空生成与差分翻译验证结合

#### 研究问题

生成测试程序后，能否同时利用多个编译器、优化级别或解释器发现 miscompilation？

#### 与原论文的区别

扩展 oracle，不把 ICE/Hang 作为唯一目标。

#### 可能的创新点

将 differential testing、输出等价和最小化反馈加入候选保留策略。

#### 实验框架

```text
历史 bug 片段 → LLM 填空 → 多编译器/多优化级别 → 输出差异 → 最小化与分类
```

#### 可行性

可复用 ClozeMaster 的生成器和现有 compiler differential testing 工具。

#### 主要风险

非确定性、未定义行为和浮点差异会造成大量伪阳性。

## 12. 与其他已读文献的关系

本文与本轮另一篇 FunFuzz 都属于 GENERATOR/G4，但重点不同：ClozeMaster 用历史 Rust bug 片段做局部填空和微调，FunFuzz 用文档提示、多岛进化和覆盖率反馈生成 C/C++ 程序。ClozeMaster 更像领域特化的历史上下文生成器；FunFuzz 更像可迁移的搜索框架。两者均不是 pass 选择、IR 优化或 backend component 生成，不应作为 Selector/Translator 论文使用。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | Rust 编译器 fuzzing 与测试程序生成 |
| 核心问题 | 通用 LLM 生成 Rust 程序有效率低，传统模板难覆盖复杂交互 |
| 输入 | 历史 Rust compiler bug 代码片段与 mask |
| 输出 | 新 Rust 测试程序、潜在 ICE/Hang 触发输入 |
| 核心方法 | clozeMask + Incoder 微调 + oracle/去重 |
| 使用的模型 | Incoder；比较 StarCoder、CodeShell，并尝试 GPT-4o |
| 使用的编译器工具 | rustc、mrustc、instrumentation |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用 ICE/Hang oracle，不是形式化证明 |
| 数据集规模 | 25,248 → 100,000 个训练片段；历史 issue 提取 6,088 个代码片段 |
| 主要指标 | 覆盖率、pass rate、报告/确认/修复 bug 数 |
| 最重要实验结果 | 报告 37 个 bug，确认 27 个，修复 10 个；覆盖率 64.34% |
| 核心创新 | 历史 bug 上下文的括号级填空生成 |
| 主要局限 | Rust/ICE/Hang 范围较窄，依赖历史数据和模型微调 |
| 与 RISC-V 研究的相关性 | 中低；可借鉴故障上下文与 oracle，非 RISC-V 后端论文 |
| 最适合作为 | G4 compiler fuzzing baseline / 工具模块 |

> 这篇论文最值得学习的是把真实历史故障上下文转化为可复用的局部生成机制；最主要的局限是 oracle 和语言范围有限；如果用于后续研究，最合理的使用方式是作为结构化测试生成 baseline，而不是简单把 Rust 替换成 RISC-V。
