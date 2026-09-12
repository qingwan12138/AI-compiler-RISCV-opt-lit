# taxonomy v2 boundary cases

> 20 个回归案例。后续新增论文的分类不应与这些“最终输出对象优先”的判据矛盾。

| Paper | Primary | Why | Why not the competing category |
|---|---|---|---|
| C06 — AwareCompiler: Agentic Context-Aware Compiler Optimization via a Synergistic Knowledge-Data Driven Framework | SELECTOR / S1 | LLM produces a pass sequence and LLVM executes the transformations. | Not TRANSLATOR: it does not emit optimized IR/source. |
| 04 — Compiler-R1: Towards Agentic Compiler Auto-tuning with Reinforcement Learning | SELECTOR / S3 | RL-trained LM selects LLVM pass policies. | Not TRANSLATOR: action space is existing passes. |
| C35 — AutoPass: Evidence-Guided LLM Agents for Compiler Performance Tuning | SELECTOR / S4 | Agent uses evidence to choose tuning actions and pass choices. | Not TRANSLATOR: LLVM tools perform changes. |
| N15 — HINTPILOT: LLM-based Compiler Hint Synthesis for Code Optimization | SELECTOR / S4 | LLM emits source-positioned GCC hint combinations; GCC acts on them. | Not GENERATOR: hints are selected for the current input, not a reusable compiler component. |
| 42 — CompilerGPT: Leveraging Large Language Models for Analyzing and Acting on Compiler Optimization Reports | TRANSLATOR / T5 | LLM iteratively rewrites source code after compiler reports. | Not SELECTOR: reports are feedback; final model output is changed source. |
| 11 — Agentic Code Optimization via Compiler-LLM Cooperation | TRANSLATOR / T1 | Source/assembly agents directly emit transformed programs. | Not SELECTOR: a guiding layer chooses levels but is not the central output artifact. |
| 68 — CompileAgent: Automated Repository-Level Compilation with LLM Agent | TRANSLATOR / T5 | ErrorSolver emits repaired repository code after diagnostics. | Not SELECTOR: tools orchestrate repair but model output is source modification. |
| 54 — Learning to Combine Instructions in LLVM Compiler | TRANSLATOR / T2 | Neural encoder–decoder maps LLVM IR to optimized LLVM IR. | Not SUPPORTING: the model directly outputs a transformed program representation. |
| 12 — LLM-VeriOpt: Verification-Guided Reinforcement Learning for LLM-Based Compiler Optimization | TRANSLATOR / T2 | LLM emits optimized LLVM IR and Alive2 validates it. | Not a verification class: Alive2 is a verification tag only. |
| C08 — LPO: Discovering Missed Peephole Optimizations with Large Language Models | TRANSLATOR / T2 | LLM emits an optimized instruction sequence for each input slice. | Not GENERATOR: human review, rather than the LM, generalizes submitted rules. |
| 70 — Don't Transform the Code, Code the Transforms | GENERATOR / G2 | LLM writes a transformation function reusable across many programs. | Not TRANSLATOR: output is a transform program, not one result instance. |
| N06 — Unprecedented Code Change Automation: The Fusion of LLMs and Transformation by Example | GENERATOR / G2 | The workflow derives transformation rules and applies them project-wide. | Not TRANSLATOR: the final system artifact is a reusable rule. |
| 44 — Leveraging Large Language Models for Generalizing Peephole Optimizations | GENERATOR / G2 | LLM generalizes peephole examples into reusable rules. | Not TRANSLATOR: generalized rule is reused beyond a source instance. |
| C17 — LLM-Guided Strategy Synthesis for Scalable Equality Saturation | GENERATOR / G2 | Workflow produces reusable EqSatL strategy DSL artifacts. | Not SELECTOR: its strategy program survives and is reused online. |
| 41 — Finding Missed Code Size Optimizations in Compilers using LLMs | GENERATOR / G4 | LLM generates/mutates compiler test programs for differential discovery. | Not G2: the generated output is test/fuzz input, not an optimization rule. |
| 53 — BenchDirect: A Directed Language Model for Compiler Benchmarks | GENERATOR / G4 | Conditioned LM emits compiler-featured OpenCL benchmark programs. | Not B1: benchmark programs are generated compiler-facing artifacts. |
| 60 — Virtual Compiler Is All You Need for Assembly Code Search | SUPPORTING / B3 | Virtual compiler supports retrieval-data synthesis, not validated compilation optimization. | Not TRANSLATOR: generated assembly is not the system output evaluated as a compiler transform. |
| 39 — Enhancing Translation Validation of Compiler Transformations with Large Language Models | SUPPORTING / B6 | LLM judges soundness of existing transformations in a validation pipeline. | Not SELECTOR/TRANSLATOR/GENERATOR: it emits verdicts and explanations. |
| C28 — Guided Tensor Lifting | TRANSLATOR / T3 | LLM emits C-to-TACO candidate programs; search/CBMC validate candidates. | Not GENERATOR: candidates are input-instance translations, not reusable transforms. |
| 101 — TritonBench: Benchmarking LLMs for Triton Operator Generation | SUPPORTING / B1 | TritonBench evaluates external LLM kernel outputs. | Not T4: the paper provides the benchmark, not a new kernel-optimizing system. |
