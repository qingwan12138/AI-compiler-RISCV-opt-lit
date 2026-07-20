#!/usr/bin/env python3
"""Pre-registered hard-state P0 with real Compile/Test/Remark/IR feedback."""
import argparse, csv, json, os, shutil, sys
from datetime import datetime
from pathlib import Path
import p0_runner as mech
import p0_deepseek_runner as core

core.MAX_TOKENS=2048
core.SYSTEM_PROMPT=("You are a source-level C compiler repair and optimization assistant. Return exactly one JSON object and no Markdown. Preserve the intended C11 unsigned semantics for every input, including n=0. Do not change the function signature, read out of bounds, add undefined behavior, or call new helpers. First repair the current state when necessary, then reduce target-function Clang LLVM IR instructions. Compiler feedback may be irrelevant; verify applicability before using it. The JSON object must contain candidate_body, action_type, target, and rationale, all strings. candidate_body must contain only statements inside the function braces.")
TYPES=("Compile","Test","Remark","IR")

def mutate_compile(body,mode):
    changes=(lambda x:x.replace("a[i]","a[missing_index]",1),lambda x:x.replace("uint32_t v","uint33_t v",1),lambda x:x.replace("return r;","return missing_result;",1),lambda x:x.replace("size_t i","index_type i",1),lambda x:x.replace("< n","< missing_n",1))
    return changes[mode%5](body)

def mutate_test(body,mode):
    if mode%5==0:return body.replace("return r;","if (n == 5) r += 1u;\n    return r;",1)
    if mode%5==1:return body.replace("return r;","return r + 1u;",1)
    if mode%5==2:return body.replace("size_t i = 0","size_t i = 1",1)
    if mode%5==3:return body.replace("i < n","i + 1 < n",1)
    return body.replace("return r;","if (n == 7) r ^= 1u;\n    return r;",1)

def build_states():
    states=[]
    for task_index,task in enumerate(mech.TASKS):
        task_id,family,init,update=task
        for local in range(2):
            index=task_index*2+local; kind=TYPES[index%4]
            reference=mech.optimized_body(init,update)
            canonical=mech.baseline_body(1,init,update)
            if kind=="Compile": current=mutate_compile(canonical,task_index)
            elif kind=="Test": current=mutate_test(canonical,task_index)
            elif kind=="Remark": current=mech.baseline_body(0 if task_index%2==0 else 1,init,update); canonical=current
            else: current=mech.baseline_body(1 if task_index%2==0 else 0,init,update); canonical=current
            states.append({"index":index,"task_index":task_index,"task":task,"task_id":task_id,"family":family,"state_id":"H{:02d}".format(index+1),"feedback_type":kind,"current":current,"canonical":canonical,"reference":reference})
    return states

def collect_feedback(clang,state,evidence):
    evidence.mkdir(parents=True,exist_ok=True); source=mech.make_source(state["current"],state["reference"]); src=evidence/"state.c"; src.write_text(source,encoding="utf-8")
    kind=state["feedback_type"]
    if kind=="Compile": result=mech.run_command([clang,"-std=c11","-O0",str(src),"-o",str(evidence/"state.exe")]); text=result["stderr"]
    elif kind=="Test":
        comp=mech.run_command([clang,"-std=c11","-O0",str(src),"-o",str(evidence/"state.exe")]); result=mech.run_command([str(evidence/"state.exe"),"--fixed"]) if comp["returncode"]==0 else comp; text=result["stderr"]
    elif kind=="Remark": result=mech.run_command([clang,"-std=c11","-O3","-Rpass-analysis=loop-vectorize","-Rpass-missed=loop-vectorize","-S","-emit-llvm",str(src),"-o",str(evidence/"remark.ll")]); text=result["stderr"]
    else:
        result=mech.run_command([clang,"-std=c11","-O0","-S","-emit-llvm",str(src),"-o",str(evidence/"state.ll")]); text=core.extract_function_ir((evidence/"state.ll").read_text(encoding="utf-8")) if result["returncode"]==0 else result["stderr"]
    text=(text or "").strip(); (evidence/"real_feedback.txt").write_text(text,encoding="utf-8")
    if not text: raise RuntimeError("empty {} feedback for {}".format(kind,state["state_id"]))
    return text[-6000:]

def prepare(clang,states,run_dir):
    for state in states: state["real_feedback"]=collect_feedback(clang,state,run_dir/"state_evidence"/state["state_id"])
    for state in states:
        peers=[s for s in states if s["feedback_type"]==state["feedback_type"]]
        pos=peers.index(state); state["placebo_feedback"]=peers[(pos+1)%len(peers)]["real_feedback"]

def condition_feedback(state,condition):
    if condition=="RealFeedback":return state["real_feedback"]
    if condition=="MatchedPlacebo":return state["placebo_feedback"]
    return "No new compiler feedback is available for this condition."

def prompt(state,condition):
    block=20260721+state["index"]+(1000 if condition=="N1" else 0); fn="static uint64_t candidate(const uint32_t *a, size_t n) {\n    "+state["current"]+"\n}"
    return """Independent hard-state P0
Condition: {c}
Task: {t}; family: {family}; state: {sid}; registered feedback type: {kind}
Paired sampling block: {block}
Intended contract: compute the same unsigned result as the original task for all arrays and n values.
Objective after repair: reduce candidate instructions under clang -std=c11 -O0 -S -emit-llvm.
Tool feedback:
{feedback}
Current function state:
{fn}
Return the required JSON object.""".format(c=condition,t=state["task_id"],family=state["family"],sid=state["state_id"],kind=state["feedback_type"],block=block,feedback=condition_feedback(state,condition),fn=fn)

def run_one(client,clang,run_dir,state):
    root=run_dir/"artifacts"/state["state_id"]; valid,baseline_ir,_,_=core.compile_measure(clang,state["canonical"],state["reference"],root/"canonical")
    if not valid.get("correctness") or not baseline_ir:raise RuntimeError("bad canonical "+state["state_id"])
    records=[]
    for condition in core.CONDITIONS:
        slot=root/condition; slot.mkdir(parents=True,exist_ok=True); user=prompt(state,condition); (slot/"prompt.txt").write_text(core.SYSTEM_PROMPT+"\n\n"+user,encoding="utf-8")
        response=output=None; error=None; elapsed=0; attempts=0; check=None; count=gain=None; utility=0.0
        try:
            response,elapsed,attempts=client.generate(user); (slot/"api_response.json").write_text(json.dumps(response,ensure_ascii=False,indent=2),encoding="utf-8"); output=core.parse_output(response["choices"][0]["message"].get("content","")); check,count,gain,utility=core.compile_measure(clang,output["candidate_body"],state["reference"],slot,baseline_ir)
        except Exception as exc:error="{}: {}".format(type(exc).__name__,exc)
        usage=response.get("usage",{}) if response else {}; message=response["choices"][0]["message"] if response else {}
        rec={"run_id":run_dir.name,"timestamp":core.now(),"task_id":state["task_id"],"program_family":state["family"],"state_id":state["state_id"],"feedback_type":state["feedback_type"],"condition":condition,"paired_seed_block":20260721+state["index"]+(1000 if condition=="N1" else 0),"model":core.MODEL,"generator_mode":"deepseek_api_hard_v1","system_prompt_sha256":core.h(core.SYSTEM_PROMPT),"user_prompt_sha256":core.h(user),"schema_sha256":core.h(core.canonical(core.SCHEMA)),"feedback_sha256":core.h(condition_feedback(state,condition)),"api_attempts":attempts,"api_elapsed_s":elapsed,"api_error":error,"finish_reason":response["choices"][0].get("finish_reason") if response else None,"reasoning_chars":len(message.get("reasoning_content") or ""),"usage":usage,"output":output,"baseline_ir_instructions":baseline_ir,"candidate_ir_instructions":count,"raw_static_gain":round(gain,8) if gain is not None else None,"correctness":bool(check and check.get("correctness")),"status":check.get("status") if check else "generation_failed","utility":round(utility,8),"tools":core.compact(check) if check else {}}
        records.append(rec); print("{}/{}/{}: {}, utility={:.4f}".format(state["state_id"],state["feedback_type"],condition,rec["status"],utility),flush=True)
    n0=next(r for r in records if r["condition"]=="N0")
    for rec in records:rec["delta_utility"]=round(rec["utility"]-n0["utility"],8);rec["beneficial_change"]=rec["delta_utility"]>0
    return records

def main():
    ap=argparse.ArgumentParser();ap.add_argument("--run-id",default="p0-hard-"+datetime.now().strftime("%Y%m%dT%H%M%SZ"));ap.add_argument("--results-dir",required=True);ap.add_argument("--limit-states",type=int,default=20);ap.add_argument("--run-kind",choices=("preflight","formal"),default="formal");ap.add_argument("--prepare-only",action="store_true");args=ap.parse_args()
    key=os.environ.get("DEEPSEEK_API_KEY");clang=shutil.which("clang")
    if not key or not clang:return 2
    run_dir=Path(args.results_dir)/args.run_id
    if run_dir.exists():print("run exists",file=sys.stderr);return 2
    run_dir.mkdir(parents=True);states=build_states();prepare(clang,states,run_dir)
    feedback_manifest=[{"state_id":s["state_id"],"task_id":s["task_id"],"family":s["family"],"feedback_type":s["feedback_type"],"real_sha256":core.h(s["real_feedback"]),"placebo_sha256":core.h(s["placebo_feedback"]),"real_chars":len(s["real_feedback"]),"placebo_chars":len(s["placebo_feedback"])} for s in states]
    (run_dir/"state_manifest.json").write_text(json.dumps(feedback_manifest,ensure_ascii=False,indent=2),encoding="utf-8")
    if args.prepare_only:print("PREPARED={}".format(run_dir));return 0
    client=core.Client(key);records=[]
    for number,state in enumerate(states[:args.limit_states],1):
        print("STATE {}/{}: {}/{}".format(number,args.limit_states,state["state_id"],state["feedback_type"]),flush=True);records.extend(run_one(client,clang,run_dir,state))
        with (run_dir/"records.partial.jsonl").open("w",encoding="utf-8") as fh:
            for rec in records:fh.write(json.dumps(rec,ensure_ascii=False,sort_keys=True)+"\n")
    compiler=mech.run_command([clang,"--version"])["stdout"].strip();core.write_results(run_dir,records,compiler,args.run_kind)
    manifest=json.loads((run_dir/"manifest.json").read_text(encoding="utf-8"));manifest.update({"experiment":"hard_state_v1","feedback_types":list(TYPES),"preregistration":"08_P0困难状态预注册.md"});(run_dir/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8");print("RESULTS={}".format(run_dir));return 0
if __name__=="__main__":sys.exit(main())
