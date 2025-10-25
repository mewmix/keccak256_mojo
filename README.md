# Keccak-256 in Mojo

A pure Mojo implementation of the Keccak-256 hash along with a self-contained
test harness and reproducible test vectors.

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

## Usage

You can import the package from Mojo code by adding the repository root to the
include path:

```bash
mojo -I . -e 'from keccak.keccak256 import keccak256_string; print(keccak256_string("abc"))'
```

Within a Mojo module or script:

```mojo
from keccak.keccak256 import keccak256_bytes, keccak256_string

let digest_from_str = keccak256_string("abc")
let bytes_input: List[Int] = [0, 1, 2]
let digest_from_bytes = keccak256_bytes(bytes_input, len(bytes_input))
```

Both helpers return a `List[Int]` containing the 32-byte digest in little-endian
byte order, matching Ethereum's Keccak-256 variant.
