# EPAS 真实测量 Mini Demo

## 1. Demo 验证什么

该 Demo 验证 EPAS（Effect-contract Platform-Adaptive Specialization）的最小闭环：

1. 用 GCC 的通用优化配方和少量架构特化配方实际编译同一个程序；
2. 在目标平台真实运行候选，并逐字比较程序输出；
3. 从运行时间、二进制大小和汇编证据构造平台效应向量 `Phi_h`；
4. 根据效应契约计算误差 `G_h`；
5. 在满足契约的候选中选择架构增量成本最小的配方。

它不是完整论文系统，但能直接验证“通用配方 + 面向平台的最小增量”这一核心假设。

## 2. 永久设计约束

- 所有性能数值都来自真实编译产物和真实程序运行。
- 任意阶段均不使用世界模型，不预测编译器状态转移，不虚拟执行 Pass，也不进行想象式 rollout。
- 不提供伪造性能模式，不生成合成运行时间、合成 PMU 或合成奖励。
- 将来即使加入候选排序模型，模型也只能决定“先测哪个候选”；最终 `Phi_h`、`G_h` 和实验结论仍必须来自真实测量。
- RISC-V 工具缺失时只返回 `unavailable`，不会回退到伪数据。

## 3. 环境要求

- Windows PowerShell 5 或更高版本；
- Python 3，可通过 `py` 启动；
- GCC。当前默认平台使用本机 MinGW GCC；
- 可选：RISC-V 交叉编译器和 QEMU，用于启用模板平台。

先检查本机 x86 环境：

```powershell
.\run.ps1 -Doctor -Platform x86_local_gcc
```

检查 RISC-V 模板环境：

```powershell
.\run.ps1 -Doctor -Platform riscv64_template
```

若 RISC-V 交叉编译器或 QEMU 未安装，第二条命令应返回 `unavailable` 和缺失组件，退出码为 2。

## 4. 快速运行

```powershell
.\run.ps1 -Quick
```

Quick 模式仍然执行真实编译和真实运行，只把输入规模固定为 `200000`、重复次数设为 `2`，以缩短等待时间。

完整运行示例：

```powershell
.\run.ps1 `
  -Platform x86_local_gcc `
  -Contract runtime_efficiency `
  -Repeats 5 `
  -Warmups 1 `
  -Size 1000000
```

也可以直接调用 Python：

```powershell
py .\epas_demo.py run --platform x86_local_gcc --contract runtime_efficiency --repeats 5 --warmups 1 --size 1000000
```

## 5. 三条效应契约

`contracts.json` 定义三条可验证知识：

| 契约 | 内核 | 目标 |
|---|---|---|
| `runtime_efficiency` | `branch` | 改善真实运行时间，同时限制尺寸和分支恶化 |
| `code_compaction` | `branch` | 缩小真实二进制，同时限制运行时间退化 |
| `vector_exposure` | `vector` | 保留或增加汇编中的向量证据，同时限制运行时间退化 |

契约误差是未满足最低效应要求的加权和。误差不超过契约阈值才算满足。

## 6. 候选配方

`candidates.json` 包含：

- `O2_baseline`：真实测量基线；
- `O3_generic`：通用性能配方；
- `Os_generic`：通用尺寸配方；
- `O3_unroll`：在通用配方上增加循环展开槽位；
- `O3_no_vector`：关闭向量化的反例；
- `O3_native`：加入 `-march=native` 的 x86 架构特化配方。

架构增量成本由新增决策槽位数量和架构特有惩罚组成。选择顺序是：先保证编译成功和输出正确，再满足效应契约，最后最小化增量成本；增量相同时才比较真实运行时间。

## 7. 结果状态

- `selected`：存在满足契约的候选，已选出最小架构增量；
- `contract_unsatisfied`：存在正确的真实测量，但没有候选满足契约；只给出误差最小的诊断候选，不宣称特化成功；
- `no_valid_candidate`：没有正确且完整测量的非基线候选；
- `baseline_failed`：基线无法编译、运行或通过正确性检查，实验立即停止；
- `unavailable`：平台工具不完整，不创建试验记录。

## 8. 输出文件

```text
results/trials.jsonl
results/runs/<run_id>.json
results/latest_summary.csv
```

- `trials.jsonl` 每个候选一行，只追加，不覆盖历史；
- `runs/<run_id>.json` 保存一次实验的完整记录；
- `latest_summary.csv` 仅是最近一次实验的查看视图，可以覆盖；
- `build/<run_id>/` 保存本次真实可执行文件和汇编证据。

每条有效非基线记录都应包含 `effects`、`contract_error`、`delta_cost`、原始时间序列和正确性结果。

## 9. 配置 RISC-V 或其他平台

`platforms.json` 的平台接口包含：

```json
{
  "compiler": "riscv64-linux-gnu-gcc",
  "runner": ["qemu-riscv64"],
  "executable_suffix": "",
  "isa": "riscv"
}
```

如果动态链接程序需要 sysroot，可以把 runner 改为类似：

```json
["qemu-riscv64", "-L", "C:/path/to/riscv/sysroot"]
```

同一接口也可以添加 ARM、另一款 x86 或真实远程执行包装器。平台接入的最低要求是：编译器能生成可执行文件，runner 能返回程序标准输出和退出码。当前 Demo 不自动部署到远程板卡；真实开发板可通过用户提供的执行包装器接入。

## 10. 当前局限

- 运行时间包含进程启动开销，因此更适合比较较大的输入；
- 分支数和向量数是汇编文本证据，不等同于硬件 PMU；
- 目前候选集合较小，重点是验证 EPAS 选择规则，不是穷举编译器空间；
- 当前正确性检查是固定内核输出逐字比较，不替代大规模差分测试；
- 当前没有学习模块。后续可加入仅用于候选优先级的排序器，但不得替代真实测量。

## 11. 运行测试

```powershell
py -m unittest discover -s .\tests -v
```

测试覆盖效应归一化、契约误差、最小特化选择、工具诊断、真实 GCC 编译、逐字输出比较、追加式证据保存和禁止伪性能模式等约束。
