# Network and Compiler Optimizations 文献阅读总结

论文题目：**Network and Compiler Optimizations for Efficient Linear Algebra Kernels in Private Transformer Inference**

作者：Karthik Garimella、Negar Neda、Austin Ebel、Nandan Kumar Jha、Brandon Reagen（论文首页；前 3 位作者等贡献）

发表时间：2025

发表平台：2025 IEEE/ACM International Conference on Computer-Aided Design（ICCAD 2025），Invited Paper；论文正文为 arXiv 版本，共 10 页

论文链接或编号：arXiv:2512.11135；ICCAD DOI：10.1109/ICCAD62629.2025.12104733

关键词：全同态加密（FHE）、编译器、CKKS、线性代数内核、Transformer、隐私推理、Orion、roofline 分析

> 本文档只依据已下载并通读的论文 PDF 记录论文事实；“阅读后的分析”和“可进一步尝试的方向”单独标出。论文研究的是 FHE 隐私 Transformer 推理中的编译与网络级优化，不是 RISC-V 后端论文。

---

## 1. 研究背景

论文关注云端大语言模型服务中的隐私问题。传统客户端-服务器推理把用户输入以明文交给云端，存在未经授权处理、收集甚至泄露的风险。全同态加密（Fully Homomorphic Encryption，FHE）允许服务器直接在密文上计算，理论上可以保留云端模型能力而不解密用户数据（第 1 节）。

FHE 的困难不只是算力不足：底层要在大整数多项式上做模运算，且编程接口主要提供 SIMD 加法、乘法和循环旋转。普通深度学习张量内核必须重新映射到 CKKS 的受限操作集合，数据如何打包、何时旋转、何时 bootstrapping（自举，恢复可用乘法层级）都会影响正确性和延迟。论文因此把问题放在“网络结构优化 + FHE 编译/内核实现 + 体系结构瓶颈分析”的交叉点上。

论文采用 Orion：一个让 PyTorch 深度网络在 FHE 下运行的框架。Orion 隐藏低层 FHE 细节，并自动处理层级和尺度管理、必要的 bootstrapping 插入。作者以 GPT-2、Phi-3 mini 和 Llama 3 8B 的 Transformer 尺寸为参照，研究 Transformer 中最重要的线性代数内核，而不是训练一个新语言模型。

## 2. 论文要解决的问题

### 2.1 FHE 中的矩阵-向量乘法如何选择打包与算法

前馈网络（Feed-Forward Network，FFN）包含两个明文-密文矩阵-向量乘法。论文比较 packed row（将多行打包到明文槽位）与 baby-step giant-step（BSGS，婴儿步-巨人步）两类方法，研究在 Transformer 规模下何种方式更适合 CKKS 的旋转、乘法层数和密钥成本（第 3 节）。

### 2.2 FFN 的非线性是否造成主要 FHE 成本

GeLU 通常以 127 次多项式近似，需要额外乘法层级，并可能触发 bootstrapping。论文研究删除 GeLU、再合并上下投影，是否能降低 FHE 延迟，以及困惑度损失如何变化（第 3-D 节）。

### 2.3 自注意力中的密文-密文矩阵乘法如何实现

自注意力的 QK^T 是密文-密文矩阵-矩阵乘法。论文给出基于行打包、外积分解、掩码提取和旋转复制的通用实现，并测试矩阵尺寸、输入乘法层级对延迟的影响（第 4 节）。

### 2.4 FHE 内核的真正瓶颈是计算还是内存

论文修改 roofline 模型，用“每字节 DRAM 流量执行的 64 位整数操作数”衡量 FHE 算术强度，分析加法、乘法和旋转是否受计算吞吐或内存带宽限制（第 5 节）。

> 本文主要研究：如何在 CKKS/FHE 的受限 SIMD 操作模型下，通过内核算法、Transformer 层级简化和内存瓶颈分析，降低私有 Transformer 推理的延迟。

## 3. 核心方法概述

核心方法由三部分组成：在 Orion 中实现并比较 row 与 Double-Hoisted BSGS 矩阵-向量内核；在网络层面移除 GeLU 并合并 FFN 投影；实现密文-密文矩阵-矩阵乘法并用 roofline 找到内存瓶颈。论文的“编译器”角色主要是将 PyTorch 图映射到 CKKS/FHE 操作并自动插入 bootstrapping，不是生成传统 CPU 汇编。

```text
PyTorch Transformer / 明文权重与密文输入
                 ↓
       Orion 映射到 CKKS/FHE 操作
                 ↓
  选择 row 或 Double-Hoisted BSGS 打包策略
                 ↓
   FFN 激活裁剪/层合并 + 自注意力矩阵乘法
                 ↓
  OpenFHE 后端执行、测量延迟与内存流量
                 ↓
  比较 speedup、困惑度、FLOPs、乘法层级和 roofline
```

输入包括 Transformer 的矩阵、密文向量或密文矩阵；输出是密文线性代数结果及其延迟。Orion 自动管理尺度、乘法层级和 bootstrapping 位置。BSGS 用较少的旋转降低矩阵-向量成本；FFN 裁剪和合并则改变网络结构，减少 FHE 层级与 FLOPs。论文未提出候选代码由 LLM 生成、编译器错误反馈修复或形式化等价证明。

## 4. 实验框架与训练流程

本文不涉及模型训练策略、SFT、PPO、GRPO 或其他强化学习训练；主要是 FHE 编译框架、内核实现和实验测量。论文只在 FFN 裁剪实验中从头训练 GPT-2 125M 作为比较模型，训练用于评估困惑度，不是提出新的训练算法。

### 4.1 Orion 运行流程

Orion 接收 PyTorch 网络，自动管理 ciphertext 的尺度与层级，并分析网络拓扑以插入 bootstrapping。其默认线性变换实现是 Double-Hoisted BSGS；本文增加 packed row 版本及密文-密文矩阵-矩阵乘法。

### 4.2 FFN 内核实验流程

对 FFN 上投影矩阵分别使用 packed row 与 BSGS，在 GPT-2 small、Phi-3 mini、Llama 3 8B 的矩阵尺寸上测量延迟。图 2 的结果是每个设置 3 次运行的平均值；论文特别指出 Llama 3 的 FFN 层使用 row 方法需要 24579 次旋转，而 BSGS 只需 272 次（第 3-C 节）。

### 4.3 网络级 FFN 裁剪流程

作者从头训练 GPT-2 125M，使用 CodeParrot 的 2.1B 个训练 token、上下文窗口 128。先删除所有 FFN 的 GeLU，再把 up-projection 与 down-projection 合并为一个线性层；随后在 Orion 下测量每层延迟和困惑度。图 3 还逐层保留一个 GeLU，用于观察合并线性 FFN 是否造成额外损失。

### 4.4 自注意力与 roofline 流程

自注意力矩阵乘法采用方形、边长为 2 的幂且不超过 128 的矩阵，将整矩阵按 row-major 放进一个 CKKS ciphertext。roofline 实验使用 OpenFHE 后端、48 个线程、2.4 GHz 最大核心频率、禁用 OpenFHE 向量化，环多项式次数 N=2^16、槽位数 n=2^15；使用 Intel PIN 统计整数操作，用硬件性能计数器统计 DRAM 流量。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数。论文也没有提出新的通用训练损失；FFN 裁剪实验报告的是语言模型困惑度。

### 5.1 BSGS 的旋转规模

矩阵-向量乘法把 n 分解为 n1×n2，其中 n1≈n2≈sqrt(n)。BSGS 将旋转分成 baby steps 与 giant steps，把所需不同旋转和旋转密钥从 O(n) 降到 O(sqrt(n))；论文用预旋转的明文对角线减少运行期代价。该关系是算法复杂度描述，不是学习目标。

### 5.2 FFN 合并

当移除 GeLU 后，两个线性层可合并：

```text
W_ffn = W1 × W2
```

其中 W1 的形状为 768×3072，W2 的形状为 3072×768，合并矩阵 W_ffn 的形状为 768×768。这样 FFN FLOPs 从 14.5B 降到 1.8B（表 II，针对论文的 GPT-2 实验设置）。

### 5.3 Roofline 算术强度

论文将算术强度改写为：

```text
Arithmetic intensity = 64-bit integer operations / DRAM traffic in bytes
```

整数操作包括通用寄存器上的 64 位 ADD、SUB、MUL、DIV，不包括栈操作和立即数。数值越低，越可能受到内存带宽限制；论文测得 FHE 原语约为 0.1 integer operations/byte，并据此认为替换编码方案和计算模型比单纯增加计算资源更值得研究。

## 6. 实验设置

### 6.1 数据集来源

FFN 裁剪/合并实验使用 CodeParrot 数据集的 2.1B 个训练 token，作者从头训练 GPT-2 125M，context window 为 128。论文没有给出该实验独立的训练集、验证集和测试集划分比例，数据清洗细节也未说明。其余内核实验主要使用 GPT-2 small、Phi-3 mini 和 Llama 3 8B 的 Transformer 尺寸与权重形状，不是报告一个新的数据集。

论文讨论的是 GPT-2 等语言模型的 FHE 推理，核心数据表示是 CKKS 的密文/明文向量和矩阵。论文中未明确说明训练数据存在何种去重或数据泄漏检查；因此不能把 2.1B token 解释成完整的数据集规模或严格的泛化评测。

### 6.2 模型与工具

| 项目 | 论文设置 |
| --- | --- |
| Transformer | GPT-2 small、Phi-3 mini、Llama 3 8B 的 FFN 尺寸；GPT-2 裁剪实验为 125M |
| FHE/编译框架 | Orion；论文说明其直接运行 PyTorch 网络并自动管理层级/尺度与 bootstrapping |
| 密码方案 | CKKS；典型说明中 N=2^16、n=2^15，Q 约 1500 bits |
| 密码后端 | OpenFHE，用于 roofline 原语测量 |
| 二进制动态分析 | Intel PIN，用于统计 64 位整数操作 |
| 线程/频率 | 48 threads；最大核心频率 2.4 GHz |
| 代码 | 论文给出 Orion 项目地址：`https://github.com/baahl-nyu/orion` |
| LLVM/GCC/RISC-V | 论文中未使用或未明确说明 |

### 6.3 对比方法

主要对比是 packed row 与 Double-Hoisted BSGS 矩阵-向量算法；网络级对比是带 GeLU 的原始 FFN、删除 GeLU 但不合并的线性 FFN、删除 GeLU 且合并投影的线性 FFN。矩阵-矩阵部分主要是论文实现的 row-packing 外积算法，不是与多个独立编译器 baseline 的对比。

### 6.4 评价指标

| 指标 | 含义 | 趋势 |
| --- | --- | --- |
| FHE latency | 单层或单内核密文计算延迟，单位秒 | 越小越好 |
| Speedup | 一种内核相对于另一种内核的延迟比 | 越大越好 |
| Perplexity | 语言模型困惑度，用于衡量 FFN 裁剪的语言建模损失 | 越小越好 |
| FFN FLOPs | FFN 浮点运算量估计 | 越小通常越好，但不等同于 FHE 延迟 |
| Multiplicative level | CKKS 可用乘法层级 | 消耗越少越容易避免 bootstrapping |
| Arithmetic intensity | 64 位整数操作数/DRAM 字节数 | 高通常更接近计算受限 |

## 7. 实验结果与结论

### 7.1 主要结果

在 Transformer 尺寸的明文-密文矩阵-向量乘法上，BSGS 在所有图 2 设置中优于 packed row；随着矩阵变大，优势扩大。论文报告最高可达 13.7×。Llama 3 FFN 层的旋转数从 row 方法的 24579 降至 BSGS 的 272，解释了规模扩大时的优势。

FFN 表 II 的三项结果如下，均为论文的 GPT-2 125M/Orion 设置：带 GeLU 的 FFN 困惑度 2.688、14.5B FFN FLOPs、62.21 s；去掉 GeLU 后困惑度 3.376、FLOPs 仍为 14.5B、14.86 s；去掉 GeLU 并合并两层后困惑度 3.342、1.8B FLOPs、5.43 s。与带 GeLU 的配置相比，最终合并配置的延迟约降低 11.46×，但困惑度升高。

### 7.2 与传统编译/算法方法的比较

论文不是与 GCC、LLVM pass 或传统 autotuner 比较，而是比较 CKKS 中两种矩阵-向量布局/算法。其结论是：在需要较少乘法层级和旋转密钥的场景，BSGS 更适合 Transformer 尺寸的线性变换；row 方法的优势主要是旋转种类简单且可使用幂-2 旋转键，但旋转次数随矩阵规模增长较差。

### 7.3 与其他 FHE 编译器/框架的关系

相关工作回顾 Chet、Porcupine、EVA、nGraph-HE、TenSEAL、DaCapo、HeLayers 和 Orion。本文实验主要在 Orion 内完成，未给出将相同内核在所有这些框架上重新实现后的统一数值对比，因此不能把 13.7× 或 11.46× 外推为相对于全部 FHE 编译器的优势。

### 7.4 消融与层级实验

图 3 逐层只保留一个 GeLU，并对其他线性 FFN 做合并；结果显示合并线性 FFN不会带来额外困惑度损失，和表 II 中“去 GeLU”后再合并的观察一致。图 5 在矩阵维度 4、8、16、32、64、128 和不同输入层级下测试密文-密文矩阵乘法；对于 GPT-2 context length 64，矩阵乘法延迟在 67.2 到 172.2 s 之间，取决于输入层级。

### 7.5 Roofline 结果

论文在图 6 中分别测量密文-密文加法、带 relinearization 的密文-密文乘法和密文旋转。三类原语都主要受内存带宽限制，而且乘法层级增加时算术强度下降。作者报告约 0.1 integer operations/byte 的量级，认为 key-switching 是乘法与旋转中最耗时、最耗内存的部分。

## 8. 主要创新点

### 8.1 创新点一：在 Orion 中系统比较 packed row 与 BSGS

作者把两种明文-密文矩阵-向量实现直接集成到 Orion，并针对 Transformer 规模给出测量。价值不在“使用 FHE”本身，而在把 CKKS 的打包、旋转密钥、乘法层级与实际 FFN 尺寸关联起来。图 2 和旋转计数支持 BSGS 的规模优势。

### 8.2 创新点二：网络级 GeLU 裁剪与投影合并的 FHE 评估

论文将网络结构修改和 FHE 编译成本放到同一实验中：删除 GeLU 去除 bootstrapping 需求，再合并两个线性投影。表 II 表明这一步同时减少延迟和 FLOPs，但会增加困惑度；因此它是隐私推理场景的精度-延迟权衡，而非无损优化。

### 8.3 创新点三：密文-密文矩阵-矩阵乘法实现与 FHE roofline

论文实现了自注意力 QK^T 所需的通用 row-packing 外积算法，并进一步用面向 FHE 的整数操作/字节 roofline 指标定位瓶颈。该方法把编译器内核、密码学操作和内存系统联系起来，为后续编码方案优化提供依据。

## 9. 局限性

### 9.1 论文明确或实验范围体现的局限

* 论文主要在 Orion、CKKS 和 OpenFHE 环境下验证，未证明结论适用于所有 FHE 编译器、编码方案或密码后端。
* FFN 裁剪实验使用 GPT-2 125M 与 CodeParrot；论文没有报告更大规模完整模型的端到端困惑度和吞吐结果。
* FHE 延迟达到秒到分钟级；论文展示了内核与单层结果，但不是完整生产服务的端到端交互延迟。
* 去除 GeLU 会造成困惑度从 2.688 增至 3.376，合并后为 3.342；因此网络级简化不是无损变换。
* 密文-密文矩阵乘法实验限制矩阵为方形、边长为 2 的幂且不超过 128，并要求矩阵装入单个 ciphertext，适用范围有限。
* 论文没有使用 LLVM、MLIR、RISC-V 后端或硬件实测；其“compiler”是 FHE/张量编译框架语境，不能直接理解为通用 CPU 编译器优化。

### 9.2 阅读后的潜在局限

* roofline 实验禁用了 OpenFHE 向量化，并固定 48 线程与 2.4 GHz；这有利于控制实验变量，但可能改变真实部署中的瓶颈比例。
* 论文没有给出完整的训练/验证/测试切分、重复实验置信区间或统计显著性；图 2 和表 II 说明部分结果平均 3 次，但不能据此推出所有测量都有相同统计保证。
* FFN 结构修改可能改变模型表达能力，论文提出蒸馏或熵正则化可缓解，但这些方法没有在本文中作为完整实验主线验证。
* 论文中“13.7×”和“11.46×”分别对应内核算法与 FFN 配置，不应混为同一种 speedup，也不应解释成真实硬件加速器的固定收益。

## 10. 阅读后的研究方向反思

### 10.1 值得借鉴的思想

最值得借鉴的是把程序表示、数据布局、编译器插入的运行时操作和硬件内存行为一起测量。论文没有只报告 FLOPs，而是分析旋转密钥、乘法层级、bootstrapping 和 DRAM 流量，这种“语义/代价/系统瓶颈”联动对 LLVM、MLIR 或 RISC-V 代价模型研究有参考价值。

### 10.2 不能直接照搬的部分

不能只把 OpenFHE 替换成 RISC-V 指令集就声称形成新工作。本文的关键约束来自 CKKS 密文操作和 key-switching；RISC-V 迁移需要重新定义目标指令、寄存器/缓存代价、向量扩展或专用指令，并证明密文语义和数值误差保持一致。

### 10.3 与当前研究方向的关系

与 LLVM/MLIR 的关系是编译器 IR、张量布局、算子融合和成本模型；与 RISC-V 的关系较弱且是潜在迁移方向，不是论文已验证的硬件平台。它更适合作为“FHE 编译器内核与代价分析”的方法参考或 baseline，而不是 RISC-V 代码生成 baseline。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V 向量扩展的 FHE 内核成本模型

#### 研究问题

在保持 CKKS 数值与密文安全约束的前提下，RISC-V V 扩展、缓存层级和专用 key-switching 指令如何改变 row/BSGS 的最优选择？

#### 与原论文的区别

不是把平台名称替换成 RISC-V，而是建立从 CKKS 操作到 RVV 指令、向量长度、内存访问和旋转密钥缓存的可解释成本模型。

#### 可能的创新点

对旋转、模乘、relinearization 分别建模，并联合选择数据布局与向量化策略。

#### 实验框架

```text
CKKS 内核图 → RVV/专用指令映射 → cycle/cache 模型 → row/BSGS 搜索 → FPGA/仿真验证
```

#### 可行性

需要 LLVM/RISC-V 后端或自定义 intrinsic、OpenFHE/Orion 内核、Spike/QEMU 或 FPGA 原型。

#### 主要风险

仿真周期不等于真实 FHE 芯片延迟；密钥存储、侧信道和大整数实现可能成为主要误差源。

### 11.2 MLIR 中的 FHE 方言与可验证算子融合

#### 研究问题

如何在 MLIR 中表示 CKKS 层级、尺度、旋转键和 bootstrapping 约束，并自动寻找安全的线性层融合？

#### 与原论文的区别

将 Orion 的框架级自动处理抽象为可检查的 IR 属性和 pass，而不是只在 Python/PyTorch API 层实现。

#### 可能的创新点

设计乘法层级/尺度的类型或 effect 系统，在优化前后检查数值误差与密文可解密性。

#### 实验框架

```text
PyTorch 图 → FHE MLIR 方言 → 布局/融合 pass → CKKS lowering → OpenFHE 执行与误差检查
```

#### 可行性

需要 MLIR dialect/pass 开发、CKKS 后端和 Orion/OpenFHE 对照实现。

#### 主要风险

形式化类型约束可能过于保守；近似数值误差不能仅靠语法类型保证。

### 11.3 误差约束下的 FFN 结构搜索

#### 研究问题

能否在困惑度、FHE 延迟、bootstrapping 次数和内存峰值之间进行多目标搜索，而不是固定删除全部 GeLU？

#### 与原论文的区别

本文只比较少数人工配置；新方向搜索每层是否保留激活、是否合并投影以及不同多项式近似阶数。

#### 可能的创新点

把语言质量约束和 FHE 代价联合起来，并用真实或校准的 CKKS 代价反馈驱动搜索。

#### 实验框架

```text
候选 FFN 结构 → 快速语言质量估计 + FHE 成本估计 → Pareto 筛选 → Orion/OpenFHE 复测
```

#### 可行性

可复用 CodeParrot、GPT-2 和 Orion；不需要把 LLM 当作生成器。

#### 主要风险

小规模困惑度不一定预测下游任务质量；FHE 成本估计可能被实际密钥与内存行为偏离。

## 12. 与其他已读文献的关系

本 slot-3 本轮只完成这一篇 ICCAD 2025 论文，因此没有第二篇“当前批次已读论文”可作事实横向比较。与正式 corpus 中已有的 ICCAD 2025 条目 CIDRE 和 VeriRL 的关系只能作范围区分：CIDRE 研究 RISC-V 自定义指令设计，VeriRL 研究 Verilog 代码生成强化学习；本文研究 FHE Transformer 的编译/内核优化，三者题名、DOI、方法和研究对象均不同，本次按 DOI、规范化题名和 arXiv/正式记录检查后未发现重复。

本文可作为 FHE 编译器/隐私推理的 supporting baseline；若后续研究 RISC-V 后端，可借鉴其内核代价与内存分析，但不能把它当作已完成的 RISC-V 编译器论文。

## 13. 一页式总结

| 项目 | 内容 |
| --- | --- |
| 论文研究任务 | 优化 FHE 私有 Transformer 推理中的线性代数内核 |
| 核心问题 | CKKS 受限操作、bootstrapping 和内存带宽造成高延迟 |
| 输入 | PyTorch Transformer、明文权重、密文向量/矩阵 |
| 输出 | Orion/OpenFHE 上的优化 FHE 内核和延迟分析 |
| 核心方法 | packed row vs. BSGS、GeLU 裁剪、FFN 合并、密文矩阵乘法、roofline |
| 使用的模型 | GPT-2 small/125M、Phi-3 mini、Llama 3 8B 尺寸 |
| 使用的编译器工具 | Orion；后端 OpenFHE；Intel PIN 做动态计数 |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 否；实验测量不等于形式化证明 |
| 数据集规模 | CodeParrot 训练 token 2.1B；context window 128；划分未说明 |
| 主要指标 | FHE latency、speedup、perplexity、FFN FLOPs、乘法层级、算术强度 |
| 最重要实验结果 | BSGS 最多优于 packed row 13.7×；FFN GeLU 去除并合并后延迟 62.21 s 降至 5.43 s，困惑度 2.688 变为 3.342 |
| 核心创新 | 将打包算法、网络级简化和 FHE roofline 放在统一评测中 |
| 主要局限 | 强依赖 CKKS/Orion/OpenFHE，模型与矩阵范围有限，未验证 LLVM/RISC-V |
| 与 RISC-V 研究的相关性 | 中低：提供成本模型和内存分析启发，但没有 RISC-V 实验 |
| 最适合作为 | FHE 编译器方法参考、隐私推理内核 baseline、代价模型素材 |

> 这篇论文最值得学习的是把 FHE 编译器操作、网络结构和内存系统放在同一条性能链路中分析；最主要的局限是结论依赖 CKKS/Orion/OpenFHE 且没有 RISC-V 或通用 LLVM 后端验证；如果用于后续研究，最合理的使用方式是作为 FHE 内核与代价模型 baseline，而不是简单地把平台名称替换为 RISC-V。
