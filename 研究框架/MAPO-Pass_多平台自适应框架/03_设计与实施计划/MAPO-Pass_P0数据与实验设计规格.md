# MAPO-Pass P0 数据与实验设计规格

> 目标：把 P0 变成可复现的候选编译与正确性数据管线。  
> 限制：P0 的 QEMU 运行只验证二进制功能；所有时间字段均不得命名或解释为目标 ISA 性能。

## 1. 基准与来源

初始基准来自 `benchmarks/sources/llvm-test-suite` 的稀疏检出，提交为 `3396731658fc485536a2aa690b5eff7b3087df0b`。P0 首批选择 6–8 个确定性内核，覆盖：

| 类别 | 建议程序 | 主要覆盖 |
|---|---|---|
| 线性代数 | `gemm`、`atax` | 密集计算、内存访问、向量化 |
| stencil | `jacobi-2d` | 循环、局部性、依赖 |
| 数据挖掘 | `correlation` | 浮点、归约、严格 FP 约束 |
| TSVC | 从 TSVC 选择 2–3 个可确定性子项 | 循环/向量化与控制流 |
| 分支/访存 | LLVM test-suite 中补选 1–2 项 | 分支和 stride 敏感性 |

每个 `program_id` 必须记录源相对路径、程序族、许可证位置、输入策略、浮点容差、参考构建命令和源文件哈希。

## 2. 目标与编译原则

目标三元组为 `x86_64`、`aarch64-linux-gnu`、`riscv64-linux-gnu`。所有目标使用同一 Clang 主版本、同一候选定义和尽可能一致的源级宏。AArch64/RISC-V 使用各自交叉 sysroot/链接器，运行时通过 `qemu-aarch64`、`qemu-riscv64` 与对应 `QEMU_LD_PREFIX` 执行。

PolyBench 浮点程序遵循其对应 `CMakeLists.txt` 的官方编译约束，例如 `-DPOLYBENCH_DUMP_ARRAYS`、`-DPOLYBENCH_USE_C99_PROTO`、`-DFP_ABSTOLERANCE=1e-5`，以及需要时的 `-ffp-contract=off -DFMA_DISABLED=1`。不得用哈希失配掩盖漏传的官方浮点约束。

## 3. 正确性策略

每个候选相对独立 `-O0` 参考或已验证校验和值验证。整数输出优先逐字节/哈希比较；浮点输出明确记录绝对/相对容差、FMA 收缩策略和比较实现。输入集在候选生成前固定：至少 5 个边界输入加 20 个随机种子输入；种子列表与输入生成器版本写入 manifest。

每条记录的状态只能为：

```text
compile_failed | link_failed | run_timeout | crashed | incorrect | accepted
```

失败状态必须保留 stderr、退出码、超时阈值和命令，不能被转换成“较慢”或从汇总中删除。

## 4. run 目录契约

```text
runs/<run_id>/
  manifest.json          # 环境、Git、工具版本、种子、候选/基准 manifest 哈希
  candidates.jsonl       # 一行一个 program × input × target × candidate 记录
  summary.csv            # 接受/失败数与可复核汇总
  rank_matrix.csv        # P0 可为空占位；P2 后记录真实排名
  artifacts/             # 二进制哈希、输出哈希、IR/汇编特征索引
```

`candidates.jsonl` 的最小字段：

```text
run_id, program_id, program_family, input_id, target_triple,
compiler_version, candidate_id, pass_sequence, compile_command,
binary_hash, correctness_status, timeout_status, stdout_hash,
stderr_path, ir_features_path, assembly_features_path, timestamp
```

## 5. P0 验收清单

- [ ] 6–8 个程序均有来源、输入和参考输出说明；
- [ ] 每程序 16–32 候选在三目标均有结构化记录；
- [ ] 所有 `accepted` 记录通过既定输入集；
- [ ] 编译、链接、运行和正确性失败均可定位；
- [ ] 每条记录可由 manifest、候选 ID 和命令复现；
- [ ] 结果不含或不误标 QEMU 目标性能时间；
- [ ] 执行一次全新 `run_id` 的复现检查。

只有全部完成才能称为“P0 完成”。当前三目标 PolyBench 冒烟是本规格的先验验证，不替代完整验收。
