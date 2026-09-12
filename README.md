# AI 编译器文献语料库

本仓库以文献语料库为主体，按语言模型在编译系统中的最终角色组织：

- [LLM as Selector](01_LLM_as_Selector/)：模型选择 pass、配置、策略或工具动作。
- [LLM as Translator](02_LLM_as_Translator/)：模型直接输出变换后的源码、IR、汇编或内核。
- [LLM as Generator](03_LLM_as_Generator/)：模型生成可复用的 pass、规则、组件或工具。
- [Supporting Literature](90_Supporting/)：基准、基础设施、传统方法、硬件背景与综述。

## 主要入口

- [三大类分类索引](00_三大类分类索引_v2.md)
- [机器可读分类表](taxonomy_v2.csv)
- [旧分类索引（保留回溯）](00_分类索引.md)
- [逐篇阅读笔记](文献逐篇阅读/)
- [研究框架总目录](研究框架/)

## 维护与归档

- [分类规则](docs/taxonomy/taxonomy_v2_rules.md)
- [文献阅读规范](docs/文献维护/文献阅读要求.md)
- [taxonomy v2 迁移过程](archive/taxonomy_v2_迁移过程/)
- [历史下载清单](archive/语料库下载历史/)

研究框架材料与语料库分开维护；每个框架在 `研究框架/` 下拥有独立目录。
