# Minimal Keccak-256 (Ethereum) – no SIMD, no DType, no external deps.

# Rotate-left 64
@always_inline
fn rotl64(x: UInt64, n: Int) -> UInt64:
    let k = n % 64
    if k == 0:
        return x
    return (x << k) | (x >> (64 - k))

# Round constants
let RC: [UInt64; 24] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
    0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
    0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008
]

# Rho rotation offsets
let R: [[Int; 5]; 5] = [
    [ 0, 36,  3, 41, 18],
    [ 1, 44, 10, 45,  2],
    [62,  6, 43, 15, 61],
    [28, 55, 25, 21, 56],
    [27, 20, 39,  8, 14]
]

# Keccak-f[1600] permutation (24 rounds)
fn keccak_f1600(state: inout [UInt64; 25]):
    for round in range(24):
        # θ
        var C: [UInt64; 5]
        for x in range(5):
            C[x] = state[x] ^ state[x+5] ^ state[x+10] ^ state[x+15] ^ state[x+20]
        var D: [UInt64; 5]
        for x in range(5):
            D[x] = C[(x+4)%5] ^ rotl64(C[(x+1)%5], 1)
        for i in range(25):
            state[i] ^= D[i % 5]

        # ρ + π
        var B: [UInt64; 25]
        for x in range(5):
            for y in range(5):
                let idx = x + 5*y
                B[y + 5*((2*x + 3*y) % 5)] = rotl64(state[idx], R[x][y])

        # χ
        for x in range(5):
            for y in range(5):
                let i = x + 5*y
                state[i] = B[i] ^ ((~B[(x+1)%5 + 5*y]) & B[(x+2)%5 + 5*y])

        # ι
        state[0] ^= RC[round]

# Core hash (r=1088 bytes=136, c=512). Input as raw pointer + length.
fn keccak256_bytes(ptr: Pointer[UInt8], length: Int) -> [UInt8; 32]:
    var state: [UInt64; 25] = [0] * 25
    let rate = 136  # bytes
    var offset = 0

    # Absorb full blocks
    while offset + rate <= length:
        for i in range(rate):
            state[i / 8] ^= UInt64(ptr[offset + i]) << ((i % 8) * 8)
        keccak_f1600(state)
        offset += rate

    # Absorb remainder and pad (Keccak padding: 0x01 ... 0x80)
    var block: [UInt8; 136] = [UInt8(0)] * 136
    let rem = length - offset
    for i in range(rem):
        block[i] = ptr[offset + i]
    block[rem] = 0x01
    block[rate - 1] ^= 0x80

    for i in range(rate):
        state[i / 8] ^= UInt64(block[i]) << ((i % 8) * 8)
    keccak_f1600(state)

    # Squeeze 32 bytes
    var out: [UInt8; 32]
    for i in range(32):
        let lane = state[i / 8]
        out[i] = UInt8((lane >> ((i % 8) * 8)) & 0xFF)
    return out

# Convenience overload for String
fn keccak256_string(s: String) -> [UInt8; 32]:
    # data().ptr returns Pointer[UInt8] on current toolchains
    return keccak256_bytes(s.data().ptr, len(s))
