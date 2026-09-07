# Legacy Six-Category Retirement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 无损保留旧六类目录中未迁移的源材料，修复新 taxonomy 的可修复链接，然后删除旧六类物理目录。

**Architecture:** 两份未被 v2 PDF 哈希覆盖的文件进入现有 v2 分类对应条目；旧目录的 `source.txt` 统一进入 `archive/taxonomy_v1/source_records/`，保持原相对目录结构。旧索引继续保留在 archive，v2 目录与索引是唯一活动入口。

**Tech Stack:** PowerShell、Python 标准库、Git、现有 taxonomy v2 校验脚本。

## Global Constraints

- 只处理旧六类物理目录与其空的旧阅读笔记目录；不删除 `archive/taxonomy_v1/` 或 v2 taxonomy 文件。
- 先以 SHA-256 确认未迁移 PDF，并在复制后重算哈希。
- `source.txt` 只归档，不作为新 taxonomy 的 canonical PDF。
- 删除前必须确认旧六类目录内的文件已在 v2 或 archive 中保留。
- 只在 v2 taxonomy 校验、带基线的链接审计和遗留资产哈希校验通过后删除旧目录。旧六类专用 validator 不作为最终验收，因为它要求旧目录仍然存在。

---

### Task 1: 保留遗留材料并修复活动链接

**Files:**
- Create: `archive/taxonomy_v1/legacy_six_category_assets/**` 与 `retirement_manifest.json`
- Create: `scripts/retire_legacy_six_categories.py`
- Modify: `taxonomy_v2_link_validation_report.md`（刷新审计报告）
- Test: `scripts/validate_taxonomy_links.py`、`scripts/validate_taxonomy_v2.py`

- [x] **Step 1: 建立遗留来源归档树**

复制六个旧目录中的全部残留文件到 `archive/taxonomy_v1/legacy_six_category_assets/`，并保留从旧分类目录开始的相对路径。

- [x] **Step 2: 保留两份无哈希匹配 PDF**

两份未匹配 PDF 只作为遗留资产归档，不猜测性并入某个 Paper_ID 或覆盖 canonical `paper.pdf`。

- [x] **Step 3: 修复活动索引的本地链接**

运行链接检查，修复非 archive 范围内指向不存在本地文件的链接；archive 中的 v1 链接仍允许作为历史快照。

- [x] **Step 4: 运行保留性校验**

核验全部旧目录残留文件在归档树中逐文件对应，且可按 SHA-256 找到。

### Task 2: 删除旧目录并验证交付

**Files:**
- Delete: 根目录下旧 `01_编译阶段排序与强化学习调优` 至 `06_多硬件编译_代价模型与IR基础设施`
- Delete: `文献逐篇阅读/` 下对应空旧分类目录
- Modify: 必要的链接影响/残留报告

- [x] **Step 1: 删除旧六类目录**

只在 Task 1 的保留性校验通过后，删除六个旧 PDF/source 目录和六个空旧笔记目录。

- [x] **Step 2: 运行最终校验**

运行：

```powershell
py -3 scripts/validate_taxonomy_v2.py
py -3 scripts/validate_taxonomy_links.py --baseline tmp/taxonomy_v2_link_baseline.json --report taxonomy_v2_link_validation_report.md
py -3 scripts/retire_legacy_six_categories.py --repo . --retire
pwsh -File tests/test_innovation_evidence.ps1
git diff --check
```

预期：taxonomy 仍覆盖 169 条，所有 non-archive 本地链接有效，旧目录不存在，旧源材料可在 archive 找到。

- [x] **Step 3: 提交并推送**

```powershell
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" add -A
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" commit -m "由Codex提交：文献：归档旧六类目录并完成三大类收口"
git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" push
```
