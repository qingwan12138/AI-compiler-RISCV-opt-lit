## 1. 研究背景

MaxKernel 关注 TPU 上高性能自定义 kernel 的生成与优化。论文指出，标准编译器流水线并不总能暴露加速器最后一段性能空间；工程师通常需要手工处理 HBM 与片上 VMEM/SRAM 之间的数据移动、DMA 流水、内存布局和多维 tiling。JAX/Pallas 等接口的约束严格、编译器错误信息底层且不透明，单次 zero-shot/few-shot 生成很难同时满足可编译性、数值正确性和硬件性能。

论文把 LLM 放在编译器反馈闭环中：模型负责提出算法计划和 Pallas kernel，编译器、测试执行器、autotuning 和 XProf 提供可操作证据。研究对象不是 LLVM pass，而是与目标加速器编译流程直接衔接的可执行 kernel 工件，因此属于本分区要求的编译器工具/程序生成方向。

## 2. 论文要解决的问题

论文要解决的是：如何让 LLM 在 TPU 低层 kernel 工程中持续生成、调试和优化候选，并避免“代码看起来合理但编译失败、数值不等价、VMEM 溢出或性能不升”的问题。具体困难包括：

- 仅靠静态生成缺少目标 TPU 的布局、内存和 lowering 反馈；
- 一个长序列 agent 容易陷入局部最优，或在多轮上下文中丢失有效状态；
- 正确性验证可能被生成器通过修改测试预言机而“奖励投机”，所以验证条件必须冻结；
- 高性能优化既需要长期迭代修复，也需要并行扩展候选并在性能差的路径上及时剪枝。

论文的核心问题可概括为：能否用专门化多 agent、冻结测试、实时编译/性能反馈以及图搜索，把 LLM 的 kernel 生成从一次性代码补全变为可恢复、可度量的硬件优化过程。

## 3. 核心方法/系统设计

MaxKernel 是模块化多 agent 框架，包含 Planning Agent、Implementation Agent、Testing and Verification Agents、Execution Agent、Autotuning Agent 和 Profiling Agent。Planning Agent 根据参考实现、硬件规格和既有证据提出高层算法/数据布局策略；Implementation Agent 将计划转成 Pallas 代码；编译修复环读取编译器错误并反复修复；测试 agent 生成测试套件，执行 agent 在 TPU 上核对数值；autotuning 搜索 block size、tile dimension 等参数；profiling agent 用 XProf 提取延迟、带宽利用率和计算密度。

系统有三种角色编排：

1. HITL 保留人在关键阶段的路由和审查权，采用 “One Agent, Then Wait”，用户可查看计划和草稿后决定下一 agent。
2. Auto 把计划、实现、编译、测试、autotuning、profiling 串成闭环 hill-climbing；失败会携带错误上下文回到计划阶段。
3. Graph-Based Autonomous Search 把每个 kernel 状态建成搜索图节点，节点保存代码、优化计划、正确性和性能指标；Parallel Search 并行扩展多条轨迹，Beam Search 保留 top-k 前沿并剪枝。

准备阶段先依据参考代码合成测试套件并冻结。Auto 维护成功状态快照，在结束时回滚到延迟最低的有效 kernel。编排器启动时为工件指定绝对路径，以降低多 agent 文件状态损坏风险。

## 4. 数据流与整体流程

整体数据流为：参考 JAX/Pallas kernel → Test Synthesis Agent 生成并冻结测试 → Planning Agent 读取参考实现、TPU 硬件上下文和 RAG 知识 → Implementation Agent 生成 Pallas 候选 → 目标编译器检查 → 编译失败则把错误送回修复/计划阶段 → 编译通过后执行冻结测试 → autotuning 搜索配置 → XProf 采集设备级延迟和瓶颈 → 把性能证据反馈给下一轮计划 → 保存有效状态或加入 SearchGraph → 终止后返回最优有效节点。

知识库采用 RAG 动态取回文档、内存布局指南和性能手册，覆盖 Pallas、Mosaic 和 XLA；论文明确排除手工调优 kernel 代码，以测试 agent 是否能泛化发现 TPU 优化。Graph Search 中，每个 worker 独立启动 Auto agent，完成新策略的生成、编译、测试和 profiling，再把新节点返回全局图。Beam 配置为宽度 3、最大深度 3、每节点 2 个分支，并把节点内循环限制为 2 次；Parallel 则从同一基线并发启动 5 条各含 5 次迭代的轨迹。

## 5. 训练/搜索/优化目标

论文没有报告对 MaxKernel 进行专门的监督微调或强化学习训练；实验中 LLM 查询和 agent 交互使用 Gemini 3.1 Pro。主要目标是产生“可编译、数值等价且更快”的 kernel，而不是优化语言模型本身。

搜索层面的目标是最小化有效 kernel 的设备执行延迟，并以相对标准 XLA 编译器的 speedup 评价；性能回归在几何平均汇总时按 1.0x 封底。正确性是硬约束，候选必须在冻结测试套件下通过 `jnp.allclose`。Auto 是局部 hill-climbing；Parallel 用多条独立轨迹扩大探索并选择最快正确结果；Beam 通过 top-k 节点选择控制搜索预算，试图在探索广度和长程修复之间折中。

## 6. 实验设置

## 6.1 数据集

主实验使用 JaxBench，共 50 个 TPU kernel 任务：17 个来自 LLM 架构的常用算子，33 个由 KernelBench 改造的融合算子，覆盖 attention、稠密/稀疏线性代数、复杂 loss 和高融合度算子。另有 8 个存在人工 Pallas kernel 的生产型 workload，用于与人工参考比较；包括 Flash/GQA/MLA/Sparse/Paged/Ragged Paged Attention、GEMM 和 Megablox GMM 等。论文还在 MLA v1、Qwen3-Next Gated DeltaNet、DeepSeek-V4 Sparse Attention、Mamba v2 SSD 和 CSA StreamIndex_topk 等真实架构上做展示。

## 6.2 模型与工具

模型为 Gemini 3.1 Pro。目标硬件为 TPU v6e，代码层主要是 JAX/Pallas，编译/执行流程结合 XLA；XProf 负责真实设备 profiling。测试使用参考 JAX 实现和动态合成的隔离测试环境，通常 `atol=rtol=10^-2`，部分 bf16 任务放宽到最多 `10^-1`，附录表 4 给出逐 workload 容差。

## 6.3 基线

四种生成方式为：Best-of-N zero-shot（参考实现条件下独立采样 N=100，选最快正确样本）、MaxKernel Auto（单轨迹最多 5 次迭代，5 次独立运行取中位数及上下界）、MaxKernel Parallel（5 条并行 Auto 轨迹选最快正确结果）和 MaxKernel Beam（beam width=3、depth=3、每节点 2 分支、每节点 2 次内部迭代）。另用人工编写 Pallas kernel 与 JAX/XLA baseline 做生产 workload 对比。

## 6.4 指标

指标包括编译率、正确率、几何平均 speedup 和 `fast_p`。编译率是成功通过目标硬件编译的候选比例；正确率是编译候选相对未优化 JAX 参考在测试输入上数值等价的比例；几何平均 speedup 相对标准 XLA，回归封底为 1.0x；`fast_p` 是同时正确且 speedup 大于阈值 p 的任务比例。设备计时排除了 host-side JAX dispatch 和编译开销。

## 7. 实验结果与结论

## 7.1 主结果

JaxBench 表 1 的结果为：Best-of-N 编译 10/50、正确 10/50、几何平均 1.08x、fast1=6/50；Auto 为 49/50（独立运行范围 48–50/50）、正确 48/50（46–49/50）、1.39x（1.19–1.42x）、fast1=22/50（18–28/50）；Parallel 为 50/50 编译、50/50 正确、1.58x、fast1=34/50；Beam 为 50/50 编译、50/50 正确、1.49x、fast1=31/50。Parallel 在 p=1.0 和 p=2.0 处的 fast fraction 分别为 68% 和 24%。

## 7.2 与传统编译器/人工系统

表 2 的 8 个生产 kernel 上，人工参考几何平均 speedup 为 2.02x，MaxKernel Parallel 为 2.32x，Beam 为 1.78x。Parallel 在 8 个 workload 中有 7 个优于人工参考；Beam 在 Paged Attention 上达到 6.74x，而人工参考为 2.41x。Ragged Paged Attention 是例外，人工参考 4.65x，Parallel 为 1.42x。论文没有把 MaxKernel 与 GCC、LLVM 或传统 autotuner 做同一 JaxBench 数值表的直接比较；主要比较对象是 XLA、zero-shot 采样和人工 Pallas。

## 7.3 与其他 LLM 方法

论文内部对比的其他 LLM 方式是 Best-of-N zero-shot 与 Gemini 3.1 Pro 驱动的 Auto/Parallel/Beam，而不是多个 LLM 家族。Auto/Parallel/Beam 通过编译器、测试和 profiling 反馈显著提高编译/正确率及 speedup。论文明确说其他 LLM 的消融留作未来工作，因此不能据此宣称 MaxKernel 对所有 LLM 均优越。

## 7.4 消融与敏感性

论文没有提供传统意义上逐组件的完整消融表，也没有报告换用其他 LLM 的消融。它提供了生成策略、轨迹数量、Beam 宽度/深度和每节点迭代预算之间的对比：单轨迹 Auto 容易卡在局部最优但长程修复能力较强；Parallel 以更多独立轨迹换稳定性；Beam 以较浅预算换更广前沿，在需要多步修复的 brittle lowering 场景可能因过早剪枝而受损。

## 7.5 典型案例

MLA Attention 上人工专家代码低于 XLA baseline，而两种图搜索均找到超过 XLA 的实现。Qwen3-Next GDN 的 forward latency 从 17.09 ms 降至 10.47 ms，训练 step 从 84.51 ms 降至 17.99 ms（最高 4.70x）；DeepSeek-V4 Sparse Attention 的 prefill 达 7.85x、decode 达 2.36x；Mamba v2 SSD 达 1.10x，CSA StreamIndex_topk 达 1.66x。框架还修复了 Ragged Paged Attention v3 prefill 的 crash/deadlock：自动加入 ALU clamp 处理左填充输入造成的负 slice size，使 DMA prefetch 稳定执行且性能开销很小。

## 8. 主要创新点

1. 将 kernel 生成拆成计划、实现、编译修复、测试、autotuning 和 profiling 等可路由的专门 agent，形成可审计的工具链。
2. 提出 HITL、Auto、Graph-Based Autonomous Search 三种控制粒度，把人工安全审查、长程迭代和并行/Beam 搜索放在同一框架。
3. 把冻结测试预言机、目标编译器反馈和 XProf 设备证据统一到生成闭环，避免只凭代码文本或 host 端时间评价。
4. 将 kernel 状态持久化为搜索图节点，支持节点回滚、上下文隔离和不同启发式搜索算法替换。
5. 在 50 个 TPU 任务及真实 LLM 架构 kernel 上展示了接近或超过人工参考的性能，说明 LLM 生成可与传统编译/手工调优互补。

## 9. 局限性

- 评测集中在 TPU v6e、JAX/Pallas 和 Gemini 3.1 Pro，跨 TPU 代际、GPU/CPU/RISC-V 后端及其他模型的泛化尚未验证。
- 论文没有给出其他 LLM 的消融、完整组件消融、token/调用成本或 wall-clock agent 成本，因此性能提升的成本收益不完整。
- 正确性主要依赖动态 `allclose` 测试，且部分任务容差达到 0.1；这不是形式化等价证明，可能遗漏测试分布之外的错误。
- Best-of-N 与 Auto/Graph 的迭代预算和并发资源不同，横向比较更接近系统策略对比，不是严格相同预算下的模型能力对比。
- Beam 在需要长程修复的内存布局/lowering 问题上可能过早剪枝；Parallel 选择最快正确样本，也可能放大采样预算。
- 真实架构展示数量有限，作者未提供完整数据、每次运行方差和所有任务的逐例代码，复现实验仍依赖 TPU v6e、XProf 和外部代码仓库。
- 论文属于 2026 年 9 月 arXiv 预印本；当前 PDF 未说明其已被 CGO/ASPLOS 等正式顶会录用，因此这里仅作为直接相关的最新 Generator 候选，不应标成已审稿顶会论文。

## 10. 阅读后的研究方向反思

MaxKernel 最值得迁移的不是 TPU 特定 tiling，而是“生成工件、验证工件、测量工件和搜索状态分离”的系统边界。对于 LLVM/RISC-V，Implementation Agent 可以输出可编译的 pass/rule/MLIR transform 或 RVV kernel，编译器负责 IR 合法性和后端诊断，验证 agent 固定语义证书，profiling agent 再提供真实 VLEN、LMUL、cache/PMU 反馈。

论文也提醒，Generator 和 Selector 的边界取决于最终持久化工件：MaxKernel 主要生成可复用 Pallas kernel，所以应归 Generator；Beam/Parallel 的节点选择是辅助 Selector。若将来只让模型在既有 kernel/pass 之间选路径，则应另行归 Selector，不应把所有 agentic search 都笼统称为 Generator。

## 11. 可进一步尝试的研究方向

1. 将冻结测试扩展为“语义验证 + 硬件盈利证书”双证书：前者检查 RVV/LLVM 变换语义，后者记录不同 VLEN、LMUL 和输入规模上的真实收益及失效条件。
2. 把 SearchGraph 的节点表示统一成源码/IR、编译诊断、测试覆盖、资源占用和 PMU 指标，以训练可解释的跨硬件节点选择器。
3. 研究长程修复与宽度探索的自适应预算分配：根据错误类型、后端资源压力和收益置信度动态决定继续 Auto、分叉 Parallel 还是 Beam 剪枝。
4. 对动态测试的容差和覆盖度做校准，结合 Alive2/SMT、差分执行和随机输入生成，量化 `allclose` 假阳性与假阴性。
5. 在多后端编译器中复用知识库，但让硬件文档检索与真实 profiling 证据分层，检验“文档先验 + 设备事实”能否避免把 TPU 经验错误迁移到 RISC-V。

## 12. 与其他已读文献的关系

MaxKernel 与已排除的 Agentic Auto-Scheduling/LOOPRAG 在闭环反馈和搜索思想上相近，但它的输出是可复用 TPU/Pallas kernel，属于 Generator；LOOPRAG 直接改写 SCoP C 源程序，更接近 Translator；Auto-Scheduling 选择循环 schedule，更接近 Selector。与 PassNet 的关系是都强调生成可嵌入编译流程的结构化工件，但 PassNet 面向张量图 compiler pass 和规模化轨迹数据，MaxKernel 面向 TPU 低层 kernel、多 agent 调试和设备 profiling。

与 AutoPass、REASONING COMPILER 等 pass/schedule 选择器相比，MaxKernel 不主要输出 LLVM pass pipeline 或 MCTS action，而是输出 Pallas 实现和配置；与 AccelOpt、VQ-LLM 等 accelerator/kernel 工作相比，MaxKernel 的直接核心是 LLM agent 的生成—测试—编译—profiling 搜索闭环，不是单纯硬件数据通路或量化 kernel 设计。与 RAG-based 编译优化工作相同之处是使用文档检索，差异在于 MaxKernel 明确排除手工 kernel 代码并将知识检索用于多个 agent 阶段。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文 | MaxKernel: Agentic Kernel Generation for TPUs |
| 时间/来源 | 2026-09-03；arXiv:2609.04523v1；14 页；预印本，论文未说明已被顶会正式录用 |
| 角色建议 | Primary: GENERATOR；Secondary: SELECTOR |
| 输入 | JAX/Pallas 参考 kernel、硬件/框架文档、历史计划和反馈 |
| 输出 | 编译通过、测试正确、经 autotuning/profiling 选择的 Pallas kernel |
| 核心闭环 | 计划 → 实现 → 编译修复 → 冻结测试 → autotuning → XProf → 下一轮计划 |
| 搜索 | Auto hill-climbing、5 路 Parallel、Beam width=3/depth=3 |
| 评测 | TPU v6e；JaxBench 50 任务；8 个人工参考 kernel；Gemini 3.1 Pro |
| 主要结果 | Parallel：50/50 编译、50/50 正确、1.58x 几何平均、fast1=34/50 |
| 生产 kernel | Parallel 几何平均 2.32x，人工参考 2.02x；8 个中 7 个优于人工参考 |
| 关键证据 | XProf 设备计时排除 host dispatch/编译开销；测试套件在迭代前冻结 |
| 主要风险 | 单 TPU/单 LLM、动态测试非形式证明、缺少成本和组件消融 |
| 对本课题价值 | 提供 Generator—验证—profiling—搜索图的可迁移系统模板，适合后续接入 LLVM/RVV |
