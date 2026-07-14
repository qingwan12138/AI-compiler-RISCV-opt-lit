# CrossTune-RL 最小 Demo：设计与操作文档

## 1. Demo 目标

本 Demo 用于验证 CrossTune-RL 的最小端到端闭环：

> IR 优化策略根据目标平台特征选择候选优化动作，后端评价模块将候选程序编译到目标平台，采集 LLVM IR 指令数、二进制大小和真实运行时间，并根据真实性能选择最优候选。

第一版不训练完整的双 LLM，也不要求立即实现复杂强化学习。重点是先验证以下数据流能够稳定运行：

```text
C 程序
   ↓
IR 优化候选生成
   ↓
平台条件化候选排序
   ↓
编译到目标平台
   ↓
运行并采集真实性能
   ↓
选择最优候选
   ↓
保存轨迹供后续学习
```

现有 Demo 已提供 x86 配置和 RISC-V 接口模板。没有 LLVM 时，也可以使用模拟模式检查完整流程和结果格式。

---

## 2. Demo 与研究框架的关系

完整 CrossTune-RL 包含 IR 优化智能体、平台条件化后端智能体、真实硬件环境以及跨平台知识学习机制。最小 Demo 使用可解释规则替代尚未训练的模型。

| 完整研究模块 | 最小 Demo 实现 | 后续替换方向 |
|---|---|---|
| IR 优化智能体 | `policy_order()` 规则策略 | LLM、分类模型或 RL 策略 |
| IR 动作空间 | Clang 优化级别和可控参数 | LLVM Pass、Pass 宏动作 |
| 后端智能体 | 编译、运行和指标排序模块 | 平台条件化策略网络 |
| 平台表示 | `platforms.json` 中的人工特征 | 硬件行为指纹 |
| 真实环境奖励 | 运行时间中位数 | 周期、能耗和多目标奖励 |
| 策略学习 | 暂不训练 | Bandit、PPO、MAPPO 或离线 RL |
| 跨平台迁移 | 预留平台配置 | 效应分解与少样本适应 |

因此，该 Demo 不是最终论文算法，而是实验管线原型。它能够提前验证编译、部署、计时、结果保存和平台切换接口。

---

## 3. 目录结构

Demo 位于：

```text
outputs/crosstune_minidemo/
├── bench.c                 # 小型 C 基准程序
├── crosstune_demo.py       # 策略、编译、运行和结果采集
├── platforms.json          # x86 与 RISC-V 平台配置
├── run.ps1                 # Windows 一键运行脚本
├── README.md               # 简要操作说明
└── build/
    ├── *.ll                # 真实实验生成的 LLVM IR
    ├── O1/O2/...           # 不同优化候选的二进制文件
    └── results.json        # 结构化实验结果
```

---

## 4. 当前优化动作

Demo 使用六组 Clang 参数模拟 IR 智能体的动作空间：

| 候选名称 | 编译参数 | 含义 |
|---|---|---|
| `O1` | `-O1` | 基础优化 |
| `O2` | `-O2` | 常规性能优化 |
| `O3` | `-O3` | 激进性能优化 |
| `Os` | `-Os` | 代码尺寸优先 |
| `O3_unroll` | `-O3 -funroll-loops` | 激进优化并展开循环 |
| `O3_no_vector` | `-O3 -fno-vectorize -fno-slp-vectorize` | 关闭向量化 |

这些动作并不等于单个 LLVM Pass，但能以最低工程成本验证：不同优化行为在不同平台上的真实性能结果可能不同。

下一阶段可以将动作替换为：

```text
控制流简化：simplifycfg + instcombine
循环规范化：loop-simplify + lcssa + indvars
内存优化：sroa + early-cse + dse
循环展开：loop-unroll
向量化准备：loop-rotate + indvars
代码尺寸优化：globaldce + mergefunc
```

---

## 5. 平台表示和简单策略

`platforms.json` 当前包含三个简化特征：

```json
{
  "vector": 1.0,
  "code_size_sensitive": 0.2,
  "branch_cost": 0.7
}
```

含义如下：

- `vector`：平台使用向量化的潜在能力；
- `code_size_sensitive`：平台对代码膨胀的敏感程度；
- `branch_cost`：分支相关开销的简化描述。

策略模块根据这些特征为候选优化打分。例如：

- 向量能力较强时，提高 `O3_unroll` 的探索优先级；
- 对代码尺寸敏感时，提高 `Os` 的优先级；
- 不支持向量能力时，提高 `O3_no_vector` 的优先级。

该规则仅用于演示：

$$
\text{平台表示}
\rightarrow
\text{候选优化排序}
$$

后续应当使用实际测量得到的行为指纹代替人工填写的特征。

---

## 6. 环境要求

### 6.1 模拟模式

只需要：

- Windows PowerShell；
- Python 3。

模拟模式不会真实编译程序，而是生成固定范围内的实验结果，用于检查：

- 策略候选排序；
- 表格输出；
- JSON 保存；
- 平台配置切换。

### 6.2 真实 x86 实验

需要：

- Python 3；
- LLVM/Clang；
- `clang` 已加入系统 PATH。

检查命令：

```powershell
python --version
clang --version
```

### 6.3 RISC-V 实验

至少需要以下一种环境：

1. RISC-V Clang 交叉编译器加 QEMU；
2. RISC-V 交叉编译器加真实开发板；
3. 在 RISC-V 设备本机运行编译与测试脚本。

正式论文实验建议使用真实硬件，QEMU 主要用于检查编译和功能正确性。

---

## 7. 一键运行

首先进入 Demo 目录：

```powershell
cd "C:\Users\17599\Documents\Codex\2026-07-12\referenced-chatgpt-conversation-this-is-untrusted\outputs\crosstune_minidemo"
```

### 7.1 运行模拟 x86 实验

```powershell
.\run.ps1 -Simulate
```

也可以直接使用 Python：

```powershell
python crosstune_demo.py --platform x86 --simulate
```

### 7.2 运行真实 x86 实验

安装 LLVM/Clang 后执行：

```powershell
.\run.ps1
```

等价命令：

```powershell
python crosstune_demo.py --platform x86
```

### 7.3 调整重复次数和候选数量

```powershell
python crosstune_demo.py --platform x86 --repeats 5 --candidates 6
```

建议正式实验至少运行 5～10 次，并使用中位数降低测量噪声。

### 7.4 运行 RISC-V 模拟配置

```powershell
.\run.ps1 -Platform riscv64 -Simulate
```

### 7.5 运行 RISC-V 真实配置

配置好交叉编译器、sysroot 和运行器后执行：

```powershell
.\run.ps1 -Platform riscv64
```

---

## 8. 输出结果说明

终端会输出类似结果：

```text
platform: x86 winner: O3_unroll
candidate         IR inst      bytes    seconds
O3_unroll              61      23000   0.076630
O3                     48      20200   0.082088
O2                     49      19500   0.089321
Os                     51      18100   0.097561
```

各指标含义：

- `IR inst`：对生成的 LLVM IR 进行近似统计得到的指令数；
- `bytes`：目标二进制文件大小；
- `seconds`：程序多次运行时间的中位数；
- `winner`：当前平台上运行时间最短的候选。

完整结果保存在：

```text
build/results.json
```

主要字段包括：

```json
{
  "platform": "x86",
  "platform_features": {},
  "policy_candidates": [],
  "winner": "O3_unroll",
  "results": []
}
```

其中 `simulated: true` 表示模拟结果，不能用于论文性能结论；只有 `simulated: false` 才表示真实编译运行结果。

---

## 9. RISC-V 接入方法

编辑 `platforms.json` 中的 `riscv64` 配置：

```json
{
  "description": "RISC-V cross target",
  "clang_target": "riscv64-linux-gnu",
  "sysroot": "你的 sysroot 路径",
  "runner": ["qemu-riscv64"],
  "features": {
    "vector": 0.0,
    "code_size_sensitive": 0.8,
    "branch_cost": 0.5
  }
}
```

如果使用真实 RISC-V 设备，建议新增一个运行包装脚本，完成：

```text
复制二进制到设备
    ↓
在设备上运行多次
    ↓
检查输出正确性
    ↓
返回中位运行时间
```

后端评价模块只需调用统一的 runner 接口，不需要改变 IR 策略代码。

---

## 10. 如何用 Demo 验证研究动机

### 实验一：IR 指标与真实性能是否一致

比较每个候选的：

$$
\Delta N_{IR}
\quad\text{与}\quad
\Delta T_{runtime}
$$

观察是否存在：

- IR 指令数减少，但运行时间上升；
- IR 指令数增加，但运行时间下降；
- 二进制尺寸增大，但性能改善；
- 同一个优化候选在不同平台上的排名发生变化。

这些现象可以直接支撑“IR 优化必须接受真实后端性能反馈”的研究动机。

### 实验二：平台条件化策略是否必要

比较：

1. 所有平台使用固定候选顺序；
2. 使用人工平台特征排序；
3. 使用硬件行为指纹排序；
4. 使用学习型策略排序。

指标包括：

- 最终找到的最佳运行时间；
- 找到最佳候选所需的编译次数；
- Top-K 候选召回率。

### 实验三：同一优化的跨平台效应

让同一程序、同一候选分别在 x86 和 RISC-V 上运行：

```text
程序 P + O3_unroll + x86      → 性能收益 R_x86
程序 P + O3_unroll + RISC-V   → 性能收益 R_riscv
```

形成跨平台配对数据，为优化效应分解提供基础。

---

## 11. 从最小 Demo 扩展到三项创新

### 11.1 扩展一：硬件行为指纹

新增 `probes/` 目录：

```text
probes/
├── memory_seq.c
├── memory_random.c
├── branch.c
├── dependency_chain.c
├── register_pressure.c
├── vector.c
└── icache.c
```

在每个平台上运行后，生成：

```json
{
  "memory_seq": 1.20,
  "memory_random": 4.85,
  "branch": 2.13,
  "vector": 0.72,
  "register_pressure": 1.66,
  "icache": 2.40
}
```

用该结果替换当前人工填写的 `features`。

### 11.2 扩展二：跨架构优化效应分解

对同一程序和候选收集多个平台的结果，并建模：

$$
\Delta R_h
=
R_{shared}
+
R_{platform}
+
R_{synergy}
$$

最小实现可以先采用：

- 跨平台平均收益作为共享效应；
- 当前平台收益减去平均收益作为平台残差；
- IR 动作与后端配置联合收益减去独立收益作为协同效应。

### 11.3 扩展三：未见平台主动少样本适应

将一个平台完全从训练数据中留出，例如：

```text
训练：x86_A + x86_B + ARM_A
测试：RISC-V_A
```

在 RISC-V 上分别允许：

$$
K \in \{0,5,10,20,50\}
$$

次真实校准，比较：

- 随机选择候选；
- 只选择预测最优候选；
- 选择不确定性最高候选；
- 选择源平台预测分歧最大的候选；
- 完整主动适应策略。

重点指标为：

$$
Speedup@K
$$

即在固定硬件评测预算下最终获得的加速效果。

---

## 12. 建议的开发阶段

### 阶段 A：跑通真实 x86

- 安装 LLVM/Clang；
- 运行六组候选；
- 检查 IR、二进制和运行时间；
- 保存稳定的 JSON 结果。

### 阶段 B：接入 RISC-V

- 完成交叉编译；
- 完成正确性验证；
- 接入 QEMU；
- 最终切换到真实开发板。

### 阶段 C：收集跨平台数据

- 增加 10～30 个小程序；
- 每个平台运行相同候选；
- 分析候选排名变化；
- 建立首批跨平台配对数据。

### 阶段 D：加入行为指纹

- 编写硬件探测程序；
- 自动采集平台特征；
- 用行为指纹预测候选排序；
- 与人工平台特征比较。

### 阶段 E：加入学习策略

- 先使用监督排序或多臂老虎机；
- 再加入候选生成和反馈迭代；
- 最后视实验需要引入分层 RL 或 LLM Agent。

---

## 13. Demo 成功标准

第一阶段达到以下条件即可认为 Demo 成功：

1. 同一个 C 程序能生成至少 4 种优化版本；
2. 能生成 LLVM IR 和目标平台二进制；
3. 能自动验证程序输出不为空且保持一致；
4. 能采集 IR 指令数、二进制大小和运行时间；
5. 能根据平台特征改变候选顺序；
6. 能选出当前平台上最快的候选；
7. 能将完整结果保存为 JSON；
8. x86 与 RISC-V 使用相同的评价接口。

论文级版本还需要增加：

- 严格的结果正确性对比；
- warm-up 和 CPU 绑核；
- 固定频率或记录 DVFS 状态；
- 多次重复和置信区间；
- 多程序、多输入规模和多平台；
- 与 `-O3`、随机搜索、传统搜索和单智能体方法比较。

---

## 14. 预期演示结果

完成 x86 与 RISC-V 真实测试后，最希望观察到以下结果：

```text
候选优化        x86 排名        RISC-V 排名
O3_unroll          1                4
O3                 2                1
Os                 5                2
O3_no_vector       4                3
```

如果不同平台的候选排名明显不同，就能说明：

> 单一、平台无关的 IR 优化策略难以在所有硬件上获得最佳真实性能，需要平台条件化后端反馈和跨平台知识建模。

这将成为后续硬件行为指纹、优化效应分解和未见平台适应研究的直接实验动机。

