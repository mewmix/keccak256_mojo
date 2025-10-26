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
  `keccak256_bytes` and `keccak256_string` helpers for byte buffers or UTF-8
  strings respectively.

## Benchmarks

Microbenchmarks comparing this implementation with [`eth-hash`](https://github.com/ethereum/eth-hash)
and [`pycryptodome`](https://pycryptodome.readthedocs.io/en/latest/) are available under
`benchmarks/`.

```bash
# Activate the Pixi environment first
pixi run python benchmarks/run_benchmarks.py

# Emit JSON or skip specific implementations if desired
pixi run python benchmarks/run_benchmarks.py --json --skip-jit
```

By default the script runs both the Mojo JIT invocation and a compiled binary produced via
`mojo build`. Compiled artifacts are stored in `.bench-build/`.

## Usage
 
Example [main.mojo](https://github.com/mewmix/keccak256_mojo/blob/main/main.mojo):

```mojo
from keccak.keccak256 import keccak256_string, to_hex32

def main():
    var d = keccak256_string("abc")
    print(to_hex32(d))
```
## Run within Pixi Shell 
```bash
mojo main.mojo
```
