// keccak256.c - Adapted tiny_sha3 Keccak-256 implementation.
// SPDX-License-Identifier: MIT

#include "keccak256.h"

// This file is a trimmed version of tiny_sha3 with only the features
// required for Keccak-256. See the original project for the full library.

// Rotation macro.
#define ROL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))

// Round constants.
static const uint64_t keccakf_rndc[24] = {
    0x0000000000000001ULL, 0x0000000000008082ULL, 0x800000000000808aULL,
    0x8000000080008000ULL, 0x000000000000808bULL, 0x0000000080000001ULL,
    0x8000000080008081ULL, 0x8000000000008009ULL, 0x000000000000008aULL,
    0x0000000000000088ULL, 0x0000000080008009ULL, 0x000000008000000aULL,
    0x000000008000808bULL, 0x800000000000008bULL, 0x8000000000008089ULL,
    0x8000000000008003ULL, 0x8000000000008002ULL, 0x8000000000000080ULL,
    0x000000000000800aULL, 0x800000008000000aULL, 0x8000000080008081ULL,
    0x8000000000008080ULL, 0x0000000080000001ULL, 0x8000000080008008ULL,
};

// Rotation offsets.
static const unsigned keccakf_rotc[24] = {
     1,  3,  6, 10, 15, 21, 28, 36, 45, 55,  2, 14,
    27, 41, 56,  8, 25, 43, 62, 18, 39, 61, 20, 44,
};

// Permutation index.
static const unsigned keccakf_piln[24] = {
    10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4,
    15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1,
};

// Internal state.
typedef struct {
    uint64_t state[25];
    unsigned rate;
    unsigned capacity;
    unsigned absorbed;
} sha3_ctx;

static void sha3_init(sha3_ctx *ctx, unsigned rate_bits) {
    ctx->rate = rate_bits / 8;
    ctx->capacity = (1600 / 8) - ctx->rate;
    ctx->absorbed = 0;
    for (unsigned i = 0; i < 25; ++i) {
        ctx->state[i] = 0;
    }
}

static void keccakf(uint64_t st[25]) {
    for (int round = 0; round < 24; ++round) {
        uint64_t bc[5];

        // Theta
        for (int i = 0; i < 5; ++i) {
            bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];
        }
        for (int i = 0; i < 5; ++i) {
            uint64_t t = bc[(i + 4) % 5] ^ ROL64(bc[(i + 1) % 5], 1);
            for (int j = 0; j < 25; j += 5) {
                st[j + i] ^= t;
            }
        }

        // Rho and Pi
        uint64_t t = st[1];
        for (int i = 0; i < 24; ++i) {
            int j = keccakf_piln[i];
            uint64_t tmp = st[j];
            st[j] = ROL64(t, keccakf_rotc[i]);
            t = tmp;
        }

        // Chi
        for (int j = 0; j < 25; j += 5) {
            uint64_t temp[5];
            for (int i = 0; i < 5; ++i) {
                temp[i] = st[j + i];
            }
            for (int i = 0; i < 5; ++i) {
                st[j + i] ^= (~temp[(i + 1) % 5]) & temp[(i + 2) % 5];
            }
        }

        // Iota
        st[0] ^= keccakf_rndc[round];
    }
}

static void sha3_update(sha3_ctx *ctx, const uint8_t *message, size_t length) {
    unsigned rate = ctx->rate;
    unsigned idx = ctx->absorbed;

    while (length--) {
        ((uint8_t *)ctx->state)[idx++] ^= *message++;
        if (idx == rate) {
            keccakf(ctx->state);
            idx = 0;
        }
    }
    ctx->absorbed = idx;
}

static void sha3_finalize(sha3_ctx *ctx, uint8_t *digest) {
    unsigned rate = ctx->rate;
    uint8_t *state_bytes = (uint8_t *)ctx->state;

    state_bytes[ctx->absorbed] ^= 0x01;
    state_bytes[rate - 1] ^= 0x80;
    keccakf(ctx->state);

    for (unsigned i = 0; i < KECCAK256_DIGEST_LENGTH; ++i) {
        digest[i] = state_bytes[i];
    }
}

void keccak256(const uint8_t *message, size_t length, uint8_t digest[KECCAK256_DIGEST_LENGTH]) {
    sha3_ctx ctx;
    sha3_init(&ctx, 1088); // 1600 - 512 -> 1088-bit rate
    sha3_update(&ctx, message, length);
    sha3_finalize(&ctx, digest);
}
