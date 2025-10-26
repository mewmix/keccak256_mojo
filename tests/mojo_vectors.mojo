from keccak.keccak256 import keccak256_bytes

def to_hex(b: List[Int]) -> String:
    var HEX: List[String] = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"]
    var out = String()
    for v in b:
        var hi = (v >> 4) & 0xF
        var lo = v & 0xF
        out += HEX[Int(hi)]
        out += HEX[Int(lo)]
    return out

def bytes_to_hex(xs: List[Int], n: Int) -> String:
    var HEX: List[String] = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"]
    var out = String()
    var i = 0
    while i < n:
        var v = xs[i] & 0xFF
        var hi = (v >> 4) & 0xF
        var lo = v & 0xF
        out += HEX[Int(hi)]
        out += HEX[Int(lo)]
        i += 1
    return out

def gen_pattern(n: Int) -> List[Int]:
    # deterministic pattern: (i*31 + 7) mod 256
    var out = [0] * n
    var i = 0
    while i < n:
        out[i] = ((i * 31) + 7) & 0xFF
        i += 1
    return ^out   # move, not copy

def print_case(data: List[Int], n: Int):
    var hex_in = bytes_to_hex(data, n)
    var digest = keccak256_bytes(data, n)  # returns List[Int]
    var hex_out = to_hex(digest)           # digest moved into to_hex; not reused
    print(hex_in + " " + hex_out)

def main():
    # 0: empty
    var empty: List[Int] = []
    print_case(empty, 0)

    # 1: "abc"
    var abc: List[Int] = [0x61, 0x62, 0x63]
    print_case(abc, 3)

    # 2: exactly one rate block (136 bytes)
    var r136 = gen_pattern(136)
    print_case(r136, 136)

    # 3: cross rate boundary (137 bytes)
    var r137 = gen_pattern(137)
    print_case(r137, 137)

    # 4: long (1000 bytes)
    var long = gen_pattern(1000)
    print_case(long, 1000)

