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

"""