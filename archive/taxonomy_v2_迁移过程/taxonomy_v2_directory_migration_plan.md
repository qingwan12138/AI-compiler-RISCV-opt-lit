# taxonomy v2 directory migration plan

> **Planning only — no files have been moved.** The map preserves legacy paper-folder names beneath the new secondary-category folders, preventing the existing `paper.pdf` basename from becoming a flat-directory collision.

## Proposed target tree

```text
01_LLM_as_Selector/
  01_Pass_Phase_Flag_Selection/
  02_Schedule_Config_Autotuning/
  03_Search_RL_Policy/
  04_Agent_Tool_Action_Selection/
02_LLM_as_Translator/
  01_Source_Optimization_Refactoring/
  02_IR_ASM_Optimization_Superoptimization/
  03_Translation_CrossLanguage_CrossISA/
  04_GPU_Kernel_Accelerator_Optimization/
  05_Repair_Compiler_Feedback/
  06_Decompilation_LowLevel_Recovery/
03_LLM_as_Generator/
  01_Compiler_Pass_Generation/
  02_Optimization_Rule_Transform_Generation/
  03_Backend_Compiler_Component_Generation/
  04_Tool_Test_Fuzz_Generation/
90_Supporting/
  01_Benchmark_Dataset/
  02_Compiler_Infrastructure/
  03_LLM_RL_Foundation/
  04_Traditional_ML_Compiler_Optimization/
  05_Hardware_ISA_Compiler_Background/
  06_Survey_Evaluation_Methodology/
```

The reading-note tree should mirror this target tree under `文献逐篇阅读/`; the root-level tree would host the PDF paper directories.

## Migration protocol for a later approved phase

1. Freeze the legacy index and record a Git commit.
2. Create all target directories without deleting legacy paths.
3. Move each PDF directory and reading note together according to `taxonomy_v2_migration_map.csv`.
4. Rewrite local links in the legacy and v2 indexes, then update any cross-note references.
5. Validate every Markdown target and every local PDF link before removing only empty legacy directories.
6. Commit the migration separately from this taxonomy audit.

## Map summary

- Rows: **169** (one per Paper_ID)
- Canonical map: [taxonomy_v2_migration_map.csv](taxonomy_v2_migration_map.csv)
- No action from this plan has been executed.
