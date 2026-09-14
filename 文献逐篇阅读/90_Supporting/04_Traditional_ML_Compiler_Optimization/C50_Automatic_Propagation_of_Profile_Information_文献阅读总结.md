# C50 Automatic Propagation of Profile Information through the Optimization Pipeline 文献阅读总结

论文题目：**Automatic Propagation of Profile Information through the Optimization Pipeline**

作者：Elisa Fröhlich、Angélica Aparecida Moreira、Fernando Magno Quintão Pereira。

发表信息：Proceedings of the ACM on Programming Languages, Volume 10, Issue OOPSLA1, Article 139（2026），26 页；DOI 10.1145/3798247。论文于 2025-10-09 收稿、2026-02-17 接收，2026 年 4 月出版。

来源：[OOPSLA 2026 论文页](https://2026.splashcon.org/details/oopsla-2026/47/Automatic-Propagation-of-Profile-Information-through-the-Optimization-Pipeline)、[ACM DOI 记录](https://doi.org/10.1145/3798247)、[作者公开 PDF](https://homepages.dcc.ufmg.br/~fernando/publications/papers/FrohlichOOPSLA26.pdf)、[artifact 项目 Hydra](https://github.com/lac-dcc/hydra)。

阅读材料：作者最终稿 PDF，共 26 页。

关键词：profile-guided optimization、control-flow graph、profile prediction、profile projection、直方图匹配、LLVM、GPT-4o、Hot-Order。

## 1. 研究背景

PGO 通过运行时观测的边频率、块频率等 profile 信息指导内联、布局及其他优化。但优化 pass 会改变控制流图，导致旧 profile 逐渐陈旧或无法直接映射；重新运行程序采集 profile 又可能昂贵、不可行或需要输入复现。论文研究如何在优化流水线中尽量复用已有执行数据，减少每个版本都重新运行的需求。

## 2. 论文要解决的问题

论文区分两个任务：profile prediction 从一个已优化程序的 CFG 单独预测热路径；profile projection 则给定参考 CFG 及其旧 profile，把频率信息映射到变换后的目标 CFG。作者希望在不重新执行目标程序的情况下，获得对目标热块排序足够准确的 profile，并比较经典算法与 LLM 方法。

## 3. 核心方法概述

论文评估静态预测和跨版本投影两类方法。静态预测基线包括随机排序、LLVM BranchProbabilityInfo/Ball-Larus 类启发式，以及 GPT-4o 读取 CFG 文本后生成热块顺序。投影方法包括已有分层哈希匹配，以及作者提出的 histogram matching：为基本块提取指令 opcode 直方图和局部邻域信息，对嵌套循环先从内到外按循环直方图匹配，再对块间相似度进行匹配；使用匹配点将参考频率投到目标 CFG。对仍缺少频率的边，再通过 minimum-cost-flow 约束补全；无法完成时用均匀外出边概率作兜底。

LLM projection 将参考 CFG/顺序与目标 CFG 一并提供给 GPT-4o，并要求 JSON 格式顺序；系统检查缺失、重复和额外块名，非法输出不进入准确率计算（第 3–4 节）。

## 4. 实验框架与训练流程

本文没有训练或微调 LLM。GPT-4o 仅通过 prompt 执行预测/投影基线；论文报告使用 Azure OpenAI 部署标识 azure:gpt-4o_2024-11-20、温度 0、最大输出 token 数 16384，其他生成超参数未完整披露。实验用 cBench 32 个程序、每个程序 20 个输入；因 clang 构建错误，最终保留 17 个成功基准。经典算法覆盖 168 个函数，平均每函数 42 个基本块；LLM prediction 因非法顺序降到 127 个函数，LLM projection 使用 120 个函数，平均分别约 20、18 个块（第 5.1、5.3–5.4 节）。测试平台为 Ubuntu 22.04.1、Intel Core i7-6700T、8 GB RAM、LLVM 18.1.8；profile 使用 Nisse 插桩，commit 25d9adf。论文报告的是模拟量/算法测量与配置下的准确率，不是运行时 speedup。

## 5. 奖励函数、损失函数或关键公式

无学习奖励或损失函数。主指标 Hot-Order 将基本块按真实或估计频率排序，以相邻交换数（等价于逆序对数）衡量估计顺序与实测顺序的差异。准确率为：

准确率 = 1 − 2 × swap_distance / (N × (N − 1))

其中 N 是 CFG 基本块数，1 表示顺序完全一致，0 表示与真实顺序相反的极端情况。该指标衡量频率排序质量，是 profile 代理指标，不等价于优化后的程序速度或 PGO 实际收益（Definition 5.1）。

## 6. 实验设置

RQ1 比较静态预测；RQ2 比较 hash 与 histogram 投影；RQ3/RQ4 比较 GPT-4o prediction/projection 与经典方案；RQ5 分析单个 LLVM 优化对映射精度的影响；RQ6 测量经典算法耗时。静态表格分别聚合 17 个基准上的函数结果；RQ5 固定使用各 cBench 程序的第一个输入，隔离单个优化 pass 的影响。profile projection 的耗时不包括初始 profile 采集，LLM 端到端耗时因远端服务/网络波动而未给出（第 5 节）。

## 7. 实验结果与结论

**静态预测（Table 1、3）**：LLVM 启发式在 -O0/-O1/-O2/-O3 的准确率分别为 79.52%、77.73%、77.09%、77.09%；随机基线约 48.44%–50.50%。受限于合法输出的 GPT-4o prediction 在 127 个函数上为 69.81%、70.96%、69.84%、71.25%，高于随机但低于 LLVM。

**profile projection（Table 2）**：作者 histogram 匹配在全部优化级别组合中均超过 hash 匹配。例如参考 -O1 到目标 -O1 分别为 97.17% 与 91.60%；参考 -O0 到目标 -O3 为 72.52% 与 63.95%。当两版 CFG 差异很大时，跨 -O0 与优化版本直接投影会下降；逐个优化阶段增量传播更可行。

**LLM projection（Table 4）**：GPT-4o projection 高于其静态 prediction，但仍落后于 hash/histogram 经典投影，且大型双 CFG prompt 更容易输出不完整或格式错误的块序列。

**误差来源与开销（RQ5–RQ6）**：simplifycfg、尤其 loop-rotate 会削弱结构匹配精度；loop rotation 改变循环入口/出口频率，参考图缺少的信息无法从结构匹配中恢复。Histogram 在 168 个函数上的总投影耗时约 22–48 秒，hash 约 8–14 秒；histogram 较慢但仍在一分钟内。作者结论是 histogram 是简单且实用的流水线候选，而不是已证明的端到端性能提升（第 5.2–5.6、7 节）。

## 8. 主要创新点

1. 将优化器流水线中的 profile 延续明确拆分为静态预测与跨 CFG 投影任务，并统一评估。
2. 提出基于块/循环指令直方图与局部结构的匹配方法，再用最小费用流补全未映射边。
3. 在同一 Hot-Order 设置中比较传统 LLVM 启发式、hash/histogram 与 GPT-4o，并分析优化 pass 对投影失真的作用。

## 9. 局限性

1. cBench 32 个基准中仅 17 个能成功构建运行，数据覆盖有限；有效样本还随 LLM 输出格式错误减少。
2. Hot-Order 排序准确率并非真实程序 speedup，也未直接证明将预测 profile 用于 PGO 后能提高最终性能。
3. 结构匹配无法恢复参考程序中不存在的动态信息，loop-rotate 是明显误差源；重复 simplifycfg 也可能累积偏差。
4. GPT-4o prediction 和 projection 均不如 LLVM/经典投影，且输出有效性会进一步缩小样本；LLM 延迟、费用和超参数披露不完整。
5. 实验集中于 cBench 和指定 LLVM/硬件环境，对更大规模工业程序与其他编译器流水线的外推需要验证。

## 10. 阅读后的研究方向反思

结果说明，profile 迁移需要同时处理控制流结构对应与动态频率守恒；单纯文本化 CFG 并不能替代编译器对支配、循环及边概率的领域知识。比起泛化地让 LLM猜热块，合理的方向是让其辅助定位不确定映射，再由结构约束、流守恒和验证器筛选，并将误差传导到后续 PGO 决策影响进行因果测量。

## 11. 可进一步尝试的研究方向

1. 在连续 pass 之间增量投影并周期性触发 profile 重采样，量化误差累积阈值。
2. 结合 block/loop 直方图、支配关系、循环迭代信息和语义锚点，专门改进 loop rotation、vectorization 与路径复制。
3. 以实际 PGO 运行时、代码布局、编译稳定性为终点指标，验证 Hot-Order 改善能否转化为收益。
4. 将 LLM 限定为候选匹配/不确定性解释器，使用类型化 CFG schema、强约束输出和流守恒检查降低无效结果。

## 12. 与当前批次文献的关系

同批 CCNF 论文研究高层计算语义下的正确规范化，profile propagation 研究 LLVM CFG 上的动态信息迁移。前者以 Lean 证明语义不变，后者以 Hot-Order 实验衡量 profile 估计准确度；都属于传统编译器技术/基础设施，GPT-4o 仅是 profile 论文的一项比较方法，而非论文核心角色。

## 13. 一页式总结

论文提出并比较在编译优化中复用 profile 的两条路线：从当前 CFG 静态预测热路径，以及把参考 CFG profile 投影到新 CFG。指令直方图匹配稳定胜过哈希投影；GPT-4o 基线优于随机，但弱于 LLVM 静态启发式及经典投影。loop-rotate 是突出误差来源，histogram 投影在实验规模下耗时不足一分钟。证据支持排序准确率和算法可用性，尚不足以证明最终 PGO 运行时收益。
