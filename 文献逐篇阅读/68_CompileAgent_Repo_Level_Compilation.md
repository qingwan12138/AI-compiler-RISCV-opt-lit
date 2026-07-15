# 68. CompileAgent: Automated repo-level compilation with LLM agent

> 主题分类：仓库级编译智能体

## 阅读范围与证据边界

- 原始来源：[https://aclanthology.org/2025.acl-long.103.pdf](https://aclanthology.org/2025.acl-long.103.pdf)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\02_LLM编译优化智能体与反馈驱动\58-CompileAgent Repo-Level Compilation. ACL 2025`
- 本地 PDF 文件数：1；提取页数：14
- 阅读状态：完整 PDF 阅读

完整 PDF，14 页；重点核对摘要、方法、实验、结论与局限。

## 1. 研究问题与动机

如何自动搜索构建指令并解决真实仓库的编译错误。

## 2. 方法与系统结构

CompileNavigator 与 ErrorSolver 结合五种工具，用 flow-based Agent 与软件制品交互；并构建 CompileAgentBench。

## 3. 实验与主要发现

编译成功率由 10% 提升至 71%，flow-based 策略优于其他 Agent 组织。

## 4. 局限与批判性阅读

工具较基础、提示敏感且会重复错误动作；编译成功不等于测试通过或性能改善。

## 5. 对当前研究方向的关系

可作为 CABLE 自动构建前端，但不应被视为优化核心贡献。

## 6. 可提炼的研究启发

固定流程和专用工具能显著约束仓库级 Agent 的行动空间。

## 7. 一句话总结

固定流程和专用工具能显著约束仓库级 Agent 的行动空间。
