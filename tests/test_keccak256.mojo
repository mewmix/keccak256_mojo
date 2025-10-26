from keccak.keccak256 import keccak256_bytes, keccak256_string, to_hex32
from tests._incremental_data import incremental_lengths, incremental_expected
from tests._fuzz_data import fuzz_lengths, fuzz_expected
from keccak.local_consts import MASK_64


fn assert_hex(label: String, got: String, expected: String) raises:
    if got != expected:
        raise Error(
            "[FAIL] " + label + ": expected " + expected + ", got " + got
        )


fn check_string(label: String, input: String, expected_hex: String) raises:
    var digest = keccak256_string(input)
    assert_hex(label, to_hex32(digest), expected_hex)


fn check_bytes(label: String, data: List[Int], length: Int, expected_hex: String) raises:
    var digest = keccak256_bytes(data, length)
    assert_hex(label, to_hex32(digest), expected_hex)


fn run_known_vectors() raises:
    check_string("empty", "", "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
    check_string("abc", "abc", "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")
    check_string(
        "quickfox/no_period",
        "The quick brown fox jumps over the lazy dog",
        "4d741b6f1eb29cb2a9b9911c82f56fa8d73b04959d3d9d222895df6c0b28aa15",
    )
    check_string(
        "quickfox/period",
        "The quick brown fox jumps over the lazy dog.",
        "578951e24efd62a3d63a86f7cd19aaa53c898fe287d2552133220370240b572d",
    )
    var sequential = [0] * 256
    for i in range(len(sequential)):
        sequential[i] = i
    check_bytes(
        "byte_range",
        sequential,
        len(sequential),
        "dc924469b334aed2a19fac7252e9961aea41f8d91996366029dbe0884229bf36",
    )
    var zeros512 = [0] * 512
    check_bytes(
        "zeros/512",
        zeros512,
        len(zeros512),
        "d5c44f659751a819616c58c9efe38e80f2b84cf621036da99c019bbe4f1fb647",
    )


fn run_incremental_vectors() raises:
    var lengths = incremental_lengths()
    var expected = incremental_expected()
    for idx in range(len(lengths)):
        var length = lengths[idx]
        var data = [0] * length
        for i in range(length):
            data[i] = i % 256
        var label = "incremental/" + String(length)
        check_bytes(label, data, length, expected[idx])


fn splitmix64_step(state: UInt64) -> UInt64:
    return (state + UInt64(0x9E3779B97F4A7C15)) & MASK_64


fn splitmix64_scramble(value: UInt64) -> UInt64:
    var z = value
    z = (z ^ (z >> UInt64(30))) & MASK_64
    z = (z * UInt64(0xBF58476D1CE4E5B9)) & MASK_64
    z = (z ^ (z >> UInt64(27))) & MASK_64
    z = (z * UInt64(0x94D049BB133111EB)) & MASK_64
    z = (z ^ (z >> UInt64(31))) & MASK_64
    return z


fn run_fuzz_vectors() raises:
    var lengths = fuzz_lengths()
    var expected = fuzz_expected()
    var buffer = [0] * 4096
    var state = UInt64(0x123456789ABCDEF0)

    for idx in range(len(expected)):
        var expected_hex = expected[idx]
        state = splitmix64_step(state)
        var next_val = splitmix64_scramble(state)
        var length = Int(next_val % UInt64(4097))
        if length != lengths[idx]:
            raise Error("fuzz length mismatch")
        if length > len(buffer):
            raise Error("fuzz length exceeds buffer")
        for i in range(length):
            state = splitmix64_step(state)
            buffer[i] = Int(splitmix64_scramble(state) & UInt64(0xFF))
        var label = "fuzz/" + String(idx)
        check_bytes(label, buffer, Int(length), expected_hex)


fn main() raises:
    run_known_vectors()
    run_incremental_vectors()
    run_fuzz_vectors()
    print("All vectors passed")
