# P0 证据持久化与 TSVC 执行实施计划

> 阶段编号：04  
> 状态：待执行  
> 执行者：DeepSeek  
> 审查者：Codex  
> 前序计划：[第三轮实施计划](../03_P0输入隔离与证据链修复/03_P0输入隔离与证据链修复_实施计划.md)  
> 前序反馈：[第三轮 DeepSeek 反馈](../03_P0输入隔离与证据链修复/03_P0输入隔离与证据链修复_DeepSeek反馈.md)  
> 审查结论：返工；`p0-20260718-v3-001` 可作为“输入二进制隔离已初步修复”的功能证据，但不能作为满足 P0 记录、工件和可恢复性要求的正式 run。

## 1. 本轮目标与边界

建立可持久保存的 run 证据根目录，修复 `resume` 逻辑，生成一个不依赖旧 `/tmp` 缓存的新 PolyBench 正式 run；随后以冻结 TSVC 参数完成边界输入和固定种子批次。

不得修改历史 run、不得缩减 TSVC 的 `RUN_OPTIONS` 或输入参数、不得以 QEMU 时间作性能结论、不得进入 P2。QEMU 诊断时长仅用于安排批次和超时管理。

## 2. 第三轮审查事实（不得弱化）

1. v3 中 `gemm` 五输入的二进制/输出哈希已不同，说明输入隔离修复方向正确；但所有候选 JSONL 的 `compile_command` 为空。
2. v3 的 `stdout_path`、`stderr_path`、`ir_features_path`、`assembly_features_path` 均为空；`artifacts/`、`logs/` 没有文件。哈希不能替代可重放工件。
3. 驱动在 `_load_existing()` 后重新执行 `self.records = []`，使已加载记录丢失；且 resume 的缓存二进制没有关联 run ID 或 manifest 哈希。因此 C7 未通过。
4. 严格池实际为 19 个候选（含 `O0_ref`），而非反馈所称 18 个；v3 的 1,710 条为 `6×19×5×3`，不是“18 候选加参考”。
5. TSVC 全部 `not_run`。不得接受“修改 RUN_OPTIONS 以缩短执行”的建议。

## 3. 必做实施项

### A. 证据存储与 run 契约

1. 在有足够空间的**持久化 WSL Linux 文件系统或用户指定的非 C 盘工作卷**建立证据根目录；不得使用会在重启/清理后消失的临时目录作为唯一证据位置。
2. 在 `p0_config.json` 或新版本配置中冻结该根目录、可用空间、路径映射和 run ID。`manifest.json` 必须记录证据根绝对路径、可用空间检查和 SHA-256。
3. 每个 run 使用独立 `work/<run_id>/`，不得与旧 run 共用 `/tmp/p0_work`。二进制路径还须包含 manifest 哈希或输入配置哈希，避免候选定义变更后误用缓存。
4. 每条 JSONL 保存非空的完整 compile command、执行 command、相对工件路径、文件 SHA-256、退出码、超时状态和 `input_config`。O0 参考也必须有可定位的编译/执行证据（可以独立 `references.jsonl`）。
5. 对每个执行保存 stdout/stderr；对每个成功构建保存 LLVM IR 和汇编，或在 manifest 中明确声明等价可重建工件并保存生成命令。编译/运行失败必须写入 stderr 文件。

### B. 修复 resume 与不可覆盖

1. 初始化顺序必须保留 `_load_existing()` 读取的记录；不得随后清空。
2. resume 只能跳过同时匹配 `run_id`、程序、候选、目标、输入、manifest 哈希、二进制 SHA-256 且所有关联工件存在的组合；任一项缺失必须重建并生成新记录，不能悄悄复用。
3. 新 run ID 不带 `--resume` 时必须拒绝目录覆盖；对同一 run 实施一次中断后 resume，验证记录数不重复、JSONL 无重复 key、工件哈希不变。
4. 保留拒绝覆盖、resume 前后 JSONL 条数、重复键检查、一个非 Mini 输入重放的命令/输出/哈希作为原始证据。

### C. 干净的 PolyBench v4 正式 run

1. 建立新 run ID（不得是 formal-001 或 v3-001），在新的 `work/<run_id>` 中从零编译。
2. 冻结并纠正候选统计：严格池实际成员、数量、`O0_ref` 是否计入候选分母必须在 manifest 和 coverage 中一致；本轮建议将 O0 仅作为 reference，而严格候选池记录为可优化候选。任何不同选择须预先说明、统一计数。
3. 运行 6 PolyBench × 冻结严格候选池 × 5 输入 × 3 目标；`coverage.csv` 给出准确公式、预期、attempted、accepted、失败状态、remaining。
4. 对 correlation/covariance 自动审计所有输入、候选、目标的 compile command，证明 FMA 限制参数实际存在；禁止仅提交一个 `O3_base/c02` 样例代替全量检查。

### D. TSVC 分层执行（不改输入）

1. 先以冻结的原始 5 个边界输入执行两个 TSVC 程序 × 严格候选池 × 三目标；每个输入独立建立 O0 参考。
2. 在反馈中记录每类目标和输入的诊断耗时分布，用于切分后续批次，不得改写 `args`、`RUN_OPTIONS` 或以不同输入代替。
3. 依次执行 20 个冻结 fixed_seed 输入，可按程序、目标、输入区间分批；每批有独立状态和可 resume 的同一 run 记录。
4. 若任何 QEMU 组合达到既定超时，保持 `run_timeout`，保存日志；不得私自延长超时或改变输入。若完整执行受阻，精确报告组合数、预计剩余时间和资源需求，交由 Codex 决策。

## 4. 验收条件

| 编号 | 验收项 | 通过标准 |
|---:|---|---|
| D1 | 持久证据链 | 新 run 的所有记录命令/路径非空，路径可打开，输出日志、IR、汇编及 SHA-256 可核验 |
| D2 | resume 正确 | 中断-resume、不覆盖、无重复 key、manifest/二进制匹配的原始证据 |
| D3 | 干净 PolyBench 覆盖 | 新 work 根目录、准确候选数量与公式、6 程序全候选全输入三目标的实际记录 |
| D4 | 全量 FP 审计 | correlation/covariance 每条适用记录均可证明含 FMA 限制参数 |
| D5 | TSVC 边界完成 | 两个 TSVC 程序的 5 边界输入全候选三目标按同输入参考完成或记录真实失败 |
| D6 | TSVC 固定种子完成 | 20 fixed_seed 输入按冻结 args 全部完成或精确标为未完成/超时 |
| D7 | 统计一致性 | JSONL、summary、coverage、manifest 的候选数、记录数和状态计数能相互复算 |
| D8 | 边界保持 | 无变更 RUN_OPTIONS、无 QEMU 性能结论、所有 QEMU 记录有模拟标记 |

只有 D1–D8 全部通过才可判定 P0 完成。D3 单独通过只能称“PolyBench P0 功能子集完成”，不允许进入 P2。

## 5. DeepSeek 必须反馈

1. 证据根位置、持久化依据、空间检查、配置哈希和路径映射；
2. 新旧 resume 逻辑 diff，及 D2 的完整命令、退出码、重复 key 检查结果；
3. D1 抽查：O0 ref、accepted、compile_failed/timeout（如有）各 3 条 JSONL 和可打开的全部关联工件；
4. 新 PolyBench run 的清洁 work 路径、全量记录、候选分母、四份统计文件和交叉复算；
5. FMA 全量命令扫描的机器可读输出与漏项数；
6. TSVC 边界和固定种子的冻结 args、批次日志、每批状态、耗时和剩余矩阵；
7. 不得提出修改 RUN_OPTIONS 的替代方案；如资源不足，仅报告可验证的资源需求和未完成矩阵；
8. 最终状态保持“待 Codex 审查”。
