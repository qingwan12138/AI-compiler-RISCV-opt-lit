# 编译器文献语料库增量维护工作流 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为文献语料库增加可审计候选缓存、PDF 预检和增量报告，减少重复工作且不改变现有入库验收标准。

**Architecture:** 新模块 `scripts/maintain_literature_candidates.ps1` 只处理 JSONL 缓存、元数据键和临时 PDF 预检；`scripts/validate_literature_corpus.ps1` 保持不变并继续承担最终语料库验收。Pester 测试在独立 fixture 中覆盖只读报告、三重去重和 PDF/HTML 判别。

**Tech Stack:** PowerShell 7、Pester 5、JSONL、既有 Poppler `pdfinfo.exe`。

## Global Constraints

- Markdown 三索引、PDF 和阅读笔记是唯一语料库事实源。
- `Report` 与 `ProbePdf` 不得修改工作区中的语料库文件。
- `RecordCandidate` 只能追加 `文献逐篇阅读/候选处理缓存.jsonl`。
- 禁止在缓存中保存账号、Cookie、令牌或密码。
- 提交前必须运行 Pester 测试和既有 `scripts/validate_literature_corpus.ps1`。
- Git 提交信息必须以 `由Codex提交：` 开头。

---

### Task 1: 缓存模型与纯函数

**Files:**

- Create: `scripts/maintain_literature_candidates.ps1`
- Create: `tests/maintain_literature_candidates.Tests.ps1`

**Interfaces:**

- Consumes: 题名、DOI、arXiv ID、年份和状态。
- Produces: `Normalize-LiteratureTitle([string]) -> [string]`、`Get-CandidateKey([hashtable]) -> [string[]]`、`Test-CandidateRecord([hashtable]) -> [string[]]`。

- [ ] **Step 1: 写失败测试，覆盖题名、DOI、arXiv 三重键和字段拒绝**

```powershell
Describe 'candidate keys' {
  It 'normalizes punctuation and case in titles' {
    Normalize-LiteratureTitle 'Guided: Tensor-Lifting!' | Should -Be 'guided tensor lifting'
  }
  It 'returns DOI and arXiv keys when present' {
    Get-CandidateKey @{ doi='10.1/X'; arxiv_id='2504.19705'; title='X' } | Should -Contain 'doi:10.1/x'
  }
}
```

- [ ] **Step 2: 运行测试并确认失败**

运行：`pwsh -NoProfile -Command "Invoke-Pester tests/maintain_literature_candidates.Tests.ps1 -Output Detailed"`

预期：失败，提示 `Normalize-LiteratureTitle` 尚未定义。

- [ ] **Step 3: 实现纯函数和允许状态集合**

实现状态枚举 `metadata_verified`、`duplicate`、`year_mismatch`、`download_failed`、`pdf_invalid`、`needs_user_session_download`；要求 `run_id`、`checked_at`、`title`、`normalized_title`、`status`，并拒绝键名含 `cookie`、`token`、`password` 的记录。

- [ ] **Step 4: 重新运行测试并确认通过**

运行相同 Pester 命令；预期全部通过。

### Task 2: JSONL 记录与增量报告

**Files:**

- Modify: `scripts/maintain_literature_candidates.ps1`
- Modify: `tests/maintain_literature_candidates.Tests.ps1`
- Create: `tests/fixtures/literature-candidates/cache.jsonl`

**Interfaces:**

- Consumes: `-Mode RecordCandidate -CachePath <path>` 或 `-Mode Report -Root <path> -CachePath <path>`。
- Produces: 追加的一行压缩 JSON，或包含 `existing_index_match`、`cached_failure`、`retryable` 和 `invalid_cache_lines` 的对象。

- [ ] **Step 1: 写失败测试，覆盖追加与只读报告**

```powershell
It 'appends exactly one valid JSONL record' {
  & $script -Mode RecordCandidate -CachePath $cache -RunId test -Title 'A' -Status metadata_verified
  (Get-Content $cache).Count | Should -Be 1
}
It 'does not change the cache in Report mode' {
  $before = Get-FileHash $cache
  & $script -Mode Report -Root $fixtureRoot -CachePath $cache | Out-Null
  (Get-FileHash $cache).Hash | Should -Be $before.Hash
}
```

- [ ] **Step 2: 运行测试并确认失败**

运行：`pwsh -NoProfile -Command "Invoke-Pester tests/maintain_literature_candidates.Tests.ps1 -Output Detailed"`

预期：失败，提示参数集或模式未实现。

- [ ] **Step 3: 实现 JSONL 安全读取、追加与报告**

`RecordCandidate` 使用 `Add-Content` 追加单行 UTF-8 JSON；`Report` 从两个索引与年份清单提取题名/DOI/arXiv 文本，基于三重键分类缓存记录。损坏 JSON 行报告行号，不改写缓存。

- [ ] **Step 4: 运行测试并确认通过**

运行相同 Pester 命令；预期全部通过。

### Task 3: PDF 临时预检

**Files:**

- Modify: `scripts/maintain_literature_candidates.ps1`
- Modify: `tests/maintain_literature_candidates.Tests.ps1`
- Create: `tests/fixtures/literature-candidates/fake.html`
- Create: `tests/fixtures/literature-candidates/minimal.pdf`

**Interfaces:**

- Consumes: `-Mode ProbePdf -PdfUrl <https-url>` 或 `-PdfPath <local-file>`。
- Produces: `[pscustomobject]`，字段为 `IsPdf`、`Pages`、`FailureKind`、`FinalUrl`，临时文件在函数退出时删除。

- [ ] **Step 1: 写失败测试，拒绝 HTML 并接受最小 PDF**

```powershell
It 'rejects HTML before corpus write' {
  (Test-PdfCandidate -PdfPath $html).IsPdf | Should -BeFalse
}
It 'accepts a parseable PDF' {
  (Test-PdfCandidate -PdfPath $pdf).Pages | Should -BeGreaterThan 0
}
```

- [ ] **Step 2: 运行测试并确认失败**

运行 Pester；预期 `Test-PdfCandidate` 未定义。

- [ ] **Step 3: 实现文件头、Content-Type 和页数检查**

本地路径读取前五字节；URL 使用临时文件下载并记录最终地址和响应 Content-Type；`%PDF-` 或 `pdfinfo` 失败时返回 `html_response`、`invalid_signature`、`unparseable_pdf` 或 `network_error`。

- [ ] **Step 4: 运行测试并确认通过**

运行 Pester；预期全部通过。

### Task 4: 文档、回归与提交

**Files:**

- Modify: `skills/maintaining-compiler-literature-corpus/SKILL.md`
- Modify: `skills/maintaining-compiler-literature-corpus/references/corpus-contract.md`
- Modify: `文献逐篇阅读/2024-2026_文献年份筛选清单.md`

**Interfaces:**

- Consumes: 新脚本的三个模式。
- Produces: 在检索与下载阶段可执行的缓存/预检说明和 C26 的可重试下载记录。

- [ ] **Step 1: 更新 Skill 与合同的流程说明**

在候选核验前增加 `Report`；在直接下载前增加 `ProbePdf`；说明缓存不是最终状态文件，且受限下载记录为 `需要用户会话下载`。

- [ ] **Step 2: 将 C26 失败记录补充为可重试会话下载**

仅更新失败原因，不改变 C26 的未完成状态或索引计数。

- [ ] **Step 3: 运行全量测试与既有验证器**

运行：`pwsh -NoProfile -Command "Invoke-Pester tests/maintain_literature_candidates.Tests.ps1 -Output Detailed"`。

运行：`pwsh -NoProfile -File scripts/validate_literature_corpus.ps1 -Root <仓库绝对路径>`。

预期：Pester 全部通过；验证器退出码 0。

- [ ] **Step 4: 精确暂存并提交**

运行：`git add -- scripts/maintain_literature_candidates.ps1 tests/maintain_literature_candidates.Tests.ps1 tests/fixtures/literature-candidates skills/maintaining-compiler-literature-corpus/SKILL.md skills/maintaining-compiler-literature-corpus/references/corpus-contract.md 文献逐篇阅读/2024-2026_文献年份筛选清单.md docs/superpowers/plans/2026-07-20-literature-corpus-incremental-workflow.md`。

运行：`git commit -m "由Codex提交：优化文献语料库候选缓存与PDF预检"`。

## 计划自检

- 覆盖设计中的缓存、报告、PDF 预检、失败恢复、无凭据存储和最终验证要求。
- 每个代码任务均先写失败 Pester 测试，再实现并验证通过。
- 未引入数据库、自动索引写入或替代现有验证器的第二事实源。
