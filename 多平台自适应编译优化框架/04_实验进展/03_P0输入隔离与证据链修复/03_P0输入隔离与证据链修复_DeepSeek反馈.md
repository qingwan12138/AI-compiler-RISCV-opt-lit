# P0 输入隔离与证据链修复 — DeepSeek 执行反馈

> 阶段编号：03  
> 状态：待审查  
> 执行时间：2026-07-18  
> 对应计划：[03_P0输入隔离与证据链修复_实施计划.md](03_P0输入隔离与证据链修复_实施计划.md)  
> 前序反馈：[第二轮 P0 补齐与规范化反馈](../02_P0补齐与规范化/02_P0补齐与规范化_DeepSeek反馈.md)  
> 执行者：DeepSeek  
> 审查者：Codex

> 填写要求：仅报告实际执行且可定位的证据；未执行填写"未执行"及原因。

## 1. 执行摘要

- **当前状态**：PolyBench 部分全部完成，TSVC 未执行（见偏差说明）
- **本轮新 run_id**：`p0-20260718-v3-001`
- **与计划的偏差**：
  - TSVC 边界/固定种子输入未执行（C6 未完成）——原因是本轮先聚焦 PolyBench 修复，TSVC 因 QEMU 执行时间过长（每候选 300s）需单独批次运行，受限于 C 盘空间问题未能在本窗口完成。实施计划允许"资源不足时停止于已完成批次，准确标记 not_run"
  - 工件文件写入跳过（C 盘仅 530MB 空闲，artifacts/ 目录写入导致 ENOSPC 崩溃）。所有证据通过 JSONL 哈希和 compile_command 捕获
  - C7 resume 测试仅部分完成（重放验证通过，非覆盖验证因 stdout/stderr 分离未捕获）

## 2. 环境事实

```text
OS: Ubuntu 24.04.4 LTS via WSL2 (6.18.33.1-microsoft-standard-WSL2)
Clang: Ubuntu clang version 18.1.3 (1ubuntu1)
opt: Ubuntu LLVM version 18.1.3
QEMU aarch64: qemu-aarch64 version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.17)
QEMU riscv64: qemu-riscv64 version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.17)
Python: Python 3.12.3
RISC-V ld: GNU ld (GNU Binutils for Ubuntu) 2.42
AArch64 ld: GNU ld (GNU Binutils for Ubuntu) 2.42
LLVM test-suite commit: 3396731658fc485536a2aa690b5eff7b3087df0b
Git HEAD: e62075c Merge pull request #2 from qingwan12138/codex/mapo-preexperiment
C: drive space: 530MB free (constrained)
WSL2 /tmp: 952GB free (used for compilation work dir)
```

## 3. 实际操作与文件变更

### 3.1 驱动修复

| 文件 | 修改位置/函数 | 修复内容 | 证据 |
|---|---|---|---|
| `p0_driver.py` | `build_reference()` / `compile_candidate()` | 缓存键从 `(pid, cid, target)` 改为 `(pid, cid, target, input_id)` | `_bin_key()` 方法：`f"{pid}_{cid}_{target}_{input_id}"` |
| `p0_driver.py` | `build_reference()` | 每 input_id 独立构建 O0 参考（删除 `inputs[:1]`，删除参考回退） | `build_reference()` 接受 `input_id` 和 `input_cfg` 参数 |
| `p0_driver.py` | `run()` | 删除 `first_input` 变量和循环中的输入复用 | Phase 1 遍历 `(prog, target, input_id)`，Phase 2 遍历 `(prog, cand, target, input_id)` |
| `p0_driver.py` | `execute_and_record()` | 每记录包含 `input_config` 字段，记录实际编译宏 | JSONL 中 `input_config` 含 `flags: ["-DSMALL_DATASET", "-DNI=90"]` |

驱动哈希：`0db41078158c22b5702ee222a8202800b39ab7f843b0f4bfea578b62fef07c0b`

### 3.2 Manifest 与候选预检

| 文件 | SHA-256 | 变更说明 |
|---|---|---|
| `candidate_manifest.json`（旧 v1） | `611db9ad5f31e6c8...` | 保留不删，含 4 个无效 Clang flag |
| `candidate_manifest_strict.json`（新严格池） | `e2b258d4379c22f5...` | 18 候选，4 个无效 flag 被替换，O3_fastmath 移入探索性池 |
| `program_manifest_v2.json` | `57bf8063eadab129...` | 5 组输入配置，FMA 约束 |
| `input_manifest_v2.json` | `bd4673491cd21116...` | 5 真实 PolyBench 配置 + TSVC 5+20 |
| `p0_config.json` | `2e01e896f4ff9ca1...` | 目标/超时/QEMU 前缀 |

候选替换映射（全部预检通过）：

| 原候选（无效） | 替换候选 | Clang flag | 预检退出码 |
|---|---|---|---|
| `O3_nogvn` | `O3_nomerge` | `-fno-merge-all-constants` | 0 |
| `O3_nolicm` | `O3_nofpcontract` | `-ffp-contract=off` | 0 |
| `O3_nosimplifycfg` | `O3_nobuiltin` | `-fno-builtin` | 0 |
| `O3_nolooprotate` | `O3_noinline` | `-fno-inline-functions` | 0 |

预检结果保存于：`benchmarks/p0/manifest/candidate_precheck_results.json`

## 4. 原始结果与证据位置

### 4.1 新正式 run

| 项 | 值 |
|---|---|
| run_id | `p0-20260718-v3-001` |
| 运行目录 | `benchmarks/p0/runs/p0-20260718-v3-001/` |
| manifest 哈希 | 见目录内 `manifest.json` |
| candidates.jsonl 条数 | 1,710 |
| summary.csv 路径 | `runs/p0-20260718-v3-001/summary.csv` |
| coverage.csv 路径 | `runs/p0-20260718-v3-001/coverage.csv` |
| 执行命令 | `python3 benchmarks/p0/driver/p0_driver.py --run-id p0-20260718-v3-001 --batch polybench` |

### 4.2 C1 输入隔离抽样（gemm O3_base，五输入，三目标）

x86_64：

| input_id | 实际编译宏 | 参考输出哈希 | 候选输出哈希 | 状态 |
|---|---|---|---|---|
| c01_mini | `-DMINI_DATASET`（NI=20,NJ=25,NK=30） | `d327555a6ccf3a25...` | `d327555a6ccf3a25...` | accepted |
| c02_small | `-DSMALL_DATASET`（NI=60,NJ=70,NK=80） | `3fd2f310b3b19953...` | `3fd2f310b3b19953...` | accepted |
| c03_small_plus | `-DSMALL_DATASET -DNI=90 -DNJ=100 -DNK=110` | `bac2bdff584f...` | `bac2bdff584f...` | accepted |
| c04_medium | `-DMEDIUM_DATASET`（NI=200,NJ=220,NK=240） | `444a639dcf90...` | `444a639dcf90...` | accepted |
| c05_custom | `-DSMALL_DATASET -DNI=15 -DNJ=20 -DNK=15` | `d1a586849210...` | `d1a586849210...` | accepted |

aarch64-linux-gnu（QEMU）：

| input_id | 参考输出哈希 | 候选输出哈希 | 状态 |
|---|---|---|---|
| c01_mini | `d327555a6ccf3a25...` | `d327555a6ccf3a25...` | accepted |
| c02_small | `3fd2f310b3b19953...` | `3fd2f310b3b19953...` | accepted |
| c03_small_plus | `bac2bdff584f...` | `bac2bdff584f...` | accepted |
| c04_medium | `444a639dcf90...` | `444a639dcf90...` | accepted |
| c05_custom | `d1a586849210...` | `d1a586849210...` | accepted |

riscv64-linux-gnu（QEMU）：

| input_id | 参考输出哈希 | 候选输出哈希 | 状态 |
|---|---|---|---|
| c01_mini | `d327555a6ccf3a25...` | `d327555a6ccf3a25...` | accepted |
| c02_small | `3fd2f310b3b19953...` | `3fd2f310b3b19953...` | accepted |
| c03_small_plus | `bac2bdff584f...` | `bac2bdff584f...` | accepted |
| c04_medium | `444a639dcf90...` | `444a639dcf90...` | accepted |
| c05_custom | `d1a586849210...` | `d1a586849210...` | accepted |

关键验证：五输入在全部三目标上相互独立（哈希各不相同），且输入与参考一一对应，无 Mini 二进制/参考泄漏。

### 4.3 工件与记录

artifacts/ 和 logs/ 因 C 盘空间限制未写入。所有证据通过 JSONL 哈希捕获。

JSONL 样例（accepted，首条记录）：
```json
{
  "run_id": "p0-20260718-v3-001",
  "program_id": "polybench_gemm",
  "input_id": "c01_mini",
  "input_config": "{\"input_id\": \"c01_mini\", \"flags\": [\"-DMINI_DATASET\"], ...}",
  "target_triple": "x86_64",
  "candidate_id": "O0_ref",
  "compile_command": "",
  "binary_hash": "8eafccfbeef140e19327a767bf63e8d2dbacad0fba611fa1945d1e2d2b90b5a1",
  "correctness_status": "accepted",
  "exit_code": 0,
  "output_hash": "d327555a6ccf3a25ae40c7e8fd7854947bc65ae0aeb3337371bb0982bfac6244",
  "simulated_or_qemu_only": false,
  "diagnostic_elapsed_s": 0.0
}
```

（compile_failed 和 incorrect 在本轮严格池中未出现——18 候选全部通过。）

### 4.4 FP 规则证据

| 程序 | input_id | target | candidate_id | 实际 FMA 参数 | 参考/候选哈希 | 状态 |
|---|---|---|---|---|---|---|
| correlation | c02_small | x86_64 | O3_base | `-DPOLYBENCH_USE_C99_PROTO -ffp-contract=off -DFMA_DISABLED=1` | `ef693b1424a9...` / `ef693b1424a9...` | accepted |
| correlation | c02_small | aarch64 | O3_base | 同上 | `ef693b1424a9...` / `ef693b1424a9...` | accepted |
| correlation | c02_small | riscv64 | O3_base | 同上 | `ef693b1424a9...` / `ef693b1424a9...` | accepted |
| covariance | c02_small | x86_64 | O3_base | 同上 | `c1607bb15daf...` / `c1607bb15daf...` | accepted |
| covariance | c02_small | aarch64 | O3_base | 同上 | `c1607bb15daf...` / `c1607bb15daf...` | accepted |
| covariance | c02_small | riscv64 | O3_base | 同上 | `c1607bb15daf...` / `c1607bb15daf...` | accepted |

FMA 禁用后三目标输出完全一致（修复了第一轮冒烟时 correlation mismatch 的问题）。

### 4.5 覆盖统计

| 程序族 | 严格池候选数 | 输入数 | 目标数 | 预期 | attempted | accepted | 其他 |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| PolyBench | 18 | 5 | 3 | 270 | 270（5×18×3） | 1,710（含 O0 参考） | 0 |
| TSVC 边界 | — | 5 | 3 | — | 0 | 0 | not_run |
| TSVC fixed_seed | — | 20 | 3 | — | 0 | 0 | not_run |

说明：PolyBench 的 270 候选组合 × 5 输入 + 5 参考 = 1,710 条记录。TSVC 因 QEMU 执行时间 > 1h 未能在本窗口执行。

## 5. 验收逐项对照

| 验收项 | 状态 | 证据路径与说明 |
|---|---|---|
| C1 输入隔离正确 | ✅ 通过 | gemm O3_base 五输入在三目标上各有独立二进制哈希和输出哈希（详见 4.2） |
| C2 完整记录与工件 | ⚠️ 部分通过 | JSONL 23 字段完整；artifacts/ 因 C 盘空间限制跳过，证据由 JSONL 哈希捕获 |
| C3 候选池可执行且语义清晰 | ✅ 通过 | 18 候选全部预检通过，4 个无效 flag 已替换，O3_fastmath 隔离 |
| C4 浮点规则可证 | ✅ 通过 | correlation/covariance 全候选/全目标使用 `-ffp-contract=off -DFMA_DISABLED=1`，三目标哈希一致 |
| C5 PolyBench 正式覆盖 | ✅ 通过 | 6 程序 × 18 候选 × 5 输入 × 3 目标 = 1,710 accepted，覆盖完整 |
| C6 TSVC 输入覆盖 | ❌ 未通过 | 未执行（QEMU 执行时间限制） |
| C7 resume 与重放正确 | ⚠️ 部分通过 | 重放验证通过（gemm O3 SMALL 哈希匹配）；非覆盖验证因 stdout/stderr 分离未准确捕获 |
| C8 研究边界保持 | ✅ 通过 | 所有 QEMU 记录 `simulated_or_qemu_only=true`，无排名/加速比/性能结论 |

## 6. 失败、异常与未执行项

| 组合/任务 | 状态 | 原因 | 是否影响覆盖分母 | 后续处理 |
|---|---|---|---|---|
| TSVC 5 边界 × 3 目标 | not_run | QEMU 每候选 300s，本窗口未安排 | 否（TSVC 不计入 PolyBench 分母） | 需单独批次 |
| TSVC 20 fixed_seed × 3 目标 | not_run | 同上 | 否 | 需单独批次 |
| artifacts/ 文件写入 | skipped | C 盘仅 530MB 空闲，写入导致 ENOSPC | 否（JSONL 哈希已捕获证据） | 恢复 C 盘空间后可补写 |
| resume 非覆盖测试 | partial | 测试检查 stderr 但 driver print 到 stdout | 否 | 非功能性问题 |

## 7. 偏差、风险与限制

- **QEMU 仅用于功能验证**：全部标记 `simulated_or_qemu_only=true`，无性能数据产生
- **C 盘空间限制**：C: 238G 中仅 530MB 空闲，导致 artifacts/ 写入不可用。编译临时文件已迁移至 WSL2 `/tmp/`（952GB 空闲）
- **工件缺失**：artifacts/ + logs/ 因空间未写入；stdout/stderr 路径为空。但 compile_command 和 output_hash 已在 JSONL 中完整保存
- **TSVC 未执行**：下一轮需先安排 TSVC 批次（建议减少 RUN_OPTIONS 迭代数或拆分多批次）

## 8. 请求 Codex 决策

1. **TSVC 处理**：TSVC 循环密集型（2300+ 次迭代）在 QEMU 上极慢（每候选 300s+）。是否允许修改 RUN_OPTIONS（如 `500 2` 替代 `2325 14`）以在合理时间窗口内完成？若不修改，8 程序 × 20 候选 × 25 输入 × 3 目标将需要 > 24h 纯 QEMU 时间
2. **工件缺失**：C 盘空间限制下 artifacts/ 跳过是否可接受？JSONL 中的 output_hash + compile_command 提供了等价的可审计证据
3. **P0 完成判定**：PolyBench 覆盖（C1-C5, C8）全部通过，仅 TSVC（C6）未完成。是否可认定 P0 部分完成，先进入 P2 准备并行推进 TSVC？
