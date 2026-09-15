# Pruner 文献阅读总结

论文题目：**Pruner: A Draft-then-Verify Exploration Mechanism to Accelerate Tensor Program Tuning**

作者：Liang Qiao、Jun Shi、Xiaoyu Hao、Xi Fang、Sen Zhang、Minfan Zhao、Ziqi Zhu、Junshi Chen、Hong An、Xulong Tang、Bing Li、Honghui Yuan、Xinyang Wang

发表时间：2025

发表平台：ASPLOS 2025，Volume 2，pp. 949–965

论文链接或编号：[ASPLOS 2025 官方议程](https://www.asplos-conference.org/asplos2025/program.html)；[DOI: 10.1145/3676641.3716269](https://doi.org/10.1145/3676641.3716269)；[arXiv:2402.02361v3](https://arxiv.org/abs/2402.02361)

关键词：代码生成、编译器优化、张量程序调优、TVM、代价模型、跨硬件迁移

> 本文档基于 17 页论文 PDF 全文整理。论文事实与阅读后的分析分开描述；文中“第 X 节”“表 X”“图 X”均指论文正文。

## 1. 研究背景

本文属于深度学习编译器和自动张量程序调优。DNN 通常先表示为计算图，再将算子映射到面向特定加速器的 kernel；手工为每种硬件和算子调优 kernel 成本高，也限制了新算子和定制 DLA 的开发。搜索型深度学习编译器（DLC）把 tile size、unroll factor 等调度变量组成搜索空间，用搜索算法和硬件测量寻找高性能张量程序（第 1、2.1 节）。

现有流程依赖学习型代价模型估计候选程序性能，以避免对全部候选做设备测量，但代价模型本身需要特征提取和推理，搜索空间又可能达到数十亿规模。论文还指出，手工特征工程复杂；跨硬件预训练模型在新平台上在线适配困难。引入轻量草稿模型、学习型验证模型和在线迁移策略，是为了减少搜索开销并保持候选质量。

## 2. 论文要解决的问题

论文集中解决三个问题（第 1、2.3 节）：

1. 每轮搜索都对大量候选执行复杂代价模型推理，探索阶段开销大。
2. 代价模型的特征工程依赖专家设计，部分基于 schedule primitive 的表示在小数据训练时区分度不足。
3. 在一个硬件平台训练的模型不能直接适应另一个平台；早期在线样本少且有偏，直接微调可能破坏模型训练。

论文目标不是重新定义张量程序语言，而是在搜索型编译器中用“先草拟、后验证”的顺序减少学习模型调用，并让预训练模型更平稳地适应目标硬件。

## 3. 核心方法概述

论文提出 Pruner 和 MoA-Pruner。

- Pruner 使用 **Draft-then-Verify**：先用 Latent Schedule Explorer（LSE）和 Symbol-based Analyzer（SA）基于硬件感知符号快速筛出小规模候选，再用 Pattern-aware Cost Model（PaCM）对这些候选进行学习型性能预测和选择。
- MoA-Pruner 在在线调优时增加 Momentum online Adaptation（MoA）。它将跨平台预训练模型作为 Siamese model 的参数起点，用目标平台在线数据更新目标模型，再以动量更新预训练模型侧参数。

系统集成在 TVM/Ansor，并扩展到 MetaSchedule 的 TensorCore 场景。图 2 和算法 1 给出的数据流是：DNN → 图分区与子图 → 调度器选择待调优子图 → LSE 生成候选 → PaCM 预测候选 → 设备测量与记录更新 → 选择最佳调度。

## 4. 系统或算法流程

### 4.1 LSE：Draft 阶段

LSE 将调度搜索视为硬件适配度优化。它根据调度生成规则产生 schedule template，随机初始化候选，然后用遗传算法迭代改变循环 tiling 因子。SA 不运行复杂学习模型，而是提取 L0、L1、L2 等层次存储相关的硬件感知符号，计算容量、计算量、并行度、传输维度等 penalty，并据此估算计算延迟与内存访问延迟（第 4.1 节，算法 2）。

论文列出 8 类符号：L0/L1 分配与计算信息、L2 footprint、并行信息、传输维度和计算量。SA 对每个最内层语句估计计算利用率和内存带宽利用率，最后将各语句的计算与访存延迟相加得到程序延迟估计。LSE 输出高硬件适配度的 `S_spec`，而不是让 PaCM 处理全部探索候选。

### 4.2 PaCM：Verify 阶段

PaCM 从低层张量 IR 中抽取跨层 buffer 的 multi-tiling pattern，把数据移动过程编码为 temporal dataflow feature。每个数据块特征包含内存访问、数据复用、访问步长、访问类型、分配大小、流向和计算密度等信息；论文描述其数据流特征为 23 维，并与 Ansor 的 statement-level feature 组合。

PaCM 使用多分支 Pattern-aware Transformer：statement-level 分支经过线性层；temporal dataflow 分支使用 self-attention 建模上下文；两个分支拼接后经线性层输出归一化性能预测。训练目标使用归一化延迟和 LambdaRank loss（第 4.2 节、图 4）。

### 4.3 MoA：在线适配

MoA 将跨平台预训练模型加载到目标模型，并使用在线数据微调目标模型；之后按照目标模型梯度以动量系数 `m = 0.99` 更新 Siamese model。论文强调 Siamese 侧不需要额外前向和反向计算。该策略试图减少直接在线微调受早期小样本和偏置影响的问题（第 4.3 节、图 5）。

## 5. 实验框架与数据流

实验在三种 NVIDIA GPU 上进行：A100、Titan V 和 Jetson Orin-AGX。端到端 DNN 工作负载包括 CNN 和 Transformer，表 3 列出 14 个模型；包括 ResNet、WideResNet、Inception-V3、DenseNet-121、MobileNet-V2、DCGAN、DeepLab-V3、BERT、GPT-2、Llama、OPT、Mistral、ViT 和 DeTR。TensorCore 半精度实验选取 6 个语言模型变体。

对比对象包括 PyTorch 2.2、Triton、Torch-TensorRT，以及 Ansor、TenSetMLP、TLP、MetaSchedule、Felix、Adatune、Roller 和 TLM。在线与离线调优多数设置为最多 200 个 round、每轮测量 10 个张量程序，即 2,000 次试验；LSE 生成的候选规模设置为 512。离线实验使用 TenSet 预训练并在目标平台数据上微调；在线实验持续收集目标平台数据。TenSet 数据集分析使用超过 2,308 个子图、每个子图 4,000 个 schedule、总计约 1,600 万个张量程序，覆盖 NVIDIA K80 和 T4。

## 6. 训练、强化学习、工具调用与验证机制

- 训练：PaCM 是 Transformer 型学习代价模型；论文还使用 TenSet 进行离线预训练/训练数据分析，并讨论目标平台微调。
- 强化学习：论文中未明确说明使用强化学习。LSE 使用遗传算法搜索调度候选，但遗传算法在本文中不是强化学习训练流程。
- 工具与编译器：系统实现于 TVM/Ansor，并在 TensorCore 实验中扩展 MetaSchedule；设备运行测量提供真实性能反馈。
- 奖励函数：论文中未明确说明 RL reward。LSE 使用硬件感知 penalty 和 SA 的经验代价；PaCM 使用归一化延迟与 LambdaRank loss。
- 形式化验证：论文中未明确说明使用形式化等价验证器。这里的“Verify”是学习代价模型对草稿候选进行性能验证，不等同于语义正确性证明。
- 多阶段训练：存在离线预训练、目标平台在线微调与 MoA 动量更新，但论文中未明确说明 SFT 或指令微调。

## 7. 数据集与样本构建

论文使用两类数据：在线调优期间由目标设备测得的候选程序数据，以及 TenSet 等离线 GPU 张量程序数据。端到端实验中，作者为每个平台构建约 500,000 个张量程序的数据集；MoA 的跨平台 Siamese 模型使用 TenSet GPUs K80-6M 数据预训练。论文还报告了约 1.5 million 张量程序的小数据集构建可能超过 10 天，但这是对数据集构建成本的实验观察，不是所有任务的固定耗时。

TenSet 静态分析以 ResNet50、ResNet3D18、MobileNet-V2、BERT-base 和 BERT-tiny 等测试集评估 `Top-k`；LSE 使用 `Best-k` 衡量草稿候选集合中接近最优程序的程度。论文没有将这些数据集描述为 RISC-V 或 LLVM 数据集，实验硬件主要为 NVIDIA GPU。

## 8. 评价指标与对比方法

主要指标包括：

1. 调优/搜索时间：达到对比方法最终调优性能所需的时间及平均 speedup。
2. 推理延迟：单位为 ms 或 μs；表 5、表 6、表 8 等给出具体 workload 的性能与编译成本。
3. `Top-k`：按预测排序后候选与真实最优延迟的相对质量。
4. `Best-k`：LSE 草稿集合中第 k 个较优候选与最优延迟的比值。
5. 编译成本和 GPU 内存：表 7 报告 2,000 次调优的分钟数，另报告 PaCM、TenSetMLP/Ansor、TLP 的峰值 GPU 内存。

对比基线覆盖学习型代价模型、搜索型张量编译器、规则型编译器和通用推理框架，因而同时考察搜索效率、最终 kernel 性能与适用模型范围。

## 9. 主要实验结果

根据摘要和第 6.1 节，在三种 GPU 上、达到相当调优性能的口径下：在线调优中 Pruner 相对 Ansor 平均约 2.6×，MoA-Pruner 平均约 4.82×；离线调优中 Pruner 相对 TenSet 和 TLP 分别约 4.75× 和 4.05×。TensorCore 场景中，Pruner 相对 MetaSchedule 的平均搜索时间 speedup 为 4.08×。

更细的在线结果在三平台上，Pruner 相对 Ansor 的平均 speedup 为 2.7×、2.5×、2.59×；MoA-Pruner 为 4.18×、4.77×、5.51×。离线场景中，Pruner 相对 TenSetMLP 为 4.67×、4.53×、5.06×；在 A100 上相对 TLP 为 4.05×（第 6.1 节）。这些数字是论文所测 DNN 和 GPU 平台的平均结果，不代表对所有硬件成立。

最终推理性能方面，A100 上 Pruner 相对 PyTorch 2.2、Triton 和 TensorRT 的平均 speedup 分别为 1.95×、2.27×、1.21×；但论文也明确指出 TensorRT/cuBLAS 在少数特殊算子和较大 reduction 维度上可以更快。TensorCore 上相对 MetaSchedule、PyTorch、Triton 的平均性能提升分别约为 1.22×、1.23×、1.3×。

PaCM 在 TenSet T4 上的 `Top-1/Top-5` 为 0.892/0.962，在 K80 上为 0.897/0.969；TenSetMLP 对应为 0.859/0.941 和 0.878/0.958，TLP 对应为 0.862/0.935 和 0.880/0.947（表 11）。LSE 的 `Best-1` 在草稿规模为 512 时为 0.995，而去掉计算 penalty 或内存 penalty 时分别为 0.880 和 0.930（表 10）。消融实验显示去掉 LSE、时序数据流特征、statement-level 特征或 MoA 都会增加调优代价或降低性能；时序数据流分支的影响大于 statement-level 分支（表 12、表 13）。

## 10. 论文真正的创新点（阅读后的分析）

论文的核心创新不是单独提出一个更大的 Transformer，而是重新安排搜索流程的职责：用可解释、便宜的硬件符号分析负责广泛探索，用学习模型集中处理较小候选集。PaCM 的另一点价值是把 schedule 的多层 tiling 解释为跨层数据流，而不只是孤立的语句或 primitive 特征。MoA 则把跨平台迁移放进在线搜索循环，减少额外的蒸馏/局部模型开销。

从编译器系统角度看，论文将“候选产生、代价估计、真实测量、模型更新”拆成可替换组件，便于嵌入已有 TVM 搜索框架；这比把整个编译器搜索过程交给一个端到端模型更容易审计和复现。

## 11. 局限性

1. 实验平台主要是 NVIDIA A100、Titan V、Jetson Orin-AGX，论文没有给出 RISC-V、CPU、AMD GPU 或其他异构加速器上的实测结果。
2. SA 的 penalty 依赖层次存储、并行单元、带宽和 transaction 等设备抽象；迁移到具有不同执行模型的硬件时需要重新定义符号和 penalty。
3. 论文的“Verify”是性能预测，不是语义正确性验证；设备测量也不能证明所有未测 schedule 的行为或性能。
4. 某些专用 kernel 库可利用 splitK、Winograd 等手工优化，论文明确承认 Pruner 在特定算子上可能落后于 PyTorch/cuBLAS/TensorRT。
5. 论文未系统量化 SA 符号设计、PaCM 架构和设备抽象在更多硬件/算子族上的维护成本，也未将完整调优数据集、训练代码和所有复现实验细节在正文中逐项展开。
6. TLP 在部分实验中微调后无法搜索可用解；作者因此在部分比较中只选择成功案例，跨方法比较仍需注意可比性。

## 12. 对 AI 编译器、LLVM/MLIR、RISC-V 和多架构优化的启发（阅读后的分析）

1. 可将“便宜的结构分析 + 精确的学习模型”作为 LLVM/MLIR pass ordering、tile/schedule 搜索的通用分层框架：静态 IR 分析先缩小候选，代价模型再排序。
2. MLIR 方言可以显式携带多层内存、数据复用、并行映射和传输维度信息，使 PaCM 类时序数据流特征不必完全从低层代码反推。
3. 面向 RISC-V/RVV 或自定义矩阵扩展时，可把向量长度、LMUL、寄存器压力、scratchpad 容量、访存对齐和核间通信纳入硬件感知符号；但这只是迁移方向，论文没有完成该实验。
4. 多硬件场景可使用 MoA 的“预训练模型 + 目标硬件在线动量更新”思路，但需要检查不同 ISA、数值精度和运行时反馈是否满足参数共享假设。
5. 若与验证结合，PaCM 的性能筛选应与 Alive2、随机差分测试或硬件仿真分开：前者负责性能排序，后者负责语义/实现正确性，不能把二者混为一谈。

## 13. 可借鉴与不可直接照搬之处（阅读后的分析）

### 可以借鉴

- Draft-then-Verify 的搜索分工，尤其适合候选空间大而高精度代价模型昂贵的编译优化任务。
- 用可解释的硬件符号表达内存层次、并行度和数据移动，再将其和学习特征结合。
- 将跨硬件适配设计为搜索循环内的持续更新，而不是额外的离线迁移阶段。
- 用 `Best-k`、`Top-k`、搜索时间、真实运行延迟和内存占用同时评估候选质量与成本。

### 不可直接照搬

- 不能直接把 NVIDIA GPU 的 L0/L1/L2 符号、penalty 和公式复制到 LLVM/RISC-V/MLIR 后端；必须按目标硬件的执行和存储层次重新定义。
- 不能把 PaCM 的性能预测称为形式化验证，也不能用少量设备测量推断语义等价或全空间最优。
- 不能把论文在三种 NVIDIA GPU 上的 speedup 当作所有异构硬件的保证。
- 不能将 MoA 的跨平台参数更新直接用于 ISA 语义差异很大的平台，而不重新验证特征、数据分布和代价模型偏差。
- 论文没有证明该方法能自动生成 LLVM pass、MLIR lowering 或 RISC-V 指令选择规则；这些需要独立的 IR 约束、正确性测试和后端实验。
