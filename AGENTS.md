# Repository Instructions

## Git 提交信息

- Codex 创建的每一条 commit 信息都必须以 `由Codex提交：` 开头。
- 推荐格式：`由Codex提交：<类型>：<简洁说明>`。
- 除非用户明确要求，不改写用户本人创建的 commit 信息。

## Git 沙盒规则

- Codex 执行会写入 Git 元数据或访问远端的命令时，必须使用 `git -C "C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献" <子命令>` 形式，以匹配仅限本仓库的持久权限规则。
- 适用子命令包括 `fetch`、`add`、`commit`、`push` 和 `merge --ff-only`；不得扩大到其他仓库或破坏性 Git 操作。
