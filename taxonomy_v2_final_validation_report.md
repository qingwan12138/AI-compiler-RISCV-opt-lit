# taxonomy v2 final validation report

## TAXONOMY V2 FINAL STATUS

**Overall: PASS**

- Source commit: `a6cc71496c356c73ecc29dd47679498a4b225397`
- Total papers / classified: **169 / 169**
- Duplicate Paper_ID: **0**
- Invalid or empty primary/secondary: **0**
- Canonical PDF hash mismatch: **0**
- Missing canonical PDF: **0** (four source-limited rows are explicitly marked)
- Reading-note missing after migration: **0**
- Notes changed only for link repair: **3**
- Migration-introduced broken links: **0**
- Old-category canonical residual: **0**
- Unmapped PDF inventory retained and reported: **1**

## Primary distribution

- SELECTOR: 12
- TRANSLATOR: 62
- GENERATOR: 10
- SUPPORTING: 85

## Secondary distribution

- B1_Benchmark_Dataset: 9
- B2_Compiler_Infrastructure: 18
- B3_LLM_RL_Foundation: 9
- B4_Traditional_ML_Compiler_Optimization: 24
- B5_Hardware_ISA_Compiler_Background: 11
- B6_Survey_Evaluation_Methodology: 14
- G1_Compiler_Pass_Generation: 1
- G2_Optimization_Rule_Transform_Generation: 6
- G4_Tool_Test_Fuzz_Generation: 3
- S1_Pass_Phase_Flag_Selection: 3
- S2_Schedule_Config_Autotuning: 4
- S3_Search_RL_Policy: 3
- S4_Agent_Tool_Action_Selection: 2
- T1_Source_Optimization_Refactoring: 25
- T2_IR_ASM_Optimization_Superoptimization: 7
- T3_Translation_CrossLanguage_CrossISA: 9
- T4_GPU_Kernel_Accelerator_Optimization: 8
- T5_Repair_Compiler_Feedback: 6
- T6_Decompilation_LowLevel_Recovery: 7

## Needs Review

- `08` — Foundation Language Models for Compiler Optimization
- `15` — Verified Learning for Compiler Optimization: An LLM-Based Approach

## Link and residual caveats

The legacy v1 index is intentionally byte-preserved in `archive/taxonomy_v1`; its old links are reported as archive exemptions. One non-canonical/unmapped PDF remains in an old directory by explicit instruction and is listed in the residual audit.
