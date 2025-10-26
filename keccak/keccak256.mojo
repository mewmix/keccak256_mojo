alias RATE = 136
alias LANES = 17  # RATE / 8
alias ROUNDS = 24
alias USE_UNROLLED_THETA_CHI = True

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
    var RC = round_constants()

    @parameter
    if USE_UNROLLED_THETA_CHI:
        var Aba = s[0]
        var Abe = s[1]
        var Abi = s[2]
        var Abo = s[3]
        var Abu = s[4]
        var Aga = s[5]
        var Age = s[6]
        var Agi = s[7]
        var Ago = s[8]
        var Agu = s[9]
        var Aka = s[10]
        var Ake = s[11]
        var Aki = s[12]
        var Ako = s[13]
        var Aku = s[14]
        var Ama = s[15]
        var Ame = s[16]
        var Ami = s[17]
        var Amo = s[18]
        var Amu = s[19]
        var Asa = s[20]
        var Ase = s[21]
        var Asi = s[22]
        var Aso = s[23]
        var Asu = s[24]

        for round in range(ROUNDS):
            var C0 = Aba ^ Aga ^ Aka ^ Ama ^ Asa
            var C1 = Abe ^ Age ^ Ake ^ Ame ^ Ase
            var C2 = Abi ^ Agi ^ Aki ^ Ami ^ Asi
            var C3 = Abo ^ Ago ^ Ako ^ Amo ^ Aso
            var C4 = Abu ^ Agu ^ Aku ^ Amu ^ Asu

            var D0 = C4 ^ rotl64(C1, 1)
            var D1 = C0 ^ rotl64(C2, 1)
            var D2 = C1 ^ rotl64(C3, 1)
            var D3 = C2 ^ rotl64(C4, 1)
            var D4 = C3 ^ rotl64(C0, 1)

            Aba = Aba ^ D0
            Abe = Abe ^ D1
            Abi = Abi ^ D2
            Abo = Abo ^ D3
            Abu = Abu ^ D4
            Aga = Aga ^ D0
            Age = Age ^ D1
            Agi = Agi ^ D2
            Ago = Ago ^ D3
            Agu = Agu ^ D4
            Aka = Aka ^ D0
            Ake = Ake ^ D1
            Aki = Aki ^ D2
            Ako = Ako ^ D3
            Aku = Aku ^ D4
            Ama = Ama ^ D0
            Ame = Ame ^ D1
            Ami = Ami ^ D2
            Amo = Amo ^ D3
            Amu = Amu ^ D4
            Asa = Asa ^ D0
            Ase = Ase ^ D1
            Asi = Asi ^ D2
            Aso = Aso ^ D3
            Asu = Asu ^ D4

            var B0 = Aba
            var B1 = rotl64(Age, 44)
            var B2 = rotl64(Aki, 43)
            var B3 = rotl64(Amo, 21)
            var B4 = rotl64(Asu, 14)
            var B5 = rotl64(Abo, 28)
            var B6 = rotl64(Agu, 20)
            var B7 = rotl64(Aka, 3)
            var B8 = rotl64(Ame, 45)
            var B9 = rotl64(Asi, 61)
            var B10 = rotl64(Abe, 1)
            var B11 = rotl64(Agi, 6)
            var B12 = rotl64(Ako, 25)
            var B13 = rotl64(Amu, 8)
            var B14 = rotl64(Asa, 18)
            var B15 = rotl64(Abu, 27)
            var B16 = rotl64(Aga, 36)
            var B17 = rotl64(Ake, 10)
            var B18 = rotl64(Ami, 15)
            var B19 = rotl64(Aso, 56)
            var B20 = rotl64(Abi, 62)
            var B21 = rotl64(Ago, 55)
            var B22 = rotl64(Aku, 39)
            var B23 = rotl64(Ama, 41)
            var B24 = rotl64(Ase, 2)

            Aba = B0 ^ ((~B1) & B2)
            Abe = B1 ^ ((~B2) & B3)
            Abi = B2 ^ ((~B3) & B4)
            Abo = B3 ^ ((~B4) & B0)
            Abu = B4 ^ ((~B0) & B1)

            Aga = B5 ^ ((~B6) & B7)
            Age = B6 ^ ((~B7) & B8)
            Agi = B7 ^ ((~B8) & B9)
            Ago = B8 ^ ((~B9) & B5)
            Agu = B9 ^ ((~B5) & B6)

            Aka = B10 ^ ((~B11) & B12)
            Ake = B11 ^ ((~B12) & B13)
            Aki = B12 ^ ((~B13) & B14)
            Ako = B13 ^ ((~B14) & B10)
            Aku = B14 ^ ((~B10) & B11)

            Ama = B15 ^ ((~B16) & B17)
            Ame = B16 ^ ((~B17) & B18)
            Ami = B17 ^ ((~B18) & B19)
            Amo = B18 ^ ((~B19) & B15)
            Amu = B19 ^ ((~B15) & B16)

            Asa = B20 ^ ((~B21) & B22)
            Ase = B21 ^ ((~B22) & B23)
            Asi = B22 ^ ((~B23) & B24)
            Aso = B23 ^ ((~B24) & B20)
            Asu = B24 ^ ((~B20) & B21)

            Aba = Aba ^ RC[round]

        s[0] = Aba
        s[1] = Abe
        s[2] = Abi
        s[3] = Abo
        s[4] = Abu
        s[5] = Aga
        s[6] = Age
        s[7] = Agi
        s[8] = Ago
        s[9] = Agu
        s[10] = Aka
        s[11] = Ake
        s[12] = Aki
        s[13] = Ako
        s[14] = Aku
        s[15] = Ama
        s[16] = Ame
        s[17] = Ami
        s[18] = Amo
        s[19] = Amu
        s[20] = Asa
        s[21] = Ase
        s[22] = Asi
        s[23] = Aso
        s[24] = Asu
    else:
        var RHO = rho_offsets()
        var C = [UInt64(0)] * 5
        var D = [UInt64(0)] * 5
        var B = [UInt64(0)] * 25

        for round in range(ROUNDS):
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


fn keccak256_raw(ptr: UnsafePointer[UInt8], length: Int) -> List[Int]:
    var state = [UInt64(0)] * 25
    var processed = 0
    var stub = [UInt8(0)] * 1
    var cursor: UnsafePointer[UInt8]
    if length > 0:
        cursor = ptr
    else:
        cursor = UnsafePointer(to=stub[0])

    while processed + RATE <= length:
        var lane_ptr = cursor
        state[0] = state[0] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[1] = state[1] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[2] = state[2] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[3] = state[3] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[4] = state[4] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[5] = state[5] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[6] = state[6] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[7] = state[7] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[8] = state[8] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[9] = state[9] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[10] = state[10] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[11] = state[11] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[12] = state[12] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[13] = state[13] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[14] = state[14] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[15] = state[15] ^ load_lane_ptr(lane_ptr)
        lane_ptr = lane_ptr.offset(8)
        state[16] = state[16] ^ load_lane_ptr(lane_ptr)

        keccak_f1600(state)
        cursor = cursor.offset(RATE)
        processed += RATE

    var block = [UInt8(0)] * RATE
    var rem = length - processed
    for i in range(rem):
        block[i] = (cursor + i)[]
    block[rem] = UInt8(0x01)
    block[RATE - 1] = block[RATE - 1] ^ UInt8(0x80)

    var tail_ptr = UnsafePointer(to=block[0])
    var lane_ptr = tail_ptr
    state[0] = state[0] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[1] = state[1] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[2] = state[2] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[3] = state[3] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[4] = state[4] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[5] = state[5] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[6] = state[6] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[7] = state[7] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[8] = state[8] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[9] = state[9] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[10] = state[10] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[11] = state[11] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[12] = state[12] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[13] = state[13] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[14] = state[14] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[15] = state[15] ^ load_lane_ptr(lane_ptr)
    lane_ptr = lane_ptr.offset(8)
    state[16] = state[16] ^ load_lane_ptr(lane_ptr)

    keccak_f1600(state)

    var out = [0] * 32
    for i in range(32):
        var lane_val = state[i // 8]
        out[i] = Int((lane_val >> UInt64((i % 8) * 8)) & UInt64(0xFF))
    return out.copy()


fn keccak256_bytes_from_u8(data: List[UInt8], length: Int) -> List[Int]:
    if length == 0:
        var stub = [UInt8(0)] * 1
        return keccak256_raw(UnsafePointer(to=stub[0]), 0)
    var ptr = UnsafePointer(to=data[0])
    return keccak256_raw(ptr, length)


fn keccak256_bytes(data: List[Int], length: Int) -> List[Int]:
    if length == 0:
        var stub = [UInt8(0)] * 1
        return keccak256_raw(UnsafePointer(to=stub[0]), 0)
    var bytes = [UInt8(0)] * length
    for i in range(length):
        bytes[i] = UInt8(data[i] & 0xFF)
    var ptr = UnsafePointer(to=bytes[0])
    return keccak256_raw(ptr, length)


fn keccak256_string(input: String) -> List[Int]:
    var data = [UInt8(0)] * len(input)
    var idx = 0
    for cp in input.codepoints():
        var value = Int(cp)
        data[idx] = UInt8(value & 0xFF)
        idx += 1
    return keccak256_bytes_from_u8(data, len(data))

fn keccak256_hex_string(input: String) -> String:
    return to_hex32(keccak256_string(input))
