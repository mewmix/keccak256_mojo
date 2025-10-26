// keccak256.h - Minimal SHA3/Keccak-256 interface for benchmark tests.
//
// Adapted from tiny_sha3 by Markku-Juhani O. Saarinen.
// Original project: https://github.com/mjosaarinen/tiny_sha3 (MIT License)
// Copyright (c) 2015, Markku-Juhani O. Saarinen
//
// The implementation provided here retains the MIT license.
//
// SPDX-License-Identifier: MIT

#ifndef KECCAK256_H
#define KECCAK256_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define KECCAK256_DIGEST_LENGTH 32

void keccak256(const uint8_t *message, size_t length, uint8_t digest[KECCAK256_DIGEST_LENGTH]);

#ifdef __cplusplus
}
#endif

#endif // KECCAK256_H
