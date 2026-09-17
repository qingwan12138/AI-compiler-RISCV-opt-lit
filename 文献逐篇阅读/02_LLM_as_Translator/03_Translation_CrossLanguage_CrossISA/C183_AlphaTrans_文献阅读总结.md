# AlphaTrans 文献阅读总结

论文题目：**AlphaTrans: A Neuro-Symbolic Compositional Approach for Repository-Level Code Translation and Validation**

作者：Ali Reza Ibrahimzada、Kaiyao Ke、Mrigank Pawagi、Muhammad Salman Abid、Rangeet Pan、Saurabh Sinha、Reyhaneh Jabbarvand

发表时间：2025 年 7 月

发表平台：Proceedings of the ACM on Software Engineering，Volume 2，FSE，Article FSE109；23 页

论文链接或编号：DOI `10.1145/3729379`；PDF 来源：[作者/机构公开 PDF](https://alirezai.cs.illinois.edu/assets/pdf/alphatrans.pdf)

关键词：仓库级代码翻译、Java-to-Python、神经符号方法、程序分解、静态分析、GraalVM 语言互操作、测试分解、LLM 反馈

> 本笔记依据 staging 中已核验的 23 页正式 PDF 撰写。事实描述以论文正文为准；第 10—12 节为阅读后的分析或后续建议。

## 1. 研究背景

代码翻译把一个编程语言中的程序转换到另一种编程语言，常用于应用现代化、维护迁移和跨语言复用。传统 transpiler 主要依赖手写规则，容易受到语言版本演进、语言对专用性、语法/语义差异和生成代码可读性的限制。

论文指出，已有 LLM 代码翻译方法在人工构造的小型 benchmark 上表现较好，但面对真实仓库时会受到三类困难影响：跨语言的编程范式、类型系统和内存管理差异；跨方法、跨类依赖造成的验证困难；以及整个项目或类超出模型上下文窗口。论文因此把 LLM 代码生成与程序分析、项目骨架、语言互操作和测试反馈组合起来，目标是处理完整的真实 Java 仓库，而非只翻译孤立函数。

论文将“神经符号”用于表示 LLM 与程序分析的组合；正文脚注特别说明，这里的 symbolic 指与机器学习互补的符号/程序分析方法，不等同于符号执行本身。

## 2. 论文要解决的问题

### 2.1 真实仓库的规模与依赖

完整项目可能包含数百个文件、数千行代码和长调用链，不能整体放入 LLM 上下文。跨类、跨方法和循环依赖也使得简单的逐文件翻译难以保持一致性。

### 2.2 源语言特性与目标语言差异

论文以 Java→Python 为第一版实现。Java 的方法/构造器重载、内部类、接口、抽象类和循环依赖等特性不能直接映射到 Python；若不先处理，目标程序可能不可运行或改变行为。

### 2.3 翻译结果的逐步验证

只在全部翻译结束后验证会延迟错误发现，也不能有效利用局部反馈。普通测试还会受到测试调用链的耦合影响：某个早期错误可能导致后续方法无法被执行，从而低估其他片段的翻译质量。

> 本文主要研究：如何将真实 Java 仓库分解成可处理的片段，利用 LLM 生成 Python 翻译，并通过增量重组、语言互操作和测试反馈逐步验证翻译结果。

## 3. 核心方法概述

AlphaTrans 包含三个主要阶段：程序变换与分解、类型翻译与目标项目骨架构建、组合式翻译与验证。程序分析负责处理结构和依赖；LLM 直接生成目标语言代码；编译、GraalVM 互操作和测试执行负责核验并产生反馈。

```text
Java 仓库与测试
        ↓
处理 Java 特有结构（重载、构造器等）
        ↓
静态分析、提取类型/依赖/调用图、分解 field/method/test fragments
        ↓
类型映射与 Python 项目 skeleton（字段和方法签名，方法体暂为 pass）
        ↓
按调用图逆拓扑序提示 LLM 翻译 fragment
        ↓
语法检查 → GraalVM 源语言测试下的隔离验证 → 翻译测试执行
        ↓
重组 Python 项目；失败时将编译/运行/测试反馈用于重新提示
        ↓
得到部分或完整的 Python 项目、测试结果和错误报告
```

### 3.1 程序变换与分解

AlphaTrans 先对 Java 方法和构造器重载做保持语义目标的重构，使其更适合翻译到 Python。例如，方法重载会增加数字后缀并更新调用点；构造器重载根据独立构造器、`this()` 调用链等模式合并、重命名或转换为工厂方法。论文强调这些源程序变换需要在翻译前完成，并用源测试检查。

之后使用静态分析提取 fragment 的位置、代码、调用者/被调用者、输入输出类型、继承关系、导入和注解等信息，并把这些信息保存到 schema。测试也被拆成按调用点递增的 test fragments，以减少测试调用链对定位的干扰。

### 3.2 类型映射与骨架

AlphaTrans 从源语言 API 文档中检索类型描述，用 RAG（Retrieval-Augmented Generation，检索增强生成）和上下文示例提示 LLM 生成源类型到 Python 类型的映射。随后用 Python 脚本进行语法和运行检查，形成可复用的 universal type mapping。项目 skeleton 包含 Python 类、字段、方法签名和类型注释，方法体暂由 `pass` 占位。

### 3.3 组合式翻译与反馈

AlphaTrans 从调用图移除回边后计算拓扑序，再按逆拓扑序翻译 method fragments；field fragments 先于 method fragments。每次生成后，系统把语法正确的结果插回 skeleton，并依次进行语法、GraalVM 隔离验证和翻译测试执行。失败时根据 coverage 为 fragment 设置重提示预算，向 LLM 提供错误反馈并重试；测试失败时还按可疑度选择 top-k 相关 fragment 重新提示。

### 3.4 LLM 的最终角色与分类

论文中的 LLM 最终直接输出：

1. Java method/field fragment 对应的 Python 源代码；
2. Python 项目中的翻译后测试代码；
3. 类型翻译候选和部分项目结构代码。

因此，LM 的最终编译系统角色是直接生成变换后程序，而非选择 pass、配置或编译器动作，也不是生成可复用的 compiler pass。建议分类为：

- `Primary_Category: TRANSLATOR`
- `Secondary_Category: T3_Translation_CrossLanguage_CrossISA`
- `Role: 直接进行 Java→Python source-to-source translation`
- `Needs_Review: NO`（依据正式正文已确认；若登记时要求拆分“源程序变换”和“LLM 输出”边界，可在字段说明中补充）

## 4. 实验框架与训练流程

### 4.1 不是模型训练论文

本文没有进行新的 LLM 预训练、SFT、PPO、GRPO 或其他参数更新。论文主要采用已有 LLM 的提示式推理、项目分解、增量重组和工具反馈。论文没有定义用于更新 LLM 参数的训练损失或强化学习奖励函数。

### 4.2 运行阶段一：源程序变换与项目分解

输入是 Java 仓库及其测试。系统先处理方法/构造器重载，再抽取 classes、fields、methods、types、调用图和测试调用点，将应用代码和测试代码转换为 fragments，并建立 schema。

### 4.3 运行阶段二：类型翻译与 skeleton 构建

系统从 Java 项目和 API 文档提取类型信息，用 LLM 生成候选 Python 类型；通过脚本进行语法/运行检查。之后构建包含 Python 类、字段和方法签名的可运行 skeleton，处理循环导入、内部类、接口和抽象类等结构。

### 4.4 运行阶段三：LLM 翻译与逐步反馈

提示包括 persona、in-context example、Java 源代码、当前部分 Python skeleton 和翻译指令。论文正文给出的主模型是 DeepSeek-Coder-33b-Instruct，提示 temperature 为 0；另用 GPT-4o 做模型选择消融。每个 fragment 的输出先过语法检查，再按条件经过 GraalVM 隔离验证和翻译测试执行；错误反馈触发重新提示，预算耗尽则继续处理下一个 fragment并保留报告。

### 4.5 工具反馈与验证

反馈来自 Python 语法检查、项目 skeleton 编译/运行、GraalVM Java-Python 语言互操作、测试运行错误、断言失败和 coverage 信息。论文使用这些反馈来改进下一次提示，不进行参数级强化学习。

## 5. 奖励函数、损失函数或关键公式

本文不涉及强化学习奖励函数，也没有报告用于微调 LLM 的损失函数。

论文的关键控制量是自适应重提示预算，而不是训练目标：

```text
repromptBudget = getAdaptiveBudget(fragment, min_budget, max_budget)
```

论文设置基础提示的最小/最大预算为 3 和 5；反馈提示的预算为 1。fragment 被多个测试高频覆盖时，预算更接近最大值。该机制表达的是推理阶段的计算资源分配：测试覆盖越充分、潜在影响越大，系统越愿意为该 fragment 进行更多重试。正文没有把它定义为奖励函数，也没有给出可学习的预算公式。

## 6. 实验设置

### 6.1 数据集来源

论文没有使用一个固定的合成训练数据集来训练 AlphaTrans。评测对象来自 GitHub 上的 Java 开源项目，选择流程为：

1. 挖掘：主要语言为 Java、自包含、超过 30 stars，且过去 12 个月有提交；
2. 过滤：调用图边数在 2,000–30,000 之间，并能在 Java 21 上成功构建且测试通过；
3. 缩减：只保留 AlphaTrans 当前支持的 Java 核心 API 和部分第三方库，要求至少保留项目总方法数的 50%。

最终使用 10 个项目，包含应用类和测试类共 836 个 classes、8,575 个 methods、2,719 个 JUnit tests；静态分析产生 17,874 个 fragments，其中表 1 给出的应用 method fragments 合计为 4,654。开发者测试的平均 method coverage 为 56.57%。

论文还使用 EvoSuite 生成补充测试，工具默认每类 120 秒；其测试平均 method coverage 为 66.87%，但这些测试并非 AlphaTrans 原始项目测试，且部分测试没有强断言。

### 6.2 模型与工具

| 类别 | 论文正文明确给出的内容 |
|---|---|
| 主 LLM | DeepSeek-Coder-33b-Instruct |
| 对照 LLM | GPT-4o，用于 RQ5 模型选择消融 |
| 提示 | temperature=0；基础提示重试预算 3–5；反馈提示预算 1 |
| 静态分析 | CodeQL、tree-sitter |
| 语言互操作/隔离验证 | GraalVM 21.0.3 + 7.1，Polyglot API |
| Java 测试 | JUnit 4 和 JUnit 5 |
| Python 测试 | Pytest 8.2.1 |
| 覆盖率 | JaCoCo、Python `coverage` |
| 测试增强 | EvoSuite，默认每类 120 秒 |
| 目标语言 | Python 3.10（提示中明确要求） |
| 源语言 | Java；实验构建要求 Java 21 |
| 格式化 | Black |

论文没有把 GraalVM 隔离执行称为形式化证明；它是基于语言互操作和测试的动态验证。

### 6.3 对比方法

AlphaTrans 的核心实验主要比较自身模块启用/移除后的结果，而不是与单一外部系统做统一主表比较。主要对照包括：

- 去掉程序变换模块的 AlphaTrans；
- 以 GPT-4o 替换 DeepSeek-Coder-33b-Instruct；
- 不做 fragment 级程序分解、直接按文件提示 LLM 的版本；
- 原开发者测试与 EvoSuite 增强测试的验证效果对照。

相关工作中还讨论了此前的 GPT-4 仓库翻译尝试、Syzygy、Oxidizer、SpecTra 等，但这些不是本文实验主表中的完整统一 baseline。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| Syntax Check | 翻译 fragment 是否可解析 | 越大越好 |
| ATR | 自动类型解析成功率 | 越大越好 |
| SV | skeleton 语法与运行验证成功率 | 越大越好 |
| GS/GF/GE | GraalVM 分别成功、断言失败、受限/错误的比例 | GS 越大越好；GF/GE 越小越好 |
| TPR | 翻译测试片段的整体 test pass rate | 越大越好 |
| ATP | 某应用 method fragment 的相关测试全部通过比例 | 越大越好 |
| AMF | application method fragments 数量 | 计数，不是质量指标 |
| Cost | GPT-4o 重复实验的调用成本 | 越小越好，但需结合质量 |

论文区分“runtime behavior validation”和“functional equivalence”：两者都与有限测试/执行有关，不等同于对所有输入的形式化语义等价证明。

## 7. 实验结果与结论

### 7.1 主要结果

在 10 个真实 Java 项目、17,874 个 fragments 上，AlphaTrans 达到：

- 所有 field、application 和 test fragments 的整体语法正确率为 96.40%；
- 4,654 个 application method fragments 的语法正确率为 98.80%；
- 1,797 个不同源类型中，自动类型解析成功率 ATR 为 91.99%；
- skeleton validation 为 100%（表 1 的 SV）；
- 以表 2 的 AMF 统计，GraalVM 直接成功 GS 为 24.50%，加上 GraalVM 无法执行但翻译测试提供部分运行验证的 M1 Some 后，runtime behavior validation 为 27.03%；
- functional equivalence（GS + M1 All）为 25.14%；
- 平均每个项目的集成翻译与验证时间为 34 小时，范围为 3–121 小时。

这里的 27.03% 和 25.14% 是相对于 application method fragments 的验证统计，不是整个项目的全输入语义证明比例。

### 7.2 与传统方法/工具流程的比较

论文的贡献不是提出新的传统编译器优化 pass，而是将静态分析、项目骨架、LLM 翻译和动态验证组合成可扩展的 repository-level pipeline。它把原本一次性“先翻译、后验证”流程改为 fragment 级增量翻译与验证。

在人工修复研究中，作者把 4 个项目的部分翻译、报告和反馈交给 2 名熟悉项目的开发者。四个项目达到全部测试通过分别需要 5.5、11、30 和 34 小时，平均 20.1 小时。该结果说明 AlphaTrans 产出的部分翻译与错误报告可以作为人工修复起点，但不表示 AlphaTrans 自动完成了全部功能等价翻译。

### 7.3 与其他 LLM 配置比较

用 GPT-4o 替换 DeepSeek-Coder-33b-Instruct 后，功能等价比例从 25.14% 提升到 27.95%，但各项目的 ATP 和 TPR 并非都更高。GPT-4o 在 API 翻译和类型转换上更强，但也可能添加不必要的错误处理代码，反而改变程序行为。重复运行 10 个项目的 GPT-4o 总成本为 143.95 美元，平均每项目 14.39 美元。

### 7.4 消融实验

- **去掉程序变换**：GraalVM Success 从 24.50% 降至 4.58%，ATP 从 2.88% 降至 0.81%，TPR 从 9.76% 降至 3.05%；论文将主要原因归于 Python 不支持 Java 风格重载。
- **去掉 fragment 分解**：文件级提示存在上下文超限和较多语法错误；表 6 中 DeepSeek-Coder 版本有 71 个文件超出上下文、152 个语法错误，GraalVM Success 为 8 个文件；GPT-4o 版本有 1 个文件超出上下文、15 个语法错误、12 个 GraalVM Success 文件，但 TPR 均为 0。
- **测试增强**：EvoSuite 将平均 method coverage 从 56.57% 提升到 66.87%，TPR 增益为 5.85 个百分点，ATP 增益为 2.11 个百分点；但测试断言质量可能弱于开发者测试。
- **测试分解**：对于至少包含两个 decomposed fragments 的选定测试，原本会被标记为失败的测试片段中，平均 62.41% 的分解片段可以通过。这说明分解有助于定位长调用链中的翻译错误。

### 7.5 案例分析

论文展示的错误主要来自 Java 与 Python API/语义差异，例如：Java `Calendar.MONTH=0` 与 Python 的月份从 1 开始、Java `null` 与 Python `None` 拼接行为不同、位运算结果写入 Python `bytes` 时需要显式掩码、以及 Java iterator 的 `hasNext()` 不能直接由 Python `next()` 模拟。这些案例说明“可解析”并不等于行为正确。

## 8. 主要创新点

### 8.1 创新点一：仓库级组合式翻译

论文把完整仓库拆成带依赖元数据的 field/method/test fragments，并以逆调用顺序翻译和逐步重组。相较于按函数独立翻译或按文件一次性翻译，该设计针对真实项目的上下文窗口和跨方法依赖问题。表 6 的文件级消融结果支持分解设计的有效性。

### 8.2 创新点二：翻译前结构变换与目标 skeleton

AlphaTrans 不把所有 Java 特性直接交给 LLM，而是先处理重载、构造器和部分结构，再建立具有可编译签名的 Python skeleton。这把语言迁移中的确定性结构工作从 LLM 生成中分离出来，降低了方法名、类型和调用点不一致的风险。

### 8.3 创新点三：GraalVM 隔离验证与测试翻译互补

系统一方面把单个 Python 方法放回 Java 项目，通过 Polyglot API 执行原 Java 测试，实现相对隔离的动态检查；另一方面继续翻译测试并在重组后的 Python 项目中运行。两条验证路径互相补充，尤其针对 GraalVM 不能处理的类型或状态。

### 8.4 创新点四：把测试覆盖用于重提示预算和错误定位

覆盖率不仅用于事后统计，还参与每个 fragment 的重提示预算；测试失败后，系统按可疑度筛选相关 fragment 进行反馈重试。该设计把验证信息接入翻译循环，而非只在最后给出总分。

## 9. 局限性

### 9.1 论文明确承认的局限

- 当前第一版实现主要支持 Java→Python；虽然作者认为组合式思路可迁移到其他语言，但程序变换和静态分析组件仍具有语言特定性。
- GraalVM 隔离验证只能处理有限的内建类型和库类型；引用环、带副作用的哈希方法、复杂对象类型等可能破坏 Java/Python 状态同构或导致无法判定类型。
- 类型映射包含人工核查和补充；论文人工检查了自动映射，并手动处理未解析类型。
- 翻译质量依赖源项目测试的覆盖率和调用链；低覆盖率项目无法得到充分的运行/功能验证。
- API 映射仍不完整，目标语言中可能没有与源语言库相同的 API；作者把更广泛库支持和 LLM 测试生成列为未来工作。
- 评测只覆盖经过筛选和缩减的 10 个 Java 项目及当前支持的 API 集合，外推到其他语言、项目和库时需谨慎。

### 9.2 阅读后的潜在局限

- 25.14% 的 functional equivalence 是基于已有测试的有限执行结果，不应解释为所有输入上的等价证明。
- 部分流程包含人工类型映射和人工后修复，因此“端到端自动翻译”的边界需要在复现实验时明确区分。
- 反复调用大模型、GraalVM 互操作和长时间测试使全仓库翻译成本较高；论文给出的 34 小时平均时间显示其更像离线迁移流水线，而不是低延迟编译器后端。
- 论文主要针对源语言迁移，不涉及 LLVM IR、机器汇编、RISC-V 指令选择或跨 ISA 优化，因此不能直接推导其对后端编译优化的效果。

## 10. 阅读后的研究方向反思

AlphaTrans 最适合作为“Translator 角色的仓库级翻译/验证 baseline 和工具模块”，而不是 RISC-V 优化的直接 baseline。值得借鉴的是“程序分解—直接生成—工具验证—错误反馈—增量重组”的闭环，以及把测试覆盖用于资源分配的设计。

不能简单照搬的部分包括：

1. Java→Python 的重载消解和 API 类型映射是语言对特定工程，不等于通用跨 ISA 迁移方法；
2. GraalVM Polyglot 验证依赖语言互操作，不能直接替代 LLVM IR 等价验证或目标 ISA 语义验证；
3. 将平台替换为 RISC-V 并不足以形成新颖性，需要新增 ISA 语义、ABI、向量长度/mask 语义或真实硬件反馈等研究问题；
4. 论文的输出是目标源代码，而不是 pass 序列、机器指令选择策略或可复用 compiler pass。

与 LLVM/RISC-V 研究的合理连接是：把 AlphaTrans 的 fragment schema、调用图逆序、反馈重提示和测试分解思想迁移到“源代码→LLVM IR”或“高层 kernel→RVV intrinsic”的 Translator 流程中；但迁移后必须重新设计语义检查和性能评测，不能沿用 Java/Python 的 GraalVM 证据。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的分层翻译与语义验证

#### 研究问题

能否将 AlphaTrans 的 fragment 分解扩展为 C/C++ kernel→LLVM IR→RVV intrinsic/assembly 的分层翻译，同时保持向量长度、mask、tail policy 和 ABI 语义？

#### 与原论文的区别

原论文是 Java→Python 源到源翻译，主要依赖 GraalVM 与测试；该方向增加 LLVM IR/目标 ISA 中间层和 RVV 语义约束。

#### 可能的创新点

让 LLM 只在局部 fragment 生成候选 IR/RVV 代码，使用 LLVM verifier、编译执行和差分测试联合筛选，并研究跨层反馈如何定位错误。

#### 实验框架

```text
C/C++ kernel
  ↓ fragment/schema 分解
LLM 生成 LLVM IR 或 RVV intrinsic
  ↓ LLVM verifier + 编译
QEMU/真实 RVV 硬件执行与差分测试
  ↓ 正确性/性能反馈
局部重提示与重组
```

#### 可行性

需要 LLVM、clang、RVV 工具链、QEMU 或 RVV 开发板、kernel benchmark 和可执行测试。

#### 主要风险

向量语义、未定义行为、内存对齐和硬件实现差异会使有限测试不足以证明等价；同时 fragment 切分可能破坏跨循环和跨函数优化机会。

### 11.2 覆盖率驱动的编译器反馈预算

#### 研究问题

能否将 AlphaTrans 的 coverage-aware reprompt budget 改造成面向编译器反馈信号的预算分配策略，例如按 LLVM verifier 错误、差分测试覆盖和性能敏感度分配 LLM 调用次数？

#### 与原论文的区别

原论文的预算来自源项目测试覆盖和 fragment 命中率；该方向融合 IR 验证、目标代码运行和性能回归信号。

#### 可能的创新点

定义可解释的错误优先级和预算调度，不把所有失败都交给大模型反复尝试，并比较固定预算、随机预算和反馈自适应预算。

#### 实验框架

```text
候选变换
  ↓ verifier / differential test / runtime profile
错误类型与覆盖特征
  ↓ budget scheduler
选择需要重生成的 fragment
  ↓
最终代码与预算-质量曲线
```

#### 可行性

可从已有 LLM code transformation 数据和 LLVM/RVV 测试工具开始，不需要立即训练新基础模型。

#### 主要风险

预算调度可能过拟合某一批 benchmark；性能信号噪声和测试覆盖不足也可能诱导错误的重试优先级。

### 11.3 跨语言翻译与后端优化的联合错误定位

#### 研究问题

当源到目标翻译同时引入源语言 API 错误和后端性能回归时，能否用调用图、编译器诊断和运行轨迹共同定位最可疑的 fragment？

#### 与原论文的区别

原论文主要用测试失败和调用链定位 Java/Python 翻译错误；该方向将错误定位延伸到 LLVM lowering、指令选择和性能差异。

#### 可能的创新点

建立跨层 fragment provenance，把源 fragment、IR、目标指令和运行指标关联起来，避免只用文本错误消息重提示。

#### 实验框架

```text
源程序 fragment → LLM 翻译 → IR/lowering → 目标代码
       ↘ 调用图/来源映射 ↙       ↘ 编译诊断/运行轨迹
                 统一错误定位
                         ↓
                   局部修复与验证
```

#### 可行性

需要编译器 debug metadata、LLVM pass remarks、差分测试和可重现的运行时 profiling。

#### 主要风险

跨层来源映射并不总是一一对应；局部错误可能由全局优化、别名分析或 ABI 约束触发。

## 12. 与其他已读文献的关系

本轮阶段2只成功完成 AlphaTrans 一篇，不能把阶段1候选的摘要信息当作已读正文证据，因此本节只做有限关系说明：

- 与阶段1候选中已有的 `LEGO-Compiler`、`TRANSAGENT` 等同属 Translator 方向，但它们的正式实验细节尚未在本轮阶段2阅读，不在此处比较数字。
- 与仓库已有的 `Introducing Compiler Semantics...` 相比，AlphaTrans关注真实仓库的组合式 source-to-source 翻译和动态验证；前者的 C→x86 assembly 任务不能与本文的 Java→Python 结果合并。
- 与仓库已有的 `LLM4Decompile` 相比，AlphaTrans是高层源语言之间的正向翻译，LLM4Decompile是低层输入到高层源码的恢复；两者都属于 Translator，但输入/输出层级不同。
- 与 Selector 类工作不同，AlphaTrans 的 LLM 不输出 pass、flag 或调度策略，而是直接输出目标程序代码。
- 与 Generator 类工作不同，AlphaTrans 不以生成可复用的 compiler pass、重写规则或测试工具为最终产物。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 真实 Java 仓库到 Python 的组合式代码翻译与增量验证 |
| 核心问题 | 规模、跨语言特性、依赖和测试验证耦合导致仓库级翻译困难 |
| 输入 | Java 应用仓库、Java 测试、类型/API 信息和调用图 |
| 输出 | Python 项目 skeleton、翻译后 Python fragment/测试、验证结果和错误报告 |
| 核心方法 | 程序变换、fragment/schema 分解、类型映射、逆调用序翻译、GraalVM + 测试反馈 |
| 使用的模型 | DeepSeek-Coder-33b-Instruct；GPT-4o 用于消融 |
| 使用的编译器工具 | CodeQL、tree-sitter、GraalVM、JUnit、Pytest、JaCoCo、coverage、EvoSuite |
| 是否使用强化学习 | 否；论文没有参数级 RL 训练 |
| 是否使用形式化验证 | 否；使用动态语言互操作和测试，不能视为形式化等价证明 |
| 数据集规模 | 10 个项目；836 classes、8,575 methods、2,719 JUnit tests、17,874 fragments |
| 主要指标 | Syntax Check、ATR、SV、GraalVM GS/GF/GE、TPR、ATP、Cost |
| 最重要实验结果 | 整体 fragment 语法正确率 96.40%；AMF 语法正确率 98.80%；functional equivalence 25.14%；平均每项目 34 小时 |
| 核心创新 | 仓库级组合式翻译、目标 skeleton、隔离验证与测试翻译互补、coverage-aware feedback |
| 主要局限 | 当前主要为 Java→Python；验证受测试覆盖和 GraalVM 类型限制；存在人工类型处理和高运行成本 |
| 与 RISC-V 研究的相关性 | 中：可借鉴分解、反馈和验证流水线，但论文不研究 LLVM IR、RISC-V 或后端性能 |
| 最适合作为 | Translator 角色的仓库级翻译/验证 baseline、fragment 编排和反馈模块参考 |

> 这篇论文最值得学习的是把完整仓库翻译拆成可验证的 fragment，并把静态分析、目标 skeleton、语言互操作和测试反馈连接成增量闭环；最主要的局限是验证仍依赖有限测试、当前语言对和部分人工类型处理。如果用于后续 RISC-V 研究，最合理的使用方式是借鉴其分解与反馈架构，再重新设计 LLVM/RVV 语义验证和真实硬件性能评测，而不是简单把目标语言替换成 RISC-V。
