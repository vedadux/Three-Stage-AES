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

# coding: utf-8

RAND_GE = 39.4

my_data = [
    [
        [ 32,  1875.7],
        [ 96,  4176.3],
        [192,  7687.7],
        [320, 11465.0],
    ], [
        [ 29, 1806.3],
        [ 96, 3880.0],
        [192, 6563.0],
        [300, 9893.0],
    ] , [
        [ 34,  1905.0],
        [ 96,  4126.0],
        [192,  7215.7],
        [310, 10899.7],
    ]
]

sota_data = [
    [ # AGEMA \cite{DBLP:journals/tches/KnichelMMS22} HPC1 Optimized Pipelined\tnote{1}
        [ 68,  4263], 
        [170,  7839],
        [340, 12085],
        [510, 16919],
    ], [ # AGEMA \cite{DBLP:journals/tches/KnichelMMS22} HPC2 Optimized Pipelined\tnote{1}
        [ 34,  5339],
        [102, 11205],
        [204, 19217],
        [340, 29267],
    ], [ # Handcrafting \cite{DBLP:conf/cosade/MominCS22} HPC2\tnote{2}
        [ 34,  3213],
        [102,  6705],
        [204, 11515],
    ], [ # Low-Latency \cite{DBLP:conf/ccs/Knichel022} HPC3\tnote{3}
        [ 68,  1849],
        [204,  4855],
        [408,  9261],
    ], [ # AGMNC \cite{DBLP:journals/iacr/WuFPWW23} AND-XOR1\tnote{3}
        [ 66,  2895],
        [165,  5745],
        [330,  9243],
        [495, 13314],
    ], [ # AGMNC \cite{DBLP:journals/iacr/WuFPWW23} AND-XOR2\tnote{3}
        [ 33,  3967],
        [ 99,  9078],
        [198, 16239],
        [330, 25469],
    ], [ # Compress \cite{compress} BP bit-level\tnote{1}
        [ 46,  2780],
        [138,  6790],
        [276, 12960],
        [460, 20450],
    ], [ # Compress \cite{compress} Canright (with fields)\tnote{1}
        [ 36,  1950],
        [ 96,  4560],
        [192,  8060],
        [300, 12480],
    ]
]

for data in my_data:
    for arr in data:
        assert(len(arr) == 2)
        arr.append(arr[0] * RAND_GE + arr[1])

for data in sota_data:
    for arr in data:
        assert(len(arr) == 2)
        arr.append(arr[0] * RAND_GE + arr[1])

for sdata in sota_data + my_data:
    for r_sota, r_3lat, r_4lat in zip(sdata, my_data[0], my_data[1]):
        comp_3 = [(1 - new/old) * 100 for new, old in zip(r_3lat, r_sota)]
        comp_4 = [(1 - new/old) * 100 for new, old in zip(r_4lat, r_sota)]
        assert(len(r_sota) == len(r_3lat) and len(r_sota) == len(r_4lat))
        for i in range(len(r_sota)):    
            print(f"& {int(r_sota[i]):5d} & \\tblchange{{{comp_3[i]:5.1f}\\%}}{{{comp_4[i]:5.1f}\\%}} ", end="")
        print("\\\\")
    print()
