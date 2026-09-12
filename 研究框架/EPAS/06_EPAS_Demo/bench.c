#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#if defined(__GNUC__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif


static NOINLINE uint64_t branch_kernel(size_t n) {
    uint64_t checksum = 0;
    uint32_t state = UINT32_C(2166136261);

    for (size_t i = 0; i < n; ++i) {
        state ^= (uint32_t)i + UINT32_C(0x9e3779b9);
        state *= UINT32_C(16777619);
        if ((state & UINT32_C(7)) < UINT32_C(3)) {
            checksum += (uint64_t)(state % UINT32_C(97));
        } else {
            checksum ^= (uint64_t)(state % UINT32_C(89)) + (uint64_t)i;
        }
    }
    return checksum;
}


static NOINLINE uint64_t vector_kernel(size_t n) {
    int32_t *left = (int32_t *)malloc(n * sizeof(*left));
    int32_t *right = (int32_t *)malloc(n * sizeof(*right));
    int32_t *output = (int32_t *)malloc(n * sizeof(*output));
    uint64_t checksum = 0;

    if (left == NULL || right == NULL || output == NULL) {
        free(left);
        free(right);
        free(output);
        return UINT64_MAX;
    }

    for (size_t i = 0; i < n; ++i) {
        left[i] = (int32_t)(i % 1009U);
        right[i] = (int32_t)((i * 7U) % 1013U);
    }
    for (size_t i = 0; i < n; ++i) {
        output[i] = left[i] * 3 + right[i] * 5;
    }
    for (size_t i = 0; i < n; ++i) {
        checksum += (uint32_t)output[i];
    }

    free(left);
    free(right);
    free(output);
    return checksum;
}


int main(int argc, char **argv) {
    char *end = NULL;
    unsigned long long parsed = 0;
    uint64_t checksum = 0;

    if (argc != 3) {
        fprintf(stderr, "usage: %s <branch|vector> <positive-size>\n", argv[0]);
        return 2;
    }

    parsed = strtoull(argv[2], &end, 10);
    if (end == argv[2] || *end != '\0' || parsed == 0 || parsed > SIZE_MAX) {
        fprintf(stderr, "size must be a positive integer within size_t range\n");
        return 2;
    }

    if (strcmp(argv[1], "branch") == 0) {
        checksum = branch_kernel((size_t)parsed);
    } else if (strcmp(argv[1], "vector") == 0) {
        checksum = vector_kernel((size_t)parsed);
        if (checksum == UINT64_MAX) {
            fprintf(stderr, "allocation failed\n");
            return 3;
        }
    } else {
        fprintf(stderr, "unknown kernel: %s\n", argv[1]);
        return 2;
    }

    printf("%" PRIu64 "\n", checksum);
    return 0;
}
