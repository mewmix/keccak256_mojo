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
   cd keccak256_mojo
   pixi install
   pixi shell
   ```
3. Confirm Mojo is available inside the environment:
   ```bash
   mojo --version
   ```

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

## Benchmarks

Microbenchmarks comparing this implementation with [`eth-hash`](https://github.com/ethereum/eth-hash)
and [`pycryptodome`](https://pycryptodome.readthedocs.io/en/latest/) are available under
`benchmarks/`. The default task prints a single table containing both Python baselines and the
Mojo JIT/compiled timings (the Mojo programs handle their own timing internally).

```bash
# Activate the Pixi environment first
pixi run bench

# JSON output for automation
pixi run bench:json

# Python-only baselines
pixi run bench:python
pixi run bench:python-json

# Mojo-only entries
pixi run bench:mojo-jit
pixi run bench:mojo-compiled
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
