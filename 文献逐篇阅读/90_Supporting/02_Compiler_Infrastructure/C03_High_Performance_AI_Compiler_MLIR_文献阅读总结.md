# Upstream MLIR AI Compiler 文献阅读总结

论文题目：**Towards a high-performance AI compiler with upstream MLIR**

作者：Renato Golin、Lorenzo Chelini、Adam Siemieniuk、Kavitha Madhu、Niranjan Hasabnis、Hans Pabst、Evangelos Georganas、Alexander Heinecke

发表时间：2024

发表平台：arXiv:2404.15204（cs.PL）

关键词：MLIR、Linalg、tensor packing、tile and fuse、libxsmm、CPU AI 编译器

> 本文档基于 13 页 PDF 全文整理。

## 1. 研究背景

AI/HPC 程序常依赖手写或厂商库才能接近硬件峰值。完整 AI 编译框架虽然能从高层模型下降，但容易形成庞大、私有的 pass 栈。作者希望尽量复用 upstream MLIR 的 Linalg/Tensor 基础设施，只保留很薄的库/硬件专用层（第1–3节）。

## 2. 论文要解决的问题

如何从 TensorFlow/PyTorch 导出的通用 Linalg-on-Tensor IR 出发，自动完成缓存友好的 packing、tiling、fusion、bufferization 与 microkernel lowering，在多种 CPU 上逼近“ninja-written”手写 libxsmm 程序性能。

## 3. 核心方法概述

流程由高层硬件无关 Linalg pipeline 和低层 XSMM dialect 组成。`tensor.pack/unpack` 改变布局并在 elementwise 链上传播，以消掉中间 pack/unpack；tile-and-fuse 以 contraction 为核心聚合生产者/消费者；one-shot bufferization 后下降到 XSMM dialect，再把 unary、binary、GEMM/BRGEMM 及其融合形式映射到 libxsmm。并行部分把 `scf.forall` 转为 OpenMP，支持二维线程分块和 AMX tile 配置提升（第4节）。

## 4. 实验框架与训练流程

```text
TensorFlow/PyTorch → Linalg-on-Tensor
→ pack 及布局传播 → tile & fuse
→ one-shot bufferization → XSMM dialect
→ libxsmm JIT microkernel + OpenMP → CPU 执行
```

论文使用人工经验设置 tile/线程启发式，没有训练代价模型；作者把自动构建 cost model 列为未来工作。

## 5. 奖励函数、损失函数或关键公式

论文中未定义奖励或损失函数。核心评价是编译器版本相对手写 `libxsmm-dnn` 的 GFLOPS/运行性能，以及 packing 和前端迁移带来的百分比开销。

## 6. 实验设置

### 6.1 工作负载

以 3 层 MLP motif 为主，batch 256、hidden size 1024，测试 FP32/BF16 推理；同时比较生成式 TensorFlow-like IR 与从 PyTorch/torch-mlir 获得的 IR（第5节）。

### 6.2 硬件

AWS c6a Zen3、c6i Cascade Lake、c7i Sapphire Rapids、c7a Zen4、c7g Graviton 3，覆盖 AVX2、AVX-512、AMX 和 Arm SVE/BFMMLA。

### 6.3 对比与指标

以手写 libxsmm-dnn 为基线，测单线程性能、在线/编译期 packing 成本、不同前端 IR 的影响，以及 2/4/8/16 线程扩展性。

## 7. 实验结果与结论

FP32 下编译器在各平台与手写版本偏差小于 5%；BF16 的 Sapphire Rapids 单线程受内存带宽和未对齐分配影响，可出现约 30% 退化（第5.1节）。编译器 packing 的平均开销约 1%，c7i BF16 为 7%；PyTorch 前端相对生成 IR 平均相差约 2%。多线程绝对性能最终与手写实现接近。论文据此说明 upstream Linalg 加薄 microkernel 层可以达到手写实现 90% 以上的性能。

## 8. 主要创新点

### 8.1 在 upstream Linalg 上完成高层优化

避免维护独立 tile dialect，把可复用的 packing、tiling、fusion 能力贡献到公共基础设施。

### 8.2 布局传播与中间转换消除

先积极 packing，再跨 elementwise 传播并通过 canonicalization 消去冗余转换。

### 8.3 编译器与 microkernel 分工

编译器负责布局、融合、并行；libxsmm 负责向量指令、寄存器流水和微架构细节。

## 9. 局限性

实验主要是 MLP motif，不代表完整模型覆盖；tile size、二维并行分块和若干架构选择仍是人工 flag，不是自动 cost model。高计算密度平台暴露内存分配/对齐缺陷；PyTorch 与 TensorFlow 的不同 lowering 仍需额外 pattern。低层性能依赖 libxsmm，不能直接说明纯 MLIR 后端已达到同等水平。

## 10. 阅读后的研究方向反思

这篇论文适合用来划清系统边界：毕业论文没有必要重新实现所有向量化和指令选择，可以把稳定 microkernel 当作后端执行原语，把创新放在布局、融合、调度选择及跨硬件证据上。要避免把“接入一个新库”本身当作创新。

## 11. 可进一步尝试的研究方向

### 11.1 跨 x86/RISC-V 的布局与 microkernel 选择

#### 研究问题

相同 Linalg 图在 x86 libxsmm 与 RISC-V RVV microkernel 上应选择怎样的 pack、tile 和融合边界。

#### 与原论文的区别

从人工启发式扩展为跨 ISA 的自动选择，并显式考虑转换成本。

#### 可能的创新点

可迁移代价模型、pack 成本分解、目标库能力约束。

#### 实验框架

```text
Linalg IR → 参数化 pack/tile/fuse
→ x86 libxsmm / RVV kernel → 实测 → 学习跨硬件策略
```

#### 可行性与风险

可先做 GEMM/MLP；RISC-V 侧 microkernel 覆盖和峰值性能是主要风险。

## 12. 与其他已读文献的关系

与 MLIR Transform Dialect 相比，本文给出具体高性能 lowering pipeline；与 Korch 的全局 kernel orchestration 不同，本文侧重单个线性代数流水和 microkernel 映射；与 RVV/xDSL 论文可直接组合成 x86 与 RISC-V 两套低层后端。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 用 upstream MLIR 构建高性能 CPU AI 编译流 |
| 核心问题 | 通用高层 IR 难以逼近手写 microkernel 性能 |
| 输入/输出 | Linalg-on-Tensor / libxsmm 调用与可执行程序 |
| 核心方法 | pack 传播、tile/fuse、bufferize、XSMM、OpenMP |
| 是否使用学习 | 否 |
| 是否使用形式化验证 | 否 |
| 硬件 | 5 类 x86/Arm CPU |
| 最重要结果 | FP32 与手写版偏差通常小于 5% |
| 核心创新 | upstream 高层通用 pass + 薄硬件/库 dialect |
| 主要局限 | 工作负载集中、启发式仍手工、依赖 libxsmm |
| 与 RISC-V 相关性 | 高，可替换低层库形成 RVV 后端 |
| 最适合作为 | 多硬件 Linalg 优化流水的实现基线 |

> 核心经验是：把可移植的高层优化 upstream，把极致性能留给薄而明确的目标层。
