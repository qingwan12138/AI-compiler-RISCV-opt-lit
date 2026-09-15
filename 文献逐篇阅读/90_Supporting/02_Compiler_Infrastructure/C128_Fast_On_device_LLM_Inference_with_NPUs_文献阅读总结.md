# Fast On-device LLM Inference with NPUs 文献阅读总结

论文题目：**Fast On-device LLM Inference with NPUs**  
作者：Daliang Xu、Hao Zhang、Liming Yang、Ruiqi Liu、Gang Huang、Mengwei Xu、Xuanzhe Liu  
发表时间：2025  
发表平台：ASPLOS ’25，Proceedings of the 30th ACM International Conference on Architectural Support for Programming Languages and Operating Systems，Volume 1，pp. 445–462  
论文链接或编号：DOI `10.1145/3669940.3707239`；arXiv `2407.05858`  
关键词：端侧大语言模型、NPU、预填充、异构协同、量化、运行时调度、移动编译基础设施

> 本笔记只把论文正文明确给出的内容记为事实；“阅读后的分析”和“可进一步尝试的方向”单独标注。

## 1. 研究背景

本文研究端侧大语言模型（Large Language Model，LLM）推理系统，重点是移动 SoC 上的 CPU、GPU 与神经处理单元（Neural Processing Unit，NPU）协同。端侧推理可以减少隐私数据外传，并支持界面自动化、邮件回复等个性化任务。

论文第 1 节指出，移动 LLM 的端到端延迟常被预填充（prefill，即把整段输入送入模型并建立中间状态）主导，而不是解码（decode，即逐 token 生成）。在 UI 自动化、上下文问答和聊天摘要中，CPU 上预填充占总延迟 88.3%–98.8%，GPU 上仍占 54.2%–91.7%。现有工作更多优化解码、激活稀疏或投机解码，未充分利用移动 NPU 的整数矩阵运算能力。

移动 NPU 的困难不是“把算子搬过去”即可解决：NPU 通常偏好静态形状和 INT8 矩阵乘，而 LLM 输入长度动态、量化存在激活离群值、LayerNorm 和 Attention 等浮点算子仍然存在。论文的目标是降低预填充延迟与能耗，同时保持可接受的 LLM 精度。

## 2. 论文要解决的问题

### 2.1 动态输入长度与静态 NPU 图不匹配

移动 NPU 通常要求静态形状。针对不同 prompt 长度重新构建和优化执行图代价高；直接填充到最大上下文长度又浪费计算。

### 2.2 分组量化与 NPU 矩阵乘能力不匹配

论文第 2.3 节说明，LLM 常用 per-group quantization 处理激活离群值，但被测移动 NPU不能直接执行分组矩阵乘，只能拆成多个子矩阵乘再进行浮点求和，最高产生 10.7 倍性能开销。

### 2.3 浮点算子不能简单消除

移动 NPU 对浮点运算较弱，而 LayerNorm、Attention 以及量化误差处理仍需要浮点计算。若全部放到 CPU/GPU，可能拉长关键路径；若全部放到 NPU，则会损害精度或效率。

> 本文主要研究：如何针对移动 LLM 预填充的动态形状、激活离群值和浮点算子约束，设计 CPU/GPU/NPU 协同的低延迟端侧推理系统。

## 3. 核心方法概述

论文提出 `llm.npu`，通过三级重构使 NPU 承担主要 INT8 计算，CPU/GPU 并行处理必要的浮点与离群值计算：

```text
动态长度 prompt
        ↓
固定长度 chunk + 因果依赖图
        ↓
共享静态子图 / 独立动态 Attention 子图
        ↓
普通值走 NPU INT8 MatMul；离群值走 CPU/GPU shadow execution
        ↓
按依赖和 NPU 停顿贡献在线选择可执行子图
        ↓
CPU/GPU/NPU 协同完成 prefill，再接任意解码后端
```

系统包含三项核心技术：

1. `Chunk-sharing graph`：把动态 prompt 切成固定长度 chunk，静态算子子图跨 chunk 共享，动态 Attention 子图按 chunk 构建。
2. `Shadow outlier execution`：NPU 对量化范围内的值执行 per-tensor INT8 MatMul，CPU 以紧凑张量补算超出量化范围的离群部分，再合并结果。
3. `Out-of-order subgraph execution`：在满足跨 chunk 和 chunk 内依赖的前提下，不严格按 chunk 顺序调度子图，以减少 NPU 等待 CPU/GPU 浮点子图造成的执行气泡。

LLM 在本文中是被加速的工作负载，不是控制其他编译器变换的语言模型代理。因此按本仓库 taxonomy 规则，建议归为 SUPPORTING/B2，而不是 SELECTOR 或 TRANSLATOR。

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用静态图构建、离线 profiling、端侧运行时调度和实机测量。

### 4.1 准备与离线 profiling

系统预构建不同 chunk 相关的 NPU 子图，区分只依赖 chunk 长度的静态算子和依赖 chunk 序号/长度的动态算子；同时对算子形状、子图执行时间、离群阈值和离群重要性进行 profiling。默认 chunk length 为 256，离群层默认剪枝率为 85%。

### 4.2 运行时 prefill

运行时将 prompt 切分为 chunk，复用共享静态子图；NPU 执行主要 INT8 线性层，CPU/GPU 执行 LayerNorm、Attention 和 shadow outlier 部分。调度器根据当前可执行集合和公式（5）的 NPU 停顿贡献选择下一个子图，调度开销为微秒级。

### 4.3 解码阶段

原型的端到端实现使用 MLLM CPU backend 进行解码；论文说明系统兼容任意解码引擎，并在第 4.6 节用 TFLite 模拟 GPU-NPU 协同的潜在效果。本文没有 SFT、PPO、GRPO、工具调用式训练或强化学习流程。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数，也没有模型训练损失函数。关键公式是 shadow outlier execution 的等价分解：

```text
x/s ⊙ w
= clip(round(x/s), -127, 128) ⊙ w       （NPU）
  + extract(floor(x/s) × 128) ⊙ w        （CPU）
```

其中 `x` 是原始浮点激活，`w` 是 INT8 权重，`s` 是量化尺度，`⊙` 是矩阵乘，`extract` 把离群激活压缩成紧凑张量。第一项保留在 NPU 的高效 per-tensor INT8 路径，第二项由 CPU 补算，以减少量化离群值带来的精度损失。

在线调度的关键目标来自论文公式（5）：

```text
C(g) =  Σ T_i       （g 在 CPU/GPU 上执行）
C(g) = -Σ T_i       （g 在 NPU 上执行）
```

`S` 是执行子图 `g` 后新变为可执行的子图集合，`T_i` 是这些子图的执行时间。系统选择 `C(g)` 最大的候选：CPU/GPU 子图希望释放更长的 NPU 工作，NPU 子图希望释放更短的 CPU/GPU 工作，从而减少 NPU 关键路径停顿。该目标不是通用吞吐最大化，也不是学习出来的奖励。

## 6. 实验设置

### 6.1 数据集来源

精度实验使用 LAMBADA、HellaSwag、WinoGrande、OpenBookQA 和 MMLU。速度实验使用 LongBench、2wikimqa、TriviaQA，并使用 DroidTask 模拟屏幕问答和 UI 动作生成；Persona-Chat 用于聊天摘要。论文还以 WikiText 在 2048 推理长度下分析 Qwen1.5-1.8B 的离群值分布。

论文给出五个模型：Qwen1.5-1.8B、Gemma-2B、Phi-2-2.7B、LLaMA-2-7B 和 Mistral-7B。数据集训练/验证/测试拆分规模未作为本文系统训练数据明确给出；本文主要是推理评测。

### 6.2 模型与工具

硬件为 Redmi K70 Pro（Snapdragon 8 Gen 3，24 GB）和 Redmi K60 Pro（Snapdragon 8 Gen 2，16 GB），均运行 Android 13。系统实现约 10K 行 C/C++ 与汇编代码，建立在 MLLM 和 Qualcomm QNN 之上，支持 Hugging Face 导出的标准 LLM 格式，并实现 KVCache、SiLU、RMSNorm、ROPE 等算子。性能实验使用 Qualcomm Hexagon NPU；论文没有给出完整 NPU 微架构细节。

### 6.3 对比方法

对比包括三种移动 LLM 引擎：llama.cpp、TFLite、MNN；一个端侧 GPU LLM 编译器 MLC-LLM；以及同样使用 NPU 预填充的 PowerInfer-v2。PowerInfer-v2 的部分结果来自其论文，因为它未开源且缺少能耗数据。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
|---|---|---|
| 推理准确率 | LLM 基准任务正确率 | 越大越好 |
| Prefill latency | 输入处理延迟 | 越小越好 |
| Prefill speed | 每秒预填充 token 数 | 越大越好 |
| Energy consumption | Android 电源接口测得的预填充能耗 | 越小越好 |
| Memory consumption | 端侧推理内存占用 | 越小越好 |
| End-to-end latency | prefill + decode 总延迟 | 越小越好 |

能耗通过 Android `/sys/class/power_supply` 每 100 ms 采样；实验重复三次并报告平均值。端到端表中的 speedup 是各样本 speedup 的几何平均。

## 7. 实验结果与结论

### 7.1 主要结果

在 prompt length 为 1024 的预填充实验中，Redmi K70 Pro 上 `llm.npu` 相对 llama.cpp-CPU、MNN-CPU、MLC-GPU、TFLite-GPU 的加速范围分别为 18.17–38.4 倍、7.3 倍、32.5–43.6 倍和 1.27–2.34 倍；Redmi K60 Pro 上对应范围为 21.3–41.3 倍、7.43 倍、37.2–69.3 倍和 1.3–2.6 倍。相对 PowerInfer-v2-NPU，两个设备分别达到 3.28–5.32 倍和 3.4–5.6 倍。

在相同 prompt length 下，Redmi K60 Pro 的预填充能耗相对 llama.cpp-CPU、MLC-GPU、TFLite-GPU 分别最高降低 35.63–59.52 倍、35.21–59.25 倍和 1.85–4.32 倍；这些是特定设备、特定 prompt length 和预填充阶段的结果，不是所有端侧设备的普遍保证。

### 7.2 与传统引擎和 NPU 基线的比较

在 LongBench 真实工作负载上，端到端结果显示 `llm.npu` 总体最低延迟。以 Redmi K70 Pro 的 2wiki-Multi-doc QA 为例，五个模型对应的端到端 speedup 几何平均相对 llama.cpp、MLC-LLM、MNN、PowerInfer-v2、TFLite 分别为 34.7 倍、21.8 倍、4.8 倍、3.7 倍、1.7 倍；TriviaQA 对应为 31.0 倍、19.6 倍、4.4 倍、3.4 倍、1.6 倍。

### 7.3 与量化方法比较

表 6 显示，五个模型在 LAMBADA 上 `llm.npu` 相对 FP16 的平均准确率下降 1.2%，HellaSwag 为约 0%，WinoGrande 为约 -0.1%，OpenBookQA 为约 -0.5%，MMLU 的平均值略高于 FP16 约 0.2 个百分点。与 SmoothQuant、K-Quant 的比较显示，`llm.npu` 的动态离群处理通常保留更多精度；但 Phi-2 在 LAMBADA 上相对 FP16 下降 4.7%，因此“精度基本保持”不是每个模型/任务都严格无损。

### 7.4 消融实验

第 4.7 节的 Figure 19 显示：直接 NPU offload 反而比 CPU 慢 2.55–2.68 倍；加入 chunk-sharing graph 后，预填充速度提升 1.46–5.09 倍；加入 shadow outlier execution 后，预填充延迟进一步降低 3.91–8.68 倍；out-of-order execution 再降低 18%–44% 延迟。三项技术共同贡献最终收益。

### 7.5 案例与权衡

离群剪枝存在速度—准确率权衡。以 Qwen1.5-1.8B 的 LAMBADA 为例，离群剪枝率为 0% 时准确率 71.3%、速度 156 token/s；剪枝 80% 时准确率降至 42.2%、速度增至 544 token/s；全部剪枝时准确率仅 8.1%、速度 596 token/s。默认 85% 是论文原型的工程设置，不是由统一最优准则学习得到的策略。

## 8. 主要创新点

### 8.1 创新点一：面向动态 prompt 的 chunk-sharing graph

论文把动态长度问题转化为固定 chunk 图的组合执行，并进一步共享 144 个子图中的 120 个（Qwen1.5-1.8B 示例），报告 prompt length 1024、chunk length 256 时最多减少 75% 的图相关内存、约 7.2 GB。创新不在于简单 padding，而在于按算子是否依赖 chunk 长度和序号划分共享/动态子图。

### 8.2 创新点二：NPU 友好的 shadow outlier execution

系统保持 NPU 的 per-tensor INT8 MatMul，将少量超量化范围的激活在 CPU 上补算。论文在 Qwen1.5-1.8B 示例中观察到每层约 5–15 个离群通道，占总通道 0.1%–0.3%；又用 hot channel 权重缓存和离线重要性分析降低复制、同步和内存代价。

### 8.3 创新点三：以 NPU 停顿贡献为目标的在线乱序调度

系统显式建模跨 chunk 与 chunk 内依赖，在可行子图中选择对减少 NPU stall 最有利者，而非只选择自身执行时间最短者。论文将精确最优排序归约为 NP-hard 问题，因此采用离线 profiling 加微秒级在线启发式。

## 9. 局限性

### 9.1 论文明确承认的局限

1. 原型当前主要实现 CPU-NPU 协同；GPU-NPU 部分是模拟/分析，GPU backend 尚未完整接入。
2. 解码阶段使用 MLLM CPU backend，导致长输出场景中端到端收益小于预填充收益。
3. 当前实现不考虑资源检测和资源竞争。
4. 默认 chunk length、离群阈值与剪枝率依赖离线 profiling，实践中需要针对不同 NPU 重新 profiling。
5. 目标是主流 decoder-only Transformer；论文没有证明对其他模型架构或所有 NPU 的迁移性。

### 9.2 阅读后发现的潜在局限

1. 端侧实机验证集中在 Qualcomm 两款手机，能耗结果还只在可 root 的 Redmi K60 Pro 上测量，跨厂商可复现性仍需验证。
2. 大幅 speedup 主要来自长 prompt 的 prefill；短 prompt 会受到 padding 和乱序调度空间不足的影响。
3. 离群剪枝示例显示速度和精度可能剧烈冲突，固定 85% 剪枝率未必适合不同模型、任务和输入分布。
4. 论文报告的是经验测量和有限基准，并非形式化精度证明；“正确性”主要体现为语言模型基准准确率保持。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把硬件约束前移到编译/运行时图重构：先识别动态维度、数据依赖和算子硬件亲和性，再决定共享、分区和调度，而不是把完整模型盲目 offload。shadow execution 也提供了“主路径低精度、稀疏异常路径高精度”的异构编译思路。

### 10.2 不能直接照搬的部分

不能仅把 Qualcomm Hexagon 换成 RISC-V NPU 就声称形成新方法；需要新的 ISA/编译后端约束、代价模型、内存一致性和真实硬件测量。三项技术是本文核心贡献，直接复现其组件组合更适合作为 baseline。

### 10.3 与本研究方向的关系

本文与“LLM 作为 Selector/Translator”不是同一角色：LLM 是被优化对象，系统本身没有让语言模型输出 pass、IR 或编译动作。因此它更适合作为异构运行时、NPU lowering 和硬件感知代价模型的系统参考，不能误写成 LLM 编译优化代理。

## 11. 可进一步尝试的研究方向

### 11.1 方向一：面向 RISC-V 向量/NPU 后端的异常感知 lowering

#### 研究问题

能否把 shadow outlier 的分解显式编译到 RVV 或自定义 NPU ISA，并自动选择异常路径的向量宽度、缓存位置和同步粒度？

#### 与原论文的区别

不只是更换芯片，而是把异常通道抽取、混合精度和后端指令选择纳入统一 lowering 与代价模型。

#### 可能的创新点

设计异常感知 IR；对普通路径与稀疏路径分别做寄存器/内存规划；用真实硬件计数器校正同步代价。

#### 实验框架

```text
LLM 算子图 → 异常感知 IR → RVV/NPU lowering → 真实硬件执行 → 精度/延迟/能耗反馈
```

#### 可行性

需要 LLVM/MLIR 后端、RVV 模拟器或开发板、量化 LLM 和异常统计数据。

#### 主要风险

自定义 NPU 的可获得性、异常分布跨输入变化、端到端同步开销可能抵消理论收益。

### 11.2 方向二：输入自适应的 chunk 与剪枝联合选择

#### 研究问题

能否根据 prompt 长度、激活异常率、内存压力和实时精度预算，动态选择 chunk length 与离群剪枝率？

#### 与原论文的区别

原论文使用默认 chunk length 和离线 profiling；新方向研究运行时多目标选择，而非固定经验参数。

#### 可能的创新点

建立可审计的精度—能耗—延迟约束选择器，并记录每次选择的输入特征和硬件反馈。

#### 实验框架

```text
输入特征/预算 → 候选 chunk×剪枝率 → 编译/运行时估计 → 安全约束过滤 → 实机测量
```

#### 可行性

可从本文五类模型、五类准确率基准和两部手机复现实验开始。

#### 主要风险

在线 profiling 成本、输入分布漂移和精度预算的可解释性是主要风险。

## 12. 与其他已读文献的关系

本轮仅完成这一篇论文，因此没有另一篇同批次论文可进行事实级横向比较。与仓库中已存在的 `NPUEval: Optimizing NPU Kernels with LLMs and Open Source Compilers` 相比，本文是端侧 LLM 推理运行时与 CPU/GPU/NPU 协同，LLM 是负载；NPUEval 的 LLM 直接生成/优化 NPU kernel，属于 TRANSLATOR/T4。二者可以组合为“LLM 生成 kernel + llm.npu 运行时调度”的研究假设，但该组合不是本文已实现内容。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 移动 NPU 加速端侧 LLM prefill |
| 核心问题 | 动态 prompt、量化离群值、浮点算子与 NPU 能力不匹配 |
| 输入 | decoder-only LLM 与动态长度 prompt |
| 输出 | CPU/GPU/NPU 协同的 prefill 结果，再接解码引擎 |
| 核心方法 | chunk-sharing graph、shadow outlier execution、乱序子图调度 |
| 使用的模型 | Qwen1.5-1.8B、Gemma-2B、Phi-2-2.7B、LLaMA-2-7B、Mistral-7B |
| 使用的编译器工具 | MLLM、Qualcomm QNN；实现自定义算子与 NPU 图 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；使用基准准确率和实机测量 |
| 数据集规模 | 论文正文未给出统一训练集规模；使用多个公开推理基准 |
| 主要指标 | prefill speed/latency、能耗、内存、准确率、端到端延迟 |
| 最重要实验结果 | 最高 43.6 倍 prefill 加速、59.5 倍能耗节省；端到端最高 32.8 倍加速 |
| 核心创新 | 将移动 NPU 静态图、量化异常和异构关键路径联合重构 |
| 主要局限 | GPU-NPU 尚未完整实现，解码偏 CPU，依赖 Qualcomm 两款设备和 profiling |
| 与 RISC-V 研究的相关性 | 中：提供异构后端与异常感知调度思路，但没有 RISC-V 实验 |
| 最适合作为 | 异构 LLM 运行时/编译基础设施参考与系统 baseline |

这篇论文最值得学习的是把动态形状、量化异常和处理器亲和性统一纳入端侧执行图与运行时调度；最主要的局限是硬件覆盖和 GPU-NPU 实现仍有限、解码端未优化。用于后续研究时，合理做法是把它作为异构运行时 baseline，再引入新的 ISA/后端、输入自适应策略或可审计代价模型，而不是简单替换成 RISC-V 后宣称完成新的 LLM 编译方法。
