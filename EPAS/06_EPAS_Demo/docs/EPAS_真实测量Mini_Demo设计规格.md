# EPAS 真实测量 Mini Demo 设计规格

## 1. 目标

本 Demo 用最小工程量验证 EPAS 的核心闭环：给定一条带有效应契约的编译知识，系统生成有限的通用候选与架构增量候选，通过真实编译、真实运行和汇编分析获得平台效应观测，选择满足契约的最小架构增量，并追加保存完整实验轨迹。

Demo 首先在当前 Windows x86 主机和 MinGW GCC 上运行。RISC-V 使用同一平台接口，但在工具链或运行器不存在时明确返回 `unavailable`，不得生成模拟性能。

## 2. 永久约束：不使用世界模型

本项目在任何阶段都不使用世界模型。Demo 中禁止出现以下行为：

- 学习或预测编译状态转移；
- 虚拟执行 Pass 或编译参数；
- imagined rollout；
- 生成合成运行时间、硬件计数器或奖励；
- 用预测结果替代真实编译和真实运行；
- 提供 `--simulate` 性能模式。

允许使用确定性的规则生成有限候选，也允许后续加入监督式候选排序，但候选最终必须接受真实编译和目标平台测量。

## 3. 非目标

第一版不实现：

- 完整 LLVM Pass 管线；
- LLM、强化学习或 Adapter 训练；
- LLVM 后端源码修改；
- 性能计数器驱动的复杂代价模型；
- 自动安装 Clang、RISC-V 工具链或 QEMU；
- 未见架构泛化结论；
- 多机器分布式调度。

## 4. 交付位置

实现源位于：

```text
work/epas_demo/
```

验证通过后同步到：

```text
outputs/EPAS_Demo/
C:\Users\2025111355\Desktop\EPAS\06_EPAS_Demo\
```

桌面目录只保存通过测试的交付副本，不直接作为开发目录。

## 5. 目录结构

```text
EPAS_Demo/
├── README.md
├── bench.c
├── epas_demo.py
├── contracts.json
├── candidates.json
├── platforms.json
├── run.ps1
├── tests/
│   └── test_epas_demo.py
├── build/                 # 运行时创建，不纳入交付初始文件
└── results/               # 运行时创建，追加实验轨迹
```

全部 Python 代码只使用标准库，避免额外安装依赖。

## 6. 基准程序

`bench.c` 提供两个可重复内核：

1. `branch`：含数据相关分支，观察展开、分支和代码尺寸效应；
2. `vector`：规则数组运算，观察自动向量化及关闭向量化的差异。

命令行格式为：

```text
bench.exe <branch|vector> <problem_size>
```

程序只向标准输出写入确定性校验值。相同内核和输入规模下，不同编译候选必须得到完全相同的输出，否则候选标记为 `incorrect`，不参与选择。

## 7. 编译知识与效应契约

第一版提供三条知识：

### K1：运行效率保持

- 前置条件：候选可编译且输出正确；
- 意图：减少真实运行时间；
- 效应：`runtime_gain` 为正，代码尺寸和分支数量不得严重恶化；
- 槽位：优化级别、循环展开、目标架构参数；
- 验证：输出一致、运行时间和汇编指标可采集。

### K2：代码紧凑保持

- 前置条件：候选可编译且输出正确；
- 意图：减小二进制；
- 效应：`size_reduction` 为正，运行时间退化不超过契约阈值；
- 槽位：`-Os`、内联相关开关；
- 验证：输出一致、二进制存在且大小可测。

### K3：向量机会保持

- 前置条件：规则数组内核；
- 意图：保留或增加向量实现机会；
- 效应：汇编中的向量寄存器或向量指令证据增加，运行时间不得明显恶化；
- 槽位：向量化开关、`-march`；
- 验证：输出一致、汇编证据和运行时间同时存在。

契约保存在 `contracts.json`，采用每个效应维度的最低目标、权重和总体误差阈值，不把自然语言描述直接作为算法输入。

## 8. 候选与最小架构增量

第一版候选包括：

| 候选 | GCC 参数 | 角色 |
|---|---|---|
| `O2_baseline` | `-O2` | 测量基线 |
| `O3_generic` | `-O3` | 通用性能配方 |
| `Os_generic` | `-Os` | 通用尺寸配方 |
| `O3_unroll` | `-O3 -funroll-loops` | 展开槽位增量 |
| `O3_no_vector` | `-O3 -fno-tree-vectorize` | 向量化反例 |
| `O3_native` | `-O3 -march=native` | x86 架构参数增量 |

`candidates.json` 为每个候选记录 `base_recipe`、`delta_slots` 和适用平台。架构增量成本定义为：

$$
\Omega(\delta)=|delta\_slots|+\lambda_{arch}\,I(architecture\_specific).
$$

这不是学习模型复杂度，而是当前候选相对于通用配方新增了多少架构特有决策。

## 9. 真实测量与效应观测

每个候选执行以下步骤：

```text
检查编译器
→ 生成汇编
→ 生成可执行文件
→ 用固定小输入获取正确输出
→ 与 O2_baseline 输出逐字节比较
→ warm-up
→ 重复运行 N 次
→ 记录中位数、最小值、最大值和 MAD
→ 统计二进制大小、条件分支和向量证据
```

禁止使用 `shell=True`。每次子进程调用都使用参数数组、超时和返回码检查。

以 `O2_baseline` 为平台内基线，构造：

$$
\Phi_h(P,c)=[runtime\_gain,size\_reduction,branch\_reduction,vector\_increase].
$$

所有分量均为相对基线的无量纲变化。绝对运行时间、文件大小和汇编计数同时保留，便于复核。

## 10. 效应保持误差

对契约中的每个最低目标 `target_j`，定义违反量：

$$
v_j=\max(0,target_j-\Phi_{h,j}).
$$

总体误差为：

$$
G_h(K,c)=\sum_j w_jv_j.
$$

候选只有在以下条件全部成立时才被视为满足契约：

- 编译成功；
- 输出正确；
- 指标完整；
- `G_h(K,c)` 不超过契约阈值。

`G_h` 是确定性的测量后评分函数，不预测未来状态或性能。

## 11. 选择规则

对每条知识，选择过程为：

1. 过滤不可编译、错误输出和平台不合法候选；
2. 计算真实 `Φ_h` 和 `G_h`；
3. 在满足契约的候选中最小化 `Ω(δ)`；
4. 增量成本相同时，优先真实运行时间更短的候选；
5. 若没有候选满足契约，输出 `contract_unsatisfied`，同时记录 `G_h` 最小的诊断候选，但不得把它写成成功特化。

该规则直接验证“满足效应约束所需的最小架构增量”，而不是简单选择最快候选。

## 12. 平台接口

`platforms.json` 至少包含：

- `x86_local_gcc`：当前本机 GCC，runner 为空；
- `riscv64_template`：RISC-V 编译器、sysroot 和 runner 模板。

平台检查命令：

```powershell
py epas_demo.py doctor --platform x86_local_gcc
py epas_demo.py doctor --platform riscv64_template
```

若编译器、sysroot 或 runner 不可用，`doctor` 和 `run` 都返回结构化 `unavailable`，列出缺失组件。程序不得降级到模拟性能。

## 13. 结果保存

每次运行创建唯一 `run_id`，并写入：

```text
results/trials.jsonl        # 每个候选一行，永久追加
results/runs/<run_id>.json  # 本次完整记录
results/latest_summary.csv  # 便于查看的本次摘要
```

记录至少包含：平台、编译器版本、主机信息、时间戳、Git/源码哈希、知识 ID、候选、完整命令、正确性、原始测量、`Φ_h`、`G_h`、`Ω(δ)`、选择状态和错误信息。已有历史结果不得覆盖。

## 14. 命令行体验

```powershell
# 环境检查
.\run.ps1 -Doctor

# 快速真实实验
.\run.ps1 -Quick

# 完整真实实验
.\run.ps1 -Repeats 7

# 指定平台和知识
py epas_demo.py run --platform x86_local_gcc --contract runtime_efficiency --repeats 5

# 查看 RISC-V 缺失组件，不生成模拟数据
py epas_demo.py doctor --platform riscv64_template
```

`-Quick` 只减少输入规模和重复次数，仍然执行真实编译与真实运行。

## 15. 错误处理

- 编译失败：记录命令、返回码和标准错误，继续其他候选；
- 运行超时：标记 `timeout`，继续其他候选；
- 输出不一致：标记 `incorrect`，禁止进入契约选择；
- 基线失败：终止当前实验，因为无法计算 `Φ_h`；
- 指标解析失败：保存原始汇编，标记对应指标缺失；
- 结果写入失败：保留当前运行目录并返回非零退出码；
- 平台不可用：输出缺失组件，不创建伪实验记录。

## 16. 测试设计

实现采用测试驱动开发。测试覆盖：

1. `normalize_effects()` 的方向和零基线处理；
2. `contract_error()` 的权重、阈值和边界；
3. `delta_cost()` 对通用候选与架构候选的区分；
4. `select_minimal_specialization()` 优先满足契约、再最小增量、最后比较运行时间；
5. 错误输出候选永不被选择；
6. 无候选满足时返回 `contract_unsatisfied`；
7. JSONL 追加而非覆盖；
8. RISC-V 工具缺失时返回 `unavailable` 且没有模拟结果；
9. 本机 GCC 可用时执行真实编译 smoke test；
10. `--quick` 仍产生 `measured: true` 的真实结果。

## 17. 验收标准

Demo 完成必须同时满足：

- `python -m unittest discover -s tests -v` 全部通过；
- `doctor` 正确识别本机 GCC 和缺失的 RISC-V 工具；
- x86 quick 模式至少成功编译并测量 4 个候选；
- 所有有效候选输出与基线完全一致；
- 至少计算一条完整 `Φ_h`、`G_h` 和 `Ω(δ)`；
- 选择结果明确区分 `selected` 与 `contract_unsatisfied`；
- 连续运行两次后 `trials.jsonl` 行数增加而不是被覆盖；
- 输出中不存在 `simulated: true`、虚拟性能或世界模型 rollout；
- 工作区、输出目录和桌面交付副本哈希一致；
- README 能让用户在 PowerShell 中独立完成环境检查和 quick 实验。

## 18. 后续扩展边界

完成第一版后可以：

- 安装 Clang/LLVM，将候选从编译参数扩展为 Pass 宏动作；
- 接入 RISC-V QEMU 做功能验证，再接真实 RISC-V 设备测性能；
- 增加 `perf`、PMU 或设备侧计数器；
- 使用监督式排序减少真实候选测量数；
- 增加第三平台执行 leave-one-platform-out。

无论如何扩展，都继续使用真实编译与真实平台测量，不引入世界模型、虚拟 rollout 或合成硬件反馈。
