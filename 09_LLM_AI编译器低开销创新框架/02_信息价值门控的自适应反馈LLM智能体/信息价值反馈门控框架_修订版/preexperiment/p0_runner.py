#!/usr/bin/env python3
"""Executable P0 mechanics smoke experiment for the feedback-value gate demo.

The candidate generator is deliberately labelled as an offline fixture.  It
exercises the validation and accounting pipeline but is not an LLM experiment.
"""

import argparse
import csv
import hashlib
import json
import os
import random
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


CONDITIONS = ("N0", "N1", "MatchedPlacebo", "RealFeedback")
GENERATOR_MODE = "offline_fixture_v1"
EPSILON_STATIC = 0.01

TASKS = (
    ("sum_u32", "loop", "uint64_t r = 0;", "r += v;"),
    ("xor_u32", "loop", "uint64_t r = 0;", "r ^= v;"),
    ("count_even", "branch", "uint64_t r = 0;", "r += ((v & 1u) == 0u);"),
    ("count_nonzero", "branch", "uint64_t r = 0;", "r += (v != 0u);"),
    ("max_u32", "memory", "uint64_t r = 0;", "if (v > r) r = v;"),
    ("sum_low_byte", "memory", "uint64_t r = 0;", "r += (v & 255u);"),
    ("weighted_3", "call", "uint64_t r = 0;", "r += (uint64_t)v * 3u;"),
    ("weighted_5", "call", "uint64_t r = 0;", "r += (uint64_t)v * 5u;"),
    ("sum_shift1", "mixed", "uint64_t r = 0;", "r += (v >> 1);"),
    ("sum_mask16", "mixed", "uint64_t r = 0;", "r += (v & 65535u);"),
)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def run_command(cmd, timeout=60):
    start = time.time()
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              universal_newlines=True, timeout=timeout)
        return {
            "command": cmd,
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "elapsed_s": round(time.time() - start, 6),
            "timeout": False,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "command": cmd,
            "returncode": None,
            "stdout": exc.stdout or "",
            "stderr": exc.stderr or "",
            "elapsed_s": round(time.time() - start, 6),
            "timeout": True,
        }


def optimized_body(init, update):
    return """{init}
    for (size_t i = 0; i < n; ++i) {{
        uint32_t v = a[i];
        {update}
    }}
    return r;""".format(init=init, update=update)


def baseline_body(state_index, init, update):
    if state_index == 0:
        return """{init}
    for (size_t i = 0; i < n; ++i) {{
        uint32_t v = a[i];
        if (v == v) {{
            {update}
        }} else {{
            {update}
        }}
    }}
    return r;""".format(init=init, update=update)
    return """{init}
    for (size_t i = 0; i < n; ++i) {{
        uint32_t v = a[i];
        {update}
        r += 0u;
    }}
    return r;""".format(init=init, update=update)


def candidate_body(condition, task_index, state_index, init, update):
    base = baseline_body(state_index, init, update)
    if condition == "RealFeedback":
        return optimized_body(init, update)
    if condition == "N1":
        return "/* paired no-feedback seed retest */\n    " + base
    if condition == "MatchedPlacebo":
        mode = (task_index + state_index) % 5
        if mode == 0:
            return base.replace("return r;", "return r")  # compile gate path
        if mode == 1:
            return base.replace("return r;", "return r + 1u;")  # correctness gate path
        return "/* matched but task-irrelevant diagnostic */\n    " + base
    return base


def feedback_text(condition, task_id, state_id):
    if condition == "RealFeedback":
        return ("IR feedback for {0}/{1}: both paths perform the same update or "
                "the zero addition is redundant; preserve unsigned semantics and "
                "remove only that redundant structure.").format(task_id, state_id)
    if condition == "MatchedPlacebo":
        return ("IR feedback for a different task: a nearby loop may contain a "
                "redundant branch or neutral arithmetic operation; inspect the "
                "unrelated diagnostic while preserving unsigned semantics.")
    return ""


def make_source(candidate, reference):
    return r'''#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

static uint64_t candidate(const uint32_t *a, size_t n) {
    CANDIDATE_BODY
}

static uint64_t reference_impl(const uint32_t *a, size_t n) {
    REFERENCE_BODY
}

static int check(const uint32_t *a, size_t n) {
    uint64_t got = candidate(a, n);
    uint64_t expected = reference_impl(a, n);
    if (got != expected) {
        fprintf(stderr, "mismatch n=%zu got=%llu expected=%llu\n", n,
                (unsigned long long)got, (unsigned long long)expected);
        return 1;
    }
    return 0;
}

static uint32_t next_u32(uint32_t *state) {
    *state = (*state * 1664525u) + 1013904223u;
    return *state;
}

int main(int argc, char **argv) {
    uint32_t fixed0[] = {0u};
    uint32_t fixed1[] = {1u, 2u, 3u, 4u, 0xffffffffu};
    uint32_t fixed2[] = {0u, 0u, 17u, 255u, 256u, 65535u, 65536u};
    if (argc == 2 && strcmp(argv[1], "--fixed") == 0) {
        return check(fixed0, 0) || check(fixed0, 1) ||
               check(fixed1, sizeof(fixed1) / sizeof(fixed1[0])) ||
               check(fixed2, sizeof(fixed2) / sizeof(fixed2[0]));
    }
    uint32_t data[96];
    uint32_t seed = 0x5eed1234u;
    for (size_t trial = 0; trial < 64; ++trial) {
        size_t n = next_u32(&seed) % 97u;
        for (size_t i = 0; i < n; ++i) data[i] = next_u32(&seed);
        if (check(data, n)) return 1;
    }
    return 0;
}
'''.replace("CANDIDATE_BODY", candidate).replace("REFERENCE_BODY", reference)


def count_ir_instructions(text):
    count = 0
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith((";", "source_filename", "target ",
                                                "declare ", "define ", "attributes ", "!")):
            continue
        if stripped.endswith(":") or stripped == "}":
            continue
        if (re.match(r"^%[-a-zA-Z$._0-9]+\s*=", stripped) or
                re.match(r"^(store|br|ret|switch|indirectbr|invoke|resume|unreachable|call)\b", stripped)):
            count += 1
    return count


def bootstrap_mean_ci(values, seed=20260719, draws=4000):
    if not values:
        return (0.0, 0.0)
    rng = random.Random(seed)
    n = len(values)
    means = []
    for _ in range(draws):
        means.append(sum(values[rng.randrange(n)] for _ in range(n)) / float(n))
    means.sort()
    lo = means[int(0.025 * (draws - 1))]
    hi = means[int(0.975 * (draws - 1))]
    return (lo, hi)


def compile_and_validate(clang, source_path, slot, baseline_ir_count):
    exe = slot / "candidate.exe"
    ir = slot / "candidate.ll"
    san = slot / "candidate_san.exe"
    compile_result = run_command([clang, "-std=c11", "-O0", "-Wall", "-Wextra",
                                  str(source_path), "-o", str(exe)])
    out = {
        "compile": compile_result,
        "fixed_test": None,
        "random_test": None,
        "sanitizer_compile": None,
        "sanitizer_test": None,
        "ir_compile": None,
        "ir_instruction_count": None,
        "static_gain": 0.0,
        "correctness": False,
    }
    if compile_result["returncode"] != 0:
        out["status"] = "compile_failed"
        return out
    out["fixed_test"] = run_command([str(exe), "--fixed"])
    out["random_test"] = run_command([str(exe), "--random"])
    out["sanitizer_compile"] = run_command([
        clang, "-std=c11", "-O0", "-fsanitize=address,undefined",
        "-fno-omit-frame-pointer", str(source_path), "-o", str(san)
    ])
    if out["sanitizer_compile"]["returncode"] == 0:
        san_env = os.environ.copy()
        san_env["ASAN_OPTIONS"] = "detect_leaks=0:halt_on_error=1"
        start = time.time()
        proc = subprocess.run([str(san), "--random"], stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, universal_newlines=True,
                              timeout=60, env=san_env)
        out["sanitizer_test"] = {
            "command": [str(san), "--random"], "returncode": proc.returncode,
            "stdout": proc.stdout, "stderr": proc.stderr,
            "elapsed_s": round(time.time() - start, 6), "timeout": False,
        }
    out["ir_compile"] = run_command([
        clang, "-std=c11", "-O0", "-S", "-emit-llvm", str(source_path), "-o", str(ir)
    ])
    if out["ir_compile"]["returncode"] == 0 and ir.exists():
        out["ir_instruction_count"] = count_ir_instructions(ir.read_text(encoding="utf-8"))
    passed = (
        out["fixed_test"]["returncode"] == 0 and
        out["random_test"]["returncode"] == 0 and
        out["sanitizer_compile"]["returncode"] == 0 and
        out["sanitizer_test"] is not None and
        out["sanitizer_test"]["returncode"] == 0
    )
    out["correctness"] = passed
    out["status"] = "accepted" if passed else "incorrect"
    if passed and baseline_ir_count and out["ir_instruction_count"] is not None:
        out["static_gain"] = max(
            0.0, (baseline_ir_count - out["ir_instruction_count"]) / float(baseline_ir_count)
        )
    return out


def compact_tool_result(result):
    if result is None:
        return None
    return {
        "command": result["command"],
        "returncode": result["returncode"],
        "elapsed_s": result["elapsed_s"],
        "timeout": result["timeout"],
        "stdout_sha256": sha256_bytes(result["stdout"].encode("utf-8")),
        "stderr_tail": result["stderr"][-1200:],
    }


def execute_condition(clang, run_dir, task_index, task, state_index, condition,
                      baseline_ir_count):
    task_id, family, init, update = task
    state_id = "S{0}".format(state_index + 1)
    slot = run_dir / "artifacts" / task_id / state_id / condition
    slot.mkdir(parents=True, exist_ok=True)
    reference = optimized_body(init, update)
    body = candidate_body(condition, task_index, state_index, init, update)
    source = make_source(body, reference)
    source_path = slot / "candidate.c"
    source_path.write_text(source, encoding="utf-8")
    validation = compile_and_validate(clang, source_path, slot, baseline_ir_count)
    feedback = feedback_text(condition, task_id, state_id)
    tool_calls = sum(1 for key in ("compile", "fixed_test", "random_test",
                                    "sanitizer_compile", "sanitizer_test", "ir_compile")
                     if validation.get(key) is not None)
    record = {
        "run_id": run_dir.name,
        "timestamp": utc_now(),
        "task_id": task_id,
        "program_family": family,
        "state_id": state_id,
        "paired_seed_block": 20260719 + task_index * 2 + state_index,
        "condition": condition,
        "generator_mode": GENERATOR_MODE,
        "feedback_type": "real" if condition == "RealFeedback" else
                         "matched_placebo" if condition == "MatchedPlacebo" else "none",
        "feedback_chars": len(feedback),
        "candidate_sha256": sha256_bytes(source.encode("utf-8")),
        "status": validation["status"],
        "correctness": validation["correctness"],
        "ir_instruction_count": validation["ir_instruction_count"],
        "static_gain": round(validation["static_gain"], 8),
        "utility": round(validation["static_gain"], 8)
                   if validation["correctness"] and validation["static_gain"] >= EPSILON_STATIC else 0.0,
        "cost": {
            "input_token_proxy": len(feedback.split()),
            "output_token_proxy": len(body.split()),
            "tool_calls": tool_calls,
            "wall_time_s": round(sum(validation[key]["elapsed_s"]
                                     for key in ("compile", "fixed_test", "random_test",
                                                 "sanitizer_compile", "sanitizer_test", "ir_compile")
                                     if validation.get(key) is not None), 6),
        },
        "tools": {key: compact_tool_result(validation.get(key))
                  for key in ("compile", "fixed_test", "random_test",
                              "sanitizer_compile", "sanitizer_test", "ir_compile")},
    }
    return record


def write_outputs(run_dir, records, compiler_version):
    by_state = {}
    for rec in records:
        by_state.setdefault((rec["task_id"], rec["state_id"]), {})[rec["condition"]] = rec
    for conditions in by_state.values():
        n0_utility = conditions["N0"]["utility"]
        for rec in conditions.values():
            rec["delta_utility"] = round(rec["utility"] - n0_utility, 8)
            rec["beneficial_change"] = rec["delta_utility"] > 0

    with (run_dir / "records.jsonl").open("w", encoding="utf-8") as handle:
        for rec in records:
            handle.write(json.dumps(rec, ensure_ascii=False, sort_keys=True) + "\n")

    rows = []
    for condition in CONDITIONS:
        subset = [r for r in records if r["condition"] == condition]
        deltas = [r["delta_utility"] for r in subset]
        ci = bootstrap_mean_ci(deltas)
        rows.append({
            "condition": condition,
            "states": len(subset),
            "accepted": sum(r["correctness"] for r in subset),
            "beneficial_change_rate": sum(r["beneficial_change"] for r in subset) / float(len(subset)),
            "mean_delta_utility": sum(deltas) / float(len(deltas)),
            "ci95_low": ci[0],
            "ci95_high": ci[1],
            "mean_ir_instructions": sum((r["ir_instruction_count"] or 0) for r in subset) / float(len(subset)),
            "tool_calls": sum(r["cost"]["tool_calls"] for r in subset),
            "wall_time_s": sum(r["cost"]["wall_time_s"] for r in subset),
        })
    with (run_dir / "summary.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    manifest = {
        "run_id": run_dir.name,
        "created_at": utc_now(),
        "phase": "P0-mechanics-smoke",
        "generator_mode": GENERATOR_MODE,
        "research_evidence": False,
        "reason_not_research_evidence": "Candidates are deterministic offline fixtures, not outputs from a fixed LLM.",
        "tasks": len(TASKS),
        "states": len(TASKS) * 2,
        "condition_runs": len(records),
        "conditions": list(CONDITIONS),
        "epsilon_static": EPSILON_STATIC,
        "compiler_version": compiler_version,
        "python_version": sys.version,
        "platform": sys.platform,
    }
    (run_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    real = next(row for row in rows if row["condition"] == "RealFeedback")
    placebo = next(row for row in rows if row["condition"] == "MatchedPlacebo")
    report = """# P0 机制冒烟预实验结果

- 运行编号：`{run_id}`
- 任务/状态/条件运行：{tasks} / {states} / {runs}
- 编译器：`{compiler}`
- 候选生成器：`{generator}`（离线固定夹具）
- RealFeedback 数值上的有益变化率：{real_rate:.1%}
- MatchedPlacebo 数值上的有益变化率：{placebo_rate:.1%}

## 结论

编译、固定测试、随机差分测试、Sanitizer、LLVM IR 指令计数、正确性门控、配对 DeltaUtility、bootstrap 区间和成本记录管线已贯通。

**不能据此进入 P1。** RealFeedback 候选由人工固定夹具直接提供，数值差异只证明验证器能识别预置的正确简化，不证明真实 LLM 能利用反馈，也不证明真实反馈优于匹配安慰剂。下一步必须接入一个固定模型与冻结 Prompt，重新生成四条件候选后才可执行文档中的 P0 停止门槛。
""".format(
        run_id=run_dir.name, tasks=len(TASKS), states=len(TASKS) * 2,
        runs=len(records), compiler=compiler_version.splitlines()[0],
        generator=GENERATOR_MODE,
        real_rate=real["beneficial_change_rate"],
        placebo_rate=placebo["beneficial_change_rate"],
    )
    (run_dir / "结论.md").write_text(report, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--clang", default="clang")
    parser.add_argument("--run-id", default=datetime.now().strftime("p0-smoke-%Y%m%dT%H%M%SZ"))
    parser.add_argument("--results-dir", default=str(Path(__file__).resolve().parent / "results"))
    args = parser.parse_args()

    clang = shutil.which(args.clang)
    if not clang:
        print("clang not found; run this script in WSL or pass --clang", file=sys.stderr)
        return 2
    version_result = run_command([clang, "--version"])
    compiler_version = version_result["stdout"].strip()
    results_root = Path(args.results_dir)
    run_dir = results_root / args.run_id
    if run_dir.exists():
        print("run directory already exists: {0}".format(run_dir), file=sys.stderr)
        return 2
    run_dir.mkdir(parents=True)

    records = []
    total = len(TASKS) * 2 * len(CONDITIONS)
    completed = 0
    for task_index, task in enumerate(TASKS):
        for state_index in range(2):
            n0 = execute_condition(clang, run_dir, task_index, task, state_index, "N0", None)
            baseline_ir = n0["ir_instruction_count"]
            records.append(n0)
            completed += 1
            print("[{0:02d}/{1}] {2}/S{3}/N0: {4}".format(
                completed, total, task[0], state_index + 1, n0["status"]))
            for condition in CONDITIONS[1:]:
                rec = execute_condition(clang, run_dir, task_index, task, state_index,
                                        condition, baseline_ir)
                records.append(rec)
                completed += 1
                print("[{0:02d}/{1}] {2}/S{3}/{4}: {5}".format(
                    completed, total, task[0], state_index + 1, condition, rec["status"]))
    write_outputs(run_dir, records, compiler_version)
    results_root.mkdir(parents=True, exist_ok=True)
    (results_root / "latest.txt").write_text(args.run_id + "\n", encoding="utf-8")
    print("Results: {0}".format(run_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())

