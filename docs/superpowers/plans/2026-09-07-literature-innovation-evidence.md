# 文献创新证据层 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从现有 taxonomy v2 和逐篇阅读笔记中建立可追溯的论文级创新证据、问题级局限证据与待人工判断的创新机会观察区。

**Architecture:** `05_创新证据矩阵.md` 是论文级证据入口，逐篇记录可验证事实；`06_局限与反例证据表.md` 按问题聚合并区分事实与推导；`07_创新机会观察区.md` 仅引用达到收录门槛的证据组。以 `taxonomy_v2.csv` 的 Paper ID 为唯一论文标识，所有已有 taxonomy、PDF、笔记和研究方案保持不变。

**Tech Stack:** Markdown、CSV、PowerShell、Python 标准库、现有 `taxonomy_v2.csv` 与 `scripts/validate_taxonomy_v2.py`。

## Global Constraints

- 不修改 `taxonomy_v2.csv`、PDF、逐篇阅读笔记、既有索引或任何研究方案目录。
- 全量入口固定为 169 条 taxonomy v2 记录；详细证据首轮覆盖 25–35 篇高价值论文。
- 论文事实、合理推导与待核验机会必须分栏标明，不能混写。
- 机会记录不得包含研究方案、预实验、最终选题或“主创新”等结论。
- 每个引用的 Paper ID 必须存在于 `taxonomy_v2.csv`；每个机会至少链接至两条独立证据，或一项系统性评测证据。
- Codex 提交信息必须以 `由Codex提交：` 开头。

---

### Task 1: 建立高价值证据样本清单与检查器

**Files:**
- Create: `scripts/validate_innovation_evidence.py`
- Create: `tests/test_innovation_evidence.ps1`
- Create: `05_创新证据矩阵.md`

**Interfaces:**
- Consumes: `taxonomy_v2.csv`（字段：`Paper_ID`、`Primary_Category`、`Priority`、`Proposed_Note_Path`）。
- Produces: `05_创新证据矩阵.md`；其中每个论文块以 `## PAPER-XX` 开头，并含 `证据类型`、`证据位置`、`事实/推导`、`证据强度` 四项。

- [ ] **Step 1: 写出失败的结构检查测试**

创建 `tests/test_innovation_evidence.ps1`，写入以下内容：

```powershell
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
py -3 "$repo/scripts/validate_innovation_evidence.py" --repo "$repo"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

- [ ] **Step 2: 运行测试，确认在产物缺失时失败**

运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：以非零退出，并报告 `05_创新证据矩阵.md` 缺失。

- [ ] **Step 3: 实现只读验证器**

创建 `scripts/validate_innovation_evidence.py`。它必须：

```python
from pathlib import Path
import csv, re, sys

required_files = ["05_创新证据矩阵.md", "06_局限与反例证据表.md", "07_创新机会观察区.md"]
paper_id_pattern = re.compile(r"\bPAPER-([A-Z]?\d{2,3})\b")

def load_ids(repo: Path) -> set[str]:
    with (repo / "taxonomy_v2.csv").open(encoding="utf-8-sig", newline="") as f:
        return {row["Paper_ID"].zfill(2) for row in csv.DictReader(f)}
```

验证器必须检查：三个文件存在；所有 `PAPER-XX` 引用都在 taxonomy 内；`05` 含 25–35 个不同的论文块；`06` 每项至少含一条证据引用；`07` 每个机会含“证据清单”“证据不足处”“待检索关键词”“状态”，并至少有两条不同 Paper ID，或明确标记“系统性评测证据”。失败时逐项输出，成功时输出 `PASS` 和覆盖数。

- [ ] **Step 4: 从 taxonomy 和阅读笔记确定首轮 25–35 篇证据论文**

优先选择 `SELECTOR`、`TRANSLATOR`、`GENERATOR` 中高/中高优先级论文，以及作为基线、验证工具或评测依据的少量 Supporting 文献。每篇先打开 `Proposed_Note_Path`，提取其“研究问题、方法、输入输出、实验、局限”字段；笔记不足时标为“证据不足”，不编造结果。清单需跨越三大核心角色，且明确哪些 Supporting 文献被保留为基线或基础设施。

- [ ] **Step 5: 写入论文级创新证据矩阵**

创建 `05_创新证据矩阵.md`，包括：范围说明、证据强度定义、筛选原则和表格。每行必须有如下列：

```markdown
| Paper ID | 三大类角色 | 已解决的问题 | 最终输出对象 | 反馈/验证 | 强基线与真实Runtime | 明确局限或反例 | 证据位置 | 事实/推导 | 强度 | 可复现性 |
```

“明确局限或反例”必须引用阅读笔记中可定位的章节、表格、结论段或明确说明“笔记未记录”；“事实/推导”首轮论文级记录应以“论文事实”为主。

- [ ] **Step 6: 运行测试，确认结构通过**

运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：输出 `PASS`，并显示 `matrix_papers=25` 至 `35`。

- [ ] **Step 7: 提交第一批论文级证据**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 05_创新证据矩阵.md scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：新增论文级创新证据矩阵"
```

### Task 2: 聚合局限、反例与已有解决路线

**Files:**
- Create: `06_局限与反例证据表.md`
- Modify: `scripts/validate_innovation_evidence.py`
- Test: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: `05_创新证据矩阵.md` 的 Paper ID、局限事实和证据位置。
- Produces: `06_局限与反例证据表.md`；每个问题以 `## LIM-XX` 开头，并包含“定义”“支持证据”“反例/适用边界”“已有解决路线”“事实/推导结论”。

- [ ] **Step 1: 扩展测试，要求每个局限都有可追溯证据**

在 `scripts/validate_innovation_evidence.py` 中加入 `LIM-` 块解析：每个 `## LIM-XX` 块必须含“支持证据”“已有解决路线”“事实/推导结论”，至少引用一个 `PAPER-XX`，且所有引用均存在于 `05` 的论文集合。

- [ ] **Step 2: 运行测试，确认缺少局限表时失败**

临时将 `06_局限与反例证据表.md` 重命名为同目录下 `.bak` 文件，运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：报告缺少局限表。测试后立刻恢复原文件名；不得删除文件。

- [ ] **Step 3: 建立问题级证据表**

创建 `06_局限与反例证据表.md`。只建立由论文事实支撑的局限，例如：

```markdown
## LIM-01：静态代理指标与真实性能的适用边界

### 定义与条件
### 支持证据（论文事实）
### 反例或适用边界（论文事实）
### 已有解决路线
### 事实/推导结论
```

各条目需说明它是“已被系统证实”“多篇论文共同指出”或“证据尚不足”，不得把某一篇论文的通用 Future Work 写成跨领域事实。

- [ ] **Step 4: 运行全量结构校验**

运行：

```powershell
py -3 scripts/validate_taxonomy_v2.py
pwsh -File tests/test_innovation_evidence.ps1
```

预期：第一个命令输出 `PASS` 且 169 条 taxonomy 不变；第二个命令输出 `PASS`。

- [ ] **Step 5: 提交局限证据表**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 06_局限与反例证据表.md scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：新增局限与反例证据表"
```

### Task 3: 建立待人工判断的创新机会观察区

**Files:**
- Create: `07_创新机会观察区.md`
- Modify: `scripts/validate_innovation_evidence.py`
- Test: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: `06_局限与反例证据表.md` 的 `LIM-XX` 证据块。
- Produces: `07_创新机会观察区.md`；每个机会以 `## OPP-XX` 开头，状态仅为 `观察`、`证据补充中` 或 `待人工判断`。

- [ ] **Step 1: 扩展测试，校验机会收录门槛**

在 `scripts/validate_innovation_evidence.py` 中加入 `OPP-` 块检查：每块必须含“已有工作边界”“未解决机制”“证据清单”“证据不足处”“待检索关键词”“状态”；状态需属于允许集合；块中必须引用一个 `LIM-XX` 及至少两个不同 `PAPER-XX`，除非出现字面标记“系统性评测证据”。

- [ ] **Step 2: 运行测试，确认空机会文件失败**

创建一个不含 `## OPP-` 的临时空内容版本，运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：失败并报告未发现机会块。测试完成后恢复受版本控制的实际文件内容。

- [ ] **Step 3: 写入机会观察区**

创建 `07_创新机会观察区.md`。每个 `OPP-XX` 只描述文献证据支持的缺口，模板如下：

```markdown
## OPP-01：机会名称

### 已有工作边界
### 未解决机制
### 近邻工作与重合边界
### 证据清单
### 证据不足处
### 待检索关键词
### 状态
```

机会数控制在 3–6 个，避免把每个局限都升级为机会；不写方案、算法流程、实验设计或贡献声明。

- [ ] **Step 4: 运行最终验证与内容检查**

运行：

```powershell
py -3 scripts/validate_taxonomy_v2.py
pwsh -File tests/test_innovation_evidence.ps1
git diff --check
```

预期：三个命令均成功；taxonomy 保持 169 条；创新证据检查报告 25–35 篇矩阵论文、所有 `LIM-` 和 `OPP-` 块合规。

- [ ] **Step 5: 提交机会观察区与验证器**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 07_创新机会观察区.md scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：新增创新机会观察区"
```

### Task 4: 产出可审阅的覆盖与边界报告

**Files:**
- Modify: `05_创新证据矩阵.md`
- Modify: `06_局限与反例证据表.md`
- Modify: `07_创新机会观察区.md`
- Test: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: 三个证据文件和 `taxonomy_v2.csv`。
- Produces: 每个文件顶部的范围、计数和人工检查说明。

- [ ] **Step 1: 补充统一的审阅信息**

三个文件顶部都需注明：生成日期、来源为 taxonomy v2、覆盖数、未覆盖范围、事实/推导规则与人工复核边界。`05` 明确列出首轮未覆盖的论文属于“未进入高价值证据样本”，不等于其无价值。

- [ ] **Step 2: 运行最终检查**

运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
python scripts/validate_taxonomy_v2.py
git status --short
```

预期：前两项为 `PASS`；状态只列出本任务新增或修改的证据文件、验证器和测试文件。

- [ ] **Step 3: 提交审阅信息**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 05_创新证据矩阵.md 06_局限与反例证据表.md 07_创新机会观察区.md
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：完善创新证据层审阅信息"
```

## Plan Self-Review

- **Spec coverage:** Task 1 implements论文级事实与25–35篇首轮覆盖；Task 2 implements问题级局限、反例和事实/推导区分；Task 3 implements机会阈值和非方案化观察区；Task 4 implements可审阅范围说明。所有任务均不修改 taxonomy、PDF、笔记或研究方案。
- **Placeholder scan:** 本计划不含 TBD、TODO 或“稍后实现”等未定义步骤；所有命令、路径、字段和验收输出均已明确。
- **Consistency:** `PAPER-XX` 由 `taxonomy_v2.csv` 解析验证；`LIM-XX` 由 Task 2 定义并在 Task 3 消费；`OPP-XX` 由 Task 3 定义；同一 `tests/test_innovation_evidence.ps1` 始终调用只读验证器。

## Execution Record

- [x] Task 1：完成 33 篇论文级证据矩阵，并加入只读结构校验。
- [x] Task 2：完成 5 项局限与反例证据聚合。
- [x] Task 3：完成 5 项待人工判断的机会观察记录。
- [x] Task 4：完成范围说明、Paper ID 校验、taxonomy 不变性校验与新增 Markdown 链接校验。

> 环境修正：本机未注册 `python` 命令，实际校验统一使用 Windows Python Launcher：`py -3`。Paper ID 正则已修正为同时支持纯数字、`Cxx` 和 `Nxx` 编号。
