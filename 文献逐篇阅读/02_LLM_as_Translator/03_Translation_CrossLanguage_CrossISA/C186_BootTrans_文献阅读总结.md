# BootTrans 文献阅读总结

论文题目：**Bootstrapping Code Translation with Weighted Multilanguage Exploration**

作者：Yuhan Wu、Huan Zhang、Wei Cheng、Chen Shen、Jingyue Yang、Wei Hu

发表时间：2026

发表平台：ACL 2026 Long Papers，pp. 36247–36259

论文链接或编号：DOI `10.18653/v1/2026.acl-long.1678`；官方页面 <https://aclanthology.org/2026.acl-long.1678/>

关键词：多语言代码翻译、执行反馈、强化学习、RLVR、GRPO、测试 oracle、数据自举、语言感知加权

> 本笔记依据 staging 中的 ACL 官方 PDF（13 页）整理。论文事实与阅读后的分析分开描述；没有把有限测试通过率写成形式化语义证明。

---

## 1. 研究背景

代码翻译是把一种编程语言中的程序迁移到另一种语言，同时尽量保持语法可接受性和运行语义一致性的任务。论文将其动机联系到遗留系统现代化和跨平台互操作。传统统计或规则式翻译器需要为语言对编写规则；无监督程序翻译方法可以减少平行代码依赖，但通常需要大量单语料来学习跨语言对应关系（第 1、5 节）。

LLM 使代码生成与翻译具有更强的跨语言建模能力，但论文指出两个具体困难：第一，带有可执行测试 oracle 的高质量平行代码稀缺；第二，不同语言对难度不同，统一优化会让容易的方向产生更多奖励，从而压制困难方向。仅依靠表面相似度或静态平行数据，难以直接优化功能正确性。

论文采用强化学习可验证奖励（Reinforcement Learning from Verifiable Rewards，RLVR）：把编译和单元测试执行结果作为训练信号。关键观察是，测试套件表达的是功能行为，经过规则转换后可以跨语言复用，因此可以在缺少目标语言参考实现时提供执行验证。

## 2. 论文要解决的问题

### 2.1 缺少多语言、带可执行 oracle 的训练数据

论文从一个资源丰富的 pivot language（默认 Python）出发，利用已有代码和测试套件生成目标语言的可验证翻译，再把通过测试的目标代码加入探索池。问题在于如何从单一 pivot 扩展到反向和跨语言方向，例如 Java→Python、Java→C++，而不是只训练 Python→X。

### 2.2 多语言翻译中的优化不平衡

不同翻译方向的难度不一致。若每个方向统一加权，简单方向更容易得到正奖励，模型可能持续优化简单模式，而困难方向停滞或波动。论文希望根据同一源代码在其他 sibling languages 上的表现，动态提高困难方向的训练权重。

> 本文主要研究：如何利用可迁移的单元测试 oracle 和执行反馈，通过数据自举与语言感知加权，使一个 LLM 在多个编程语言方向上进行更均衡的功能代码翻译。

## 3. 核心方法概述

BootTrans 包含两个核心部件：Bootstrapping Multilanguage Exploration（多语言探索自举）和 Language-aware Weight Optimization（语言感知权重优化）。前者维护 seed pool 与 exploration pool，用通过测试的模型翻译结果扩展后续训练输入；后者根据 sibling translation directions 的累计奖励重加权 GRPO 目标。

```text
Python pivot 代码 + 单元测试
        ↓ 规则转换测试 oracle 到 Java/C++
模型对每个目标语言生成 G 个候选翻译
        ↓ 编译 + 执行对应测试套件
通过候选获得二值奖励，并进入 exploration pool
        ↓
从 seed pool / exploration pool 继续采样
        ↓
按 sibling-language 奖励计算语言感知权重
        ↓
GRPO 更新翻译策略 πθ
        ↓
输出目标语言代码
```

LLM 的最终编译系统角色是 Translator：它直接输出 C++、Java、Python 等目标语言源代码。编译器/解释器和单元测试不是输出角色，而是验证生成代码并形成 RL 奖励的外部工具。论文的训练数据使用 MultiPL-E 转换测试脚手架，并过滤不能编译、不能执行或入口签名不明确的测试。

## 4. 实验框架与训练流程

论文不是只做提示词评测，而是训练一个代码翻译策略。其执行和训练流程如下。

### 4.1 Seed pool 构造

原始训练来源是 KodCode-RL-10K 子集。作者提取 Python 解答和测试用例，并使用 MultiPL-E 将测试用例脚手架转换为 Java 与 C++。过滤失败编译/执行的测试以及入口签名不明确的样本；同时删除函数入口名称与 HumanEval-X 或 TransCoder-Test 重叠的训练样本，以降低数据泄漏风险。最终得到 5,584 个 Python 源程序，每个样本平均拥有 Python 8.11、Java 8.09、C++ 8.09 个测试用例（第 4.1 节与附录 A）。

### 4.2 多语言探索与经验收集

每一步从 seed pool 与 exploration pool 取一个 batch。对源语言之外的每个目标语言生成 G 个候选，使用目标语言测试 oracle 计算奖励。如果某个候选编译并通过全部测试，就把它作为目标语言代码加入 exploration pool；当同一方向有多个通过候选时随机保留一个。exploration pool 是 FIFO 队列，容量与非 pivot 语言数量和 rollout batch size 相关。

这一机制使通过验证的 Java/C++ 翻译可以在后续被当作源代码，支持 Java→Python、Java→C++ 等原始 seed 中没有的方向。只加入通过测试的 rollout，以减少语义漂移。

### 4.3 语言感知权重与 GRPO 更新

对每个源代码和目标语言，先生成一组候选并计算累计奖励；然后利用其他 sibling 目标语言的奖励计算该方向的权重。模型采用 Group Relative Policy Optimization（GRPO）更新，并加入 KL 惩罚和 clipped importance ratio。

### 4.4 推理与兼容性实验

训练后使用 greedy decoding 进行评测。论文还将 BootTrans 与 InterTrans 的路径扩展以及 UniTrans 的迭代执行反馈结合，考察训练时优化是否能与推理时增强方法叠加。另有 Java/C++ pivot 实验、未见 Go 语言实验、低资源 Dlang/Racket 实验和 ClassEval-T 类级翻译实验。

## 5. 奖励函数、损失函数或关键公式

### 5.1 二值可验证奖励

论文定义：

```text
R(y, T) = 1[ y 编译成功并通过测试套件 T ]
```

编译错误、运行时错误和超时均得到 `R = 0`。该奖励优化的是测试可观察到的功能正确性，而不是参考译文的表面相似度。它不是形式化等价证明。

### 5.2 语言感知权重

对源代码 `xi` 和目标语言 `Lk`，令 `Ri,k` 为该方向 G 个候选的累计奖励，令 `Ri,¬k` 为其他 sibling 目标语言的累计奖励：

```text
wi,k = Ri,¬k / (Ri,k + Ri,¬k)
```

当目标方向奖励较低、但 sibling 方向表现较好时，`wi,k` 较高，训练会更多关注该困难方向。如果所有方向候选都失败，分母为零，论文跳过该样本的 policy update。

### 5.3 GRPO 目标

论文在式（3）中以 `wi,k` 加权 GRPO 目标，目标包含：

- 当前策略与旧策略之间的 clipped importance ratio；
- 同一目标语言候选组的标准化 advantage；
- 参考策略 KL penalty，系数 `β = 0.01`；
- clipping range `ε = 0.2`。

其意图是保留 GRPO 的相对奖励学习，同时让不同语言方向不再使用完全相同的训练权重。论文没有把奖励设计成可读性、可维护性或 idiomatic style 的复合指标。

## 6. 实验设置

### 6.1 数据集来源

训练数据基于 KodCode-RL-10K 子集，使用 Python 代码和测试，再通过 MultiPL-E 转换为 Java/C++ 测试脚手架。最终训练集为 5,584 个有效 Python 样本。Python、Java、C++ 测试用例平均数量分别为 8.11、8.09、8.09。

评测使用：

- HumanEval-X：每种语言 164 个源代码片段；在 C++、Python、Java 的六个方向上共 984 个测试样本，平均每个样本 6.9 个测试用例。
- TransCoder-Test：翻译到 Java、Python、C++ 的样本数分别为 482、464、467，六个方向合计 2,826 个测试样本，平均每个样本 10 个测试用例。
- ClassEval-T：用于类级代码翻译，评估类级和方法级 CA。

作者过滤了与 HumanEval-X 和 TransCoder-Test 函数入口重叠的训练样本，但训练集由 KodCode 与 MultiPL-E 构造，仍应在后续复现时检查更细粒度的语义或模板泄漏。

### 6.2 模型与工具

论文实验涉及 Qwen3-1.7B、Qwen3-32B、Llama-3.1-8B-Instruct、Llama-3.1-70B-Instruct、Qwen2.5-7B-Instruct、Qwen2.5-32B-Instruct 等模型。BootTrans 主训练使用 Qwen3-1.7B；优化器为 AdamW，学习率为 `1×10^-6`；rollout macro batch size 为 256，`G = 8`，actor micro batch size 为 8。

代码翻译和测试转换使用 MultiPL-E；候选正确性由目标语言编译和单元测试执行判断。论文未在正文中统一给出所有编译器版本和硬件平台，不能补写。

### 6.3 对比方法

主要对比包括：

- 同族基础模型与大规模 sibling 模型；
- EffiReasonTrans：用 RL 优化推理路径的代码翻译方法；
- CoTran：利用编译器和符号执行反馈的协作式 RL 翻译；
- MultiPL-T：用 teacher 模型合成多语言代码并 rejection sampling 后进行 SFT；
- PPOCoder：基于 PPO 和执行反馈的代码生成/翻译方法；
- OORL：结合在线 RL 与离线 group DPO 目标的方法。

主对比实验尽量将方法初始化为相同 Qwen3-1.7B，并使用相同训练数据；EffiReasonTrans 使用其公开数据集。附录 B 记录了各 baseline 的适配方式。

### 6.4 评价指标

主要指标是 top-1 Computational Accuracy（CA@1）：生成一个候选代码后，依据编译和测试执行结果判断是否正确。论文还在 ClassEval-T 上报告类级 `CAc` 与方法级 `CAm`，并在附录中按逻辑不一致、语法无效、API 误用、类型不匹配、签名不匹配分类错误。

| 指标 | 含义 | 越大越好 |
|---|---|---|
| CA@1 | top-1 候选的编译/测试通过准确率 | 是 |
| CAc | ClassEval-T 类级准确率 | 是 |
| CAm | ClassEval-T 方法级准确率 | 是 |
| 错误计数 | 不同翻译失败类型的数量 | 越少越好 |

## 7. 实验结果与结论

### 7.1 主要结果

在 Qwen3-1.7B 上，BootTrans 的 HumanEval-X 六方向平均 CA@1 为 74.70，TransCoder-Test 平均为 84.70。相同模型的基础结果分别为 64.33 和 79.58，因此平均提升 10.37 和 5.12 个百分点（表 1）。

在 Llama-3.1-8B-Instruct 上，BootTrans 相比基础模型的两套基准平均提升分别为 15.35 和 5.84 个百分点；在 Qwen2.5-7B-Instruct 上分别提升 15.35 和 4.33 个百分点。具体方向仍有差异，不能把平均提升解释为所有语言对均等提升。

### 7.2 与其他 LLM/翻译方法比较

使用相同 Qwen3-1.7B 设置时，BootTrans 在 HumanEval-X 和 TransCoder-Test 的平均 CA@1 分别为 74.70 和 84.70，高于 EffiReasonTrans 的 65.25 和 80.36、CoTran 的 64.03 和 79.16、MultiPL-T 的 64.74 和 78.18、PPOCoder 的 69.21 和 81.04、OORL 的 69.92 和 75.22（表 2）。这些是论文设置下的执行测试结果，不是形式化正确率。

### 7.3 消融实验

Qwen3-1.7B 消融显示：

- 去掉 exploration pool 后，HumanEval-X 平均 CA@1 从 74.70 降至 70.73；TransCoder-Test 从 84.70 降至 82.88。
- 去掉语言感知 weighting 后，HumanEval-X 平均降至 72.16；TransCoder-Test 降至 83.19。

论文据此认为，自举探索对反向/跨语言方向尤其重要，而 weighting 能缓解简单方向对训练信号的支配。

### 7.4 Pivot、语言扩展与类级结果

将 Java 或 C++ 替换为 pivot 时，BootTrans 相对对应基础模型仍有提升，但 Python pivot 的总体覆盖最好。对未参与训练的 Go 以及低资源 Dlang、Racket，BootTrans 也高于 Qwen3-1.7B 基础模型，例如 P→D 从 23.08 提升到 41.67，P→R 从 12.18 提升到 28.85；这些结果来自 HumanEval-X 扩展实验。

在 ClassEval-T 上，BootTrans 多数方向改善类级或方法级 CA，但 J→C 没有改善，论文将其归因于 Qwen3-1.7B 处理 C++ 复杂内存管理和语法的能力限制。

### 7.5 案例和错误分析

一个 C++→Python 字符编码案例中，基础模型把字符加法误译为字符串拼接，而 BootTrans 使用 `chr(ord(char) + 2)` 保持行为。另一个最大公约数案例中，BootTrans 使用 Python `divmod`，但返回值处理存在错误，说明探索能够产生更 idiomatic 的表达，也可能引入类型或语义错误。

在 HumanEval-X 错误分类图中，论文报告 BootTrans 相比基础模型降低了多类错误，尤其是 API misuse；但图中统计依赖该基准和错误分类规则，不能泛化为所有代码迁移场景。

## 8. 主要创新点

### 8.1 创新点一：基于可迁移测试 oracle 的多语言自举

现有 RLVR 翻译训练通常受限于带参考实现和测试的语言对。BootTrans 从一个 pivot 语言的代码-测试对出发，把测试转换到目标语言，并把通过验证的翻译重新作为后续源输入。这种 seed pool + exploration pool 设计使训练逐步覆盖原始数据缺少的反向和跨语言方向。表 3 的去掉 exploration 消融支持其作用。

### 8.2 创新点二：语言感知的 sibling-reward weighting

论文没有对所有翻译方向平均处理，而是使用同一源代码在其他目标语言上的奖励估计困难程度；当某个方向相对落后时提高其权重。去掉 weighting 后的平均下降支持该机制的有效性。

### 8.3 创新点三：训练时方法与推理时增强的可组合性

BootTrans 主要改造训练阶段，但论文还展示了它可以与 InterTrans 的路径扩展和 UniTrans 的迭代反馈组合。该结果表明 BootTrans 的自举训练机制与部分推理时方法具有互补性，但不等于论文提出了新的推理时搜索算法。

## 9. 局限性

### 9.1 论文明确承认的局限

- 评测主要覆盖 Python、Java、C++ 三种命令式语言，对具有根本不同范式的领域特定语言可能需要额外适配。
- 语言感知 weighting 依赖二值执行奖励，不能直接衡量可读性、可维护性或 idiomatic style。
- 方法效果受测试套件规模影响；pivot 语言测试不足会导致性能下降。
- 未来工作包括扩展到函数式语言和设计更复杂的奖励机制。

### 9.2 阅读后的潜在局限

- 编译通过并通过有限单元测试只证明在测试覆盖范围内的行为一致，不能替代形式化语义等价证明。
- exploration pool 只收集通过测试的候选，可能强化测试 oracle 能覆盖到的模式，对未覆盖行为形成盲点。
- 默认 Python pivot 受 KodCode 数据规模、MultiPL-E 转换模板和 LLM 预训练语言分布影响；换到 RISC-V、DSL 或系统级代码不能只替换语言名即视为成立。
- 论文主实验多为函数/方法级翻译；ClassEval-T 虽涉及类级依赖，但对大型仓库、跨文件 API 和构建系统的覆盖仍有限。
- 训练使用多轮 rollout 和 GRPO，计算成本、失败样本比例及不同语言编译执行环境的开销没有在摘要级指标中完全体现。

## 10. 阅读后的研究方向反思

BootTrans 最值得借鉴的是把“代码翻译正确性”落到可执行测试 oracle，并用跨语言测试迁移缓解平行代码稀缺；这比只优化 BLEU、编辑距离或 token-level 相似度更接近编译/迁移系统的实际需求。对编译器研究而言，它可作为 Translator 训练方法参考，而不是 Selector 或 Generator 框架。

它的核心贡献已经是 pivot-based test-oracle bootstrapping 与 language-aware weighting。仅把 Python/Java/C++ 替换成 RISC-V 汇编或某个新 ISA，创新性不足，还需要解决 ISA 语义、调用约定、寄存器/内存模型和可执行验证环境等新问题。更合理的迁移方式是把其“可验证自举 + 困难方向加权”与跨 ISA 的 emulator、ISA simulator 或 translation validation 结合，并明确区分测试通过与语义证明。

与 RISC-V 研究的相关性为中等：论文没有 RISC-V 实验，但其执行反馈训练范式可作为跨 ISA Translator 的方法基线。由于 RISC-V 目标代码的 ABI、指令选择和硬件扩展会造成新的验证约束，不能直接照搬其三种高级语言的测试转换模板。

## 11. 可进一步尝试的研究方向

以下是阅读后的建议，不是 BootTrans 已实现的工作。

### 11.1 面向跨 ISA 的分层可验证自举翻译

#### 研究问题

如何把源代码→RISC-V 汇编/LLVM IR 的翻译测试，从函数级单元测试扩展到 ABI、寄存器状态和内存访问行为验证。

#### 与原论文的区别

不只是更换目标语言；新增 ISA 语义、调用约定、模拟器执行和 translation validation 层。

#### 可能的创新点

把 BootTrans 的 exploration pool 分成源码级、IR 级和汇编级，并只允许通过逐层约束的候选进入下一层。

#### 实验框架

```text
C/C++ 源程序 + 测试
        ↓
LLVM IR / RISC-V 汇编候选
        ↓
编译、模拟器执行、ABI/寄存器检查
        ↓
分层奖励与困难方向加权
        ↓
GRPO 更新翻译策略
```

#### 可行性

需要 LLVM、RISC-V 编译器/模拟器、可执行测试和一个可控的小型代码翻译模型。

#### 主要风险

测试覆盖不足、模拟器与真实硬件差异、汇编输出的非唯一性，以及编译通过但状态语义不一致。

### 11.2 结构化奖励替代单一二值测试奖励

#### 研究问题

如何在有限测试 oracle 下区分编译失败、ABI 错误、内存错误、数值误差和性能退化。

#### 与原论文的区别

不再只使用 `R∈{0,1}`，而是将静态验证、动态测试和 ISA/性能约束分层组合。

#### 可能的创新点

设计防止 reward hacking 的分级奖励，并研究其对不同语言/ISA 难度加权的影响。

#### 实验框架

```text
候选翻译
  ↓
语法/编译检查 → ABI/静态检查 → 动态测试 → 性能/代码尺寸检查
  ↓
分层奖励与错误类型
  ↓
加权策略更新
```

#### 可行性

可从已有 HumanEval-X 或小型 RISC-V kernel 集合开始，逐步增加仿真和真实性能测试。

#### 主要风险

多目标奖励冲突、奖励尺度不稳定，以及性能反馈成本高。

### 11.3 面向大型仓库的跨文件探索池

#### 研究问题

BootTrans 的函数级探索如何处理跨文件依赖、构建系统、宏、外部库和版本化 API。

#### 与原论文的区别

新增仓库图、依赖一致性和增量构建，不再把单函数测试视为完整正确性。

#### 可能的创新点

按调用图或模块边界维护探索池，只有接口、构建和测试共同通过的片段才可作为新训练样本。

#### 实验框架

```text
仓库依赖图
  ↓
按依赖顺序翻译模块
  ↓
增量编译 + 接口检查 + 集成测试
  ↓
保留通过模块并扩展探索池
```

#### 可行性

需要真实开源项目、构建脚本、静态分析器和增量测试基础设施。

#### 主要风险

编译成本、模块间错误归因和训练数据泄漏。

## 12. 与其他已读文献的关系

本轮 staging 只对 BootTrans 完成正文阅读，不能把其他候选的未读摘要当作已确认事实。基于 BootTrans 正文中列出的相关工作，可以作如下有限关系判断：

- 与 TransCoder、TransCoder-ST、MultiPL-E 等工作共享“跨语言代码翻译 + 可执行测试”问题背景，但 BootTrans 的区别在于用 pivot 测试 oracle、探索池和语言感知权重进行 RLVR 训练。
- 与 CoTran、PPOCoder、OORL、EffiReasonTrans 都涉及 RL 或执行反馈；BootTrans 的直接差异是多语言方向的自举扩展和 sibling-reward weighting。
- 与 InterTrans、UniTrans 的关系是训练时方法和推理时路径/迭代反馈可以组合；BootTrans 的表 4 给出了兼容性实验。
- 与 AlphaTrans、LLMigrate、SACTOR、Scalable Validated Code Translation 等本地或用户明确排除的迁移工作不能在本笔记中做正文级比较，因为本轮没有重新阅读它们的 PDF；只保留全局去重层面的版本/题名排除记录。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 多语言 LLM 代码翻译 |
| 核心问题 | 平行代码和可执行 oracle 稀缺；语言方向优化不平衡 |
| 输入 | 源语言代码、目标语言、可迁移测试套件 |
| 输出 | 目标语言源代码 |
| 核心方法 | seed/exploration 双池自举 + language-aware weighting + GRPO |
| 使用的模型 | 主训练 Qwen3-1.7B；比较多种 Qwen/Llama 模型 |
| 使用的编译器工具 | MultiPL-E 测试转换；目标语言编译与单元测试执行 |
| 是否使用强化学习 | 是，GRPO/RLVR |
| 是否使用形式化验证 | 否；使用编译和有限单元测试执行反馈 |
| 数据集规模 | 训练 5,584 个样本；HumanEval-X 984 个六方向样本；TransCoder-Test 2,826 个样本 |
| 主要指标 | CA@1、ClassEval-T 的 CAc/CAm、错误类型计数 |
| 最重要实验结果 | Qwen3-1.7B 上 HumanEval-X 平均 74.70、TransCoder-Test 平均 84.70 |
| 核心创新 | 可执行测试 oracle 驱动的多语言自举和困难方向加权 |
| 主要局限 | 语言范围有限、二值奖励不衡量代码质量、依赖测试规模 |
| 与 RISC-V 研究的相关性 | 中；可借鉴可验证 Translator 训练，但没有 RISC-V 实验 |
| 最适合作为 | 跨语言/跨 ISA Translator 的训练方法参考和 baseline |

> 这篇论文最值得学习的是把测试 oracle 变成可扩展的翻译训练信号，并用探索池突破单向语言迁移；最主要的局限是有限测试和二值奖励不能保证全面语义等价。如果用于后续研究，最合理的使用方式是作为可验证翻译训练基线，再加入 ISA/ABI/IR 级约束，而不是简单替换目标语言名称。
