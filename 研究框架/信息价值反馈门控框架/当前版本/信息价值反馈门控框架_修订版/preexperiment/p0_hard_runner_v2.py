#!/usr/bin/env python3
"""Hard-state P0 v2: target-only optimization remarks."""
import sys
from pathlib import Path
import p0_hard_runner as runner

_original_collect = runner.collect_feedback

def collect_feedback(clang, state, evidence):
    if state["feedback_type"] != "Remark":
        return _original_collect(clang, state, evidence)
    evidence.mkdir(parents=True, exist_ok=True)
    source = """#include <stdint.h>
#include <stddef.h>
__attribute__((used,noinline))
uint64_t candidate(const uint32_t *a, size_t n) {
    BODY
}
""".replace("BODY", state["current"])
    src = evidence / "target_remark_state.c"
    src.write_text(source, encoding="utf-8")
    result = runner.mech.run_command([
        clang, "-std=c11", "-O3",
        "-Rpass=loop-vectorize",
        "-Rpass-analysis=loop-vectorize",
        "-Rpass-missed=loop-vectorize",
        "-S", "-emit-llvm", str(src), "-o", str(evidence / "target_remark.ll")
    ])
    text = (result["stderr"] or "").strip()
    (evidence / "real_feedback.txt").write_text(text, encoding="utf-8")
    if not text:
        raise RuntimeError("empty target-only Remark feedback for " + state["state_id"])
    return text[-6000:]

runner.collect_feedback = collect_feedback

if __name__ == "__main__":
    sys.exit(runner.main())
