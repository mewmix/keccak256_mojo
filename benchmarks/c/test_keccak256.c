// Minimal smoke tests for the Keccak-256 baseline.
// SPDX-License-Identifier: MIT

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "keccak256.h"

static void to_hex(const uint8_t *bytes, size_t length, char *out) {
    static const char digits[] = "0123456789abcdef";
    for (size_t i = 0; i < length; ++i) {
        out[i * 2] = digits[(bytes[i] >> 4) & 0xF];
        out[i * 2 + 1] = digits[bytes[i] & 0xF];
    }
    out[length * 2] = '\0';
}

static int assert_digest(const char *label, const uint8_t *message, size_t length, const char *expected) {
    uint8_t digest[KECCAK256_DIGEST_LENGTH];
    char hex[KECCAK256_DIGEST_LENGTH * 2 + 1];

    keccak256(message, length, digest);
    to_hex(digest, KECCAK256_DIGEST_LENGTH, hex);

    if (strcmp(hex, expected) != 0) {
        fprintf(stderr, "%s mismatch: got %s, expected %s\n", label, hex, expected);
        return 1;
    }
    return 0;
}

int main(void) {
    int status = 0;
    status |= assert_digest("keccak256(\"abc\")", (const uint8_t *)"abc", 3,
                            "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45");
    status |= assert_digest("keccak256(\"\")", (const uint8_t *)"", 0,
                            "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");

    if (status == 0) {
        printf("All C baseline tests passed.\n");
    }
    return status;
}
