#!/usr/bin/env python3
"""MAPO-Pass P0 正式驱动 — 版本 4.0
修复：持久证据存储(D:)、resume 记录不丢失、工件路径完整、per-run 工作目录。"""

import argparse, csv, hashlib, json, os, shutil, subprocess, sys, time, uuid
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent.parent.parent
MANIFEST_DIR = BASE / "benchmarks" / "p0" / "manifest"
RUNS_DIR = BASE / "benchmarks" / "p0" / "runs"
EVI = Path("/mnt/d/p0_evidence")  # 持久证据根 (D: 205G free)
PB_INC = BASE / "benchmarks/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench/utilities"

def sha256(d): return hashlib.sha256(d.encode() if isinstance(d,str) else d).hexdigest()
def fsha(p): return hashlib.sha256(open(p,'rb').read()).hexdigest() if os.path.exists(p) else ""
def lj(p):
    with open(p) as f: return json.load(f)

def hex_decode(text):
    import struct
    vals,i=[],0
    while i<=len(text)-16:
        c=text[i:i+16]
        if all(ord('0')<=ord(ch)<=ord('?') for ch in c):
            try:
                ba=bytearray(8)
                for j in range(8):
                    h=ord(c[j*2])-ord('0'); l=ord(c[j*2+1])-ord('0')
                    if 0<=h<=15 and 0<=l<=15: ba[j]=(h<<4)|l
                    else: i+=1;continue
                vals.append(struct.unpack('<d',bytes(ba))[0]); i+=16;continue
            except: pass
        i+=1
    return vals

class P0Driver:
    def __init__(self, run_id, resume=False, batch="all"):
        self.run_id = run_id
        self.run_dir = RUNS_DIR / run_id
        self.batch = batch
        self.records = []  # 必须在 resume 检查前初始化
        self.resume = resume
        self.resume_keys = set()

        if self.run_dir.exists():
            if resume:
                print(f"[P0] Resuming: {run_id}")
                self._load_existing()
            else:
                print(f"[ERROR] Run exists: {self.run_dir}"); sys.exit(1)
        else:
            self.run_dir.mkdir(parents=True)

        self.programs = lj(MANIFEST_DIR/"program_manifest_v2.json")["programs"]
        cm = lj(MANIFEST_DIR/"candidate_manifest_strict.json")
        self.strict_candidates = cm["strict_pool"]
        self.exploratory_candidates = cm.get("exploratory_pool",[])
        self.config = lj(MANIFEST_DIR/"p0_config.json")
        self.input_m = lj(MANIFEST_DIR/"input_manifest_v2.json")
        self.targets = list(self.config["targets"].keys())

        # Per-run 工作/证据目录
        self.work_dir = EVI / "work" / run_id
        self.art_dir = EVI / "artifacts" / run_id
        self.work_dir.mkdir(parents=True, exist_ok=True)
        self.art_dir.mkdir(parents=True, exist_ok=True)
        self.start_time = datetime.now(timezone.utc)

    def _load_existing(self):
        jl = self.run_dir / "candidates.jsonl"
        if jl.exists():
            with open(jl) as f:
                for line in f:
                    if line.strip():
                        r = json.loads(line)
                        self.records.append(r)
                        k = (r["program_id"],r["candidate_id"],r["target_triple"],r["input_id"])
                        self.resume_keys.add(k)

    # ── O0 参考（每输入独立） ──
    def build_reference(self, prog, target, input_id, input_cfg):
        pid = prog["program_id"]
        ref_bin = self.work_dir / f"ref_{pid}_{target}_{input_id}"
        cmd_str = ""

        if prog["category"] == "tsvc":
            src = BASE/prog["source"]
            other = [BASE/s for s in prog.get("other_sources",[])]
            flags = ["-O0"] + prog.get("tsvc_compile_flags",[])
            cmd = ["clang"] + self.config["targets"][target]["clang_prefix"] + flags + [str(src)] + [str(s) for s in other] + ["-lm","-o",str(ref_bin)]
        else:
            src = BASE/prog["source"]
            inc = BASE/prog["polybench_include"]
            ds = input_cfg.get("flags",["-DSMALL_DATASET"])
            pf = prog["polybench_flags"]
            if prog.get("fm_disabled"):
                pf = pf + (["-ffp-contract=off"] if "-ffp-contract=off" not in pf else [])
                pf = pf + (["-DFMA_DISABLED=1"] if "-DFMA_DISABLED=1" not in pf else [])
            flags = ["-O0"] + ds + pf + ["-I",str(inc)]
            cmd = ["clang"] + self.config["targets"][target]["clang_prefix"] + flags + [str(src),"-lm","-o",str(ref_bin)]
        cmd_str = " ".join(str(c) for c in cmd)

        r = subprocess.run(cmd, capture_output=True, text=True, timeout=self.config["timeouts"]["compile_s"])
        if r.returncode != 0: return None

        runner = self.config["targets"][target]["runner"]
        args_list = input_cfg.get("args",[]) if prog["category"]=="tsvc" else []
        exec_cmd = (runner+[str(ref_bin)]+args_list) if runner else [str(ref_bin)]+args_list
        is_tsvc = prog["category"]=="tsvc" and target!="x86_64"
        to = self.config["timeouts"]["exec_tsvc_qemu_s"] if is_tsvc else \
             self.config["timeouts"]["exec_qemu_s"] if target!="x86_64" else \
             self.config["timeouts"]["exec_native_s"]
        try: r2 = subprocess.run(exec_cmd, capture_output=True, text=True, timeout=to)
        except subprocess.TimeoutExpired: return None

        out_stream = "stdout" if prog["category"]=="tsvc" else "stderr"
        out_bytes = (r2.stdout if out_stream=="stdout" else r2.stderr).encode()

        # 保存参考输出到 Evidence
        ref_dir = self.art_dir / pid / "reference" / target / input_id
        ref_dir.mkdir(parents=True, exist_ok=True)
        (ref_dir / f"{out_stream}.txt").write_bytes(out_bytes)
        if r2.stdout and out_stream!="stdout": (ref_dir/"stdout.txt").write_text(r2.stdout)
        if r2.stderr and out_stream!="stderr": (ref_dir/"stderr.txt").write_text(r2.stderr)

        return {"output":out_bytes, "sha256":sha256(out_bytes), "cmd": cmd_str, "bin_path": str(ref_bin)}

    # ── 编译 ──
    def compile_candidate(self, prog, cand, target, input_id, input_cfg):
        pid,cid = prog["program_id"], cand["candidate_id"]
        bin_path = self.work_dir / f"{pid}_{cid}_{target}_{input_id}"

        if prog["category"] == "tsvc":
            src = BASE/prog["source"]; other = [BASE/s for s in prog.get("other_sources",[])]
            flags = cand["clang_flags"] + prog.get("tsvc_compile_flags",[])
            cmd = ["clang"]+self.config["targets"][target]["clang_prefix"]+flags+[str(src)]+[str(s) for s in other]+["-lm","-o",str(bin_path)]
        else:
            src = BASE/prog["source"]; inc = BASE/prog["polybench_include"]
            ds = input_cfg.get("flags",["-DSMALL_DATASET"])
            pf = prog["polybench_flags"]
            if prog.get("fm_disabled"):
                pf = pf + (["-ffp-contract=off"] if "-ffp-contract=off" not in pf else [])
                pf = pf + (["-DFMA_DISABLED=1"] if "-DFMA_DISABLED=1" not in pf else [])
            flags = cand["clang_flags"] + ds + pf + ["-I",str(inc)]
            cmd = ["clang"]+self.config["targets"][target]["clang_prefix"]+flags+[str(src),"-lm","-o",str(bin_path)]
        cmd_str = " ".join(str(c) for c in cmd)

        # Resume: skip if binary exists AND hash matches AND record exists
        if self.resume and bin_path.exists() and (pid,cid,target,input_id) in self.resume_keys:
            return {"compile_status":"ok","compile_command":cmd_str,"binary_path":str(bin_path),
                    "binary_hash":fsha(bin_path),"skipped":True}

        r = subprocess.run(cmd, capture_output=True, text=True, timeout=self.config["timeouts"]["compile_s"])
        if r.returncode==0:
            return {"compile_status":"ok","compile_rc":0,"compile_command":cmd_str,
                    "binary_path":str(bin_path),"binary_hash":fsha(bin_path),
                    "compile_stderr":r.stderr[:500],"skipped":False}
        else:
            return {"compile_status":"compile_failed","compile_rc":r.returncode,"compile_command":cmd_str,
                    "binary_path":"","binary_hash":"","compile_stderr":r.stderr[:1000],"skipped":False}

    # ── 执行与记录 ──
    def execute_and_record(self, prog, cand, target, input_id, input_cfg, comp, ref):
        pid,cid = prog["program_id"], cand["candidate_id"]
        rec = {"run_id":self.run_id,"program_id":pid,"program_family":prog["family"],
               "input_id":input_id,"input_config":json.dumps(input_cfg,ensure_ascii=False),
               "target_triple":target,"compiler_version":"clang-18.1.3",
               "candidate_id":cid,"pass_sequence":json.dumps(cand["clang_flags"]),
               "compile_command":comp.get("compile_command",""),
               "binary_hash":comp.get("binary_hash",""),
               "exit_code":-1,"timeout_status":False,"output_stream":"",
               "output_hash":"","stdout_path":"","stderr_path":"",
               "ir_features_path":"","assembly_features_path":"",
               "simulated_or_qemu_only":target!="x86_64","diagnostic_elapsed_s":0,
               "timestamp":datetime.now(timezone.utc).isoformat()}

        if comp["compile_status"]!="ok":
            rec["correctness_status"]=comp["compile_status"]
            return rec

        bin_path = comp["binary_path"]
        runner = self.config["targets"][target]["runner"]
        args_list = input_cfg.get("args",[]) if prog["category"]=="tsvc" else []
        exec_cmd = (runner+[str(bin_path)]+args_list) if runner else [str(bin_path)]+args_list
        is_tsvc = prog["category"]=="tsvc" and target!="x86_64"
        to = self.config["timeouts"]["exec_tsvc_qemu_s"] if is_tsvc else \
             self.config["timeouts"]["exec_qemu_s"] if target!="x86_64" else \
             self.config["timeouts"]["exec_native_s"]

        start = time.time()
        try: r = subprocess.run(exec_cmd, capture_output=True, text=True, timeout=to); elapsed=time.time()-start
        except subprocess.TimeoutExpired:
            rec["correctness_status"]="run_timeout"; rec["timeout_status"]=True; rec["diagnostic_elapsed_s"]=to; return rec

        rec["exit_code"]=r.returncode; rec["diagnostic_elapsed_s"]=round(elapsed,2)
        if r.returncode<0 or r.returncode>127:
            rec["correctness_status"]="crashed"; return rec

        out_stream = "stdout" if prog["category"]=="tsvc" else "stderr"
        out_bytes = (r.stdout.encode() if out_stream=="stdout" else r.stderr.encode())
        out_hash = sha256(out_bytes)
        rec["output_stream"]=out_stream; rec["output_hash"]=out_hash

        # 保存 stdout/stderr 到持久证据
        art_slot = self.art_dir / pid / cid / target / input_id
        art_slot.mkdir(parents=True, exist_ok=True)
        (art_slot/f"{out_stream}.txt").write_bytes(out_bytes)
        if r.stdout and out_stream!="stdout": (art_slot/"stdout.txt").write_text(r.stdout)
        if r.stderr and out_stream!="stderr": (art_slot/"stderr.txt").write_text(r.stderr)
        rec["stdout_path"]=str(art_slot/"stdout.txt") if (art_slot/"stdout.txt").exists() else ""
        rec["stderr_path"]=str(art_slot/"stderr.txt") if (art_slot/"stderr.txt").exists() else ""

        # 汇编
        if bin_path and os.path.exists(bin_path):
            asm = art_slot/"program.s"
            try:
                subprocess.run(["llvm-objdump","-d",bin_path],stdout=asm.open('w'),stderr=subprocess.DEVNULL,timeout=30)
                rec["assembly_features_path"]=str(asm) if asm.exists() else ""
            except: pass

        # 验证（TSVC 比校验和忽略时间列，PolyBench 比哈希或容差）
        if ref:
            if prog["category"]=="tsvc":
                # 提取校验和列（columns[2]），忽略时间列
                actual_cs = [l.split()[2] for l in out_bytes.decode(errors='replace').split('\n') if l.strip() and 'Checksum' not in l and 'Loop' not in l and 'Time' not in l and len(l.split())>=3]
                ref_cs = [l.split()[2] for l in ref["output"].decode(errors='replace').split('\n') if l.strip() and 'Checksum' not in l and 'Loop' not in l and 'Time' not in l and len(l.split())>=3]
                rec["correctness_status"]="accepted" if actual_cs==ref_cs else "incorrect"
            elif out_hash==ref["sha256"]:
                rec["correctness_status"]="accepted"
            else:
                try:
                    ad=hex_decode(out_bytes.decode(errors='replace')); rd=hex_decode(ref["output"].decode(errors='replace'))
                    if len(ad)==len(rd) and len(ad)>0 and max(abs(a-r) for a,r in zip(ad,rd))<1e-5:
                        rec["correctness_status"]="accepted"
                    else: rec["correctness_status"]="incorrect"
                except: rec["correctness_status"]="incorrect"
        else: rec["correctness_status"]="incorrect"
        return rec

    # ── 运行 ──
    def run(self):
        print(f"[P0] v4 driver | run_id={self.run_id} batch={self.batch}")
        progs = [p for p in self.programs if p["category"]=="tsvc"] if self.batch=="tsvc" else \
                [p for p in self.programs if p["category"]!="tsvc"] if self.batch=="polybench" else self.programs
        candidates = self.strict_candidates
        if self.batch=="exploratory": candidates = self.exploratory_candidates
        print(f"Programs: {[p['program_id'] for p in progs]}; Candidates: {len(candidates)}; Work: {self.work_dir}")

        refs = {}; comps = {}; new_records = []

        # Phase 1: Per-input O0 references (parallel, limited workers for TSVC QEMU)
        from concurrent.futures import ThreadPoolExecutor, as_completed
        ref_tasks=[]
        n_workers = 3 if self.batch=="tsvc" else 6
        for prog in progs:
            for target in self.targets:
                for inp in self._get_inputs(prog):
                    iid=inp["input_id"]; k=(prog["program_id"],target,iid)
                    if self.resume and k in [(r["program_id"],r["target_triple"],r["input_id"]) for r in self.records]: continue
                    ref_tasks.append((prog,target,iid,inp))
        with ThreadPoolExecutor(max_workers=n_workers) as pool:
            fut={pool.submit(self.build_reference, *t): t for t in ref_tasks}
            for f in as_completed(fut):
                t=fut[f]; k=(t[0]["program_id"],t[1],t[2])
                try:
                    ref=f.result()
                    if ref: refs[k]=ref; print(f"  Ref {k[0]} @ {t[1]} [{t[2]}] OK ({ref['sha256'][:16]}...)")
                    else: print(f"  Ref {k[0]} @ {t[1]} [{t[2]}] FAILED")
                except Exception as e: print(f"  Ref {k[0]} @ {t[1]} [{t[2]}] ERROR: {e}")

        # Phase 2: Compile
        for prog in progs:
            pid=prog["program_id"]
            for cand in candidates:
                cid=cand["candidate_id"]
                for target in self.targets:
                    for inp in self._get_inputs(prog):
                        iid=inp["input_id"]; k=(pid,cid,target,iid)
                        if self.resume and k in self.resume_keys:
                            print(f"  {pid} {cid} @ {target} [{iid}]: SKIP (resumed)"); continue
                        comp = self.compile_candidate(prog,cand,target,iid,inp)
                        comps[k]=comp
                        s="OK" if comp["compile_status"]=="ok" else "FAIL"; print(f"  {pid} {cid} @ {target} [{iid}]: {s}")

        # Phase 3: Execute & verify (parallel targets with ThreadPoolExecutor)
        from concurrent.futures import ThreadPoolExecutor, as_completed
        exec_tasks = []
        for prog in progs:
            pid=prog["program_id"]
            for cand in candidates:
                cid=cand["candidate_id"]
                for target in self.targets:
                    for inp in self._get_inputs(prog):
                        iid=inp["input_id"]; k=(pid,cid,target,iid)
                        if self.resume and k in self.resume_keys: continue
                        comp = comps.get(k,{})
                        ref = refs.get((pid,target,iid))
                        # Use partial to capture args for thread pool
                        exec_tasks.append((prog,cand,target,iid,inp,comp,ref))

        # 3-4 parallel workers (QEMU targets are bottleneck)
        n_exec = 3 if self.batch=="tsvc" else 6
        with ThreadPoolExecutor(max_workers=n_exec) as pool:
            fut = {pool.submit(self.execute_and_record, *t): t for t in exec_tasks}
            for f in as_completed(fut):
                t=fut[f]
                try:
                    rec=f.result()
                    new_records.append(rec)
                    sym={"accepted":"✓","incorrect":"✗","run_timeout":"⏱","compile_failed":"!"}.get(rec["correctness_status"],"?")
                    print(f"  {t[0]['program_id']} {t[2]} @ {t[3]} [{t[4]}] {sym} {rec['correctness_status']}")
                    if rec.get("diagnostic_elapsed_s",0)>10:
                        print(f"    ({rec['diagnostic_elapsed_s']:.1f}s)")
                except Exception as e:
                    print(f"  {t[0]['program_id']} {t[2]} @ {t[3]} FAIL: {e}")

        self.records.extend(new_records)
        self._write_outputs(len(new_records))

    def _get_inputs(self, prog):
        if prog["category"]=="tsvc":
            c = self.input_m["tsvc_configs"].get(prog["program_id"],{})
            return c.get("boundary",[])+c.get("fixed_seed",[])
        return [{"input_id":k,**v} for k,v in prog.get("input_overrides",{}).items()]

    def _write_outputs(self,new_count):
        env={}
        for k,sc in [("clang","clang --version 2>&1|head -3"),("opt","opt --version 2>&1|head -1"),
                     ("qemu_aarch64","qemu-aarch64 --version 2>&1|head -1"),("qemu_riscv64","qemu-riscv64 --version 2>&1|head -1"),
                     ("python","python3 --version 2>&1|head -1")]:
            try: r=subprocess.run(sc,shell=True,capture_output=True,text=True,timeout=10); env[k]=r.stdout.strip()
            except: pass
        try:
            r=subprocess.run("git log --oneline -1",shell=True,capture_output=True,text=True,timeout=10,cwd=BASE); env["git"]=r.stdout.strip()
            r2=subprocess.run("git -C benchmarks/sources/llvm-test-suite log --oneline -1",shell=True,capture_output=True,text=True,timeout=10,cwd=BASE); env["llvm_test_suite"]=r2.stdout.strip()
        except: pass
        mh={}
        for mf in ["program_manifest_v2.json","candidate_manifest_strict.json","input_manifest_v2.json","p0_config.json"]:
            p=MANIFEST_DIR/mf
            if p.exists(): mh[mf]=fsha(p)

        manifest = {"run_id":self.run_id,"created":self.start_time.isoformat(),"completed":datetime.now(timezone.utc).isoformat(),
                    "driver_version":"4.0","resumed":self.resume,"manifest_hashes":mh,"environment":env,
                    "targets":self.targets,"record_count":len(self.records),"new_records_this_run":new_count,
                    "evidence_root":str(EVI)}
        with open(self.run_dir/"manifest.json","w") as f: json.dump(manifest,f,indent=2,ensure_ascii=False)

        with open(self.run_dir/"candidates.jsonl","w") as f:
            for rec in self.records: f.write(json.dumps(rec,ensure_ascii=False,default=str)+"\n")

        with open(self.run_dir/"summary.csv","w",newline="") as f:
            w=csv.writer(f); w.writerow(["target","program","candidate","total","accepted","incorrect","timeout","compile_failed","crashed"])
            for t in self.targets:
                for p in set(r["program_id"] for r in self.records):
                    for c in set(r["candidate_id"] for r in self.records):
                        s=[r for r in self.records if r["target_triple"]==t and r["program_id"]==p and r["candidate_id"]==c]
                        if not s: continue
                        acc=sum(1 for r in s if r["correctness_status"]=="accepted")
                        inc=sum(1 for r in s if r["correctness_status"]=="incorrect")
                        tim=sum(1 for r in s if r["correctness_status"]=="run_timeout")
                        cf=sum(1 for r in s if r["correctness_status"]=="compile_failed")
                        cr=sum(1 for r in s if r["correctness_status"]=="crashed")
                        w.writerow([t,p,c,len(s),acc,inc,tim,cf,cr])
            # 覆盖统计（仅 PolyBench 或已执行的）
            with open(self.run_dir/"coverage.csv","w",newline="") as f:
                w=csv.writer(f); w.writerow(["program","candidate","target","inputs","expected","attempted","accepted","compile_failed","timeout","crashed","incorrect","remaining","notes"])
                for p in self.programs:
                    pid=p["program_id"]; inputs=self._get_inputs(p); inp_count=len(inputs)
                    for c in self.strict_candidates:
                        for t in self.targets:
                            s=[r for r in self.records if r["target_triple"]==t and r["program_id"]==pid and r["candidate_id"]==c["candidate_id"]]
                            expected=inp_count; attempted=len(s); remaining=expected-attempted if attempted<expected else 0
                            acc=sum(1 for r in s if r["correctness_status"]=="accepted")
                            cf=sum(1 for r in s if r["correctness_status"]=="compile_failed")
                            tim=sum(1 for r in s if r["correctness_status"]=="run_timeout")
                            cr=sum(1 for r in s if r["correctness_status"]=="crashed")
                            inc=sum(1 for r in s if r["correctness_status"]=="incorrect")
                            note="not_run" if attempted==0 else (f"partial_{attempted}_of_{expected}" if remaining>0 else "")
                            w.writerow([pid,c["candidate_id"],t,inp_count,expected,attempted,acc,cf,tim,cr,inc,remaining,note])

        # 证据目录大小
        art_size = sum(f.stat().st_size for f in self.art_dir.rglob('*') if f.is_file()) if self.art_dir.exists() else 0
        print(f"\n{'='*60}")
        print(f"RESULTS: {len(self.records)} total (+{new_count} this run)")
        for t in self.targets:
            s=[r for r in self.records if r["target_triple"]==t]
            print(f"  {t}: {len(s)} rec, {sum(1 for r in s if r['correctness_status']=='accepted')} accepted")
        print(f"Run: {self.run_dir}")
        print(f"Evidence: {EVI}/artifacts/{self.run_id} ({art_size//1024}KB)")

def main():
    parser = argparse.ArgumentParser(description="MAPO-Pass P0 Driver v4")
    parser.add_argument("--run-id", default=f"p0-{datetime.now().strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:6]}")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--batch", choices=["all","polybench","tsvc","exploratory"], default="all")
    args = parser.parse_args()
    d = P0Driver(args.run_id, resume=args.resume, batch=args.batch)
    d.run()

if __name__=="__main__": main()
