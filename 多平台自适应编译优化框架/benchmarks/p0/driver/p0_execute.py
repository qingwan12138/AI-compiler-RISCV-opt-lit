#!/usr/bin/env python3
"""
P0 Step D/E: Execute compiled candidates and generate structured records.
Uses existing compiled binaries from work/ directory.
"""
import csv, hashlib, json, os, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent.parent.parent
WORK = BASE / "benchmarks" / "p0" / "work"
RUNS = BASE / "benchmarks" / "p0" / "runs"
PB_INC = BASE / "benchmarks/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench/utilities"
TSVC = BASE / "benchmarks/sources/llvm-test-suite/MultiSource/Benchmarks/TSVC"
MANIFEST = BASE / "benchmarks" / "p0" / "manifest"

RUN_ID = "p0_run_001"

TARGETS = {
    "x86_64": {"runner": None},
    "aarch64-linux-gnu": {"runner": ["qemu-aarch64", "-L", "/usr/aarch64-linux-gnu"]},
    "riscv64-linux-gnu": {"runner": ["qemu-riscv64", "-L", "/usr/riscv64-linux-gnu"]},
}

def load_json(path):
    with open(path) as f:
        return json.load(f)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

# ─── Build references ───────────────────────────────────────────────────
def build_references(programs):
    refs = {}
    for prog in programs:
        pid = prog["program_id"]
        print(f"Ref {pid}...", end=" ", flush=True)
        src = BASE / prog["source"]
        if prog["family"] == "tsvc":
            other = [BASE / s for s in prog.get("other_sources", [])]
            cmd = ["clang", "-O0", "-DUSE_CLOCK", str(src)] + [str(s) for s in other] + ["-lm", "-o", f"/tmp/ref_{pid}"]
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if r.returncode != 0:
                print(f"BUILD FAIL: {r.stderr[:200]}")
                refs[pid] = None; continue
            r2 = subprocess.run([f"/tmp/ref_{pid}", "2325", "14"], capture_output=True, text=True, timeout=30)
            out = r2.stdout.encode()
        else:
            flags = ["-O0", "-DSMALL_DATASET"] + prog["polybench_flags"] + ["-I", str(PB_INC)]
            r = subprocess.run(["clang"] + flags + [str(src), "-lm", "-o", f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
            if r.returncode != 0:
                print(f"BUILD FAIL: {r.stderr[:200]}")
                refs[pid] = None; continue
            r2 = subprocess.run([f"/tmp/ref_{pid}"], capture_output=True, text=True, timeout=30)
            out = r2.stderr.encode()
        refs[pid] = {"sha256": sha256(out), "output": out}
        print(f"OK ({refs[pid]['sha256'][:12]}...)")
    return refs

# ─── Execute and verify ─────────────────────────────────────────────────
def run_program(bin_path, target, args=None):
    target_cfg = TARGETS[target]
    if target_cfg["runner"] is None:
        cmd = [str(bin_path)]
    else:
        cmd = target_cfg["runner"] + [str(bin_path)]
    if args:
        cmd.extend(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        return {"rc": r.returncode, "stdout": r.stdout, "stderr": r.stderr, "ok": True}
    except subprocess.TimeoutExpired:
        return {"rc": -1, "stdout": "", "stderr": "", "ok": False, "timeout": True}
    except Exception as e:
        return {"rc": -2, "stdout": "", "stderr": str(e), "ok": False, "crashed": True}

def verify_polybench(stderr, ref):
    actual = stderr.encode()
    actual_hash = sha256(actual)
    return actual_hash == ref["sha256"], actual_hash

def verify_tsvc(stdout, ref):
    actual = stdout.encode()
    actual_hash = sha256(actual)
    return actual_hash == ref["sha256"], actual_hash

# ─── Main ───────────────────────────────────────────────────────────────
def main():
    programs = load_json(MANIFEST / "program_manifest.json")["programs"]
    candidates = load_json(MANIFEST / "candidate_manifest.json")["candidates"]
    input_manifest = load_json(MANIFEST / "input_seed_manifest.json")

    run_dir = RUNS / RUN_ID
    artifacts_dir = run_dir / "artifacts"
    run_dir.mkdir(parents=True, exist_ok=True)
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    # Build references
    print("=== Building references ===")
    refs = build_references(programs)

    # Prepare input configs
    poly_inputs = [{"input_id": f"r{i:02d}", "args": []} for i in range(1, 6)]  # 5 boundary runs

    # Execute and record
    print("\n=== Executing and verifying ===")
    records = []

    for prog in programs:
        pid = prog["program_id"]
        ref = refs.get(pid)
        if ref is None:
            print(f"Skipping {pid}: no reference")
            continue

        for cand in candidates:
            cid = cand["candidate_id"]
            for target in ["x86_64", "aarch64-linux-gnu", "riscv64-linux-gnu"]:
                bin_path = WORK / f"{pid}_{cid}_{target}"
                if not bin_path.exists():
                    print(f"  {pid} {cid} @ {target}: NO BINARY")
                    records.append({
                        "run_id": RUN_ID, "program_id": pid, "input_id": "ALL",
                        "target_triple": target, "candidate_id": cid,
                        "correctness_status": "compile_failed",
                        "simulated_or_qemu_only": target != "x86_64",
                    })
                    continue

                if prog["family"] == "tsvc":
                    inputs = [{"input_id": "default", "args": ["2325", "14"]}]
                else:
                    inputs = poly_inputs

                for inp in inputs:
                    print(f"  {pid} {cid} @ {target} [{inp['input_id']}]...", end=" ", flush=True)
                    res = run_program(bin_path, target, inp.get("args"))
                    sim = target != "x86_64"

                    if not res.get("ok"):
                        status = "run_timeout" if res.get("timeout") else "crashed"
                        print(f"{status.upper()}")
                    else:
                        if prog["family"] == "tsvc":
                            match, out_hash = verify_tsvc(res["stdout"], ref)
                        else:
                            match, out_hash = verify_polybench(res["stderr"], ref)
                        status = "accepted" if match else "incorrect"
                        print("OK" if match else "MISMATCH")

                    records.append({
                        "run_id": RUN_ID,
                        "program_id": pid,
                        "program_family": prog["family"],
                        "input_id": inp["input_id"],
                        "target_triple": target,
                        "compiler_version": "clang-18.1.3",
                        "candidate_id": cid,
                        "pass_sequence": json.dumps(cand["pass_sequence"]),
                        "compile_command": "",
                        "binary_hash": sha256(open(bin_path, "rb").read()) if bin_path.exists() else "",
                        "correctness_status": status,
                        "timeout_status": res.get("timeout", False),
                        "stdout_hash": sha256(res.get("stdout", "").encode()) if res.get("ok") else "",
                        "stderr_path": "",
                        "ir_features_path": "",
                        "assembly_features_path": "",
                        "simulated_or_qemu_only": sim,
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                    })

    # Write outputs
    print("\n=== Writing outputs ===")
    jsonl_path = run_dir / "candidates.jsonl"
    with open(jsonl_path, "w") as f:
        for rec in records:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print(f"candidates.jsonl: {len(records)} records")

    # Summary
    csv_path = run_dir / "summary.csv"
    with open(csv_path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["target", "program", "candidate", "total", "accepted", "incorrect", "timeout", "failed"])
        for t in ["x86_64", "aarch64-linux-gnu", "riscv64-linux-gnu"]:
            for p in programs:
                pid = p["program_id"]
                for c in candidates:
                    cid = c["candidate_id"]
                    subset = [r for r in records if r["target_triple"] == t and r["program_id"] == pid and r["candidate_id"] == cid]
                    if not subset: continue
                    acc = sum(1 for r in subset if r["correctness_status"] == "accepted")
                    inc = sum(1 for r in subset if r["correctness_status"] == "incorrect")
                    tim = sum(1 for r in subset if r.get("timeout_status"))
                    fail = sum(1 for r in subset if "fail" in r["correctness_status"])
                    w.writerow([t, pid, cid, len(subset), acc, inc, tim, fail])
    print(f"summary.csv written")

    # manifest.json
    manifest = {
        "run_id": RUN_ID, "created": datetime.now(timezone.utc).isoformat(),
        "programs": [p["program_id"] for p in programs],
        "candidates": [c["candidate_id"] for c in candidates],
        "targets": list(TARGETS.keys()),
        "record_count": len(records),
    }
    with open(run_dir / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    with open(run_dir / "run_id.txt", "w") as f:
        f.write(f"{RUN_ID}\n")

    # Print final summary
    print("\n=== Summary ===")
    for t in ["x86_64", "aarch64-linux-gnu", "riscv64-linux-gnu"]:
        t_records = [r for r in records if r["target_triple"] == t]
        acc = sum(1 for r in t_records if r["correctness_status"] == "accepted")
        inc = sum(1 for r in t_records if r["correctness_status"] == "incorrect")
        fail = sum(1 for r in t_records if r["correctness_status"] != "accepted" and r["correctness_status"] != "incorrect")
        print(f"  {t}: {len(t_records)} records, {acc} accepted, {inc} incorrect, {fail} other")

    print(f"\nComplete! Run: {run_dir}")

if __name__ == "__main__":
    main()
