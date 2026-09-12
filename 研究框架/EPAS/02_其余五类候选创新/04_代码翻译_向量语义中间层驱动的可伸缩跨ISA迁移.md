# 代码翻译：向量语义中间层驱动的可伸缩跨 ISA 迁移

> **学术状态：候选创新，尚需针对性查新。** 跨 ISA intrinsic 翻译、LLM 向量化和 NEON→RVV 工具均已有工作；本候选点聚焦固定宽度 SIMD 与 RVV 可变向量长度之间的语义桥接。
>
> **当前定位调整（2026-07-13）**：本文是[创新 06：EPAS](06_多硬件编译_效应保持的最小架构增量知识特化.md)的第二阶段代码翻译扩展，不进入第一版主实验。VSIR 可作为通用知识 `K^m` 的语义载体；源/目标 ISA lowering、VLEN、mask 和 intrinsic 选择可作为 `Slots_m`；差分测试和向量语义检查可作为 `Verify_m`。研究重点仍是效应保持和最小架构增量，而不是把代码翻译与编译调优简单拼接。

## 1. 候选创新点名称与命名拆解

- **研究对象**：向量 intrinsic/向量代码的跨 ISA 翻译。
- **核心新机制**：先恢复 ISA 无关、向量长度感知的语义中间层，再向目标 ISA 降低。
- **目标或约束**：在 RVV 的 vector-length-agnostic（VLA）约束下保持语义正确并获得可伸缩性能。

候选名称：**向量语义中间层驱动的可伸缩跨 ISA 代码迁移**。

## 2. 对应论文组与主要文献依据

| 证据 | 已提供的基础/边界 |
|---|---|
| [LLM-Vectorizer](https://doi.org/10.1145/3696443.3708929) | LLM 向量化、正确性验证和性能评测；说明验证闭环必要。 |
| [IntrinTrans](https://arxiv.org/abs/2510.10119) | NEON→RVV intrinsic 翻译、多 Agent 编译/测试/优化流程；说明直接迁移已有强基线。 |
| [VecIntrinBench](https://arxiv.org/abs/2511.18867) | intrinsic 翻译基准与评测任务。 |
| [neon2rvv](https://github.com/zzh-wisdom/neon2rvv) | 规则/API 兼容层工程基线。 |

neon2rvv 是来源受限项目页，不承担论文方法结论；关键判断以其工程接口和其余三篇全文为依据。

## 3. 已有工作已经解决的问题

当前工作已能用规则、LLM 或多 Agent 完成 intrinsic 映射、编译修复、测试和局部性能优化，也已有专门基准。因而“LLM 把 NEON 翻译成 RVV”“多 Agent 编译—测试闭环”或“加入正确性验证”均不能单独作为新意。

## 4. 尚未解决的研究空白

NEON/x86 SIMD 常把固定 lane 数和固定寄存器宽度写入 API；RVV 的有效向量长度由 `VL/VTYPE` 和硬件 `VLEN` 共同决定。逐 API 翻译容易保留源 ISA 的宽度假设，产生尾部处理、mask、lane 重排、归约顺序、饱和/舍入和越界访存错误，也可能生成只在某一 VLEN 上有效的“伪移植”代码。

## 5. 核心机制与数学表示

定义向量语义中间层（Vector Semantic IR, VSIR）节点：

$$
v=(op,type,shape,mask,mem,reduce,sat,round,VL\_dep,side\_effect).
$$

翻译分两步：

$$
Code_{src}\xrightarrow{Recover}VSIR
\xrightarrow{Lower(ISA,e_h)}Code_{tgt}.
$$

VSIR 不记录“NEON 的某个 API 对应 RVV 的某个 API”，而记录 lane 关系、有效元素域、mask 传播、内存访问模式和数值语义。正确性目标为：

$$
\forall x,\forall VL\in\mathcal V_h:\quad
Sem(Code_{src},x)=Sem(Lower(VSIR,VL),x),
$$

性能目标在正确性约束下最小化：

$$
\min_{Lowering}\;T_h(Code)+\lambda Size(Code)+\mu N_{fallback}.
$$

LLM 负责语义恢复和候选 lowering，编译器/解释器/差分测试负责证据；不能让 LLM 自述替代验证。

## 6. 系统组成与数据流

```text
NEON / x86 intrinsic / 向量 C 代码
  → 语义恢复器（LLM + API 规范 + 数据流）
  → VSIR：lane、mask、memory、reduction、rounding、VL 依赖
  → 目标 lowering 候选（RVV，可扩展其他 ISA）
  → 编译检查 + 多 VLEN 语义执行/差分测试
  → RISC-V 实机性能与后端诊断
  → 失败证据回写语义节点或 lowering 规则
```

## 7. 可检验的研究问题与假设

- **RQ1**：VSIR 是否比逐 API/直接 LLM 翻译提高功能正确率和多 VLEN 正确率？
- **RQ2**：语义恢复与目标 lowering 分离，是否提高对未见 intrinsic 组合的泛化？
- **RQ3**：VLA 感知 lowering 是否比固定 VL 模板在不同 RVV 设备上具有更稳定性能？
- **H1**：显式 mask、tail、reduction 和 rounding 语义会显著减少“可编译但语义错误”的样本。

## 8. 最小可行 Demo

从 20–30 个常见 NEON intrinsic 组合开始，覆盖算术、load/store、shuffle、比较/mask、归约、饱和运算六类。手工定义一个小型 VSIR schema；用 Clang AST/LLVM IR + LLM 恢复语义；生成 RVV intrinsic；在 QEMU/Spike 做多 `VLEN` 测试，在一台 RISC-V 实机测性能。第一版不追求任意 C/C++，只做函数级纯计算内核。

## 9. 实验平台、基线、消融与指标

- **平台**：x86 开发机；RISC-V 模拟环境（多 VLEN）+ 至少一台 RVV 实机。
- **数据**：VecIntrinBench 子集、IntrinTrans 可比任务、自建组合/尾部边界样本。
- **基线**：neon2rvv、直接 LLM 翻译、IntrinTrans 风格 Agent、规则 API 映射、完整 VSIR 方法。
- **消融**：无 VL 语义、无 mask/tail 节点、无数值语义、直接 source→target、无失败回写。
- **指标**：编译通过率、功能正确率、多 VLEN 正确率、未见组合泛化、实机加速比、代码膨胀、修复轮数。

## 10. 与已有工作的创新边界

边界不在“跨 ISA 翻译”，而在：**以长度无关的向量语义作为学习和验证对象，显式桥接固定宽度 SIMD 与 VLA ISA，并将源语义恢复和目标实现优化解耦**。必须查新 vector IR、portable SIMD IR、VLA translation、RVV intrinsic migration、SIMD semantics 和 superword-level parallelism。

## 11. 主要风险与降级方案

- **语义覆盖爆炸**：限定函数内、无异常、无复杂别名的 intrinsic 内核。
- **形式证明困难**：先做多 VLEN 差分测试与属性测试，关键算子再接 Alive2/SMT。
- **真实 RVV 平台有限**：模拟器验证语义，实机验证性能；明确两种证据不能互换。
- **VSIR 被认为只是新 IR**：必须通过未见组合泛化、多 VLEN 正确率和 lowering 复用证明其作用。

## 12. 与当前研究方向的关系

这是六点中最直接命中“RISC-V + AI + 代码翻译 + 编译器”的候选方向。RISC-V/RVV 是高价值目标后端，同时 VSIR 可扩展到 SVE、AVX 等，使方法不局限于单一 ISA。

## 13. 综合评分

| 维度 | 评分（5分制） | 判断 |
|---|---:|---|
| 创新性 | 4.6 | 固定 SIMD→VLA 的语义桥接具有清晰问题特征，仍需查 portable vector IR。 |
| 可行性 | 4.2 | 小型 VSIR 和有限 intrinsic 子集可快速起步。 |
| 硕士适配度 | 4.8 | 问题集中、Demo 明确、RISC-V 特色强。 |
| 工程成本 | 3.7 | 需要解析、生成和多 VLEN 测试，但范围可控。 |
| 重合风险 | 3.0 | IntrinTrans 很近，必须突出语义中间层与 VLA 验证。 |
