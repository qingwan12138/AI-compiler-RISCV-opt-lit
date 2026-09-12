#!/usr/bin/env python3
"""P0 validation v2 - clean, no variable leaks."""
import csv, hashlib, json, os, subprocess, sys
from datetime import datetime, timezone

BASE = "/mnt/c/Users/cjh/AI-compiler-RISCV-opt-lit/多平台自适应编译优化框架"
MANIFEST = f"{BASE}/benchmarks/p0/manifest"
PB_INC = f"{BASE}/benchmarks/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench/utilities"

# Load manifests
prog = json.load(open(f"{MANIFEST}/program_manifest.json"))["programs"]
cands = json.load(open(f"{MANIFEST}/candidate_manifest.json"))["candidates"]
input_m = json.load(open(f"{MANIFEST}/input_seed_manifest.json"))

# Subset: first 2 programs (gemm + atax), 5 candidates
use_progs = [p for p in prog if p["program_id"] in ("polybench_gemm", "polybench_atax")]
use_cands = [c for c in cands if c["candidate_id"] in ("O0_ref","O1_base","O3_base","Os_base","O3_nounroll")]

def sha(d):
    return hashlib.sha256(d).hexdigest()

# Build references
refs = {}
for p in use_progs:
    pid = p["program_id"]
    src = f"{BASE}/{p['source']}"
    flags = ["-O0", "-DSMALL_DATASET"] + p["polybench_flags"] + ["-I", PB_INC]
    r = subprocess.run(["clang"] + flags + [src, "-lm", "-o", f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
    if r.returncode != 0:
        print(f"REF FAIL {pid}: {r.stderr[:200]}"); refs[pid] = None; continue
    r2 = subprocess.run([f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
    refs[pid] = sha(r2.stderr.encode())
    print(f"Ref {pid}: {refs[pid][:16]}...")

# Execute
records = []
for p in use_progs:
    pid = p["program_id"]
    ref = refs.get(pid)
    if not ref: continue
    src = f"{BASE}/{p['source']}"
    pflags = ["-DSMALL_DATASET"] + p["polybench_flags"] + ["-I", PB_INC]

    for c in use_cands:
        for target, runner in [("x86_64", None), ("aarch64-linux-gnu", ["qemu-aarch64","-L","/usr/aarch64-linux-gnu"]), ("riscv64-linux-gnu", ["qemu-riscv64","-L","/usr/riscv64-linux-gnu"])]:
            bin_path = f"/tmp/{pid}_{c['candidate_id']}_{target}"
            flags = c["clang_flags"] + pflags
            cmd = ["clang"]
            if target != "x86_64":
                cmd += [f"--target={target}", "--gcc-toolchain=/usr"]
            cmd += flags + [src, "-lm", "-o", bin_path]

            print(f"  {pid} {c['candidate_id']} @ {target}...", end=" ", flush=True)
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if r.returncode != 0:
                print(f"COMPILE FAIL ({r.stderr[:60]})")
                records.append({"program_id":pid,"target_triple":target,"candidate_id":c["candidate_id"],"correctness_status":"compile_failed"})
                continue
            print("compiled", end=" ")

            # Execute (1 input)
            try:
                if runner:
                    r2 = subprocess.run(runner + [bin_path], capture_output=True, text=True, timeout=30)
                else:
                    r2 = subprocess.run([bin_path], capture_output=True, text=True, timeout=10)
            except subprocess.TimeoutExpired:
                print("TIMEOUT"); records.append({"program_id":pid,"target_triple":target,"candidate_id":c["candidate_id"],"correctness_status":"run_timeout"})
                continue

            if r2.returncode < 0 or r2.returncode > 127:
                print("CRASHED"); records.append({"program_id":pid,"target_triple":target,"candidate_id":c["candidate_id"],"correctness_status":"crashed"})
                continue

            h = sha(r2.stderr.encode())
            if h == ref:
                print("✓")
                records.append({"program_id":pid,"target_triple":target,"candidate_id":c["candidate_id"],"correctness_status":"accepted","stderr_hash":h})
            else:
                print(f"✗ mismatch ({h[:12]}...)")
                records.append({"program_id":pid,"target_triple":target,"candidate_id":c["candidate_id"],"correctness_status":"incorrect","stderr_hash":h})

# Report
print(f"\n{'='*60}")
print(f"RESULTS: {len(records)} records")
for t in ["x86_64","aarch64-linux-gnu","riscv64-linux-gnu"]:
    s = [r for r in records if r.get("target_triple")==t]
    acc = sum(1 for r in s if r["correctness_status"]=="accepted")
    fail = sum(1 for r in s if r["correctness_status"]!="accepted")
    print(f"  {t}: {len(s)} total, {acc} accepted, {fail} failed")

# Write structured output
run_dir = f"{BASE}/benchmarks/p0/runs/p0_val2"
os.makedirs(run_dir, exist_ok=True)
with open(f"{run_dir}/candidates.jsonl", "w") as f:
    for r in records:
        r["run_id"]="p0_val2"
        r["simulated_or_qemu_only"]=r.get("target_triple","")!="x86_64"
        f.write(json.dumps(r, ensure_ascii=False)+"\n")
with open(f"{run_dir}/summary.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["target","program","candidate","status"])
    for r in records:
        w.writerow([r.get("target_triple",""),r.get("program_id",""),r.get("candidate_id",""),r["correctness_status"]])
print(f"\nWritten to: {run_dir}")
