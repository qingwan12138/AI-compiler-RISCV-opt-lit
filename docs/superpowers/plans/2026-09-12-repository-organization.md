# 文献语料库仓库整理实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将仓库整理为文献语料库主入口，并把每个研究框架的全部材料集中到 `研究框架/<框架名>/`。

**Architecture:** 正式 PDF、三大类目录和逐篇阅读笔记保持原位；框架材料通过 Git 可追踪移动集中管理；当前 taxonomy 数据、规则和历史报告按“根入口、文档、归档”分层；所有路径变更通过仓库级链接检查和内容哈希检查验证。

**Tech Stack:** Git、PowerShell、Python 3、Markdown、现有 taxonomy/语料库验证脚本。

## Global Constraints

- 不删除或改写论文 PDF、逐篇阅读笔记和研究内容。
- `taxonomy_v2.csv` 的 169 个唯一 Paper ID 及分类值不变。
- `01_LLM_as_Selector/`、`02_LLM_as_Translator/`、`03_LLM_as_Generator/`、`90_Supporting/` 与 `文献逐篇阅读/` 不移动。
- 所有 Git 提交以 `由Codex提交：` 开头。
- `archive/.local/` 不得被 Git 跟踪。
- 任何目标路径冲突、PDF/笔记哈希变化或正式索引链接失败都停止提交。

---

### Task 1: 冻结迁移前基线

**Files:**
- Read: `taxonomy_v2.csv`
- Read: `00_三大类分类索引_v2.md`
- Read: `01_LLM_as_Selector/**/paper.pdf`
- Read: `02_LLM_as_Translator/**/paper.pdf`
- Read: `03_LLM_as_Generator/**/paper.pdf`
- Read: `90_Supporting/**/paper.pdf`
- Read: `文献逐篇阅读/**/*.md`

**Interfaces:**
- Consumes: 当前干净的 `main` 与 `origin/main`。
- Produces: 迁移前 Paper ID、PDF、笔记和内容哈希基线，供 Task 6 比较。

- [ ] **Step 1: 检查 Git 状态和远端基线**

Run:

```powershell
git status --short
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
```

Expected: 工作区干净、分支为 `main`、本地与远端哈希一致。

- [ ] **Step 2: 统计 taxonomy Paper ID**

Run:

```powershell
$rows = Import-Csv -LiteralPath 'taxonomy_v2.csv'
$ids = $rows.Paper_ID
[pscustomobject]@{
  Rows = $rows.Count
  UniquePaperIds = ($ids | Sort-Object -Unique).Count
  EmptyPrimary = ($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.Primary_Category) }).Count
}
```

Expected: `Rows=169`、`UniquePaperIds=169`、`EmptyPrimary=0`。

- [ ] **Step 3: 获取 PDF 与笔记内容哈希集合**

Run:

```powershell
$pdfRoots = '01_LLM_as_Selector','02_LLM_as_Translator','03_LLM_as_Generator','90_Supporting'
$pdfs = $pdfRoots | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter '*.pdf' }
$notes = Get-ChildItem -LiteralPath '文献逐篇阅读' -Recurse -File -Filter '*.md'
$pdfHashes = $pdfs | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash | Sort-Object
$noteHashes = $notes | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash | Sort-Object
[pscustomobject]@{PdfCount=$pdfs.Count; PdfUniqueHashes=($pdfHashes|Select-Object -Unique).Count; NoteCount=$notes.Count; NoteUniqueHashes=($noteHashes|Select-Object -Unique).Count}
```

Expected: 得到非零、可在 Task 6 原样重算的四个计数；Shell 会话中保留 `$pdfHashes` 和 `$noteHashes`。

---

### Task 2: 分层整理 taxonomy 与仓库说明文件

**Files:**
- Create: `docs/taxonomy/`
- Create: `docs/文献维护/`
- Create: `archive/taxonomy_v2_迁移过程/`
- Create: `archive/语料库下载历史/`
- Move: 根目录 taxonomy 过程文件
- Move: `文献阅读要求.md`
- Move: `download_manifest*.json`

**Interfaces:**
- Consumes: Task 1 的基线。
- Produces: 根目录只保留当前人工索引和 `taxonomy_v2.csv`，规则与历史材料各归其位。

- [ ] **Step 1: 创建目标目录并逐项检查无冲突**

Run:

```powershell
$targets = 'docs/taxonomy','docs/文献维护','archive/taxonomy_v2_迁移过程','archive/语料库下载历史'
$targets | ForEach-Object { if (-not (Test-Path -LiteralPath $_)) { New-Item -ItemType Directory -Path $_ | Out-Null } }
```

Expected: 四个目标目录存在。

- [ ] **Step 2: 使用 `git mv` 移动当前规则和阅读规范**

Run:

```powershell
git mv taxonomy_v2_rules.md docs/taxonomy/taxonomy_v2_rules.md
git mv 文献阅读要求.md docs/文献维护/文献阅读要求.md
```

Expected: 两个文件显示为 Git rename。

- [ ] **Step 3: 归档 taxonomy 迁移过程文件**

逐项运行 `git mv <源文件> archive/taxonomy_v2_迁移过程/<同名文件>`，源文件集合严格为设计规格第 4.3 节列出的 13 个文件。

Expected: 根目录不再出现 `taxonomy_v2_*report*`、迁移映射、预检、复核队列和边界案例文件；`taxonomy_v2.csv` 保持原位。

- [ ] **Step 4: 归档历史下载清单**

Run:

```powershell
git mv download_manifest.json archive/语料库下载历史/download_manifest.json
git mv download_manifest.pre_classification.json archive/语料库下载历史/download_manifest.pre_classification.json
```

Expected: 两份清单作为 rename 进入归档。

---

### Task 3: 迁移已有独立框架

**Files:**
- Create: `研究框架/`
- Move: 7 个现有独立框架目录
- Flatten: `FAME-Opt_完整研究方案/FAME-Opt_完整研究方案/`

**Interfaces:**
- Consumes: 设计规格第 5.1 与 5.2 节路径映射。
- Produces: 8 个一框架一目录的目标。

- [ ] **Step 1: 创建并验证框架根目录**

Run:

```powershell
if (-not (Test-Path -LiteralPath '研究框架')) { New-Item -ItemType Directory -Path '研究框架' | Out-Null }
```

Expected: `研究框架/` 存在且目标框架名均未被占用。

- [ ] **Step 2: 使用 `git mv` 迁移 7 个独立框架**

按设计规格第 5.1 节表格逐项执行 `git mv`，每次移动前检查目标不存在。

Expected: Translator、MAPO-Pass、EPAS、CABLE、FACT、可执行证据契约、硬件效应反馈各自只有一个顶层目录。

- [ ] **Step 3: 展平 FAME-Opt**

Run:

```powershell
git mv 'FAME-Opt_完整研究方案/FAME-Opt_完整研究方案' '研究框架/FAME-Opt'
```

确认外层目录无剩余跟踪文件后再移除空目录。

Expected: `研究框架/FAME-Opt/00_项目导航与阅读顺序.md` 存在，不再有双层同名嵌套。

---

### Task 4: 拆分候选框架并集中通用证据

**Files:**
- Create: `研究框架/00_通用证据与框架筛选/`
- Create: `研究框架/可验证结构化编辑框架/`
- Create: `研究框架/信息价值反馈门控框架/`
- Create: `研究框架/失败边界记忆框架/`
- Move: `09_LLM_AI编译器低开销创新框架/` 内的材料
- Move: 根目录创新证据文件
- Move: `07_六类论文创新点提炼/` 与 `08_六类论文创新点提炼/`

**Interfaces:**
- Consumes: 旧低开销框架集合和跨框架证据。
- Produces: 三个独立框架及一个通用比较/证据目录。

- [ ] **Step 1: 创建目标目录且确认无同名冲突**

建立设计规格第 5.3、5.4 节中的全部目标目录。

Expected: 所有目标为空，不覆盖现有材料。

- [ ] **Step 2: 分别迁移三个候选框架**

将旧 `09_LLM_AI编译器低开销创新框架/` 中：

- `01_可验证结构化编辑驱动的LLM编译优化器/` 移入 `研究框架/可验证结构化编辑框架/`；
- `02_信息价值门控的自适应反馈LLM智能体/` 移入 `研究框架/信息价值反馈门控框架/`；
- `03_失败边界记忆驱动的反重复LLM编译优化器/` 移入 `研究框架/失败边界记忆框架/`。

Expected: 三个框架材料不再共享一个包装目录。

- [ ] **Step 3: 迁移低开销框架共同材料**

旧目录剩余的总览、证据矩阵、同步改写规格、实施计划和完成报告移入 `研究框架/00_通用证据与框架筛选/低开销三框架比较/`。

Expected: 旧 `09_LLM_AI编译器低开销创新框架/` 无剩余跟踪文件。

- [ ] **Step 4: 集中根目录证据文件**

使用 `git mv` 将 `05_创新证据矩阵.md`、`06_局限与反例证据表.md`、`07_创新机会观察区.md`、`08_近邻工作与创新边界表.md`、`09_机制增量与可做性门控.md`、`文献创新点思考要求.md` 移入 `研究框架/00_通用证据与框架筛选/`。

Expected: 根目录不再有散落研究框架证据文件。

- [ ] **Step 5: 保留历史六类分析的两个版本**

Run:

```powershell
git mv '07_六类论文创新点提炼' '研究框架/00_通用证据与框架筛选/历史六类创新分析/v1'
git mv '08_六类论文创新点提炼' '研究框架/00_通用证据与框架筛选/历史六类创新分析/v2'
```

Expected: 两个版本均存在，内容不合并、不删除。

---

### Task 5: 建立导航并处理本地临时归档

**Files:**
- Rename: `README.txt` -> `README.md`
- Create/Modify: `研究框架/*/README.md`
- Modify: `.gitignore`
- Move ignored local files: `tmp/` -> `archive/.local/tmp_2026-09-12/`
- Archive selected taxonomy tools: `archive/taxonomy_v2_迁移过程/工具与证据/`

**Interfaces:**
- Consumes: Task 2–4 的最终目录。
- Produces: 可从根目录和每个框架 README 导航的仓库。

- [ ] **Step 1: 重命名根 README 并改写导航**

先执行 `git mv README.txt README.md`，再使用补丁将 README 改为四个入口：文献索引、逐篇笔记、研究框架、维护与归档。

Expected: GitHub 默认展示 `README.md`，所有入口均为相对链接。

- [ ] **Step 2: 为每个框架建立或修复 README**

逐目录检查。已有 README 保留内容并更新导航；缺失 README 时新增仅包含状态、研究问题、阅读顺序、证据、方法、实验和历史版本入口的文件。

Expected: `研究框架/` 下除 `00_通用证据与框架筛选/` 外，每个一级框架目录都有 README；通用证据目录也有说明文件。

- [ ] **Step 3: 保存一次性 taxonomy 工具与证据**

将 `tmp/` 根部的一次性 taxonomy 脚本和两个 JSON 基线移入 `archive/taxonomy_v2_迁移过程/工具与证据/`。这些文件作为新增历史材料接受 Git 跟踪。

Expected: 迁移过程可以审计，Poppler 与渲染缓存未被纳入。

- [ ] **Step 4: 验证递归移动目标后归档其余 tmp**

先将源和目标解析为绝对路径，确认两者均位于仓库根目录下且目标为 `archive/.local/tmp_2026-09-12/`。然后更新 `.gitignore` 增加 `archive/.local/`，最后使用 PowerShell `Move-Item -LiteralPath` 移动剩余内容。

Expected: 原 `tmp/` 不再存在或为空；本地临时材料仍可恢复；`git status --short --ignored` 显示本地归档被忽略。

---

### Task 6: 修复链接并运行完整验证

**Files:**
- Modify: 受路径移动影响的 Markdown 链接
- Modify: `scripts/validate_innovation_evidence.py`
- Read: 所有正式 PDF、笔记、索引和框架 README

**Interfaces:**
- Consumes: Task 1 的哈希基线和 Task 2–5 的最终结构。
- Produces: 链接有效、内容未变的整理结果。

- [ ] **Step 1: 搜索旧路径残留**

使用 `rg -n` 分别搜索所有被迁移的旧目录名和根级文件名。区分：当前可执行链接、历史叙述文本、代码块中的历史命令。

Expected: 当前导航与真实链接不引用旧路径；历史描述保留并标注历史性质。

- [ ] **Step 2: 机械修复相对链接**

使用补丁逐文件更新 Markdown 相对路径，不改写正文结论和实验数据。

Expected: Git diff 中链接修改仅对应目录迁移。

- [ ] **Step 3: 重算 PDF 与笔记哈希**

重复 Task 1 Step 3 的命令，将迁移后排序哈希数组与 `$pdfHashes`、`$noteHashes` 使用 `Compare-Object` 比较。

Expected: 两次比较均无输出；PDF 和笔记数量均与迁移前一致。

- [ ] **Step 4: 先验证创新证据检查器能暴露旧路径**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/test_innovation_evidence.ps1
```

Expected: FAIL，错误指出根目录的 `05_创新证据矩阵.md` 等文件不存在，证明测试覆盖本次路径迁移。

- [ ] **Step 5: 更新创新证据检查器的固定路径**

将 `scripts/validate_innovation_evidence.py` 中五个证据文件路径统一改为：

```text
研究框架/00_通用证据与框架筛选/05_创新证据矩阵.md
研究框架/00_通用证据与框架筛选/06_局限与反例证据表.md
研究框架/00_通用证据与框架筛选/07_创新机会观察区.md
研究框架/00_通用证据与框架筛选/08_近邻工作与创新边界表.md
研究框架/00_通用证据与框架筛选/09_机制增量与可做性门控.md
```

内部字典键改为文件名与相对路径分离：路径用于读取，原文件名用于既有内容检查，防止把路径变化误当成内容合同变化。

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/test_innovation_evidence.ps1
```

Expected: PASS，并报告 `neighbor_audits=5; mechanism_gates=5`。

- [ ] **Step 6: 运行其余现有验证脚本**

Run:

```powershell
py -3 scripts/validate_taxonomy_v2.py
py -3 scripts/validate_taxonomy_links.py
powershell -ExecutionPolicy Bypass -File scripts/validate_literature_corpus.ps1 -Root (Get-Location).Path
```

Expected: 三项均退出码 0；链接检查不得依赖迁移前 broken-link baseline 掩盖新错误。

- [ ] **Step 7: 检查仓库结构和格式**

Run:

```powershell
git diff --check
git status --short
git status --short --ignored -- archive/.local
```

Expected: 无格式错误；改动仅为计划内移动、README、链接和归档；本地临时归档只显示 ignored。

---

### Task 7: 提交、同步与推送

**Files:**
- Stage: 仅本次整理涉及的路径

**Interfaces:**
- Consumes: Task 6 全部验证结果。
- Produces: `origin/main` 上可审计的仓库整理提交。

- [ ] **Step 1: 精准暂存并复核 diff**

使用 `git -C <仓库绝对路径> add` 精准暂存 README、研究框架、docs、archive、`.gitignore` 和被修复链接的文件；不暂存 `archive/.local/`。

Expected: `git diff --cached --stat` 只包含计划内文件。

- [ ] **Step 2: 提交整理结果**

Run:

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：整理：重构文献仓库与研究框架导航"
```

Expected: 提交成功且无未暂存的计划内改动。

- [ ] **Step 3: 再次确认远端未前进**

Run:

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" fetch origin
git rev-list --left-right --count origin/main...main
```

Expected: 本地仅领先本轮提交，远端不领先；若远端领先则停止，不 rebase、不强推。

- [ ] **Step 4: 推送并核对同步状态**

Run:

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" push
git rev-parse HEAD
git rev-parse origin/main
git status --short
```

Expected: 两个哈希一致，工作区干净。
