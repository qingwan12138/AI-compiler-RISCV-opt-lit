# EPAS Real-Measurement Mini Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable EPAS Mini Demo that uses real GCC compilation and execution to evaluate effect contracts and select the smallest architecture delta, while never using a world model or synthetic performance data.

**Architecture:** `epas_core.py` owns deterministic EPAS math and selection, `epas_runner.py` owns platform checks and real measurements, and `epas_demo.py` orchestrates CLI runs and persistent results. JSON files define contracts, candidates, and platforms; C code provides deterministic branch and vector kernels. Every reported `Phi`, `G`, and selection decision is derived from real artifacts and runs.

**Tech Stack:** Python 3 standard library, `unittest`, MinGW GCC, C11, PowerShell 5+.

**Approved Spec:** `docs/superpowers/specs/2026-07-13-epas-real-measurement-demo-design.md`

## Global Constraints

- No world model, compiler-state transition predictor, virtual Pass execution, imagined rollout, or model-based planning at any stage.
- No synthetic runtime, PMU counters, rewards, or `--simulate` performance mode.
- Predictors may later choose candidates to measure, but may never supply `Phi_h`, `G_h`, or paper evidence.
- Missing RISC-V tools must produce structured `unavailable`; never fall back to fake data.
- Python dependencies are standard-library only.
- All subprocess calls use argument lists, `shell=False`, explicit timeouts, and checked return codes.
- Candidate correctness is exact stdout equality with the `O2_baseline` for the same kernel and input.
- Results append to JSONL and create a unique per-run JSON; prior trials are never overwritten.
- Development location: `work/epas_demo/`; verified copies: `outputs/EPAS_Demo/` and `C:\Users\2025111355\Desktop\EPAS\06_EPAS_Demo\`.
- This workspace is not a Git repository. Replace commit steps with a checkpoint containing the exact passing test command and SHA-256 manifest.

---

## File Map

- `work/epas_demo/epas_core.py`: normalized effects, contract error, delta cost, minimal specialization selection.
- `work/epas_demo/epas_runner.py`: tool doctor, subprocess execution, compilation, correctness, timing, assembly metrics.
- `work/epas_demo/epas_demo.py`: `doctor` and `run` CLI, orchestration, persistence, human-readable summary.
- `work/epas_demo/bench.c`: deterministic `branch` and `vector` kernels.
- `work/epas_demo/contracts.json`: K1–K3 effect contracts.
- `work/epas_demo/candidates.json`: GCC candidates and architecture delta metadata.
- `work/epas_demo/platforms.json`: local x86 and RISC-V template tools.
- `work/epas_demo/run.ps1`: one-command Windows entry point.
- `work/epas_demo/README.md`: operation, output semantics, limitations, RISC-V configuration.
- `work/epas_demo/tests/test_core.py`: EPAS math and selection tests.
- `work/epas_demo/tests/test_runner.py`: doctor, assembly metrics, output equality, and real GCC tests.
- `work/epas_demo/tests/test_cli.py`: CLI, append persistence, unavailable behavior, and anti-simulation guard.

---

### Task 1: EPAS Core Math and Selection

**Files:**
- Create: `work/epas_demo/epas_core.py`
- Create: `work/epas_demo/tests/test_core.py`

**Interfaces:**
- Produces: `normalize_effects(baseline, candidate) -> dict[str, float]`
- Produces: `contract_error(contract, effects) -> float`
- Produces: `delta_cost(candidate, architecture_penalty=1.0) -> float`
- Produces: `select_minimal_specialization(contract, evaluated) -> dict`

- [ ] **Step 1: Write failing normalization and error tests**

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from epas_core import contract_error, normalize_effects

class EffectTests(unittest.TestCase):
    def test_normalize_effects_uses_positive_is_better_directions(self):
        baseline = {"runtime_seconds": 10.0, "binary_bytes": 1000,
                    "branch_count": 20, "vector_count": 2}
        candidate = {"runtime_seconds": 8.0, "binary_bytes": 900,
                     "branch_count": 15, "vector_count": 4}
        self.assertEqual(normalize_effects(baseline, candidate), {
            "runtime_gain": 0.2, "size_reduction": 0.1,
            "branch_reduction": 0.25, "vector_increase": 1.0,
        })

    def test_contract_error_only_penalizes_unmet_minimums(self):
        contract = {"effects": {
            "runtime_gain": {"min": 0.10, "weight": 2.0},
            "size_reduction": {"min": -0.20, "weight": 1.0},
        }}
        self.assertAlmostEqual(contract_error(contract, {
            "runtime_gain": 0.04, "size_reduction": -0.10,
        }), 0.12)
```

- [ ] **Step 2: Run tests and verify RED**

Run: `py -m unittest work/epas_demo/tests/test_core.py -v`

Expected: import failure for missing `epas_core`.

- [ ] **Step 3: Implement normalized effects and contract error**

```python
def _relative_reduction(base: float, value: float) -> float:
    if base == 0:
        return 0.0 if value == 0 else -float(value)
    return (float(base) - float(value)) / abs(float(base))

def normalize_effects(baseline, candidate):
    vector_base = float(baseline["vector_count"])
    vector_value = float(candidate["vector_count"])
    vector_increase = ((vector_value - vector_base) / max(1.0, abs(vector_base)))
    return {
        "runtime_gain": _relative_reduction(baseline["runtime_seconds"], candidate["runtime_seconds"]),
        "size_reduction": _relative_reduction(baseline["binary_bytes"], candidate["binary_bytes"]),
        "branch_reduction": _relative_reduction(baseline["branch_count"], candidate["branch_count"]),
        "vector_increase": vector_increase,
    }

def contract_error(contract, effects):
    return sum(
        float(rule.get("weight", 1.0)) * max(0.0, float(rule["min"]) - float(effects[name]))
        for name, rule in contract["effects"].items()
    )
```

- [ ] **Step 4: Add failing delta and selector tests**

```python
from epas_core import delta_cost, select_minimal_specialization

class SelectionTests(unittest.TestCase):
    def test_delta_cost_counts_slots_and_architecture_penalty(self):
        self.assertEqual(delta_cost({"delta_slots": ["unroll"], "architecture_specific": False}), 1.0)
        self.assertEqual(delta_cost({"delta_slots": ["march"], "architecture_specific": True}), 2.0)

    def test_selector_prefers_contract_satisfaction_then_minimal_delta(self):
        contract = {"threshold": 0.05}
        evaluated = [
            {"candidate": "fast_large_delta", "status": "measured", "correct": True,
             "contract_error": 0.0, "delta_cost": 2.0, "runtime_seconds": 0.8},
            {"candidate": "minimal", "status": "measured", "correct": True,
             "contract_error": 0.01, "delta_cost": 1.0, "runtime_seconds": 1.0},
        ]
        result = select_minimal_specialization(contract, evaluated)
        self.assertEqual(result["status"], "selected")
        self.assertEqual(result["winner"]["candidate"], "minimal")
```

- [ ] **Step 5: Verify RED, then implement minimal selector**

```python
def delta_cost(candidate, architecture_penalty=1.0):
    return float(len(candidate.get("delta_slots", []))) + (
        float(architecture_penalty) if candidate.get("architecture_specific", False) else 0.0
    )

def select_minimal_specialization(contract, evaluated):
    valid = [row for row in evaluated if row.get("status") == "measured" and row.get("correct")]
    satisfying = [row for row in valid if row["contract_error"] <= float(contract["threshold"])]
    if satisfying:
        winner = min(satisfying, key=lambda row: (
            row["delta_cost"], row["runtime_seconds"], row["candidate"]
        ))
        return {"status": "selected", "winner": winner}
    if valid:
        diagnostic = min(valid, key=lambda row: (
            row["contract_error"], row["delta_cost"], row["runtime_seconds"]
        ))
        return {"status": "contract_unsatisfied", "diagnostic": diagnostic}
    return {"status": "no_valid_candidate"}
```

- [ ] **Step 6: Run Task 1 tests**

Run: `py -m unittest work/epas_demo/tests/test_core.py -v`

Expected: all Task 1 tests pass.

- [ ] **Step 7: Record non-Git checkpoint**

Run tests, then record SHA-256 for `epas_core.py` and `test_core.py` in the execution log.

---

### Task 2: Configuration and Platform Doctor

**Files:**
- Create: `work/epas_demo/platforms.json`
- Create: `work/epas_demo/contracts.json`
- Create: `work/epas_demo/candidates.json`
- Create: `work/epas_demo/epas_runner.py`
- Create: `work/epas_demo/tests/test_runner.py`

**Interfaces:**
- Produces: `load_json(path) -> dict`
- Produces: `doctor(platform) -> dict`
- Produces: `resolve_executable(command) -> str | None`

- [ ] **Step 1: Write failing doctor tests**

```python
import unittest
from epas_runner import doctor

class DoctorTests(unittest.TestCase):
    def test_missing_compiler_is_unavailable_without_fake_metrics(self):
        result = doctor({"compiler": "definitely-missing-epas-compiler", "runner": []})
        self.assertEqual(result["status"], "unavailable")
        self.assertIn("compiler", result["missing"])
        self.assertNotIn("runtime_seconds", result)
```

- [ ] **Step 2: Verify RED and implement doctor**

```python
import json, shutil
from pathlib import Path

def load_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

def resolve_executable(command):
    return shutil.which(command)

def doctor(platform):
    missing = []
    compiler = resolve_executable(platform["compiler"])
    if not compiler:
        missing.append("compiler")
    runner = platform.get("runner", [])
    if runner and not resolve_executable(runner[0]):
        missing.append("runner")
    return {
        "status": "available" if not missing else "unavailable",
        "compiler": compiler,
        "missing": missing,
    }
```

- [ ] **Step 3: Add concrete JSON configurations**

`platforms.json` defines `x86_local_gcc` with compiler `gcc`, no runner, executable suffix `.exe`; `riscv64_template` defines `riscv64-linux-gnu-gcc` and `qemu-riscv64`.

`contracts.json` defines `runtime_efficiency`, `code_compaction`, and `vector_exposure`, each with `kernel`, `baseline`, `effects`, and `threshold`.

`candidates.json` defines the six candidate names and flags from the approved spec, with `base_recipe`, `delta_slots`, `architecture_specific`, and `platforms`.

- [ ] **Step 4: Add configuration schema tests**

Tests assert that every contract references an existing baseline, every candidate has a list of flags and delta slots, and no configuration contains `simulated`, `synthetic_runtime`, or a world-model field.

- [ ] **Step 5: Run Task 2 tests and record checkpoint**

Run: `py -m unittest work/epas_demo/tests/test_runner.py -v`

Expected: doctor and configuration tests pass.

---

### Task 3: Real GCC Compilation, Correctness, and Measurement

**Files:**
- Create: `work/epas_demo/bench.c`
- Modify: `work/epas_demo/epas_runner.py`
- Modify: `work/epas_demo/tests/test_runner.py`

**Interfaces:**
- Produces: `run_command(argv, timeout) -> subprocess.CompletedProcess`
- Produces: `assembly_metrics(path, isa) -> dict`
- Produces: `compile_candidate(...) -> dict`
- Produces: `measure_executable(...) -> dict`
- Produces: `evaluate_candidate(...) -> dict`

- [ ] **Step 1: Write failing assembly and exact-output tests**

Create temporary assembly containing conditional jumps and `xmm` instructions; expect `assembly_metrics()` to count both. Test that `outputs_match("42\n", "42\n")` is true and whitespace/content changes are false after only normalizing line endings.

- [ ] **Step 2: Implement deterministic helpers**

```python
def outputs_match(expected, actual):
    return expected.replace("\r\n", "\n") == actual.replace("\r\n", "\n")

def median_absolute_deviation(values):
    med = statistics.median(values)
    return statistics.median(abs(value - med) for value in values)
```

`assembly_metrics()` reads text and counts conditional branch mnemonics and x86 vector register references (`xmm`, `ymm`, `zmm`). It keeps the raw assembly path in the result.

- [ ] **Step 3: Write `bench.c`**

Implement `branch_kernel(n)` with data-dependent branches and `vector_kernel(n)` with allocated float arrays and a deterministic checksum. `main()` validates kernel name and positive size, prints one checksum line, and returns nonzero on invalid input or allocation failure.

- [ ] **Step 4: Write failing real GCC smoke test**

Skip only when `shutil.which("gcc")` is absent. In a temporary directory compile `bench.c` with `-O2`, run `branch 10000` twice, and assert exact identical stdout and `measured=True`.

- [ ] **Step 5: Implement compilation and measurement**

`compile_candidate()` creates `.s` and `.exe` files with two real GCC invocations. `measure_executable()` performs one correctness run, configurable warm-ups, and repeated timed subprocess runs using `time.perf_counter_ns()`. It returns median, min, max, MAD, repeats, and `measured: True`; no branch returns synthetic values.

- [ ] **Step 6: Implement candidate evaluation**

`evaluate_candidate()` catches compilation/timeout/process errors into structured statuses, compares stdout to the baseline, gathers binary size and assembly metrics, and returns no effects until the orchestrator supplies baseline metrics.

- [ ] **Step 7: Run Task 3 tests and real smoke test**

Run: `py -m unittest work/epas_demo/tests/test_runner.py -v`

Expected: all tests pass; the GCC smoke test runs rather than skips on the current machine.

---

### Task 4: CLI Orchestration and Append-Only Results

**Files:**
- Create: `work/epas_demo/epas_demo.py`
- Create: `work/epas_demo/tests/test_cli.py`

**Interfaces:**
- Produces: `run_experiment(args) -> dict`
- Produces: `append_jsonl(path, rows) -> None`
- Produces: `write_run_json(path, record) -> None`
- Produces: `write_summary_csv(path, rows) -> None`
- CLI: `doctor` and `run` subcommands.

- [ ] **Step 1: Write failing append and selection persistence tests**

Use a temporary directory, call `append_jsonl()` twice, and assert two lines remain. Test a small measured candidate fixture flows through normalization, contract error, delta cost, and selection into a run record.

- [ ] **Step 2: Implement persistence helpers**

Use UTF-8, create parent directories, open JSONL with mode `a`, create unique UTC run IDs with microseconds, write per-run JSON, and replace only `latest_summary.csv` because it is explicitly a view of the latest run rather than historical evidence.

- [ ] **Step 3: Implement `doctor` CLI**

`py epas_demo.py doctor --platform NAME` loads platform config, prints JSON, and exits 0 for available or 2 for unavailable.

- [ ] **Step 4: Implement `run` CLI**

Parse platform, contract, repeats, warm-ups, problem size, timeout, build directory, and results directory. Refuse unknown platform/contract; refuse unavailable platform before creating trial rows. Measure baseline first, terminate on baseline failure, evaluate remaining legal candidates, calculate `Phi`, `G`, and delta cost, then call the selector.

- [ ] **Step 5: Add failure-path tests**

Tests cover unknown configuration, unavailable RISC-V returning exit 2, baseline failure halting the run, and no valid candidate returning `no_valid_candidate`.

- [ ] **Step 6: Run Task 4 tests and complete suite**

Run: `py -m unittest discover -s work/epas_demo/tests -v`

Expected: all tests pass.

---

### Task 5: PowerShell Entry Point, README, and Anti-Simulation Guard

**Files:**
- Create: `work/epas_demo/run.ps1`
- Create: `work/epas_demo/README.md`
- Modify: `work/epas_demo/tests/test_cli.py`

**Interfaces:**
- `run.ps1 -Doctor`, `run.ps1 -Quick`, and full run options.

- [ ] **Step 1: Write failing repository guard test**

The test scans `.py` and `.json` production files and fails if it finds CLI/config keys named `simulate`, `synthetic_runtime`, `world_model`, or `imagined_rollout`. Documentation may mention these only in explicit prohibition text.

- [ ] **Step 2: Implement `run.ps1`**

Resolve the script directory, find `py`, fail clearly if absent, map `-Doctor` to doctor, map `-Quick` to real `run` with size `200000` and repeats `2`, and pass full runs with configurable platform, contract, repeats, warm-ups, and size.

- [ ] **Step 3: Write README**

Document prerequisites, exact commands, contract interpretation, output files, the distinction between `selected` and `contract_unsatisfied`, RISC-V setup, and the permanent world-model/no-fake-measurement constraints. State that quick mode is real measurement.

- [ ] **Step 4: Run tests and command help**

Run:

```powershell
py -m unittest discover -s work/epas_demo/tests -v
py work/epas_demo/epas_demo.py --help
py work/epas_demo/epas_demo.py doctor --platform x86_local_gcc
py work/epas_demo/epas_demo.py doctor --platform riscv64_template
```

Expected: tests pass, x86 is available, RISC-V is unavailable with missing compiler/runner, and no synthetic metrics appear.

---

### Task 6: Real Quick Experiment, Re-run Persistence, and Delivery

**Files:**
- Runtime create: `work/epas_demo/build/`
- Runtime create: `work/epas_demo/results/`
- Create delivery: `outputs/EPAS_Demo/`
- Create delivery: `C:\Users\2025111355\Desktop\EPAS\06_EPAS_Demo\`

**Interfaces:**
- Produces verified runnable package and real measured sample results.

- [ ] **Step 1: Run full tests immediately before experiment**

Run: `py -m unittest discover -s work/epas_demo/tests -v`

Expected: all tests pass with zero failures.

- [ ] **Step 2: Run a real quick experiment twice**

Run twice:

```powershell
py work/epas_demo/epas_demo.py run --platform x86_local_gcc --contract runtime_efficiency --repeats 2 --warmups 1 --size 200000
```

Expected: at least four candidates have `status=measured`, all selected-valid candidates have exact baseline output, and every measured row has `measured=true`.

- [ ] **Step 3: Verify append-only evidence**

Record line count after run 1 and run 2. Expected: `trials.jsonl` increases by the number of evaluated candidates; two unique files exist under `results/runs/`.

- [ ] **Step 4: Verify EPAS fields**

Inspect latest run JSON. Expected: every valid non-baseline candidate includes `effects`, `contract_error`, and `delta_cost`; top-level selection is one of `selected`, `contract_unsatisfied`, or `no_valid_candidate`.

- [ ] **Step 5: Create clean deliveries**

Copy source/config/tests/docs plus a `sample_results/` directory containing the verified run JSON and summary. Exclude transient executables and assembly from the clean package unless referenced by sample results. Copy first to `outputs/EPAS_Demo`, verify, then to desktop with explicit permission.

- [ ] **Step 6: Run final package verification**

Verify:

- source/output/desktop file inventories match;
- SHA-256 hashes match for every delivered file;
- strict UTF-8 for Markdown/JSON/Python/PowerShell/C;
- no production `simulate`, synthetic metric, world-model state transition, or rollout implementation;
- all JSON parses;
- all tests pass when run from `outputs/EPAS_Demo`;
- x86 doctor and quick experiment work from the delivered package;
- RISC-V doctor reports unavailable without fake data.

- [ ] **Step 7: Record final non-Git checkpoint**

Write a SHA-256 manifest and verification summary under `outputs/EPAS_Demo/VERIFICATION.md`. Do not offer merge or PR actions because the workspace is non-Git.
