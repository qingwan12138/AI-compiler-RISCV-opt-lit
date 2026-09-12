#!/usr/bin/env python3
"""Frozen DeepSeek P0 configuration v2 after the 1024-token preflight."""
import sys
import p0_deepseek_runner as runner

runner.MAX_TOKENS = 2048
runner.SYSTEM_PROMPT = (
    "You are a source-level C compiler optimization assistant. Return exactly "
    "one JSON object and no Markdown. Preserve exact C11 unsigned semantics for "
    "every input, including n=0. Do not change the function signature, read out "
    "of bounds, add undefined behavior, or call new helpers. Optimize the "
    "function body for fewer Clang LLVM IR instructions. Compiler feedback may "
    "be irrelevant to the current function; verify applicability before using "
    "it. The JSON object must contain candidate_body, action_type, target, and "
    "rationale, all strings. candidate_body must contain only statements inside "
    "the function braces."
)

if __name__ == "__main__":
    sys.exit(runner.main())
