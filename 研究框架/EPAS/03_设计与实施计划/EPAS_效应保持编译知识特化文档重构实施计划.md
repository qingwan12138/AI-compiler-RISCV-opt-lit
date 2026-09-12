# EPAS 效应保持编译知识特化文档重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前“通用—架构特化双层知识”主线重构为 EPAS 的“跨层效应契约—最小架构增量特化—知识可迁移边界发现”，并同步全部交付副本。

**Architecture:** `K=(Pre,I,E*,Slots,Verify)` 定义跨层效应契约；`Φ_h` 记录目标平台真实效应；`G_h` 衡量效应实现误差；`δ_h` 表示最小架构增量；`T(K,h)` 根据实现质量、适配成本和负迁移发现知识边界。原双层知识、实例化器和 `Q_shared + Q_arch` 保留为数据结构与支撑机制，不再单独承担创新性。

**Tech Stack:** Markdown、PowerShell、`apply_patch`、`rg`、严格 UTF-8、SHA-256、现有 44 篇文献证据矩阵、IntOpt、QiMeng-GEMM。

## Global Constraints

- 设计规范为 `docs/superpowers/specs/2026-07-13-effect-preserving-architecture-specialization-design.md`。
- 所有创新继续标注“候选创新，尚需针对性查新”，不得声称首次。
- 必须明确 IntOpt 已覆盖 intent 与 transformation 的显式分离。
- 必须明确 QiMeng-GEMM 已覆盖平台无关描述、平台 hints、实例化和目标平台搜索。
- 双层知识、Adapter、pairwise ranking、排序器、少样本学习和 RISC-V 实测均不得单独写成主创新。
- EPAS 文档必须定义 `E_m^{*}`、`Φ_h(P,c)`、`G_h(K^m,c)`、`δ_h^m`、`T(K^m,h)` 和 `Normalize_h`。
- 第一版为 x86 + RISC-V，只声称跨平台效应保持与架构特化；至少第三类平台完整留出后才评估未见架构适应。
- 第一版不引入世界模型、多步 rollout、完整 RL、双 LLM 联合训练、LLVM 后端源码改造或创新 05 主线。
- 不修改 `C:\Users\2025111355\Desktop\crosstune_minidemo`。
- 保留 `C:\Users\2025111355\Desktop\文献\当前创新框架总结.md`，最终 SHA-256 必须仍为 `13D667A9CCC27D84AAC4930B567BF2961141F04FB106467B7DB784ED42A8280D`。
- 当前工作区不是 Git 仓库；用历史副本和哈希校验替代提交。

---

## File Map

### 工作区源文档

- Archive: `work/history/2026-07-13-before-epas-effect-contract/`
- Modify: `work/innovation_docs/00_证据矩阵.md`
- Modify: `work/innovation_docs/00_六类论文创新点总览.md`
- Modify: `work/innovation_docs/01_Pass调优_跨架构效应解耦的少样本策略迁移.md`
- Modify: `work/innovation_docs/02_编译智能体_真实后端实现对齐的意图反馈学习.md`
- Modify: `work/innovation_docs/04_代码翻译_向量语义中间层驱动的可伸缩跨ISA迁移.md`
- Delete after archive: `work/innovation_docs/06_多硬件编译_通用-架构特化双层知识驱动的编译自适应.md`
- Create: `work/innovation_docs/06_多硬件编译_效应保持的最小架构增量知识特化.md`
- Delete after archive: `work/innovation_docs/CrossTune-RL_多硬件自适应编译优化研究框架.md`
- Create: `work/innovation_docs/EPAS_效应保持的多硬件编译知识特化研究框架.md`

### 工作区交付副本

- Sync directory: `outputs/六类论文创新点提炼/`
- Replace old 06 with `06_多硬件编译_效应保持的最小架构增量知识特化.md`
- Replace CrossTune framework with `EPAS_效应保持的多硬件编译知识特化研究框架.md`
- Sync modified 00、01、02、04。

### 桌面文献项目

- Sync directory: `C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\07_六类论文创新点提炼`
- Preserve: `C:\Users\2025111355\Desktop\文献\当前创新框架总结.md`

---

### Task 1: 建立 EPAS 重构前历史基线

**Files:**
- Create: `work/history/2026-07-13-before-epas-effect-contract/`
- Read: File Map 中全部待修改或替换的工作区源文档

**Interfaces:**
- Consumes: 当前双层知识版本与已批准 EPAS 规范。
- Produces: 可恢复的重构前文档、文件清单和哈希记录。

- [ ] **Step 1:** 严格 UTF-8 读取证据矩阵、总览、01、02、04、当前 06 和当前总框架。
- [ ] **Step 2:** 创建历史目录并复制上述 7 份源文档，文件名保持不变。
- [ ] **Step 3:** 记录 work、outputs、桌面目录文件清单及 SHA-256。
- [ ] **Step 4:** 验证历史副本与当前源文档逐份哈希一致。
- [ ] **Step 5:** 验证 `当前创新框架总结.md` 的 SHA-256 为既定值；失败时停止。

### Task 2: 重写证据矩阵与主创新 06

**Files:**
- Modify: `work/innovation_docs/00_证据矩阵.md`
- Delete: `work/innovation_docs/06_多硬件编译_通用-架构特化双层知识驱动的编译自适应.md`
- Create: `work/innovation_docs/06_多硬件编译_效应保持的最小架构增量知识特化.md`

**Interfaces:**
- Consumes: EPAS 设计规范、IntOpt 和 QiMeng-GEMM 边界、现有第 6 类证据。
- Produces: 13 节 EPAS 主创新文档及更新后的第 2/6 类研究空白。

- [ ] **Step 1:** 在证据矩阵第 2 类明确 IntOpt 已覆盖 intent formulation/refinement/realization，不能把 intent 显式化重复写成创新。
- [ ] **Step 2:** 在证据矩阵第 6 类将空白改为“效应契约、最小架构增量和迁移边界”，保留 QiMeng-GEMM 边界。
- [ ] **Step 3:** 归档后删除当前 06，并用新文件名创建恰好 13 个编号二级章节。
- [ ] **Step 4:** 第 1–4 节写候选名称、已有工作边界、研究空白和主/子研究问题。
- [ ] **Step 5:** 第 5–8 节定义 `K^m`、`Φ_h`、`G_h`、`δ_h`、特化目标和 `T(K,h)` 分类判据。
- [ ] **Step 6:** 第 9–11 节写系统闭环、MVP、基线/消融/指标和可证伪标准。
- [ ] **Step 7:** 第 12–13 节写代码翻译接口、风险、命名和综合评分。
- [ ] **Step 8:** 验证恰好 13 节、至少 7 个来源链接、五个核心量完整、无首次断言，且双平台声明边界正确。

### Task 3: 重写 EPAS 总研究框架

**Files:**
- Delete: `work/innovation_docs/CrossTune-RL_多硬件自适应编译优化研究框架.md`
- Create: `work/innovation_docs/EPAS_效应保持的多硬件编译知识特化研究框架.md`

**Interfaces:**
- Consumes: Task 2 新版 06 和 EPAS 设计规范。
- Produces: 15 节总框架，覆盖知识、特化、评价、反馈和迁移边界发现。

- [ ] **Step 1:** 将标题、一句话定位和主研究问题全部切换为 EPAS；CrossTune-RL 只作为历史名称说明。
- [ ] **Step 2:** 写入 `K → E* → δ_h → Specialize → Φ_h → G_h → Top-k → T(K,h)` 的总体数据流。
- [ ] **Step 3:** 分别定义效应契约、平台归一化、最小增量正则、正确性/合法性约束和迁移分类。
- [ ] **Step 4:** 明确 LLM、双层知识、实例化器、Adapter、排序器、RISC-V 和 RL 的支撑定位。
- [ ] **Step 5:** 保留现有 Mini Demo 数据管线批评：模拟结果、人工 `policy_order()`、非空输出检查、缺少预热和重复测量均不是论文证据。
- [ ] **Step 6:** 更新基线、消融、指标、实施阶段、代码翻译接口、查新词、风险和降级方案。
- [ ] **Step 7:** 验证总框架恰好 15 个编号章节，含五个核心量、IntOpt/QiMeng 边界、MVP 和两/三平台声明条件。

### Task 4: 更新总览与关联文档

**Files:**
- Modify: `work/innovation_docs/00_六类论文创新点总览.md`
- Modify: `work/innovation_docs/01_Pass调优_跨架构效应解耦的少样本策略迁移.md`
- Modify: `work/innovation_docs/02_编译智能体_真实后端实现对齐的意图反馈学习.md`
- Modify: `work/innovation_docs/04_代码翻译_向量语义中间层驱动的可伸缩跨ISA迁移.md`

**Interfaces:**
- Consumes: Task 2–3 的新文件名和主创新定义。
- Produces: 有效链接、无旧主线残留的六类总览及关联说明。

- [ ] **Step 1:** 总览改写主问题、核心公式、架构图、评分、实验和推荐题目，链接新版 06 与 EPAS 总框架。
- [ ] **Step 2:** 总览明确“06 为主创新”“01 已并入 06”“02 为效应观测与解释支撑”“04 为代码翻译扩展”“05 不进入当前研究主线”。
- [ ] **Step 3:** 更新 01 顶部说明，将共享—残差模型定位为 EPAS 的候选排序支撑。
- [ ] **Step 4:** 更新 02 顶部说明，将意图—后端对齐定位为 `Φ_h/G_h` 的观测和解释来源，不单独承担 intent 创新。
- [ ] **Step 5:** 更新 04 顶部说明，将跨 ISA 翻译定位为 EPAS 的第二阶段候选实例化对象。
- [ ] **Step 6:** 验证总览 7 个相对 Markdown 链接全部有效，01、02、04 各自仍为 13 个编号章节，且没有旧 06/旧框架链接。

### Task 5: 同步 outputs 与桌面文献项目

**Files:**
- Sync: `outputs/六类论文创新点提炼/*.md`
- Sync: `C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\07_六类论文创新点提炼\*.md`

**Interfaces:**
- Consumes: 已核验的 8 份工作区交付文档。
- Produces: work、outputs、Desktop 三处完全一致的 8 份 Markdown。

- [ ] **Step 1:** 精确删除 outputs 中旧 06 和旧 CrossTune 总框架，复制新版 00、01、02、04、06 和 EPAS 总框架。
- [ ] **Step 2:** 验证 outputs 恰好 8 份 Markdown，只有一个 `06_` 文件和一个 EPAS 总框架。
- [ ] **Step 3:** 请求桌面目标目录写权限，解析并核对绝对路径严格位于指定 `07_六类论文创新点提炼` 目录。
- [ ] **Step 4:** 精确删除桌面旧 06 和旧 CrossTune 总框架，同步修改文档；03、05 保持内容不变。
- [ ] **Step 5:** 验证 Desktop 恰好 8 份 Markdown，文件名与 outputs 完全一致。
- [ ] **Step 6:** 验证 work、outputs 和 Desktop 的 8 份同名文件逐份 SHA-256 一致。

### Task 6: 完整交付验证

**Files:**
- Verify: `work/innovation_docs/*.md`
- Verify: `outputs/六类论文创新点提炼/*.md`
- Verify: Desktop 交付目录 `*.md`
- Preserve: `C:\Users\2025111355\Desktop\文献\当前创新框架总结.md`

**Interfaces:**
- Consumes: Task 1–5 的历史副本、源文档和同步副本。
- Produces: 退出码 0、失败项 0 的最终验证证据。

- [ ] **Step 1:** 严格 UTF-8 解码三处 8 份交付文档并确认非空。
- [ ] **Step 2:** 验证 01–06 各为 13 个编号章节，EPAS 总框架为 15 个编号章节。
- [ ] **Step 3:** 验证新版 06 和总框架含 `E*`、`Φ_h`、`G_h`、`δ_h`、`T(K,h)`、`Normalize_h`、MVP 和可证伪标准。
- [ ] **Step 4:** 验证 IntOpt 与 QiMeng-GEMM 边界、双平台/三平台声明和支撑模块定位完整。
- [ ] **Step 5:** 验证总览 7 个链接有效，所有当前交付文档不引用旧 06 或旧 CrossTune 总框架文件名。
- [ ] **Step 6:** 验证旧文件仅存在于历史归档，当前 work、outputs 和 Desktop 均不存在。
- [ ] **Step 7:** 验证三处 8 份文档名称和 SHA-256 完全一致。
- [ ] **Step 8:** 验证历史 `当前创新框架总结.md` 哈希未变；输出文件数、章节数、链接数、核心术语、哈希匹配数和失败数。
