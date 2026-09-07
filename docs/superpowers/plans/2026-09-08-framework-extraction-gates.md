# 文献框架提炼门控 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为五项既有文献机会建立近邻碰撞审计与机制增量/可做性门控，使框架候选只能由可追溯文献证据保留。

**Architecture:** `08_近邻工作与创新边界表.md` 记录机会与近邻论文的覆盖差异及碰撞风险；`09_机制增量与可做性门控.md` 记录独立机制的最低判据与公开核验条件；`07_创新机会观察区.md` 只增加指向两张门控表的审计状态。扩展现有只读验证器以校验 ID、链接和状态，不改动 taxonomy 或任何研究方案。

**Tech Stack:** Markdown、Python 标准库、PowerShell、`taxonomy_v2.csv`、既有 `scripts/validate_innovation_evidence.py`。

## Global Constraints

- 审计范围固定为 `OPP-01` 至 `OPP-05`，不新增机会，不提出算法、研究方案、预实验或最终选题。
- 不修改 taxonomy v2、PDF、逐篇笔记、`05/06` 论文事实或既有研究方案目录。
- 每项近邻审计必须有 3–5 篇 `PAPER-` 引用，并标注事实/推断和重合风险。
- 每项机制门控必须明确“退化为的最近工作”、公开核验条件和可证伪指标；“保留观察”不是创新结论。
- `07` 的框架审计状态仅允许：`保留观察`、`证据不足`、`近邻重合高`。
- Codex 提交信息必须以 `由Codex提交：` 开头。

---

### Task 1: 扩展创新证据只读校验器

**Files:**
- Modify: `scripts/validate_innovation_evidence.py`
- Modify: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: `05_创新证据矩阵.md`、`06_局限与反例证据表.md`、`07_创新机会观察区.md`、`taxonomy_v2.csv`。
- Produces: 对 `08_近邻工作与创新边界表.md` 和 `09_机制增量与可做性门控.md` 的结构校验输出。

- [x] **Step 1: 写出失败条件**

在校验器的 `REQUIRED_FILES` 中加入：

```python
"08_近邻工作与创新边界表.md",
"09_机制增量与可做性门控.md",
```

并定义：

```python
NEIGHBOR_RE = re.compile(r"^## OPP-(\d{2,3})[：:].*近邻", re.MULTILINE)
GATE_RE = re.compile(r"^## OPP-(\d{2,3})[：:].*机制", re.MULTILINE)
```

- [x] **Step 2: 运行测试，确认新增文件尚未创建时失败**

运行：

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：非零退出，并报告两个新增 Markdown 文件缺失。

- [x] **Step 3: 实现门控结构校验**

在 `main()` 中加入规则：每个 `OPP-01` 至 `OPP-05` 在 `08` 和 `09` 中各出现一次；`08` 每块包含“近邻论文”“尚未覆盖的条件”“重合风险”“事实/推断”“人工复核重点”，并包含 3–5 个不同 `PAPER-`；`09` 每块包含“共同输入与输出”“最低独立机制判据”“退化为的最近工作”“公开核验条件”“可证伪指标”“门控结果”；`07` 每个 OPP 块包含“框架审计状态”及到 `08`、`09` 的 Markdown 链接。状态只允许三个全局状态。

- [ ] **Step 4: 运行测试，确认校验器仍会因空门控文件失败**

分别以只有标题、不含 `## OPP-` 块的临时内容执行测试，预期报告缺少五个对应 OPP 审计块。完成后恢复文件内容。

- [ ] **Step 5: 提交校验器扩展**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：扩展框架门控校验"
```

### Task 2: 建立近邻工作与创新边界审计表

**Files:**
- Create: `08_近邻工作与创新边界表.md`
- Test: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: 五项 OPP、对应 LIM 和 `05` 的论文级事实。
- Produces: 每项 OPP 的 3–5 篇近邻表、重合风险和人工复核点。

- [x] **Step 1: 为每项机会选择 3–5 篇近邻**

依据任务、最终输出对象、反馈和验证范围，而非标题关键词。每项需至少一篇直接处理相同任务的论文和一篇提供关键反例/基础设施的论文；同一论文可服务多个机会，但每个关系需说明原因。

- [x] **Step 2: 创建近邻审计表**

每个块采用以下固定结构：

```markdown
## OPP-01：……近邻碰撞审计

### 近邻论文
| Paper ID | 已覆盖任务/输出 | 已覆盖反馈与验证 | 仍未覆盖的条件 | 关系性质 |

### 尚未覆盖的条件
### 重合风险
### 事实/推断
### 人工复核重点
```

禁止使用“首次”“空白”“领先”等不可复现判断；高重合风险必须明确写出不能独立主张的内容。

- [x] **Step 3: 运行校验**

```powershell
pwsh -File tests/test_innovation_evidence.ps1
```

预期：通过，且输出 5 个机会的近邻门控计数。

- [ ] **Step 4: 提交近邻审计表**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 08_近邻工作与创新边界表.md scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：新增近邻工作碰撞审计"
```

### Task 3: 建立机制增量与可做性门控，并回写观察状态

**Files:**
- Create: `09_机制增量与可做性门控.md`
- Modify: `07_创新机会观察区.md`
- Test: `tests/test_innovation_evidence.ps1`

**Interfaces:**
- Consumes: `08` 中的碰撞风险与最近工作、`05/06` 中的事实。
- Produces: 五项机会的机制差异门控和 `07` 的审计状态。

- [x] **Step 1: 为每项机会写出最低独立机制判据**

“最低独立机制判据”必须是信息、约束、决策对象或反馈闭环中的一个可识别差异；不得把模型、平台、Agent、RL、Alive2 或更多搜索轮数单独视为差异。

- [x] **Step 2: 创建机制增量与可做性门控**

每个块采用以下固定结构：

```markdown
## OPP-01：……机制增量与可做性门控

### 共同输入与输出
### 最低独立机制判据
### 退化为的最近工作
### 公开核验条件
### 可证伪指标
### 门控结果
```

门控结果仅为 `保留观察`、`证据不足` 或 `近邻重合高`，并在文中解释原因。

- [x] **Step 3: 回写机会观察区**

在 `07_创新机会观察区.md` 的每个 OPP 块末尾添加：

```markdown
### 框架审计状态
`状态`；详见 [近邻碰撞审计](../../../08_近邻工作与创新边界表.md#对应锚点) 与 [机制门控](../../../09_机制增量与可做性门控.md#对应锚点)。
```

- [x] **Step 4: 运行最终验证**

运行：

```powershell
py -3 -m py_compile scripts/validate_innovation_evidence.py
pwsh -File tests/test_innovation_evidence.ps1
py -3 scripts/validate_taxonomy_v2.py
git diff --check
```

预期：全部成功；taxonomy 仍为 169 条；机会、近邻、门控均为 5 项。

- [ ] **Step 5: 提交完整门控层**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add 07_创新机会观察区.md 08_近邻工作与创新边界表.md 09_机制增量与可做性门控.md scripts/validate_innovation_evidence.py tests/test_innovation_evidence.ps1
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：完成框架提炼门控"
```

## Plan Self-Review

- **Spec coverage:** Task 1 adds reference/status validation; Task 2 supplies five 3–5-paper nearest-work audits; Task 3 supplies five mechanism/feasibility gates and writes only audit status to `07`.
- **Placeholder scan:** 所有新文件、块名、状态、命令和字段均已明确；无未定义实现步骤。
- **Consistency:** `OPP-XX` 是三份审计文件的共同键；`PAPER-` 和 `LIM-` 继续由既有验证器校验；`07` 只消费 `08/09` 的最终状态，不重复论文事实。
