# 36. Ansor: Generating High-Performance Tensor Programs for Deep Learning. OSDI 2020.

> 主题分类：张量程序分层搜索

## 阅读范围与证据边界

- 原始来源：[https://www.usenix.org/conference/osdi20/presentation/zheng](https://www.usenix.org/conference/osdi20/presentation/zheng)
- 本地条目目录：`C:\Users\2025111355\Desktop\文献\AI编译器与RISC-V优化相关文献\36-Ansor Generating High-Performance Tensor Programs for Deep Learning. OSDI 2020`
- 本地 PDF 文件数：1；提取页数：18
- 阅读状态：完整 PDF 阅读

完整 PDF，18 页；重点依据搜索空间、cost model、scheduler、评价和局限。

## 1. 研究问题与动机

现有张量程序搜索空间过度依赖手工模板或过早剪枝，容易遗漏有效的优化组合；多子图网络还需要任务级调度。

## 2. 方法与系统结构

Ansor 用 hierarchical search-space representation 自动生成 program sketches，再用随机 annotation、evolutionary search 和 learned cost model 微调；task scheduler 同时在多个 subgraph 之间分配搜索资源。

## 3. 实验与主要发现

相对已有方案，报告 Intel CPU、ARM CPU、NVIDIA GPU 上最高约 3.8x、2.6x、1.7x 的端到端性能提升，并能找到既有搜索空间之外的程序。

## 4. 局限与批判性阅读

面向 tensor program；依赖 schedule 规则、cost model 和测量；不直接处理通用 LLVM IR Pass 序列、程序语义验证或 LLM 迁移。

## 5. 对当前研究方向的关系

它是“分层动作空间+硬件感知搜索+预算调度”的强基线，能帮助设计 Backend Agent 的搜索层和评测预算。

## 6. 可提炼的研究启发

分层并不等于双智能体；真正可借鉴的是用高层结构缩小低层搜索并按信息价值分配测量。

## 7. 一句话总结

分层并不等于双智能体；真正可借鉴的是用高层结构缩小低层搜索并按信息价值分配测量。
