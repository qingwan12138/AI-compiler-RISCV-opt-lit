"""Platform discovery and real-measurement helpers for the EPAS demo."""

import json
import re
import shutil
import statistics
import subprocess
import time
from pathlib import Path


def load_json(path):
    """Load one UTF-8 JSON document."""
    return json.loads(Path(path).read_text(encoding="utf-8"))


def resolve_executable(command):
    """Resolve a command using the host executable search path."""
    return shutil.which(command)


def _tool_version(executable):
    if not executable:
        return None
    try:
        completed = subprocess.run(
            [str(executable), "--version"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=True,
            shell=False,
            timeout=10,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError):
        return None
    combined = (completed.stdout or completed.stderr).strip()
    return combined.splitlines()[0] if combined else None


def doctor(platform):
    """Report whether all tools required by a platform are installed."""
    missing = []
    compiler = resolve_executable(platform["compiler"])
    if not compiler:
        missing.append("compiler")

    runner = platform.get("runner", [])
    resolved_runner = None
    if runner:
        resolved_runner = resolve_executable(runner[0])
        if not resolved_runner:
            missing.append("runner")

    return {
        "status": "available" if not missing else "unavailable",
        "compiler": compiler,
        "compiler_version": _tool_version(compiler),
        "runner": resolved_runner,
        "missing": missing,
    }


def outputs_match(expected, actual):
    """Compare program outputs exactly after normalizing only line endings."""
    return expected.replace("\r\n", "\n") == actual.replace("\r\n", "\n")


def assembly_metrics(path, isa):
    """Extract lightweight, directly observed evidence from compiler assembly."""
    assembly_path = Path(path).resolve()
    text = assembly_path.read_text(encoding="utf-8", errors="strict")
    lowered = text.lower()

    if isa == "x86":
        mnemonics = re.findall(r"^\s*([a-z][a-z0-9.]*)\b", lowered, re.MULTILINE)
        branch_count = sum(
            mnemonic.startswith("j") and mnemonic not in {"jmp", "jmpq"}
            or mnemonic.startswith("loop")
            for mnemonic in mnemonics
        )
        vector_count = len(re.findall(r"%?(?:xmm|ymm|zmm)\d+\b", lowered))
    elif isa == "riscv":
        branch_mnemonics = {
            "beq",
            "bne",
            "blt",
            "bge",
            "bltu",
            "bgeu",
            "beqz",
            "bnez",
            "blez",
            "bgez",
            "bltz",
            "bgtz",
        }
        mnemonics = re.findall(r"^\s*([a-z][a-z0-9.]*)\b", lowered, re.MULTILINE)
        branch_count = sum(mnemonic in branch_mnemonics for mnemonic in mnemonics)
        vector_count = len(re.findall(r"\bv(?:[0-9]|[12][0-9]|3[01])\b", lowered))
    else:
        raise ValueError("Unsupported ISA for assembly evidence: {}".format(isa))

    return {
        "branch_count": branch_count,
        "vector_count": vector_count,
        "assembly_path": str(assembly_path),
    }


def run_command(argv, timeout):
    """Run one checked subprocess without shell interpretation."""
    return subprocess.run(
        [str(item) for item in argv],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=True,
        shell=False,
        timeout=float(timeout),
    )


def median_absolute_deviation(values):
    """Return the median absolute deviation for observed timings."""
    median = statistics.median(values)
    return statistics.median(abs(value - median) for value in values)


def compile_candidate(source_path, candidate, platform, build_dir, timeout=60):
    """Compile one candidate to a real executable and a real assembly file."""
    source_path = Path(source_path).resolve()
    build_dir = Path(build_dir).resolve()
    build_dir.mkdir(parents=True, exist_ok=True)

    compiler = resolve_executable(platform["compiler"])
    if compiler is None:
        raise FileNotFoundError("compiler is unavailable: {}".format(platform["compiler"]))

    stem = candidate["name"]
    executable = build_dir / (stem + platform.get("executable_suffix", ""))
    assembly = build_dir / (stem + ".s")
    common = [compiler, "-std=c11"] + list(candidate["flags"])
    executable_command = common + [str(source_path), "-o", str(executable)]
    assembly_command = common + ["-S", str(source_path), "-o", str(assembly)]

    run_command(executable_command, timeout)
    run_command(assembly_command, timeout)

    return {
        "status": "compiled",
        "candidate": candidate["name"],
        "compiler": compiler,
        "executable": str(executable),
        "assembly": str(assembly),
        "commands": {
            "executable": executable_command,
            "assembly": assembly_command,
        },
    }


def _execution_argv(executable, platform, kernel, size):
    runner = list(platform.get("runner", []))
    return runner + [str(Path(executable).resolve()), str(kernel), str(int(size))]


def measure_executable(
    executable,
    platform,
    kernel,
    size,
    repeats=5,
    warmups=1,
    timeout=30,
):
    """Execute a compiled program and return only directly observed timings."""
    if int(repeats) <= 0:
        raise ValueError("repeats must be positive")
    if int(warmups) < 0:
        raise ValueError("warmups must be non-negative")
    if int(size) <= 0:
        raise ValueError("size must be positive")

    argv = _execution_argv(executable, platform, kernel, size)
    correctness_run = run_command(argv, timeout)
    expected_output = correctness_run.stdout

    for _ in range(int(warmups)):
        warmup = run_command(argv, timeout)
        if not outputs_match(expected_output, warmup.stdout):
            raise RuntimeError("program output changed during warm-up")

    timings = []
    for _ in range(int(repeats)):
        start_ns = time.perf_counter_ns()
        measured_run = run_command(argv, timeout)
        elapsed = (time.perf_counter_ns() - start_ns) / 1_000_000_000.0
        if not outputs_match(expected_output, measured_run.stdout):
            raise RuntimeError("program output changed during timed runs")
        timings.append(elapsed)

    return {
        "measured": True,
        "stdout": expected_output,
        "runtime_seconds": statistics.median(timings),
        "runtime_min_seconds": min(timings),
        "runtime_max_seconds": max(timings),
        "runtime_mad_seconds": median_absolute_deviation(timings),
        "timings_seconds": timings,
        "repeats": int(repeats),
        "warmups": int(warmups),
        "execution_command": argv,
    }


def _failure_row(candidate, status, error):
    return {
        "candidate": candidate["name"],
        "flags": list(candidate["flags"]),
        "status": status,
        "measured": False,
        "correct": False,
        "error": str(error),
    }


def evaluate_candidate(
    source_path,
    candidate,
    platform,
    build_dir,
    kernel,
    size,
    repeats,
    warmups,
    timeout,
    expected_output=None,
):
    """Compile, execute, verify, and inspect one real candidate."""
    try:
        compiled = compile_candidate(
            source_path,
            candidate,
            platform,
            build_dir,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        return _failure_row(candidate, "compile_timeout", error)
    except (subprocess.CalledProcessError, FileNotFoundError, OSError) as error:
        detail = getattr(error, "stderr", None) or error
        return _failure_row(candidate, "compile_failed", detail)

    try:
        measured = measure_executable(
            compiled["executable"],
            platform,
            kernel,
            size,
            repeats=repeats,
            warmups=warmups,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        return _failure_row(candidate, "run_timeout", error)
    except (subprocess.CalledProcessError, RuntimeError, ValueError, OSError) as error:
        detail = getattr(error, "stderr", None) or error
        return _failure_row(candidate, "run_failed", detail)

    correct = (
        True
        if expected_output is None
        else outputs_match(expected_output, measured["stdout"])
    )
    row = {
        "candidate": candidate["name"],
        "flags": list(candidate["flags"]),
        "status": "measured",
        "correct": correct,
        "binary_bytes": Path(compiled["executable"]).stat().st_size,
        "executable_path": compiled["executable"],
        "assembly_path": compiled["assembly"],
        "compile_commands": compiled["commands"],
    }
    row.update(measured)

    try:
        evidence = assembly_metrics(compiled["assembly"], platform["isa"])
    except (UnicodeError, ValueError, OSError) as error:
        row["status"] = "metric_failed"
        row["error"] = str(error)
        return row

    row.update(evidence)
    return row
