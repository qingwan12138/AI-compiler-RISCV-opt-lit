# CABLE Demo 升级设计

## 1. 文档定位

本文件设计 CABLE 下一版 Demo，但本轮**不修改**桌面 `EPAS/06_EPAS_Demo` 的代码、样例结果和哈希文件。

现有 EPAS Demo 可以作为真实编译、正确性检查、运行时间采集、代码尺寸统计和平台接口的基础。它尚未实现 CABLE 的知识分解、反例边界学习和失配驱动调优，因此不能用现有 Demo 结果证明 CABLE 创新成立。

## 2. Demo 目标

下一版 Demo 需要用最小规模证明以下闭环能够真实运行：

```text
载入结构化知识
  -> 在多个平台或平台结果上执行真实测量
  -> 生成效应证据
  -> 初始知识分类
  -> 对新样本执行 KEEP / REFINE / REPLACE
  -> 记录反例并更新知识边界
  -> 对 REFINE/REPLACE 执行有限架构修正
  -> 保存全部真实轨迹
```

Demo 不追求立即超过 `-O3`，首先验证数据和决策闭环。

## 3. 永久禁止项

Demo 的任何阶段均不使用世界模型，并禁止：

- 预测 Pass 执行后的虚拟 IR 状态；
- imagined rollout；
- 虚构运行时间、PMU 或代码尺寸；
- 用预测效应写入真实测量字段；
- 在缺少 RISC-V 工具链或运行器时伪造 RISC-V 数据；
- 把候选排序分数解释为真实性能；
- 将未实现模块写成已经完成。

## 4. 当前基础与计划能力

| 能力 | 当前 EPAS Demo | CABLE 下一版计划 |
|---|---:|---:|
| 真实编译 | 已有基础 | 复用并加强元数据 |
| 正确性检查 | 已有基础 | 增加输入和输出摘要 |
| 运行时间和代码尺寸 | 已有基础 | 增加跨平台效应归一化 |
| 候选配置 | 已有基础 | 映射为知识动作 |
| 结构化知识对象 | 尚未实现 | 新增 |
| 多平台证据矩阵 | 尚未实现 | 新增 |
| 知识类别 | 尚未实现 | 新增 |
| 效应门控 | 尚未实现 | 新增 |
| 反例边界更新 | 尚未实现 | 新增 |
| 失配驱动修正 | 尚未实现 | 新增 |

## 5. 建议目录

```text
CABLE_Demo
|-- README.md
|-- bench
|   |-- bench.c
|   `-- expected_outputs.json
|-- config
|   |-- platforms.json
|   |-- actions.json
|   |-- knowledge.json
|   `-- gate_thresholds.json
|-- cable
|   |-- measure.py
|   |-- effects.py
|   |-- knowledge.py
|   |-- classifier.py
|   |-- gate.py
|   |-- boundary.py
|   |-- tuner.py
|   `-- cli.py
|-- evidence
|   |-- measurements.jsonl
|   |-- gate_events.jsonl
|   |-- boundary_versions.jsonl
|   `-- tuning_trials.jsonl
|-- tests
|   |-- test_effects.py
|   |-- test_classifier.py
|   |-- test_gate.py
|   |-- test_boundary.py
|   `-- test_tuner.py
`-- results
```

该目录只是下一阶段设计，不表示文件已经创建。

## 6. 数据结构

### 6.1 知识文件 `knowledge.json`

```json
{
  "knowledge_id": "loop_unroll_reduce_control",
  "conditions": {
    "loop_kind": "regular",
    "body_size": "small_or_medium",
    "alias_risk": "low"
  },
  "actions": ["loop_simplify", "licm", "loop_unroll"],
  "expected_effects": {
    "runtime_direction": "improve",
    "spill_growth_max": 0.05,
    "code_size_growth_max": 0.10
  },
  "boundary": {
    "class": "insufficient_evidence",
    "rules": []
  }
}
```

### 6.2 真实测量 `measurements.jsonl`

```json
{
  "run_id": "real-run-id",
  "program_id": "bench-001",
  "input_id": "n-1000000",
  "platform_id": "x86-local",
  "knowledge_id": "loop_unroll_reduce_control",
  "compiler": "clang",
  "compiler_version": "recorded-at-runtime",
  "target_flags": ["recorded-at-runtime"],
  "correct": true,
  "legal": true,
  "runtime_samples_ns": [1, 2, 3],
  "binary_size_bytes": 12345,
  "effects": {
    "runtime": 0.04,
    "code_size": -0.03,
    "spill": null,
    "vector": null
  },
  "missing_effects": ["spill", "vector"]
}
```

示例中的数值只说明字段格式，不作为真实实验结果。

### 6.3 门控事件 `gate_events.jsonl`

```json
{
  "event_id": "gate-event-id",
  "knowledge_id": "loop_unroll_reduce_control",
  "measurement_run_id": "real-run-id",
  "decision": "REFINE",
  "dominant_mismatch": "code_size",
  "reasons": ["code_size_limit_exceeded"],
  "boundary_version_before": 2,
  "boundary_version_after": 3
}
```

### 6.4 边界版本 `boundary_versions.jsonl`

```json
{
  "knowledge_id": "loop_unroll_reduce_control",
  "version": 3,
  "parent_version": 2,
  "update_type": "shrink",
  "added_conditions": {
    "estimated_register_pressure": "low"
  },
  "supporting_event_ids": ["gate-event-id"]
}
```

## 7. 分阶段 MVP

### MVP-A：真实效应采集

目标：把现有候选配置映射为知识动作，确保基线、候选、正确性和运行样本追加保存。

完成标准：

- 不覆盖历史结果；
- 缺失指标显式标记；
- 没有工具链的平台返回 unavailable；
- 每个结果可追溯到编译命令和二进制。

### MVP-B：初始知识分类

目标：对 2 至 3 条知识、2 个平台和少量程序构造效应矩阵，输出 stable、sensitive、conflicting、specific 或 insufficient_evidence。

完成标准：

- 分类依据可打印；
- 改变阈值能重新计算；
- 训练和测试程序分离；
- missing 不参与零值平均。

### MVP-C：门控和边界更新

目标：对一个已知冲突案例执行 `KEEP/REFINE/REPLACE`，追加反例并生成新边界版本。

完成标准：

- 门控只读取真实测量；
- 边界更新有父版本和证据 ID；
- 相似案例能够读取新边界；
- 不删除原边界版本。

### MVP-D：失配驱动架构修正

目标：针对 spill、代码尺寸或向量化中的一种失配，从有限动作族选择候选，并在固定预算内真实验证。

完成标准：

- 与 Random Search 使用相同候选上限；
- 保存全部尝试，而不是只保存最佳结果；
- 输出主导失配是否被修复；
- 修正结果回写知识证据。

## 8. 最小演示场景

建议选择循环展开作为首个完整案例：

1. 在 x86 和 RISC-V 上运行基线；
2. 应用相同通用知识；
3. 记录两平台运行时间、代码尺寸和可获得的 spill 代理；
4. 如果一个平台改善、另一个平台恶化，分类为冲突或敏感；
5. 门控在恶化平台执行 `REPLACE`；
6. 尝试较小展开因子或删除展开；
7. 真实运行选择结果；
8. 更新边界为“高寄存器压力条件下不直接复用”。

如果当前硬件无法可靠获取 spill，可先以汇编中的栈访问变化作为可解释代理，并明确其局限，不得伪装成 PMU 实测。

## 9. CLI 设想

```text
cable collect       采集真实基线和候选效应
cable classify      根据已有证据分类知识
cable gate          对指定真实测量作出门控决策
cable update        追加反例并生成边界新版本
cable tune          在固定预算下执行失配驱动候选验证
cable report        汇总效应、门控、边界和调优结果
```

所有命令都读取真实证据文件。`classify` 和 `gate` 不执行虚拟编译。

## 10. 测试要求

### 单元测试

- 相对效应方向计算；
- missing 传播；
- 五类知识分类边界；
- 三种门控决策；
- 边界版本不可覆盖；
- 失配到动作族映射；
- 预算耗尽停止。

### 集成测试

- 本机真实编译和运行；
- 错误输出必须失败；
- 编译失败必须记录；
- 不可用平台不得生成 runtime 字段；
- 追加运行不会覆盖旧 JSONL；
- 相同输入可复现实验摘要。

## 11. 与 Baseline 的 Demo 级比较

Demo 至少比较：

- `-O3`；
- Random Search；
- General-Only；
- 无边界更新的门控；
- 完整 CABLE 原型。

第一版 Demo 可以只展示一个冲突知识案例，但必须使用相同候选预算。

## 12. 本轮未执行事项

- 尚未创建上述 `CABLE_Demo` 代码目录；
- 尚未修改 EPAS Demo；
- 尚未生成新的 RISC-V 实测结果；
- 尚未实现知识分类器、门控或边界更新器；
- 尚未证明 CABLE 优于 Baseline。

这些能力必须在下一次代码实施、测试和真实多平台实验后才能更新为“已实现”。

