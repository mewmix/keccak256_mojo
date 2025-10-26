alias RATE = 136
alias LANES = 17  # RATE / 8
alias ROUNDS = 24
alias USE_UINT8_CORE = False
alias USE_POINTER_ABSORB = False
alias USE_UNROLLED_THETA_CHI = False

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

fn load_lane_ptr(ptr: UnsafePointer[UInt8]) -> UInt64:
    var v = UInt64(ptr[0])
    v |= UInt64(ptr[1]) << 8
    v |= UInt64(ptr[2]) << 16
    v |= UInt64(ptr[3]) << 24
    v |= UInt64(ptr[4]) << 32
    v |= UInt64(ptr[5]) << 40
    v |= UInt64(ptr[6]) << 48
    v |= UInt64(ptr[7]) << 56
    return v

fn keccak_f1600(mut s: List[UInt64]) -> None:
    var C = [UInt64(0)] * 5
    var D = [UInt64(0)] * 5
    var B = [UInt64(0)] * 25
    var RC = round_constants()
    var RHO = rho_offsets()

    for round in range(ROUNDS):
        @parameter
        if USE_UNROLLED_THETA_CHI:
            C[0] = s[0] ^ s[5] ^ s[10] ^ s[15] ^ s[20]
            C[1] = s[1] ^ s[6] ^ s[11] ^ s[16] ^ s[21]
            C[2] = s[2] ^ s[7] ^ s[12] ^ s[17] ^ s[22]
            C[3] = s[3] ^ s[8] ^ s[13] ^ s[18] ^ s[23]
            C[4] = s[4] ^ s[9] ^ s[14] ^ s[19] ^ s[24]

            D[0] = C[4] ^ rotl64(C[1], 1)
            D[1] = C[0] ^ rotl64(C[2], 1)
            D[2] = C[1] ^ rotl64(C[3], 1)
            D[3] = C[2] ^ rotl64(C[4], 1)
            D[4] = C[3] ^ rotl64(C[0], 1)

            s[0] = s[0] ^ D[0]
            s[5] = s[5] ^ D[0]
            s[10] = s[10] ^ D[0]
            s[15] = s[15] ^ D[0]
            s[20] = s[20] ^ D[0]

            s[1] = s[1] ^ D[1]
            s[6] = s[6] ^ D[1]
            s[11] = s[11] ^ D[1]
            s[16] = s[16] ^ D[1]
            s[21] = s[21] ^ D[1]

            s[2] = s[2] ^ D[2]
            s[7] = s[7] ^ D[2]
            s[12] = s[12] ^ D[2]
            s[17] = s[17] ^ D[2]
            s[22] = s[22] ^ D[2]

            s[3] = s[3] ^ D[3]
            s[8] = s[8] ^ D[3]
            s[13] = s[13] ^ D[3]
            s[18] = s[18] ^ D[3]
            s[23] = s[23] ^ D[3]

            s[4] = s[4] ^ D[4]
            s[9] = s[9] ^ D[4]
            s[14] = s[14] ^ D[4]
            s[19] = s[19] ^ D[4]
            s[24] = s[24] ^ D[4]
        else:
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

        @parameter
        if USE_UNROLLED_THETA_CHI:
            var b00 = B[0]
            var b01 = B[1]
            var b02 = B[2]
            var b03 = B[3]
            var b04 = B[4]
            s[0] = b00 ^ ((~b01) & b02)
            s[1] = b01 ^ ((~b02) & b03)
            s[2] = b02 ^ ((~b03) & b04)
            s[3] = b03 ^ ((~b04) & b00)
            s[4] = b04 ^ ((~b00) & b01)

            var b10 = B[5]
            var b11 = B[6]
            var b12 = B[7]
            var b13 = B[8]
            var b14 = B[9]
            s[5] = b10 ^ ((~b11) & b12)
            s[6] = b11 ^ ((~b12) & b13)
            s[7] = b12 ^ ((~b13) & b14)
            s[8] = b13 ^ ((~b14) & b10)
            s[9] = b14 ^ ((~b10) & b11)

            var b20 = B[10]
            var b21 = B[11]
            var b22 = B[12]
            var b23 = B[13]
            var b24 = B[14]
            s[10] = b20 ^ ((~b21) & b22)
            s[11] = b21 ^ ((~b22) & b23)
            s[12] = b22 ^ ((~b23) & b24)
            s[13] = b23 ^ ((~b24) & b20)
            s[14] = b24 ^ ((~b20) & b21)

            var b30 = B[15]
            var b31 = B[16]
            var b32 = B[17]
            var b33 = B[18]
            var b34 = B[19]
            s[15] = b30 ^ ((~b31) & b32)
            s[16] = b31 ^ ((~b32) & b33)
            s[17] = b32 ^ ((~b33) & b34)
            s[18] = b33 ^ ((~b34) & b30)
            s[19] = b34 ^ ((~b30) & b31)

            var b40 = B[20]
            var b41 = B[21]
            var b42 = B[22]
            var b43 = B[23]
            var b44 = B[24]
            s[20] = b40 ^ ((~b41) & b42)
            s[21] = b41 ^ ((~b42) & b43)
            s[22] = b42 ^ ((~b43) & b44)
            s[23] = b43 ^ ((~b44) & b40)
            s[24] = b44 ^ ((~b40) & b41)
        else:
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

    @parameter
    if USE_UINT8_CORE:
        var bytes = [UInt8(0)] * length
        for i in range(length):
            bytes[i] = UInt8(data[i] & 0xFF)

        while offset + RATE <= length:
            @parameter
            if USE_POINTER_ABSORB:
                var lane_ptr = UnsafePointer(to=bytes[offset])
                for lane in range(LANES):
                    state[lane] = state[lane] ^ load_lane_ptr(lane_ptr)
                    lane_ptr = lane_ptr.offset(8)
            else:
                var base = offset
                for lane in range(LANES):
                    var v = UInt64(bytes[base + 0])
                    v |= UInt64(bytes[base + 1]) << 8
                    v |= UInt64(bytes[base + 2]) << 16
                    v |= UInt64(bytes[base + 3]) << 24
                    v |= UInt64(bytes[base + 4]) << 32
                    v |= UInt64(bytes[base + 5]) << 40
                    v |= UInt64(bytes[base + 6]) << 48
                    v |= UInt64(bytes[base + 7]) << 56
                    state[lane] = state[lane] ^ v
                    base += 8
            keccak_f1600(state)
            offset += RATE

        var rem = length - offset
        var block = [UInt8(0)] * RATE
        for i in range(rem):
            block[i] = bytes[offset + i]
        block[rem] = UInt8(0x01)
        block[RATE - 1] = block[RATE - 1] ^ UInt8(0x80)

        @parameter
        if USE_POINTER_ABSORB:
            var lane_ptr = UnsafePointer(to=block[0])
            for lane in range(LANES):
                state[lane] = state[lane] ^ load_lane_ptr(lane_ptr)
                lane_ptr = lane_ptr.offset(8)
        else:
            var base = 0
            for lane in range(LANES):
                var v = UInt64(block[base + 0])
                v |= UInt64(block[base + 1]) << 8
                v |= UInt64(block[base + 2]) << 16
                v |= UInt64(block[base + 3]) << 24
                v |= UInt64(block[base + 4]) << 32
                v |= UInt64(block[base + 5]) << 40
                v |= UInt64(block[base + 6]) << 48
                v |= UInt64(block[base + 7]) << 56
                state[lane] = state[lane] ^ v
                base += 8
        keccak_f1600(state)
    else:
        while offset + RATE <= length:
            for lane in range(LANES):
                var base = offset + lane * 8
                var v = UInt64(0)
                v |= UInt64(data[base + 0] & 0xFF) << 0
                v |= UInt64(data[base + 1] & 0xFF) << 8
                v |= UInt64(data[base + 2] & 0xFF) << 16
                v |= UInt64(data[base + 3] & 0xFF) << 24
                v |= UInt64(data[base + 4] & 0xFF) << 32
                v |= UInt64(data[base + 5] & 0xFF) << 40
                v |= UInt64(data[base + 6] & 0xFF) << 48
                v |= UInt64(data[base + 7] & 0xFF) << 56
                state[lane] = state[lane] ^ v
            keccak_f1600(state)
            offset += RATE

        var rem = length - offset
        var block = [0] * RATE
        for i in range(rem):
            block[i] = data[offset + i] & 0xFF
        block[rem] = 0x01
        block[RATE - 1] ^= 0x80

        for lane in range(LANES):
            var base = lane * 8
            var v = UInt64(0)
            v |= UInt64(block[base + 0]) << 0
            v |= UInt64(block[base + 1]) << 8
            v |= UInt64(block[base + 2]) << 16
            v |= UInt64(block[base + 3]) << 24
            v |= UInt64(block[base + 4]) << 32
            v |= UInt64(block[base + 5]) << 40
            v |= UInt64(block[base + 6]) << 48
            v |= UInt64(block[base + 7]) << 56
            state[lane] = state[lane] ^ v
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
