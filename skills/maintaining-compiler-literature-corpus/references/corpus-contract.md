# Taxonomy v2 语料库维护合同

## 1. 文件职责与权威顺序

| 文件 | 用途 | 写入规则 |
|---|---|---|
| `taxonomy_v2.csv` | Paper_ID、主/二级分类、标签、优先级、复核状态、当前 PDF/笔记路径的机器可读总账 | 每篇论文一行；以本文件字段为准 |
| `00_三大类分类索引_v2.md` | 当前角色与二级分类的人类可读索引 | 新论文在对应二级分类表中增加一行 |
| `文献逐篇阅读/00_逐篇阅读目录.md` | 全部笔记的可浏览目录 | 保留历史六类行；新论文追加到 `Taxonomy v2 新增记录` 区，并填写当前主/二级分类 |
| `文献逐篇阅读/2024-2026_文献年份筛选清单.md` | 候选发现、核验、下载、阅读状态及失败原因 | 新候选先登记，再按状态推进 |
| `文献逐篇阅读/候选处理缓存.jsonl` | 可审计的候选处理事件及重试辅助信息 | 仅由 `RecordCandidate` 模式追加，不代替任何索引或总账 |

旧分类索引 `00_分类索引.md` 和迁移字段归档仅供历史审计。它们不用于新增论文的分类、去重或完成判定。

## 2. 主类与二级类

主类依照 [Taxonomy v2 规则](../../../docs/taxonomy/taxonomy_v2_rules.md)：

| Primary_Category | 判定 | PDF 根目录 | 笔记根目录 |
|---|---|---|---|
| `SELECTOR` | 模型输出 pass、phase、flag、schedule、配置、候选、策略或工具动作，现有编译器/工具执行变换 | `01_LLM_as_Selector` | `文献逐篇阅读/01_LLM_as_Selector` |
| `TRANSLATOR` | 模型直接输出变换后的源码、IR、汇编、kernel、修复、翻译或低层恢复结果 | `02_LLM_as_Translator` | `文献逐篇阅读/02_LLM_as_Translator` |
| `GENERATOR` | 模型输出可复用的编译器能力，如 pass、规则、后端组件、工具、测试或 fuzzer | `03_LLM_as_Generator` | `文献逐篇阅读/03_LLM_as_Generator` |
| `SUPPORTING` | 基准、数据集、基础设施、LLM/RL 基础、传统编译器 ML、硬件背景、综述或评测方法 | `90_Supporting` | `文献逐篇阅读/90_Supporting` |

Supporting 是有效主类，不是证据不足时的兜底。Agent、RL、验证工具、LLVM/MLIR、RISC-V/RVV、GPU、多硬件和反馈机制均作为横向标签或证据维度。

二级类使用 `taxonomy_v2.csv` 中与主类兼容的受控值，例如 `S1_Pass_Phase_Flag_Selection`、`T3_Translation_CrossLanguage_CrossISA`、`G2_Optimization_Rule_Transform_Generation`、`B5_Hardware_ISA_Compiler_Background`。新增值先更新并校验受控分类规则，不从论文主题临时造新主类。

## 3. 目录和路径

物理二级目录用两位数字加去掉角色字母的标签名：

```text
SELECTOR / S1_Pass_Phase_Flag_Selection
  -> 01_LLM_as_Selector/01_Pass_Phase_Flag_Selection/
  -> 文献逐篇阅读/01_LLM_as_Selector/01_Pass_Phase_Flag_Selection/
```

统一布局：

```text
<Primary directory>/<Secondary directory>/<Paper-ID>-<slug>-<venue-or-year>/paper.pdf
文献逐篇阅读/<Primary directory>/<Secondary directory>/<Paper-ID>_<note-slug>_文献阅读总结.md
```

路径写入 CSV 时相对仓库根目录、使用 `/` 分隔符。没有本地论文 PDF 的源材料受限记录使用 `SOURCE_LIMITED_NO_LOCAL_PDF`，其 Note_Path 仍指向明确标注材料限制的笔记。

## 4. 当前 CSV 字段

保留以下顺序和字段；迁移专用旧字段只存在归档副本中：

```text
Paper_ID,Year,Title,Primary_Category,Secondary_Category,Role,Method,Task,
Input_Level,Output_Level,Platform,Feedback,Verification,Benchmark,Tool,
Agentic,Priority,Classification_Confidence,Classification_Rationale,
Needs_Review,PDF_Path,Note_Path
```

`taxonomy_v2.csv` 的 `Paper_ID` 必须唯一。`Primary_Category`、`Secondary_Category` 依据论文实际系统输出与方法证据填写；`Classification_Rationale` 记录可核验依据，`Classification_Confidence` 使用 `HIGH`、`MEDIUM` 或 `LOW`，`Needs_Review` 使用 `YES` 或 `NO`。来源受限或主要角色不清楚时降低置信度并标记复核。

## 5. 关键词、检索与候选筛选

将研究方向拆成主题、编译对象、方法、反馈/验证证据、硬件/IR 五组词，再组合英文检索式并加入排除词。当前年份候选以年份筛选清单标题和用户指定范围为准；仓库现行窗口为 2024–2026，若用户给出新范围则按用户范围记录本轮口径。

必须联网核验候选。来源优先正式 proceedings、出版社或会议/期刊主页，再用 arXiv、ACL Anthology、OpenReview、USENIX、作者主页及 DBLP/Crossref 补充。至少核实题名、作者、首次公开年份、正式渠道、稳定页面、PDF 地址或正文可得性、DOI/arXiv ID（存在时）和主题相关性。

候选硬门槛为直接相关、年份合规、元数据可核验、正文可获得。满足门槛后优先正式发表或被官方渠道确认接收的成果；相关性和证据相当时正式版优先。高质量预印本用于补足相关工作，不用弱相关论文凑数。年份列记首次可靠公开年份，发表渠道列另记正式渠道年份；预印本与正式版属于同一工作时保留一个 Paper_ID。

## 6. 去重与缓存

候选去重顺序：DOI、arXiv ID、规范化题名、作者与方法相符的版本关系。检索前运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/maintain_literature_candidates.ps1 -Mode Report -Root <仓库根目录> -CachePath <候选缓存路径>
```

该脚本从 taxonomy 总账、当前角色索引和逐篇目录识别已收录条目。年份清单中的未完成候选不因已登记而算作入库。缓存每行至少含 `run_id`、`checked_at`、`title`、`normalized_title`、`status`；不得写入 Cookie、令牌、密码等凭据。

## 7. 候选字段与状态

年份筛选清单至少记录：Paper_ID、年份、主类/二级类、题名、稳定文献链接、直接 PDF 链接或受限原因、发表渠道、关键词、优先级、状态和一手核验来源。

成功状态依次为：

`发现候选 → 元数据已核验 → 已下载 → PDF有效 → 阅读完成 → taxonomy 已登记 → 角色索引已登记 → 逐篇目录已登记 → 年份清单已完成`

失败状态使用 `重复项`、`年份不符`、`年份待确认`、`下载失败`、`需要用户会话下载`、`正文不可得`、`PDF无效`、`阅读失败` 或 `待分类`，并附一句原因。`需要用户会话下载` 可重试，但不得标为已下载。

## 8. PDF 与阅读

下载前用候选脚本的 `ProbePdf` 模式检查直接链接：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/maintain_literature_candidates.ps1 -Mode ProbePdf -PdfUrl <直接PDF链接>
```

保存后检查 `%PDF-` 签名并使用 PDF 解析器确认页数。登录页、HTML、错误页和不可解析文件均不得进入有效 PDF 状态。复用已有有效 PDF，不重复下载。

**REQUIRED SUB-SKILL:** 使用 `reading-compiler-literature` 逐篇阅读。事实只来自可读正文；准确数字标明对照对象、数据集、指标和统计口径。正文不可得时保留失败/受限状态，不能伪装为全文阅读。逐篇笔记使用 13 节合同；最小可行 Demo 只在后续创新方案阶段集中设计。

## 9. 同步索引

同一批次内依次完成以下写入：

1. 更新 CSV 中的当前路径字段 `PDF_Path`、`Note_Path` 和分类证据字段。
2. 在 `00_三大类分类索引_v2.md` 的目标二级分类表中加入文献笔记链接、本地 PDF 链接和元数据。
3. 在逐篇阅读目录中保留所有旧历史行，并将新条目追加到 `Taxonomy v2 新增记录` 区；其类别栏写 `PRIMARY / SECONDARY`。
4. 更新年份筛选清单状态和本轮计数；失败项保留原因。

两个当前目录都必须能跳转到 Note_Path；有本地 PDF 的条目必须能跳转到 PDF_Path。源材料受限条目明确写“资料受限（无本地 PDF）”。类别、Paper_ID、笔记和 PDF 路径必须与 CSV 一致。

## 10. 优先级和复核

| 优先级 | 依据 |
|---|---|
| 高 | 核心竞品、关键方法或基础设施，直接影响研究主线或新颖性判断 |
| 中高 | 可组合方法、强实验基线或高复现价值材料 |
| 中 | 重要支撑、评测或工程参考 |
| 低 | 背景或与编译器主线关系较弱 |

渠道声望不直接决定研究优先级。源材料受限条目不标为高。分类或路径无法可靠确认时设置 `Needs_Review=YES`，并在报告中列出人工确认项。

## 11. 验证与完成条件

完成批次前运行：

```powershell
py -3 scripts/validate_taxonomy_v2.py
py -3 scripts/validate_taxonomy_links.py
powershell -ExecutionPolicy Bypass -File scripts/validate_literature_corpus.ps1 -Root <仓库根目录>
```

必要时还运行 `tests/maintain_literature_candidates.Tests.ps1` 和创新证据验证。语料库校验要求 taxonomy、当前角色索引、逐篇目录和年份清单存在；CSV 与两个目录的 Paper_ID 集合一致；分类与 Note_Path/PDF_Path 一致；笔记满足 13 节；本地 PDF 签名有效；所有索引链接有效。

完成数须满足：候选数 = 成功数 + 保留失败数；每条新增 taxonomy 记录在两个目录均有对应 ID；有效 PDF 数等于可解析的新 PDF 数；成功笔记数等于合格的新笔记数。任一验证未通过时，报告未完成的阶段与证据。

## 12. Git 边界

常规入库任务在本地完成并验证后交付状态摘要。只有用户明确要求 Git 交付时，才执行暂存、提交、fetch 或 push；届时仅暂存本轮相关文件，遵守仓库 `AGENTS.md` 的提交信息格式和安全规则。远端领先或分叉时停止并报告，不强推、不重写历史。
