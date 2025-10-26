#define _POSIX_C_SOURCE 200809L
// bench_keccak256.c - Keccak-256 microbenchmark for native baseline.
// SPDX-License-Identifier: MIT

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "keccak256.h"

#define NUM_MESSAGES 512
#define ROUNDS 200
#define BASE_LENGTH 32
#define MAX_LENGTH 512
#define LENGTH_STRIDE 31
#define WARMUP_ROUNDS 3

static size_t message_length(size_t index) {
    size_t span = (size_t)(MAX_LENGTH - BASE_LENGTH + 1);
    return (size_t)BASE_LENGTH + ((index * LENGTH_STRIDE) % span);
}

static void generate_message(size_t index, uint8_t *buffer, size_t *out_length) {
    size_t length = message_length(index);
    for (size_t offset = 0; offset < length; ++offset) {
        buffer[offset] = (uint8_t)((index + offset) % 256);
    }
    *out_length = length;
}

static void warm_up(void) {
    uint8_t message[MAX_LENGTH];
    size_t length = 0;
    uint8_t digest[KECCAK256_DIGEST_LENGTH];
    for (int round = 0; round < WARMUP_ROUNDS; ++round) {
        for (size_t idx = 0; idx < NUM_MESSAGES; ++idx) {
            generate_message(idx, message, &length);
            keccak256(message, length, digest);
        }
    }
}

static double seconds_since(const struct timespec *start, const struct timespec *end) {
    double sec = (double)(end->tv_sec - start->tv_sec);
    double nsec = (double)(end->tv_nsec - start->tv_nsec) / 1e9;
    return sec + nsec;
}

static void run_benchmark(double *out_seconds, uint32_t *out_checksum) {
    uint8_t message[MAX_LENGTH];
    size_t length = 0;
    uint8_t digest[KECCAK256_DIGEST_LENGTH];
    uint32_t checksum = 0;
    struct timespec start;
    struct timespec end;

    warm_up();

    if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }

    for (int round = 0; round < ROUNDS; ++round) {
        for (size_t idx = 0; idx < NUM_MESSAGES; ++idx) {
            generate_message(idx, message, &length);
            keccak256(message, length, digest);
            checksum ^= digest[0];
        }
    }

    if (clock_gettime(CLOCK_MONOTONIC, &end) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }

    *out_seconds = seconds_since(&start, &end);
    *out_checksum = checksum;
}

static void print_table(const char *label, double seconds, double hashes_per_second, uint32_t checksum) {
    printf("implementation | seconds | hashes/s | checksum\n");
    printf("-------------- | ------- | -------- | --------\n");
    printf("%s | %.9f | %.2f | %u\n", label, seconds, hashes_per_second, checksum);
}

static void print_json(const char *label, double seconds, double hashes_per_second, uint32_t checksum) {
    printf("{\"implementation\": \"%s\", \"seconds\": %.12f, \"hashes_per_second\": %.2f, \"checksum\": %u}\n",
           label, seconds, hashes_per_second, checksum);
}

int main(int argc, char **argv) {
    const char *label = "c (tiny-sha3)";
    int emit_json = 0;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--json") == 0) {
            emit_json = 1;
        } else if (strcmp(argv[i], "--label") == 0 && i + 1 < argc) {
            label = argv[i + 1];
            ++i;
        }
    }

    double seconds = 0.0;
    uint32_t checksum = 0;
    run_benchmark(&seconds, &checksum);

    const double total_hashes = (double)(NUM_MESSAGES * ROUNDS);
    double throughput = seconds > 0.0 ? total_hashes / seconds : 0.0;

    if (emit_json) {
        print_json(label, seconds, throughput, checksum);
    } else {
        print_table(label, seconds, throughput, checksum);
    }

    return 0;
}
