#!/usr/bin/env python3
import argparse, json, os, platform, random, shutil, statistics, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BUILD = ROOT / "build"
CANDIDATES = {
    "O1": ["-O1"],
    "O2": ["-O2"],
    "O3": ["-O3"],
    "Os": ["-Os"],
    "O3_unroll": ["-O3", "-funroll-loops"],
    "O3_no_vector": ["-O3", "-fno-vectorize", "-fno-slp-vectorize"]
}

def run(cmd, timeout=120):
    return subprocess.run(cmd, text=True, capture_output=True, timeout=timeout, check=True)

def ir_count(path):
    count = 0
    for line in path.read_text(errors="ignore").splitlines():
        s = line.strip()
        if s and not s.startswith((";", "!")) and " = " in s:
            count += 1
        elif s.startswith(("ret ", "br ", "switch ", "store ", "call ")):
            count += 1
    return count

def policy_order(features):
    scores = {k: 0.0 for k in CANDIDATES}
    scores["O3"] += 2.0
    scores["O2"] += 1.0
    scores["Os"] += 2.0 * features.get("code_size_sensitive", 0)
    scores["O3_unroll"] += 1.5 * features.get("vector", 0) - features.get("code_size_sensitive", 0)
    scores["O3_no_vector"] += 1.0 - features.get("vector", 0)
    return sorted(scores, key=scores.get, reverse=True)

def simulate(name, features):
    rng = random.Random(name)
    rows = []
    base = {"O1": (56, 21000, 0.105), "O2": (49, 19500, 0.088), "O3": (48, 20200, 0.081),
            "Os": (51, 18100, 0.096), "O3_unroll": (61, 23000, 0.075), "O3_no_vector": (50, 19800, 0.087)}
    for k in policy_order(features):
        ir, size, runtime = base[k]
        if not features.get("vector", 0) and k == "O3_unroll": runtime *= 1.18
        rows.append({"candidate": k, "flags": CANDIDATES[k], "ir_instructions": ir,
                     "binary_bytes": size, "runtime_seconds": runtime + rng.random() * .002,
                     "simulated": True})
    return rows

def real(platform_name, cfg, repeats, limit):
    clang = shutil.which("clang")
    if not clang:
        raise RuntimeError("clang not found. Install LLVM or run with --simulate.")
    BUILD.mkdir(exist_ok=True)
    rows = []
    target = cfg.get("clang_target")
    prefix = [clang] + (["--target=" + target] if target else [])
    if cfg.get("sysroot"):
        prefix += ["--sysroot=" + cfg["sysroot"]]
    for name in policy_order(cfg["features"])[:limit]:
        flags = CANDIDATES[name]
        ll = BUILD / (name + ".ll")
        exe = BUILD / (name + (".exe" if os.name == "nt" and not target else ""))
        run(prefix + flags + ["-S", "-emit-llvm", str(ROOT / "bench.c"), "-o", str(ll)])
        run(prefix + flags + [str(ROOT / "bench.c"), "-o", str(exe)])
        expected = run((cfg.get("runner") or []) + [str(exe), "1000"]).stdout.strip()
        times = []
        for _ in range(repeats):
            t0 = time.perf_counter()
            got = run((cfg.get("runner") or []) + [str(exe)]).stdout.strip()
            times.append(time.perf_counter() - t0)
            if got == "" or expected == "": raise RuntimeError("empty benchmark output")
        rows.append({"candidate": name, "flags": flags, "ir_instructions": ir_count(ll),
                     "binary_bytes": exe.stat().st_size, "runtime_seconds": statistics.median(times),
                     "simulated": False})
    return rows

def main():
    ap = argparse.ArgumentParser(description="CrossTune-RL minimal IR/backend closed-loop demo")
    ap.add_argument("--platform", default="x86")
    ap.add_argument("--repeats", type=int, default=3)
    ap.add_argument("--candidates", type=int, default=6)
    ap.add_argument("--simulate", action="store_true")
    args = ap.parse_args()
    configs = json.loads((ROOT / "platforms.json").read_text())
    if args.platform not in configs: raise SystemExit("unknown platform: " + args.platform)
    cfg = configs[args.platform]
    rows = simulate(args.platform, cfg["features"]) if args.simulate else real(args.platform, cfg, args.repeats, args.candidates)
    rows.sort(key=lambda x: x["runtime_seconds"])
    result = {"platform": args.platform, "host": platform.platform(), "platform_features": cfg["features"],
              "policy_candidates": policy_order(cfg["features"]), "winner": rows[0]["candidate"], "results": rows}
    BUILD.mkdir(exist_ok=True)
    out = BUILD / "results.json"
    out.write_text(json.dumps(result, indent=2))
    print("platform:", args.platform, "winner:", rows[0]["candidate"])
    print(f"{'candidate':16} {'IR inst':>8} {'bytes':>10} {'seconds':>10}")
    for r in rows: print(f"{r['candidate']:16} {r['ir_instructions']:8} {r['binary_bytes']:10} {r['runtime_seconds']:10.6f}")
    print("results:", out)

if __name__ == "__main__":
    try: main()
    except (subprocess.CalledProcessError, RuntimeError) as e:
        print("ERROR:", e, file=sys.stderr)
        if isinstance(e, subprocess.CalledProcessError): print(e.stderr, file=sys.stderr)
        sys.exit(1)
