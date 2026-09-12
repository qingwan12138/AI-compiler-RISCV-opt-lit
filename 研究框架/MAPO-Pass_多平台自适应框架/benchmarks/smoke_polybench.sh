#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_root="$script_dir/sources/llvm-test-suite/SingleSource/Benchmarks/Polybench"
build_root="$script_dir/build/smoke"

common_flags=(
  -O2
  -DSMALL_DATASET
  -DPOLYBENCH_DUMP_ARRAYS
  -DFP_ABSTOLERANCE=1e-5
  -I "$source_root/utilities"
)
riscv_flags=(
  --target=riscv64-linux-gnu
  --gcc-toolchain=/usr
  --ld-path=/usr/bin/riscv64-linux-gnu-ld
)

benchmarks=(
  "gemm:linear-algebra/blas/gemm/gemm.c"
  "atax:linear-algebra/kernels/atax/atax.c"
  "jacobi-2d:stencils/jacobi-2d/jacobi-2d.c"
  "correlation:datamining/correlation/correlation.c"
)

mkdir -p "$build_root"
printf 'benchmark\tx86_sha256\triscv_sha256\tstatus\n'

for entry in "${benchmarks[@]}"; do
  name="${entry%%:*}"
  relative_source="${entry#*:}"
  source_file="$source_root/$relative_source"
  x86_binary="$build_root/$name-x86"
  riscv_binary="$build_root/$name-riscv64"
  x86_output="$build_root/$name-x86.out"
  riscv_output="$build_root/$name-riscv64.out"

  clang "${common_flags[@]}" "$source_file" -lm -o "$x86_binary"
  clang "${riscv_flags[@]}" "${common_flags[@]}" "$source_file" -lm -o "$riscv_binary"

  "$x86_binary" 2>"$x86_output"
  QEMU_LD_PREFIX=/usr/riscv64-linux-gnu qemu-riscv64 "$riscv_binary" 2>"$riscv_output"

  x86_hash="$(sha256sum "$x86_output" | cut -d ' ' -f 1)"
  riscv_hash="$(sha256sum "$riscv_output" | cut -d ' ' -f 1)"
  status=match
  if [[ "$x86_hash" != "$riscv_hash" ]]; then
    status=mismatch
  fi

  printf '%s\t%s\t%s\t%s\n' "$name" "$x86_hash" "$riscv_hash" "$status"
done
