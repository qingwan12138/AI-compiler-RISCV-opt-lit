# CrossTune-RL 最小 Demo

这是一个可操作的端到端闭环：IR 策略模块按平台特征排列候选优化，后端评价模块编译、运行并采集 LLVM IR 指令数、二进制大小和运行时间，最后选出真实运行最快的候选。它不训练双 LLM，目的是先验证研究框架的数据流和实验管线。

## 立即运行

需要 Python 3（建议从 python.org 安装并加入 PATH）。没有 LLVM 时，可先运行模拟模式查看完整流程：

```powershell
.\run.ps1 -Simulate
```

安装 LLVM 并确保 `clang` 在 PATH 后，运行真实 x86 实验：

```powershell
.\run.ps1
```

结果保存在 `build/results.json`。真实实验会测试 `-O1/-O2/-O3/-Os`、循环展开和关闭向量化等候选；每个候选生成 LLVM IR 和本机二进制，并以运行时间中位数排序。

## 模块与研究框架的对应关系

- `policy_order()`：最小 IR 优化策略。读取平台特征，决定优先探索哪些候选。
- `real()`：平台条件化后端评价器。负责编译、运行、正确性基本检查和指标采集。
- `platforms.json`：平台表示与工具配置。当前含 x86 和 RISC-V 模板。
- `bench.c`：小型分支与整数计算基准程序。

这里的策略只是可解释的打分规则，以后可替换为 LLM、分类器或强化学习策略；后端评价接口保持不变。

## 接入 RISC-V

编辑 `platforms.json` 中的 `riscv64`：

1. 安装支持 RISC-V 的 clang 和 `qemu-riscv64`，或把 `runner` 改为设备上的 SSH 执行包装器。
2. 如果交叉工具链需要 sysroot，填写 `sysroot`。
3. 若设备支持向量扩展，将 `features.vector` 调整为 `1.0`，并按需要在候选参数中加入 `-march`/`-mabi`。
4. 运行：

```powershell
.\run.ps1 -Platform riscv64
```

注意：QEMU 测得的是模拟性能；论文实验应由真实设备执行文件并返回稳定计时结果。

## 下一步可扩展项

1. 将平台特征替换为 microbenchmark 采集的硬件行为指纹。
2. 保存同一候选在 x86 与 RISC-V 上的配对结果，分析共享效应和平台特定效应。
3. 让策略根据历史 `results.json` 更新候选得分，形成最小 bandit/RL 循环。
4. 增加程序输出基准文件、warm-up、CPU 绑核和更多重复测量，以满足正式实验要求。
