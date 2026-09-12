# EPAS Demo 验证记录

验证日期：2026-07-13（Asia/Shanghai）

## 1. 测试结果

- 开发目录完整测试：27 项通过，0 失败；
- `outputs/EPAS_Demo` 独立交付包测试：27 项通过，0 失败；
- 真实 GCC smoke test 未跳过，实际完成 C 编译、执行、逐字输出比较和汇编读取；
- x86 平台诊断：`available`；
- RISC-V 模板诊断：`unavailable`，缺少 `compiler, runner`，退出码为 2，结果中没有运行时间字段。

## 2. 两次真实样例实验

命令：

```powershell
py epas_demo.py run --platform x86_local_gcc --contract runtime_efficiency --repeats 2 --warmups 1 --size 200000
```

核对结果：

- 连续执行两次；
- `sample_results/trials.jsonl` 共 12 行，每次 6 个实际编译候选；
- `sample_results/runs/` 包含 2 份唯一运行记录；
- 每次均有 5 个正确且完整测量的非基线候选；
- 所有有效非基线候选均包含 `effects`、`contract_error` 和 `delta_cost`；
- 所有 `status=measured` 的记录均有 `measured=true`；
- 所有实际测量候选均与基线输出完全一致；
- 两次样例运行状态均为 `selected`，当时的最小增量候选均为 `O3_no_vector`。

上述候选是当时机器噪声和真实测量下的选择结果，并非固定答案。交付包独立复跑时，系统选择了 `Os_generic`，说明选择来自本次测量而非硬编码。

## 3. 样例证据

- `sample_results/trials.jsonl`：追加式候选记录；
- `sample_results/runs/*.json`：两次完整运行记录；
- `sample_results/latest_summary.csv`：最近一次样例摘要；
- `sample_results/artifacts/20260713T141328839327Z/`：最近一次样例对应的 6 个可执行文件和 6 份汇编文件。

样例 JSON 中保留执行当时的绝对产物路径和完整命令；交付包中的 `artifacts` 是这些真实产物的校验副本。

## 4. 永久约束验证

- 生产 Python/JSON 中不存在伪性能命令行模式；
- 不存在合成运行时间、虚拟 PMU、想象式 rollout 或编译状态转移预测实现；
- `Phi_h`、`G_h` 和候选选择只使用实际编译、运行及汇编证据；
- 缺失平台工具时不创建试验记录；
- JSONL 历史只追加；
- 候选输出不正确时永不参与选择。

## 5. 完整性

- Markdown、JSON、Python、PowerShell 和 C 文本文件已按严格 UTF-8 解码检查；
- 所有 JSON 文件均可解析；
- `SHA256SUMS.txt` 保存交付文件的 SHA-256 清单；
- 桌面副本复制后需与本目录逐文件比对路径、大小和 SHA-256。
