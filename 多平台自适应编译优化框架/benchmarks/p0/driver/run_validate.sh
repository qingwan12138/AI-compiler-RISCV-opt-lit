#!/bin/bash
# Run P0 validation from within WSL2
cd /mnt/c/Users/cjh/AI-compiler-RISCV-opt-lit/多平台自适应编译优化框架
python3 benchmarks/p0/driver/p0_validate.py 2>&1 | tee /tmp/p0_validate_output.txt
