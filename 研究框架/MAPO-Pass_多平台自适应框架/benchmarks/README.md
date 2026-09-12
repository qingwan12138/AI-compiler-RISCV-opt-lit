# MAPO-Pass benchmarks

`sources/llvm-test-suite` is a shallow, sparse checkout of the official LLVM
test-suite repository at commit `3396731658fc485536a2aa690b5eff7b3087df0b`.

The initial P0 subset uses PolyBench and TSVC. QEMU runs are correctness
checks only and must not be reported as real RISC-V performance.
