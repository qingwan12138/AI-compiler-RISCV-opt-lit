# 28. neon2rvv: A Translator from ARM NEON Intrinsics to RISC-V Vector Extension.

> 主题分类：NEON 到 RVV 工程翻译器

## 阅读范围与证据边界

- 原始来源：[https://github.com/howjmay/neon2rvv](https://github.com/howjmay/neon2rvv)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\28-neon2rvv A Translator from ARM NEON Intrinsics to RISC-V Vector Extension`
- 本地 PDF 文件数：0；提取页数：0
- 阅读状态：源材料受限；已补充官方项目/规范页面

源材料受限；本地仅有 source.txt，另根据官方 GitHub README 补充阅读。

## 1. 研究问题与动机

需要把 AArch64 NEON intrinsic 代码快速转换成 RVV 代码，以便在 RISC-V 上运行和分析热点。

## 2. 方法与系统结构

官方 neon2rvv 是头文件级 translator，将部分 NEON intrinsic 映射为 RVV 等价实现；目标初期为 RV64、VLEN=128，使用 riscv64 GNU toolchain，并提供 Spike/QEMU 交叉编译测试。

## 3. 实验与主要发现

项目 README 说明其目标是缩短得到可运行 RISC-V 程序的时间，再用于 profiling/hot path 识别；它是工程工具而非学习方法。

## 4. 局限与批判性阅读

覆盖的 intrinsic 子集和语义边界有限；固定 VLEN=128 的初期目标不代表所有 RVV 硬件；本地没有仓库快照。

## 5. 对当前研究方向的关系

可作为规则式跨架构迁移基线，也可用于构造“规则可完成但性能不一定最优”的测试样本。

## 6. 可提炼的研究启发

与 IntrinTrans 对照，可以把规则映射、LLM 翻译和后端性能反馈三者区分开。

## 7. 一句话总结

与 IntrinTrans 对照，可以把规则映射、LLM 翻译和后端性能反馈三者区分开。
