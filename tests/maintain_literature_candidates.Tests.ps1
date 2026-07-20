$scriptPath = Join-Path $PSScriptRoot '../scripts/maintain_literature_candidates.ps1'
. $scriptPath

Describe '文献候选缓存基础规则' {
    It '规范化题名以支持跨来源去重' {
        Normalize-LiteratureTitle 'Guided: Tensor-Lifting!' | Should Be 'guided tensor lifting'
    }

    It '同时生成 DOI、arXiv 和规范化题名去重键' {
        $keys = Get-CandidateKey @{ doi = '10.1/X'; arxiv_id = '2504.19705'; title = 'Guided Tensor Lifting' }
        ($keys -contains 'doi:10.1/x') | Should Be $true
        ($keys -contains 'arxiv:2504.19705') | Should Be $true
        ($keys -contains 'title:guided tensor lifting') | Should Be $true
    }

    It '拒绝包含凭据字段的缓存记录' {
        $errors = Test-CandidateRecord @{ run_id = 'test'; checked_at = '2026-07-20T00:00:00Z'; title = 'A'; normalized_title = 'a'; status = 'metadata_verified'; cookie = 'secret' }
        ($errors -contains '缓存记录不得包含敏感凭据字段: cookie') | Should Be $true
    }
}

Describe '文献候选缓存操作' {
    It '只追加一条有效 JSONL 候选记录' {
        $cache = Join-Path $TestDrive 'cache.jsonl'
        & $scriptPath -Mode RecordCandidate -CachePath $cache -RunId 'test-run' -Title 'Guided Tensor Lifting' -Status 'metadata_verified' | Out-Null
        (Get-Content -LiteralPath $cache).Count | Should Be 1
        ((Get-Content -LiteralPath $cache -Raw | ConvertFrom-Json).normalized_title) | Should Be 'guided tensor lifting'
    }

    It '报告模式不修改候选缓存' {
        $cache = Join-Path $TestDrive 'cache.jsonl'
        '{"run_id":"test","checked_at":"2026-07-20T00:00:00Z","title":"Unknown","normalized_title":"unknown","status":"download_failed"}' | Set-Content -LiteralPath $cache -Encoding utf8
        $before = (Get-FileHash -LiteralPath $cache).Hash
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $report = & $scriptPath -Mode Report -Root $repoRoot -CachePath $cache
        (Get-FileHash -LiteralPath $cache).Hash | Should Be $before
        $report.retryable | Should Be 1
    }

    It '不将年份筛选清单中的未完成候选误判为已入库' {
        $cache = Join-Path $TestDrive 'c26.jsonl'
        '{"run_id":"test","checked_at":"2026-07-20T00:00:00Z","title":"Reductive Analysis with Compiler-Guided Large Language Models for Input-Centric Code Optimizations","normalized_title":"reductive analysis with compiler guided large language models for input centric code optimizations","doi":"10.1145/3729282","status":"needs_user_session_download"}' | Set-Content -LiteralPath $cache -Encoding utf8
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $report = & $scriptPath -Mode Report -Root $repoRoot -CachePath $cache
        $report.existing_index_match | Should Be 0
        $report.retryable | Should Be 1
    }
}

Describe 'PDF 预检' {
    It '在写入语料库前拒绝 HTML 响应内容' {
        $html = Join-Path $TestDrive 'login.html'
        '<!doctype html><title>Login</title>' | Set-Content -LiteralPath $html -Encoding utf8
        (Test-PdfCandidate -PdfPath $html).IsPdf | Should Be $false
        (Test-PdfCandidate -PdfPath $html).FailureKind | Should Be 'html_response'
    }

    It '接受现有的可解析论文 PDF 并返回页数' {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $pdf = Join-Path $repoRoot '03_形式验证_超级优化与规则生成/C27-Removing-Undef-PLDI2026/paper.pdf'
        $result = Test-PdfCandidate -PdfPath $pdf
        $result.IsPdf | Should Be $true
        ($result.Pages -gt 0) | Should Be $true
    }

    It '将不可访问的 URL 明确标记为网络错误' {
        $result = Test-PdfCandidate -PdfUrl 'http://127.0.0.1:9/unavailable.pdf'
        $result.IsPdf | Should Be $false
        $result.FailureKind | Should Be 'network_error'
    }
}
