// 
// Copyright (C) 2024 Vedad Hadžić
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 

// Based on the C implementation of the AES S-Box by David Canright

#include <cstdio>
#include <cassert>
#include "gf_operations.h"

/// The representation used is Sigma = W^2, s = Sigma^2 * Z, p = 1, Pi = 1

/// @brief Extracts bits x[high:low] (inclusive)
/// @param x    Source to extract from
/// @param high Highest extracted bit
/// @param low  Lowest extracted bit
/// @return Extraction result
inline uint64_t extract(uint64_t x, int64_t high, int64_t low)
{
    assert(high >= 0 && high <= 63);
    assert(low >= 0 && low <= 63);
    assert(high >= low);

    x >>= low;
    const uint64_t size = high - low + 1;
    const uint64_t mask = (1LU << size) - 1;
    return x & mask;
}

uint64_t gf_4_mul(uint64_t x, uint64_t y)
{
    uint64_t xh = extract(x, 1, 1); 
    uint64_t xl = extract(x, 0, 0);
    uint64_t yh = extract(y, 1, 1);
    uint64_t yl = extract(y, 0, 0);

    uint64_t m_mul = (xh ^ xl) & (yh ^ yl);
    uint64_t h_mul = (xh & yh);
    uint64_t l_mul = (xl & yl);
    
    uint64_t zh = h_mul ^ m_mul;
    uint64_t zl = l_mul ^ m_mul;
    
    return (zh << 1) | (zl << 0);
}

uint64_t gf_4_scl_sigma(uint64_t x)
{
    uint64_t xh = extract(x, 1, 1); 
    uint64_t xl = extract(x, 0, 0);
    uint64_t yh = xl;
    uint64_t yl = xh ^ xl;
    return (yh << 1) | (yl << 0);
}

uint64_t gf_4_scl_sigma2(uint64_t x)
{
    uint64_t xh = extract(x, 1, 1); 
    uint64_t xl = extract(x, 0, 0);
    uint64_t yh = xh ^ xl;
    uint64_t yl = xh;
    return (yh << 1) | (yl << 0);
}

uint64_t gf_4_sq(uint64_t x)
{
    uint64_t xh = extract(x, 1, 1); 
    uint64_t xl = extract(x, 0, 0);
    uint64_t yh = xl, yl = xh;
    return (yh << 1) | (yl << 0);
}

uint64_t gf_16_mul(uint64_t x, uint64_t y) 
{
    uint64_t xh = extract(x, 3, 2); 
    uint64_t xl = extract(x, 1, 0);
    uint64_t yh = extract(y, 3, 2);
    uint64_t yl = extract(y, 1, 0);

    uint64_t m_mul = gf_4_mul(xh ^ xl, yh ^ yl);
    m_mul = gf_4_scl_sigma(m_mul);
    uint64_t h_mul = gf_4_mul(xh, yh);
    uint64_t l_mul = gf_4_mul(xl, yl);
    
    uint64_t zh = h_mul ^ m_mul;
    uint64_t zl = l_mul ^ m_mul;
    
    return (zh << 2) | (zl << 0);
}

uint64_t gf_16_sq_scl_s(uint64_t x)
{
    uint64_t xh = extract(x, 3, 2); 
    uint64_t xl = extract(x, 1, 0);
    uint64_t yh = gf_4_sq(xh ^ xl);
    uint64_t yl = gf_4_scl_sigma2(gf_4_sq(xl));
    return (yh << 2) | (yl << 0);
}

uint64_t gf_16_inv_canright(uint64_t x)
{
    uint64_t xh = extract(x, 3, 2); 
    uint64_t xl = extract(x, 1, 0);
    uint64_t aa = gf_4_scl_sigma(gf_4_sq(xh ^ xl));
    uint64_t bb = gf_4_mul(xh, xl);
    uint64_t cc = gf_4_sq(aa ^ bb); // inverse
    uint64_t yh = gf_4_mul(cc, xl);
    uint64_t yl = gf_4_mul(cc, xh);
    return (yh << 2) | (yl << 0);
}

uint64_t gf_16_inv_new(uint64_t x)
{
    uint64_t x0 = extract(x, 0, 0);
    uint64_t x1 = extract(x, 1, 1);
    uint64_t x2 = extract(x, 2, 2);
    uint64_t x3 = extract(x, 3, 3);

    uint64_t a0 = x1 ^ x0; // depth(1)
    uint64_t a1 = x3 ^ x2; // depth(1)
    uint64_t b0 = x2 & x0; // depth(1)
    uint64_t b1 = x3 & x1; // depth(1)
    uint64_t c0 = a0 ^ b0; // depth(2)
    uint64_t c1 = a1 ^ b0; // depth(2)
    uint64_t d0 = x0 ^ b1; // depth(2)
    uint64_t d1 = x2 ^ b1; // depth(2)
    uint64_t e0 = x3 & c0; // depth(3)
    uint64_t e1 = x1 & c1; // depth(3)
    uint64_t f0 = a1 & d0; // depth(3)
    uint64_t f1 = a0 & d1; // depth(3)
    uint64_t y3 = a0 ^ e1; // depth(4)
    uint64_t y2 = x0 ^ f1; // depth(4)
    uint64_t y1 = a1 ^ e0; // depth(4)
    uint64_t y0 = x2 ^ f0; // depth(4)

    return (y3 << 3) | (y2 << 2) | (y1 << 1) | (y0 << 0);
}

uint64_t gf_256_inv_canright(uint64_t x)
{
    uint64_t xh = extract(x, 7, 4); 
    uint64_t xl = extract(x, 3, 0);
    uint64_t aa = gf_16_sq_scl_s(xh ^ xl);
    uint64_t bb = gf_16_mul(xh, xl);
    uint64_t cc = gf_16_inv_new(aa ^ bb);
    uint64_t yh = gf_16_mul(cc, xl);
    uint64_t yl = gf_16_mul(cc, xh);
    return (yh << 4) | (yl << 0);
}

uint64_t gf_256_switch_basis(uint64_t x, const uint64_t* basis)
{
    uint64_t y = 0;
    for (int i = 7; i >= 0; i -= 1)
    {
        if (x & 1) y ^= basis[i];
        x >>= 1;
    }
    return y;
}

uint64_t aes_sbox(uint64_t x, uint64_t(*gf_256_inv_fun)(uint64_t))
{
    uint64_t y;
    y = gf_256_switch_basis(x, A2X);
    y = gf_256_inv_fun(y);
    y = gf_256_switch_basis(y, X2S);
    return y ^ 0x63;
}

uint64_t aes_inv_sbox(uint64_t x, uint64_t(*gf_256_inv_fun)(uint64_t))
{
    uint64_t y;
    y = gf_256_switch_basis(x ^ 0x63, S2X);
    y = gf_256_inv_fun(y);
    y = gf_256_switch_basis(y, X2A);
    return y;
}