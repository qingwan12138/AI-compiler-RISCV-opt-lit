# Maintaining Compiler Literature Corpus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建并安装一个个人 Skill，使 Codex 能从研究方向出发完成 2024–2026 文献检索、分类下载、全文阅读和三个清单的一致性维护。

**Architecture:** 新 Skill 只负责编排与语料库状态，复用 `reading-compiler-literature` 生成 14 节笔记。详细分类和索引契约放入单层 reference，只读 PowerShell 脚本负责确定性验证，最后安装到个人 Skills 目录。

**Tech Stack:** Markdown Skill、YAML UI metadata、PowerShell 7、Codex skill-creator scripts。

## Global Constraints

- Skill 名称固定为 `maintaining-compiler-literature-corpus`。
- 个人安装目录固定为 `C:\Users\2025111355\.codex\skills`。
- 只检索首次公开或正式发表年份为 2024–2026 的文献。
- 不围绕预设框架定向搜证；默认保持现有六类主分类。
- 下载失败、正文不可得、重复和年份冲突必须保留原因。
- 三个状态文件必须同批更新并通过只读验证后才能报告完成。

---

### Task 1: RED 基线与脚手架

**Files:**
- Inspect: `文献逐篇阅读/2024-2026_文献年份筛选清单.md`
- Create temporarily: `tmp/skill-build/maintaining-compiler-literature-corpus/`

**Interfaces:**
- Consumes: 当前语料库和已确认设计。
- Produces: 可编辑的官方 Skill 脚手架。

- [ ] **Step 1: 运行无 Skill 基线检查**

从已提交版本读取年份清单中的“尚未纳入本地已读语料库”，同时在工作区确认 C01–C14 的 PDF 与笔记已存在；预期结果是状态矛盾，证明缺少全流程一致性约束。

- [ ] **Step 2: 确认目标 Skill 尚不存在**

运行 `Test-Path C:\Users\2025111355\.codex\skills\maintaining-compiler-literature-corpus`；预期输出 `False`。

- [ ] **Step 3: 读取 UI metadata 规范并初始化**

读取 `skill-creator/references/openai_yaml.md`，运行 `init_skill.py maintaining-compiler-literature-corpus --path tmp/skill-build --resources scripts,references`，传入显示名称、简述和默认提示。

### Task 2: GREEN 编写最小可用 Skill

**Files:**
- Modify: `tmp/skill-build/maintaining-compiler-literature-corpus/SKILL.md`
- Create: `tmp/skill-build/maintaining-compiler-literature-corpus/references/corpus-contract.md`
- Modify: `tmp/skill-build/maintaining-compiler-literature-corpus/agents/openai.yaml`

**Interfaces:**
- Consumes: 研究方向、语料库根目录、现有三个清单。
- Produces: 九阶段编排流程、六类分类/关键词/状态/索引合同。

- [ ] **Step 1: 写触发描述和核心流程**

描述只说明使用场景；正文规定清点、关键词矩阵、联网检索、元数据核验、候选记录、下载验证、调用逐篇阅读、三清单同步和最终验证。

- [ ] **Step 2: 写语料库合同**

定义六类主分类、关键词五维矩阵、一手来源优先级、去重键、目录与文件命名、候选字段、状态机、优先级、索引行和失败状态。

- [ ] **Step 3: 检查无重复阅读规则**

确认 Skill 只声明 `REQUIRED SUB-SKILL: reading-compiler-literature`，不复制 14 节模板。

### Task 3: RED/GREEN 实现只读验证器

**Files:**
- Create: `tmp/skill-build/maintaining-compiler-literature-corpus/scripts/validate_literature_corpus.ps1`
- Create temporarily: `tmp/skill-fixtures/invalid-corpus/`

**Interfaces:**
- Consumes: `-Root <语料库绝对路径>`。
- Produces: 成功时退出码 0 和统计摘要；失败时退出码 1 与逐项错误。

- [ ] **Step 1: 构造失败样例**

创建缺失 PDF 链接、缺少第 14 节笔记、两个索引数量不一致和过期候选状态的最小 fixture。

- [ ] **Step 2: 编写验证器**

验证三个必需 Markdown 文件、两个索引行数/编号集合、分类汇总、本地链接、PDF `%PDF-` 签名和可解析页数、笔记 1–14 节以及过期候选状态。

- [ ] **Step 3: 验证失败样例确实失败**

运行脚本指向 invalid fixture；预期退出码 1，至少报告四类错误。

- [ ] **Step 4: 验证当前真实语料库通过**

运行脚本指向工作区根目录；预期退出码 0，并报告两个索引条目数相同。

### Task 4: 验证、安装和回归检查

**Files:**
- Validate: `tmp/skill-build/maintaining-compiler-literature-corpus/`
- Install: `C:\Users\2025111355\.codex\skills\maintaining-compiler-literature-corpus/`

**Interfaces:**
- Consumes: 已通过本地测试的 Skill 构建目录。
- Produces: Codex 可发现的个人 Skill。

- [ ] **Step 1: 运行官方验证器**

运行 `quick_validate.py`；预期 YAML、目录名和必需文件全部通过。

- [ ] **Step 2: 扫描占位符和路径泄漏**

搜索 `TODO|TBD|PLACEHOLDER`；预期无结果。除默认安装位置和示例根目录外，不写死当前单批 C01–C14。

- [ ] **Step 3: 安装个人 Skill**

将构建目录复制到个人 Skills 目录；不覆盖其他个人 Skills。

- [ ] **Step 4: 对安装副本重新验证**

对安装目录运行 `quick_validate.py`，再从安装副本运行语料库验证器；两者均应退出 0。

- [ ] **Step 5: 清理本任务临时构建与 fixture**

只删除已确认位于工作区 `tmp/skill-build` 和 `tmp/skill-fixtures` 的本任务目录，不触碰原有 `tmp` 其他内容。
