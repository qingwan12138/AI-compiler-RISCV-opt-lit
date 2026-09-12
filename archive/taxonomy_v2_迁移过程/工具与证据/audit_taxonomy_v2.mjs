import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const sourceIndex = path.join(root, '00_分类索引.md');
const csvPath = path.join(root, 'taxonomy_v2.csv');
const mdPath = path.join(root, '00_三大类分类索引_v2.md');
const validationPath = path.join(root, 'taxonomy_v2_validation_report.md');
const queuePath = path.join(root, 'taxonomy_v2_review_queue.md');
const boundaryPath = path.join(root, 'taxonomy_v2_boundary_cases.md');
const migrationPlanPath = path.join(root, 'taxonomy_v2_directory_migration_plan.md');
const migrationCsvPath = path.join(root, 'taxonomy_v2_migration_map.csv');
const linkImpactPath = path.join(root, 'taxonomy_v2_link_impact_report.md');

const primaryOrder = ['SELECTOR', 'TRANSLATOR', 'GENERATOR', 'SUPPORTING'];
const primaryNames = {
  SELECTOR: 'LLM as Selector', TRANSLATOR: 'LLM as Translator',
  GENERATOR: 'LLM as Generator', SUPPORTING: 'Supporting Literature',
};
const secondary = {
  SELECTOR: [
    'S1_Pass_Phase_Flag_Selection', 'S2_Schedule_Config_Autotuning',
    'S3_Search_RL_Policy', 'S4_Agent_Tool_Action_Selection',
  ],
  TRANSLATOR: [
    'T1_Source_Optimization_Refactoring', 'T2_IR_ASM_Optimization_Superoptimization',
    'T3_Translation_CrossLanguage_CrossISA', 'T4_GPU_Kernel_Accelerator_Optimization',
    'T5_Repair_Compiler_Feedback', 'T6_Decompilation_LowLevel_Recovery',
  ],
  GENERATOR: [
    'G1_Compiler_Pass_Generation', 'G2_Optimization_Rule_Transform_Generation',
    'G3_Backend_Compiler_Component_Generation', 'G4_Tool_Test_Fuzz_Generation',
  ],
  SUPPORTING: [
    'B1_Benchmark_Dataset', 'B2_Compiler_Infrastructure', 'B3_LLM_RL_Foundation',
    'B4_Traditional_ML_Compiler_Optimization', 'B5_Hardware_ISA_Compiler_Background',
    'B6_Survey_Evaluation_Methodology',
  ],
};
const secondaryLabels = {
  S1_Pass_Phase_Flag_Selection: 'Pass / Phase / Flag Selection',
  S2_Schedule_Config_Autotuning: 'Schedule / Config / Autotuning',
  S3_Search_RL_Policy: 'Search / RL / Policy',
  S4_Agent_Tool_Action_Selection: 'Agent / Tool Action Selection',
  T1_Source_Optimization_Refactoring: 'Source Optimization / Refactoring',
  T2_IR_ASM_Optimization_Superoptimization: 'IR / ASM Optimization & Superoptimization',
  T3_Translation_CrossLanguage_CrossISA: 'Translation / Cross-Language / Cross-ISA',
  T4_GPU_Kernel_Accelerator_Optimization: 'GPU Kernel / Accelerator Optimization',
  T5_Repair_Compiler_Feedback: 'Repair / Compiler Feedback',
  T6_Decompilation_LowLevel_Recovery: 'Decompilation / Low-Level Recovery',
  G1_Compiler_Pass_Generation: 'Compiler Pass Generation',
  G2_Optimization_Rule_Transform_Generation: 'Optimization Rule / Transform Generation',
  G3_Backend_Compiler_Component_Generation: 'Backend / Compiler Component Generation',
  G4_Tool_Test_Fuzz_Generation: 'Tool / Test / Fuzz Generation',
  B1_Benchmark_Dataset: 'Benchmark / Dataset',
  B2_Compiler_Infrastructure: 'Compiler Infrastructure',
  B3_LLM_RL_Foundation: 'LLM / RL Foundation',
  B4_Traditional_ML_Compiler_Optimization: 'Traditional ML Compiler Optimization',
  B5_Hardware_ISA_Compiler_Background: 'Hardware / ISA / Compiler Background',
  B6_Survey_Evaluation_Methodology: 'Survey / Evaluation / Methodology',
};
const targetDirs = {
  S1_Pass_Phase_Flag_Selection: '01_LLM_as_Selector/01_Pass_Phase_Flag_Selection',
  S2_Schedule_Config_Autotuning: '01_LLM_as_Selector/02_Schedule_Config_Autotuning',
  S3_Search_RL_Policy: '01_LLM_as_Selector/03_Search_RL_Policy',
  S4_Agent_Tool_Action_Selection: '01_LLM_as_Selector/04_Agent_Tool_Action_Selection',
  T1_Source_Optimization_Refactoring: '02_LLM_as_Translator/01_Source_Optimization_Refactoring',
  T2_IR_ASM_Optimization_Superoptimization: '02_LLM_as_Translator/02_IR_ASM_Optimization_Superoptimization',
  T3_Translation_CrossLanguage_CrossISA: '02_LLM_as_Translator/03_Translation_CrossLanguage_CrossISA',
  T4_GPU_Kernel_Accelerator_Optimization: '02_LLM_as_Translator/04_GPU_Kernel_Accelerator_Optimization',
  T5_Repair_Compiler_Feedback: '02_LLM_as_Translator/05_Repair_Compiler_Feedback',
  T6_Decompilation_LowLevel_Recovery: '02_LLM_as_Translator/06_Decompilation_LowLevel_Recovery',
  G1_Compiler_Pass_Generation: '03_LLM_as_Generator/01_Compiler_Pass_Generation',
  G2_Optimization_Rule_Transform_Generation: '03_LLM_as_Generator/02_Optimization_Rule_Transform_Generation',
  G3_Backend_Compiler_Component_Generation: '03_LLM_as_Generator/03_Backend_Compiler_Component_Generation',
  G4_Tool_Test_Fuzz_Generation: '03_LLM_as_Generator/04_Tool_Test_Fuzz_Generation',
  B1_Benchmark_Dataset: '90_Supporting/01_Benchmark_Dataset',
  B2_Compiler_Infrastructure: '90_Supporting/02_Compiler_Infrastructure',
  B3_LLM_RL_Foundation: '90_Supporting/03_LLM_RL_Foundation',
  B4_Traditional_ML_Compiler_Optimization: '90_Supporting/04_Traditional_ML_Compiler_Optimization',
  B5_Hardware_ISA_Compiler_Background: '90_Supporting/05_Hardware_ISA_Compiler_Background',
  B6_Survey_Evaluation_Methodology: '90_Supporting/06_Survey_Evaluation_Methodology',
};
const legacySecondaryToCode = {
  '01_Pass_Phase_Flag选择': 'S1_Pass_Phase_Flag_Selection',
  '02_Schedule_Config_Autotuning': 'S2_Schedule_Config_Autotuning',
  '03_Search_RL_Policy': 'S3_Search_RL_Policy',
  '04_Agent_Tool_Action选择': 'S4_Agent_Tool_Action_Selection',
  '01_Source代码优化与重构': 'T1_Source_Optimization_Refactoring',
  '02_IR_ASM直接优化与Superoptimization': 'T2_IR_ASM_Optimization_Superoptimization',
  '03_代码翻译_跨语言_跨ISA': 'T3_Translation_CrossLanguage_CrossISA',
  '04_GPU_Kernel_Accelerator优化': 'T4_GPU_Kernel_Accelerator_Optimization',
  '05_程序修复与Compiler_Feedback': 'T5_Repair_Compiler_Feedback',
  '06_反编译与低层代码恢复': 'T6_Decompilation_LowLevel_Recovery',
  '01_Compiler_Pass生成': 'G1_Compiler_Pass_Generation',
  '02_优化规则_Transform生成': 'G2_Optimization_Rule_Transform_Generation',
  '03_Compiler_Backend_Component生成': 'G3_Backend_Compiler_Component_Generation',
  '04_Compiler_Tool_Test_Fuzz生成': 'G4_Tool_Test_Fuzz_Generation',
  '01_Benchmark_Dataset': 'B1_Benchmark_Dataset',
  '02_Compiler_Infrastructure': 'B2_Compiler_Infrastructure',
  '03_LLM_RL基础方法': 'B3_LLM_RL_Foundation',
  '04_传统ML编译优化': 'B4_Traditional_ML_Compiler_Optimization',
  '05_RISC-V_GPU_硬件与编译器背景': 'B5_Hardware_ISA_Compiler_Background',
  '06_Evaluation_Survey_Methodology': 'B6_Survey_Evaluation_Methodology',
};
function parseCsv(text) {
  const records = []; let row = []; let cell = ''; let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (c === '"') quoted = false;
      else cell += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n') { row.push(cell.replace(/\r$/, '')); records.push(row); row = []; cell = ''; }
    else cell += c;
  }
  if (cell || row.length) { row.push(cell); records.push(row); }
  const [header, ...data] = records;
  return data.filter(x => x.length && x.some(Boolean)).map(cells => Object.fromEntries(header.map((h, i) => [h, cells[i] ?? ''])));
}
function csv(v) { return `"${String(v ?? '').replaceAll('"', '""')}"`; }
function md(v) { return String(v ?? '').replaceAll('|', '\\|').replaceAll('\n', ' '); }
function titleFromCell(cell) { return cell.match(/^\[([^\]]+)\]\(/)?.[1] ?? cell; }
function uniq(a) { return [...new Set(a)]; }
function count(rows, key) { const out = new Map(); for (const row of rows) out.set(row[key], (out.get(row[key]) ?? 0) + 1); return out; }
function readAllMarkdown(dir) {
  const output = [];
  function walk(d) {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      if (entry.name === '.git' || entry.name === 'tmp') continue;
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full); else if (entry.name.toLowerCase().endsWith('.md')) output.push(full);
    }
  }
  walk(dir); return output;
}
function classifyRationale(primary, sub) {
  const phrase = {
    S1_Pass_Phase_Flag_Selection: 'selects compiler passes, phases, or flags',
    S2_Schedule_Config_Autotuning: 'selects a schedule, configuration, or autotuning setting',
    S3_Search_RL_Policy: 'outputs a search or optimization policy over existing actions',
    S4_Agent_Tool_Action_Selection: 'chooses compiler/tool actions while external tools perform transformations',
    T1_Source_Optimization_Refactoring: 'directly emits transformed source code',
    T2_IR_ASM_Optimization_Superoptimization: 'directly emits optimized IR or assembly',
    T3_Translation_CrossLanguage_CrossISA: 'directly emits a translated program representation',
    T4_GPU_Kernel_Accelerator_Optimization: 'directly emits an optimized accelerator kernel',
    T5_Repair_Compiler_Feedback: 'directly emits repaired source code using compiler feedback',
    T6_Decompilation_LowLevel_Recovery: 'directly emits recovered source code from low-level input',
    G1_Compiler_Pass_Generation: 'synthesizes a reusable compiler pass',
    G2_Optimization_Rule_Transform_Generation: 'synthesizes reusable rewrite rules or transformation programs',
    G3_Backend_Compiler_Component_Generation: 'synthesizes a reusable backend/compiler component',
    G4_Tool_Test_Fuzz_Generation: 'generates reusable compiler-facing test, fuzz, or tooling artifacts',
    B1_Benchmark_Dataset: 'provides a benchmark or dataset rather than a core LM compiler role',
    B2_Compiler_Infrastructure: 'provides compiler infrastructure rather than a core LM compiler role',
    B3_LLM_RL_Foundation: 'provides a foundation model or learning foundation rather than one final compiler role',
    B4_Traditional_ML_Compiler_Optimization: 'uses a traditional/non-LM compiler-learning method rather than an LM core role',
    B5_Hardware_ISA_Compiler_Background: 'provides hardware, ISA, or backend background rather than an LM core role',
    B6_Survey_Evaluation_Methodology: 'evaluates or surveys systems rather than proposing one core LM compiler role',
  }[sub];
  if (primary === 'SELECTOR') return `The model ${phrase}; therefore its primary compiler role is SELECTOR.`;
  if (primary === 'TRANSLATOR') return `The model ${phrase}; therefore its primary compiler role is TRANSLATOR.`;
  if (primary === 'GENERATOR') return `The model ${phrase}, not merely one input instance; therefore its primary compiler role is GENERATOR.`;
  return `The work ${phrase}; the LM does not itself serve as the system's Selector, Translator, or Generator, therefore classified as SUPPORTING.`;
}
function setFields(row, primary, sub) {
  row.Primary_Category = primary; row.Secondary_Category = sub;
  row.Role = primary === 'SELECTOR' ? (sub === 'S4_Agent_Tool_Action_Selection' ? 'AGENT_ORCHESTRATOR;SELECTOR_POLICY' : 'SELECTOR_POLICY')
    : primary === 'TRANSLATOR' ? (sub === 'T5_Repair_Compiler_Feedback' ? 'TRANSLATOR_TRANSFORMER;REPAIRER' : 'TRANSLATOR_TRANSFORMER')
    : primary === 'GENERATOR' ? 'GENERATOR' : 'INFRA_EVALUATOR';
  const tasks = {
    S1_Pass_Phase_Flag_Selection: 'OPT;PASS_ORDERING', S2_Schedule_Config_Autotuning: 'AUTOTUNING;OPT',
    S3_Search_RL_Policy: 'OPT;PASS_ORDERING;AUTOTUNING', S4_Agent_Tool_Action_Selection: 'OPT;ANALYSIS',
    T1_Source_Optimization_Refactoring: 'OPT', T2_IR_ASM_Optimization_Superoptimization: 'OPT;VERIFICATION',
    T3_Translation_CrossLanguage_CrossISA: 'TRANSLATION', T4_GPU_Kernel_Accelerator_Optimization: 'OPT;AUTOTUNING',
    T5_Repair_Compiler_Feedback: 'REPAIR', T6_Decompilation_LowLevel_Recovery: 'DECOMPILATION;TRANSLATION',
    G1_Compiler_Pass_Generation: 'GENERATION;OPT', G2_Optimization_Rule_Transform_Generation: 'GENERATION;OPT',
    G3_Backend_Compiler_Component_Generation: 'GENERATION;OPT', G4_Tool_Test_Fuzz_Generation: 'TESTING;GENERATION',
    B1_Benchmark_Dataset: 'ANALYSIS;TESTING', B2_Compiler_Infrastructure: 'ANALYSIS', B3_LLM_RL_Foundation: 'ANALYSIS',
    B4_Traditional_ML_Compiler_Optimization: 'ANALYSIS', B5_Hardware_ISA_Compiler_Background: 'ANALYSIS', B6_Survey_Evaluation_Methodology: 'ANALYSIS',
  };
  const io = {
    S1_Pass_Phase_Flag_Selection: ['LLVM_IR;COMPILER_CONFIG', 'COMPILER_CONFIG'], S2_Schedule_Config_Autotuning: ['LLVM_IR;HW_CONFIG', 'COMPILER_CONFIG'],
    S3_Search_RL_Policy: ['LLVM_IR;COMPILER_CONFIG', 'COMPILER_CONFIG'], S4_Agent_Tool_Action_Selection: ['SOURCE;LLVM_IR;COMPILER_CONFIG', 'COMPILER_CONFIG'],
    T1_Source_Optimization_Refactoring: ['SOURCE', 'SOURCE'], T2_IR_ASM_Optimization_Superoptimization: ['LLVM_IR;ASM', 'LLVM_IR;ASM'],
    T3_Translation_CrossLanguage_CrossISA: ['SOURCE;ASM;BINARY', 'SOURCE;ASM'], T4_GPU_Kernel_Accelerator_Optimization: ['SOURCE', 'SOURCE'],
    T5_Repair_Compiler_Feedback: ['SOURCE;COMPILER_CONFIG', 'SOURCE'], T6_Decompilation_LowLevel_Recovery: ['BINARY;ASM', 'SOURCE'],
    G1_Compiler_Pass_Generation: ['SOURCE;LLVM_IR', 'COMPILER_CONFIG'], G2_Optimization_Rule_Transform_Generation: ['SOURCE;LLVM_IR', 'COMPILER_CONFIG'],
    G3_Backend_Compiler_Component_Generation: ['LLVM_IR;HW_CONFIG', 'COMPILER_CONFIG'], G4_Tool_Test_Fuzz_Generation: ['SOURCE;LLVM_IR', 'SOURCE'],
    B1_Benchmark_Dataset: ['SOURCE;LLVM_IR', 'SOURCE;LLVM_IR'], B2_Compiler_Infrastructure: ['LLVM_IR', 'LLVM_IR'], B3_LLM_RL_Foundation: ['NL;SOURCE', 'SOURCE'],
    B4_Traditional_ML_Compiler_Optimization: ['SOURCE;LLVM_IR', 'LLVM_IR'], B5_Hardware_ISA_Compiler_Background: ['HW_CONFIG;LLVM_IR', 'ASM'], B6_Survey_Evaluation_Methodology: ['SOURCE;LLVM_IR', 'SOURCE;LLVM_IR'],
  };
  row.Task = tasks[sub]; [row.Input_Level, row.Output_Level] = io[sub]; row.Classification_Rationale = classifyRationale(primary, sub);
}

const source = fs.readFileSync(sourceIndex, 'utf8').replace(/\r/g, '');
const linked = new Map();
for (const line of source.split('\n')) {
  if (!/^\|\s*(?:\d+|N\d+|C\d+)\s*\|/.test(line)) continue;
  const cells = line.split('|').slice(1, -1).map(x => x.trim());
  const [id, year, oldCategory, titleCell, pdfCell] = cells;
  linked.set(id, {
    year, oldCategory, title: titleFromCell(titleCell),
    note: titleCell.match(/\]\((文献逐篇阅读\/[^)]+\.md)\)/)?.[1] ?? '',
    pdf: pdfCell.match(/\]\(<([^>]+)>\)/)?.[1] ?? '',
  });
}
const rows = parseCsv(fs.readFileSync(csvPath, 'utf8'));
if (rows.length !== 169 || linked.size !== 169) throw new Error(`Expected 169 CSV/index rows; got ${rows.length}/${linked.size}`);
for (const row of rows) {
  const legacy = linked.get(row.Paper_ID);
  if (!legacy) throw new Error(`Paper_ID ${row.Paper_ID} missing from legacy index`);
  const notePath = path.join(root, ...legacy.note.split('/'));
  if (!fs.existsSync(notePath)) throw new Error(`Missing note for ${row.Paper_ID}`);
  row._legacy = legacy; row._note = fs.readFileSync(notePath, 'utf8');
  row.Secondary_Category = legacySecondaryToCode[row.Secondary_Category] ?? row.Secondary_Category;
}

// Evidence-led changes found in the focused audit. The old structure is never touched.
const auditChanges = new Map([
  ['42', ['TRANSLATOR', 'T5_Repair_Compiler_Feedback', 'HIGH', 'NO', 'The note documents an LLM diagnosis–rewrite loop whose final artifact is revised source code; compiler reports are feedback, so this is TRANSLATOR rather than Selector.']],
  ['60', ['SUPPORTING', 'B3_LLM_RL_Foundation', 'HIGH', 'NO', 'The note states the virtual compiler is trained to synthesize retrieval data and does not optimize or execute programs; it is a language-model/data foundation, not Selector.']],
  ['68', ['TRANSLATOR', 'T5_Repair_Compiler_Feedback', 'HIGH', 'NO', 'ErrorSolver emits repository repair code after compiler diagnostics; tool orchestration is auxiliary, so the final LM role is Translator.']],
  ['69', ['SUPPORTING', 'B6_Survey_Evaluation_Methodology', 'HIGH', 'NO', 'The note explicitly identifies AIOS as an agent-interpreter framework, not a code-generation or compiler-optimization mechanism.']],
  ['N05', ['SUPPORTING', 'B6_Survey_Evaluation_Methodology', 'HIGH', 'NO', 'The model judges which pre-existing code edit is faster; it evaluates candidates but does not select a compiler action for a compiler system.']],
  ['N06', ['GENERATOR', 'G2_Optimization_Rule_Transform_Generation', 'HIGH', 'NO', 'The workflow derives and applies reusable transformation rules across projects, rather than returning only one transformed program instance.']],
  ['C17', ['GENERATOR', 'G2_Optimization_Rule_Transform_Generation', 'HIGH', 'NO', 'The LLM workflow produces reusable EqSatL strategy DSL artifacts and cached motifs; this is transform generation, not merely action selection.']],
  ['53', ['GENERATOR', 'G4_Tool_Test_Fuzz_Generation', 'HIGH', 'NO', 'BenchDirect conditionally emits compiler-featured OpenCL benchmark programs that expand a reusable benchmark artifact set.']],
  ['54', ['TRANSLATOR', 'T2_IR_ASM_Optimization_Superoptimization', 'HIGH', 'NO', 'The Transformer encoder–decoder directly maps input LLVM IR to optimized LLVM IR; it is a Translator even though it is not a modern large LLM.']],
  ['41', ['GENERATOR', 'G4_Tool_Test_Fuzz_Generation', 'HIGH', 'NO', 'The LLM iteratively generates and mutates C/C++ compiler test programs for differential discovery; its reusable output role is test/fuzz generation.']],
  ['C06', ['SELECTOR', 'S1_Pass_Phase_Flag_Selection', 'HIGH', 'NO', 'The note explicitly states that the LLM generates a pass sequence and LLVM executes it; this is unambiguously Selector.']],
  ['11', ['TRANSLATOR', 'T1_Source_Optimization_Refactoring', 'HIGH', 'NO', 'Although the guiding agent selects layers, the Source and Assembly agents directly emit transformed code; direct program transformation is the central contribution.']],
  ['N15', ['SELECTOR', 'S4_Agent_Tool_Action_Selection', 'HIGH', 'NO', 'The LLM emits source-positioned compiler hint combinations; GCC performs the actual optimization, so hints are compiler-action choices.']],
  ['39', ['SUPPORTING', 'B6_Survey_Evaluation_Methodology', 'HIGH', 'NO', 'The LLM predicts whether a pre-existing compiler transformation is sound; it is a verifier/judge pipeline, not a Selector, Translator, or Generator.']],
  ['C28', ['TRANSLATOR', 'T3_Translation_CrossLanguage_CrossISA', 'HIGH', 'NO', 'The model emits C-to-TACO candidate programs; grammar search and CBMC validate them, but the LM output is a program representation.']],
  ['08', ['SUPPORTING', 'B3_LLM_RL_Foundation', 'MEDIUM', 'YES', 'The available note explicitly marks its implementation details as inferred from metadata and a related preprint; retain it as a foundation record pending the primary paper.']],
  ['15', ['TRANSLATOR', 'T2_IR_ASM_Optimization_Superoptimization', 'MEDIUM', 'YES', 'The available note states that its method description is based on limited metadata and cross-paper inference; the candidate is direct IR transformation but needs the primary paper.']],
]);
const prior = new Map(rows.map(r => [r.Paper_ID, { primary: r.Primary_Category, secondary: r.Secondary_Category, review: r.Needs_Review }]));
for (const [id, [primary, sub, confidence, review, specific]] of auditChanges) {
  const row = rows.find(x => x.Paper_ID === id); if (!row) throw new Error(`Unknown audited paper ${id}`);
  setFields(row, primary, sub); row.Classification_Confidence = confidence; row.Needs_Review = review;
  row.Classification_Rationale = `${row.Classification_Rationale} Audit evidence: ${specific}`;
}
// Preserve clean code vocabulary and regenerate a rationale for all non-special rows.
for (const row of rows) {
  if (!auditChanges.has(row.Paper_ID)) setFields(row, row.Primary_Category, row.Secondary_Category);
  if (!row.Classification_Confidence) row.Classification_Confidence = 'HIGH';
  if (!row.Needs_Review) row.Needs_Review = 'NO';
}

const headers = ['Paper_ID', 'Year', 'Title', 'Old_Category', 'Primary_Category', 'Secondary_Category', 'Role', 'Method', 'Task', 'Input_Level', 'Output_Level', 'Platform', 'Feedback', 'Verification', 'Benchmark', 'Tool', 'Agentic', 'Priority', 'Classification_Confidence', 'Classification_Rationale', 'Needs_Review'];
const dup = [...new Set(rows.filter((r, i) => rows.findIndex(x => x.Paper_ID === r.Paper_ID) !== i).map(r => r.Paper_ID))];
const invalidPrimary = rows.filter(r => !primaryOrder.includes(r.Primary_Category));
const invalidSecondary = rows.filter(r => !secondary[r.Primary_Category]?.includes(r.Secondary_Category));
const emptyPrimary = rows.filter(r => !r.Primary_Category);
const emptyRationale = rows.filter(r => !r.Classification_Rationale);
const emptyConfidence = rows.filter(r => !r.Classification_Confidence);
const reviewRows = rows.filter(r => r.Needs_Review === 'YES');
const notesRead = rows.filter(r => r._note?.length).length;
const reviewMissingQueue = reviewRows.filter(r => !auditChanges.has(r.Paper_ID));
if (rows.length !== 169 || dup.length || invalidPrimary.length || invalidSecondary.length || emptyPrimary.length || emptyRationale.length || emptyConfidence.length || notesRead !== 169 || reviewMissingQueue.length) {
  throw new Error(`Taxonomy validation failed: total=${rows.length}, duplicate=${dup.length}, invalidP=${invalidPrimary.length}, invalidS=${invalidSecondary.length}, emptyP=${emptyPrimary.length}, rationale=${emptyRationale.length}, confidence=${emptyConfidence.length}, notes=${notesRead}, queue=${reviewMissingQueue.length}`);
}
fs.writeFileSync(csvPath, `${headers.join(',')}\n${rows.map(r => headers.map(h => csv(r[h])).join(',')).join('\n')}\n`, 'utf8');

const primaryCount = count(rows, 'Primary_Category'); const secondaryCount = count(rows, 'Secondary_Category');
let index = '# LLM Compiler 三大类文献索引 v2（审计版）\n\n';
index += '> 一级类仅表达 LM 的最终编译角色；Agent、RL、验证器与平台均为标签。此文件不移动旧目录、PDF 或逐篇阅读笔记。`NEEDS_REVIEW` 仅表示主要论文证据不足，而非没有当前候选分类。\n\n';
index += `- 总条目：**169**；SELECTOR：**${primaryCount.get('SELECTOR')}**；TRANSLATOR：**${primaryCount.get('TRANSLATOR')}**；GENERATOR：**${primaryCount.get('GENERATOR')}**；SUPPORTING：**${primaryCount.get('SUPPORTING')}**。\n- 待人工复核：**${reviewRows.length}**。\n\n`;
for (const primary of primaryOrder) {
  const number = primaryOrder.indexOf(primary) + 1; index += `## ${number}. ${primaryNames[primary]}\n\n`;
  for (const sub of secondary[primary]) {
    const subset = rows.filter(r => r.Primary_Category === primary && r.Secondary_Category === sub);
    index += `### ${sub} — ${secondaryLabels[sub]}\n\n`;
    if (!subset.length) { index += '_无映射论文。_\n\n'; continue; }
    index += '| Paper ID | 年份 | 文献 | 原类别 | Role / Method | Confidence | Rationale |\n|---|---:|---|---|---|---|---|\n';
    for (const r of subset) {
      const link = `[${md(r.Title)}](${encodeURI(r._legacy.note.replaceAll('\\', '/'))})`;
      const tags = `${r.Role}<br>${r.Method}${r.Needs_Review === 'YES' ? '<br>⚠️ NEEDS_REVIEW' : ''}`;
      index += `| ${r.Paper_ID} | ${r.Year} | ${link} | ${md(r.Old_Category)} | ${md(tags)} | ${r.Classification_Confidence} | ${md(r.Classification_Rationale)} |\n`;
    }
    index += '\n';
  }
}
index += '## Review queue\n\n| Paper_ID | Title | Current Primary | Candidate Alternative | Ambiguity | Evidence Needed | Recommendation |\n|---|---|---|---|---|---|---|\n';
const reviewInfo = {
  '08': ['SUPPORTING', 'SELECTOR / TRANSLATOR', '现有笔记明确说明方法细节为基于相关预印本的推断。', '正式论文 PDF 或 proceedings 版本的任务输出与实验章节。', '保留 B3；获得原文后优先复核。'],
  '15': ['TRANSLATOR', 'GENERATOR', '现有笔记明确标为源材料受限且方法描述基于推测。', '原论文全文，特别是 LLM 最终输出对象与验证闭环。', '暂保留 T2；未获得原文前不得用于定量结论。'],
};
for (const r of reviewRows) { const i = reviewInfo[r.Paper_ID]; index += `| ${r.Paper_ID} | ${md(r.Title)} | ${r.Primary_Category} | ${i[1]} | ${i[2]} | ${i[3]} | ${i[4]} |\n`; }
fs.writeFileSync(mdPath, index, 'utf8');

let queue = '# taxonomy v2 review queue\n\n> 本队列仅收录经过复读后仍缺少足够一手证据的条目；所有条目已有唯一的暂定 Primary 分类。\n\n';
queue += '| Paper_ID | Title | Current Primary | Candidate Alternative | Ambiguity | Evidence Needed | Recommendation |\n|---|---|---|---|---|---|---|\n';
for (const r of reviewRows) { const i = reviewInfo[r.Paper_ID]; queue += `| ${r.Paper_ID} | ${md(r.Title)} | ${r.Primary_Category} | ${i[1]} | ${i[2]} | ${i[3]} | ${i[4]} |\n`; }
queue += '\n## Closed review decisions\n\n本轮已利用现有笔记关闭 13 个上一轮待复核条目：C06、11、42、60、68、69、N05、N06、N15、39、41、C17、C28。关键决策依据已写入 `taxonomy_v2.csv` 的 `Classification_Rationale`。\n';
fs.writeFileSync(queuePath, queue, 'utf8');

const boundaryCases = [
  ['C06', 'SELECTOR / S1', 'LLM produces a pass sequence and LLVM executes the transformations.', 'Not TRANSLATOR: it does not emit optimized IR/source.'],
  ['04', 'SELECTOR / S3', 'RL-trained LM selects LLVM pass policies.', 'Not TRANSLATOR: action space is existing passes.'],
  ['C35', 'SELECTOR / S4', 'Agent uses evidence to choose tuning actions and pass choices.', 'Not TRANSLATOR: LLVM tools perform changes.'],
  ['N15', 'SELECTOR / S4', 'LLM emits source-positioned GCC hint combinations; GCC acts on them.', 'Not GENERATOR: hints are selected for the current input, not a reusable compiler component.'],
  ['42', 'TRANSLATOR / T5', 'LLM iteratively rewrites source code after compiler reports.', 'Not SELECTOR: reports are feedback; final model output is changed source.'],
  ['11', 'TRANSLATOR / T1', 'Source/assembly agents directly emit transformed programs.', 'Not SELECTOR: a guiding layer chooses levels but is not the central output artifact.'],
  ['68', 'TRANSLATOR / T5', 'ErrorSolver emits repaired repository code after diagnostics.', 'Not SELECTOR: tools orchestrate repair but model output is source modification.'],
  ['54', 'TRANSLATOR / T2', 'Neural encoder–decoder maps LLVM IR to optimized LLVM IR.', 'Not SUPPORTING: the model directly outputs a transformed program representation.'],
  ['12', 'TRANSLATOR / T2', 'LLM emits optimized LLVM IR and Alive2 validates it.', 'Not a verification class: Alive2 is a verification tag only.'],
  ['C08', 'TRANSLATOR / T2', 'LLM emits an optimized instruction sequence for each input slice.', 'Not GENERATOR: human review, rather than the LM, generalizes submitted rules.'],
  ['70', 'GENERATOR / G2', 'LLM writes a transformation function reusable across many programs.', 'Not TRANSLATOR: output is a transform program, not one result instance.'],
  ['N06', 'GENERATOR / G2', 'The workflow derives transformation rules and applies them project-wide.', 'Not TRANSLATOR: the final system artifact is a reusable rule.'],
  ['44', 'GENERATOR / G2', 'LLM generalizes peephole examples into reusable rules.', 'Not TRANSLATOR: generalized rule is reused beyond a source instance.'],
  ['C17', 'GENERATOR / G2', 'Workflow produces reusable EqSatL strategy DSL artifacts.', 'Not SELECTOR: its strategy program survives and is reused online.'],
  ['41', 'GENERATOR / G4', 'LLM generates/mutates compiler test programs for differential discovery.', 'Not G2: the generated output is test/fuzz input, not an optimization rule.'],
  ['53', 'GENERATOR / G4', 'Conditioned LM emits compiler-featured OpenCL benchmark programs.', 'Not B1: benchmark programs are generated compiler-facing artifacts.'],
  ['60', 'SUPPORTING / B3', 'Virtual compiler supports retrieval-data synthesis, not validated compilation optimization.', 'Not TRANSLATOR: generated assembly is not the system output evaluated as a compiler transform.'],
  ['39', 'SUPPORTING / B6', 'LLM judges soundness of existing transformations in a validation pipeline.', 'Not SELECTOR/TRANSLATOR/GENERATOR: it emits verdicts and explanations.'],
  ['C28', 'TRANSLATOR / T3', 'LLM emits C-to-TACO candidate programs; search/CBMC validate candidates.', 'Not GENERATOR: candidates are input-instance translations, not reusable transforms.'],
  ['101', 'SUPPORTING / B1', 'TritonBench evaluates external LLM kernel outputs.', 'Not T4: the paper provides the benchmark, not a new kernel-optimizing system.'],
];
let boundary = '# taxonomy v2 boundary cases\n\n> 20 个回归案例。后续新增论文的分类不应与这些“最终输出对象优先”的判据矛盾。\n\n| Paper | Primary | Why | Why not the competing category |\n|---|---|---|---|\n';
for (const [id, category, why, not] of boundaryCases) { const r = rows.find(x => x.Paper_ID === id); boundary += `| ${id} — ${md(r.Title)} | ${category} | ${why} | ${not} |\n`; }
fs.writeFileSync(boundaryPath, boundary, 'utf8');

const migrationRows = rows.map(r => {
  const legacy = r._legacy; const target = targetDirs[r.Secondary_Category];
  const noteName = path.posix.basename(legacy.note); const pdfFolder = legacy.pdf ? path.posix.basename(path.posix.dirname(legacy.pdf)) : '';
  const oldPath = `NOTE:${legacy.note}; PDF:${legacy.pdf}`;
  const proposedPdf = legacy.pdf ? `${target}/${pdfFolder}/paper.pdf` : 'SOURCE_LIMITED_NO_LOCAL_PDF';
  const proposed = `NOTE:文献逐篇阅读/${target}/${noteName}; PDF:${proposedPdf}`;
  return { Paper_ID: r.Paper_ID, Primary: r.Primary_Category, Secondary: r.Secondary_Category, Old_Path: oldPath, Proposed_New_Path: proposed };
});
const migrationHeaders = ['Paper_ID', 'Primary', 'Secondary', 'Old_Path', 'Proposed_New_Path'];
fs.writeFileSync(migrationCsvPath, `${migrationHeaders.join(',')}\n${migrationRows.map(r => migrationHeaders.map(h => csv(r[h])).join(',')).join('\n')}\n`, 'utf8');
let plan = '# taxonomy v2 directory migration plan\n\n> **Planning only — no files have been moved.** The map preserves legacy paper-folder names beneath the new secondary-category folders, preventing the existing `paper.pdf` basename from becoming a flat-directory collision.\n\n## Proposed target tree\n\n```text\n01_LLM_as_Selector/\n  01_Pass_Phase_Flag_Selection/\n  02_Schedule_Config_Autotuning/\n  03_Search_RL_Policy/\n  04_Agent_Tool_Action_Selection/\n02_LLM_as_Translator/\n  01_Source_Optimization_Refactoring/\n  02_IR_ASM_Optimization_Superoptimization/\n  03_Translation_CrossLanguage_CrossISA/\n  04_GPU_Kernel_Accelerator_Optimization/\n  05_Repair_Compiler_Feedback/\n  06_Decompilation_LowLevel_Recovery/\n03_LLM_as_Generator/\n  01_Compiler_Pass_Generation/\n  02_Optimization_Rule_Transform_Generation/\n  03_Backend_Compiler_Component_Generation/\n  04_Tool_Test_Fuzz_Generation/\n90_Supporting/\n  01_Benchmark_Dataset/\n  02_Compiler_Infrastructure/\n  03_LLM_RL_Foundation/\n  04_Traditional_ML_Compiler_Optimization/\n  05_Hardware_ISA_Compiler_Background/\n  06_Survey_Evaluation_Methodology/\n```\n\n';
plan += 'The reading-note tree should mirror this target tree under `文献逐篇阅读/`; the root-level tree would host the PDF paper directories.\n\n';
plan += '## Migration protocol for a later approved phase\n\n1. Freeze the legacy index and record a Git commit.\n2. Create all target directories without deleting legacy paths.\n3. Move each PDF directory and reading note together according to `taxonomy_v2_migration_map.csv`.\n4. Rewrite local links in the legacy and v2 indexes, then update any cross-note references.\n5. Validate every Markdown target and every local PDF link before removing only empty legacy directories.\n6. Commit the migration separately from this taxonomy audit.\n\n';
plan += `## Map summary\n\n- Rows: **${migrationRows.length}** (one per Paper_ID)\n- Canonical map: [taxonomy_v2_migration_map.csv](taxonomy_v2_migration_map.csv)\n- No action from this plan has been executed.\n`;
fs.writeFileSync(migrationPlanPath, plan, 'utf8');

const markdownFiles = readAllMarkdown(root);
const legacyRefFiles = []; let legacyRefs = 0;
for (const file of markdownFiles) {
  const body = fs.readFileSync(file, 'utf8');
  const n = (body.match(/(?:^|[(/<])0[1-6]_[^/\s)>"]+/gm) ?? []).length;
  if (n) { legacyRefFiles.push(path.relative(root, file).replaceAll('\\', '/')); legacyRefs += n; }
}
const pdfGroups = new Map();
const missingPdfIds = [];
for (const r of migrationRows) {
  const pdf = r.Old_Path.match(/PDF:(.+)$/)?.[1] ?? '';
  if (!pdf) { missingPdfIds.push(r.Paper_ID); continue; }
  if (!pdfGroups.has(pdf)) pdfGroups.set(pdf, []);
  pdfGroups.get(pdf).push(r.Paper_ID);
}
const sharedPdfGroups = [...pdfGroups.entries()].filter(([, ids]) => ids.length > 1);
const noteNames = migrationRows.map(r => r.Old_Path.match(/NOTE:([^;]+)/)?.[1] ?? '').map(p => path.posix.basename(p));
const duplicateNoteNames = [...new Set(noteNames.filter((n, i) => noteNames.indexOf(n) !== i))];
const specialPaths = migrationRows.filter(r => /[^\x00-\x7F]|\s|[()]/.test(r.Old_Path)).length;
let impact = '# taxonomy v2 link impact report\n\n> Planning analysis only. No link, PDF, note, or legacy directory has been edited.\n\n';
impact += '## Inventory\n\n';
impact += `- Markdown files scanned: **${markdownFiles.length}**\n- Markdown files containing legacy category-path references: **${legacyRefFiles.length}**\n- Legacy category-path reference occurrences: **${legacyRefs}**\n- Legacy index rows: **${migrationRows.length}**\n- Rows with a local PDF link: **${migrationRows.length - missingPdfIds.length}**\n- Rows without a local PDF link: **${missingPdfIds.length}** (${missingPdfIds.join(', ') || 'none'})\n- Unique referenced PDF paths: **${pdfGroups.size}**\n- Shared PDF reference groups: **${sharedPdfGroups.length}**\n- Duplicate note basenames: **${duplicateNoteNames.length}**\n- Migration rows with Chinese, spaces, or parentheses in legacy artifact paths: **${specialPaths}**\n\n`;
impact += '## Markdown/indexes requiring rewrite in a future move\n\n- `00_分类索引.md` — every local note/PDF link uses the legacy six-category paths.\n- `文献逐篇阅读/00_逐篇阅读目录.md` — mirrors the legacy note and PDF paths.\n- `00_三大类分类索引_v2.md` — links directly to the legacy reading-note paths.\n- Any note named below that contains category-relative references must be rewritten after its source/target path changes.\n\n';
impact += '## Shared PDF references\n\n';
if (sharedPdfGroups.length) { impact += '| Existing PDF path | Paper IDs | Handling |\n|---|---|---|\n'; for (const [p, ids] of sharedPdfGroups) impact += `| ${md(p)} | ${ids.join(', ')} | Keep one physical PDF and retain distinct metadata/notes; do not duplicate blindly. |\n`; }
else impact += '_No shared PDF reference groups._\n';
impact += '\n## Collision and path-safety findings\n\n';
impact += `- Every PDF leaf is named \`paper.pdf\`; a flat migration would therefore collide. The proposed map preserves each current paper-folder basename under its new secondary directory.\n- ${duplicateNoteNames.length ? `Duplicate note basenames require a suffix strategy: ${duplicateNoteNames.join(', ')}.` : 'No duplicate note basenames were detected.'}\n- ${specialPaths} planned paths contain Chinese characters, spaces, or parentheses. Future move scripts must use literal paths, quoted arguments, and Markdown destinations wrapped in angle brackets where necessary.\n- Existing duplicate PDF references (${sharedPdfGroups.length} group(s)) must be handled as version/duplicate metadata relationships rather than independent file moves.\n- The ${missingPdfIds.length} rows without a local PDF link must remain note-only/source-limited until a separate, approved acquisition pass.\n`;
impact += '\n## Affected Markdown files detected\n\n';
for (const file of legacyRefFiles) impact += `- ${file}\n`;
fs.writeFileSync(linkImpactPath, impact, 'utf8');

const oldCategories = [...new Set(rows.map(r => r.Old_Category))];
let report = '# taxonomy v2 validation report (audit edition)\n\n';
report += `- Audit scope: taxonomy reliability, review preparation, and migration planning only.\n- Reading notes consulted: **${notesRead}/169**; focused boundary re-reads: **20**.\n- Legacy content mutation: **none** — no existing PDF, reading note, legacy directory, or \`00_分类索引.md\` changed.\n\n`;
report += '## Final validation\n\n| Check | Result |\n|---|---:|\n';
for (const [label, value] of [
  ['Total papers', rows.length], ['Classified', rows.filter(r => r.Primary_Category).length], ['Unclassified', rows.filter(r => !r.Primary_Category).length],
  ['Duplicate Paper_ID', dup.length], ['Empty Primary_Category', emptyPrimary.length], ['Invalid Primary_Category', invalidPrimary.length],
  ['Invalid Secondary_Category', invalidSecondary.length], ['Empty Classification_Rationale', emptyRationale.length], ['Empty Classification_Confidence', emptyConfidence.length],
  ['Needs_Review', reviewRows.length], ['Migration map rows', migrationRows.length], ['Validation status', 'PASS'],
]) report += `| ${label} | ${value} |\n`;
report += '\n## Primary distribution\n\n| Primary | Count |\n|---|---:|\n'; for (const p of primaryOrder) report += `| ${p} | ${primaryCount.get(p) ?? 0} |\n`;
report += '\n## Secondary distribution\n\n| Primary | Secondary | Count |\n|---|---|---:|\n'; for (const p of primaryOrder) for (const s of secondary[p]) report += `| ${p} | ${s} | ${secondaryCount.get(s) ?? 0} |\n`;
report += '\n## Old category → new category migration matrix\n\n| Old category | SELECTOR | TRANSLATOR | GENERATOR | SUPPORTING | Total |\n|---|---:|---:|---:|---:|---:|\n';
for (const old of oldCategories) { const group = rows.filter(r => r.Old_Category === old); report += `| ${md(old)} | ${group.filter(r => r.Primary_Category === 'SELECTOR').length} | ${group.filter(r => r.Primary_Category === 'TRANSLATOR').length} | ${group.filter(r => r.Primary_Category === 'GENERATOR').length} | ${group.filter(r => r.Primary_Category === 'SUPPORTING').length} | ${group.length} |\n`; }
report += '\n## Audit changes\n\n- Primary-category corrections: **9** (42, 60, 68, 69, N05, N06, C17, 53, 54).\n- Generator-secondary correction: **1** (41: G2 → G4).\n- Previous review entries resolved from notes: **13**.\n- New review entry added because its existing note is explicitly inferential: **08**.\n- Remaining review entries: **2** (08, 15).\n\n';
report += '## Review queue coverage\n\n'; for (const r of reviewRows) report += `- ${r.Paper_ID}: present in [taxonomy_v2_review_queue.md](taxonomy_v2_review_queue.md).\n`;
report += '\n## Generated planning artifacts\n\n- [taxonomy_v2_boundary_cases.md](taxonomy_v2_boundary_cases.md) — 20 taxonomy regression cases.\n- [taxonomy_v2_directory_migration_plan.md](taxonomy_v2_directory_migration_plan.md) — no-op migration protocol.\n- [taxonomy_v2_migration_map.csv](taxonomy_v2_migration_map.csv) — 169 planned paper mappings.\n- [taxonomy_v2_link_impact_report.md](taxonomy_v2_link_impact_report.md) — link/collision risks before any move.\n';
fs.writeFileSync(validationPath, report, 'utf8');

console.log(JSON.stringify({
  total: rows.length, primary: Object.fromEntries(primaryCount), review: reviewRows.map(r => r.Paper_ID),
  primaryChanges: rows.filter(r => prior.get(r.Paper_ID).primary !== r.Primary_Category).map(r => r.Paper_ID),
  secondaryChanged: rows.filter(r => prior.get(r.Paper_ID).secondary !== r.Secondary_Category && !legacySecondaryToCode[prior.get(r.Paper_ID).secondary]).map(r => r.Paper_ID),
  migrationRows: migrationRows.length, markdownFiles: markdownFiles.length, legacyRefFiles: legacyRefFiles.length, legacyRefs, sharedPdfGroups: sharedPdfGroups.length,
}, null, 2));
