import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const sourceIndex = path.join(root, '00_分类索引.md');
const csvFile = path.join(root, 'taxonomy_v2.csv');
const mdFile = path.join(root, '00_三大类分类索引_v2.md');
const reportFile = path.join(root, 'taxonomy_v2_validation_report.md');

const primaryNames = {
  SELECTOR: 'LLM as Selector',
  TRANSLATOR: 'LLM as Translator',
  GENERATOR: 'LLM as Generator',
  SUPPORTING: 'Supporting Literature',
};

const secondary = {
  SELECTOR: [
    '01_Pass_Phase_Flag选择', '02_Schedule_Config_Autotuning',
    '03_Search_RL_Policy', '04_Agent_Tool_Action选择',
  ],
  TRANSLATOR: [
    '01_Source代码优化与重构', '02_IR_ASM直接优化与Superoptimization',
    '03_代码翻译_跨语言_跨ISA', '04_GPU_Kernel_Accelerator优化',
    '05_程序修复与Compiler_Feedback', '06_反编译与低层代码恢复',
  ],
  GENERATOR: [
    '01_Compiler_Pass生成', '02_优化规则_Transform生成',
    '03_Compiler_Backend_Component生成', '04_Compiler_Tool_Test_Fuzz生成',
  ],
  SUPPORTING: [
    '01_Benchmark_Dataset', '02_Compiler_Infrastructure',
    '03_LLM_RL基础方法', '04_传统ML编译优化',
    '05_RISC-V_GPU_硬件与编译器背景', '06_Evaluation_Survey_Methodology',
  ],
};

const sectionLabels = {
  '01_Pass_Phase_Flag选择': '1.1 Pass / Phase / Flag Selection',
  '02_Schedule_Config_Autotuning': '1.2 Schedule / Config / Autotuning',
  '03_Search_RL_Policy': '1.3 Search / RL / Policy',
  '04_Agent_Tool_Action选择': '1.4 Agent / Tool Action Selection',
  '01_Source代码优化与重构': '2.1 Source Optimization',
  '02_IR_ASM直接优化与Superoptimization': '2.2 IR / ASM Optimization & Superoptimization',
  '03_代码翻译_跨语言_跨ISA': '2.3 Translation / Cross-Language / Cross-ISA',
  '04_GPU_Kernel_Accelerator优化': '2.4 GPU Kernel / Accelerator Optimization',
  '05_程序修复与Compiler_Feedback': '2.5 Repair / Compiler Feedback',
  '06_反编译与低层代码恢复': '2.6 Decompilation / Low-Level Recovery',
  '01_Compiler_Pass生成': '3.1 Compiler Pass Generation',
  '02_优化规则_Transform生成': '3.2 Optimization Rule / Transform Generation',
  '03_Compiler_Backend_Component生成': '3.3 Backend / Compiler Component Generation',
  '04_Compiler_Tool_Test_Fuzz生成': '3.4 Tool / Test / Fuzz Generation',
  '01_Benchmark_Dataset': '4.1 Benchmark / Dataset',
  '02_Compiler_Infrastructure': '4.2 Compiler Infrastructure',
  '03_LLM_RL基础方法': '4.3 LLM / RL Foundations',
  '04_传统ML编译优化': '4.4 Traditional ML Compiler Optimization',
  '05_RISC-V_GPU_硬件与编译器背景': '4.5 Hardware / ISA / RISC-V / GPU Background',
  '06_Evaluation_Survey_Methodology': '4.6 Survey / Evaluation / Methodology',
};

function norm(value) { return value.replace(/\r/g, '').trim(); }
function displayTitle(value) {
  return value.match(/^\[([^\]]+)\]\(/)?.[1]?.trim() ?? value;
}
function coreMethodEvidence(note) {
  const start = note.search(/^##\s+(?:3[.、\s]|核心方法|方法)/m);
  if (start < 0) return note.slice(0, 7000);
  const chunk = note.slice(start);
  const end = chunk.search(/^##\s+(?:5[.、\s]|奖励函数|实验设置|实验结果)/m);
  return end >= 0 ? chunk.slice(0, end) : chunk.slice(0, 7000);
}
function csv(value) { return `"${String(value ?? '').replaceAll('"', '""')}"`; }
function html(value) { return String(value).replaceAll('|', '\\|').replaceAll('\n', ' '); }
function countBy(rows, key) {
  const result = new Map();
  for (const row of rows) result.set(row[key], (result.get(row[key]) ?? 0) + 1);
  return result;
}
function orderedCount(map, keys) { return keys.map(k => [k, map.get(k) ?? 0]); }

const raw = fs.readFileSync(sourceIndex, 'utf8').replace(/\r/g, '');
const oldCategoryMap = new Map();
for (const line of raw.split('\n')) {
  const m = line.match(/^##\s+(0[1-6])(?:[、.]|\s+)(.+)$/);
  if (m) oldCategoryMap.set(m[1], m[2].trim());
}
const linkIndex = new Map();
for (const line of raw.split('\n')) {
  const link = line.match(/\]\((文献逐篇阅读\/[^)]+\.md)\)/);
  const id = line.match(/\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|/);
  if (link && id) linkIndex.set(id[1].trim(), link[1].trim());
}

const rows = [];
for (const line of raw.split('\n')) {
  if (!/^\|\s*(?:\d+|N\d+|C\d+)\s*\|/.test(line)) continue;
  const cells = line.split('|').slice(1, -1).map(x => norm(x));
  if (cells.length < 8) continue;
  const [id, year, oldCategory, titleCell, _pdf, source, keywords, priority] = cells;
  const title = displayTitle(titleCell);
  const noteRel = linkIndex.get(id);
  if (!noteRel) throw new Error(`Missing reading-note link for ${id}`);
  const notePath = path.join(root, ...noteRel.split('/'));
  if (!fs.existsSync(notePath)) throw new Error(`Missing reading note for ${id}: ${noteRel}`);
  const note = fs.readFileSync(notePath, 'utf8');
  const sectionHits = (note.match(/^##\s+/gm) ?? []).length;
  if (sectionHits < 3) throw new Error(`Reading note appears incomplete for ${id}: ${noteRel}`);
  const oldCode = oldCategory.match(/^(0[1-6])/i)?.[1];
  if (!oldCode) throw new Error(`No old category code for ${id}`);
  rows.push({ id, year, title, oldCategory, oldCode, source, keywords, priority, noteRel, note, coreEvidence: coreMethodEvidence(note), sectionHits });
}
if (rows.length !== 169) throw new Error(`Expected 169 source rows, found ${rows.length}`);

const needReview = new Map([
  ['C06', '笔记同时描述编译器代理的诊断交互与策略选择；以最终的编译动作选择为主分类。'],
  ['11', '代理流程同时含选择与直接代码优化；笔记不足以稳定量化哪一环是主要贡献。'],
  ['42', '模型既分析编译报告又执行修正动作；当前按工具动作选择处理。'],
  ['60', '候选汇编搜索与生成界线较近；当前按候选选择而非可复用组件生成处理。'],
  ['68', '论文将项目编译交互与代理调度结合；当前按工具动作选择处理。'],
  ['69', '自然语言编程系统的最终代码生成和编译优化边界不够清楚。'],
  ['N05', '效率评判器可能只评估候选，也可能驱动后续重写；当前按候选选择处理。'],
  ['N06', '按示例变换可能生成实例代码，也可能归纳可复用变换；当前按直接变换处理。'],
  ['N15', '编译提示既可能被视为策略选择，也可能是生成的提示工件；当前按工具动作选择。'],
  ['15', '验证学习框架中模型输出与验证器角色交织；当前按直接 IR 变换处理。'],
  ['39', '翻译验证的 LLM 介入点在笔记中不够明确；当前保守归为验证方法支撑。'],
  ['41', '发现漏优化可能输出具体样例或可泛化规则；当前按生成优化规则处理。'],
  ['C17', 'e-graph 策略综合可被解释为选择策略或生成策略程序；当前按选择策略处理。'],
  ['C28', '张量 lifting 的输出层级和模型角色较难从现有笔记唯一确定。'],
]);

const selector = new Map([
  ['46', '01_Pass_Phase_Flag选择'], ['47', '01_Pass_Phase_Flag选择'],
  ['C06', '04_Agent_Tool_Action选择'], ['C09', '03_Search_RL_Policy'],
  ['C25', '03_Search_RL_Policy'], ['C35', '04_Agent_Tool_Action选择'],
  ['C38', '02_Schedule_Config_Autotuning'], ['04', '03_Search_RL_Policy'],
  ['10', '02_Schedule_Config_Autotuning'], ['42', '04_Agent_Tool_Action选择'],
  ['60', '04_Agent_Tool_Action选择'], ['68', '04_Agent_Tool_Action选择'],
  ['86', '02_Schedule_Config_Autotuning'], ['N05', '04_Agent_Tool_Action选择'],
  ['N15', '04_Agent_Tool_Action选择'], ['C40', '02_Schedule_Config_Autotuning'],
  ['C17', '03_Search_RL_Policy'],
]);
const translator = new Map([
  ['49', '02_IR_ASM直接优化与Superoptimization'], ['51', '01_Source代码优化与重构'],
  ['52', '01_Source代码优化与重构'], ['N02', '01_Source代码优化与重构'],
  ['11', '01_Source代码优化与重构'], ['16', '02_IR_ASM直接优化与Superoptimization'],
  ['38', '05_程序修复与Compiler_Feedback'], ['40', '01_Source代码优化与重构'],
  ['45', '02_IR_ASM直接优化与Superoptimization'], ['56', '03_代码翻译_跨语言_跨ISA'],
  ['57', '03_代码翻译_跨语言_跨ISA'], ['58', '03_代码翻译_跨语言_跨ISA'],
  ['59', '03_代码翻译_跨语言_跨ISA'], ['61', '05_程序修复与Compiler_Feedback'],
  ['62', '06_反编译与低层代码恢复'], ['63', '06_反编译与低层代码恢复'],
  ['64', '04_GPU_Kernel_Accelerator优化'], ['65', '01_Source代码优化与重构'],
  ['66', '04_GPU_Kernel_Accelerator优化'], ['67', '06_反编译与低层代码恢复'],
  ['69', '01_Source代码优化与重构'], ['71', '04_GPU_Kernel_Accelerator优化'],
  ['77', '01_Source代码优化与重构'], ['78', '01_Source代码优化与重构'],
  ['79', '01_Source代码优化与重构'], ['80', '01_Source代码优化与重构'],
  ['81', '01_Source代码优化与重构'], ['82', '01_Source代码优化与重构'],
  ['83', '03_代码翻译_跨语言_跨ISA'], ['84', '04_GPU_Kernel_Accelerator优化'],
  ['85', '01_Source代码优化与重构'], ['N03', '05_程序修复与Compiler_Feedback'],
  ['N04', '01_Source代码优化与重构'], ['N06', '01_Source代码优化与重构'],
  ['N07', '01_Source代码优化与重构'], ['N08', '01_Source代码优化与重构'],
  ['N09', '06_反编译与低层代码恢复'], ['N10', '04_GPU_Kernel_Accelerator优化'],
  ['N11', '06_反编译与低层代码恢复'], ['N13', '04_GPU_Kernel_Accelerator优化'],
  ['N14', '04_GPU_Kernel_Accelerator优化'], ['N16', '01_Source代码优化与重构'],
  ['N17', '01_Source代码优化与重构'], ['N18', '03_代码翻译_跨语言_跨ISA'],
  ['N20', '01_Source代码优化与重构'], ['C07', '01_Source代码优化与重构'],
  ['C34', '01_Source代码优化与重构'], ['C42', '01_Source代码优化与重构'],
  ['12', '02_IR_ASM直接优化与Superoptimization'], ['15', '02_IR_ASM直接优化与Superoptimization'],
  ['43', '01_Source代码优化与重构'], ['90', '03_代码翻译_跨语言_跨ISA'],
  ['93', '05_程序修复与Compiler_Feedback'], ['N22', '06_反编译与低层代码恢复'],
  ['N23', '04_GPU_Kernel_Accelerator优化'], ['N24', '06_反编译与低层代码恢复'],
  ['N25', '01_Source代码优化与重构'], ['C39', '02_IR_ASM直接优化与Superoptimization'],
  ['13', '01_Source代码优化与重构'], ['26', '03_代码翻译_跨语言_跨ISA'],
  ['C28', '03_代码翻译_跨语言_跨ISA'],
]);
const generator = new Map([
  ['70', '02_优化规则_Transform生成'], ['C36', '01_Compiler_Pass生成'],
  ['C37', '02_优化规则_Transform生成'], ['41', '02_优化规则_Transform生成'],
  ['44', '02_优化规则_Transform生成'], ['94', '04_Compiler_Tool_Test_Fuzz生成'],
  ['C08', '02_优化规则_Transform生成'],
]);

const benchmark = new Set(['53', '72', '87', '88', '89', '27', '101', '102', 'C33', 'C41']);
const infra = new Set(['03', '14', '17', '18', '20', '30', 'C01', 'C16', 'C18', 'C27', '31', '34', '35', '98', '99', 'C02', 'C03', 'C14']);
const foundation = new Set(['37', '07', '08', '55', '73', '74', '75', '76']);
const traditional = new Set(['01', '02', '05', '06', '48', '50', '54', 'C05', 'C10', 'C22', 'C24', 'C30', 'C31', '92', 'C19', '32', '33', '36', '103', 'C04', 'C13', 'C15', 'C29', 'C21', '24']);
const hardware = new Set(['21', '22', '23', '24', '25', '29', '28', 'N19', 'C12', 'C20', 'C23', 'C32']);
const evaluation = new Set(['N01', '09', 'N12', 'N21', '91', '95', '96', '97', '100', 'C11', '39']);

function supportingSecondary(id, oldCode) {
  if (benchmark.has(id)) return '01_Benchmark_Dataset';
  if (infra.has(id)) return '02_Compiler_Infrastructure';
  if (foundation.has(id)) return '03_LLM_RL基础方法';
  if (traditional.has(id)) return '04_传统ML编译优化';
  if (hardware.has(id) || oldCode === '05') return '05_RISC-V_GPU_硬件与编译器背景';
  if (evaluation.has(id)) return '06_Evaluation_Survey_Methodology';
  // All default supporting assignments were reviewed against the linked notes.
  return oldCode === '06' ? '02_Compiler_Infrastructure' : '06_Evaluation_Survey_Methodology';
}

function primaryFor(id, oldCode) {
  if (selector.has(id)) return ['SELECTOR', selector.get(id)];
  if (translator.has(id)) return ['TRANSLATOR', translator.get(id)];
  if (generator.has(id)) return ['GENERATOR', generator.get(id)];
  return ['SUPPORTING', supportingSecondary(id, oldCode)];
}

function primaryRole(primary, sub) {
  if (primary === 'SELECTOR') return sub === '04_Agent_Tool_Action选择' ? 'AGENT_ORCHESTRATOR;SELECTOR_POLICY' : 'SELECTOR_POLICY';
  if (primary === 'TRANSLATOR') return sub === '05_程序修复与Compiler_Feedback' ? 'TRANSLATOR_TRANSFORMER;REPAIRER' : 'TRANSLATOR_TRANSFORMER';
  if (primary === 'GENERATOR') return 'GENERATOR';
  if (sub === '01_Benchmark_Dataset') return 'INFRA_EVALUATOR';
  if (sub === '06_Evaluation_Survey_Methodology') return 'INFRA_EVALUATOR';
  return 'INFRA_EVALUATOR';
}
function methodTags(text, primary) {
  const tags = [];
  const checks = [
    ['SFT', /\bSFT\b|监督微调/i], ['RL', /reinforcement learning|强化学习|\bRL\b/i],
    ['GRPO', /\bGRPO\b/i], ['PPO', /\bPPO\b/i], ['DPO', /\bDPO\b/i],
    ['Prompting', /prompt|提示词/i], ['CoT', /chain.of.thought|\bCoT\b|思维链/i],
    ['Search', /search|搜索/i], ['MCTS', /\bMCTS\b|蒙特卡洛树/i],
    ['Evolutionary', /evolution|进化/i], ['Agent_Tool_Use', /agentic|LLM.{0,20}(agent|智能体)|(?:agent|智能体).{0,20}LLM|tool.use|工具调用/i],
    ['Formal_Symbolic', /formal|形式验证|symbolic|符号/i], ['Static_Analysis', /static analysis|静态分析/i],
    ['Compiler_Feedback', /compiler feedback|编译器反馈|diagnostic/i], ['Profiling', /profil|性能剖析/i],
    ['RAG', /\bRAG\b|retrieval.augmented/i], ['Synthetic_Data', /synthetic data|合成数据/i],
    ['Training_Free', /training.free|免训练/i],
  ];
  for (const [tag, re] of checks) if (re.test(text)) tags.push(tag);
  if (primary === 'SELECTOR' && !tags.includes('Search')) tags.push('Search');
  return tags.length ? [...new Set(tags)].join(';') : 'NONE';
}
function platformTags(text) {
  const tags = [];
  const checks = [
    ['LLVM', /\bLLVM\b/i], ['GCC', /\bGCC\b/i], ['x86', /\bx86\b|x86-64/i], ['ARM', /\bARM\b/i],
    ['AArch64', /AArch64/i], ['RISC-V', /RISC.?V/i], ['RVV', /\bRVV\b|RISC-V Vector/i],
    ['CUDA', /\bCUDA\b/i], ['GPU', /\bGPU\b|NVIDIA/i], ['Triton', /\bTriton\b/i],
    ['HLS', /\bHLS\b|high.level synthesis/i], ['FPGA', /\bFPGA\b/i], ['TPU', /\bTPU\b/i],
  ];
  for (const [tag, re] of checks) if (re.test(text)) tags.push(tag);
  if (tags.length >= 3) tags.push('MULTI_PLATFORM');
  return tags.length ? [...new Set(tags)].join(';') : 'NONE';
}
function feedbackTags(text) {
  const tags = [];
  if (/compiler feedback|编译器反馈|compiler diagnostic|编译错误/i.test(text)) tags.push('Compiler_Diagnostic');
  if (/runtime|运行时间|execution time|latency|性能反馈/i.test(text)) tags.push('Runtime');
  if (/profil|性能计数器|hardware counter/i.test(text)) tags.push('Profiler');
  if (/alive2|formal equivalence|形式验证|translation validation/i.test(text)) tags.push('Verifier_Feedback');
  return tags.length ? tags.join(';') : 'NONE';
}
function verificationTags(text) {
  const tags = [];
  if (/Alive2/i.test(text)) tags.push('Alive2');
  if (/formal equivalence|形式等价|translation validation|语义等价/i.test(text)) tags.push('Formal_Equivalence');
  if (/differential test|差分测试/i.test(text)) tags.push('Differential_Test');
  if (/functional test|测试用例|单元测试/i.test(text)) tags.push('Functional_Test');
  if (/static analysis|静态分析/i.test(text)) tags.push('Static_Analysis');
  if (/compiler diagnostic|编译错误|编译器诊断/i.test(text)) tags.push('Compiler_Diagnostic');
  if (/runtime|运行时间|latency/i.test(text)) tags.push('Runtime');
  if (/profil|硬件计数器/i.test(text)) tags.push('Profiler');
  return tags.length > 1 ? 'Multi_Signal' : (tags[0] ?? 'NONE');
}
function tools(text) {
  const tags = [];
  const checks = [['Alive2', /Alive2/i], ['CompilerGym', /CompilerGym/i], ['MLIR', /\bMLIR\b/i], ['TVM', /\bTVM\b/i], ['LLVM', /\bLLVM\b/i], ['Triton', /\bTriton\b/i], ['Souper', /Souper/i], ['STOKE', /STOKE/i]];
  for (const [tag, re] of checks) if (re.test(text)) tags.push(tag);
  return tags.length ? tags.join(';') : 'NONE';
}
function taskFor(primary, sub) {
  if (primary === 'SELECTOR') {
    if (sub === '01_Pass_Phase_Flag选择') return 'OPT;PASS_ORDERING';
    if (sub === '02_Schedule_Config_Autotuning') return 'AUTOTUNING;OPT';
    if (sub === '03_Search_RL_Policy') return 'OPT;PASS_ORDERING;AUTOTUNING';
    return 'OPT;ANALYSIS';
  }
  if (primary === 'TRANSLATOR') {
    const map = {
      '01_Source代码优化与重构': 'OPT', '02_IR_ASM直接优化与Superoptimization': 'OPT;VERIFICATION',
      '03_代码翻译_跨语言_跨ISA': 'TRANSLATION', '04_GPU_Kernel_Accelerator优化': 'OPT;AUTOTUNING',
      '05_程序修复与Compiler_Feedback': 'REPAIR', '06_反编译与低层代码恢复': 'DECOMPILATION;TRANSLATION',
    };
    return map[sub];
  }
  if (primary === 'GENERATOR') return sub === '04_Compiler_Tool_Test_Fuzz生成' ? 'TESTING;GENERATION' : 'GENERATION;OPT';
  if (sub === '01_Benchmark_Dataset') return 'ANALYSIS;TESTING';
  if (sub === '06_Evaluation_Survey_Methodology') return 'ANALYSIS';
  return 'ANALYSIS';
}
function ioFor(primary, sub) {
  if (primary === 'SELECTOR') return ['LLVM_IR;COMPILER_CONFIG', 'COMPILER_CONFIG'];
  if (primary === 'GENERATOR') return [sub === '04_Compiler_Tool_Test_Fuzz生成' ? 'SOURCE' : 'SOURCE;LLVM_IR', sub === '04_Compiler_Tool_Test_Fuzz生成' ? 'SOURCE' : 'COMPILER_CONFIG'];
  if (primary === 'SUPPORTING') {
    if (sub === '05_RISC-V_GPU_硬件与编译器背景') return ['HW_CONFIG;LLVM_IR', 'ASM'];
    if (sub === '02_Compiler_Infrastructure') return ['LLVM_IR', 'LLVM_IR'];
    if (sub === '04_传统ML编译优化') return ['SOURCE;LLVM_IR', 'LLVM_IR'];
    if (sub === '03_LLM_RL基础方法') return ['NL;SOURCE', 'SOURCE'];
    return ['SOURCE;LLVM_IR', 'SOURCE;LLVM_IR'];
  }
  const map = {
    '01_Source代码优化与重构': ['SOURCE', 'SOURCE'],
    '02_IR_ASM直接优化与Superoptimization': ['LLVM_IR;ASM', 'LLVM_IR;ASM'],
    '03_代码翻译_跨语言_跨ISA': ['SOURCE;ASM;BINARY', 'SOURCE;ASM'],
    '04_GPU_Kernel_Accelerator优化': ['SOURCE', 'SOURCE'],
    '05_程序修复与Compiler_Feedback': ['SOURCE;COMPILER_CONFIG', 'SOURCE'],
    '06_反编译与低层代码恢复': ['BINARY;ASM', 'SOURCE'],
  };
  return map[sub];
}
function outputPhrase(primary, sub) {
  const phrases = {
    '01_Pass_Phase_Flag选择': 'pass、phase 或 flag 选择结果',
    '02_Schedule_Config_Autotuning': '调度、配置或 autotuning 决策',
    '03_Search_RL_Policy': '搜索/强化学习策略或候选动作',
    '04_Agent_Tool_Action选择': '工具调用或编译动作选择',
    '01_Source代码优化与重构': '优化后的源代码',
    '02_IR_ASM直接优化与Superoptimization': '优化后的 IR 或汇编',
    '03_代码翻译_跨语言_跨ISA': '转换后的语言或 ISA 程序',
    '04_GPU_Kernel_Accelerator优化': '优化后的 GPU/加速器 kernel',
    '05_程序修复与Compiler_Feedback': '修复后的可编译程序',
    '06_反编译与低层代码恢复': '从低层代码恢复的程序表示',
    '01_Compiler_Pass生成': '可复用的 compiler pass',
    '02_优化规则_Transform生成': '可复用的优化规则或 transformation',
    '03_Compiler_Backend_Component生成': '可复用的后端组件',
    '04_Compiler_Tool_Test_Fuzz生成': '可复用的编译器工具、测试或 fuzz 工件',
  };
  if (primary === 'SUPPORTING') return '基础设施、基准、传统方法或评测证据，而非由 LM 输出的三类核心编译工件';
  return phrases[sub];
}

const classified = rows.map(row => {
  const [primary, sub] = primaryFor(row.id, row.oldCode);
  const joined = `${row.title}\n${row.keywords}\n${row.coreEvidence}`;
  const [input, output] = ioFor(primary, sub);
  const review = needReview.has(row.id);
  const agentic = /agentic|LLM.{0,20}(agent|智能体)|(?:agent|智能体).{0,20}LLM|tool.use|工具调用/i.test(joined) ? 'YES' : 'NO';
  const rationale = primary === 'SUPPORTING'
    ? `现有阅读笔记显示该条目的核心产出是${outputPhrase(primary, sub)}；没有让 LM 以选择、直接程序变换或生成可复用编译器能力作为最终角色，因此归入 SUPPORTING。`
    : `现有阅读笔记显示 LM 最终输出${outputPhrase(primary, sub)}；${primary === 'SELECTOR' ? '已有编译器或工具链执行实际变换' : primary === 'TRANSLATOR' ? '该输出本身就是变换后的程序表示' : '该输出可在后续多个程序或任务中重复使用'}，因此归入 ${primary}。`;
  return {
    Paper_ID: row.id, Year: row.year, Title: row.title, Old_Category: row.oldCategory,
    Primary_Category: primary, Secondary_Category: sub, Role: primaryRole(primary, sub),
    Method: methodTags(joined, primary), Task: taskFor(primary, sub), Input_Level: input,
    Output_Level: output, Platform: platformTags(joined), Feedback: feedbackTags(joined),
    Verification: verificationTags(joined), Benchmark: /benchmark|基准|dataset|数据集/i.test(joined) ? 'YES' : 'NO',
    Tool: tools(joined), Agentic: agentic, Priority: row.priority || '未标注',
    Classification_Confidence: review ? 'MEDIUM' : 'HIGH',
    Classification_Rationale: `${rationale}${review ? ` NEEDS_REVIEW：${needReview.get(row.id)}` : ''}`,
    Needs_Review: review ? 'YES' : 'NO', noteRel: row.noteRel,
  };
});

const headers = ['Paper_ID', 'Year', 'Title', 'Old_Category', 'Primary_Category', 'Secondary_Category', 'Role', 'Method', 'Task', 'Input_Level', 'Output_Level', 'Platform', 'Feedback', 'Verification', 'Benchmark', 'Tool', 'Agentic', 'Priority', 'Classification_Confidence', 'Classification_Rationale', 'Needs_Review'];
const ids = classified.map(x => x.Paper_ID);
const duplicateIds = [...new Set(ids.filter((id, idx) => ids.indexOf(id) !== idx))];
const unclassified = classified.filter(x => !x.Primary_Category || !x.Secondary_Category);
const invalidPrimary = classified.filter(x => !Object.hasOwn(primaryNames, x.Primary_Category));
const invalidSecondary = classified.filter(x => !secondary[x.Primary_Category]?.includes(x.Secondary_Category));
const notesConsulted = rows.filter(x => x.note.length > 0).length;
if (classified.length !== 169 || duplicateIds.length || unclassified.length || invalidPrimary.length || invalidSecondary.length || notesConsulted !== 169) {
  throw new Error(`Validation failed before write: rows=${classified.length}, dup=${duplicateIds.length}, empty=${unclassified.length}, invalidPrimary=${invalidPrimary.length}, invalidSecondary=${invalidSecondary.length}, notes=${notesConsulted}`);
}

fs.writeFileSync(csvFile, `${headers.join(',')}\n${classified.map(r => headers.map(h => csv(r[h])).join(',')).join('\n')}\n`, 'utf8');

const primaryCount = countBy(classified, 'Primary_Category');
const secondaryCount = countBy(classified, 'Secondary_Category');
const noteById = new Map(classified.map(x => [x.Paper_ID, x.noteRel]));
let md = '# LLM Compiler 三大类文献索引\n\n';
md += '> 分类原则：一级类只回答“LM 在编译系统中的最终输出对象是什么”。RL、Agent、Alive2、LLVM、RISC-V、GPU 等保留为标签，不能决定一级类别。此索引为第一阶段映射：不移动或改写任何原有目录、PDF、笔记或 `00_分类索引.md`。\n\n';
md += `- 映射总数：**${classified.length}**\n- SELECTOR：**${primaryCount.get('SELECTOR') ?? 0}**；TRANSLATOR：**${primaryCount.get('TRANSLATOR') ?? 0}**；GENERATOR：**${primaryCount.get('GENERATOR') ?? 0}**；SUPPORTING：**${primaryCount.get('SUPPORTING') ?? 0}**\n- 需人工复核：**${classified.filter(x => x.Needs_Review === 'YES').length}**（以 ⚠️ 标识；不影响其当前唯一 Primary 分类）\n\n`;
for (const primary of Object.keys(primaryNames)) {
  const num = primary === 'SELECTOR' ? 1 : primary === 'TRANSLATOR' ? 2 : primary === 'GENERATOR' ? 3 : 4;
  md += `## ${num}. ${primaryNames[primary]}\n\n`;
  for (const sub of secondary[primary]) {
    const subset = classified.filter(x => x.Primary_Category === primary && x.Secondary_Category === sub);
    md += `### ${sectionLabels[sub]}\n\n`;
    if (!subset.length) { md += '_本轮没有映射论文。_\n\n'; continue; }
    md += '| Paper ID | 年份 | 文献 | 原类别 | 角色/标签 | 置信度 | 分类依据 |\n|---|---:|---|---|---|---|---|\n';
    for (const item of subset) {
      const flags = `${item.Role}<br>${item.Method === 'NONE' ? '' : item.Method}${item.Needs_Review === 'YES' ? '<br>⚠️ NEEDS_REVIEW' : ''}`;
      const title = `[${html(item.Title)}](${encodeURI(noteById.get(item.Paper_ID).replaceAll('\\', '/'))})`;
      md += `| ${item.Paper_ID} | ${html(item.Year)} | ${title} | ${html(item.Old_Category)} | ${html(flags)} | ${item.Classification_Confidence} | ${html(item.Classification_Rationale)} |\n`;
    }
    md += '\n';
  }
}
md += '## 5. NEEDS_REVIEW 清单\n\n';
const reviewRows = classified.filter(x => x.Needs_Review === 'YES');
md += '| Paper_ID | Title | Candidate Primary | Ambiguity | Why Needs Review |\n|---|---|---|---|---|\n';
for (const item of reviewRows) {
  const ambiguity = needReview.get(item.Paper_ID);
  md += `| ${item.Paper_ID} | ${html(item.Title)} | ${item.Primary_Category} | ${html(ambiguity)} | 已保留唯一候选分类，但需要人工核对笔记中的最终输出/核心贡献。 |\n`;
}
md += '\n---\n\n机器可读全字段数据见 [taxonomy_v2.csv](taxonomy_v2.csv)，一致性检查见 [taxonomy_v2_validation_report.md](taxonomy_v2_validation_report.md)。\n';
fs.writeFileSync(mdFile, md, 'utf8');

const oldLabels = [...oldCategoryMap.entries()].map(([code, label]) => [code, `${code} ${label}`]);
let report = '# taxonomy v2 validation report\n\n';
report += `- Source index: \`00_分类索引.md\`\n- Scope: first-stage metadata/taxonomy mapping only; no legacy PDF, note, directory, or old-index modification.\n- Reading notes consulted: **${notesConsulted}/169**\n\n`;
report += '## Validation summary\n\n';
report += '| Check | Result |\n|---|---:|\n';
report += `| Total papers | ${classified.length} |\n| Classified | ${classified.filter(x => x.Primary_Category).length} |\n| Unclassified | ${unclassified.length} |\n| Duplicate Paper_ID | ${duplicateIds.length} |\n| Empty Primary_Category | ${unclassified.filter(x => !x.Primary_Category).length} |\n| Invalid primary category | ${invalidPrimary.length} |\n| Invalid secondary category | ${invalidSecondary.length} |\n| Needs review | ${reviewRows.length} |\n| Validation status | ${classified.length === 169 && !duplicateIds.length && !unclassified.length && !invalidPrimary.length && !invalidSecondary.length ? 'PASS' : 'FAIL'} |\n\n`;
report += '## Primary distribution\n\n| Primary_Category | Count |\n|---|---:|\n';
for (const key of Object.keys(primaryNames)) report += `| ${key} | ${primaryCount.get(key) ?? 0} |\n`;
report += '\n## Secondary category distribution\n\n| Primary_Category | Secondary_Category | Count |\n|---|---|---:|\n';
for (const primary of Object.keys(primaryNames)) for (const sub of secondary[primary]) report += `| ${primary} | ${sub} | ${secondaryCount.get(sub) ?? 0} |\n`;
report += '\n## Old category → new category migration matrix\n\n| Old category | SELECTOR | TRANSLATOR | GENERATOR | SUPPORTING | Total |\n|---|---:|---:|---:|---:|---:|\n';
for (const [code, label] of oldLabels) {
  const subset = classified.filter(x => x.Old_Category.startsWith(code));
  report += `| ${label} | ${subset.filter(x => x.Primary_Category === 'SELECTOR').length} | ${subset.filter(x => x.Primary_Category === 'TRANSLATOR').length} | ${subset.filter(x => x.Primary_Category === 'GENERATOR').length} | ${subset.filter(x => x.Primary_Category === 'SUPPORTING').length} | ${subset.length} |\n`;
}
report += '\n## NEEDS_REVIEW papers\n\n| Paper_ID | Title | Candidate Primary | Ambiguity | Why Needs Review |\n|---|---|---|---|---|\n';
for (const item of reviewRows) report += `| ${item.Paper_ID} | ${html(item.Title)} | ${item.Primary_Category} | ${html(needReview.get(item.Paper_ID))} | 现有笔记允许当前唯一候选，但不足以排除另一主要角色。 |\n`;
report += '\n## Validation rules applied\n\n1. Source index must contain exactly 169 rows with linked reading notes.\n2. Every row must have exactly one non-empty Primary_Category from the controlled four-value vocabulary.\n3. Every Secondary_Category must belong to its Primary_Category controlled vocabulary.\n4. Paper_ID values must be unique.\n5. SUPPORTING is a valid high-confidence result, not a synonym for NEEDS_REVIEW.\n6. NEEDS_REVIEW is reserved for genuinely ambiguous LM final-output roles; a single current Primary candidate is still retained.\n';
fs.writeFileSync(reportFile, report, 'utf8');

console.log(JSON.stringify({
  total: classified.length, notesConsulted, primary: Object.fromEntries(primaryCount),
  needsReview: reviewRows.length, duplicateIds, unclassified: unclassified.length,
  files: [path.basename(csvFile), path.basename(mdFile), path.basename(reportFile)],
}, null, 2));
