# 02_P0补齐与规范化 执行计划

## 任务拆解

### A. 修订 Manifest
- `program_manifest_v2.json` — 6 程序 + 类别信息
- `candidate_manifest_v2.json` — 同 20 候选，不改动
- `input_manifest_v2.json` — 5 真实 PolyBench 配置 + TSVC 5+20 输入
- `p0_config.json` — 超时、QEMU 前缀、驱动版本

### B. 重写正式驱动
- `p0_driver.py` → 唯一正式入口
  - `--resume` 续跑
  - 完整 JSONL 字段（diagnostic_elapsed_s, exit_code, output_stream 等）
  - 工件契约：manifest.json, candidates.jsonl, summary.csv, coverage.csv, artifacts/, logs/
  - 失败夹具

### C. 批次执行
- 编译：8程序 × 20候选 × 3目标 = 480 次
- 执行最低覆盖：gemm/atax/correlation/covariance × 5配置 × 3目标
- TSVC controlflow × 5输入 × 3目标
- 更新 coverage.csv

### D. 填写反馈
- 02_P0补齐与规范化_DeepSeek反馈.md → 待审查
