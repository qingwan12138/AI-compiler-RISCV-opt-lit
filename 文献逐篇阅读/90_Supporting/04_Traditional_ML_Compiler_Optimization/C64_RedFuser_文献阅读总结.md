# RedFuser 文献阅读总结

论文题目：**RedFuser: An Automatic Operator Fusion Framework for Cascaded Reductions on AI Accelerators**

作者：Xinsheng Tang, Yangcheng Li, Nan Wang, Zhiyi Shu, Xingyu Ling, Junna Xing, Peng Zhou, Qiang Liu

发表时间：2026；发表平台：ASPLOS 2026（官方 program；论文正文为作者 arXiv 版本，22 页）

论文链接或编号：arXiv:2603.10026；正式会议：ASPLOS 2026

关键词：operator fusion、cascaded reduction、TVM、TIR、GPU kernel、incremental computation

## 1. 研究背景

深度学习模型中常出现具有跨循环依赖的级联归约，例如 attention 中的 safe softmax 与 GEMM。现有 AI 编译器通常分别生成 kernel，导致重复加载和中间结果写回；手工融合策略覆盖面有限（摘要、第 1–2 节）。

## 2. 论文要解决的问题

### 2.1 级联归约的可融合性

需要从 TIR/计算结构中识别可分解、满足代数结构且具有依赖关系的归约链。

### 2.2 融合后的高效生成

融合不能只减少 kernel 数量，还要处理共享内存、寄存器、线程块与依赖归约的增量更新。

> 本文主要研究：如何自动识别并生成适合 AI 加速器的级联归约融合 kernel。

## 3. 核心方法概述

RedFuser 先用符号推导分析归约表达式，再将融合结果转成 scalar-level 和 tile-level 表示，最后生成硬件感知 kernel（第 3–4 节）。

```text
PyTorch/主流框架模型
        ↓ TVM frontend
TIR AST
        ↓ visitor + symbolic deduction
级联归约表达式与融合条件
        ↓ ACRF + incremental computation
融合 scalar/tile IR
        ↓ hardware-aware lowering
优化 kernel + runtime
```

本文不使用 LLM、SFT 或强化学习。

## 4. 实验框架与训练流程

本文不涉及模型训练。TVM frontend 将模型降低到 TIR；ACRF（Automatic Cascaded Reductions Fusion）检查分解条件，生成单段或多段融合策略，并通过 tile-level lowering 生成目标 kernel。实验在 GPU 与多个平台上比较融合层级、增量/非增量计算及 ML/非 ML workload（第 5 节和附录）。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数。核心条件包括：归约函数可写成 `F_i(x,d_i)=G_i(x) ⊗_i H_i(d_i)`，且 `⊗_i` 形成交换幺半群；增量形式通过保存前次部分结果、修正当前结果和继续归约来减少重复计算（第 3.2 节）。

## 6. 实验设置

### 6.1 数据集来源

实验包含 ML workload 和非 ML workload；正文示例涉及 safe softmax、GEMM、FlashAttention、FlashDecoding 等级联归约。表 2、表 3 给出配置与输入规模；当前文本提取不足以可靠重建全部表格数值，不能补写统一数据集规模。

### 6.2 模型与工具

基于 TVM compiler stack 和 TIR；实验环境提到 Ubuntu 22.04 与 CUDA 12.8，并使用 GPU 后端。RedFuser 是传统编译器框架，不是 LLM 系统。

### 6.3 对比方法

比较未融合实现、不同融合层级、非增量与增量计算，以及现有 AI 编译器和手写优化 kernel（摘要、图 5–7）。

### 6.4 评价指标

| 指标 | 含义 |
|---|---|
| Normalized performance | 相对基线的归一化执行性能 |
| Speedup | 融合实现相对现有编译器/基线的加速比 |
| Fusion level | 选择部分模块或全模型融合的效果 |
| Kernel/runtime behavior | 线程块、共享内存与中间结果访问代价 |

## 7. 实验结果与结论

### 7.1 主要结果

摘要报告 RedFuser 在多类 workload 上相对先进 AI 编译器达到约 2×–5× speedup，并可接近高度优化的手写 kernel；该范围是论文实验 workload 的结果，不是所有模型的保证。

### 7.2 传统方法比较

融合后输入数据可只加载一次，并减少前序归约结果的中间访存。图 5、6 显示融合层级与增量计算都会影响性能。

### 7.3 消融实验

论文比较 single-segment/multi-segment、不同融合层级及 incremental/non-incremental 方案；增量形式用于缓解归约长度与片上容量约束。

### 7.4 案例分析

FlashAttention 和 FlashDecoding 被用作复杂级联归约案例；算法通过数据依赖决定哪些步骤需要保存旧结果或进行修正。

## 8. 主要创新点

### 8.1 级联归约的统一融合方法

用可分解性、交换幺半群和依赖结构把若干归约模式转成可自动处理的数学条件。

### 8.2 增量计算形式

通过逐步更新部分结果避免完整重复归约，直接针对片上存储和重复访存问题。

### 8.3 从符号表达式到硬件感知 kernel

RedFuser 将分析、IR 构造和 lowering 串成轻量框架，减少为每种模式手工实现融合规则的需求。

## 9. 局限性

### 9.1 论文明确承认或体现的局限

方法依赖归约操作的代数假设和当前 AI 编程模型；跨 block 通信受现有 GPU 编程模型限制，某些模式仍需多 kernel launch 或特定硬件支持（第 3 节）。

### 9.2 阅读后发现的潜在局限

可融合模式主要集中于常见 sum/product/max/min 归约；对不满足交换幺半群、复杂控制流或数值稳定性约束的算子，适用性需要额外证明。论文没有给出跨 RISC-V 加速器的实测证据。

## 10. 阅读后的研究方向反思

RedFuser 适合作为传统 ML 编译优化 baseline 或融合模块。若迁移到 RISC-V，仅替换 GPU 后端创新性有限；更有价值的是将 RVV/自定义矩阵扩展的寄存器与 scratchpad 约束纳入融合可行性和代价模型，并验证浮点重排的数值误差边界。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RVV 的归约融合代价模型

#### 研究问题
如何联合向量长度、尾部处理、寄存器压力和 scratchpad 容量选择融合粒度。

#### 与原论文的区别
目标是 RVV 可移植性能模型，不是直接复刻 GPU tile lowering。

#### 可能的创新点
运行时 VL 分派、误差约束和硬件计数器校准。

#### 实验框架
TIR/MLIR → cascaded-reduction analysis → RVV tile plan → LLVM/RISC-V → hardware counters。

#### 可行性
需要 TVM 或 MLIR、LLVM RVV 和真实 RISC-V 板卡/模拟器。

#### 主要风险
RVV 硬件可用性、内存层次差异和浮点重排误差。

## 12. 与其他已读文献的关系

与 C48 Scorch 都研究 ML 编译器性能，但 C48 关注稀疏自动调度，RedFuser 关注级联归约融合。与 C29 Neptune 都涉及算子融合和 GPU，但 RedFuser 的核心是可证明的归约代数与增量计算。与 C46 Trinity 的 tile-level 搜索不同，RedFuser 主要采用符号推导和规则化 lowering，适合作为融合 baseline/工具模块。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | AI 加速器上的级联归约自动融合 |
| 核心问题 | 重复访存、跨循环依赖、片上容量约束 |
| 输入 | PyTorch/TVM TIR |
| 输出 | 融合的 tile-level kernel |
| 核心方法 | ACRF、代数条件、增量计算、硬件感知 lowering |
| 使用的模型 | 无 LLM/学习模型作为核心方法 |
| 使用的编译器工具 | TVM、TIR、CUDA |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 使用代数条件；不是完整形式化证明系统 |
| 主要指标 | normalized performance、speedup |
| 最重要实验结果 | 相对先进 AI 编译器约 2×–5×（摘要报告） |
| 核心创新 | 级联归约融合与增量计算的统一框架 |
| 主要局限 | 依赖归约代数和硬件模型 |
| 与 RISC-V 研究的相关性 | 中；可迁移到 RVV，但论文未实测 |
| 最适合作为 | 传统 ML 编译优化 baseline/融合模块 |

> 这篇论文最值得学习的是把级联归约的数学结构直接接入编译器 lowering；最主要的局限是适用算子和硬件模型受限；后续应研究 RVV 代价模型与数值正确性，而不是只替换 GPU 后端。
