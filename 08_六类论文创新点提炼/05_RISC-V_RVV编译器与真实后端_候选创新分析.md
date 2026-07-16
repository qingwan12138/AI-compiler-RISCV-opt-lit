# 类别五：RISC-V/RVV 编译器与真实后端——候选创新点分析

> 文献数量：2024–2026 年独立条目 8；其中 2 份源材料受限
> 完整阅读数量：8 份新文献总结；另读 RVV C Intrinsic Specification 总结作为标准边界
> 证据范围：本地逐篇阅读总结；源材料受限条目不承担关键数字或方法结论
> 分析日期：2026-07-16
> 证据充分程度：中高（后端状态化缺口清晰，但实现复杂度高于前四类）

## 1. 这一类在研究什么

结论：这类工作不只问“程序有没有向量化”，而是研究高层计算怎样真正变成高质量 RISC-V/RVV 汇编。关键环节包括多层 IR lowering、指令选择、`vsetvli` 配置、SEW/LMUL、尾/掩码策略、寄存器分配、predication、stride load、微内核尺寸和真实性能计数器。

2025–2026 年的代表工作已经覆盖 Snitch 定制扩展的多层后端、MLIR/xDSL→RVV intrinsic 真机链、RVV MetaSchedule、真实硬件成本盲区诊断，以及从 SAIL 规格综合标量 RISC-V 指令选择规则。因此，“打通一条 RVV lowering”“在一块板上枚举微内核”“用真机反馈调参数”都已有直接近邻。

最明显的系统缺口是：RVV 的 `vl/vtype` 是跨多条指令持续生效的配置状态，但现有多层后端和规则综合工作主要针对无状态标量规则或 Snitch 的固定扩展；普通 RVV lowering 又容易把 LMUL、尾/掩码和 `vsetvli` 当作局部选择，丢失跨区域合并、寄存器压力和配置切换的全局权衡。

## 2. 主要文献证据表

| 文献 | 已解决的问题 | 使用的方法 | 主要结果 | 局限性 | 对新创新的约束 |
|---|---|---|---|---|---|
| Multi-level RISC-V Backend（CGO 2025） | 窄 LLVM 后端丢失定制扩展语义 | 多层 SSA dialect、memref_stream、渐进 lowering、spill-free allocator | Snitch 端到端 FPU utilization 73%–90% | Snitch/微内核专用、RTL 仿真、无 spill | 多层“宽后端”已被覆盖，但非 RVV 状态语义 |
| RVV Autovectorization Performance Analysis（2025） | RVV 自动向量化性能缺基线 | 总结推测为多编译器性能评测 | 具体结果无法核验 | 无 PDF，内容大量待核 | 只作为待补基线，不支持关键主张 |
| RVCC RFC（2025） | 多厂商后端补丁缺统一验证路径 | 分层验证、staging repository 讨论 | 形成社区流程建议 | RFC、非已部署学术系统 | 多平台回归是现实约束，不是算法创新 |
| RVV TSVC Coverage（2025） | RVV 向量化覆盖缺系统评测 | 总结推测 GCC/LLVM + TSVC | 具体结果无法核验 | 无 PDF，覆盖不等于性能 | 只支持“覆盖和性能必须分开”的一般纪律 |
| RVV Tensor Probabilistic Programs（2025） | tensor 调度依赖手工，单一配置非最优 | RVV MetaSchedule、概率程序、FPGA 多 VLEN + 商业 SoC | 总结报告比 GCC +46%、比 muRISCV-NN +29% | tensor 域、搜索昂贵、每硬件独立 | 真机搜索是强基线，LLM 增值必须体现在迁移/预算 |
| Closer in the Gap（2026） | RVV cost model 与真机行为偏离 | microbenchmark 校准、代理应用、模拟器分析 | 识别 predication、stride load、LMUL 盲区 | 单 BananaPi F3、版本时效性 | PMU 必须先校准；局部静态成本不足 |
| MLIR/xDSL RVV Lowering（2026） | 上游 MLIR→RVV 可部署路径不完整 | 自定义 dialect/pass、EmitC、真机枚举微内核 | 两块板相对 OpenBLAS 最高约 2.4× | FP32 GEMM、两板、枚举、无迁移代价模型 | 打通 lowering 和真机微内核选择已被覆盖 |
| ISA Specification Backend Synthesis（CGO 2026） | 手写指令选择规则量大、难维护 | SAIL/gMIR、规范化索引、随机签名、SMT、TableGen | RISC-V 约 8000 规则/36 分钟，SPEC 平均慢 2% | 标量为主、简单成本、完整后端仍手工 | 规格综合已实用；RVV 状态/真实成本仍缺 |

RVV C Intrinsic Specification 只定义 API、类型和 VLA 约束，不提供微架构性能指导。它是正确性与接口兼容的标准依据，不能替代后端成本和状态优化。

【论文事实】Multi-level Backend、Closer in the Gap、xDSL RVV 和 Backend Synthesis 的总结基于可用正文；两篇 2025 评测总结明确声明源材料受限，本文不使用其推测数字。

## 3. 已有工作已经解决了什么

结论：从高层 IR 到 RVV 代码、从 ISA 规格到选择规则、从搜索到真机反馈都已有实现；下一步需要把 RVV 配置状态作为跨层、跨指令的一等优化对象。

1. 【论文事实】Multi-level Backend 已证明目标扩展语义应在合适的多个 SSA 层逐步保留，不能再把“多层 dialect”本身称为创新。
2. 【论文事实】xDSL RVV 已打通 MLIR/xDSL→EmitC→RVV intrinsic→两块真机的短闭环，并通过枚举选择微内核。
3. 【论文事实】RVV MetaSchedule 已在不同 VLEN FPGA 和商业 SoC 上做硬件搜索，是任何 RVV 自动调优方案的强基线。
4. 【论文事实】Closer in the Gap 已指出 predication、stride load 和 LMUL 是成本模型关键盲区，并强调 PMU 校准。
5. 【论文事实】Backend Synthesis 已能从 RISC-V SAIL 和 gMIR 语义生成生产规模 GlobalISel 规则，但主要覆盖标量、局部、短序列和简单操作数成本。
6. 【论文事实】RVCC 已把多硬件功能/性能回归和可复现性列为后端优化现实要求。

## 4. 仍未解决的研究空白

结论：最值得做的空白是把 RVV 配置状态显式保留到多层 IR/机器 IR，并联合决定 `vsetvli` 放置、LMUL、尾/掩码和寄存器压力。

### 空白 A：`vl/vtype` 的跨指令状态没有成为统一优化对象

- 【论文事实】Backend Synthesis 的规则以短标量序列为主，未处理 RVV 配置状态；Multi-level Backend 面向 Snitch SSR/FREP，不是 VLA 的 `vtype/vl`；xDSL RVV 输出标准 intrinsic，但未形成全局配置状态优化。
- 【合理推导】两个局部最优的 RVV 指令选择可能要求不同 SEW/LMUL，合在一起会增加 `vsetvli`、缩短 live range 可用寄存器或导致 spill；逐指令贪心成本看不到这个问题。
- 证据充分度：高。

### 空白 B：predication/stride/LMUL 的真机证据没有系统回写到后端决策

- 【论文事实】Closer in the Gap 诊断了成本盲区；MetaSchedule 和 xDSL RVV 能以真机搜索绕过部分盲区，但没有把证据固化为通用后端的可审计状态成本。
- 【合理推导】需要区分“搜索找到一个快 kernel”和“修正编译器何时选择某种状态/指令”。
- 证据充分度：中高。

### 空白 C：结构化专用路径与通用后端 fallback 的边界不明确

- 【论文事实】Multi-level Backend 的 spill-free allocator 只适合受限微内核；xDSL RVV 只覆盖 FP32 GEMM；完整 LLVM 后端仍负责一般控制流、ABI 和 spill。
- 【合理推导】需要静态判定何时进入专用状态化路径，失败时给出可解释 fallback，而不是静默生成差代码。
- 证据充分度：中。

## 5. 候选创新点列表

| 候选创新点 | 解决的空白 | 新机制 | 新颖性 | 可实现性 | 证据充分度 | 推荐程度 |
|---|---|---|---:|---:|---:|---:|
| 配置状态显式化的 RVV 多层后端 | A+B | config region、状态图、切换/执行/spill 联合成本、真机校准 | 5 | 3 | 4 | 5 |
| RVV SAIL 驱动的状态化指令选择规则综合 | A | VLEN 参数化语义、状态效应、SMT、TableGen | 5 | 2 | 4 | 3 |
| PMU 校准的 predication/stride 成本补丁生成 | B | microbenchmark 证据、成本误差定位、回归门控 | 4 | 4 | 4 | 4 |
| 结构化专用后端—通用 LLVM fallback 边界学习 | C | 可行性证书、压力预测、双路真机选择 | 4 | 3 | 3 | 3 |

评分说明：第二候选理论新颖性高，但需构建 RVV SAIL/gMIR 语义和状态化 SMT，风险过大。第三候选最容易落地，但可能被评价为调参/工程补丁。第一候选在研究问题、RISC-V 特异性和可做的受限 MVP 之间最平衡。

## 6. 最推荐的创新点

### 6.1 创新点名称

【候选创新】**配置状态显式化的 RVV 多层后端**。

### 6.2 一句话解释

把 `vsetvli` 产生的 `vl/vtype` 状态从“后端临时插入的一条指令”提升为跨 MLIR/机器 IR 可见的配置区域，让编译器联合选择 SEW、LMUL、尾/掩码策略、配置切换位置和寄存器压力，而不是逐条指令局部决定。

### 6.3 创新点命名拆解

- **配置状态**：`S=<VL/AVL, SEW, LMUL, tail policy, mask policy>`，对后续多条向量指令持续生效。
- **显式化**：在 IR 中用 region/attribute/SSA token 表达状态需求、继承、冲突和失效。
- **多层后端**：从 Linalg/Vector 意图、RVV 合法化到机器指令选择和寄存器压力都保留必要信息。
- **联合决策**：同时计算执行成本、状态切换、spill、代码尺寸和 fallback，而非只选单条最便宜指令。

### 6.4 文献依据

- 架构依据：Multi-level Backend 证明“宽后端”能保留硬件语义并接近峰值，但目标是 Snitch，不处理 RVV VLA 状态。
- 规则依据：Backend Synthesis 证明 SAIL + 高频模式 + SMT 可以自动构建后端规则，但其局部标量模型未覆盖 RVV 状态和真实微架构成本。
- 性能依据：Closer in the Gap 证明 predication、stride load、LMUL 的局部成本假设会偏离真机；MetaSchedule/xDSL RVV 证明真机选择能找到更好配置。
- 工程依据：xDSL RVV 提供可快速扩展 dialect/pass 并输出可部署 intrinsic 的短链，适合做受限原型。
- 不能再声称的内容：不能声称“建立多层 RISC-V 后端”“打通 MLIR→RVV”“首次真机选择微内核”“首次从 SAIL 综合 RISC-V 后端”。
- 核心候选边界：**让 RVV 配置成为跨层状态，并用全局状态转换与寄存器压力共同决定 lowering/选择**。

### 6.5 已有工作与研究空白

局部 lowering 常近似为：

```text
每个 vector op → 选择一个 RVV intrinsic/指令 → 必要时插入 vsetvli
```

状态化后端改为：

```text
一组 vector op + live ranges + layout
→ 候选配置区域及其状态转换
→ 联合选择 LMUL/SEW/tail/mask 和指令序列
→ 最小化执行 + 切换 + spill + 代码尺寸
```

【合理推导】RVV 的核心不是“有更多 intrinsic 名称”，而是向量配置状态在区域内持续存在。若状态在 lowering 中过早丢失，后端只能事后插入/合并 `vsetvli`，难以改变上层 tile、LMUL 和 live range 来消除根因。

### 6.6 核心机制

定义配置状态：

```text
S = <AVL_expr, SEW, LMUL, Tail, Mask>
```

在 IR 中引入受限原型：

```text
rvv.config_region [S_candidates] {
  rvv.op ... requires <SEW, LMUL, mask/tail constraints>
}
```

每个候选 lowering 边 `e=(i→j)` 有成本：

```text
C(e) = C_exec(op, S_j, h)
     + C_switch(S_i, S_j, h)
     + λ_spill·C_spill(live_ranges, LMUL)
     + λ_size·C_code
```

- `C_exec`：指令、predication、stride/contiguous load 的平台成本；
- `C_switch`：改变 `vtype/vl` 所需 `vsetvli` 和流水线影响；
- `C_spill`：LMUL 扩大寄存器组后产生的压力；
- `C_code`：多版本、展开和尾处理的体积。

编译器构建“配置状态图”：节点是程序位置与候选 `S`，边是执行向量操作或切换配置。第一版可用动态规划/最短路选择最低成本路径；不需要 LLM 或 RL。选定路径后：

1. 合并相邻兼容 region；
2. 上提/下沉 `vsetvli`，但不得跨越可能修改 `vl/vtype` 的调用或内联汇编；
3. 根据 LMUL live range 预测 spill，必要时改小 LMUL 或拆分 region；
4. 对尾/掩码策略做合法性检查；
5. 不能安全/盈利处理的区域回退到通用 LLVM lowering。

真机 microbenchmark 只用于校准成本表，并保存硬件/编译器版本。若目标平台未知，使用保守成本和 fallback，不把单板参数当成 RVV 通用事实。

### 6.7 系统组成与数据流

```text
Linalg/Vector IR 与 shape/layout/live-range 信息
                    ↓
候选 SEW/LMUL/tail/mask 与合法性约束生成
                    ↓
rvv.config_region / SSA config token
                    ↓
构建配置状态图
                    ↓
真机校准的 exec/switch/predication/stride 成本
                    ↓
联合考虑 spill 与代码尺寸的路径选择
                    ↓
region 合并、vsetvli 放置、RVV lowering
                    ↓
Machine verifier + QEMU/Spike 差分测试
                    ↓
真实 RVV 硬件 PMU/时间回归
                    ↓
状态化路径或通用后端 fallback
```

MVP 只覆盖单基本块或结构化循环 region、整数/FP 逐元素、规约和简单 MatMul，不宣称支持一般 CFG、调用或全部 RVV intrinsic。

### 6.8 小白化例子

一个函数先做 8-bit 向量加法，再做 32-bit 规约。局部方法分别选出看似最快的 LMUL，结果在两段之间多次执行 `vsetvli`，高 LMUL 又让第二段 spill。状态化后端会比较三种方案：各自最优但切换多、统一较小 LMUL、或拆成两个可安全上提配置的 region；如果统一配置少 2 次切换并避免 spill，即使单条指令成本略高，整体仍更快。

### 6.9 可检验的研究问题

1. 显式配置区域能否减少动态 `vsetvli` 次数和不必要的配置切换？
2. 联合 LMUL—live range 决策能否降低 RVV spill 并改善真机性能？
3. 真机校准的 predication/stride 成本是否优于 LLVM 默认/静态操作数成本选择？
4. 同一 IR 在两块 RVV 微架构上是否需要不同的最优配置区域划分？
5. 结构化专用路径的可解释 fallback 是否能避免复杂 kernel 的性能或正确性回归？

### 6.10 可验证假设

- H1：相对普通逐 op lowering，状态化后端降低静态和动态 `vsetvli` 数量。
- H2：相对只优化切换次数，加入 LMUL 寄存器压力后进一步降低 spill load/store 和运行时间。
- H3：相对统一静态成本，真机校准成本在未见 kernel 上降低错误配置选择率。
- H4：删除跨层 region 信息后，后端无法通过机器级 peephole 完全恢复同等收益。
- H5：fallback 门控使不适合结构化路径的 kernel 最坏退化受控，而非以覆盖率换性能。

### 6.11 最小可行 Demo

- **目标**：在 10–15 个结构化 RVV kernel 上证明配置状态图能减少切换/spill并提高真机性能。
- **输入**：TSVC 子集、MatMul/Reduction/Softmax 子算子和 xDSL RVV 可生成的 GEMM 微内核。
- **范围**：只支持单循环 nest、无外部调用、固定数据类型集合；先不修改完整 LLVM GlobalISel。
- **实现**：在 xDSL/MLIR 层增加 `rvv.config_region` 原型和成本选择 pass，最终输出标准 RVV intrinsic C++ 或 LLVM IR。
- **平台**：至少一块 RVV 1.0 Linux 真机；若有第二块不同 VLEN/微架构板则做跨板验证，具体设备需人工确认。
- **步骤**：采 microbenchmark→校准切换/predication/stride/LMUL 成本→生成候选状态→选择路径→编译/测试/反汇编/真机测量。
- **预计工作量**：2 周 IR 与合法性，2 周状态图/选择器，1 周成本校准，2 周实验与消融。
- **成功标准**：在多个 kernel 上减少 `vsetvli` 或 spill，并在同等正确性下获得稳定真机收益；若无性能提升，能明确否定局部假设。

### 6.12 实验设计

#### 实验平台

固定编译器 commit、`-march/-mabi`、链接库、频率、绑核和输入。先用 microbenchmark 校准 PMU；不可用或不可信的事件不纳入结论。模拟器只作语义/trace 辅助，不替代真机性能。

#### 数据集

- 微基准：配置切换、predication、stride/segment load、LMUL 压力；
- 结构化 kernel：TSVC、PolyBench、GEMM/Reduction/Softmax 子算子；
- 负例：深 live range、混合 SEW、调用边界、内联汇编和高 mask 稀疏度；
- 真实应用切片：至少从一个 ML/HPC 应用提取热点。

#### 对比基线

- LLVM/Clang 默认 RVV lowering；
- xDSL RVV 式固定/枚举微内核路径；
- greedy-local：每个 op 选最低局部成本；
- switch-only：只合并 `vsetvli`，不考虑 spill；
- target-exhaustive：小 kernel 上枚举配置的性能上限；
- 完整方法：多层状态、联合成本、真机校准和 fallback。

#### 消融实验

依次删除状态 region、切换成本、predication/stride 校准、LMUL spill 项、代码尺寸项和 fallback。另比较静态成本、单板实测成本以及少量目标板校准。

#### 评价指标

- 静态/动态 `vsetvli` 数量与配置 region 数；
- spill load/store、向量/标量指令、代码尺寸；
- 真机运行时间、speedup 中位数和最坏 10%；
- 配置选择 Regret 与命中 exhaustive 最优的比例；
- 编译时间和状态图规模；
- fallback 率、fallback 原因和错误回退率；
- 正确性测试、sanitizer/差分测试通过率。

#### 统计要求

真机运行至少重复 20 次，报告中位数、bootstrap 95% 置信区间和配对效应量。多个 kernel 的性能比较同时报告逐项结果，不能只给几何平均。成本参数只在开发 kernel 上拟合，最终测试按 kernel 家族隔离。

### 6.13 与已有工作的创新边界

- 与 Multi-level Backend 的区别：它为 Snitch SSR/FREP 构建多层 SSA 后端；本方法针对 RVV VLA 的 `vl/vtype` 持久状态和配置切换/寄存器联合成本。
- 与 xDSL RVV 的区别：它打通 lowering 并真机枚举 GEMM 微内核；本方法在 IR 中显式建模状态并自动选择跨操作配置区域。
- 与 RVV MetaSchedule 的区别：MetaSchedule 对每个算子/硬件搜索调度；本方法研究通用后端内部的状态表达、合法化和可审计成本决策。
- 与 Closer in the Gap 的区别：其贡献是诊断成本盲区；本方法把校准证据回写到实际配置状态选择。
- 与 Backend Synthesis 的区别：它综合无状态短标量规则；本方法处理 RVV 状态转换、LMUL live range 和多指令区域，首版不追求自动综合整套规则。
- 直接复用的模块：xDSL/MLIR、RVV intrinsic、LLVM 后端、microbenchmark、PMU、动态规划。
- 核心创新候选：**RVV 配置状态的跨层 IR 表达 + 状态转换/执行/spill 联合选择 + 真机校准 fallback**。

### 6.14 风险与降级方案

| 风险 | 影响 | 降级方案 |
|---|---|---|
| LLVM 已有成熟 vsetvli 优化覆盖大部分问题 | 新颖性/收益下降 | 聚焦上层 LMUL/shape 信息无法在机器层恢复的案例；与现有 pass 做严格消融 |
| 完整多层后端工作量过大 | 无法按期完成 | 只做 xDSL/MLIR 单循环 `config_region` 原型，输出 intrinsic C++ |
| 真机 PMU 不可靠 | 成本校准失真 | 以运行时间、反汇编和 spill 为核心；先做计数器 microbenchmark 校准 |
| 状态图组合爆炸 | 编译时间过高 | 限制候选 SEW/LMUL、region 边界和 beam 宽度；报告最优性损失 |
| LMUL 与后端寄存器分配接口难联动 | spill 预测不准 | 使用静态 live-range 近似 + 编译后反馈迭代；首版不改 LLVM allocator |
| 只有一块 RVV 板 | 无法证明可移植性 | 主张单后端状态优化；跨硬件仅作未来工作，不用模拟器替代真机结论 |
| 状态显式化不带来速度 | 主假设失败 | 转向 PMU 校准的成本盲区补丁或结构化 fallback 边界 |
| 正确性受尾/掩码影响 | 生成错误代码 | 使用官方 spec 约束、Machine verifier、QEMU/Spike 与差分测试；失败即 fallback |
| 基线能力不公平 | 结论无效 | 保持同一 LLVM/工具链和调度预算，分别比较默认、局部、枚举与完整方法 |

### 6.15 可证伪条件

以下任一结果会否定或显著削弱候选创新：

1. 现有 LLVM `vsetvli` 优化已恢复与显式 region 相同的切换和性能；
2. 减少 `vsetvli` 不带来可重复真机收益，或被更高 spill/代码尺寸抵消；
3. LMUL live-range 模型不能比局部贪心降低 spill 和 Regret；
4. 真机校准成本不比静态 TTI 在未见 kernel 上更准确；
5. 优势只存在于专门构造的 microbenchmark，真实热点无改善；
6. 状态图编译开销过高，接近逐 kernel exhaustive search；
7. fallback 过于保守，导致覆盖率低到无法产生实际价值。

### 6.16 综合评分

| 维度 | 1—5分 | 评分理由 |
|---|---:|---|
| 新颖性 | 5 | RVV 配置状态把多层后端、规格综合和真机成本三个近邻连接到具体未解问题 |
| 文献证据 | 4 | 四篇完整近邻支撑强；两篇 2025 评测源材料受限 |
| 可实现性 | 3 | 受限 xDSL 原型可做，完整 LLVM 后端工作量高 |
| 实验可验证性 | 5 | `vsetvli`、spill、Regret、真机时间和 fallback 均可量化 |
| 与 RISC-V 相关性 | 5 | 问题直接来自 RVV VLA/LMUL/尾掩码状态，无法通过换平台完成 |
| 与总体主线兼容性 | 4 | 可作为最终主线的真实后端执行层，但不必成为所有类别中心 |
| 研究风险 | 4 | 现有 LLVM pass 能力、接口复杂度和真机条件带来较高风险 |

结论：当前适合作为**后端技术深度最高的主创新候选**。若最终主线强调一年内可完成，应把范围严格限定为 xDSL/MLIR 的结构化 kernel 原型；若更重视编译器论文的新颖性，则可继续推进到 LLVM Machine IR 的状态化选择与现有 `vsetvli` pass 正面对比。
