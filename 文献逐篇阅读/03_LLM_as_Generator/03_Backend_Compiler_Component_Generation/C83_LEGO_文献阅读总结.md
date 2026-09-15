# LEGO 文献阅读总结

论文题目：**LEGO: A Layout Expression Language for Code Generation of Hierarchical Mapping**

作者：Amir Mohammad Tavakkoli、Cosmin E. Oancea、Mary Hall

发表时间：2026

发表平台：2026 IEEE/ACM International Symposium on Code Generation and Optimization（CGO 2026）主会，pp. 228–241

论文链接或编号：[DOI 10.1109/CGO68049.2026.11394846](https://doi.org/10.1109/CGO68049.2026.11394846)；作者公开 PDF：[LEGO-CGO26.pdf](https://users.cs.utah.edu/~tavak/assets/pdf/LEGO-CGO26.pdf)

关键词：data layout、MLIR compiler、GPU code generation、hierarchical mapping、Triton、CUDA、symbolic simplification

建议分类：`GENERATOR / G3_Backend_Compiler_Component_Generation`。论文最终产物是可复用的布局代数、索引映射与代码生成组件，不是由语言模型选择 pass 或直接改写程序。

> 本笔记事实均依据本地 PDF 正文；关键数字注明论文章节、图或表。阅读后的分析与论文事实分开书写。

---

## 1. 研究背景

论文研究 GPU 和异构编译中的数据布局、线程布局与代码生成。引言指出，在摩尔定律和 Dennard scaling 不再持续提供性能增益后，架构专用化和领域专用编程系统成为重要方向；数据移动可能成为执行时间和能耗的主要成本，因此需要通过布局、分块和内存层次优化减少数据移动（第 1 节）。

传统方法包括循环变换、tiling、unroll-and-jam、多面体编译，以及 Triton、CuTe、Graphene 等面向 GPU 的布局/数据移动抽象。论文认为，现有布局表达常要求程序员显式写 stride、低层索引算术或线性矩阵，表达复杂层次布局时容易出错，并且一些系统只支持线性或规则的布局（第 1、2 节）。

论文因此提出一个独立于具体编译器的布局抽象，自动从高层布局规格推导索引表达式，再接入 Triton、CUDA 模板和 MLIR。论文不以 LLM、强化学习或训练模型为方法核心。

## 2. 论文要解决的问题

### 2.1 复杂层次布局的高层表达

程序员需要表达逻辑索引空间、层次 tile、线程块布局和数据布局的组合关系，同时避免手工推导多层 reshape、permute 和 stride 计算（第 2 节）。

### 2.2 布局到索引表达式的自动推导

系统应从布局描述自动生成 `apply` 和 `inv` 映射，使逻辑索引能够映射到物理位置，反向映射也能恢复逻辑坐标（第 3 节）。

### 2.3 对不规则和非线性布局的支持

论文希望超越仅支持规则、矩形、显式 stride 的布局，支持用户定义的双射，例如 anti-diagonal 和 brick 布局；同时还讨论非整除 tile 的 partial tile 和有限的 injective mapping 支持（第 3-C、3-D 节）。

### 2.4 与现有代码生成生态的集成

布局抽象需要能落到 Triton、CUDA 和 MLIR，而不是停留在独立的数学表示（第 4 节）。

> 本文主要研究：如何用一个可组合的布局代数，从高层层次布局规格自动生成索引和 GPU/MLIR 代码，以减少数据移动并保留性能。

## 3. 核心方法概述

LEGO 将数据布局提升为一等抽象。用户先定义逻辑索引空间，再用 `GroupBy` 表示层次 tile，用 `OrderBy` 表示每层的规则或用户定义重排。系统通过规范双射把多维索引空间和一维物理位置连接起来，自动生成 `apply`/`inv`，并把结果注入代码模板或 MLIR 方言。

```text
逻辑索引空间与计算/数据布局规格
        ↓
GroupBy + OrderBy + RegP/GenP 组成布局代数
        ↓
自动推导 apply / inv 双射与维度信息
        ↓
SymPy 符号化索引表达式与范围传播
        ↓
Z3 检查整除、非负性和上界等简化条件
        ↓
注入 Triton/CUDA 模板，或生成 MLIR arith/affine/memref/vector/gpu 代码
        ↓
在 GPU 上执行并比较性能、吞吐和代码生成开销
```

LEGO 的两个基本接口是：`apply` 将逻辑多维索引映射到重排后的平坦物理位置；`inv` 将物理位置映射回逻辑索引。`RegP` 表示维度置换，`GenP` 表示用户提供的规则或不规则映射。论文的算法正确性依赖用户提供的 `GenP` 逆函数确实是双射逆函数，并要求 `GroupBy` 与各级 `OrderBy` 的元素总数一致（第 3-B 节）。

与 Triton 示例相比，论文第 2 节和图 1 报告：一个矩阵乘法布局示例中的用户显式算术操作数量从 31 减少到 9。这里是输入规格复杂度的减少，不表示所有程序都固定减少相同数量的运行时指令。

## 4. 实验框架与训练流程

本文不涉及模型训练、SFT、PPO、GRPO 或强化学习，主要采用静态布局描述、符号表达式生成和运行时性能评测。

### 4.1 布局规格与语义

第 3 节用 `GroupBy`、`OrderBy`、`RegP`、`GenP` 和 `ExpandBy` 定义层次布局。`GroupBy` 先把逻辑空间 reshape 成多级 tile；`OrderBy` 再在各级应用规则或用户定义的重排；`ExpandBy` 用于不能整除 tile 大小的 partial tile。

### 4.2 索引表达式生成与简化

第 4-A 节描述了模板实例化流程：用户提供含 Jinja2 `{{ }}` 占位符的 Triton/CUDA 模板，LEGO 生成索引表达式并替换占位符。实现接入 SymPy，并额外传播布局范围；论文表 II 给出 7 条整数除法和取模简化规则。规则的侧条件由 Z3 SMT solver 使用布局推导出的索引范围检查。论文还用一个简单代价模型比较展开与未展开表达式，选择操作数更少的版本；NW 采用未展开形式，LUD 采用展开形式（第 4-A 节）。

### 4.3 MLIR 集成

第 4-B 节通过 MLIR Python bindings 生成代码，使用 `arith`、`affine`、`memref`、`vector` 和 `gpu` 方言表达算术、控制流、内存、向量和 GPU 操作。生成的单个 MLIR 文件同时包含布局信息和计算代码。

### 4.4 推理/运行阶段

实验阶段将生成的 Triton、CUDA 或 MLIR 代码编译后在 NVIDIA A100 80GB GPU 上执行。每个 benchmark 先 warm-up 25 次，再收集 100 次运行结果并报告均值（第 5 节）。

## 5. 奖励函数、损失函数或关键公式

本文没有使用强化学习，因此不存在强化学习奖励函数，也没有神经网络训练损失。

### 5.1 层次元素数约束

第 3-A 节用下式表示 q 层、d 维 tile 的总元素数：

```text
N = (n1_1 × ... × n1_d) × ... × (nq_1 × ... × nq_d)
```

它要求层次 tile 的元素总数与逻辑空间一致。

### 5.2 逻辑到物理位置的映射

论文第 3-A、3-B 节通过规范双射 `B` 和 `B^-1` 组合 reshape 与重排。其核心含义是：先将逻辑多维索引展平，再在层次 tile 空间中重排，最后获得物理平坦位置；`inv` 按相反顺序恢复逻辑坐标。该组合在 `GenP` 确实为双射且各空间元素数相等时构成双射。

### 5.3 表达式选择目标

第 4-A 节没有定义学习式损失，而是用生成表达式中的操作数数量作简单代价，比较预展开和未展开版本，选择操作数计数更低的表达式。该代价模型只服务于索引表达式简化，不是硬件真实性能模型。

## 6. 实验设置

### 6.1 数据集来源

本文没有传统训练/验证/测试数据集。实验使用 5 个来自官方 Triton repository 的 benchmark：Grouped GEMM、LayerNorm Forward、LayerNorm Backward、Softmax 和 FP16 Matrix Multiplication（第 5-A 节）。CUDA 实验使用 Rodinia 中的 NW、LUD，并使用 brick 数据布局的 3D stencil；MLIR 实验使用 2D transpose（第 5-B、5-C 节）。

### 6.2 模型与工具

论文正文第 5 节和附录给出的环境包括：

| 项目 | 设置 |
|---|---|
| GPU | NVIDIA Ampere A100 80GB |
| CPU | AMD EPYC 7513，32 cores |
| 操作系统 | CentOS |
| LLVM | commit `556ec4a` |
| Triton | 3.2.0 |
| PyTorch | 2.5.1 |
| CUDA | 12.4 |
| Python | 3.12.4 |
| MLIR | 构建 LLVM commit `556ec4a` 中的 MLIR，目标包含 X86 和 NVPTX |
| 运行统计 | warm-up 25 次，采样 100 次，报告均值 |

附录还列出 Ninja 1.12.1、CMake 3.26.5 和 GCC 11.2.0。作者提供了 artifact DOI `10.5281/zenodo.17633994`；附录报告预计需要约 40 GB 磁盘、约 2 小时准备和约 1.5 小时实验执行。

### 6.3 对比方法

* Triton benchmark：与官方 Triton repository 实现比较。
* PyTorch：矩阵乘法等场景通过 CUDA backend/cuBLAS 比较。
* CUDA：NW、LUD 和 stencil 与 Rodinia/原始布局实现比较。
* MLIR transpose：与 NVIDIA CUDA SDK、使用 `nvcc` 编译的 baseline 比较。
* 布局代数：正文还在表达层面与 CuTe/Graphene shape algebra 比较，重点是是否需要显式 stride，以及能否表达非线性布局；这不是完全相同的端到端运行基线。

### 6.4 评价指标

| 指标 | 含义 | 方向 |
|---|---|---|
| 运行性能/吞吐 | GPU benchmark 的执行性能；transpose 以 GB/s 表示 | 越大越好 |
| Speedup | 相对原始或 baseline 实现的加速比 | 越大越好 |
| Generation time | 每个应用一次性代码生成与简化耗时 | 越小越好 |
| Arithmetic ops | 生成前后用户代码中的算术操作数量 | 通常越小越好 |

## 7. 实验结果与结论

### 7.1 主要结果

第 5 节将评测分为 Triton、CUDA 和 MLIR 三类。实验整体说明 LEGO 可生成与 Triton 接近的性能，并能通过布局变化减少共享内存 bank conflict、实现 thread coarsening 或改善 stencil 数据局部性。

### 7.2 生成开销

表 III 报告在 Apple M2 Max 笔记本上的一次性代码生成和简化时间：LayerNorm FWD+BWD 为 0.33 s，Grouped GEMM 为 0.65 s，Softmax 为 0.05 s，Matmul 每个变体为 1.11 s，LUD 为 0.87 s，NW 为 0.46 s，Bricks 的 Cube/Star 为 5.95/18.07 s，Transpose 的 Naive/SMEM 为 1.07/1.15 s。论文强调这一开销只属于索引生成，不影响稳态执行（第 5 节表 III）。

### 7.3 Triton 结果

第 5-A 节图 11 在三个问题规模上比较 LEGO、Triton 与 PyTorch。作者报告 LEGO 与 Triton 整体性能几乎相同；2k 规模上 PyTorch/cuBLAS 多数 benchmark 更快，但规模增大后 LEGO 生成的代码可充分利用 tensor cores。表 IV 报告用户侧算术操作由 LayerNorm FWD 的 6→1、LayerNorm BWD 的 4→0、Softmax 的 4→0、Grouped GEMM 的 20→6、Matmul 的 31→9 减少。

### 7.4 CUDA 结果

* NW：通过 anti-diagonal 共享内存布局减少 bank conflict 和 warp stalls，相比 baseline 的性能提升范围为 1.4×–2.1×（第 5-B 节、图 12a）。
* LUD：将 thread coarsening 重述为布局优化；最佳配置使用逻辑 LUD block 64×64、coarsening factor 4，同时保持 CUDA block 为 16×16，以增加每个线程块的工作量并改善 block-level parallelism（第 5-B 节、图 12b）。
* Stencil：使用 3D brick 布局替代常规 row-major 布局，在 27-point、125-point cube 及 7/13/19/27-point star stencil 上，论文报告仅改变数据布局即可获得 3.4×–3.9× speedup（第 5-B 节、图 12c 和图 13b）。

### 7.5 MLIR 结果

表 V 用 GB/s 比较 CUDA SDK 与 LEGO-MLIR 的 2D transpose。Naive 配置在尺寸 2048/4096/8192 上分别为 CUDA SDK 212.0/175.8/175.4、LEGO-MLIR 206.8/178.0/190.7；Smem+Coalesced 配置分别为 CUDA SDK 670.0/718.2/735.7、LEGO-MLIR 681.7/741.2/759.4。作者据此认为两种编译框架性能可比，LEGO 在生成线性化数组访问时略有优势（第 5-C 节表 V）。

### 7.6 消融与案例

论文没有神经网络模块消融。与布局表达相关的案例包括图 2 的层次 reshape/permute、图 7 的 anti-diagonal、图 8 的二维非连续布局和表 I 的 Triton/CUDA/MLIR 布局规格。表达式展开选择在 NW 与 LUD 上给出相反偏好，说明索引简化的最佳形式依赖具体表达式和应用。

## 8. 主要创新点

### 8.1 创新点一：统一的层次布局代数

LEGO 用 `GroupBy`、`OrderBy`、`RegP` 和 `GenP` 统一表达逻辑空间、层次 tile、规则置换和用户定义双射。相较需要显式 stride 的 CuTe/Graphene 形式，它从层次规格内部推导 stride 和索引。

### 8.2 创新点二：支持任意用户定义双射的索引生成

只要用户提供映射及其逆函数，LEGO 可以表达 anti-diagonal、brick 等超出规则矩形 stride 的布局。论文的价值在于将这类映射接入统一 `apply`/`inv` 语义，而不是仅展示某一个手写优化案例。

### 8.3 创新点三：面向多生态的代码生成集成

论文展示同一布局抽象如何注入 Triton/CUDA 模板，并通过 MLIR Python bindings 生成 MLIR。MLIR 集成使用多个标准方言，说明该组件可以作为领域专用编译器的布局基础设施。

### 8.4 创新点四：带范围约束的符号简化

LEGO 将布局推导的索引范围传入 SymPy，并用 Z3 检查整数除法、取模简化的侧条件。该机制把布局语义和索引表达式优化连接起来，减少手工索引算术。

## 9. 局限性

### 9.1 论文明确承认或说明的局限

* `GenP` 的双射及其逆函数正确性由用户负责；系统的构造正确性依赖这个前提（第 3-B 节）。
* 非双射支持有限。`ExpandBy` 支持 partial tile；injective mapping 只允许特定使用方式，并且仅导出 `apply`，论文评测重点仍是双射布局（第 3-D 节）。
* MLIR 集成目前是展示性实现；与更多 dialect 的集成留作未来工作（第 4-B 节）。
* 论文未来工作是继续探索更多布局和系统集成，并未声称覆盖所有 GPU 或异构架构（第 7 节）。

### 9.2 阅读后的潜在局限

* 主要端到端实验集中在 NVIDIA A100、Triton、CUDA 和 MLIR GPU 路径，不能直接推出 RISC-V、CPU 或其他 GPU 后端同样的性能。
* 3.4×–3.9× 等结果来自特定 stencil 与布局 baseline；不能解释为布局代数在所有程序上的固定收益。
* `Generation time` 是一次性索引生成和简化开销，不是真实硬件执行时间；表 III 不能替代完整编译流水线成本分析。
* 性能选择使用操作数计数的简单代价模型，论文未证明该计数在不同 GPU 架构上总能预测最佳运行时间。
* 论文比较了若干代表性 benchmark，但没有提供跨多种 GPU、跨 ISA 或大规模应用程序集的系统性迁移实验。

## 10. 阅读后的研究方向反思

LEGO 最适合作为 GENERATOR 类的布局/后端代码生成组件或 baseline。值得借鉴的是把数据布局、线程布局和索引生成分离，并通过 `apply`/`inv` 接口把高层规格连接到具体代码。不能简单照搬的是 NVIDIA GPU、Triton 或 A100 的布局经验；若只把 CUDA 后端替换成 RISC-V，主要属于平台迁移，不足以单独形成新贡献。

对于 RISC-V 研究，较有价值的结合点是：保留布局代数和可验证索引生成，将物理布局与 RVV 向量长度、LMUL、缓存层次或自定义矩阵扩展的代价模型相连。这样研究问题从“换一个目标后端”升级为“布局表达如何驱动跨 ISA 代码生成与硬件条件选择”。论文使用 Z3 检查简化侧条件，也可作为索引等价性/边界正确性检查模块，但不能把它扩大为完整程序语义验证。

## 11. 可进一步尝试的研究方向

### 11.1 面向 RISC-V RVV 的布局—向量映射生成

#### 研究问题

如何将 LEGO 的层次布局映射到 RVV 的 vector length、LMUL、分块和尾部处理策略，并保持索引和边界正确。

#### 与原论文的区别

不只替换目标 ISA，而是引入 RVV 硬件参数和向量化约束，研究布局—向量配置的联合生成。

#### 可能的创新点

增加 RVV-specific layout primitives、尾部 mask 规则和基于实测性能的代价模型。

#### 实验框架

```text
LEGO 布局规格 + RVV 硬件参数
        ↓
生成 RVV-friendly 分块、索引和 mask
        ↓
LLVM/MLIR lowering
        ↓
Spike/QEMU 或真实 RVV 平台验证正确性与性能
```

#### 可行性

需要 MLIR/LLVM RVV 后端、仿真器或真实开发板，以及矩阵/ stencil/向量 benchmark。

#### 主要风险

仿真器性能与真实硬件不一致；不同 VLEN/LMUL 的最优布局可能不稳定。

### 11.2 布局双射的自动验证与反例生成

#### 研究问题

如何自动检查用户 `GenP` 与逆函数是否真的是双射，并在失败时生成最小索引反例。

#### 与原论文的区别

原论文把 `GenP` 双射责任留给用户；该方向把这一前提变成显式的验证和诊断能力。

#### 可能的创新点

组合 SMT 约束、范围分析和随机差分测试，覆盖 `apply(inv(x))=x` 与 `inv(apply(i))=i` 两个方向。

#### 实验框架

```text
布局规格
   ↓
生成 apply/inv 约束
   ↓
SMT 证明或产生反例
   ↓
将通过的布局交给 CUDA/MLIR/RVV 代码生成
```

#### 可行性

可以复用论文已有的 SymPy、Z3 和布局语义；不需要训练模型。

#### 主要风险

用户定义的非线性函数可能使 SMT 求解昂贵；有限测试不能替代完整证明。

### 11.3 跨硬件布局代价模型

#### 研究问题

同一逻辑计算在 A100、RISC-V 向量处理器和其他 GPU 上如何选择不同数据/线程布局。

#### 与原论文的区别

从论文的表达式操作数代价扩展到包含 bank conflict、cache locality、向量利用率、访存吞吐的跨硬件代价模型。

#### 可能的创新点

统一布局表示、硬件特征和测量反馈，支持静态筛选与少量实测校准。

#### 实验框架

```text
逻辑程序 + 候选布局集合
        ↓
静态特征/合法性过滤
        ↓
跨硬件代价模型排序
        ↓
Triton/CUDA/MLIR/RVV 生成与实测
        ↓
更新代价模型并比较迁移效果
```

#### 可行性

需要多硬件 benchmark、统一计时口径和后端代码生成支持。

#### 主要风险

测量成本高；模型可能过拟合 A100 或某一类布局。

## 12. 与其他已读文献的关系

本槽位只完整处理 LEGO 一篇论文，因此没有同批次可用于事实级横向比较的已读论文。与仓库中已有条目的关系仅作分类层面的去重判断：它与 MLIR、自动调优和 GPU 布局方向存在主题交集，但不是已占用的 MLIR RL、稀疏自动调度或 RISC-V 后端论文的版本关系；DOI、规范化题名和正文主题均独立。

从研究角色看，LEGO 更适合作为可复用的 `GENERATOR/G3` 后端/代码生成模块；它不是 `SELECTOR`，因为没有输出 pass/phase 选择策略，也不是 `TRANSLATOR`，因为论文系统输出的是索引与代码生成能力，而非以语言模型为核心的源程序或 IR 翻译。

## 13. 一页式总结

| 项目 | 内容 |
|---|---|
| 论文研究任务 | 用层次布局代数生成 GPU/MLIR 索引与代码 |
| 核心问题 | 手工 stride 和复杂索引难写、难复用、难扩展到不规则布局 |
| 输入 | 逻辑索引空间、tile 层次、线程/数据布局、代码模板或 MLIR 计算 |
| 输出 | `apply`/`inv` 映射、简化索引表达式、Triton/CUDA/MLIR 代码 |
| 核心方法 | `GroupBy`、`OrderBy`、`RegP`、`GenP`、`ExpandBy` 与符号简化 |
| 使用的模型 | 无机器学习模型；无 LLM |
| 使用的编译器工具 | SymPy、Z3、Triton、CUDA、LLVM/MLIR |
| 是否使用强化学习 | 否 |
| 是否使用形式化验证 | 使用 Z3 检查简化侧条件；布局双射前提部分由用户负责，不是完整程序语义证明 |
| 数据集规模 | 无训练数据集；使用 Triton、Rodinia 和 transpose benchmark |
| 主要指标 | 生成时间、算术操作数、GPU speedup、GB/s throughput |
| 最重要实验结果 | Triton 性能近似；NW 1.4×–2.1×；stencil 3.4×–3.9×；MLIR transpose 与 CUDA SDK 可比 |
| 核心创新 | 无显式 stride 的层次布局表达、任意双射布局、跨 Triton/CUDA/MLIR 集成 |
| 主要局限 | 用户负责 `GenP` 双射；非双射和更多 dialect 支持有限；硬件覆盖集中于 A100 |
| 与 RISC-V 研究的相关性 | 中：布局代数和验证可迁移，但正文没有 RISC-V 实验，需重新建立 RVV 后端与代价模型 |
| 最适合作为 | GENERATOR 类的布局/代码生成模块与 GPU 编译 baseline |

> 这篇论文最值得学习的是把复杂数据/线程布局从手工索引算术提升为可组合、可生成的编译器抽象；最主要的局限是双射前提依赖用户、跨硬件证据有限。如果用于后续研究，合理方式是把它作为布局生成与索引验证底座，再加入 RVV 或多硬件代价模型，而不是简单替换目标 ISA。
