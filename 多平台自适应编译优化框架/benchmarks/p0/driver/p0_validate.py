#!/usr/bin/env python3
"""P0 validation: small subset to verify pipeline end-to-end."""
import csv, hashlib, json, os, subprocess, time
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent.parent.parent
WORK = BASE / "benchmarks" / "p0" / "work"
RUNS = BASE / "benchmarks" / "p0" / "runs"
PB_INC = BASE / "benchmarks/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench/utilities"

TARGETS = {
    "x86_64": {"runner": None},
    "aarch64-linux-gnu": {"runner": ["qemu-aarch64", "-L", "/usr/aarch64-linux-gnu"]},
    "riscv64-linux-gnu": {"runner": ["qemu-riscv64", "-L", "/usr/riscv64-linux-gnu"]},
}

def sha256(data):
    return hashlib.sha256(data).hexdigest()

# Only test 1 PolyBench + 1 TSVC, 4 candidates each
PROGRAMS = [
    {"id": "polybench_gemm", "family": "linear_algebra",
     "src": "benchmarks/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench/linear-algebra/blas/gemm/gemm.c",
     "flags": ["-DSMALL_DATASET", "-DPOLYBENCH_DUMP_ARRAYS", "-DFP_ABSTOLERANCE=1e-5", "-DPOLYBENCH_USE_C99_PROTO", "-I", str(PB_INC)]},
    {"id": "tsvc_controlflow_dbl", "family": "tsvc",
     "src": "benchmarks/sources/llvm-test-suite/MultiSource/Benchmarks/TSVC/ControlFlow-dbl/tsc.c",
     "other": ["benchmarks/sources/llvm-test-suite/MultiSource/Benchmarks/TSVC/ControlFlow-dbl/dummy.c"],
     "flags": ["-DUSE_CLOCK"]},
]

CANDIDATES = ["O0_ref", "O1_base", "O3_base", "Os_base"]

# Build references
refs = {}
for p in PROGRAMS:
    pid = p["id"]
    if p["family"] == "tsvc":
        src = BASE / p["src"]
        other = [BASE / s for s in p["other"]]
        r = subprocess.run(["clang", "-O0"] + p["flags"] + [str(src)] + [str(s) for s in other] + ["-lm", "-o", f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
        if r.returncode != 0: print(f"{pid} ref BUILD FAIL"); continue
        r2 = subprocess.run([f"/tmp/ref_{pid}", "2325", "14"], capture_output=True, text=True, timeout=30)
        refs[pid] = {"output": r2.stdout.encode(), "sha256": sha256(r2.stdout.encode())}
    else:
        src = BASE / p["src"]
        r = subprocess.run(["clang", "-O0"] + p["flags"] + [str(src), "-lm", "-o", f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
        if r.returncode != 0: print(f"{pid} ref BUILD FAIL: {r.stderr[:200]}"); continue
        r2 = subprocess.run([f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
        refs[pid] = {"output": r2.stderr.encode(), "sha256": sha256(r2.stderr.encode())}
    print(f"Ref {pid}: {refs[pid]['sha256'][:16]}...")

# Compile & execute
records = []
for p in PROGRAMS:
    pid = p["id"]
    ref = refs.get(pid)
    if not ref: continue
    for cid in CANDIDATES:
        for target, cfg in TARGETS.items():
            # Compile
            bin_path = WORK / f"{pid}_{cid}_{target}"
            if p["family"] == "tsvc":
                src = BASE / p["src"]; other = [BASE / s for s in p.get("other", [])]
                cmd = ["clang"] + cfg["runner"][:0] if cfg["runner"] else []
                cmd = ["clang"] + (["--target=" + target.replace("-linux-gnu","")] if target != "x86_64" else [])
                cmd += ["--gcc-toolchain=/usr"] if target != "x86_64" else []
                # Map target to clang triple
                triple_map = {"x86_64":"","aarch64-linux-gnu":"aarch64-linux-gnu","riscv64-linux-gnu":"riscv64-linux-gnu"}
                # Use candidate definition from manifest
                cand_map = {"O0_ref":["-O0"],"O1_base":["-O1"],"O3_base":["-O3"],"Os_base":["-Os"]}
                flags = cand_map[cid] + p["flags"]
                cmd = ["clang"]
                if target != "x86_64":
                    cmd += [f"--target={target}", "--gcc-toolchain=/usr"]
                cmd += flags + [str(src)] + [str(s) for s in other] + ["-lm", "-o", str(bin_path)]
            else:
                cand_map = {"O0_ref":["-O0"],"O1_base":["-O1"],"O3_base":["-O3"],"Os_base":["-Os"]}
                flags = cand_map[cid] + p["flags"]
                cmd = ["clang"]
                if target != "x86_64":
                    cmd += [f"--target={target}", "--gcc-toolchain=/usr"]
                cmd += flags + [str(src), "-lm", "-o", str(bin_path)]

            print(f"Compile {pid} {cid} @ {target}...", end=" ", flush=True)
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if r.returncode != 0:
                print(f"FAIL: {r.stderr[:100]}")
                records.append({"run_id":"p0_validate","program_id":pid,"input_id":"ALL","target_triple":target,"candidate_id":cid,"correctness_status":"compile_failed","simulated_or_qemu_only":target!="x86_64"})
                continue
            print("OK")

            # Execute (1 input for PolyBench, 1 for TSVC)
            for inp_id in ["default"]:
                print(f"  Run {cid} @ {target} [{inp_id}]...", end=" ", flush=True)
                args_list = ["2325", "14"] if p["family"] == "tsvc" else []
                if cfg["runner"]:
                    exec_cmd = cfg["runner"] + [str(bin_path)] + args_list
                else:
                    exec_cmd = [str(bin_path)] + args_list
                try:
                    r2 = subprocess.run(exec_cmd, capture_output=True, text=True, timeout=30)
                    if r2.returncode < 0 or r2.returncode > 127:
                        print("CRASHED"); status = "crashed"
                    else:
                        out = r2.stdout.encode() if p["family"] == "tsvc" else r2.stderr.encode()
                        h = sha256(out)
                        if h == ref["sha256"]:
                            print("OK"); status = "accepted"
                        else:
                            print(f"MISMATCH ({h[:12]}...)"); status = "incorrect"
                except subprocess.TimeoutExpired:
                    print("TIMEOUT"); status = "run_timeout"

                records.append({"run_id":"p0_validate","program_id":pid,"program_family":p["family"],"input_id":inp_id,"target_triple":target,"compiler_version":"clang-18.1.3","candidate_id":cid,"pass_sequence":json.dumps(cand_map[cid]),"compile_command":" ".join(str(c) for c in cmd),"binary_hash":"","correctness_status":status,"timeout_status":status=="run_timeout","stdout_hash":"","stderr_path":"","ir_features_path":"","assembly_features_path":"","simulated_or_qemu_only":target!="x86_64","timestamp":datetime.now(timezone.utc).isoformat()})

# Write output
run_dir = RUNS / "p0_validate"
run_dir.mkdir(parents=True, exist_ok=True)
with open(run_dir / "candidates.jsonl", "w") as f:
    for rec in records:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
with open(run_dir / "summary.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["target","program","candidate","total","accepted","incorrect","failed"])
    for t in TARGETS:
        for p in PROGRAMS:
            for c in CANDIDATES:
                s = [r for r in records if r["target_triple"]==t and r["program_id"]==p["id"] and r["candidate_id"]==c]
                if not s: continue
                acc=sum(1 for r in s if r["correctness_status"]=="accepted")
                inc=sum(1 for r in s if r["correctness_status"]=="incorrect")
                fail=sum(1 for r in s if r["correctness_status"] not in ("accepted","incorrect"))
                w.writerow([t,p["id"],c,len(s),acc,inc,fail])

print(f"\n=== Results: {len(records)} records ===")
for t in TARGETS:
    s = [r for r in records if r["target_triple"]==t]
    acc = sum(1 for r in s if r["correctness_status"]=="accepted")
    print(f"  {t}: {len(s)} records, {acc} accepted")
print(f"Run dir: {run_dir}")
