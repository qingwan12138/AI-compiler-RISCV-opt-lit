# 语料库三个 Skill 与 Taxonomy v2 适配设计

## 1. 目标

将 `maintaining-compiler-literature-corpus`、`reading-compiler-literature` 和 `developing-compiler-innovations` 统一适配到仓库当前的 Taxonomy v2 结构，并把可维护版本提交、推送到 GitHub。迁移历史继续可审计，但不再进入日常维护路径。

## 2. 当前问题

- 语料库维护 skill 仍把旧六类目录和 `00_分类索引.md` 当作当前合同。
- 校验器仍要求旧索引，并保留迁移前、迁移后双路径语义。
- 逐篇阅读 skill 没有声明 Taxonomy v2 的分类输入、路径归属和总账更新边界。
- 创新分析 skill 仍以旧六类为固定分析单元，与当前 Selector、Translator、Generator、Supporting 体系冲突。
- 仓库只保存了语料库维护 skill；另外两个 skill 只有已安装副本，无法随仓库版本化和复现。

## 3. 权威数据与文件职责

日常维护采用以下职责划分：

| 文件 | 职责 |
|---|---|
| `taxonomy_v2.csv` | 论文唯一 ID、当前主类/二级类、标签、优先级、当前 PDF/笔记路径及复核状态的机器可读总账 |
| `00_三大类分类索引_v2.md` | 面向人的当前分类总索引；包含三个 LLM 核心角色和 Supporting |
| `文献逐篇阅读/00_逐篇阅读目录.md` | 面向人的全部阅读笔记目录 |
| `文献逐篇阅读/2024-2026_文献年份筛选清单.md` | 新候选的发现、核验、下载和阅读状态 |
| `文献逐篇阅读/候选处理缓存.jsonl` | 可重试事件与跨批次去重辅助记录 |
| `archive/taxonomy_v2_迁移过程/` | 旧六类到 Taxonomy v2 的迁移证据，仅供审计 |

`00_分类索引.md` 明确降级为旧结构兼容入口，不再参与新增论文事务或完成判定。

## 4. Taxonomy CSV 精简

先把当前完整 `taxonomy_v2.csv` 复制为迁移归档快照，再将日常总账移除以下旧迁移字段：

- `Old_Category`
- `Old_PDF_Path`
- `Old_Note_Path`

将：

- `Proposed_PDF_Path` 改名为 `PDF_Path`
- `Proposed_Note_Path` 改名为 `Note_Path`

其他当前分类、标签、证据和复核字段保持不变，Paper ID、记录数、分类值和实际路径不得变化。同步修改 taxonomy、链接和创新证据验证脚本，取消 `--pre-migration` 日常验证模式；历史迁移工具保留在归档目录，不改写历史报告。

## 5. 三个 Skill 的职责

### 5.1 语料库维护

`maintaining-compiler-literature-corpus` 负责从检索到正式入库的状态事务：

1. 从年份清单登记候选并核验元数据。
2. 根据论文中语言模型的最终编译系统角色确定主分类，再按受控词表选择二级分类。
3. 下载 PDF、调用逐篇阅读 skill、生成当前路径。
4. 同步 taxonomy CSV、当前分类索引、逐篇目录和年份清单。
5. 运行完整验证后才允许 Git 交付。

其分类合同直接引用仓库 `docs/taxonomy/taxonomy_v2_rules.md`，skill 自身只保留执行所需的简明路径映射和事务规则。

### 5.2 逐篇阅读

`reading-compiler-literature` 继续负责基于正文生成 13 节中文笔记，但增加仓库集成接口：

- 输入包含 Paper ID、PDF 路径、主类和二级类；已有 taxonomy 记录优先于自行推断。
- 新论文尚未入账时，可以输出分类建议，但正式分类由维护 skill 写入总账。
- 笔记写入 `文献逐篇阅读/<主类目录>/<二级类目录>/`。
- 单篇阅读只更新笔记；批量入库时由维护 skill 统一更新三个状态文件，避免两个 skill 并发修改总账。
- 保留正文证据纪律和 13 节格式，不把创新 Demo 写入逐篇笔记。

### 5.3 创新分析

`developing-compiler-innovations` 不再按旧六类强制拆分，改为：

1. 以 Selector、Translator、Generator 三个核心角色分别建立证据组。
2. Supporting 只作为基准、基础设施、传统方法、硬件背景或评测证据，不产生与核心角色并列的“第四条 LLM 创新主线”。
3. RISC-V/RVV、LLVM/MLIR、形式验证、反馈、RL、Agent 和多硬件作为横向标签与约束分析。
4. 先在角色内推导候选，再跨角色进行新颖性碰撞、机制合并和唯一主线选择。
5. 通过 Paper ID 和 `Note_Path` 读取证据，输出继续区分论文事实、合理推导和候选创新。

## 6. 仓库与本地安装布局

仓库 `skills/` 保存三个 skill 的完整可版本化源文件：

```text
skills/
├── maintaining-compiler-literature-corpus/
├── reading-compiler-literature/
└── developing-compiler-innovations/
```

实现和验证以仓库副本为准。三项逐一完成 RED、GREEN 和回归验证后，再同步到 `C:\Users\2025111355\.codex\skills\<skill-name>\`。同步仅覆盖这三个明确目标，不触碰其他已安装 skill。

## 7. 测试与验证

在修改每个 skill 前，先增加会因旧合同而失败的测试，再进行最小修改：

- 维护 skill：测试不得引用旧六类或把 `00_分类索引.md` 当作当前索引；验证器必须读取新总账字段和当前索引。
- 阅读 skill：测试必须识别 Taxonomy v2 输入、主/二级路径以及“维护 skill 负责总账写入”的职责边界。
- 创新 skill：测试必须识别三核心角色、Supporting 支撑定位和横向标签，且不再要求旧六类输出。
- Taxonomy：验证 169 个唯一 Paper ID、四个有效主类、二级类合法、所有 `PDF_Path`/`Note_Path` 存在、当前两个索引链接有效。

最终运行：skill 快速校验、skill 合同测试、taxonomy 验证、链接验证、语料库验证、创新证据验证和 `git diff --check`。任何记录数、路径、PDF、笔记或索引内容异常都停止提交。

## 8. Git 与交付

- 设计规格独立提交。
- 实现只暂存 taxonomy、三个 skill、对应脚本、测试和必要文档。
- 提交信息全部以 `由Codex提交：` 开头。
- 推送前重新获取 `origin/main`；远端前进或分叉时停止，不强推。
- 推送后确认本地 `HEAD` 与 `origin/main` 一致、工作区干净。

## 9. 完成标准

- 三个 skill 在仓库中均有完整源文件并通过校验。
- 三个已安装副本与仓库对应目录内容一致。
- 日常 taxonomy CSV 不再含旧迁移字段，归档快照可追溯。
- 当前索引、PDF、笔记、Paper ID 和创新证据引用全部通过验证。
- 实现提交已推送到 GitHub，且本地与远端无 ahead/behind。
