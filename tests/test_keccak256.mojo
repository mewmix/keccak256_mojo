from keccak.keccak256 import keccak256_string

fn to_hex32(d: [UInt8; 32]) -> String:
    let lut = "0123456789abcdef"
    var s = ""
    for i in range(32):
        let v = int(d[i])
        s += lut[(v >> 4)]
        s += lut[v & 15]
    return s

fn check(input: String, expected_hex: String):
    let h = keccak256_string(input)
    let got = to_hex32(h)
    print(input, " -> ", got, " | OK=", got == expected_hex)

fn main():
    check("",   "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
    check("abc","4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")
