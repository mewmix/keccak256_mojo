from keccak.keccak256 import keccak256_bytes
import time
from sys import argv

alias NUM_MESSAGES = 512
alias ROUNDS = 200
alias BASE_LENGTH = 32
alias MAX_LENGTH = 512
alias LENGTH_STRIDE = 31


fn message_length(index: Int) -> Int:
    var span = MAX_LENGTH - BASE_LENGTH + 1
    return BASE_LENGTH + ((index * LENGTH_STRIDE) % span)


fn generate_message(index: Int) -> List[Int]:
    var length = message_length(index)
    var data = [0] * length
    for offset in range(length):
        data[offset] = (index + offset) % 256
    return data.copy()


fn warm_up(rounds: Int = 3) -> Int:
    var checksum = 0
    for _ in range(rounds):
        for idx in range(NUM_MESSAGES):
            var message = generate_message(idx)
            var digest = keccak256_bytes(message, len(message))
            checksum ^= digest[0]
    return checksum


struct BenchmarkResult:
    var seconds: Float64
    var checksum: Int

    fn __init__(out self, seconds: Float64 = 0.0, checksum: Int = 0):
        self.seconds = seconds
        self.checksum = checksum


fn run_benchmark() -> BenchmarkResult:
    var checksum = warm_up()
    var start = time.perf_counter()
    for _ in range(ROUNDS):
        for idx in range(NUM_MESSAGES):
            var message = generate_message(idx)
            var digest = keccak256_bytes(message, len(message))
            checksum ^= digest[0]
    var elapsed = time.perf_counter() - start
    return BenchmarkResult(seconds=elapsed, checksum=checksum)


fn float_to_string(value: Float64) -> String:
    return String(value)


fn int_to_string(value: Int) -> String:
    return String(value)


def main():
    var label = "mojo"
    var emit_json = False
    var expect_label = False
    var first = True
    for raw_arg in argv():
        if first:
            first = False
            continue
        var arg = String(raw_arg)
        if expect_label:
            label = arg
            expect_label = False
            continue
        if arg == "--json":
            emit_json = True
        elif arg == "--label":
            expect_label = True

    var result = run_benchmark()
    var seconds = result.seconds
    var checksum = result.checksum
    if seconds < 0.0:
        seconds = 0.0
    var total_hashes = NUM_MESSAGES * ROUNDS
    var throughput = Float64(total_hashes)
    if seconds > 0.0:
        throughput = throughput / seconds
    else:
        throughput = 0.0

    if emit_json:
        var json = "{"
        json += "\"implementation\": \"" + label + "\", "
        json += "\"seconds\": " + float_to_string(seconds) + ", "
        json += "\"hashes_per_second\": " + float_to_string(throughput) + ", "
        json += "\"checksum\": " + int_to_string(checksum)
        json += "}"
        print(json)
    else:
        print("implementation | seconds | hashes/s | checksum")
        print("-------------- | ------- | -------- | --------")
        var line = label
        line += " | "
        line += float_to_string(seconds)
        line += " | "
        line += float_to_string(throughput)
        line += " | "
        line += int_to_string(checksum)
        print(line)
