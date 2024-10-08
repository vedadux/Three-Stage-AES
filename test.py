# 
# Copyright (C) 2024 Vedad Hadžić
# 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 

GE = 0.798
RANDOM_BIT_GE = 39.4

print(1593.074000 / GE)
print(3450.552000 / GE)
print(6233.710000 / GE)
print(9497.796000 / GE)

print(1572.592000 / GE)
print(3328.458000 / GE)
print(5973.030000 / GE)
print(9053.310000 / GE)

print("after repair")
print(1521.254000 / GE)
print(3380.594000 / GE)
print(6010.536000 / GE)
print(9045.596000 / GE)

print("HPC3 variant")

cost = [
    1475.502000,
    3518.116000,
    6204.184000,
    9308.936000,
]

bits = [
    (31  + 1),
    (95  + 1),
    (191 + 1),
    (319 + 1),
]

for c,b in zip(cost, bits):
    print(f"{(c / GE):9.2f} | {(c / GE + b * RANDOM_BIT_GE):9.2f}")

print("HPC1 variant")

cost = [
    1639.890000,
    3409.588000,
    5965.582000,
    9023.518000,
]

bits = [
    (33  + 1),
    (105 + 1),
    (211 + 1),
    (339 + 1),
]

for c,b in zip(cost, bits):
    print(f"{(c / GE):9.2f} | {(c / GE + b * RANDOM_BIT_GE):9.2f}")


"""
[00002.514166]    Chip area for module '\masked_aes_sbox_fwd': 1490.664000
[00004.390241]    Chip area for module '\masked_aes_sbox_fwd': 3441.508000
[00007.007593]    Chip area for module '\masked_aes_sbox_fwd': 6216.420000
[00011.527108]    Chip area for module '\masked_aes_sbox_fwd': 9192.428000

[00002.661111]    Chip area for module '\masked_aes_sbox_fwd': 1478.960000
[00004.952743]    Chip area for module '\masked_aes_sbox_fwd': 3358.782000
[00007.853562]    Chip area for module '\masked_aes_sbox_fwd': 6123.054000
[00011.669182]    Chip area for module '\masked_aes_sbox_fwd': 9144.282000

[00002.756107]    Chip area for module '\masked_aes_sbox_fwd': 1547.056000
[00004.745920]    Chip area for module '\masked_aes_sbox_fwd': 3337.236000
[00007.806306]    Chip area for module '\masked_aes_sbox_fwd': 5757.038000
[00011.665515]    Chip area for module '\masked_aes_sbox_fwd': 8708.308000

[00002.897019]    Chip area for module '\masked_aes_sbox_fwd': 1553.440000
[00004.804057]    Chip area for module '\masked_aes_sbox_fwd': 3352.930000
[00007.759963]    Chip area for module '\masked_aes_sbox_fwd': 5748.526000
[00011.796041]    Chip area for module '\masked_aes_sbox_fwd': 8685.432000

// old inv hpc1 last stage
[00001.342639]    Chip area for module '\masked_test_parallel_hpc1_ls':  598.500000
[00001.975096]    Chip area for module '\masked_test_parallel_hpc1_ls': 1285.578000
[00003.097657]    Chip area for module '\masked_test_parallel_hpc1_ls': 2192.106000
[00004.541785]    Chip area for module '\masked_test_parallel_hpc1_ls': 3259.298000
input [3:0] in_r_raw_ab;
input [3:0] in_r_raw_ac;
input [7:0] in_r_raw_ab;
input [7:0] in_r_raw_ac;
input [15:0] in_r_raw_ab;
input [15:0] in_r_raw_ac;
input [19:0] in_r_raw_ab;
input [19:0] in_r_raw_ac;
// old inv hpc3 last stage
[00001.363231]    Chip area for module '\masked_test_parallel_hpc3_ls':  647.976000
[00002.119960]    Chip area for module '\masked_test_parallel_hpc3_ls': 1400.490000
[00003.292575]    Chip area for module '\masked_test_parallel_hpc3_ls': 2449.062000
[00004.868497]    Chip area for module '\masked_test_parallel_hpc3_ls': 3781.988000
input [3:0] in_r;
input [11:0] in_r;
input [23:0] in_r;
input [39:0] in_r;
"""

cost = [
     598.500000,
    1285.578000,
    2192.106000,
    3259.298000,
]

bits = [
    2 * ( 3 + 1),
    2 * ( 7 + 1),
    2 * (15 + 1),
    2 * (19 + 1),
]

for c,b in zip(cost, bits):
    print(f"HPC1 {(c / GE):9.2f} | {(c / GE + b * RANDOM_BIT_GE):9.2f}")


cost = [
     647.976000,
    1400.490000,
    2449.062000,
    3781.988000,
]

bits = [
    ( 3 + 1),
    (11 + 1),
    (23 + 1),
    (39 + 1),
]

for c,b in zip(cost, bits):
    print(f"HPC3 {(c / GE):9.2f} | {(c / GE + b * RANDOM_BIT_GE):9.2f}")



area = """
[00000.640166]    Chip area for module '\masked_hpc3_1_mul': 51.604000
[00000.780512]    Chip area for module '\masked_hpc3_1_mul': 126.882000
[00000.782613]    Chip area for module '\masked_hpc3_1_mul': 234.080000
[00001.107227]    Chip area for module '\masked_hpc3_1_mul': 372.400000
"""
rands = """
input in_p;
input in_r;
input [2:0] in_p;
input [2:0] in_r;
input [5:0] in_p;
input [5:0] in_r;
input [9:0] in_p;
input [9:0] in_r;
"""

import re