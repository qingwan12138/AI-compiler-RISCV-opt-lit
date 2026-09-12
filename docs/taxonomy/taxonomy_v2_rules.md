# Taxonomy v2 rules

## Current corpus ledger

`taxonomy_v2.csv` is the canonical machine-readable ledger for current paper IDs,
primary and secondary categories, tags, review state, and local files. Its active
path columns are `PDF_Path` and `Note_Path`. The Markdown role index is
`00_三大类分类索引_v2.md`; `文献逐篇阅读/00_逐篇阅读目录.md` is the reading-note
catalog. The old six-category index and migration-only columns are historical
records, not inputs to new-paper processing.

The ledger has one row per paper. When adding an item, assign a new `Paper_ID`,
set one valid primary and compatible secondary category, then record paths under
the matching primary/secondary directories. Keep the existing CSV field order.
Historical old-category and old-path mappings are preserved in
`archive/taxonomy_v2_迁移过程/taxonomy_v2_with_migration_fields_2026-09-12.csv`.

## Primary decision rule

Classify the **final compiler-system role of the LM**, not its training method,
platform, verifier, or agent wrapper.

1. **SELECTOR** — the LM emits a pass, phase, flag, schedule, configuration,
   candidate, policy, or tool action; an existing compiler/tool performs the
   program transformation.
2. **TRANSLATOR** — the LM directly emits a transformed source program, IR,
   assembly, kernel, repair, translation, or recovered low-level program.
3. **GENERATOR** — the LM emits a reusable compiler capability, such as a
   pass, rewrite/transform rule, backend component, tool, test generator, or
   fuzzer.
4. **SUPPORTING** — the work is a benchmark/dataset, compiler infrastructure,
   LLM/RL foundation, traditional non-LM compiler ML, hardware/ISA background,
   or survey/evaluation methodology.  Supporting is a valid result, not a
   fallback for uncertainty.

When the primary role cannot be established from the note or paper evidence,
select the most defensible single primary and set `Needs_Review=YES`.

## Controlled secondary vocabulary

| Primary | Allowed secondary categories |
|---|---|
| SELECTOR | S1 Pass/Phase/Flag; S2 Schedule/Config; S3 Search/RL/Policy; S4 Agent/Tool Action |
| TRANSLATOR | T1 Source Optimization; T2 IR/ASM/Superoptimization; T3 Cross-language/ISA Translation; T4 GPU/Accelerator Kernel; T5 Repair/Compiler Feedback; T6 Decompilation/Low-level Recovery |
| GENERATOR | G1 Compiler Pass; G2 Optimization Rule/Transform; G3 Backend/Compiler Component; G4 Tool/Test/Fuzz |
| SUPPORTING | B1 Benchmark/Dataset; B2 Compiler Infrastructure; B3 LLM/RL Foundation; B4 Traditional ML Compiler Optimization; B5 Hardware/ISA Background; B6 Survey/Evaluation Methodology |

## Tags are never primary categories

Agent, RL/GRPO/PPO, Alive2/formal verification, LLVM/MLIR, RISC-V/RVV, GPU,
CUDA, and feedback mechanisms are recorded as tags only.  They do not choose
the primary category.

## Adding a new paper

Run `python scripts/classify_new_paper_template.py --title "..."` to create a
proposal.  Verify final LM output from the actual paper/note, assign exactly
one controlled Primary and compatible Secondary, then manually add the row to
`taxonomy_v2.csv`.  Do not let the helper overwrite canonical taxonomy data.
