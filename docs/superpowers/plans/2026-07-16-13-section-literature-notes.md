# 逐篇文献笔记 13 节格式实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 删除逐篇笔记的最小 Demo，并让笔记、Skill、自动化和验证器统一采用 13 节合同。

**Architecture:** 以索引链接集合为迁移边界，机械删除旧第 12 节并重编号后两节；合同和验证器同时切换，避免新旧格式并存。六类创新分析不在本次迁移范围内。

**Tech Stack:** Markdown、PowerShell、Codex Skills、TOML。

## Global Constraints

- 不改变第 1–11 节论文事实与分析。
- 不删除六类创新分析中的集中式 Demo。
- 验证通过后精准暂存本轮相关文件，以 `由Codex提交：` 开头的中文提交信息推送 `main`。

### Task 1: 建立 13 节失败基线

**Files:**
- Test: `scripts/validate_literature_corpus.ps1`

- [x] 运行验证器并显式传入 `-ExpectedNoteSections 13 -SkipPdfInfo`。
- [x] 确认当前 151 份笔记均因仍为 14 节而失败。

### Task 2: 迁移笔记与当前仓库合同

**Files:**
- Modify: `文献逐篇阅读/**/*.md`
- Modify: `文献阅读要求.md`
- Modify: `文献逐篇阅读/00_逐篇阅读目录.md`
- Modify: `文献逐篇阅读/2024-2026_文献年份筛选清单.md`
- Modify: `skills/maintaining-compiler-literature-corpus/**`
- Modify: `scripts/validate_literature_corpus.ps1`

- [x] 对索引链接到的笔记删除旧第 12 节，原第 13、14 节改为第 12、13 节。
- [x] 将仓库合同、目录说明和验证器默认值改为 13。
- [x] 增加“逐篇不设计 Demo、六类创新阶段集中设计”的边界说明。

### Task 3: 同步个人 Skills 与自动化

**Files:**
- Modify: `C:/Users/2025111355/.codex/skills/reading-compiler-literature/**`
- Modify: `C:/Users/2025111355/.codex/skills/maintaining-compiler-literature-corpus/**`
- Modify: `C:/Users/2025111355/.codex/automations/automation/automation.toml`

- [x] 同步两个个人 Skill 的 SKILL、requirements、合同和验证器。
- [x] 将自动化第 8、10、12 步改为 13 节和摘要式汇报。

### Task 4: 完整验证

**Files:**
- Test: `scripts/validate_literature_corpus.ps1`
- Test: `C:/Users/2025111355/.codex/skills/.system/skill-creator/scripts/quick_validate.py`

- [x] 检查 151 份笔记章节序列及 Demo 一级章节残留。
- [x] 运行完整语料库验证并确认退出码为 0。
- [x] 校验两个个人 Skill，比较仓库与安装副本哈希。
- [x] 审查 Git diff 统计和工作区状态，仅摘要汇报。

### Task 5: GitHub 交付

- [ ] 精准暂存本轮相关文件并以 `由Codex提交：` 开头的中文信息提交。
- [ ] 再次 fetch，确认 `origin/main` 未前进后推送 `main`。
- [ ] 核对本地与远端哈希一致、ahead/behind 为 0。
