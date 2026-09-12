# Corpus Skills Taxonomy v2 Adaptation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将三个编译器文献 skill、机器可读 taxonomy 总账和验证工具统一切换到仓库当前的 Taxonomy v2 结构，并同步已安装副本后推送 GitHub。

**Architecture:** 仓库 `skills/` 是三个 skill 的唯一版本化源，`taxonomy_v2.csv` 是当前分类和路径总账，两个 Markdown 索引与年份清单是人类可读状态。先以失败合同测试锁定旧六类和迁移字段问题，再依次精简 taxonomy、适配维护/阅读/创新 skill，最后同步到本机 Codex skills 目录并完成全仓验证。

**Tech Stack:** Python 3 标准库、PowerShell、Markdown、CSV、Git、Codex skill validator。

## Global Constraints

- 保持 `taxonomy_v2.csv` 的 169 个唯一 Paper ID、当前主分类、二级分类和路径值不变。
- 不修改论文 PDF、逐篇阅读笔记正文、当前索引条目内容或研究框架结论。
- `00_分类索引.md` 只作旧结构兼容入口，不参与新增论文事务或完成判定。
- 三个 skill 逐一执行 RED、GREEN、回归验证；前一个通过后才修改下一个。
- 仓库副本验证通过后才同步到 `C:\Users\2025111355\.codex\skills\`。
- 本地安装同步只覆盖三个明确的 skill 目录。
- 所有 Git 提交信息以 `由Codex提交：` 开头。
- 所有修改在本地完成并通过验证后才推送；不强推、不重写用户提交。

---

## File Map

**Create:**

- `tests/test_corpus_skill_contracts.py`：三个 skill 和 taxonomy 当前合同测试。
- `archive/taxonomy_v2_迁移过程/taxonomy_v2_with_migration_fields_2026-09-12.csv`：精简前审计快照。
- `skills/reading-compiler-literature/{SKILL.md,references/requirements.md,agents/openai.yaml}`。
- `skills/developing-compiler-innovations/{SKILL.md,references/requirements.md,agents/openai.yaml}`。

**Modify:**

- `taxonomy_v2.csv`：移除迁移字段，将 Proposed 路径改为当前路径字段。
- `scripts/validate_taxonomy_v2.py`：只验证当前 schema 和当前路径。
- `scripts/validate_innovation_evidence.py`：读取 `Note_Path`。
- `scripts/maintain_literature_candidates.ps1`：从当前分类索引、逐篇目录和 taxonomy 查重。
- `docs/taxonomy/taxonomy_v2_rules.md`：记录当前总账字段和新增条目流程。
- `skills/maintaining-compiler-literature-corpus/**`：切换到 Taxonomy v2 合同。

---

### Task 1: 建立当前合同的失败测试

**Files:**
- Create: `tests/test_corpus_skill_contracts.py`
- Read: `taxonomy_v2.csv`
- Read: `skills/maintaining-compiler-literature-corpus/**`
- Read: 两个已安装 skill 目录

**Interfaces:**
- Consumes: 已批准的适配设计。
- Produces: `TaxonomyContractTests`、`MaintainingSkillContractTests`、`ReadingSkillContractTests`、`InnovationSkillContractTests`。

- [ ] **Step 1: 编写 taxonomy schema 测试**

使用 `unittest` 和 `csv.DictReader` 断言 schema 含 `PDF_Path`、`Note_Path`，不含三个 `Old_*` 与两个 `Proposed_*` 字段，并断言 169 行、169 个唯一 ID。

- [ ] **Step 2: 运行 taxonomy 测试并确认失败**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.TaxonomyContractTests -v
```

Expected: FAIL，原因是 CSV 仍含迁移字段且缺少当前路径字段。

- [ ] **Step 3: 编写维护 skill 测试**

断言入口、合同、候选脚本和校验器包含 `taxonomy_v2.csv`、`00_三大类分类索引_v2.md` 与四个主类；活动合同不得把旧六类或 `00_分类索引.md` 当作当前入口。

- [ ] **Step 4: 运行维护 skill 测试并确认失败**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.MaintainingSkillContractTests -v
```

Expected: FAIL，指出旧六类、旧索引或缺少当前总账合同。

- [ ] **Step 5: 编写阅读和创新 skill 测试**

阅读测试要求仓库 skill 声明 Paper ID、主/二级分类、镜像笔记路径和总账写入边界。创新测试要求三个核心角色、Supporting 支撑定位、横向标签和唯一主线，且不得要求旧六类输出。

- [ ] **Step 6: 运行两个测试并确认失败**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.ReadingSkillContractTests tests.test_corpus_skill_contracts.InnovationSkillContractTests -v
```

Expected: FAIL，原因包括仓库 skill 缺失及旧六类创新合同。

---

### Task 2: 精简 taxonomy 当前总账

**Files:**
- Create: `archive/taxonomy_v2_迁移过程/taxonomy_v2_with_migration_fields_2026-09-12.csv`
- Modify: `taxonomy_v2.csv`
- Modify: `scripts/validate_taxonomy_v2.py`
- Modify: `scripts/validate_innovation_evidence.py`
- Modify: `docs/taxonomy/taxonomy_v2_rules.md`
- Test: `tests/test_corpus_skill_contracts.py`

**Interfaces:**
- Consumes: 原 CSV 的 25 列和 169 行。
- Produces: 22 列当前 schema；路径字段为 `PDF_Path`、`Note_Path`。

- [ ] **Step 1: 保存迁移字段归档快照**

复制原始 CSV 到归档目标并比较 SHA-256，确保快照与精简前文件完全一致。

- [ ] **Step 2: 机械转换 CSV schema**

输出字段依次为：

```text
Paper_ID,Year,Title,Primary_Category,Secondary_Category,Role,Method,Task,
Input_Level,Output_Level,Platform,Feedback,Verification,Benchmark,Tool,
Agentic,Priority,Classification_Confidence,Classification_Rationale,
Needs_Review,PDF_Path,Note_Path
```

`PDF_Path` 取原 `Proposed_PDF_Path`，`Note_Path` 取原 `Proposed_Note_Path`。转换前后比较 `(Paper_ID, Primary_Category, Secondary_Category, PDF path, Note path)` 元组，必须完全一致。

- [ ] **Step 3: 更新 taxonomy 验证器**

更新 `REQUIRED`，删除 `--pre-migration` 和条件选列逻辑，始终验证当前路径；保留主/二级兼容性、行数、唯一 ID、置信度和路径存在性检查。

- [ ] **Step 4: 更新消费者和分类规则**

把活动代码中的 `Proposed_Note_Path` 改为 `Note_Path`；在分类规则中明确 CSV 是当前总账，新增论文写入当前路径字段，迁移历史从归档读取。

- [ ] **Step 5: 运行 taxonomy 合同和验证**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.TaxonomyContractTests -v
py -3 scripts/validate_taxonomy_v2.py
py -3 scripts/validate_innovation_evidence.py
```

Expected: 全部 PASS；taxonomy 为 169 行，创新证据维持既有计数。

- [ ] **Step 6: 精准提交**

提交信息：`由Codex提交：重构：精简Taxonomy v2当前总账`。

---

### Task 3: 适配语料库维护 skill

**Files:**
- Modify: `skills/maintaining-compiler-literature-corpus/SKILL.md`
- Modify: `skills/maintaining-compiler-literature-corpus/references/corpus-contract.md`
- Modify: `skills/maintaining-compiler-literature-corpus/scripts/validate_literature_corpus.ps1`
- Modify: `skills/maintaining-compiler-literature-corpus/agents/openai.yaml`
- Modify: `scripts/maintain_literature_candidates.ps1`
- Test: `tests/test_corpus_skill_contracts.py`

**Interfaces:**
- Consumes: 当前 taxonomy schema、分类规则、年份清单和候选缓存。
- Produces: 从候选发现到四状态文件同步的 Taxonomy v2 入库事务。

- [ ] **Step 1: 更新维护入口**

将重建现状、分类下载、同步入库和完成报告切换为四主类与受控二级类。事务同步 taxonomy CSV、当前分类索引、逐篇目录和年份清单；旧索引不进入完成条件。

- [ ] **Step 2: 重写 corpus contract**

合同覆盖四主类目录映射、主类选择、二级词表、当前 CSV 字段、Paper ID/路径、候选状态机、四状态文件一致性和 Git 交付；分类语义引用 `docs/taxonomy/taxonomy_v2_rules.md`。

- [ ] **Step 3: 更新候选去重**

`Get-CorpusCandidateKeys` 从当前分类索引、逐篇目录和 taxonomy CSV 提取 DOI、arXiv ID 与规范化题名，不再读取旧索引。

- [ ] **Step 4: 更新语料库校验器**

要求 taxonomy CSV、当前分类索引、逐篇目录和年份清单；比较三者 ID；验证 `PDF_Path`、`Note_Path`、目录兼容性、13 节笔记、PDF 签名和可选页数。删除旧六类标题计数逻辑。

- [ ] **Step 5: 更新 UI 元数据**

`short_description` 和 `default_prompt` 明确 Taxonomy v2 总账与当前索引同步。

- [ ] **Step 6: 运行目标测试和回归**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.MaintainingSkillContractTests -v
powershell -ExecutionPolicy Bypass -File tests/maintain_literature_candidates.Tests.ps1
powershell -ExecutionPolicy Bypass -File scripts/validate_literature_corpus.ps1 -Root (Get-Location).Path -SkipPdfInfo
```

Expected: 全部 PASS，且无旧索引依赖。

- [ ] **Step 7: 快速校验并提交**

运行 skill quick validator；提交信息：`由Codex提交：功能：适配Taxonomy v2语料库维护技能`。

---

### Task 4: 将逐篇阅读 skill 纳入仓库并适配

**Files:**
- Create: `skills/reading-compiler-literature/SKILL.md`
- Create: `skills/reading-compiler-literature/references/requirements.md`
- Create: `skills/reading-compiler-literature/agents/openai.yaml`
- Test: `tests/test_corpus_skill_contracts.py`

**Interfaces:**
- Consumes: Paper ID、PDF、可选 taxonomy 记录及正文证据。
- Produces: 位于主类/二级类镜像目录的 13 节中文笔记，以及维护 skill 可消费的完成/失败结果。

- [ ] **Step 1: 复制已安装 skill 作为基线**

把三个明确文件复制到仓库目录并比较 SHA-256；不复制缓存或无关文件。

- [ ] **Step 2: 更新 SKILL 入口**

增加 Taxonomy v2 输入、已有分类优先、未入账论文只输出分类建议、镜像笔记路径和总账所有权边界；保留正文阅读、13 节笔记与证据纪律。

- [ ] **Step 3: 更新阅读要求**

保留 13 节、事实/分析分离、数字证据、缺失信息用语和自检；仓库集成时使用 `文献逐篇阅读/00_逐篇阅读目录.md`，正式入库由维护 skill 统一更新 taxonomy 与索引。

- [ ] **Step 4: 更新 UI 元数据**

说明 skill 输出 Taxonomy v2 路径下的笔记，不宣称负责整个入库事务。

- [ ] **Step 5: 测试、快速校验并提交**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.ReadingSkillContractTests -v
```

Expected: PASS。运行 quick validator 后，以 `由Codex提交：功能：适配Taxonomy v2逐篇阅读技能` 提交。

---

### Task 5: 将创新分析 skill 纳入仓库并适配

**Files:**
- Create: `skills/developing-compiler-innovations/SKILL.md`
- Create: `skills/developing-compiler-innovations/references/requirements.md`
- Create: `skills/developing-compiler-innovations/agents/openai.yaml`
- Test: `tests/test_corpus_skill_contracts.py`

**Interfaces:**
- Consumes: taxonomy Paper ID、`Note_Path`、三核心角色证据和 Supporting 证据。
- Produces: 角色内候选、跨角色碰撞、唯一主创新、支撑模块、实验和可证伪条件。

- [ ] **Step 1: 复制已安装 skill 作为基线**

复制三个明确文件并校验 SHA-256，不携带其他本地数据。

- [ ] **Step 2: 更新 SKILL 入口**

把固定六类流程替换为 Selector、Translator、Generator 分组分析；Supporting 作为基线和约束；硬件、IR、验证、反馈、RL、Agent 作为横向标签。保留证据分层、近邻检索、机制增量、实验和唯一主线选择。

- [ ] **Step 3: 重构 requirements**

合同改为证据输入、三角色分析模板、Supporting 规则、横向标签矩阵、候选评分、近邻碰撞、最小 Demo、正式实验、可证伪门控、输出格式和自检；移除旧六类计数和六份固定产物。

- [ ] **Step 4: 更新 UI 元数据**

描述改为从 Taxonomy v2 三角色证据推导创新，不再出现“六类文献”。

- [ ] **Step 5: 测试、快速校验并提交**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts.InnovationSkillContractTests -v
```

Expected: PASS。运行 quick validator 后，以 `由Codex提交：功能：适配Taxonomy v2创新分析技能` 提交。

---

### Task 6: 全仓回归并同步本地安装副本

**Files:**
- Read: 三个仓库 skill 目录
- Replace exact targets: `C:\Users\2025111355\.codex\skills\<三个skill>\**`

**Interfaces:**
- Consumes: 三个已验证仓库 skill。
- Produces: 与仓库逐文件一致的三个已安装 skill。

- [ ] **Step 1: 运行全部验证**

```powershell
py -3 -m unittest tests.test_corpus_skill_contracts -v
py -3 scripts/validate_taxonomy_v2.py
py -3 scripts/validate_taxonomy_links.py
powershell -ExecutionPolicy Bypass -File tests/maintain_literature_candidates.Tests.ps1
powershell -ExecutionPolicy Bypass -File tests/test_innovation_evidence.ps1
powershell -ExecutionPolicy Bypass -File scripts/validate_literature_corpus.ps1 -Root (Get-Location).Path -SkipPdfInfo
git diff --check
```

Expected: 所有命令退出码为 0。

- [ ] **Step 2: 校验三个 skill 包**

使用 `skill-creator/scripts/quick_validate.py` 逐一校验；发现错误时修复并重跑目标测试和全仓相关验证。

- [ ] **Step 3: 请求授权并同步安装目录**

使用明确绝对源、目标目录，只替换三个 skill 内的已知文件，不操作 `.codex/skills` 根目录或其他 skill。

- [ ] **Step 4: 比较仓库与安装副本**

分别生成相对路径、文件大小和 SHA-256 清单；三个目录的 `Compare-Object` 必须无输出。

- [ ] **Step 5: 检查 Git 工作区**

确认没有未提交的计划内修改，所有实现提交均以 `由Codex提交：` 开头。

---

### Task 7: 远端同步与推送

**Files:**
- Push: 本地 `main` 的设计、计划和实现提交。

**Interfaces:**
- Consumes: Task 6 的全绿验证和已同步安装副本。
- Produces: `origin/main` 上完整可复现的适配结果。

- [ ] **Step 1: 获取远端并检查分叉**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" fetch origin
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" rev-list --left-right --count origin/main...main
```

Expected: 远端不领先；若远端领先或分叉，停止，不 rebase、不强推。

- [ ] **Step 2: 推送 main**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" push origin main
```

- [ ] **Step 3: 核对最终状态**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" rev-parse HEAD
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" rev-parse origin/main
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" status --short --branch
```

Expected: 哈希相同，ahead/behind 为 0，工作区干净。
