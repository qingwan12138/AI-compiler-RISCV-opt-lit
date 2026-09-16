# IssueMut 文献阅读总结

论文题目：**Learning Compiler Fuzzing Mutators from Historical Bugs**

作者：Lingjun Liu、Feiran (Alex) Qin、Owolabi Legunsen、Marcelo d’Amorim

发表时间：2026

发表平台：第 23 届 International Conference on Mining Software Repositories（MSR ’26），Technical Papers，13 页

论文链接或编号：DOI `10.1145/3793302.3793374`；作者 PDF：https://www.cs.cornell.edu/~legunsen/pubs/LiuETAlIssueMutMSR26.pdf

关键词：compiler testing、bug histories、mutational fuzzing、LLM agents、C compiler

> 本笔记只依据本轮下载的完整正文 PDF；页码均指该 PDF 页码。论文事实与阅读后的研究思考分开描述。

---

## 1. 研究背景

编译器是软件开发基础设施，编译器错误可能影响大量下游程序。编译器 fuzzing（模糊测试）通过生成或修改程序来触发崩溃、内部编译器错误（ICE）及其他错误行为。论文关注 mutational fuzzing（变异式 fuzzing）：从已有的自包含 C 程序种子出发，应用变异器生成新测试程序。

正文第 1 节指出，变异搜索空间可看成“输入程序为节点、可能的变异为边”的图；高质量变异器需要生成语法有效、能触发深层编译器行为的输入。现有变异式工具的变异器主要来自人工规则、程序无关变换或 LLM 的一般化能力，没有系统利用已经修复的真实 compiler bug 报告。论文的动机是：bug report 中包含触发 bug 的程序元素和上下文，这些历史信息可能把搜索导向相似但尚未发现的错误。

论文将 IssueMut 定位为 LLM 辅助的可复用 mutator 生成/挖掘工具，而不是让 LLM 每次从零生成完整测试程序。其目标是缓解完整程序生成的有效性和搜索效率问题。

## 2. 论文要解决的问题

### 2.1 如何从历史 bug 报告得到可复用的变异器

论文研究如何从 GCC、LLVM 已修复 bug 报告中提取 bug-triggering positive input，并构造不触发该 bug 的 negative input，再归纳出把 negative input 变为 positive input 的通用 mutator（第 1、3.1 节）。

### 2.2 历史变异器能否提升现有变异式 compiler fuzzer

论文比较把 IssueMut mutators 接入 MetaMut 和 Kitten 后的版本，与各自基线在覆盖率、崩溃数量、唯一性和 bug 发现上的差异（第 4.3 节）。

### 2.3 IssueMut 与 LLM 生成 mutator 的互补性

论文比较 IssueMut 与 MetaMut mutator 的静态结构、动态行为、覆盖/崩溃随时间变化及 crash 类型和 compiler module 分布（第 4.4 节）。

### 2.4 缩小到成功变异器是否更有效

论文还研究只使用此前触发过 crash 的“successful mutators”，是否能在固定时间预算内更快、更多地发现新 crash（第 4.5 节）。

> 本文主要研究：如何利用真实 compiler bug 历史，在 LLM 辅助下挖掘可复用的 C 代码 mutator，并将其接入现有变异式 compiler fuzzing 框架。

## 3. 核心方法概述

IssueMut 有两个组成部分：半自动 mutator miner，以及将挖掘出的 mutator 接入 MetaMut/Kitten 的增强 fuzzer 框架。其最终生成物是 bash/sed-like 变换脚本或需要 Clang AST visitor 的上下文敏感 mutator，而不是一批只能使用一次的测试文件（第 1、3 节）。

```text
已修复 GCC/LLVM bug 报告
        ↓
抓取 bug-triggering positive C test
        ↓
LLM 生成不触发该 bug 的 negative C test
        ↓
人工检查 negative test 的编译性与问题一致性
        ↓
LLM agent 概括变换、生成额外输入/输出对、合成 mutator
        ↓
自动验证；错误/错误变换交给 refiner，最多迭代 5 次
        ↓
去除重复 mutator，得到 bug-history mutator 集
        ↓
作用于 GCC/LLVM regression-test seed corpus
        ↓
记录覆盖率、crash、唯一 crash，并提交可复现 bug
```

LLM 的角色分成两处：GPT-4o mini 负责从报告和 positive input 生成 negative input；Gemini 2.5 Pro 通过 LangChain agentic architecture 负责 generalize mutation、生成额外测试对和创建/修正脚本（第 3.1.2–3.1.4 节）。三类后续 agent 是 Mutator Creator、Mutator Validator 和 Mutator Refiner。论文没有把“LLM 输出的完整程序”作为最终工件，而是把 LLM 置于可复用变异规则生成链路中。

## 4. 实验框架与训练流程

本文不涉及模型预训练、SFT、PPO、GRPO 或 RL 训练；主要采用静态的 agent 推理流程和后续 fuzzing 运行。

### 4.1 历史报告筛选与 positive/negative 构造

作者抓取 2023 年 1 月至 2024 年 10 月期间已 fixed/closed 的 GCC 和 Clang issues：GCC 1,457 条、LLVM/Clang 303 条。对报告中的测试在新版本编译器上执行；仍会 crash 的原测试被丢弃，避免把已知回归当成新发现。没有输入的报告也丢弃（第 3.1.1 节）。

GPT-4o mini 根据 bug report 与 positive input 产生相似但不触发 bug 的 negative input。作者人工检查其可编译性及是否符合 issue 描述；不合格时改用 Claude 或 o1-mini 重问，仍不能验证则丢弃（第 3.1.2–3.1.3 节）。

### 4.2 Mutator 生成与验证

Gemini 2.5 Pro 驱动的 Mutator Creator 先把 negative→positive 的具体变化反向概括为通用 mutation description，再生成默认 3 组额外 C input-output pairs，最后创建通用 sed-based bash script。需要上下文信息的少数情形使用 Clang AST visitor。Validator 在原始 pair 和额外 3 组 pair 上执行脚本：4/4 通过为 Correct，3/4 为 Partially Correct；低于 3/4 或 harness 出错则进入 Refiner。Refiner 根据错误消息和输出 diff 修正，最多 5 轮（第 3.1.4 节）。

对生成结果做语义上的“变换输出”哈希去重：在代表性随机 seed 样本上应用 mutator，使用 `sha256sum` 聚合输出。论文报告去掉 16 个重复后保留 587 个 mutators（第 3.1.4 节）。

### 4.3 Fuzzing 运行流程

作者将 587 个 mutators 接入 MetaMut，形成 MetaMut-i；从中随机选择 20 个接入 Kitten，形成 Kitten-i。种子是 GCC 与 LLVM 全部 test cases。实验固定在 `-O2`，使用 GCC 15 revision `87492fb` 与 Clang 20 revision `9bdf683`，并用固定随机数种子重复运行（第 3.2、4.2 节）。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数，也没有训练损失函数。关键目标是通过可执行测试对验证 mutation rule：

```text
mutator(negative_input) ≈ positive_input
```

这里的“≈”是测试输出与预期输出一致，而不是形式化语义等价证明。Validator 的判定是：4 个 input-output pairs 全通过为 Correct，3 个通过为 Partially Correct；论文把两者都报告为可用 mutator（第 3.1.4 节）。

Fuzzing 侧的主要观测量是 branch coverage、crash 数量/唯一性、crash 类型和受影响 compiler module。coverage 用于 MetaMut 的队列探索；crash 去重使用 MetaMut 的 stacktrace-based procedure，关注顶部两个 stack frames（第 3.2、4.2 节）。这些是实验指标，不是可优化的显式 reward。

## 6. 实验设置

### 6.1 数据集来源

原始输入来自 GCC 和 LLVM/Clang 已修复、已关闭的历史 bug reports，以及 GCC/LLVM regression test suites。候选报告时间窗为 2023-01 至 2024-10，共 GCC 1,457、LLVM 303。最终从 1,760 报告挖掘 603 个候选 mutators，去掉 16 个输出行为重复项后为 587 个：GCC 412、LLVM 175（第 3.1.1、3.1.4 节）。

seed corpus 是 GCC 和 LLVM 的全部 test cases；第 3.2 节给出 35,472 个 seed test cases 的总量。作者没有把这些数据称为训练集/验证集/测试集；这是历史报告挖掘和 fuzzing seed corpus。报告筛选、人工 negative-case 检查和脚本验证降低了明显的无效样本风险，但历史报告本身带来选择偏差，论文在第 4.7 节承认 issue selection 是外部有效性威胁。

### 6.2 模型与工具

| 组件 | 论文明确给出的设置 |
| --- | --- |
| Negative input 生成 | GPT-4o mini；失败时可重问 Claude 或 o1-mini |
| Mutator agent | LangChain-based architecture + Gemini 2.5 Pro |
| Prompt 优化 | PromptPerfect，用于优化 negative-test prompt |
| Fuzzer | MetaMut、Kitten；增强版为 MetaMut-i、Kitten-i |
| 编译器 | GCC 15 revision `87492fb`；Clang 20 revision `9bdf683` |
| 编译选项 | `-O2` |
| 主机 | Ubuntu 22.04.5 LTS、双 AMD EPYC 9684X 96-core CPU、755 GB memory |
| Fuzz4All 对照 | NCSA Delta A40 节点、AMD EPYC 7763、NVIDIA A40、128 GB RAM、RHEL 8.8 |

论文没有明确给出所有 agent API 的推理温度、token 上限或训练框架版本。

### 6.3 对比方法

主要 baseline 是 MetaMut 的 supervised `mu.s` 与 unsupervised `mu.u` mutators；Kitten 是第二个 grammar-based mutational baseline。论文还作轻量 Fuzz4All 对照。背景中提到 MetaMut 相对 AFL++、Csmith、YARPGen、GrayC 的既有结果，但本实验的直接比较对象是 MetaMut/Kitten 及其 IssueMut 增强版（第 4.1 节）。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| Branch coverage | 编译器分支覆盖，图中以 covered branches 表示 | 越大越好 |
| Crashes | fuzzing 期间触发的崩溃，按运行/时间统计 | 越大越好，但需去重 |
| Unique crashes | 经 stacktrace 去重后的不同崩溃 | 越大越好 |
| Confirmed/fixed bugs | 开发者确认、修复或标为 duplicate 的报告 | 越多越好 |
| Compilation success rate | 生成程序成功编译比例；无效输入也可能用于稳健性测试 | 越高通常越好 |
| Crash/module distribution | crash 类型及位于 front-end、IR generation、optimization、back-end 的分布 | 用于多样性分析 |

## 7. 实验结果与结论

### 7.1 主要结果

IssueMut 从 1,760 个 GCC/LLVM bug reports 得到 587 个 mutators。摘要和第 4.6 节报告：IssueMut 相关 campaign 观察到 65 个可报告 bugs；其中 60 个被开发者确认、修复或标为 duplicate。摘要还概括为 GCC 25、LLVM 27 个新 bug 是 state-of-the-art mutational fuzzer 未发现的；第 4.6 节给出的 65 个报告汇总是 LLVM 37、GCC 28，其中 confirmed 38、duplicate 9、fixed 13，合计开发者认可 60。

### 7.2 与传统/现有变异式方法比较

在五次、每次 24 小时、30 physical cores 的 MetaMut 对比中，MetaMut-i 平均发现 93.2 crashes，MetaMut 平均 49.0，最多约 1.9×；合并运行结果的 unique crashes 为 MetaMut-i 77、MetaMut 19（第 4.3.1 节）。两者 branch coverage 差异很小，说明提升主要来自不同的 bug-reaching paths，而非明显扩大覆盖区域。

在 Kitten 的 50 次、每次 8 小时、单 CPU core 对比中，Kitten-i 平均 14.22 crashes，Kitten 7.98，提升最多约 1.78×；unique crashes 为 Kitten-i 独有 43、Kitten 独有 13。paired t-test 的 `p < 0.001`、95% CI 为 `[5.45, 7.03]` crashes，Cohen’s `d = 2.23`（第 4.3.2 节）。Kitten-i 只接入 20 个随机选择并人工实现的 IssueMut mutators，不是全部 587 个。

### 7.3 与其他 LLM 方法的比较

与 MetaMut 相比，IssueMut mutators 更多执行 add/modify/delete，并常来自真实 bug 的多个编辑；MetaMut mutators 更多是单个 AST action。IssueMut 更容易体现近期 C23 特性，例如新的 literal suffix 和 binary literal；论文认为 MetaMut 的一般化 LLM 能力未必能准确优先处理新近语言特性（第 4.4.1 节）。

与 Fuzz4All 的 24 小时轻量对照中，Fuzz4All 在 Clang 生成 244,722 个输入、GCC 生成 203,483 个输入，总共触发 11 个 crash，其中 9 个 unique，IssueMut 也触发其中 4 个。作者明确说明这不是完全同等的 side-by-side 比较：Fuzz4All 需要 GPU，IssueMut 的 MetaMut/Kitten 运行主要使用 CPU，且版本和配置有所差异（第 5.1 节）。

### 7.4 消融实验

只保留此前触发过 crash 的 104 个 successful mutators 后，24 小时内出现 20 个其他全量 mutator campaign 没有触发的 crash；在 2 小时处，focused campaign 平均触发 50.8 个 distinct crashes（第 4.5 节）。这表明在固定预算下，成功 mutator 集合可提高 exploitation 速度，但并不等于对所有未探索空间都完备。

跨编译器小规模消融从 GCC/LLVM 各抽 100 个 mutators，在 source compiler × target compiler 四种组合中各运行 8 小时、10 CPU cores。报告统计中，15/37 个 LLVM bugs 约 40% 由 GCC 来源 mutators 暴露，9/28 个 GCC bugs 约 32% 由 LLVM 来源 mutators 暴露；表 4 的平均 crash 数为 GCC→GCC 2.25、GCC→LLVM 1.25、LLVM→LLVM 6.00、LLVM→GCC 5.25（第 5.2 节）。

### 7.5 案例分析

第 2 节的 Clang bug #120083 由两个 mutation 共同形成：M17 添加带 `extern` 的函数声明，M3 把 `extern` 改成 `static`，最终在 LLVM IR generation 阶段触发 crash。第 5.3 节还展示 M3 触发 LLVM #123410、M5 触发 `__builtin_dump_struct` 相关 LLVM #120086、M1 包装 `__builtin_assoc_barrier` 触发 GCC #118868、M7 删除数组长度触发 GCC #119001 的例子。

## 8. 主要创新点

### 8.1 创新点一：把 bug history 变成可复用 mutator

已有工具可用 LLM 直接生成 mutator，或直接补全/组合测试程序；IssueMut 的新设计是从真实 bug report 的 positive/negative pair 反向抽取通用变换，再应用到整个 seed corpus。论文的证据是 587 个去重后的 C mutators 以及相对 MetaMut/Kitten 的 unique crash 增益（第 3、4.3 节）。

### 8.2 创新点二：positive/negative pair 加额外 pair 的过拟合控制

仅让脚本复现原始 bug pair 容易过拟合。IssueMut 让 Creator 生成默认 3 个额外 input-output pairs，再由 Validator 检查 4 个 pairs，并在失败时用 Refiner 迭代。这个设计是工程机制；其价值在于把 LLM 生成的规则约束为可执行、可泛化的测试变换，而不是形式化证明（第 3.1.4 节）。

### 8.3 创新点三：把历史 mutator 接入多种 mutational fuzzer

论文不仅生成规则，还将其 retrofitting 到 MetaMut 和 Kitten，显示 bug-history mutators 可以与 coverage-guided 和 grammar-based 两种搜索方式结合。跨 GCC/LLVM 结果进一步支持一定程度的跨编译器复用（第 4.3、5.2 节）。

### 8.4 创新点四：成功 mutator 的预算聚焦经验

论文通过 successful-only campaign 展示了一个可操作的 fuzzing 调度策略：在固定预算下优先使用历史上触发过 crash 的 mutators。该结论来自实验性 limit study，不是新的强化学习策略（第 4.5 节）。

## 9. 局限性

### 9.1 论文明确承认的局限

论文在第 4.7 节承认：LLM 生成 negative tests 和 mutators 会带来 hallucination 及 model-specific behavior；作者用人工检查、自动 validator 和多次 fuzzing 缓解。测试结果具有随机性，作者用固定随机种子多次重复；issue 选择范围只覆盖已修复 bug，构成外部有效性威胁。论文还指出不同 negative variant 可能生成不同 mutator，对该选择敏感性留作未来工作。

作者没有声称 IssueMut 提供形式化语义等价保证。Validator 只在有限 input-output pairs 上检查脚本行为。MetaMut 当前只检查 crash；论文指出理论上可扩展到 differential testing 的 miscompilation 检查，但本文没有完成该扩展（第 3.2 节）。

### 9.2 阅读后发现的潜在局限

IssueMut 的主要实现面向 C，context-insensitive 情况优先用 sed-like 脚本；复杂跨函数、宏展开、模板或强语境依赖的变换可能需要更多 AST 工程。Kitten-i 只实现 20 个随机 mutators，因此 Kitten 结论不能直接外推到全量集合。

不同对照的时间、硬件和并行度不同，Fuzz4All 比较尤其应视为轻量参考，不能据此得出成本或吞吐的严格结论。历史 bug 报告天然偏向曾被发现、报告和修复的行为，可能遗漏未报告的编译器状态空间。实验以 crash 为主，不能把“crash 数提升”直接解释为所有 miscompilation 或语义错误都提升。

## 10. 阅读后的研究方向反思

值得借鉴的是“真实 bug 证据 → 可复用变换 → 有限可执行验证 → fuzzing 反馈”的闭环，以及把 generator 与现有 fuzzer 解耦。IssueMut 的核心贡献是历史驱动的 mutator mining 和验证/接入方法，不能仅把 C 换成 RISC-V 或把 GCC 换成 LLVM 就宣称新颖。

若迁移到 RISC-V，应区分方法迁移与新问题：仅替换目标 ISA 属于平台适配；针对 RVV intrinsic、向量长度/LMUL/VL 状态、ABI 和不同后端 lowering 设计历史 bug schema、跨编译器 oracle 或新 mutator 语言，才可能形成新的研究问题。本文没有 RISC-V 实验，因此与 RISC-V 的关系是“可借鉴的生成/测试框架”，不是 RISC-V 结论。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV intrinsic 的历史驱动 mutator 挖掘

#### 研究问题

历史 LLVM/GCC RISC-V/RVV issue 是否能产生可复用、能触发 backend/lowering bug 的 intrinsic 变换。

#### 与原论文的区别

不只替换编译器；增加 RVV 的 `vl`、`vtype`、LMUL、tail/mask 和 ABI 约束建模，并区分编译通过、汇编约束和运行时结果。

#### 可能的创新点

面向 RVV 状态组合的 mutation description schema，以及跨 LLVM 后端版本的可迁移 mutator 验证。

#### 实验框架

```text
RVV issue/commit + regression tests → positive/negative pairs
→ LLM 生成候选 mutator → LLVM parser/assembler/运行时 oracle 验证
→ QEMU/真实 RVV 硬件差分 fuzzing
```

#### 可行性

需要 LLVM RISC-V backend、RVV 编译器版本、QEMU 或 RVV 机器、历史 issue 与可复现测试。

#### 主要风险

真实 RVV 硬件可得性、模拟器与硬件差异、未定义行为及向量状态 oracle 不充分。

### 11.2 历史 mutator 与语义等价/翻译验证结合

#### 研究问题

如何在 compiler crash 之外发现 IssueMut 生成变换引起的错误优化或错误代码生成。

#### 与原论文的区别

把有限 pair validator 扩展为 differential execution、Alive2 类 translation validation 或架构级参考解释器；研究对象从 robustness crash 扩展到 semantic miscompilation。

#### 可能的创新点

为每个 mutator 自动生成等价性假设、输入约束和多级 oracle，并量化 false positive/false negative。

#### 实验框架

```text
历史 bug pair → mutator → 生成候选程序
→ 编译器 A/B 或 IR 验证器 → 运行时/形式化反馈
→ 保留能稳定暴露语义差异的 mutator
```

#### 可行性

需要 LLVM IR、Alive2 或等价工具、差分编译器以及可控输入生成。

#### 主要风险

形式化验证覆盖面有限；未定义行为可能把真实错误与不合法测试混淆；运行时结果不等于全程序语义证明。

### 11.3 历史成功率驱动的 mutator 调度

#### 研究问题

successful-only 策略如何随编译器版本、seed、模块和时间变化而动态更新。

#### 与原论文的区别

本文只做 fixed set 的 limit study；后续可研究在线 bandit/RL 调度、版本漂移和探索-利用权衡。

#### 可能的创新点

以新覆盖、不同 compiler module、crash 去重和可复现 bug 作为多目标反馈，而不是只看 crash 次数。

#### 实验框架

```text
mutator pool → 并行 fuzzing → coverage/crash/module feedback
→ 更新 mutator priority → 新一轮 seed/mutator 选择
```

#### 可行性

可直接在 MetaMut 或 Kitten 框架上实现，先使用 GCC/LLVM 再扩展 RISC-V backend。

#### 主要风险

过度利用旧成功 mutator 会降低新区域探索；crash 去重和版本变化会导致反馈非平稳。

## 12. 与其他已读文献的关系

本轮只完成 IssueMut 一篇论文，因此不能依据当前批次建立多篇横向实验比较。论文正文自身将 MetaMut 作为主要对照：MetaMut 是 LLM 生成 mutator 的方法参考，IssueMut 则把真实 bug history 转换成 mutator；Fuzz4All 是直接由 LLM 生成完整测试输入的 generator，对应另一种生成路径。LegoFuzz、ClozeMaster、ATLAS 等相关工作在 IssueMut 的 related work 中被提及，但本轮没有重新通读其 PDF，故不把其细节写成已确认的本批次事实。

从角色上看，IssueMut 属于 `GENERATOR / G4_Tool_Test_Fuzz_Generation`：LM 最终参与生成可复用 compiler fuzzing mutator/tool，而不是选择已有 pass（SELECTOR）或直接输出待编译优化程序作为最终产品（TRANSLATOR）。它最适合作为 compiler-test/fuzz 工具模块和 generator baseline。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 从历史 compiler bug 报告挖掘可复用 C mutator |
| 核心问题 | 真实 bug history 能否提升变异式 compiler fuzzing |
| 输入 | GCC/LLVM bug reports、positive/negative C pairs、regression-test seeds |
| 输出 | 587 个去重 bug-history mutators及增强版 MetaMut/Kitten |
| 核心方法 | LLM 生成 negative case；agent 概括、合成、验证、修正 mutator |
| 使用的模型 | GPT-4o mini；Gemini 2.5 Pro；失败重问可用 Claude/o1-mini |
| 使用的编译器工具 | GCC 15、Clang 20、MetaMut、Kitten、Clang AST visitor |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；只有有限 input-output 行为验证 |
| 数据集规模 | 1,760 reports；35,472 seeds；603 候选 mutators，去重后 587 |
| 主要指标 | branch coverage、crashes、unique crashes、confirmed/fixed bugs |
| 最重要实验结果 | MetaMut-i 24 小时平均 93.2 vs 49.0 crashes；unique 77 vs 19；IssueMut 报告 65 bugs，60 被确认/修复/标为 duplicate |
| 核心创新 | 将真实 bug history 归纳为可复用 mutator 并接入现有 fuzzers |
| 主要局限 | C 任务范围、有限 pair 验证、历史选择偏差、以 crash 为主 |
| 与 RISC-V 研究的相关性 | 中：可迁移生成/验证闭环，但正文没有 RISC-V 实验 |
| 最适合作为 | compiler fuzz 工具模块、GENERATOR/G4 baseline、历史驱动 mutator 生成参考 |

这篇论文最值得学习的是把真实 bug 报告转化为可复用、可验证的 fuzzing 变异能力；最主要的局限是有限测试对不能替代形式化语义保证，且实验主要面向 C 编译器 crash。用于后续研究时，合理方式是把 IssueMut 作为历史驱动的 generator/fuzz 模块，再针对 RVV 状态、后端 lowering 或 miscompilation oracle 提出新的问题，而不是简单替换目标平台。
