# Keccak-256 in Mojo
[![CI](https://github.com/mewmix/keccak256_mojo/actions/workflows/blank.yml/badge.svg?branch=main)](https://github.com/mewmix/keccak256_mojo/actions/workflows/blank.yml)

A pure Mojo implementation of the Keccak-256 hash for educational purposes.

## Installation

1. Install [Pixi](https://pixi.sh/latest/) if you have not already:
   ```bash
   curl -fsSL https://pixi.sh/install.sh | sh
   ```
2. Create or activate the environment:
   ```bash
   git clone https://github.com/mewmix/keccak256_mojo/
   cd keccak256_mojo
   pixi install
   pixi shell
   ```
3. Confirm Mojo is available inside the environment:
   ```bash
   mojo --version
   ```

### Native toolchains for baselines

`pixi install` automatically provisions the exact versions of all necessary toolchains, including `mojo`, `rust`, `cargo`, `clang` (C compiler), `zig`, and `python`. You do not need to install anything globally!

## Development

* Run the full test suite (known, incremental, and fuzz vectors):
  ```bash
  pixi run test
  ```
* Alternatively, invoke the harness directly if you already have Mojo on the
  `PATH`:
  ```bash
  mojo -I . tests/test_keccak256.mojo
  ```
* The implementation lives in `keccak/keccak256.mojo`; the module exports
  `keccak256_bytes`, `keccak256_string`, and `keccak256_hex_string` helpers for
  byte buffers or UTF-8 strings respectively.

### Native baseline smoke tests

Lightweight C and Rust programs are included to validate the third-party
implementations used for benchmarking.

```bash
# Rust baseline
(cd benchmarks/rust && cargo test)

# C baseline
cc -std=c11 -O2 benchmarks/c/keccak256.c benchmarks/c/test_keccak256.c -o benchmarks/c/test_keccak256
benchmarks/c/test_keccak256
```

Compiled artifacts live alongside the sources—see `.gitignore` for the list of
ignored binaries so they do not end up in commits.

## Benchmarks

Microbenchmarks comparing this implementation with [`eth-hash`](https://github.com/ethereum/eth-hash),
[`pycryptodome`](https://pycryptodome.readthedocs.io/en/latest/),
the C tiny_sha3 port, and a Rust `tiny-keccak` baseline are available under
`benchmarks/`. Every baseline is timed with the same message schedule, warm-up, and
iteration counts to keep the comparison fair.

```bash
# Activate the Pixi environment first
pixi run bench

# JSON output for automation
pixi run bench:json

# Run baselines with native CPU optimizations (-mcpu=native / apple-m1)
pixi run bench:native

# Run the multi-threaded selector collision brute-force workload (Mojo vs Zig)
pixi run bench:bruteforce

# Python-only baselines
pixi run bench:python
pixi run bench:python-json

# Mojo-only entries
pixi run bench:mojo-jit
pixi run bench:mojo-compiled

# Native-only generic baselines
python benchmarks/run_full_benchmarks.py --skip-eth-hash --skip-pycryptodome --skip-mojo-jit --skip-mojo-compiled
python benchmarks/run_full_benchmarks.py --skip-eth-hash --skip-pycryptodome --skip-mojo-jit --skip-mojo-compiled --json
```

To exercise the native benchmark drivers directly:

```bash
# C baseline (writes results to .bench-build/ by default)
cc -std=c11 -O3 benchmarks/c/keccak256.c benchmarks/c/bench_keccak256.c -o .bench-build/c_keccak_bench
.bench-build/c_keccak_bench --json

# Rust baseline
(cd benchmarks/rust && cargo run --release --bin bench -- --json)
```

Pass `--json` directly to `benchmarks/mojo_benchmark.mojo` if you prefer machine-readable Mojo
output. Compiled artifacts land in `.bench-build/` when using the compiled task. Benchmarks are super noisy, and we are battling the most legendary and highly optimized C backends so don't expect any remarkable numbers anytime soon.

## Usage
 
Example [main.mojo](https://github.com/mewmix/keccak256_mojo/blob/main/main.mojo):

```mojo
from keccak.keccak256 import keccak256_hex_string

def main():
    print(keccak256_hex_string("abc"))
```
## Run within Pixi Shell 
```bash
mojo main.mojo
```
