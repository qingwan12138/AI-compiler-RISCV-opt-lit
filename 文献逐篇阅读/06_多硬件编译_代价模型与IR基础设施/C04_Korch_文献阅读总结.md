# Korch 文献阅读总结

论文题目：**Optimal Kernel Orchestration for Tensor Programs with Korch**

作者：Muyan Hu 等

发表时间：2024

发表平台：ASPLOS 2024 / arXiv:2406.09465

关键词：tensor program、operator fission、kernel orchestration、二进制线性规划、GPU

> 本文档基于 15 页 PDF 全文整理。

## 1. 研究背景

现有 DNN 框架通常按人工规则贪心融合算子。算子是按数学语义划分的，不一定对应 GPU 上最合适的 kernel 边界；例如 softmax 内含 elementwise、reduce 和 broadcast，不同部分可能更适合与相邻算子的局部计算融合（第1节）。

## 2. 论文要解决的问题

如何突破完整算子边界，把 tensor program 的细粒度计算系统地映射为一组 GPU kernels，并在所有合法组合中选择总执行代价最小的 kernel orchestration，而不是依赖设备特定的贪心融合规则。

## 3. 核心方法概述

Korch 先把算子裂解成 elementwise、reduce/broadcast、layout transform、linear transform 四类 primitive，并使用 TASO 图变换优化 primitive graph。随后枚举图的 execution state；两个 state 的集合差对应一个合法凸子图，也就是候选 kernel。内存密集候选由 TVM MetaSchedule 调优，计算密集候选调用 cuDNN/cuBLAS/TensorRT。候选实测延迟输入二进制线性规划（BLP），求出覆盖计算且总成本最低的 kernel 集合，最后拼接 CUDA 代码（第2–5节）。

## 4. 实验框架与训练流程

```text
ONNX 计算图 → 子图切分 → operator fission
→ primitive graph/TASO 优化 → 枚举凸子图
→ 生成并实测候选 kernel → BLP 全局选择
→ 按依赖拼接 kernel → GPU 可执行程序
```

没有神经模型训练；主要离线成本来自候选 kernel 的自动调优与测量。

## 5. 奖励函数、损失函数或关键公式

若候选 kernel `K_i` 的实测时间为 `c_i`、是否选择为 `u_i∈{0,1}`，目标是（第4.2节，式2）：

```text
min Cost(u) = Σ_i c_i u_i
```

约束保证每个必要 primitive 被正确产生、kernel 输入已就绪并满足图依赖。论文假设串行 kernel 总时间可由单个 kernel 时间相加。

## 6. 实验设置

### 6.1 硬件

NVIDIA V100 16GB（AWS p3.8xlarge、CUDA 11.7）和 A100 80GB（Perlmutter、CUDA 11.7）。

### 6.2 工作负载

Candy、YOLOv4、YOLOX-Nano、Segformer、EfficientViT，batch size 1；V100 用 FP32，A100 用 TF32（第6.1节）。

### 6.3 基线与指标

PyTorch 2.0.1、TVM 0.11、TensorRT 8.2；比较端到端推理延迟、子图案例收益和调优时间。

## 7. 实验结果与结论

Korch 在 V100/A100 上最高加速 1.7×/1.6×，平均加速 1.39×/1.30×（第6.2节、图6）。仅把 operator fission 接到 TensorRT，Segformer 已加速 1.24×。EfficientViT 案例通过允许少量冗余计算、减少 kernel 数和调整 MatMul 布局，使子图相对 TensorRT 加速 3.29×；某 Segformer 图中，拆成多个 kernel 比全部贪心融合快 2.24×。最大测试子图有 584 个 execution states、3078 个候选 kernels，PuLP 在 1000 秒内求得最优解（第5.2节）。

## 8. 主要创新点

### 8.1 Operator fission 扩大优化空间

先裂解再重组，使一个算子的不同部分可进入不同 kernels。

### 8.2 图论枚举合法 kernel

通过 execution state 差值枚举凸子图，系统覆盖合法候选。

### 8.3 BLP 全局编排

以实测 kernel 时间为代价，替代局部贪心融合，并允许冗余计算换取更少 I/O 或更好布局。

## 9. 局限性

候选数对图宽度呈指数增长，主要时间消耗在 profiling；当前只支持单输出候选，不联合选择数据布局，也只考虑 kernel 串行执行，不处理 CUDA multi-stream（第5.3、8节）。计算密集候选依赖厂商库，TVM 在 A100 上弱于 TensorRT 也限制了整体收益。论文只评估两代 NVIDIA GPU。

## 10. 阅读后的研究方向反思

Korch 的关键不是“又一种融合”，而是把融合边界提升为可求解的全局编排问题。若用于毕业论文，不能简单把 BLP 换成另一求解器；更有价值的是加入多硬件代价、不确定性、并行执行或编译预算约束。

## 11. 可进一步尝试的研究方向

### 11.1 预算感知的跨硬件 kernel orchestration

#### 研究问题

在只有少量真机测量时，如何为 GPU 与 RISC-V CPU/NPU 选择不同 kernel 边界。

#### 与原论文的区别

把确定的单 GPU 延迟表扩展为带预测不确定性、profiling 成本和多设备目标的优化。

#### 可能的创新点

主动挑选候选、置信上界代价、跨设备 Pareto orchestration。

#### 实验框架

```text
primitive graph → 候选子图 → 代价模型筛选
→ 少量真机测量 → 鲁棒整数规划 → 多后端执行
```

#### 可行性与风险

可从小图和 GEMM/softmax 开始；不同后端的 kernel 生成能力需要统一描述。

## 12. 最小可行 Demo

### 12.1 Demo 目标

在 5–10 个小型 attention/MLP 子图上比较贪心融合与全局编排。

### 12.2 输入数据

ONNX/MLIR 表示的 softmax、layernorm、matmul+elementwise 子图。

### 12.3 执行流程

```text
primitive 化 → 枚举小规模候选 → 两后端测量 → ILP 选择 → 端到端复测
```

### 12.4 需要的工具

ONNX/MLIR、TVM 或 Triton、PuLP/OR-Tools、GPU 与 K3。

### 12.5 输出结果

| 子图 | 候选数 | 调优时间 | kernel 数 | 延迟加速 |
|---|---:|---:|---:|---:|

### 12.6 成功标准

全局方案在相同正确性下稳定优于贪心融合，并显著减少需要真机测量的候选数。

## 13. 与其他已读文献的关系

与 Ansor/TCL 相比，Korch 优化的是 kernel 之间的编排，而非单 kernel schedule 的 cost model；与 upstream MLIR 流水互补，可用 Linalg primitive 作为裂解表示；与 MLIR latency-hiding 论文结合后可进一步建模多线程、DMA overlap 和多 kernel 并行。

## 14. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 为 tensor program 寻找最优 kernel 编排 |
| 核心问题 | 算子级贪心融合太粗、设备规则成本高 |
| 输入/输出 | ONNX 图 / 选定 kernels 与可执行程序 |
| 核心方法 | operator fission、凸子图枚举、profiling、BLP |
| 是否使用学习 | 否；调用 TVM 自动调优 |
| 是否使用形式化验证 | 否 |
| 实验硬件 | V100、A100 |
| 最重要结果 | 最高 1.7×/1.6×，平均 1.39×/1.30× |
| 核心创新 | 从算子融合转向 primitive 级全局 orchestration |
| 主要局限 | 候选爆炸、profiling 重、单输出与串行执行 |
| 与 RISC-V 相关性 | 中，可将编排迁移到异构后端 |
| 最适合作为 | kernel 边界与全局组合优化基线 |

> 最关键的结论是：融合得更多不一定更快，kernel 边界应由全局代价决定。
