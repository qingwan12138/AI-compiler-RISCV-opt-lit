# MLIR Transform Dialect 文献阅读总结

论文题目：**The MLIR Transform Dialect: Your compiler is more powerful than you think**

作者：Martin Paul Lücke、Oleksandr Zinenko、William S. Moses、Michel Steuwer、Albert Cohen

发表时间：2024

发表平台：arXiv:2409.03864（cs.PL）

关键词：MLIR、Transform Dialect、细粒度编译控制、Pass 组合、自动调优

> 本文档基于 19 页 PDF 全文整理。

## 1. 研究背景

通用编译器通常只向用户暴露粗粒度 pass pipeline、flag 或少量 pragma。MLIR 内部已经有 tiling、interchange、unroll 等细粒度变换函数，但用户若要精确组合它们，往往必须写 C++ pass 并重编译编译器；Halide/TVM 的 schedule 又局限于各自领域（第1–2节）。

## 2. 论文要解决的问题

如何把通用编译器内部已有的细粒度变换安全、可组合地暴露给性能工程师，使“计算内容”和“优化计划”分离，同时支持静态检查、复用和外部自动调优。

## 3. 核心方法概述

Transform Dialect 把优化计划本身表示为 MLIR。输入由 payload IR 和 Transform IR 两部分组成；解释器维护 handle 到 payload operation 的映射，并调用 MLIR C++ 接口执行变换。handle/parameter 遵循 SSA，可精确串联变换；handle invalidation 防止变换删除 IR 后继续引用悬空对象；silenceable/definite error 提供分层错误处理。每个 transform 还能声明前置/后置条件，使 pipeline 组合可静态检查（第3节）。

## 4. 实验框架与训练流程

```text
Payload IR + Transform script
→ handle 精确匹配目标 op
→ 解释器逐条执行 transform
→ 更新/失效 handle
→ 检查前置与后置条件
→ 生成优化后 IR
```

论文通过 5 个案例评估：复现 pass pipeline、鲁棒 lowering、定位反优化 pattern、细粒度循环优化、与 BACO 自动调优集成。无需模型训练。

## 5. 奖励函数、损失函数或关键公式

没有训练损失。自动调优案例把 tile size、是否向量化等参数作为搜索变量，并用运行性能作为外部目标；约束包括 tile size 必须整除维度、内层循环不满足向量宽度时禁止向量化（第4.5节、图10）。

## 6. 实验设置

### 6.1 案例1

对 TensorFlow/TFLite 转 TOSA 的多个模型，自动把现有 MLIR pass pipeline 转为 Transform script，测解释开销（表1、图6）。

### 6.2 案例3–5

在 StableHLO/Enzyme 工作流中二分定位 100 多个 pattern 的性能退化；在 ResNet-50 层的循环巢上比较 OpenMP 与 Transform；使用 BACO 搜索 tile 参数。

### 6.3 评价指标

编译时间开销、pipeline 静态可诊断性、kernel 运行时间和自动调优加速比。

## 7. 实验结果与结论

Transform script 复现原 pass pipeline 时，额外编译开销最高 2.6%（第4.1节）。反优化定位中，每次搜索从“改 C++、链接和打包约 10 分钟”降至修改脚本后最多 4 秒，并定位到影响 XLA fusion 的 pattern（第4.3节）。OpenMP 与 Transform 的 tiled 版本中位时间分别为 0.48 秒和 0.49 秒；加入 libxsmm microkernel transform 后降至 0.017 秒，快 20 倍以上。BACO 搜索最终获得 1.68× 加速（第4.4–4.5节）。

## 8. 主要创新点

### 8.1 优化计划也是 IR

复用 SSA、类型、region、rewrite 和 dialect 扩展机制表达优化控制。

### 8.2 可变 IR 下的 handle 安全

显式追踪失效、替换和删除，避免组合变换时使用悬空引用。

### 8.3 前置/后置条件驱动组合

把 pass 的输入假设和输出 dialect 暴露为可检查契约，提前发现错误顺序。

## 9. 局限性

五个案例证明可用性但不是大规模 benchmark；高性能仍依赖 transform 实现、目标库和用户提供的优化知识。解释器模式可能在极细粒度、大规模脚本上产生开销，论文只说明必要时可进一步 JIT。前置/后置条件也需要 transform 作者准确声明，无法自动保证语义等价。

## 10. 阅读后的研究方向反思

Transform Dialect 很适合作为实验框架的“动作层”：LLM、贝叶斯优化或强化学习不直接拼接危险的 pass 字符串，而是生成受类型、handle 和契约限制的 Transform IR。真正的论文创新应放在搜索、证据或跨硬件策略上，而不是重复实现 dialect。

## 11. 可进一步尝试的研究方向

### 11.1 证据约束的 Transform script 搜索

#### 研究问题

能否利用编译 remark、IR 特征和实测性能，自动生成只作用于收益热点的 Transform script。

#### 与原论文的区别

原文提供控制语言；扩展工作研究“谁生成脚本、如何拒绝退化脚本”。

#### 可能的创新点

静态契约过滤、性能证据记忆、跨 x86/RISC-V 的 Pareto 选择。

#### 实验框架

```text
MLIR → 热点/remark → 候选 Transform IR
→ 静态契约检查 → 双架构编译实测 → 更新搜索策略
```

#### 可行性与风险

基础设施成熟；风险是 Transform Dialect 版本变化和不同后端支持不对称。

## 12. 与其他已读文献的关系

与 MLIR 基础论文相比，本文重点是“控制变换”而非定义多层 IR；与 Ansor/TCL 等搜索系统互补，可把 Transform script 作为结构化搜索空间；与 LLM 编译智能体结合时，它能承担比自由文本 pass 序列更安全的动作接口。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 将 MLIR 细粒度变换暴露为可编程优化计划 |
| 核心问题 | pass/pragma 太粗，写 C++ pass 成本高 |
| 输入/输出 | Payload IR+Transform IR / 优化后 IR |
| 核心方法 | handle、parameter、解释器、失效追踪、契约 |
| 是否使用学习 | 否；可外接自动调优 |
| 是否使用形式化验证 | 否；有静态组合检查 |
| 实验规模 | 5 个案例 |
| 最重要结果 | 开销最高 2.6%；microkernel 案例 20×+ |
| 核心创新 | 把可组合的编译控制本身建模为 MLIR |
| 主要局限 | 案例规模小，契约与高性能策略仍需提供 |
| 与 RISC-V 相关性 | 中高，可作为跨架构调优动作层 |
| 最适合作为 | MLIR 自动调优与智能体的结构化接口 |

> 最重要的启发是：搜索系统应操作“可检查的优化 IR”，而不是不可控的文本命令。
