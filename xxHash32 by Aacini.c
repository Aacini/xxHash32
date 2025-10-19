/****************************************************************
*	xxHash32 - Copyright (C) 2012-2023 Yann Collet		*
*	https://github.com/Cyan4973/xxHash			*
*								*
*	This is a simplified version of xxh32 C++ original code	*
*	This version written by Antonio Perez Ayala aka Aacini	*
*	antonio.perez.ayala@gmail.com				*
*	https://www.apaacini.com				*
****************************************************************/

#include <stdio.h>
#include <stdint.h>
#include <string.h>

// Rotate left an uint32 (circular shift)
uint32_t rotl(uint32_t v, int x) {
    return (v << x) | (v >> (32 - x));
}

// Read 1 byte as uint8
uint8_t read_u8(const char* input, int pos) {
    return static_cast<uint8_t>(input[pos]);
}

// Read 4 bytes as uint32 little-endian
uint32_t read_u32le(const char* input, int pos) {
    const uint32_t b0 = read_u8(input, pos + 0);
    const uint32_t b1 = read_u8(input, pos + 1);
    const uint32_t b2 = read_u8(input, pos + 2);
    const uint32_t b3 = read_u8(input, pos + 3);
    return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
}

    constexpr uint32_t PRIME32_1 = 0x9E3779B1U;
    constexpr uint32_t PRIME32_2 = 0x85EBCA77U;
    constexpr uint32_t PRIME32_3 = 0xC2B2AE3DU;
    constexpr uint32_t PRIME32_4 = 0x27D4EB2FU;
    constexpr uint32_t PRIME32_5 = 0x165667B1U;


uint32_t xxh32(const char* input, int len, uint32_t seed) {
    int pos = 0;
    uint32_t h32 = 0;

    int blocks16 = len / 16;	// new variable
    int rest = len % 16;	// new variable

    // XXH32 PROCESS BLOCKS OF 16 BYTES
    if (blocks16 > 0) {

        uint32_t v1 = seed + PRIME32_1 + PRIME32_2;
        uint32_t v2 = seed + PRIME32_2;
        uint32_t v3 = seed;
        uint32_t v4 = seed - PRIME32_1;

        for ( int i = 1; i <= blocks16; i++ ) {

            // // "round 0"
            v1 += read_u32le(input, pos + 0*4) * PRIME32_2;
            v1 = rotl(v1, 13) * PRIME32_1;

            // // "round 1"
            v2 += read_u32le(input, pos + 1*4) * PRIME32_2;
            v2 = rotl(v2, 13) * PRIME32_1;

            // // "round 2"
            v3 += read_u32le(input, pos + 2*4) * PRIME32_2;
            v3 = rotl(v3, 13) * PRIME32_1;

            // // "round 3"
            v4 += read_u32le(input, pos + 3*4) * PRIME32_2;
            v4 = rotl(v4, 13) * PRIME32_1;

            pos += 16;

        }

    // // "digest" (bad nesting)

        h32 = rotl(v1, 1) + rotl(v2, 7) + rotl(v3, 12) + rotl(v4, 18);

    } else {

        // If len less 16: initialize h32 with seed + PRIME32_5
        h32 = seed + PRIME32_5;

    }

    h32 += (uint32_t) len;

    // // "finalize"

    // XXH32 PROCESS BLOCKS OF 4 BYTES
    int blocks4 = rest / 4;	// new variable
    for ( i = 1; i <= blocks4; i++ ) {
        h32 += read_u32le(input, pos) * PRIME32_3;
        h32 = rotl(h32, 17) * PRIME32_4;
        pos += 4;
    }

    // XXH32 PROCESS BLOCKS OF 1 BYTE
    int blocks1 = rest % 4;	// new variable
    for ( i = 1; i <= blocks1; i++ ) {
        h32 += read_u8(input, pos) * PRIME32_5;
        h32 = rotl(h32, 11) * PRIME32_1;
        pos += 1;
    }

    // // "avalanche"
    h32 ^= h32 >> 15;
    h32 *= PRIME32_2;
    h32 ^= h32 >> 13;
    h32 *= PRIME32_3;
    h32 ^= h32 >> 16;

    return h32;

}

