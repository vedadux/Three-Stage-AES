import json
from verif_msi import *

FILE_PATH = "syn/syn_masked_aes_sbox_fwd_2_pre.json"

CELLS_INFO = {
    "$_AND_":   {"ins": ["A", "B"], "out": "Y"},
    "$_XOR_":   {"ins": ["A", "B"], "out": "Y"},
    "$_NOT_":   {"ins": ["A"], "out": "Y"},
    "$_DFF_P_": {"ins": ["D"], "out": "Q"},
}

def and_impl(a, b):
    a_int, b_int = (type(a) is int), (type(b) is int)
    if a_int and b_int:
        return a & b
    elif a_int:
        return b if a else 0
    elif b_int:
        return a if b else 0
    return andGate(a, b)

def not_impl(a):
    if type(a) is int: 
        return 1 - a
    return notGate(a)

def xor_impl(a, b):
    a_int, b_int = (type(a) is int), (type(b) is int)
    if a_int and b_int:
        return a ^ b
    elif a_int:
        return not_impl(b) if a else b
    elif b_int:
        return not_impl(a) if b else a
    return xorGate(a, b)

def dff_impl(d):
    if type(d) is int:
        return d
    return Register(d)

def evaluate(bit, bit_defines, symbol_table):
    if bit in symbol_table:
        return symbol_table[bit]
    func, ins = bit_defines[bit]
    inputs = [evaluate(b, bit_defines, symbol_table) for b in ins]
    result = CELL_IMPL[func](*inputs)
    symbol_table[bit] = result
    return result

CELL_IMPL = {
    "$_AND_":   and_impl,
    "$_XOR_":   xor_impl,
    "$_NOT_":   not_impl,
    "$_DFF_P_": dff_impl,
}

with open(FILE_PATH, "r") as f:
    data = json.load(f)
modules = data["modules"]
assert(len(modules) != 0)
module_name = list(modules.keys())[0]
print(module_name)

module = modules[module_name]

bit_names = {}
for name_id, name_info in module["netnames"].items():
    real_name = name_id
    if "attributes" in name_info and "hdlname" in name_info["attributes"]:
        real_name = ".".join(name_info["attributes"]["hdlname"].split())
    assert("bits" in name_info)
    for idx, bit in enumerate(name_info["bits"]):
        suffix = "" if len(name_info["bits"]) == 1 else f"[{idx}]"
        if bit not in bit_names:
            bit_names[bit] = []
        bit_names[bit].append(real_name + suffix)

bit_defines = {}
for cell_name, cell_info in module["cells"].items():
    cell_type = cell_info["type"]
    type_info = CELLS_INFO[cell_type]
    connections = cell_info["connections"]
    out_bit = connections[type_info["out"]][0]
    in_bits = [connections[port][0] for port in type_info["ins"]]
    bit_defines[out_bit] = (cell_type, in_bits)

# perform the execution

SPEC = {"in_a" : {"type": "S", "len": 8},
        "in_random" : {"type": "M", "len": None}, 
        "out_b": {"type": "O", "len": 8}, 
        "in_clock": {"type": 1, "len": 1},
        "in_reset": {"type": 0, "len": 1}}

secrets = {}
masks = {}
outputs = []
symbol_table = {}
for port_id, port_info in module["ports"].items():
    port_spec = SPEC[port_id]
    bits = port_info["bits"]
    if port_spec["type"] == "S":
        assert(port_info["direction"] == "input")
        num_secrets = port_spec["len"]
        assert(len(bits) % num_secrets == 0)
        num_shares = len(bits) // num_secrets
        for i in range(num_secrets):
            positions = [j for j in range(i, len(bits), num_secrets)]
            assert(len(positions) == num_shares), f"{positions}"
            secret = symbol(f"s_{len(secrets)}", "S", 1)
            secrets[(port_id, i)] = secret
            shares = getRealShares(secret, num_shares)
            for p, sh in zip(positions, shares):
                print(f"Adding {port_id}[{p}] with bit {bits[p]}: {sh}")
                symbol_table[bits[p]] = inputGate(sh)
    elif port_spec["type"] == "M":
        assert(port_info["direction"] == "input")
        assert(port_spec["len"] == None)
        for idx, bit in enumerate(bits):
            mask = symbol(f"m_{len(masks)}", "M", 1)
            masks[(port_id, idx)] = mask
            symbol_table[bit] = inputGate(mask)
    elif type(port_spec["type"]) is int:
        assert(port_info["direction"] == "input")
        value = port_spec["type"]
        assert(port_spec["len"] == len(bits))
        for idx, bit in enumerate(bits):
            symbol_table[bit] = (value >> idx) & 1
for port_id, port_info in module["ports"].items():
    port_spec = SPEC[port_id]
    bits = port_info["bits"]
    if port_spec["type"] == "O":
        assert(port_info["direction"] == "output")
        num_outputs = port_spec["len"]
        assert(len(bits) % num_outputs == 0)
        num_shares = len(bits) // num_secrets
        for i in range(num_outputs):
            positions = [j for j in range(i, len(bits), num_secrets)]
            share_bits = []
            shares = [evaluate(bits[p], bit_defines, symbol_table) for p in positions]
            outputs.append(tuple(shares))

# print(outputs)

GLITCHES = True

inverse_symbol_table = {sym.num: idx for idx, sym in symbol_table.items() if type(sym) is not int}

order = 1
while True:
    tups = checkSecurity(order, GLITCHES, "pini", *outputs)
    if tups[0] != 0: 
        print(tups)
        for t in tups[2]:
            print([bit_names[inverse_symbol_table[ti]][0] for ti in t])
        break
