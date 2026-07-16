# 硬件效应反馈驱动的 LLM 编译优化智能体材料实施计划

> **For agentic workers:** This plan is documentation-only; execute inline with checkpointed verification. Steps use checkbox syntax for tracking.

**Goal:** 建立独立的“硬件效应反馈驱动的可验证 LLM 编译优化智能体”材料文件夹，并提供可用 GCC 运行、可替换真实 LLM 的预实验 Demo。

**Architecture:** 以硬件条件化的证据契约为主线：Agent 接收程序特征与硬件响应摘要，生成候选和证据契约；确定性工具执行编译、正确性和性能检查；路由器决定迁移、补测或拒绝。RISC-V/RVV 只作为实验平台选项。

**Tech Stack:** Markdown、PowerShell、GCC、工作区 Python；不要求安装 MLIR、Clang 或特定 LLM 服务。

## Global Constraints

- 独立文件夹不使用数字前缀，不修改此前两个材料文件夹。
- 主线核心必须是硬件效应反馈驱动的 LLM Agent，而不是 RISC-V 专用后端。
- 预实验明确区分真实多硬件结果与单机不同编译目标配置的弱替代实验。
- 所有性能结论必须经过正确性、重复测量和证据契约门控。
- Codex 创建的 commit 信息必须以 `由Codex提交：` 开头。

---

### Task 1: 建立材料目录和索引

**Files:**
- Create: `硬件效应反馈驱动的可验证LLM编译优化智能体/00_材料索引与使用说明.md`

- [ ] 写明主线、文件用途、阅读顺序和 RISC-V 平台边界。
- [ ] 检查索引中的每个相对链接都指向现有文件。

### Task 2: 编写硬件感知主线框架

**Files:**
- Create: `硬件效应反馈驱动的可验证LLM编译优化智能体/01_硬件感知LLM智能体主线框架.md`

- [ ] 定义硬件响应摘要、硬件条件化证据契约、迁移/补测/拒绝决策和记忆门控。
- [ ] 写出研究问题、假设、基线、消融、统计和失败条件。
- [ ] 明确 RISC-V 只是平台矩阵中的一个选项。

### Task 3: 汇集相关材料

**Files:**
- Copy: `可执行证据契约驱动的LLM编译优化智能体/02_LLM智能体与证据契约材料.md`
- Copy: `可执行证据契约驱动的LLM编译优化智能体/04_硬件反馈与跨平台支撑材料.md`
- Copy: `可执行证据契约驱动的LLM编译优化智能体/03_语义与盈利证书支撑材料.md`
- Copy: `可执行证据契约驱动的LLM编译优化智能体/05_跨平台边界与RVV压力测试材料.md`

- [ ] 保留原始证据边界，不把支撑材料改写成新的原创性事实。

### Task 4: 编写硬件感知预实验 Demo

**Files:**
- Create: `硬件效应反馈驱动的可验证LLM编译优化智能体/06_硬件感知预实验Demo.md`

- [ ] 使用 GCC SAXPY 内核展示两个硬件配置摘要和候选路由。
- [ ] 提供 Stub Agent、Direct-LLM 和 Contract-LLM 三种条件。
- [ ] 规定编译证据、checksum、重复时间、speedup、迁移/补测/拒绝输出。
- [ ] 说明单机目标配置只能作为弱替代实验，不能冒充真实跨硬件结论。

### Task 5: 完整验证和提交

- [ ] 验证目录文件数、索引链接、关键术语和禁用表述。
- [ ] 运行 `scripts/validate_literature_corpus.ps1`，确认原语料库不受影响。
- [ ] 执行 `git diff --check`。
- [ ] 使用前缀 `由Codex提交：研究：建立硬件感知LLM智能体材料` 提交并推送。
