#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t kernel(uint32_t n) {
    uint64_t sum = 0;
    for (uint32_t i = 0; i < n; ++i) {
        uint32_t x = i * 1664525u + 1013904223u;
        if ((x & 7u) < 5u)
            sum += (uint64_t)(x ^ (x >> 11));
        else
            sum -= (uint64_t)(x * 3u + 1u);
    }
    return sum;
}

int main(int argc, char **argv) {
    uint32_t n = argc > 1 ? (uint32_t)strtoul(argv[1], NULL, 10) : 30000000u;
    printf("%llu\n", (unsigned long long)kernel(n));
    return 0;
}
