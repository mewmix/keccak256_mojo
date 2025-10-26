alias RATE = 136
alias LANES = 17  # RATE / 8
alias ROUNDS = 24
alias USE_UINT8_CORE = False
alias USE_POINTER_ABSORB = False
alias USE_UNROLLED_THETA_CHI = True
alias USE_UNROLLED_ABSORB = True

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
    if n == 0:
        return x
    var shift = UInt64(n)
    var inv = UInt64(64 - n)
    return (x << shift) | (x >> inv)

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

        @parameter
        if USE_UNROLLED_THETA_CHI:
            B[0] = rotl64(s[0], 0)
            B[10] = rotl64(s[1], 1)
            B[20] = rotl64(s[2], 62)
            B[5] = rotl64(s[3], 28)
            B[15] = rotl64(s[4], 27)
            B[16] = rotl64(s[5], 36)
            B[1] = rotl64(s[6], 44)
            B[11] = rotl64(s[7], 6)
            B[21] = rotl64(s[8], 55)
            B[6] = rotl64(s[9], 20)
            B[7] = rotl64(s[10], 3)
            B[17] = rotl64(s[11], 10)
            B[2] = rotl64(s[12], 43)
            B[12] = rotl64(s[13], 25)
            B[22] = rotl64(s[14], 39)
            B[23] = rotl64(s[15], 41)
            B[8] = rotl64(s[16], 45)
            B[18] = rotl64(s[17], 15)
            B[3] = rotl64(s[18], 21)
            B[13] = rotl64(s[19], 8)
            B[14] = rotl64(s[20], 18)
            B[24] = rotl64(s[21], 2)
            B[9] = rotl64(s[22], 61)
            B[19] = rotl64(s[23], 56)
            B[4] = rotl64(s[24], 14)
        else:
            var RHO = rho_offsets()
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
            @parameter
            if USE_UNROLLED_ABSORB:
                var lane0 = UInt64(0)
                lane0 |= UInt64(data[offset + 0] & 0xFF)
                lane0 |= UInt64(data[offset + 1] & 0xFF) << 8
                lane0 |= UInt64(data[offset + 2] & 0xFF) << 16
                lane0 |= UInt64(data[offset + 3] & 0xFF) << 24
                lane0 |= UInt64(data[offset + 4] & 0xFF) << 32
                lane0 |= UInt64(data[offset + 5] & 0xFF) << 40
                lane0 |= UInt64(data[offset + 6] & 0xFF) << 48
                lane0 |= UInt64(data[offset + 7] & 0xFF) << 56
                state[0] = state[0] ^ lane0
                var lane1 = UInt64(0)
                lane1 |= UInt64(data[offset + 8] & 0xFF)
                lane1 |= UInt64(data[offset + 9] & 0xFF) << 8
                lane1 |= UInt64(data[offset + 10] & 0xFF) << 16
                lane1 |= UInt64(data[offset + 11] & 0xFF) << 24
                lane1 |= UInt64(data[offset + 12] & 0xFF) << 32
                lane1 |= UInt64(data[offset + 13] & 0xFF) << 40
                lane1 |= UInt64(data[offset + 14] & 0xFF) << 48
                lane1 |= UInt64(data[offset + 15] & 0xFF) << 56
                state[1] = state[1] ^ lane1
                var lane2 = UInt64(0)
                lane2 |= UInt64(data[offset + 16] & 0xFF)
                lane2 |= UInt64(data[offset + 17] & 0xFF) << 8
                lane2 |= UInt64(data[offset + 18] & 0xFF) << 16
                lane2 |= UInt64(data[offset + 19] & 0xFF) << 24
                lane2 |= UInt64(data[offset + 20] & 0xFF) << 32
                lane2 |= UInt64(data[offset + 21] & 0xFF) << 40
                lane2 |= UInt64(data[offset + 22] & 0xFF) << 48
                lane2 |= UInt64(data[offset + 23] & 0xFF) << 56
                state[2] = state[2] ^ lane2
                var lane3 = UInt64(0)
                lane3 |= UInt64(data[offset + 24] & 0xFF)
                lane3 |= UInt64(data[offset + 25] & 0xFF) << 8
                lane3 |= UInt64(data[offset + 26] & 0xFF) << 16
                lane3 |= UInt64(data[offset + 27] & 0xFF) << 24
                lane3 |= UInt64(data[offset + 28] & 0xFF) << 32
                lane3 |= UInt64(data[offset + 29] & 0xFF) << 40
                lane3 |= UInt64(data[offset + 30] & 0xFF) << 48
                lane3 |= UInt64(data[offset + 31] & 0xFF) << 56
                state[3] = state[3] ^ lane3
                var lane4 = UInt64(0)
                lane4 |= UInt64(data[offset + 32] & 0xFF)
                lane4 |= UInt64(data[offset + 33] & 0xFF) << 8
                lane4 |= UInt64(data[offset + 34] & 0xFF) << 16
                lane4 |= UInt64(data[offset + 35] & 0xFF) << 24
                lane4 |= UInt64(data[offset + 36] & 0xFF) << 32
                lane4 |= UInt64(data[offset + 37] & 0xFF) << 40
                lane4 |= UInt64(data[offset + 38] & 0xFF) << 48
                lane4 |= UInt64(data[offset + 39] & 0xFF) << 56
                state[4] = state[4] ^ lane4
                var lane5 = UInt64(0)
                lane5 |= UInt64(data[offset + 40] & 0xFF)
                lane5 |= UInt64(data[offset + 41] & 0xFF) << 8
                lane5 |= UInt64(data[offset + 42] & 0xFF) << 16
                lane5 |= UInt64(data[offset + 43] & 0xFF) << 24
                lane5 |= UInt64(data[offset + 44] & 0xFF) << 32
                lane5 |= UInt64(data[offset + 45] & 0xFF) << 40
                lane5 |= UInt64(data[offset + 46] & 0xFF) << 48
                lane5 |= UInt64(data[offset + 47] & 0xFF) << 56
                state[5] = state[5] ^ lane5
                var lane6 = UInt64(0)
                lane6 |= UInt64(data[offset + 48] & 0xFF)
                lane6 |= UInt64(data[offset + 49] & 0xFF) << 8
                lane6 |= UInt64(data[offset + 50] & 0xFF) << 16
                lane6 |= UInt64(data[offset + 51] & 0xFF) << 24
                lane6 |= UInt64(data[offset + 52] & 0xFF) << 32
                lane6 |= UInt64(data[offset + 53] & 0xFF) << 40
                lane6 |= UInt64(data[offset + 54] & 0xFF) << 48
                lane6 |= UInt64(data[offset + 55] & 0xFF) << 56
                state[6] = state[6] ^ lane6
                var lane7 = UInt64(0)
                lane7 |= UInt64(data[offset + 56] & 0xFF)
                lane7 |= UInt64(data[offset + 57] & 0xFF) << 8
                lane7 |= UInt64(data[offset + 58] & 0xFF) << 16
                lane7 |= UInt64(data[offset + 59] & 0xFF) << 24
                lane7 |= UInt64(data[offset + 60] & 0xFF) << 32
                lane7 |= UInt64(data[offset + 61] & 0xFF) << 40
                lane7 |= UInt64(data[offset + 62] & 0xFF) << 48
                lane7 |= UInt64(data[offset + 63] & 0xFF) << 56
                state[7] = state[7] ^ lane7
                var lane8 = UInt64(0)
                lane8 |= UInt64(data[offset + 64] & 0xFF)
                lane8 |= UInt64(data[offset + 65] & 0xFF) << 8
                lane8 |= UInt64(data[offset + 66] & 0xFF) << 16
                lane8 |= UInt64(data[offset + 67] & 0xFF) << 24
                lane8 |= UInt64(data[offset + 68] & 0xFF) << 32
                lane8 |= UInt64(data[offset + 69] & 0xFF) << 40
                lane8 |= UInt64(data[offset + 70] & 0xFF) << 48
                lane8 |= UInt64(data[offset + 71] & 0xFF) << 56
                state[8] = state[8] ^ lane8
                var lane9 = UInt64(0)
                lane9 |= UInt64(data[offset + 72] & 0xFF)
                lane9 |= UInt64(data[offset + 73] & 0xFF) << 8
                lane9 |= UInt64(data[offset + 74] & 0xFF) << 16
                lane9 |= UInt64(data[offset + 75] & 0xFF) << 24
                lane9 |= UInt64(data[offset + 76] & 0xFF) << 32
                lane9 |= UInt64(data[offset + 77] & 0xFF) << 40
                lane9 |= UInt64(data[offset + 78] & 0xFF) << 48
                lane9 |= UInt64(data[offset + 79] & 0xFF) << 56
                state[9] = state[9] ^ lane9
                var lane10 = UInt64(0)
                lane10 |= UInt64(data[offset + 80] & 0xFF)
                lane10 |= UInt64(data[offset + 81] & 0xFF) << 8
                lane10 |= UInt64(data[offset + 82] & 0xFF) << 16
                lane10 |= UInt64(data[offset + 83] & 0xFF) << 24
                lane10 |= UInt64(data[offset + 84] & 0xFF) << 32
                lane10 |= UInt64(data[offset + 85] & 0xFF) << 40
                lane10 |= UInt64(data[offset + 86] & 0xFF) << 48
                lane10 |= UInt64(data[offset + 87] & 0xFF) << 56
                state[10] = state[10] ^ lane10
                var lane11 = UInt64(0)
                lane11 |= UInt64(data[offset + 88] & 0xFF)
                lane11 |= UInt64(data[offset + 89] & 0xFF) << 8
                lane11 |= UInt64(data[offset + 90] & 0xFF) << 16
                lane11 |= UInt64(data[offset + 91] & 0xFF) << 24
                lane11 |= UInt64(data[offset + 92] & 0xFF) << 32
                lane11 |= UInt64(data[offset + 93] & 0xFF) << 40
                lane11 |= UInt64(data[offset + 94] & 0xFF) << 48
                lane11 |= UInt64(data[offset + 95] & 0xFF) << 56
                state[11] = state[11] ^ lane11
                var lane12 = UInt64(0)
                lane12 |= UInt64(data[offset + 96] & 0xFF)
                lane12 |= UInt64(data[offset + 97] & 0xFF) << 8
                lane12 |= UInt64(data[offset + 98] & 0xFF) << 16
                lane12 |= UInt64(data[offset + 99] & 0xFF) << 24
                lane12 |= UInt64(data[offset + 100] & 0xFF) << 32
                lane12 |= UInt64(data[offset + 101] & 0xFF) << 40
                lane12 |= UInt64(data[offset + 102] & 0xFF) << 48
                lane12 |= UInt64(data[offset + 103] & 0xFF) << 56
                state[12] = state[12] ^ lane12
                var lane13 = UInt64(0)
                lane13 |= UInt64(data[offset + 104] & 0xFF)
                lane13 |= UInt64(data[offset + 105] & 0xFF) << 8
                lane13 |= UInt64(data[offset + 106] & 0xFF) << 16
                lane13 |= UInt64(data[offset + 107] & 0xFF) << 24
                lane13 |= UInt64(data[offset + 108] & 0xFF) << 32
                lane13 |= UInt64(data[offset + 109] & 0xFF) << 40
                lane13 |= UInt64(data[offset + 110] & 0xFF) << 48
                lane13 |= UInt64(data[offset + 111] & 0xFF) << 56
                state[13] = state[13] ^ lane13
                var lane14 = UInt64(0)
                lane14 |= UInt64(data[offset + 112] & 0xFF)
                lane14 |= UInt64(data[offset + 113] & 0xFF) << 8
                lane14 |= UInt64(data[offset + 114] & 0xFF) << 16
                lane14 |= UInt64(data[offset + 115] & 0xFF) << 24
                lane14 |= UInt64(data[offset + 116] & 0xFF) << 32
                lane14 |= UInt64(data[offset + 117] & 0xFF) << 40
                lane14 |= UInt64(data[offset + 118] & 0xFF) << 48
                lane14 |= UInt64(data[offset + 119] & 0xFF) << 56
                state[14] = state[14] ^ lane14
                var lane15 = UInt64(0)
                lane15 |= UInt64(data[offset + 120] & 0xFF)
                lane15 |= UInt64(data[offset + 121] & 0xFF) << 8
                lane15 |= UInt64(data[offset + 122] & 0xFF) << 16
                lane15 |= UInt64(data[offset + 123] & 0xFF) << 24
                lane15 |= UInt64(data[offset + 124] & 0xFF) << 32
                lane15 |= UInt64(data[offset + 125] & 0xFF) << 40
                lane15 |= UInt64(data[offset + 126] & 0xFF) << 48
                lane15 |= UInt64(data[offset + 127] & 0xFF) << 56
                state[15] = state[15] ^ lane15
                var lane16 = UInt64(0)
                lane16 |= UInt64(data[offset + 128] & 0xFF)
                lane16 |= UInt64(data[offset + 129] & 0xFF) << 8
                lane16 |= UInt64(data[offset + 130] & 0xFF) << 16
                lane16 |= UInt64(data[offset + 131] & 0xFF) << 24
                lane16 |= UInt64(data[offset + 132] & 0xFF) << 32
                lane16 |= UInt64(data[offset + 133] & 0xFF) << 40
                lane16 |= UInt64(data[offset + 134] & 0xFF) << 48
                lane16 |= UInt64(data[offset + 135] & 0xFF) << 56
                state[16] = state[16] ^ lane16
            else:
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

        @parameter
        if USE_UNROLLED_ABSORB:
            var tail0 = UInt64(0)
            tail0 |= UInt64(block[0])
            tail0 |= UInt64(block[1]) << 8
            tail0 |= UInt64(block[2]) << 16
            tail0 |= UInt64(block[3]) << 24
            tail0 |= UInt64(block[4]) << 32
            tail0 |= UInt64(block[5]) << 40
            tail0 |= UInt64(block[6]) << 48
            tail0 |= UInt64(block[7]) << 56
            state[0] = state[0] ^ tail0
            var tail1 = UInt64(0)
            tail1 |= UInt64(block[8])
            tail1 |= UInt64(block[9]) << 8
            tail1 |= UInt64(block[10]) << 16
            tail1 |= UInt64(block[11]) << 24
            tail1 |= UInt64(block[12]) << 32
            tail1 |= UInt64(block[13]) << 40
            tail1 |= UInt64(block[14]) << 48
            tail1 |= UInt64(block[15]) << 56
            state[1] = state[1] ^ tail1
            var tail2 = UInt64(0)
            tail2 |= UInt64(block[16])
            tail2 |= UInt64(block[17]) << 8
            tail2 |= UInt64(block[18]) << 16
            tail2 |= UInt64(block[19]) << 24
            tail2 |= UInt64(block[20]) << 32
            tail2 |= UInt64(block[21]) << 40
            tail2 |= UInt64(block[22]) << 48
            tail2 |= UInt64(block[23]) << 56
            state[2] = state[2] ^ tail2
            var tail3 = UInt64(0)
            tail3 |= UInt64(block[24])
            tail3 |= UInt64(block[25]) << 8
            tail3 |= UInt64(block[26]) << 16
            tail3 |= UInt64(block[27]) << 24
            tail3 |= UInt64(block[28]) << 32
            tail3 |= UInt64(block[29]) << 40
            tail3 |= UInt64(block[30]) << 48
            tail3 |= UInt64(block[31]) << 56
            state[3] = state[3] ^ tail3
            var tail4 = UInt64(0)
            tail4 |= UInt64(block[32])
            tail4 |= UInt64(block[33]) << 8
            tail4 |= UInt64(block[34]) << 16
            tail4 |= UInt64(block[35]) << 24
            tail4 |= UInt64(block[36]) << 32
            tail4 |= UInt64(block[37]) << 40
            tail4 |= UInt64(block[38]) << 48
            tail4 |= UInt64(block[39]) << 56
            state[4] = state[4] ^ tail4
            var tail5 = UInt64(0)
            tail5 |= UInt64(block[40])
            tail5 |= UInt64(block[41]) << 8
            tail5 |= UInt64(block[42]) << 16
            tail5 |= UInt64(block[43]) << 24
            tail5 |= UInt64(block[44]) << 32
            tail5 |= UInt64(block[45]) << 40
            tail5 |= UInt64(block[46]) << 48
            tail5 |= UInt64(block[47]) << 56
            state[5] = state[5] ^ tail5
            var tail6 = UInt64(0)
            tail6 |= UInt64(block[48])
            tail6 |= UInt64(block[49]) << 8
            tail6 |= UInt64(block[50]) << 16
            tail6 |= UInt64(block[51]) << 24
            tail6 |= UInt64(block[52]) << 32
            tail6 |= UInt64(block[53]) << 40
            tail6 |= UInt64(block[54]) << 48
            tail6 |= UInt64(block[55]) << 56
            state[6] = state[6] ^ tail6
            var tail7 = UInt64(0)
            tail7 |= UInt64(block[56])
            tail7 |= UInt64(block[57]) << 8
            tail7 |= UInt64(block[58]) << 16
            tail7 |= UInt64(block[59]) << 24
            tail7 |= UInt64(block[60]) << 32
            tail7 |= UInt64(block[61]) << 40
            tail7 |= UInt64(block[62]) << 48
            tail7 |= UInt64(block[63]) << 56
            state[7] = state[7] ^ tail7
            var tail8 = UInt64(0)
            tail8 |= UInt64(block[64])
            tail8 |= UInt64(block[65]) << 8
            tail8 |= UInt64(block[66]) << 16
            tail8 |= UInt64(block[67]) << 24
            tail8 |= UInt64(block[68]) << 32
            tail8 |= UInt64(block[69]) << 40
            tail8 |= UInt64(block[70]) << 48
            tail8 |= UInt64(block[71]) << 56
            state[8] = state[8] ^ tail8
            var tail9 = UInt64(0)
            tail9 |= UInt64(block[72])
            tail9 |= UInt64(block[73]) << 8
            tail9 |= UInt64(block[74]) << 16
            tail9 |= UInt64(block[75]) << 24
            tail9 |= UInt64(block[76]) << 32
            tail9 |= UInt64(block[77]) << 40
            tail9 |= UInt64(block[78]) << 48
            tail9 |= UInt64(block[79]) << 56
            state[9] = state[9] ^ tail9
            var tail10 = UInt64(0)
            tail10 |= UInt64(block[80])
            tail10 |= UInt64(block[81]) << 8
            tail10 |= UInt64(block[82]) << 16
            tail10 |= UInt64(block[83]) << 24
            tail10 |= UInt64(block[84]) << 32
            tail10 |= UInt64(block[85]) << 40
            tail10 |= UInt64(block[86]) << 48
            tail10 |= UInt64(block[87]) << 56
            state[10] = state[10] ^ tail10
            var tail11 = UInt64(0)
            tail11 |= UInt64(block[88])
            tail11 |= UInt64(block[89]) << 8
            tail11 |= UInt64(block[90]) << 16
            tail11 |= UInt64(block[91]) << 24
            tail11 |= UInt64(block[92]) << 32
            tail11 |= UInt64(block[93]) << 40
            tail11 |= UInt64(block[94]) << 48
            tail11 |= UInt64(block[95]) << 56
            state[11] = state[11] ^ tail11
            var tail12 = UInt64(0)
            tail12 |= UInt64(block[96])
            tail12 |= UInt64(block[97]) << 8
            tail12 |= UInt64(block[98]) << 16
            tail12 |= UInt64(block[99]) << 24
            tail12 |= UInt64(block[100]) << 32
            tail12 |= UInt64(block[101]) << 40
            tail12 |= UInt64(block[102]) << 48
            tail12 |= UInt64(block[103]) << 56
            state[12] = state[12] ^ tail12
            var tail13 = UInt64(0)
            tail13 |= UInt64(block[104])
            tail13 |= UInt64(block[105]) << 8
            tail13 |= UInt64(block[106]) << 16
            tail13 |= UInt64(block[107]) << 24
            tail13 |= UInt64(block[108]) << 32
            tail13 |= UInt64(block[109]) << 40
            tail13 |= UInt64(block[110]) << 48
            tail13 |= UInt64(block[111]) << 56
            state[13] = state[13] ^ tail13
            var tail14 = UInt64(0)
            tail14 |= UInt64(block[112])
            tail14 |= UInt64(block[113]) << 8
            tail14 |= UInt64(block[114]) << 16
            tail14 |= UInt64(block[115]) << 24
            tail14 |= UInt64(block[116]) << 32
            tail14 |= UInt64(block[117]) << 40
            tail14 |= UInt64(block[118]) << 48
            tail14 |= UInt64(block[119]) << 56
            state[14] = state[14] ^ tail14
            var tail15 = UInt64(0)
            tail15 |= UInt64(block[120])
            tail15 |= UInt64(block[121]) << 8
            tail15 |= UInt64(block[122]) << 16
            tail15 |= UInt64(block[123]) << 24
            tail15 |= UInt64(block[124]) << 32
            tail15 |= UInt64(block[125]) << 40
            tail15 |= UInt64(block[126]) << 48
            tail15 |= UInt64(block[127]) << 56
            state[15] = state[15] ^ tail15
            var tail16 = UInt64(0)
            tail16 |= UInt64(block[128])
            tail16 |= UInt64(block[129]) << 8
            tail16 |= UInt64(block[130]) << 16
            tail16 |= UInt64(block[131]) << 24
            tail16 |= UInt64(block[132]) << 32
            tail16 |= UInt64(block[133]) << 40
            tail16 |= UInt64(block[134]) << 48
            tail16 |= UInt64(block[135]) << 56
            state[16] = state[16] ^ tail16
        else:
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
