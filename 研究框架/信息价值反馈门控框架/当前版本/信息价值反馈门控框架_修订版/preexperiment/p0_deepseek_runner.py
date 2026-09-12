#!/usr/bin/env python3
"""DeepSeek V4 Pro paired-feedback P0 experiment."""
import argparse, csv, hashlib, json, os, random, re, shutil, sys, time
import urllib.error, urllib.request
from datetime import datetime, timezone
from pathlib import Path
import p0_runner as mech

MODEL="deepseek-v4-pro"; BASE_URL="https://api.deepseek.com"
CONDITIONS=("N0","N1","MatchedPlacebo","RealFeedback")
TEMPERATURE=0.2; TOP_P=0.95; MAX_TOKENS=1024; EPSILON=0.01
SYSTEM_PROMPT="""You are a source-level C compiler optimization assistant. Return exactly one JSON object and no Markdown. Preserve exact C11 unsigned semantics for every input, including n=0. Do not change the function signature, read out of bounds, add undefined behavior, or call new helpers. Optimize the function body for fewer Clang LLVM IR instructions. The JSON object must contain candidate_body, action_type, target, and rationale, all strings. candidate_body must contain only statements inside the function braces."""
SCHEMA={"type":"object","required":["candidate_body","action_type","target","rationale"],"additionalProperties":False,"properties":{k:{"type":"string"} for k in ("candidate_body","action_type","target","rationale")}}

def now(): return datetime.now(timezone.utc).isoformat()
def h(text): return hashlib.sha256(text.encode("utf-8")).hexdigest()
def canonical(value): return json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(",",":"))

def extract_function_ir(text,name="candidate"):
    marker="@{}(".format(name); lines=text.splitlines(); start=None
    for i,line in enumerate(lines):
        if line.lstrip().startswith("define ") and marker in line: start=i; break
    if start is None: return ""
    selected=[]
    for line in lines[start:]:
        selected.append(line)
        if line.strip()=="}": break
    return "\n".join(selected)

def ir_count(path):
    if not path.exists(): return None
    body=extract_function_ir(path.read_text(encoding="utf-8"))
    return mech.count_ir_instructions(body) if body else None

def parse_output(content):
    text=(content or "").strip()
    if text.startswith("```"):
        text=re.sub(r"^```(?:json)?\s*","",text); text=re.sub(r"\s*```$","",text)
    value=json.loads(text)
    required=set(SCHEMA["required"])
    if not isinstance(value,dict) or set(value)!=required: raise ValueError("schema mismatch")
    if not all(isinstance(value[k],str) for k in required): raise ValueError("fields must be strings")
    body=value["candidate_body"].strip()
    if not body or "```" in body or re.search(r"\buint64_t\s+candidate\s*\(",body):
        raise ValueError("candidate_body must be body statements only")
    value["candidate_body"]=body; return value

def feedback(condition,state,task_id):
    if condition=="RealFeedback":
        if state==0: return "LLVM IR inspection for {} found a conditional whose true and false successors perform the same unsigned accumulator update. The branch adds instructions but does not change the result.".format(task_id)
        return "LLVM IR inspection for {} found an addition of the unsigned identity value zero after each accumulator update. It adds instructions but does not change the result.".format(task_id)
    if condition=="MatchedPlacebo":
        if state==0: return "LLVM IR inspection for unrelated_buffer_task found three pointer alias checks guarding a vectorized store. The checks add instructions and depend on relationships between separate output buffers."
        return "LLVM IR inspection for unrelated_switch_task found a signed range check before an indirect switch dispatch. The check adds instructions and depends on negative selector values."
    return "No new compiler feedback is available for this condition."

def prompt_for(task,task_index,state,condition):
    task_id,family,init,update=task; body=mech.baseline_body(state,init,update)
    block=20260720+task_index*2+state+(1000 if condition=="N1" else 0)
    function="static uint64_t candidate(const uint32_t *a, size_t n) {\n    "+body+"\n}"
    return """Experiment condition: {c}
Task: {t}
Program family: {f}
State: S{s}
Paired sampling block: {b}
Objective: reduce candidate instructions under clang -std=c11 -O0 -S -emit-llvm.
Correctness is checked by fixed tests, randomized differential tests, ASan and UBSan.
Compiler feedback:
{fb}
Function to optimize:
{fn}
Return the required JSON object.""".format(c=condition,t=task_id,f=family,s=state+1,b=block,fb=feedback(condition,state,task_id),fn=function)

class Client:
    def __init__(self,key): self.key=key
    def generate(self,prompt,retries=3):
        payload={"model":MODEL,"messages":[{"role":"system","content":SYSTEM_PROMPT},{"role":"user","content":prompt}],"temperature":TEMPERATURE,"top_p":TOP_P,"max_tokens":MAX_TOKENS,"response_format":{"type":"json_object"}}
        data=json.dumps(payload,ensure_ascii=False).encode("utf-8"); error=None
        for attempt in range(1,retries+1):
            req=urllib.request.Request(BASE_URL+"/chat/completions",data=data,method="POST",headers={"Authorization":"Bearer "+self.key,"Content-Type":"application/json"}); start=time.time()
            try:
                with urllib.request.urlopen(req,timeout=180) as response: raw=response.read().decode("utf-8")
                return json.loads(raw),round(time.time()-start,6),attempt
            except urllib.error.HTTPError as exc:
                error="HTTP {}: {}".format(exc.code,exc.read().decode("utf-8",errors="replace")[-1000:])
                if exc.code not in (408,429,500,502,503,504): break
            except Exception as exc: error="{}: {}".format(type(exc).__name__,exc)
            if attempt<retries: time.sleep(2**(attempt-1))
        raise RuntimeError(error or "request failed")

def compile_measure(clang,body,reference,slot,baseline=None):
    slot.mkdir(parents=True,exist_ok=True); source=mech.make_source(body,reference); src=slot/"candidate.c"; src.write_text(source,encoding="utf-8")
    valid=mech.compile_and_validate(clang,src,slot,None); count=ir_count(slot/"candidate.ll")
    gain=(baseline-count)/float(baseline) if baseline and count is not None else None
    utility=gain if valid.get("correctness") and gain is not None and gain>=EPSILON else 0.0
    return valid,count,gain,utility

def compact(valid):
    names=("compile","fixed_test","random_test","sanitizer_compile","sanitizer_test","ir_compile")
    return {n:mech.compact_tool_result(valid.get(n)) for n in names}

def run_state(client,clang,run_dir,task_index,task,state):
    task_id,family,init,update=task; state_id="S{}".format(state+1); root=run_dir/"artifacts"/task_id/state_id
    reference=mech.optimized_body(init,update); baseline_body=mech.baseline_body(state,init,update)
    baseline_valid,baseline_ir,_,_=compile_measure(clang,baseline_body,reference,root/"state_baseline")
    if not baseline_valid.get("correctness") or not baseline_ir: raise RuntimeError("bad baseline {}/{}".format(task_id,state_id))
    records=[]
    for condition in CONDITIONS:
        slot=root/condition; slot.mkdir(parents=True,exist_ok=True); prompt=prompt_for(task,task_index,state,condition)
        (slot/"prompt.txt").write_text(SYSTEM_PROMPT+"\n\n"+prompt,encoding="utf-8")
        response=None; output=None; error=None; elapsed=0; attempts=0; valid=None; count=None; gain=None; utility=0.0
        try:
            response,elapsed,attempts=client.generate(prompt); (slot/"api_response.json").write_text(json.dumps(response,ensure_ascii=False,indent=2),encoding="utf-8")
            output=parse_output(response["choices"][0]["message"].get("content","")); valid,count,gain,utility=compile_measure(clang,output["candidate_body"],reference,slot,baseline_ir)
        except Exception as exc: error="{}: {}".format(type(exc).__name__,exc)
        usage=response.get("usage",{}) if response else {}; message=response["choices"][0]["message"] if response else {}
        rec={"run_id":run_dir.name,"timestamp":now(),"task_id":task_id,"program_family":family,"state_id":state_id,"condition":condition,"paired_seed_block":20260720+task_index*2+state+(1000 if condition=="N1" else 0),"model":MODEL,"generator_mode":"deepseek_api","system_prompt_sha256":h(SYSTEM_PROMPT),"user_prompt_sha256":h(prompt),"schema_sha256":h(canonical(SCHEMA)),"feedback_sha256":h(feedback(condition,state,task_id)),"api_attempts":attempts,"api_elapsed_s":elapsed,"api_error":error,"finish_reason":response["choices"][0].get("finish_reason") if response else None,"reasoning_chars":len(message.get("reasoning_content") or ""),"usage":usage,"output":output,"baseline_ir_instructions":baseline_ir,"candidate_ir_instructions":count,"raw_static_gain":round(gain,8) if gain is not None else None,"correctness":bool(valid and valid.get("correctness")),"status":valid.get("status") if valid else "generation_failed","utility":round(utility,8),"tools":compact(valid) if valid else {}}
        records.append(rec); print("{}/{}/{}: {}, ir={}, utility={:.4f}".format(task_id,state_id,condition,rec["status"],count,utility),flush=True)
    n0=next(r for r in records if r["condition"]=="N0")
    for rec in records: rec["delta_utility"]=round(rec["utility"]-n0["utility"],8); rec["beneficial_change"]=rec["delta_utility"]>0
    return records

def bootstrap(values,draws=5000):
    if not values:return 0.0,0.0
    rng=random.Random(20260720); n=len(values); samples=sorted(sum(values[rng.randrange(n)] for _ in range(n))/n for _ in range(draws))
    return samples[int(.025*(draws-1))],samples[int(.975*(draws-1))]

def write_results(run_dir,records,compiler,kind):
    with (run_dir/"records.jsonl").open("w",encoding="utf-8") as fh:
        for r in records: fh.write(json.dumps(r,ensure_ascii=False,sort_keys=True)+"\n")
    rows=[]
    for condition in CONDITIONS:
        subset=[r for r in records if r["condition"]==condition]; deltas=[r["delta_utility"] for r in subset]; low,high=bootstrap(deltas)
        rows.append({"condition":condition,"states":len(subset),"generated":sum(r["output"] is not None for r in subset),"accepted":sum(r["correctness"] for r in subset),"beneficial_change_rate":sum(r["beneficial_change"] for r in subset)/len(subset),"mean_utility":sum(r["utility"] for r in subset)/len(subset),"mean_delta_utility":sum(deltas)/len(deltas),"ci95_low":low,"ci95_high":high,"prompt_tokens":sum(r["usage"].get("prompt_tokens",0) for r in subset),"completion_tokens":sum(r["usage"].get("completion_tokens",0) for r in subset),"api_wall_s":sum(r["api_elapsed_s"] for r in subset)})
    with (run_dir/"summary.csv").open("w",newline="",encoding="utf-8-sig") as fh: w=csv.DictWriter(fh,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    by={r["condition"]:r for r in rows}; real=by["RealFeedback"]; families=sorted(set(r["program_family"] for r in records if r["condition"]=="RealFeedback" and r["beneficial_change"]))
    signal=kind=="formal" and real["mean_delta_utility"]>max(by["N1"]["mean_delta_utility"],by["MatchedPlacebo"]["mean_delta_utility"]) and real["mean_delta_utility"]>0 and len(families)>=2 and real["accepted"]>0
    manifest={"run_id":run_dir.name,"created_at":now(),"run_kind":kind,"research_evidence":kind=="formal","model":MODEL,"base_url":BASE_URL,"temperature":TEMPERATURE,"top_p":TOP_P,"max_tokens":MAX_TOKENS,"system_prompt_sha256":h(SYSTEM_PROMPT),"schema_sha256":h(canonical(SCHEMA)),"compiler_version":compiler,"python_version":sys.version,"states":len(records)//4,"condition_runs":len(records),"positive_real_feedback_families":families,"pre_registered_continue_signal":signal,"limitations":["Sampling blocks are pairing identifiers, not guaranteed deterministic API seeds.","P0 uses target-function LLVM IR count at -O0.","Only IR feedback is tested in P0."]}
    (run_dir/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
    report="# DeepSeek V4 Pro P0 结果\n\n- 状态/条件运行：{}/{}\n- RealFeedback 平均 DeltaUtility：{:.6f}，95% CI [{:.6f}, {:.6f}]\n- N1：{:.6f}\n- MatchedPlacebo：{:.6f}\n- 正向程序族：{}\n- 判断：**{}**\n".format(len(records)//4,len(records),real["mean_delta_utility"],real["ci95_low"],real["ci95_high"],by["N1"]["mean_delta_utility"],by["MatchedPlacebo"]["mean_delta_utility"],", ".join(families) or "无","进入 P1" if signal else "不进入 P1 / 需复核")
    (run_dir/"结论.md").write_text(report,encoding="utf-8")

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--run-id",default="p0-deepseek-"+datetime.now().strftime("%Y%m%dT%H%M%SZ")); ap.add_argument("--results-dir",required=True); ap.add_argument("--limit-states",type=int,default=20); ap.add_argument("--run-kind",choices=("preflight","formal"),default="formal"); ap.add_argument("--clang",default="clang"); args=ap.parse_args()
    key=os.environ.get("DEEPSEEK_API_KEY"); clang=shutil.which(args.clang)
    if not key or not clang: print("DEEPSEEK_API_KEY or clang missing",file=sys.stderr); return 2
    run_dir=Path(args.results_dir)/args.run_id
    if run_dir.exists(): print("run directory exists",file=sys.stderr); return 2
    run_dir.mkdir(parents=True); compiler=mech.run_command([clang,"--version"])["stdout"].strip(); client=Client(key)
    states=[(i,t,s) for i,t in enumerate(mech.TASKS) for s in range(2)][:args.limit_states]; records=[]
    for number,(i,task,state) in enumerate(states,1):
        print("STATE {}/{}: {}/S{}".format(number,len(states),task[0],state+1),flush=True); records.extend(run_state(client,clang,run_dir,i,task,state))
        with (run_dir/"records.partial.jsonl").open("w",encoding="utf-8") as fh:
            for r in records: fh.write(json.dumps(r,ensure_ascii=False,sort_keys=True)+"\n")
    write_results(run_dir,records,compiler,args.run_kind); (Path(args.results_dir)/"latest_deepseek.txt").write_text(args.run_id+"\n",encoding="utf-8"); print("RESULTS={}".format(run_dir)); return 0
if __name__=="__main__": sys.exit(main())

