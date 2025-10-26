alias RATE = 136

fn round_constants() -> List[UInt64]:
    return [
        UInt64(0x0000000000000001), UInt64(0x0000000000008082),
        UInt64(0x800000000000808A), UInt64(0x8000000080008000),
        UInt64(0x000000000000808B), UInt64(0x0000000080000001),
        UInt64(0x8000000080008081), UInt64(0x8000000000008009),
        UInt64(0x000000000000008A), UInt64(0x0000000000000088),
        UInt64(0x0000000080008009), UInt64(0x000000008000000A),
        UInt64(0x000000008000808B), UInt64(0x800000000000008B),
        UInt64(0x8000000000008089), UInt64(0x8000000000008003),
        UInt64(0x8000000000008002), UInt64(0x8000000000000080),
        UInt64(0x000000000000800A), UInt64(0x800000008000000A),
        UInt64(0x8000000080008081), UInt64(0x8000000000008080),
        UInt64(0x0000000080000001), UInt64(0x8000000080008008),
    ]

fn rho_offsets() -> List[List[Int]]:
    return [
        [0, 36, 3, 41, 18],
        [1, 44, 10, 45, 2],
        [62, 6, 43, 15, 61],
        [28, 55, 25, 21, 56],
        [27, 20, 39, 8, 14],
    ]

fn to_hex32(d: List[Int]) -> String:
    var lut = "0123456789abcdef"
    var out = ""
    for v in d:
        var b = v & 0xFF
        out += lut[(b >> 4) & 0xF]
        out += lut[b & 0xF]
    return out

fn rotl64(x: UInt64, n: Int) -> UInt64:
    var k = n % 64
    if k == 0:
        return x
    var shift = UInt64(k)
    return (x << shift) | (x >> UInt64(64 - k))

fn keccak_f1600(mut s: List[UInt64]) -> None:
    var RC = round_constants()
    var RHO = rho_offsets()
    var C = [UInt64(0)] * 5
    var D = [UInt64(0)] * 5
    var B = [UInt64(0)] * 25

    for round in range(24):
        for x in range(5):
            C[x] = s[x] ^ s[x + 5] ^ s[x + 10] ^ s[x + 15] ^ s[x + 20]
        for x in range(5):
            D[x] = C[(x + 4) % 5] ^ rotl64(C[(x + 1) % 5], 1)
        for i in range(25):
            s[i] = s[i] ^ D[i % 5]

        for x in range(5):
            for y in range(5):
                var idx = x + 5 * y
                var new_idx = y + 5 * ((2 * x + 3 * y) % 5)
                B[new_idx] = rotl64(s[idx], RHO[x][y])

        for y in range(0, 25, 5):
            var b0 = B[y + 0]
            var b1 = B[y + 1]
            var b2 = B[y + 2]
            var b3 = B[y + 3]
            var b4 = B[y + 4]
            s[y + 0] = b0 ^ ((~b1) & b2)
            s[y + 1] = b1 ^ ((~b2) & b3)
            s[y + 2] = b2 ^ ((~b3) & b4)
            s[y + 3] = b3 ^ ((~b4) & b0)
            s[y + 4] = b4 ^ ((~b0) & b1)

        s[0] = s[0] ^ RC[round]

fn keccak256_bytes(data: List[Int], length: Int) -> List[Int]:
    var state = [UInt64(0)] * 25
    var offset = 0

    while offset + RATE <= length:
        for i in range(RATE):
            var lane = i // 8
            var shift = (i % 8) * 8
            var byte_val = UInt64(data[offset + i] & 0xFF)
            state[lane] = state[lane] ^ (byte_val << UInt64(shift))
        keccak_f1600(state)
        offset += RATE

    var rem = length - offset
    var block = [0] * RATE
    for i in range(rem):
        block[i] = data[offset + i] & 0xFF
    block[rem] = 0x01
    block[RATE - 1] ^= 0x80

    for i in range(RATE):
        var lane = i // 8
        var shift = (i % 8) * 8
        var block_byte = UInt64(block[i])
        state[lane] = state[lane] ^ (block_byte << UInt64(shift))
    keccak_f1600(state)

    var out = [0] * 32
    for i in range(32):
        var lane_val = state[i // 8]
        out[i] = Int((lane_val >> UInt64((i % 8) * 8)) & UInt64(0xFF))
    return out.copy()



fn keccak256_string(input: String) -> List[Int]:
    var data = [0] * len(input)
    var idx = 0
    for cp in input.codepoints():   # <-- fixed
        data[idx] = Int(cp)
        idx += 1
    return keccak256_bytes(data, len(data))

fn keccak256_hex_string(input: String) -> String:
    return to_hex32(keccak256_string(input))
