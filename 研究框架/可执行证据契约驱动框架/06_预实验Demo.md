# 预实验 Demo：证据契约驱动的 LLM 编译优化智能体

## 1. Demo 目标

这个 Demo 不直接证明最终论文主张，只验证一条最小闭环：

> LLM Agent 提出优化候选和证据契约，编译器工具独立检查编译、正确性、编译证据和真实性能，只有通过全部门控的候选才能进入记忆。

实验对象是 SAXPY 内核：<code>y[i] = a * x[i] + y[i]</code>。第一版使用 GCC，因为当前环境没有 clang、mlir-opt 或 opt；以后替换编译器或平台时，证据契约格式保持不变。

## 2. 对比条件

| 条件 | 说明 |
|---|---|
| Direct-LLM | LLM 直接输出修改后的 C 代码，不要求结构化证据 |
| Contract-LLM | LLM 同时输出候选动作、前提、预期证据和否定条件 |
| Stub Agent | 暂时不用 LLM，使用固定候选验证后端闭环 |
| GCC -O3 | 编译器默认优化基线 |

没有 LLM 时先运行 Stub Agent；有 LLM/API 后，只替换候选生成步骤。

## 3. 准备目录

在本文件夹下执行：

~~~
New-Item -ItemType Directory -Force .\demo_run | Out-Null
Set-Location .\demo_run
~~~

## 4. 创建基线程序

新建 <code>baseline.c</code>：

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

## 5. 创建 Stub Agent 候选

复制基线为 <code>candidate.c</code>，只替换 <code>saxpy</code> 函数：

~~~c
static void saxpy(int n, float a,
                  const float * restrict x,
                  float * restrict y) {
#pragma GCC ivdep
#pragma GCC unroll 4
    for (int i = 0; i < n; ++i) {
        y[i] = a * x[i] + y[i];
    }
}
~~~

<code>restrict</code> 是 C 语言中的指针承诺，表示这次调用中 <code>x</code> 和 <code>y</code> 不重叠。因此它必须作为前提写进契约，而不是被 Agent 当作无条件安全的优化。

## 6. 编译并收集证据

~~~
gcc -O3 -march=native -std=c11 -fopt-info-vec-optimized=baseline.vec.txt baseline.c -o baseline.exe
gcc -O3 -march=native -std=c11 -fopt-info-vec-optimized=candidate.vec.txt candidate.c -o candidate.exe
~~~

如果 GCC 不接受上面的文件参数，改用标准错误重定向：

~~~
gcc -O3 -march=native -std=c11 -fopt-info-vec baseline.c -o baseline.exe 2> baseline.vec.txt
gcc -O3 -march=native -std=c11 -fopt-info-vec candidate.c -o candidate.exe 2> candidate.vec.txt
~~~

查看编译证据：

~~~
Get-Content .\baseline.vec.txt
Get-Content .\candidate.vec.txt
~~~

记录是否出现 <code>optimized: loop vectorized</code> 或同义的向量化成功信息。不能因为候选代码写了 pragma 就直接声称优化已经生效。

## 7. 正确性和性能测试

先分别运行 11 次，丢弃第一次：

~~~
1..11 | ForEach-Object { .\baseline.exe } | Tee-Object .\baseline.run.txt
1..11 | ForEach-Object { .\candidate.exe } | Tee-Object .\candidate.run.txt
~~~

正确性门要求：

- 两个程序都返回退出码 0；
- checksum 的绝对差小于 <code>1e-4 * max(1, abs(baseline_checksum))</code>；
- 没有崩溃、超时或 NaN。

性能门要求：

1. 每个版本丢弃第一次运行；
2. 使用剩余 10 次的中位数；
3. 计算 <code>speedup = baseline_median / candidate_median</code>；
4. 候选只有在正确性通过且中位时间没有变慢超过 5% 时才进入“待接受”状态；
5. 最终接受还需要通过契约证据检查。

如果需要自动求中位数，可使用工作区提供的 Python：

~~~
$py = 'C:\Users\2025111355\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py -c "import statistics,re; from pathlib import Path; p=Path('baseline.run.txt'); x=[float(re.search(r'seconds=([0-9.]+)',s).group(1)) for s in p.read_text().splitlines() if 'seconds=' in s][1:]; print(statistics.median(x))"
& $py -c "import statistics,re; from pathlib import Path; p=Path('candidate.run.txt'); x=[float(re.search(r'seconds=([0-9.]+)',s).group(1)) for s in p.read_text().splitlines() if 'seconds=' in s][1:]; print(statistics.median(x))"
~~~

单个 kernel 的一次加速不能证明主线成立；本轮重点是验证门控闭环能否正确接受、拒绝和解释候选。

## 8. 证据契约

保存为 <code>contract.json</code>，第一轮可手工填写：

~~~json
{
  "action": "restrict_and_unroll_saxpy",
  "preconditions": [
    "x and y are disjoint",
    "n is positive",
    "the floating-point tolerance is fixed before testing"
  ],
  "expected_ir_evidence": [
    "the saxpy loop remains present",
    "the loop is reported as vectorized or unrolled"
  ],
  "expected_machine_evidence": [
    "compiler vectorization report is present"
  ],
  "performance_hypothesis": "The candidate median time is no more than 5 percent slower than baseline.",
  "correctness_check": "checksum difference is below the fixed tolerance",
  "falsifiers": [
    "compile failure",
    "checksum mismatch",
    "missing vectorization evidence",
    "candidate median is more than 5 percent slower"
  ],
  "decision": "pending"
}
~~~

最小裁决规则：

~~~
compile_ok AND correctness_ok AND expected_evidence_present AND performance_ok
    => accept and allow memory write
otherwise
    => reject, record failure reason, and forbid memory write
~~~

## 9. 接入 LLM Agent

把下面的提示词发给你的 LLM，要求只返回 JSON：

~~~
你是编译优化智能体。请阅读给定 C 程序，最多提出一个结构化优化候选。
必须返回 contract 和 candidate_source 两个字段。

contract 必须包含 action、preconditions、expected_ir_evidence、
expected_machine_evidence、performance_hypothesis、correctness_check、falsifiers。

候选必须保持函数语义，明确 restrict/pragma 等修改的前提，不能把“应该变快”当作证据。
如果程序不适合安全优化，可以返回 reject 及其原因。

验证器会独立编译、运行、比较 checksum、查看编译报告并测量中位时间。
只有验证器通过后，候选才允许进入长期记忆。
~~~

第一次接入时固定模型和 temperature，重复至少 10 次；否则无法区分机制收益和模型随机性。

## 10. 对照和消融

| 条件 | 目的 |
|---|---|
| GCC 默认 -O3 | 现实基线 |
| Direct-LLM | 检查没有契约时的编译、正确性和性能 |
| Contract-LLM | 检查完整机制 |
| 去掉否定条件 | 检查反证字段是否有作用 |
| 去掉编译报告 | 检查真实编译证据是否必要 |
| 去掉记忆门控 | 检查偶然成功是否污染后续候选 |

所有条件使用相同的模型、候选预算、编译器和运行次数。

## 11. 记录表

至少记录 10 次尝试，不能只保留成功案例：

| trial | condition | compile | correctness | evidence | baseline_median | candidate_median | speedup | decision | failure_reason |
|---:|---|---|---|---|---:|---:|---:|---|---|
| 1 | Stub/Direct/Contract | pass/fail | pass/fail | pass/fail | — | — | — | accept/reject | — |

## 12. 预实验成功标准

1. 基线和候选都能稳定编译运行；
2. 正确性门能捕获一个故意制造的错误候选；
3. 编译器证据能区分“声明了向量化”和“实际报告向量化”；
4. Contract-LLM 能拒绝至少一个不满足前提的候选，或给出可解释失败原因；
5. 结果表同时包含成功、失败和拒绝。

性能没有提升不等于 Demo 失败。如果证据契约能可靠拒绝错误解释，这仍然验证了主线闭环的一部分。

## 13. 结果解释

- 编译成功但 checksum 错误：正确性门有效，候选必须拒绝。
- checksum 正确但没有预期编译证据：机制解释不成立，只进入待验证区。
- 证据成立但性能变慢：记录为性能反例或负迁移。
- 性能变快且证据成立：允许写入已验证记忆，但仍需更多 kernel 验证。
- Direct-LLM 与 Contract-LLM 没有差异：说明当前 Demo 尚未证明契约价值，应增加反例或未见输入，而不是直接扩大模型。

## 14. 后续扩展

1. 增加 dot product 和 reduction 两个 kernel；
2. 将 C 文件切换为 MLIR Transform 或 LLVM Pass 动作；
3. 在第二个平台重复相同契约格式；
4. 加入硬件响应摘要，比较有无硬件反馈时的迁移和拒绝率；
5. 最后再加入 RISC-V/RVV 平台，不改变主线定义。

本 Demo 只能验证候选生成、证据契约、确定性工具裁决和记忆门控的最小闭环，不能单独证明通用 LLM 编译优化能力。
