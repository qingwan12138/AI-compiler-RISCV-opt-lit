# 类别四：向量化与跨 ISA 迁移——固定宽度 SIMD 到 VLA 的语义契约恢复

> 审阅结论：不再把“设计一个平台无关向量 IR”作为创新；MLIR Vector dialect 已提供通用、可重定向且支持 scalable vector 的抽象。
> 文献范围：本类 4 篇逐篇阅读笔记；重点参考 LLM-Vectorizer、IntrinTrans、VecIntrinBench、neon2rvv。
> 证据强度：高，但数据规模仅约 50 个函数级任务，需扩展。
> 日期：2026-07-15

## 1. 先说结论

NEON/SSE/AVX 到 RVV 的难点不是换函数名，而是把“固定宽度、固定 lane 数”的源程序恢复成“向量长度运行时可变”的算法契约。

推荐创新点名称：**面向多 VLEN 验证的固定宽度 SIMD—VLA 语义契约恢复与反例修正**。

它不发明新的通用向量 IR，而是把 MLIR Vector dialect 或 LLVM scalable vector 当作实现底座，研究源 intrinsic 中没有显式写出的 mask、tail、VL、归约顺序和跨寄存器分组语义如何被恢复、验证和修正。

## 2. 已有工作做到哪里了

| 工作 | 已覆盖 | 主要缺口 |
|---|---|---|
| neon2rvv | 头文件规则映射，快速把 NEON 映射到 RVV | 常采用固定 VLEN 假设，覆盖和性能有限 |
| VecIntrinBench | 约 50 个跨架构 intrinsic 迁移任务和多维评测 | 规模小，复杂 VLA 语义覆盖不足 |
| IntrinTrans | LLM + 编译 + 测试 + 活跃性反馈闭环 | 正确性依赖有限测试，VLA 契约未显式化 |
| LLM-Vectorizer | LLM 生成、Checksum 和 Alive2 验证 | 重点是 x86 向量化，验证覆盖率受限 |

同时，[MLIR Vector dialect](https://mlir.llvm.org/docs/Dialects/Vector/)已经提供面向多硬件的机器无关向量抽象和 scalable vector 支持；[LLVM 的 RVV 文档](https://llvm.org/docs/RISCV/RISCVVectorExtension.html)也采用 scalable vector 类型表达 RVV。因此，不能再声称“首次提出平台无关向量语义中间层”。

## 3. 真正的研究空白

固定宽度 SIMD 代码里常有隐含假设：

- 每次恰好处理 4/8/16 个元素；
- 尾部由标量循环处理，或调用方保证长度整除；
- mask 的未激活 lane 应保留、归零或不关心；
- shuffle 依赖固定 lane 编号；
- reduction 的组合顺序和浮点结果容忍度；
- 多个寄存器共同表示一个逻辑向量。

如果直接逐 intrinsic 映射到 RVV，代码可能：

- 只在 VLEN=128 时正确；
- 换到 VLEN=256/512 时重复或漏算元素；
- 在最后一次迭代错误处理 tail；
- 因 mask/tail policy 不同读入未定义值；
- 浮点归约结果与原程序的允许误差不一致。

这些问题不能仅靠“编译通过”发现，也不能由一个通用 IR 自动解决。

## 4. 推荐创新点

### 4.1 一句话解释

先把源 SIMD 代码还原成一份不依赖固定向量宽度的“算法说明书”，再据此生成 RVV；如果它在某个 VLEN 或边界输入上失败，就用最小反例指出是哪条语义假设恢复错了。

### 4.2 VLA 语义契约

对每个待迁移函数恢复：

```text
Iteration domain : 处理的逻辑元素范围
Lane mapping     : 源 lane 与逻辑索引的关系
Mask policy      : 激活/未激活 lane 的行为
Tail policy      : 最后不足一个向量时的行为
VL discipline    : setvl 的位置与循环推进关系
Reduction law    : 结合律、顺序约束与浮点容忍度
Memory contract  : 对齐、stride、越界禁止条件
```

契约先由静态分析和规则恢复确定性部分，LLM 只提出歧义部分的候选解释。每条解释必须通过执行或形式工具验证，不能采信 LLM 自我判断。

### 4.3 翻译流程

1. 解析源 intrinsic 和控制流，恢复固定宽度 lane 行为；
2. 把行为提升到 VLA 契约；
3. 在 MLIR Vector/scalable vector 上生成中间实现；
4. lowering 到 RVV intrinsic 或 LLVM RVV；
5. 在多个 VLEN 配置、随机输入和边界输入上差分执行；
6. 对失败样本做 delta debugging，得到最小 `(VLEN, n, mask, data)` 反例；
7. 将反例归类为 lane、tail、mask、reduction 或 memory contract 错误；
8. 只修正对应契约字段，再重新生成。

### 4.4 为什么这比“直接让 LLM 翻译”更强

- 失败位置从一整段代码缩小到一个契约字段；
- 同一契约可生成不同 RVV 实现，便于性能搜索；
- 多 VLEN 验证直接检查可伸缩性，而不是默认 128 位；
- 规则工具可处理常见一对一映射，LLM 只负责真正有歧义的组合语义。

## 5. 最小可行实验

### 5.1 数据集扩展

从 VecIntrinBench 起步，新增以下高风险类别：

- 非整除长度与多种 tail；
- mask merge/zero/agnostic 行为；
- 固定 lane shuffle 与跨寄存器拼接；
- widening/narrowing；
- 整数和浮点 reduction；
- stride、gather/scatter。

至少覆盖 VLEN=128/256/512；若真实硬件不足，可用模拟器做功能验证，但性能必须在真实硬件上测。

### 5.2 基线

1. neon2rvv 规则翻译；
2. LLM 一次性翻译；
3. IntrinTrans 风格编译—测试反馈；
4. 使用通用 IR 但没有显式 VLA 契约的版本；
5. 完整契约恢复 + 多 VLEN 反例修正。

### 5.3 指标

- 编译通过率；
- 单 VLEN 与多 VLEN 功能正确率；
- VLEN 泛化率：未参与修正的 VLEN 上是否正确；
- 各类语义错误检出率；
- 平均修正轮数；
- 与手写 RVV 的真实硬件性能比；
- 代码是否保持 VLEN-agnostic。

## 6. 可证伪假设

主假设：显式 VLA 契约和多 VLEN 反例反馈能显著降低“单一 VLEN 通过、换 VLEN 失败”的隐蔽错误，并减少翻译修正轮数。

失败信号：

- 契约抽取本身比直接翻译更不稳定；
- 通用 IR 基线已自动处理绝大多数问题，显式契约没有增益；
- 多 VLEN 正确率提高但代码性能大幅下降且无法再优化；
- 复杂 shuffle/reduction 无法用所定义契约表达。

## 7. 论文边界

可主张：固定宽度到 VLA 的契约恢复、多 VLEN 测试协议、契约级反例定位与修正。

不可主张：首次跨 ISA intrinsic 翻译、首次 LLM+编译反馈、首次平台无关向量 IR、仅凭 QEMU 获得真实加速结论。

## 8. 综合判断

| 维度 | 评分（5 分） | 说明 |
|---|---:|---|
| 新颖性 | 4.2 | 从“代码翻译”收窄到“VLA 隐含语义恢复” |
| 可实现性 | 3.6 | 高风险语义和多 VLEN 测试工程量较大 |
| 实验清晰度 | 4.6 | 多 VLEN 隐蔽错误可直接量化 |
| RISC-V 相关性 | 5.0 | 直接针对 RVV 可伸缩语义 |
| 风险 | 中高 | 形式验证覆盖和浮点语义是难点 |

最终建议：作为类别四主创新。实现时复用 MLIR/LLVM 现有向量抽象，把论文贡献集中在语义恢复、反例和验证协议上。
