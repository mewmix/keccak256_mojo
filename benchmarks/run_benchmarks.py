#!/usr/bin/env python3
"""Microbenchmarks comparing Mojo, eth-hash, and PyCryptodome implementations."""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from functools import lru_cache
from pathlib import Path
from typing import Callable, Dict, Iterable, List

# Benchmark parameters shared with the Mojo driver. Keep these in sync with the
# constants defined in ``benchmarks/mojo_benchmark.mojo``.
NUM_MESSAGES = 512
ROUNDS = 200
BASE_LENGTH = 32
MAX_LENGTH = 512
LENGTH_STRIDE = 31


def _message_length(index: int) -> int:
    span = MAX_LENGTH - BASE_LENGTH + 1
    return BASE_LENGTH + (index * LENGTH_STRIDE) % span


def _make_message(index: int) -> bytes:
    length = _message_length(index)
    return bytes((index + offset) % 256 for offset in range(length))


def _iter_messages() -> Iterable[bytes]:
    for idx in range(NUM_MESSAGES):
        yield _make_message(idx)


HashFn = Callable[[bytes], int]


def _warm_up(hash_fn: HashFn, rounds: int = 3) -> None:
    for _ in range(rounds):
        for msg in _iter_messages():
            _ = hash_fn(msg)


def _run_python_bench(name: str, hash_fn: HashFn) -> Dict[str, float]:
    total_hashes = NUM_MESSAGES * ROUNDS
    _warm_up(hash_fn)
    start = time.perf_counter()
    checksum = 0
    for _ in range(ROUNDS):
        for msg in _iter_messages():
            checksum ^= hash_fn(msg)
    elapsed = time.perf_counter() - start
    return {
        "implementation": name,
        "seconds": elapsed,
        "hashes_per_second": total_hashes / elapsed,
        "checksum": checksum,
    }


def _require_module(module: str) -> None:
    try:
        __import__(module)
    except ModuleNotFoundError as exc:  # pragma: no cover - import guard
        raise SystemExit(
            f"Missing optional dependency '{module}'. Install via `pixi install` "
            "or `pip install` before running the benchmarks."
        ) from exc


def bench_pycryptodome() -> Dict[str, float]:
    _require_module("Crypto")
    from Crypto.Hash import keccak

    def _digest(msg: bytes) -> int:
        return keccak.new(digest_bits=256, data=msg).digest()[0]

    return _run_python_bench("pycryptodome", _digest)


def bench_eth_hash() -> Dict[str, float]:
    _require_module("eth_hash")
    from eth_hash.auto import keccak

    def _digest(msg: bytes) -> int:
        return keccak(msg)[0]

    return _run_python_bench("eth-hash", _digest)


@lru_cache(maxsize=1)
def _mojo_cmd() -> str:
    mojo = shutil.which("mojo")
    if mojo is None:
        raise SystemExit(
            "Unable to locate the `mojo` CLI. Activate your Pixi environment or "
            "install Mojo before benchmarking."
        )
    subprocess.run([mojo, "--version"], check=True)
    return mojo


@lru_cache(maxsize=1)
def _mojo_supports_opt_flag() -> bool:
    mojo = _mojo_cmd()
    help_cmd = [mojo, "build", "--help"]
    proc = subprocess.run(help_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = (proc.stdout or "") + (proc.stderr or "")
    return "--opt" in output


def bench_mojo_interpreted(root: Path) -> Dict[str, float]:
    mojo = _mojo_cmd()
    target = root / "benchmarks" / "mojo_benchmark.mojo"
    total_hashes = NUM_MESSAGES * ROUNDS
    warmup_cmd = [mojo, "-I", str(root), str(target)]
    subprocess.run(warmup_cmd, check=True)
    start = time.perf_counter()
    subprocess.run(warmup_cmd, check=True)
    elapsed = time.perf_counter() - start
    return {
        "implementation": "mojo (jit)",
        "seconds": elapsed,
        "hashes_per_second": total_hashes / elapsed,
        "checksum": None,
    }


def bench_mojo_compiled(root: Path, build_dir: Path) -> Dict[str, float]:
    mojo = _mojo_cmd()
    target = root / "benchmarks" / "mojo_benchmark.mojo"
    build_dir.mkdir(parents=True, exist_ok=True)
    binary = build_dir / "mojo_keccak_bench"

    compile_cmd = [
        mojo,
        "build",
        "-I",
        str(root),
        str(target),
        "-o",
        str(binary),
    ]
    if _mojo_supports_opt_flag():
        compile_cmd.append("--opt=3")
    subprocess.run(compile_cmd, check=True)

    total_hashes = NUM_MESSAGES * ROUNDS
    start = time.perf_counter()
    subprocess.run([str(binary)], check=True)
    elapsed = time.perf_counter() - start
    return {
        "implementation": "mojo (compiled)",
        "seconds": elapsed,
        "hashes_per_second": total_hashes / elapsed,
        "checksum": None,
    }


def format_results(results: List[Dict[str, float]]) -> str:
    headers = ("implementation", "seconds", "hashes/s", "checksum")
    lines = [" | ".join(headers)]
    lines.append(" | ".join("-" * len(h) for h in headers))
    for result in results:
        lines.append(
            " | ".join(
                [
                    result["implementation"],
                    f"{result['seconds']:.6f}",
                    f"{result['hashes_per_second']:.2f}",
                    "-" if result["checksum"] is None else str(result["checksum"]),
                ]
            )
        )
    return "\n".join(lines)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-mojo",
        action="store_true",
        help="Skip both Mojo benchmarks.",
    )
    parser.add_argument(
        "--skip-jit",
        action="store_true",
        help="Skip the Mojo JIT/interpreted benchmark.",
    )
    parser.add_argument(
        "--skip-compiled",
        action="store_true",
        help="Skip the Mojo compiled benchmark.",
    )
    parser.add_argument(
        "--skip-eth-hash",
        action="store_true",
        help="Skip the eth-hash baseline.",
    )
    parser.add_argument(
        "--skip-pycryptodome",
        action="store_true",
        help="Skip the PyCryptodome baseline.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit benchmark results as JSON instead of a table.",
    )
    parser.add_argument(
        "--build-dir",
        default=".bench-build",
        help="Directory for compiled Mojo artifacts (default: .bench-build).",
    )
    args = parser.parse_args(argv)

    root = Path(__file__).resolve().parents[1]
    results: List[Dict[str, float]] = []

    if not args.skip_eth_hash:
        results.append(bench_eth_hash())
    if not args.skip_pycryptodome:
        results.append(bench_pycryptodome())

    if not args.skip_mojo:
        if not args.skip_jit:
            results.append(bench_mojo_interpreted(root))
        if not args.skip_compiled:
            build_dir = root / args.build_dir
            results.append(bench_mojo_compiled(root, build_dir))

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print(format_results(results))
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    sys.exit(main())
