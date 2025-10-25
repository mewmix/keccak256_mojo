from keccak.keccak256 import keccak256_bytes, keccak256_string
from tests._incremental_data import INCREMENTAL_LENGTHS, INCREMENTAL_EXPECTED
from tests._fuzz_data import FUZZ_LENGTHS, FUZZ_EXPECTED

fn to_hex32(d: [UInt8; 32]) -> String:
    let lut = "0123456789abcdef"
    var s = ""
    for i in range(32):
        let v = Int(d[i])
        s += lut[(v >> 4)]
        s += lut[v & 15]
    return s

fn assert_hex(label: String, got: String, expected: String):
    if got != expected:
        print("[FAIL] ", label, ": expected ", expected, ", got ", got)
        raise Exception("vector mismatch")

fn check_string(label: String, input: String, expected_hex: String):
    let h = keccak256_string(input)
    let got = to_hex32(h)
    assert_hex(label, got, expected_hex)

fn check_bytes(label: String, data: Pointer[UInt8], length: Int, expected_hex: String):
    let h = keccak256_bytes(data, length)
    let got = to_hex32(h)
    assert_hex(label, got, expected_hex)

fn run_known_vectors():
    check_string("empty", "", "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
    check_string("abc", "abc", "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")

fn run_incremental_vectors():
    var buffer: [UInt8; 1000] = [UInt8(0)] * 1000
    for idx in range(len(INCREMENTAL_LENGTHS)):
        let length = INCREMENTAL_LENGTHS[idx]
        for i in range(length):
            buffer[i] = UInt8(i % 256)
        let label = "incremental/" + String(length)
        check_bytes(label, Pointer[UInt8](&buffer[0]), length, INCREMENTAL_EXPECTED[idx])

fn splitmix64_next(state: inout UInt64) -> UInt64:
    state = state + UInt64(0x9E3779B97F4A7C15)
    var z = state
    z ^= z >> 30
    z = z * UInt64(0xBF58476D1CE4E5B9)
    z ^= z >> 27
    z = z * UInt64(0x94D049BB133111EB)
    z ^= z >> 31
    return z

fn run_fuzz_vectors():
    var buffer: [UInt8; 4096] = [UInt8(0)] * 4096
    var state: UInt64 = 0x123456789ABCDEF0
    for idx in range(len(FUZZ_EXPECTED)):
        let next_val = splitmix64_next(state)
        let length = Int(next_val % UInt64(4097))
        if length != FUZZ_LENGTHS[idx]:
            raise Exception("fuzz length mismatch")
        if length > len(buffer):
            raise Exception("fuzz length exceeds buffer")
        for i in range(length):
            let value = splitmix64_next(state)
            buffer[i] = UInt8(value & 0xFF)
        let label = "fuzz/" + String(idx)
        check_bytes(label, Pointer[UInt8](&buffer[0]), length, FUZZ_EXPECTED[idx])

fn main():
    run_known_vectors()
    run_incremental_vectors()
    run_fuzz_vectors()
    print("All vectors passed")
