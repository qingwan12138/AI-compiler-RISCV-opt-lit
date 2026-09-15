# Evaluating Compiler Optimization Impacts on zkVM Performance 文献阅读总结

论文题目：**Evaluating Compiler Optimization Impacts on zkVM Performance**

作者：Thomas Gassmann, Stefanos Chaliasos, Thodoris Sotiropoulos, Zhendong Su

发表时间：2025（首次公开）；正式发表 2026

发表平台：ASPLOS 2026 Volume 2，pp. 697–714；DOI: 10.1145/3779212.3790159；arXiv:2508.17518

论文链接或编号：[ASPLOS/DOI](https://doi.org/10.1145/3779212.3790159)；[arXiv](https://arxiv.org/abs/2508.17518)

关键词：zkVM、LLVM、RISC-V、编译优化、代价模型、自动调优

## 1. 研究背景

零知识虚拟机（zkVM）把常规 Rust/C/C++ 程序转成可生成证明的执行流程，但传统 LLVM 优化器的启发式通常面向 cache、分支预测和乱序执行等传统 CPU 特征，而 zkVM 的成本更接近执行指令、内存分页和证明约束。论文因此系统考察传统 LLVM pass 在 RISC-V-based zkVM 上的效果。

## 2. 论文要解决的问题

### 2.1 单个 LLVM pass 的影响

不同优化 pass 在 RISC Zero、SP1 与 x86 上分别带来什么性能收益或退化？

### 2.2 默认优化级别与自动调优

`-O0`、`-O1`、`-O2`、`-O3`、`-Os`、`-Oz` 以及 pass 组合是否适合 zkVM，自动调优能否进一步改善执行和证明时间？

### 2.3 zkVM-aware 编译器修改

能否依据 pass 级分析修改 LLVM 的内联、循环、算术和内存代价决策，使生成代码更适合 zkVM？

> 本文主要研究：传统 LLVM 优化如何影响 RISC-V-based zkVM 的执行、周期和证明成本，以及如何做针对性调整。

## 3. 核心方法概述

论文不是 LLM 系统，而是实验评测、OpenTuner 搜索和 LLVM pass/代价模型修改。

```text
58 个 Rust/C/C++ benchmark
        ↓
LLVM 生成 RISC-V guest 程序
        ↓
单 pass、优化级别或 OpenTuner pass 组合
        ↓
RISC Zero / SP1 执行与证明
        ↓
记录 cycle、执行时间、证明时间和 paging 行为
        ↓
定位代价模型问题并修改 LLVM
```

## 4. 实验框架与训练流程

本文不涉及模型训练，主要采用编译实验和自动调优。

### 4.1 单 pass 与优化级别

作者分别应用 64 个 LLVM pass、六个标准优化级别和未优化 baseline，在两个 zkVM 上测量执行与证明表现，并与 x86 native 执行对比。

### 4.2 自动调优

使用 OpenTuner 为每个 benchmark 搜索 pass 配置，报告相对于 `-O3` 的 zkVM execution/proving 改善。该搜索不是强化学习训练。

### 4.3 定向 LLVM 修改

论文围绕内联阈值、除法/算术代价模型、循环相关 pass 和无关的超标量 CPU 优化，形成三组轻量修改；随后重新运行 58 个 benchmark。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习奖励函数或神经网络损失。自动调优目标是降低 benchmark 的执行时间或证明时间；论文同时用 cycle count、动态指令数和 paging cycles 解释性能变化。具体搜索实现的统一奖励公式在论文中未明确说明。

## 6. 实验设置

### 6.1 数据集来源

benchmark 共 58 个 Rust 与 C/C++ 程序，覆盖 PolyBench、NPB、密码学原语、SHA、椭圆曲线验证、regex、Merkle tree、RSP 以及 MNIST 等 zkVM workload。论文列出库版本，并使用 RISC Zero zkVM 1.2.3 与 SP1 zkVM 4.1.1。

### 6.2 模型与工具

工具包括 LLVM、OpenTuner、RISC Zero、SP1 和 Rust/C/C++ 编译链；目标 guest ISA 为 RISC-V。硬件对照为 x86 native execution。论文没有使用 LLM。

### 6.3 对比方法

对比对象包括无 pass baseline、六个标准优化级别、单个 LLVM pass、OpenTuner 自动调优配置、原始 LLVM `-O3` 与作者修改后的 LLVM `-O3`。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
|---|---|---|
| Cycle count | guest 执行的总周期数 | 越小越好 |
| zkVM execution time | executor 重放并生成执行轨迹的时间 | 越小越好 |
| Proving time | prover 生成证明的时间 | 越小越好 |
| Native x86 time | 传统 CPU 对照执行时间 | 越小越好 |

## 7. 实验结果与结论

### 7.1 主要结果

标准优化级别在两个 zkVM 上总体有效，但收益明显小于传统 CPU；不同 pass 的方向并不稳定。`inline` 是最有利的 pass 之一，`licm` 在多个 workload 上最有害。

### 7.2 自动调优

相对 `-O3`，OpenTuner 在 SP1 上平均改善执行和证明时间约 17%，在 RISC Zero 上执行时间约 19%、证明时间约 17%；论文还报告最高约 2.2× 的 proving speedup。

### 7.3 定向修改

修改后的 LLVM 在 RISC Zero 的 58 个 benchmark 中至少 39 个执行性能提升，平均约 4.6%；SP1 中 19/58 提升，平均约 1%。最大单例执行收益达到 RISC Zero 上 45%。证明时间也有改善，但部分 workload 出现回退。

### 7.4 案例与安全发现

`licm` 在 `npb-lu` 上会增加访存和 paging 压力，RISC Zero 证明时间最高约变为 2.7×；更激进的 inline threshold 可改善平均执行时间，但可能损害 x86。自动调优过程中作者还发现并私下报告了 SP1 的一个可导致错误结果被证明的 silent-failure 安全问题。

## 8. 主要创新点

### 8.1 创新点一：zkVM 上的系统化 pass 评测

论文同时覆盖 64 个 pass、标准优化级别、58 个 benchmark、两个 zkVM 和 x86 对照，建立了 pass 级影响图景。

### 8.2 创新点二：从性能现象反推代价模型

作者将性能变化与指令数、paging cycles、内联和循环变换联系起来，指出传统 CPU 启发式不能直接迁移到证明执行环境。

### 8.3 创新点三：轻量 zkVM-aware LLVM 修改

通过调整内联、算术代价模型并关闭不相关 pass，验证了针对证明成本的编译器优化空间。

## 9. 局限性

### 论文明确或正文可见的边界

实验只覆盖 RISC Zero、SP1 和 58 个 workload；部分 pass 的根因分析集中在少数案例。作者也指出 profiling、cost model 和不同 zkVM 行为仍有待进一步研究。

### 阅读后发现的潜在局限

证明时间可能受分片、分页和 prover 实现影响，不能只用指令数解释。修改后的 LLVM 参数是否能迁移到其他 zkVM、RISC-V 扩展或真实生产 workload，当前 PDF 内容不足以确认。

## 10. 阅读后的研究方向反思

最值得借鉴的是“编译器决策—RISC-V guest 成本—证明反馈”的闭环，以及把 pass 级结果用于代价模型修正。论文已完成 zkVM pass 评测和定向 LLVM 修改，后续不能仅把平台替换为另一块 RISC-V 板卡。它适合作为 RISC-V/zkVM 编译优化 baseline、成本指标设计参考和硬件反馈模块。

## 11. 可进一步尝试的研究方向

### 11.1 多 zkVM 的统一成本模型

#### 研究问题
如何统一解释执行周期、paging、proof shard 和 proving time。

#### 与原论文的区别
从两个 zkVM 的经验修改扩展到跨 prover 的可迁移模型。

#### 可能的创新点
分解并学习多目标成本，同时保留可解释的 pass 级因果证据。

#### 实验框架
```text
LLVM pass 配置 → 多 zkVM 执行 → 周期/分页/分片/证明反馈 → 统一成本模型 → 配置选择
```

#### 可行性
需要多个 zkVM、LLVM 插桩、benchmark 和证明日志。

#### 主要风险
不同 prover 的内部成本不可直接比较，数据收集代价高。

### 11.2 RISC-V 向量 guest 的证明感知优化

#### 研究问题
RVV 指令减少动态指令数后，是否一定降低 zkVM 执行与证明成本。

#### 与原论文的区别
研究向量长度、向量访存和证明约束编码的交互，而不只是调 LLVM 标量 pass。

#### 可能的创新点
建立 RVV-aware 且 proof-aware 的合法指令选择与代价模型。

#### 实验框架
```text
标量/RVV IR → LLVM 后端 → guest 执行 → 证明成本 → 对照 pass 与向量长度
```

#### 可行性
需要支持 RVV 的 zkVM 或模拟后端、LLVM 和可重复的证明环境。

#### 主要风险
zkVM 对扩展指令的支持、证明电路成本和公平对照可能成为瓶颈。

## 12. 与其他已读文献的关系

本论文与 C60 的符号基本块 profiling 都关注编译器成本模型，但 C60 主要为 ML kernel 生成静态输入参数化 profile，本论文直接测量 zkVM 执行与证明成本。与 C15、C25 等 pass 选择/自动调优工作相比，本论文提供了 RISC-V-based zkVM 的特殊反馈信号；与 C63 Arancini 的形式化内存模型翻译不同，本论文重点是优化代价而非跨 ISA 语义映射。它适合作为硬件/执行环境 baseline。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 评测并改进 zkVM 上的 LLVM 优化 |
| 核心问题 | 传统 CPU 启发式是否适合证明执行成本 |
| 输入 | Rust/C/C++ benchmark 与 LLVM pass |
| 输出 | RISC-V guest 程序及优化配置 |
| 核心方法 | pass 评测、OpenTuner、zkVM-aware LLVM 修改 |
| 使用的模型 | 传统 LLVM；无 LLM |
| 使用的编译器工具 | LLVM、OpenTuner、RISC Zero、SP1 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 评测证明执行，但非编译变换形式化证明 |
| 数据集规模 | 58 个 benchmark、64 个 LLVM pass |
| 主要指标 | cycle、execution time、proving time |
| 最重要实验结果 | 修改 LLVM 在 RISC Zero 平均 +4.6%，最高单例 +45% |
| 核心创新 | zkVM 成本反馈驱动的 pass/代价模型分析 |
| 主要局限 | zkVM、workload 和 prover 范围有限 |
| 与 RISC-V 研究的相关性 | 高：目标 guest 基于 RISC-V |
| 最适合作为 | RISC-V/zkVM 编译优化 baseline 与成本模型参考 |

这篇论文最值得学习的是把证明系统的真实执行成本引入 LLVM 优化分析；最主要的局限是结果依赖两个 zkVM 和有限 workload；用于后续研究时，合理方式是扩展成本模型与 RVV/多 zkVM 验证，而不是只替换硬件平台。
