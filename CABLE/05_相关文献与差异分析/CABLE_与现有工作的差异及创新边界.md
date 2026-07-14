# CABLE 与现有工作的差异及创新边界

## 1. 文档目的

本文件用于回答两个问题：

1. CABLE 周围哪些技术已经被现有研究覆盖？
2. CABLE 能够合理提出的候选创新主张是什么？

本文依据原 EPAS 项目中的 44 篇逐篇阅读笔记，并补充近期公开论文。这里只做研究定位，不等同于完整系统综述。CABLE 的三个创新仍需进一步系统查新，因此不声称首次。

## 2. 相关工作分组

### 2.1 强化学习与编译 Pass 调优

[Compiler-R1](https://arxiv.org/abs/2506.15701) 将 LLM Agent、工具交互、监督微调和强化学习用于 LLVM Pass 序列调优，说明 LLM 可以在编译环境反馈下学习优化策略。

[CompilerGym](https://arxiv.org/abs/2109.08267) 提供标准化编译优化强化学习环境，使 Pass 排序、状态表示和奖励设计能够进行统一实验。

因此，CABLE 不能把以下内容写成独立创新：

- LLM 生成 Pass 序列；
- 编译器工具调用；
- 使用强化学习优化编译策略；
- 根据编译结果更新策略。

CABLE 的不同问题是：多架构真实效应能否形成带适用边界的知识，以及反例如何更新该边界。

### 2.2 多智能体与运行时反馈编译优化

[AutoPass](https://arxiv.org/abs/2606.20373) 使用多智能体、编译器证据和运行时反馈进行性能调优。

[Agentic Code Optimization via Compiler-LLM Cooperation](https://arxiv.org/abs/2604.04238) 将多个抽象层的优化 Agent、编译器工具、测试生成和指导 Agent 结合起来。

因此，CABLE 不能把以下内容写成核心创新：

- IR Agent 加 Backend Agent；
- 多 Agent 协作；
- 编译器反馈加真实性能反馈；
- 根据失败原因重新生成候选。

CABLE 需要额外证明：失败被持久化为知识反例，改变了适用边界，并降低了后续相似错误。

### 2.3 优化意图与 IR 变换

[IntOpt](https://arxiv.org/abs/2602.18511) 显式分离高层优化意图、编译器分析支持的意图细化和低层变换实现。

因此，CABLE 不应声称：

- 首次使用 Optimization Intent；
- 首次把意图和 Pass 实现分离；
- 首次让编译器分析帮助 LLM 优化 IR。

CABLE 中的预期效应与 IntOpt 的优化意图存在联系，但用途不同：预期效应被用于跨架构真实性能证据对齐、门控和知识边界更新，而不只是指导一次 IR 变换。

### 2.4 多硬件代码生成与自动调优

[TVM](https://www.usenix.org/conference/osdi18/presentation/chen) 已经支持面向多种硬件后端的端到端优化、代码生成和设备测量。

[Ansor](https://www.usenix.org/conference/osdi20/presentation/zheng) 使用大规模搜索空间、进化搜索和学习型代价模型生成高性能张量程序。

[TenSet](https://openreview.net/forum?id=aIfp8kLuvc9) 提供多个硬件平台上的大规模张量程序性能记录，并系统研究代价模型训练和迁移。

因此，CABLE 不能把以下内容写成创新：

- 在多个硬件平台上自动调优；
- 使用远程设备运行候选；
- 使用学习模型减少测量次数；
- 建立多平台性能数据集。

CABLE 的研究对象更接近一般 LLVM 编译知识，而非只针对张量调度候选；其主张必须落在知识适用边界和反例演化上。

### 2.5 跨硬件性能建模和迁移

[LLMTuner](https://openreview.net/forum?id=FCFM3Yxtsm) 研究使用 LLM 进行跨硬件张量程序性能建模，并报告未见硬件上的性能估计能力。

[COGNATE](https://openreview.net/forum?id=EV0itGFjmm) 利用一般硬件数据和少量目标加速器数据训练稀疏张量程序代价模型。

相关工作已经覆盖：

- 共享模型与平台特定参数；
- 跨设备性能预测；
- 少样本目标平台微调；
- 新硬件快速适应；
- 主动选择部分测量样本。

因此，CABLE 已经主动放弃“未见平台快速适应”作为当前主创新，也不使用性能世界模型。CABLE 可以使用候选排序器，但排序器不能替代真实效应证据。

### 2.6 平台提示与高性能代码生成

[QiMeng-GEMM](https://ojs.aaai.org/index.php/AAAI/article/view/34461) 使用针对 GEMM 优化的 meta-prompts、平台相关信息和搜索过程，在包括 RISC-V 在内的平台上生成高性能代码。

这意味着“通用优化描述加平台提示”“LLM 根据平台生成不同代码”和“RISC-V 实机搜索”都不能单独构成 CABLE 的创新。

CABLE 的区别在于：通用知识必须带预期效应和证据边界；平台失败不只触发新候选，还会修改这条知识的跨架构适用范围。

### 2.7 RISC-V 向量化和跨 ISA 代码翻译

[IntrinTrans](https://arxiv.org/abs/2510.10119) 使用多智能体、编译测试反馈和活跃性分析，将其他架构的 intrinsic 代码翻译并优化为 RISC-V Vector intrinsic。

[VecIntrinBench](https://arxiv.org/abs/2511.18867) 提供面向 RISC-V Vector 的跨架构 intrinsic 迁移基准和功能、性能测试。

[LLVM RISC-V Vector Extension 文档](https://llvm.org/docs/RISCV/RISCVVectorExtension.html) 说明了 LLVM 中 RVV 类型、伪指令、`VSETVLI` 插入和相关 lowering 机制。

[RISC-V Vector C Intrinsics Specification](https://docs.riscv.org/reference/vector-c-intrinsics/v1.0/rvv-intrinsic-spec.html) 定义了 C 语言层面使用 RVV 的接口。

因此，CABLE 不能声称：

- 首次用 LLM 翻译到 RVV；
- 首次结合编译测试反馈优化 intrinsic；
- 首次比较 x86、ARM 和 RISC-V 向量代码；
- 首次进行 RVV 性能验证。

代码翻译可以成为 CABLE 后续应用：将一条翻译知识也表示为条件、动作、预期效应、边界和证据，但不进入第一阶段主实验。

## 3. 对比矩阵

| 工作方向 | 已覆盖能力 | 与 CABLE 重叠 | CABLE 尚需回答的问题 |
|---|---|---|---|
| Compiler-R1 | LLM、RL、Pass 调优、工具反馈 | IR 优化候选 | 候选能否形成带跨架构边界的知识 |
| AutoPass | 多智能体、编译器证据、运行时反馈 | 真实反馈与诊断 | 失败是否持久更新知识边界并降低重复错误 |
| Agentic Code Optimization | 多抽象层 Agent 协作 | 跨层优化 | 跨层效应如何用于知识分类和边界演化 |
| IntOpt | 意图形成、细化与实现 | 显式优化目标 | 预期效应如何在不同架构上验证并形成反例 |
| TVM/Ansor | 多硬件代码生成、搜索、代价模型 | 多平台真实测量 | 一般 LLVM 优化知识在哪里可以跨架构复用 |
| TenSet | 多硬件性能数据和代价模型 | 多平台效应数据 | 从数据中显式提取知识边界而非只训练排序器 |
| LLMTuner/COGNATE | 跨硬件性能模型、迁移与适应 | 平台差异 | 不依赖世界模型时如何用真实反例维护知识 |
| QiMeng-GEMM | 通用优化技术、平台提示、目标平台搜索 | 通用与平台特化 | 平台失败如何改变通用知识的适用范围 |
| IntrinTrans | LLM、多智能体、RVV 翻译和优化 | RISC-V 与代码翻译 | 翻译知识的跨架构效应边界如何表示和更新 |

## 4. CABLE 的候选创新边界

### 候选创新一

不是“共享编译知识”，而是：

> 使用多架构真实效应显式分解知识，并为每项知识维护程序条件、预期效应、适用边界和正反证据。

### 候选创新二

不是“使用运行时反馈”，而是：

> 将目标平台上的效应冲突转化为可持久化反例，通过 `KEEP/REFINE/REPLACE` 更新知识边界，并验证重复错误率是否下降。

### 候选创新三

不是“为每个平台独立调优”，而是：

> 根据通用知识的具体效应失配选择有限架构修正族，并在相同真实测量预算下验证其搜索效率。

## 5. 不能单独声称的创新

以下内容可以是系统组件或实验条件，但不能单独写成 CABLE 的创新点：

- LLM 与编译器结合；
- 强化学习编译调优；
- 双智能体或多智能体；
- IR Agent 与 Backend Agent；
- 真实性能反馈；
- 多平台测试；
- RISC-V 实验；
- Adapter 和平台嵌入；
- 共享模型加平台残差；
- 候选排序器；
- 少样本微调；
- 未见平台迁移；
- Optimization Intent；
- 编译测试闭环。

## 6. 需要进一步查新的关键词

正式投稿前，应围绕以下组合进行系统检索：

```text
compiler optimization knowledge boundary
cross-architecture optimization applicability
negative transfer compiler autotuning
counterexample-guided compiler optimization
effect-conditioned compiler knowledge
cross-platform optimization rule learning
runtime evidence knowledge refinement compiler
architecture-specific compiler tuning diagnostics
```

还应检索以下相邻领域：

- counterexample-guided inductive synthesis；
- invariant and precondition learning；
- transfer learning negative transfer detection；
- continual rule refinement；
- empirical performance portability；
- feedback-directed optimization repositories。

即使其他领域存在相似思想，也需要判断将其用于一般 LLVM 跨架构编译知识是否已有直接工作。

## 7. 审稿人可能的质疑

### 质疑一：只是规则库加平台调优

回应所需证据：边界由数据学习而非人工指定；反例更新显著降低留出程序中的重复错误。

### 质疑二：多维效应只是更多特征

回应所需证据：多维效应相对只用运行时间显著提高冲突识别或门控质量，并有对应消融。

### 质疑三：架构模块只是缩小搜索空间

回应所需证据：失配维度与有效动作存在稳定关联，在相同动作空间上限和预算下优于随机搜索。

### 质疑四：知识边界只是记住平台 ID

回应所需证据：边界同时包含程序条件，并在同平台留出程序和不同微架构上保持解释力。

### 质疑五：完整方法不如独立调优

回应所需证据：报告相同预算下性能、负迁移和知识复用收益；若独立调优稳定更好，应如实降低整体主张。

## 8. 当前最稳妥的贡献表述

> CABLE 研究编译优化知识的跨架构适用边界。它首先根据多个硬件平台上的真实跨层效应，将优化知识表示并分解为通用稳定、架构敏感、架构冲突和架构专用类型；随后利用目标平台反例执行效应门控和边界更新；最后根据具体效应失配进行有限的架构专用调优。该框架旨在保留可复用知识，同时减少无条件共享导致的负迁移。

## 9. 学术声明边界

- 当前三个创新点均为候选主张；
- 本文件不是 PRISMA 式系统综述；
- 部分 2026 年工作仍是预印本，应在正式写作时标明发表状态；
- 正式论文不得使用未经完整检索支持的优先性措辞；
- 如果后续发现直接重叠工作，应调整算法或降低主张，而不是忽略相关文献。
