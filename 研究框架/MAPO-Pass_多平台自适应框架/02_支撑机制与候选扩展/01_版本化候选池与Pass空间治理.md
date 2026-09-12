# 版本化候选池与 Pass 空间治理

> 定位：MAPO-Pass 的实验控制模块，不是独立创新点。

## 1. 目的

MAPO-Pass 要比较的是“不同平台如何从同一候选池选择”，而不是“谁能搜索更多候选”。候选池必须在任何真实平台测量前固定、版本化并对所有方法可见。

## 2. 第一版候选定义

以 `-O3` 基础流水线为锚点，候选由有限的局部变更产生：

- 删除或禁用一个稳定动作；
- 交换相邻的可交换动作；
- 在预定义位置插入一次有限重排；
- 调整已注册 Pass 的保守参数；
- 保留 `-O3` 作为显式回退候选。

P0 每程序使用 16–32 条候选；P2 初始建议 32 条。候选不是任意文本 Pass 管线：每条都要有稳定 `candidate_id`、序列 token、生成规则、随机种子和编译命令。

## 3. 动作白名单与排除项

优先覆盖与平台差异相关、且 LLVM 18 中可稳定执行的动作：循环展开、向量化/SLP、内联、GVN、LICM、循环旋转、循环 unswitch、load-store vectorizer、简化 CFG 与代码布局相关动作。动作名称以实际 `opt --print-passes` 和编译器版本为准。

第一版排除：依赖 profile 的 Pass、需目标专属后端修改的 Pass、未定义顺序约束的组合、会使候选语义检查不可控的变换，以及只能在某一平台编译的候选。被排除原因需要记录，而不是从结果表中消失。

## 4. 候选清单格式

每条候选至少存为 JSON 对象：

```json
{
  "candidate_id": "c017",
  "base": "O3",
  "pass_sequence": ["default<O3>", "no-loop-vectorize"],
  "generation_rule": "disable-vectorization",
  "seed": 20260718,
  "expected_scope": "loop_vectorization",
  "status": "registered"
}
```

`status` 允许 `registered`、`compile_failed`、`incorrect`、`timeout`、`accepted`，但注册后的候选不得因性能不佳被删除。

## 5. 公平性检查

- 所有方法使用同一候选 ID 集合和同一候选顺序随机化种子；
- MAPO-Pass 的目标平台微基准测量计入预算；
- 任意方法的编译失败、超时和不正确均计入其已尝试单元；
- 在比较前冻结候选 manifest 的哈希；
- 不依据目标平台结果增加或替换候选。

## 6. 与主线的关系

候选池只提供可比较的决策空间。即使候选池由随机搜索、专家规则或受限 LLM 生成，MAPO-Pass 的核心问题仍是“响应指纹条件化的共享—残差收益建模是否在等预算下有效”。
