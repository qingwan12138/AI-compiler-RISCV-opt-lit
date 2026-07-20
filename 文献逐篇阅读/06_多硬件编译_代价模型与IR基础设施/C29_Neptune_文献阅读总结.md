# Neptune 文献阅读总结

论文题目：**Neptune: Advanced ML Operator Fusion for Locality and Parallelism on GPUs**

作者：Yifan Zhao、Egan Johnson、Prasanth Chatarasi、Vikram S. Adve、Sasa Misailovic

发表时间：2026

发表平台：PLDI 2026，Proceedings of the ACM on Programming Languages，Article 220

论文链接或编号：DOI `10.1145/3808298`；arXiv `2510.08726`

关键词：张量编译器、算子融合、归约融合、GPU、TVM、Triton、FlashAttention、FlashDecoding

> 本文档用于文献阅读、组会汇报和后续研究分析。论文事实与阅读后的研究思考需要分开描述。

## 1. 研究背景

深度学习框架通常用数学张量算子描述模型，而高性能 GPU kernel 还需要处理内存层次、循环分块、线程布局和 Tensor Core 执行。论文第 1 节指出，基于 tile 的编译器把抽象降低到接近硬件的层次，调度型编译器则用数学程序加变换模板描述优化，但二者都难以自动处理带循环携带依赖的复杂归约融合。

Attention 是典型例子：矩阵乘、逐元素计算、softmax 和第二次矩阵乘之间存在复杂依赖。现有系统往往依赖手写 FlashAttention/FlashDecoding kernel 或特定模板，牺牲了高层表示的可组合性和可维护性。论文因此研究如何把这类高级融合能力纳入标准张量编译流程。

## 2. 论文要解决的问题

### 2.1 复杂归约依赖阻碍算子融合

普通 loop fusion 遇到多个归约循环时会产生过早读取或错误中间值。论文的目标不是忽略依赖，而是允许先进行受控的“朴素融合”，再自动构造代数修正项，使最终归约结果保持正确。

### 2.2 高层调度与低层 tile 优化脱节

调度搜索若同时暴露所有低层变换，搜索空间会很长且难以使用；tile 编译器又把关键高层融合交给程序员。Neptune 试图用 loop-scalar IR 承载高层变换，再翻译到 tile IR，让两类优化在一个流水线中协同。

> 本文主要研究：如何在张量程序编译器中自动实现带复杂归约依赖的高级算子融合，并将其与 GPU 调度、tile 优化和自动调优组合。

## 3. 核心方法概述

Neptune 接收张量表达式和高层 schedule template。模板引导优化器把程序转成 loop-scalar IR，执行普通循环变换以及 rolling update、split-k 两种新型归约融合；随后 loop-to-tile translator 把优化后的循环程序降到 tile IR，tile optimizer 再执行线程 tile、数据布局、Tensor Core 和硬件相关变换；autotuner 通过修改模板和参数寻找更快配置。

```text
张量表达式 + 高层调度模板
        ↓
loop-scalar IR
        ↓
依赖分析 + 代数修正项推导 + rolling update / split-k
        ↓
优化后的循环程序
        ↓
loop-scalar IR → tile IR
        ↓
tile 优化、数据布局、Tensor Core 与硬件映射
        ↓
GPU kernel → 实测 latency → autotuner 调整模板/参数
```

核心修正函数为 `h(t, r, r')`：它把已用旧归约值 `r` 计算的消费者中间结果 `t` 修正为使用新归约值 `r'` 的结果。论文第 4.1 节给出条件 `h(g(r,c),r,r') = g(r',c)`，以及 `h(x f y,r,r') = h(x,r,r') f h(y,r,r')`；当 `g` 对参数 `c` 可逆时，可由逆函数机械构造 `h`。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT 或强化学习，主要采用静态编译变换、符号求解、tile 优化和性能自动调优。

### 4.1 高层编译阶段

输入张量表达式被规范化为 loop-scalar IR。用户提供的模板只描述 tile、privatize、融合等高层操作；模板优化器做依赖重组、模式匹配、修正函数求解和循环重写。rolling update 会缓存生产者归约的前一轮和当前轮结果；split-k 会把归约拆成局部并行归约再合并。

### 4.2 中低层降级阶段

翻译器把 loop-scalar IR 转为 tile IR，并处理维度顺序协调、tile 访问和线程映射。tile optimizer 负责线程级 tile、共享内存/寄存器数据放置、Tensor Core 和 swizzling 等低层变换。

### 4.3 自动调优与正确性

autotuner 修改 schedule template 和优化参数，并通过实际 kernel 性能测量选择配置。论文同时说明，修正推导在实数语义下给出形式化正确性论证；浮点归约不严格满足结合律，因此论文另行做数值精度实验，而不是把实数等价直接表述为所有浮点执行都严格等价。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有训练损失函数。关键公式是修正函数条件：

```text
h(g(r, c), r, r') = g(r', c)
h(x f y, r, r') = h(x, r, r') f h(y, r, r')
h(t, r, r') = g(r', inverse_c(g(r, t)))   （当 g 对 c 可逆）
```

其中 `f` 是归约运算，`g` 生成每个归约项，`r/r'` 是生产者归约的旧值和新值，`c` 是非归约输入，`t` 是消费者当前中间结果。实验目标是 kernel latency；论文报告几何平均 speedup，而不是把 speedup 当作训练奖励。

## 6. 实验设置

### 6.1 数据集来源

论文评测 10 个 attention-based operator，覆盖 Global、Causal、GQA、ALiBi、SoftCap、Window 等变体，并区分 prefill（PF）和 decoding（DC）模式。另有 L2 norm、RMSNorm、Performer 等算子用于扩展测试。论文没有把这些称为机器学习训练数据集，也未报告传统意义上的训练/验证/测试集划分。

### 6.2 模型与工具

Neptune 构建在 Apache TVM 的 schedule tensor compiler 和 Triton 的 tile tensor compiler 之上。实验覆盖 NVIDIA 6000 Ada、A5000、A100 和 AMD MI300 四种 GPU；对比还包含 PyTorch、FlexAttention、Mirage、CUTLASS 及多种 Triton 实现。论文给出部分输入规模为序列长度网格，但当前 PDF 内容不足以确认每一项配置的完整硬件驱动版本。

### 6.3 对比方法

主要 compiler baseline 包括 TVM、Triton、FlexAttention、Mirage 以及 Triton-based FlashAttention 实现；人工优化库 baseline 包括 CUTLASS-based kernels。Mirage 另行报告，因为它在部分输入形状找不到有效 kernel。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| latency | GPU kernel 执行延迟 | 越小越好 |
| speedup | 基线时间与 Neptune 时间之比 | 越大越好 |
| geomean speedup | 跨序列长度或配置的几何平均加速 | 越大越好 |
| numerical accuracy | 浮点变换后的数值误差/准确性 | 需满足误差约束 |

## 7. 实验结果与结论

### 7.1 主要结果

在 10 个 attention operator、4 个 GPU 和 320 个 operator-序列长度-GPU 配置中，Neptune 在 284 个配置上达到不差于其他 compiler 的最低 latency。相对最佳 compiler baseline 的总体几何平均 speedup 为 1.35×；按 GPU 汇总为 6000 Ada 1.15×、A5000 1.14×、A100 1.38×、MI300 1.85×。

### 7.2 与传统方法的比较

Neptune 在 reduction fusion 被 TVM 合法性检查拒绝的场景中减少了中间 kernel 和全局内存传输。对人工优化库，论文在 256 个配置中有 101 个配置优于 CUTLASS-based state-of-the-art kernels；这部分结果不能解释为所有配置都超过人工 kernel。

### 7.3 与其他编译器比较

Neptune 的优势来自跨算子和跨 GPU 的一致性：已有 Triton heuristics 或专门模板在部分算子上很强，但没有一个 baseline 在所有算子和 GPU 上都保持高性能。Neptune 的 attention 输入为 38 行 vanilla attention 加 28 行 schedule，论文以此对比 Tri-Dao Triton 约 650 行 kernel，说明程序表达负担有所降低。

### 7.4 消融实验

论文分别比较 rolling update、split-k、不同 tile/schedule 组合、不同序列长度和 GPU 架构，并测试与人工库及 Mirage 的关系。rolling update 更适合 prefill，split-k 通过 privatization 提供更多并行度，更适合 decoding；不同硬件和 memory-bound 场景会改变收益。

### 7.5 案例分析

softmax 示例展示了朴素融合会读取过早的 `xmax`，而修正项 `exp(xmax_prev - xmax_curr)` 可以把历史 `xsum` 更新到当前尺度。对 Mirage，A100 的部分 global attention 配置中 Neptune 相对 Mirage 可达到 1.25×–6.71×，同时 Mirage 在部分形状无法生成有效 kernel。

## 8. 主要创新点

### 8.1 创新点一：可泛化的代数修正驱动归约融合

现有 FlashAttention/FlashDecoding 多是针对 attention 的专用算法。Neptune 从归约器 `f`、项生成函数 `g` 和修正函数 `h` 抽象出一套编译分析，并自动求解与验证修正函数。实验中的 rolling update 和 split-k 是该范式的两个实例，价值在于把专用优化提升为可组合的编译原语。

### 8.2 创新点二：统一 loop-scalar 与 tile 优化流水线

论文把高层算子融合放在适合表达循环和代数重写的 loop-scalar IR，把硬件细节交给 tile IR 和 tile optimizer，避免让一个 schedule 同时承担所有低层细节。该分层设计由跨 GPU 实验支持，但不是单纯“同时使用 TVM 和 Triton”。

### 8.3 创新点三：将高级融合作为标准 schedule primitive

rolling update 和 split-k 可在模板中与 tile、privatize 等变换组合，因而不必为每个 attention 变体手写完整 kernel。其通用性仍受归约结构、代数可逆性和数值语义约束。

## 9. 局限性

### 论文明确承认的局限

- rolling update 会增加修正计算，并缓存前后两轮结果，使循环携带数据流更复杂、并行化更困难。
- split-k 需要保存局部归约结果，空间开销受 tile 大小控制。
- 浮点归约不严格满足结合律，论文依赖数值实验评估准确性，而不是仅凭实数证明覆盖所有浮点行为。
- autotuning 仍需要真实测量；论文报告单个配置编译/调优耗时可在 1.5–10 分钟范围内，具体取决于 setup。

### 阅读后发现的潜在局限

- 输入仍需要用户编写高层 schedule template，尚未完全自动发现所有高层策略。
- 评测重点是 GPU 张量算子，不能直接推出对 CPU、RVV 或任意非张量程序的效果。
- 论文展示的是静态变换和实测 kernel 性能；不应把它表述成 LLM agent 或强化学习系统。

## 10. 阅读后的研究方向反思

Neptune 最值得借鉴的是“依赖被打破后如何以可检查的代数证据恢复结果”，以及把高层变换和硬件后端分层。其核心贡献是修正函数分析、两种融合原语和 loop-to-tile pipeline，直接照搬到 RISC-V 只替换后端不会形成充分创新。对 RISC-V/RVV 方向，它更适合作为高层 tensor fusion/IR 变换 baseline，再研究 RVV 的向量长度无关归约、尾部处理、LMUL 选择和真实硬件代价模型如何改变修正与调度策略。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的可验证归约融合

#### 研究问题

如何把 rolling update 的修正项降低到 RVV，并保证不同 VLEN、VL/VLMAX 和尾部迭代下的语义与数值约束。

#### 与原论文的区别

研究对象从 GPU tile kernel 转为 RVV 向量长度无关后端，重点是后端合法性和跨 VLEN 性能，而不是只移植算子。

#### 可能的创新点

建立 RVV-aware repair lowering、VL 分块策略和向量寄存器压力模型。

#### 实验框架

```text
张量/loop IR → 修正融合 → RVV lowering → Spike/真实 RVV 后端 → 正确性与性能反馈
```

#### 可行性

可基于 MLIR/LLVM RVV 后端、RVV 模拟器和可获得的 RISC-V 向量硬件开展。

#### 主要风险

浮点误差、不同 VLEN 的调度不稳定，以及模拟器时间不能代表真实硬件时间。

### 11.2 修正函数的硬件感知选择

#### 研究问题

在多个代数等价修正函数存在时，如何结合寄存器、缓存和向量化代价选择实现。

#### 与原论文的区别

把“能否构造修正项”扩展为“在硬件约束下选择哪一种修正项”。

#### 可能的创新点

构建修正表达式代价模型并让选择过程显式保留正确性证据。

#### 实验框架

```text
候选修正函数 → 符号合法性过滤 → 硬件代价模型 → 后端生成 → 实测排序
```

#### 可行性

可以复用 Neptune 的 IR 分层和现有编译器 profiling。

#### 主要风险

代价模型跨硬件迁移性弱，且修正项的计算收益可能被内存瓶颈掩盖。

## 12. 与其他已读文献的关系

本批次另一篇 RACE 研究的是 CPU 嵌套循环中的数组冗余消除，Neptune 研究 GPU 张量算子的归约融合；两者都把跨迭代/跨循环的计算复用显式化，但 Neptune 依赖代数修正恢复归约语义，RACE 依赖哈希标识、辅助数组和冲突图选择。Neptune 更适合作为多硬件 tensor compiler 与融合 IR 的方法参考，RACE 更适合作为循环冗余消除和代价/内存权衡的 baseline；二者没有明显的同题重复。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 将复杂归约融合纳入张量编译器 |
| 核心问题 | 依赖阻碍融合，调度与 tile 优化脱节 |
| 输入 | 张量表达式、高层 schedule template |
| 输出 | 跨 GPU 的优化 kernel |
| 核心方法 | 代数修正分析、rolling update、split-k、loop-to-tile |
| 使用的模型 | 无机器学习模型；有 autotuner |
| 使用的编译器工具 | TVM、Triton、Neptune IR、tile optimizer |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 有实数语义下的修正正确性论证；另有数值实验 |
| 数据集规模 | 10 个 attention-based operators，320 个主配置 |
| 主要指标 | latency、geomean speedup、数值准确性 |
| 最重要实验结果 | 相对最佳 compiler baseline 总体 1.35×，284/320 配置不差于其他 compiler |
| 核心创新 | 以可推导修正项实现可组合的高级归约融合 |
| 主要局限 | 模板仍需人工指导，浮点与硬件适用范围受限 |
| 与 RISC-V 研究的相关性 | 中高：高层 IR/融合思想可迁移，但需重新处理 RVV 后端 |
| 最适合作为 | 多硬件 tensor compiler 方法参考与 GPU baseline |

这篇论文最值得学习的是把“先融合、再用代数证据修正”做成编译器原语；最主要的局限是模板和硬件范围仍有限。如果用于后续研究，合理方式是围绕 RVV 的向量长度无关、后端代价和可审计正确性提出新问题，而不是简单替换 GPU 为 RISC-V。
