# C46 Trinity 文献阅读总结

论文题目：**Trinity: Three-Dimensional Tensor Program Optimization via Tile-level Equality Saturation**

作者：Jaehyeong Park、Youngchan Kim、Haechan An、Gieun Jeong、Jeehoon Kang、Dongsu Han。

发表信息：ASPLOS 2026 主会论文，DOI 10.1145/3779212.3790240；Proceedings of the ACM on Programming Languages, Volume 10, Issue 2, Article 99（论文页码 2079–2107）。本文阅读作者公开的 30 页 PDF，含 artifact appendix。

来源：[ASPLOS 2026 官方议程](https://www.asplos-conference.org/asplos2026/program/index.html)、[作者公开 PDF](https://ina.kaist.ac.kr/assets/bibliography/Trinity.pdf)、[DOI](https://doi.org/10.1145/3779212.3790240)、[artifact 仓库](https://github.com/kaist-ina/Trinity-AE)。

关键词：张量程序、等价饱和、e-graph、tile-level IR、Triton、GPU 融合。

## 1. 研究背景

现代 GPU 张量程序性能取决于代数变换、访存组织和计算调度的共同选择。单个局部调优器通常无法同时找到融合边界、循环结构、缓存行为和并行布局的好组合。复杂 Transformer 算子的手工融合成本高，现有编译器生成的 kernel 也可能拆分计算并产生中间数据搬运。

## 2. 论文要解决的问题

Trinity 研究如何在统一搜索空间中联合优化张量程序的代数表达、内存 I/O 与计算编排，并把最优候选编译成高效 GPU kernel。核心困难是有状态 load/store 与别名使代数重写难以保持语义；序列结合律又会让 e-graph 急剧膨胀；而纯静态代价模型难以准确预测不同 GPU 上的延迟。

## 3. 核心方法概述

系统将计算表示为包含 tile、load/store、循环与序列的 IR，以 tile 为优化粒度进行 equality saturation。表达式传播使内存操作参与代数重写；序列规范化为固定右结合形式以控制 e-graph 增长；携带读写区域、别名、循环依赖和形状信息的 e-class analysis 用于约束融合、插入和其他重写的合法性。

论文提供 31 条代数 rewrite rules，以及 loop fusion、fission、循环不变式移动/插入和循环体 factoring 等变换。提取分两阶段：先选择循环组织和 kernel 边界，再贪心选择循环体操作；最多保留 512 个候选，生成 Triton 3.4.0 程序并通过真实硬件 profiling 选择 kernel，block size 另行 autotune。

## 4. 实验框架与训练流程

### 4.1 代表性案例

Vanilla Transformer attention 案例中，e-graph 搜索得到 online softmax 风格的计算，跨 query/key/value projection、reshape 和 attention 融合为一个 kernel，减少中间张量写回。相较手工优化的 FlashInfer/H100，论文报告最高 1.35× 加速。由于浮点重排会改变舍入，结果以数值误差界内等价评估，不要求 bitwise identical。

### 4.2 候选选择与代码生成

从初始 tensor IR 建立等价类，应用重写并截断搜索；抽取候选后生成 Triton 代码，在目标 GPU 上 profiling，选择实测更快者。搜索空间可很大：论文给出 Vanilla 的 2×10^17 和 KeyFormer 的最高 10^21 量级；Vanilla 示例编码为 434 个 e-class、2058 个 e-node，提取 170 个 kernel 候选约需 54 秒。

### 4.3 训练流程

本文没有机器学习模型训练、RL 或损失函数。优化来自等价饱和、候选提取与硬件实测选择。artifact 由 Rust/egg 优化器和 Triton 后端构成。

## 5. 奖励函数、损失函数或关键公式

没有学习奖励或损失函数。动态 profiling 的 kernel latency 用于候选选择，block size 通过 autotuning 决定；静态 FLOPs/结构规则辅助提取阶段，而实际硬件执行时间是最终性能依据。正确性约束由 IR 语义与 e-class analysis 中的形状、读写区域和依赖信息支撑。

## 6. 实验设置

### 6.1 工作负载与硬件

| 项目 | 设置 |
|---|---|
| 模型/算子 | LLaMA 3 8B、Falcon 7B；Vanilla、Pre-Norm、QK-Norm、RoCo、KeyFormer、SwiGLU FFN |
| 推理场景 | speculative decoding，16-token block；1008-token prefix，KV cache 长度 1024 |
| GPU | NVIDIA H100 80 GB、A100 40 GB、RTX 4090、RTX 5090 |
| 软件 | PyTorch 2.8.0、Triton 3.4.0、TensorRT 10.10.0.31、FlashInfer 0.5.3；Rust 1.75+ |
| 延迟报告 | 正文比较 kernel/inference latency；artifact 对延迟测量三次取最小值 |

### 6.2 对比系统

比较 TorchInductor、TensorRT、FlashInfer、FlashTensor、Relax、Mirage 等。系统适用的 GPU、算子和 CUDA Graph 设置不尽相同；主结果未启用 CUDA Graph，以维持与默认基线较一致的部署条件。附录另给 CUDA Graph 结果。

### 6.3 主要结果

H100 上相对 TensorRT，LLaMA 3 不同配置的加速比分别包括 Vanilla 1.71×、Pre-Norm 1.43×、QK-Norm 1.63×、KeyFormer 1.29×、RoCo 1.37×、SwiGLU FFN 1.10×；论文报告相对 Mirage 最高 3.07×。Vanilla attention 相较手工优化 FlashInfer 最高 1.35×。RTX 4090 与 H100 上最佳 tile/中间值驻留策略不同，说明配置依赖硬件资源。

### 6.4 编译成本

正文报告 Trinity 对各架构优化时间：SwiGLU 266s、Vanilla 203s、QK-Norm 375s、Pre-Norm 1162s、RoCo 710s、KeyFormer 1459s；Mirage 对应成本为 348s、7741s、4039s、8678s、16062s、15963s。搜索成本仍然显著，但在复杂联合优化案例中低于所比较系统。

## 7. 结果分析与证据边界

实验显示 tile-level equality saturation 可联合探索高层代数、访存和执行边界，在论文覆盖的 Transformer 推理 workload 和 GPU 上产生有竞争力的 Triton kernel。真实硬件 profiling 降低了静态代价估计误差。结果不能推出对训练/backprop 或任意张量图同样有效；论文明确指出新算子需要 rewrite rules，超大 attention+FFN 联合搜索会遇到固定轮次重写的困难。数值“等价”容许浮点舍入差异，需按论文测试阈值理解。

## 8. 主要创新点

1. 以 tile-level equality saturation 统一搜索张量计算、内存 I/O 和调度结构。
2. 通过表达式传播、序列规范化与携带内存语义的 e-class analysis 管理状态操作和搜索膨胀。
3. 两阶段提取后生成 Triton，并通过目标硬件 profiling 选择最终 kernel。

## 9. 局限性

1. 当前评估针对推理工作负载，不支持训练反向传播。
2. 依赖 Triton，未利用 Hopper 专用 warp specialization 或 TMA 等高级特性。
3. 新算子需要人工补充 rewrite rules；规则完备性与扩展成本限制适用范围。
4. 巨大的 attention 与 FFN 联合优化可能使固定轮次规则应用难以充分探索；profiling 也需要目标 GPU 和时间。

## 10. 阅读后的研究方向反思

Trinity 显示，显式表达搜索空间和合法性条件能让编译器系统获得可解释的变换覆盖，但规则维护仍是瓶颈。后续可研究从算子语义自动合成/验证 rewrite rules、面向硬件的分层剪枝，以及把近似数值误差预算纳入代价模型。论文 artifact 还为复现实验提供了 Rust optimizer、Triton 后端、profile 脚本和预生成 IR/kernel。

## 11. 可进一步尝试的研究方向

1. 为训练 workload 扩展 tile IR，明确梯度、随机性和混合精度的等价条件。
2. 将 Triton 后端与 TMA、warp specialization 等硬件特性结合，比较抽象 IR 是否需要显式表达异步搬运。
3. 对 rewrite rules 做自动验证或从高层算子定义生成，减少新算子接入的手工成本。
4. 研究跨 GPU 迁移候选与 profile 样本，降低每个目标平台的搜索时间。

## 12. 与本批另一篇论文的关系

本批 LOOPRAG 以 LLM 生成优化后的 SCoP 源码，依靠检索示例和编译/动态测试/性能反馈；Trinity 不使用 LLM，而是在结构化张量 IR 上执行显式等价搜索并生成 GPU kernel。两者都把性能测量闭环用于候选筛选，但前者搜索灵活、正确性依赖有限测试，后者变换空间受规则约束且用 e-class analysis 管理合法性。一个可探索的结合方式是让模型建议或归纳 rewrite candidates，再由等价饱和和验证条件筛选；这是研究假设，并非论文已经实现的系统。

## 13. 一页式总结

| 项目 | 结论 |
|---|---|
| 研究对象 | Transformer 推理张量程序与 GPU kernel |
| 系统角色 | SUPPORTING / B2_Compiler_Infrastructure；传统编译器优化基础设施 |
| 核心方法 | tile-level equality saturation、内存语义分析、两阶段提取、Triton profiling |
| 主要证据 | 多种 Transformer 架构、4 类 NVIDIA GPU、与 6 类编译/内核系统比较 |
| 正确性 | 结构化 IR 约束及数值容差测试；不要求浮点 bitwise 相同 |
| 主要限制 | 不支持训练、依赖 Triton/手写规则、搜索及硬件 profiling 成本高 |
| 复现 | artifact appendix 提供开源仓库、命令行和评估流程 |
