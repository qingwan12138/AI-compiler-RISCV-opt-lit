# taxonomy v2 validation report

- Source index: `00_分类索引.md`
- Scope: first-stage metadata/taxonomy mapping only; no legacy PDF, note, directory, or old-index modification.
- Reading notes consulted: **169/169**

## Validation summary

| Check | Result |
|---|---:|
| Total papers | 169 |
| Classified | 169 |
| Unclassified | 0 |
| Duplicate Paper_ID | 0 |
| Empty Primary_Category | 0 |
| Invalid primary category | 0 |
| Invalid secondary category | 0 |
| Needs review | 14 |
| Validation status | PASS |

## Primary distribution

| Primary_Category | Count |
|---|---:|
| SELECTOR | 17 |
| TRANSLATOR | 61 |
| GENERATOR | 7 |
| SUPPORTING | 84 |

## Secondary category distribution

| Primary_Category | Secondary_Category | Count |
|---|---|---:|
| SELECTOR | 01_Pass_Phase_Flag选择 | 2 |
| SELECTOR | 02_Schedule_Config_Autotuning | 4 |
| SELECTOR | 03_Search_RL_Policy | 4 |
| SELECTOR | 04_Agent_Tool_Action选择 | 7 |
| TRANSLATOR | 01_Source代码优化与重构 | 27 |
| TRANSLATOR | 02_IR_ASM直接优化与Superoptimization | 6 |
| TRANSLATOR | 03_代码翻译_跨语言_跨ISA | 9 |
| TRANSLATOR | 04_GPU_Kernel_Accelerator优化 | 8 |
| TRANSLATOR | 05_程序修复与Compiler_Feedback | 4 |
| TRANSLATOR | 06_反编译与低层代码恢复 | 7 |
| GENERATOR | 01_Compiler_Pass生成 | 1 |
| GENERATOR | 02_优化规则_Transform生成 | 5 |
| GENERATOR | 03_Compiler_Backend_Component生成 | 0 |
| GENERATOR | 04_Compiler_Tool_Test_Fuzz生成 | 1 |
| SUPPORTING | 01_Benchmark_Dataset | 10 |
| SUPPORTING | 02_Compiler_Infrastructure | 18 |
| SUPPORTING | 03_LLM_RL基础方法 | 8 |
| SUPPORTING | 04_传统ML编译优化 | 25 |
| SUPPORTING | 05_RISC-V_GPU_硬件与编译器背景 | 11 |
| SUPPORTING | 06_Evaluation_Survey_Methodology | 12 |

## Old category → new category migration matrix

| Old category | SELECTOR | TRANSLATOR | GENERATOR | SUPPORTING | Total |
|---|---:|---:|---:|---:|---:|
| 01 编译阶段排序与强化学习调优（28 篇） | 7 | 4 | 0 | 17 | 28 |
| 02 LLM 编译优化智能体与反馈驱动（71 篇） | 9 | 44 | 3 | 15 | 71 |
| 03 形式验证、超级优化与规则生成（32 篇） | 1 | 10 | 4 | 17 | 32 |
| 04 向量化与跨 ISA 代码迁移（6 篇） | 0 | 2 | 0 | 4 | 6 |
| 05 RISC-V、RVV 编译器与真实后端（9 篇） | 0 | 0 | 0 | 9 | 9 |
| 06 多硬件编译、代价模型与 IR 基础设施（23 篇） | 0 | 1 | 0 | 22 | 23 |

## NEEDS_REVIEW papers

| Paper_ID | Title | Candidate Primary | Ambiguity | Why Needs Review |
|---|---|---|---|---|
| C06 | AwareCompiler: Agentic Context-Aware Compiler Optimization via a Synergistic Knowledge-Data Driven Framework | SELECTOR | 笔记同时描述编译器代理的诊断交互与策略选择；以最终的编译动作选择为主分类。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 11 | Agentic Code Optimization via Compiler-LLM Cooperation | TRANSLATOR | 代理流程同时含选择与直接代码优化；笔记不足以稳定量化哪一环是主要贡献。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 42 | CompilerGPT: Leveraging Large Language Models for Analyzing and Acting on Compiler Optimization Reports | SELECTOR | 模型既分析编译报告又执行修正动作；当前按工具动作选择处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 60 | Virtual Compiler Is All You Need for Assembly Code Search | SELECTOR | 候选汇编搜索与生成界线较近；当前按候选选择而非可复用组件生成处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 68 | CompileAgent: Automated Repository-Level Compilation with LLM Agent | SELECTOR | 论文将项目编译交互与代理调度结合；当前按工具动作选择处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 69 | AIOS: LLM as Interpreter for Natural Language Programming | TRANSLATOR | 自然语言编程系统的最终代码生成和编译优化边界不够清楚。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| N05 | Rethinking Code Refinement: Learning to Judge Code Efficiency | SELECTOR | 效率评判器可能只评估候选，也可能驱动后续重写；当前按候选选择处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| N06 | Unprecedented Code Change Automation: The Fusion of LLMs and Transformation by Example | TRANSLATOR | 按示例变换可能生成实例代码，也可能归纳可复用变换；当前按直接变换处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| N15 | HINTPILOT: LLM-based Compiler Hint Synthesis for Code Optimization | SELECTOR | 编译提示既可能被视为策略选择，也可能是生成的提示工件；当前按工具动作选择。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 15 | Verified Learning for Compiler Optimization: An LLM-Based Approach | TRANSLATOR | 验证学习框架中模型输出与验证器角色交织；当前按直接 IR 变换处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 39 | Enhancing Translation Validation of Compiler Transformations with Large Language Models | SUPPORTING | 翻译验证的 LLM 介入点在笔记中不够明确；当前保守归为验证方法支撑。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| 41 | Finding Missed Code Size Optimizations in Compilers using LLMs | GENERATOR | 发现漏优化可能输出具体样例或可泛化规则；当前按生成优化规则处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| C17 | LLM-Guided Strategy Synthesis for Scalable Equality Saturation | SELECTOR | e-graph 策略综合可被解释为选择策略或生成策略程序；当前按选择策略处理。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |
| C28 | Guided Tensor Lifting | TRANSLATOR | 张量 lifting 的输出层级和模型角色较难从现有笔记唯一确定。 | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |

## Validation rules applied

1. Source index must contain exactly 169 rows with linked reading notes.
2. Every row must have exactly one non-empty Primary_Category from the controlled four-value vocabulary.
3. Every Secondary_Category must belong to its Primary_Category controlled vocabulary.
4. Paper_ID values must be unique.
5. SUPPORTING is a valid high-confidence result, not a synonym for NEEDS_REVIEW.
6. NEEDS_REVIEW is reserved for genuinely ambiguous LM final-output roles; a single current Primary candidate is still retained.
