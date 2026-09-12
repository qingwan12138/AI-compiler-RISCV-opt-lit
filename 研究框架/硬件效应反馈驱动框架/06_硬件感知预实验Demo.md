# 预实验 Demo：硬件效应反馈驱动的 LLM 编译优化智能体

## 1. Demo 目标

本 Demo 验证四件事：

1. Agent 能否读取硬件响应摘要；
2. Agent 能否生成带硬件前提的优化候选；
3. 系统能否根据反馈选择“迁移、补测或拒绝”；
4. 证据契约能否阻止错误或偶然加速进入记忆。

当前环境有 GCC，没有 clang、mlir-opt 或 opt。因此第一版使用 SAXPY 内核和 GCC。两种 GCC 目标配置只是在同一机器上做流程演示，不能冒充真实多硬件实验；真实跨硬件结论需要第二台不同架构的平台。

## 2. 三种实验条件

| 条件 | 说明 |
|---|---|
| Direct-LLM | LLM 只输出候选代码，不读取硬件摘要，也不写契约 |
| Contract-LLM | LLM 输出候选、硬件前提和完整证据契约 |
| Hardware-aware Contract-LLM | LLM 读取硬件响应摘要，决定迁移、补测或拒绝 |

没有 LLM 时先用 Stub Agent 生成固定候选，验证后面的路由器和证据门。

## 3. 准备目录和基线程序

执行：

~~~
New-Item -ItemType Directory -Force .\hardware_demo_run | Out-Null
Set-Location .\hardware_demo_run
~~~

新建 <code>saxpy.c</code>：

~~~c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N (1 << 24)
#define REPEAT 12

static void saxpy(int n, float a, const float *x, float *y) {
    for (int i = 0; i < n; ++i) {
        y[i] = a * x[i] + y[i];
    }
}

int main(void) {
    float *x = (float *)malloc(sizeof(float) * N);
    float *y = (float *)malloc(sizeof(float) * N);
    if (!x || !y) return 2;
    for (int i = 0; i < N; ++i) {
        x[i] = (float)(i % 97) * 0.01f;
        y[i] = (float)(i % 53) * 0.02f;
    }
    clock_t begin = clock();
    for (int r = 0; r < REPEAT; ++r) saxpy(N, 1.25f, x, y);
    clock_t end = clock();
    double checksum = 0.0;
    for (int i = 0; i < N; i += 1024) checksum += y[i];
    printf("seconds=%.6f checksum=%.9f\n",
           (double)(end - begin) / (double)CLOCKS_PER_SEC, checksum);
    free(x);
    free(y);
    return 0;
}
~~~

## 4. 生成两个硬件条件配置

### 配置 A：generic_x86

~~~json
{
  "platform_id": "generic_x86",
  "physical_platform": "same_machine",
  "compiler_target": "-march=x86-64",
  "responses": {
    "vector": "unknown_or_baseline",
    "cache": "measure",
    "stride": "measure",
    "branch": "measure"
  },
  "evidence_strength": "weak_same_machine_proxy"
}
~~~

### 配置 B：native_x86

~~~json
{
  "platform_id": "native_x86",
  "physical_platform": "same_machine",
  "compiler_target": "-march=native",
  "responses": {
    "vector": "native_target",
    "cache": "measure",
    "stride": "measure",
    "branch": "measure"
  },
  "evidence_strength": "weak_same_machine_proxy"
}
~~~

这两个配置用于演示“硬件条件输入如何影响路由”。它们不是两块真实硬件，不能用于声称跨架构泛化。

## 5. 收集编译和运行证据

分别编译：

~~~powershell
gcc -O3 -std=c11 -march=x86-64 -fopt-info-vec-optimized=generic.vec.txt saxpy.c -o generic.exe
gcc -O3 -std=c11 -march=native -fopt-info-vec-optimized=native.vec.txt saxpy.c -o native.exe
~~~

如果 GCC 不接受文件参数：

~~~powershell
gcc -O3 -std=c11 -march=x86-64 -fopt-info-vec saxpy.c -o generic.exe 2> generic.vec.txt
gcc -O3 -std=c11 -march=native -fopt-info-vec saxpy.c -o native.exe 2> native.vec.txt
~~~

查看后端证据：

~~~powershell
Get-Content .\generic.vec.txt
Get-Content .\native.vec.txt
~~~

运行并保存 11 次结果，丢弃第一次：

~~~powershell
1..11 | ForEach-Object { .\generic.exe } | Tee-Object .\generic.run.txt
1..11 | ForEach-Object { .\native.exe } | Tee-Object .\native.run.txt
~~~

每个配置记录：

- 编译是否成功；
- checksum 是否一致；
- 是否出现向量化报告；
- 10 次有效运行的中位时间；
- native 相对 generic 的 speedup；
- 结果是否受系统噪声影响。

## 6. Stub Agent 的硬件路由

先用固定规则模拟 Agent：

~~~text
if target_profile == native_x86:
    allow candidate "restrict + unroll 4"
elif target_profile == generic_x86:
    request one target measurement before accepting
else:
    reject transfer and run target-only search
~~~

这一步只验证路由逻辑，不声称规则已经学习到硬件规律。

## 7. 硬件条件化证据契约

为候选建立 <code>contract.json</code>：

~~~json
{
  "action": "restrict_and_unroll_saxpy",
  "program_preconditions": [
    "x and y are disjoint",
    "n is positive"
  ],
  "hardware_preconditions": [
    "target profile contains vectorization evidence",
    "target compiler accepts the requested unroll pragma"
  ],
  "expected_backend_evidence": [
    "the SAXPY loop is vectorized or unrolled"
  ],
  "performance_hypothesis": {
    "generic_x86": "request one target measurement before transfer",
    "native_x86": "candidate median is not more than 5 percent slower"
  },
  "falsifiers": [
    "compile failure",
    "checksum mismatch",
    "missing vectorization evidence",
    "candidate slowdown greater than 5 percent"
  ],
  "route": "transfer_or_measure_or_reject",
  "decision": "pending"
}
~~~

## 8. 最小路由裁决

~~~text
hardware_similarity_high AND contract_evidence_present AND correctness_ok
    => transfer

hardware_similarity_uncertain OR performance_uncertain
    => request target measurement

hardware_similarity_low OR falsifier_triggered
    => reject transfer and run target-only search
~~~

路由器输出必须包含理由，不能只输出一个标签：

~~~json
{
  "decision": "request_measurement",
  "reason": "hardware profile is a same-machine proxy and performance evidence is insufficient",
  "next_action": "run candidate 5 additional times",
  "memory_write": false
}
~~~

## 9. 接入 LLM Agent

发送给 LLM 的提示词：

~~~text
你是硬件感知的编译优化智能体。
输入包括：程序摘要、候选动作集合、硬件响应摘要和历史记忆。

请只返回 JSON，字段必须包含：
candidate、program_preconditions、hardware_preconditions、
expected_backend_evidence、performance_hypothesis、falsifiers、
route、reason。

route 只能是 transfer、request_measurement 或 reject。
不能把硬件型号名称当作性能证据。
如果硬件响应摘要不足以判断，必须选择 request_measurement 或 reject。
如果优化前提不成立，必须 reject。
~~~

第一次接入时固定模型、temperature 和候选预算，至少重复 10 次。

## 10. 对照和消融

| 条件 | 检验内容 |
|---|---|
| Direct-LLM | 没有硬件输入和证据契约时的错误率 |
| Contract-LLM | 有契约但没有硬件路由时的收益 |
| Hardware-aware Contract-LLM | 完整方法 |
| 完整方法去掉硬件响应 | 硬件反馈是否必要 |
| 完整方法把响应换成硬件 ID | 实测效应是否优于型号标签 |
| 完整方法去掉 reject | 强制迁移是否造成更多负迁移 |
| 完整方法去掉补测 | 主动测量是否节省预算 |

所有条件固定模型、候选次数、编译器和运行次数。

## 11. 记录表

至少记录 10 个候选：

| trial | profile | condition | route | compile | correctness | backend_evidence | median_time | speedup | memory_write | reason |
|---:|---|---|---|---|---|---|---:|---:|---|---|
| 1 | generic/native | Direct/Contract/Hardware-aware | transfer/measure/reject | pass/fail | pass/fail | pass/fail | — | — | yes/no | — |

核心指标：

- route accuracy：路由与充分测量后的 oracle 决策一致程度；
- false transfer rate：应该拒绝却强行迁移的比例；
- measurement saving：达到固定性能阈值少用的目标测量次数；
- evidence consistency：契约声称的后端证据实际出现的比例；
- negative transfer rate：迁移后比目标默认配置更慢的比例；
- speedup/regret：真实性能和距离高预算搜索上界的差距。

## 12. 成功标准和失败解释

预实验可以继续扩展，需要满足：

1. 至少一个候选被正确拒绝或转入补测；
2. 正确性门能捕获一个故意制造的错误候选；
3. 硬件条件字段能改变路由，而不是只出现在日志里；
4. 完整方法的 false transfer rate 低于去掉 reject 的版本；
5. 结果表同时包含 transfer、request_measurement 和 reject，或明确说明某状态尚未触发。

失败时按以下方式解释：

- 两种配置性能相同：说明同机代理不足，不能声称硬件迁移；
- 硬件反馈不改变路由：硬件模块尚未产生有效机制；
- reject 几乎全部触发：路由过于保守，应报告 coverage-risk；
- 候选变快但没有后端证据：只能记录为偶然成功，不能写入记忆；
- Direct-LLM 和完整方法无差异：说明需要更强反例或更多未见输入。

## 13. 后续真实平台实验

单机 Demo 通过后，保持同一 contract 和 route 字段，在第二个平台重复：

1. 收集同一组 microbenchmark 的响应摘要；
2. 固定程序、输入、编译器版本和运行次数；
3. 记录迁移、补测、拒绝的决策；
4. 与 target-only 和强制迁移比较；
5. RISC-V/RVV 可以作为第二或第三平台，但不改变主线标题。

本 Demo 验证的是“硬件信息是否改变 LLM Agent 决策”，不是单独证明某个硬件上的加速。
