#!/bin/bash
cd /mnt/c/Users/cjh/AI-compiler-RISCV-opt-lit/多平台自适应编译优化框架
python3 benchmarks/p0/driver/p0_driver.py --run-id p0-tsvc-20260718-001 --batch tsvc 2>&1 | tee /tmp/p0_tsvc_direct.txt
