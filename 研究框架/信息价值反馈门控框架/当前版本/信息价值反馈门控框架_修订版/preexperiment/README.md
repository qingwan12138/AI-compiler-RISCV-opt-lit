# P0 机制冒烟预实验

本目录把 `../04_预实验Demo.md` 的 P0 核心流程实现成可执行实验。

当前版本用于验证实验管线，而不是验证论文假设：

- 10 个 C 函数任务，覆盖 loop、branch、memory、call、mixed 五类模式；
- 每个任务构造 2 个状态，共 20 个配对状态；
- 每个状态执行 `N0`、`N1`、`MatchedPlacebo`、`RealFeedback`，共 80 次条件运行；
- 每个候选均经过编译、固定测试、随机差分测试、ASan/UBSan 和 LLVM IR 指令计数；
- 输出逐条 JSONL、条件汇总 CSV、运行清单和中文结论。

## 重要限制

本机仓库没有可调用的 LLM 客户端配置。本版本的候选由 `offline_fixture_v1` 固定生成，以验证配对、门控、计费和统计代码。`RealFeedback` 的候选是预先编写的正确简化，不能据此声称真实反馈优于安慰剂，也不能据此决定进入 P1。

## 运行

在仓库根目录的 PowerShell 中执行：

```powershell
wsl.exe -e /bin/bash --noprofile --norc -c "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd '/mnt/c/Users/cjh/AI-compiler-RISCV-opt-lit/09_LLM_AI编译器低开销创新框架/01_可验证结构化编辑驱动的LLM编译优化器/信息价值反馈门控框架_修订版/preexperiment'; python3 p0_runner.py"
```

快速自测：

```powershell
py -m unittest discover -s "09_LLM_AI编译器低开销创新框架/01_可验证结构化编辑驱动的LLM编译优化器/信息价值反馈门控框架_修订版/preexperiment/tests" -v
```

结果写入 `results/<run_id>/`，`results/latest.txt` 指向最近一次运行。

