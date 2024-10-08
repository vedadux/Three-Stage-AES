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

import json
from VerifMSI import *
import argparse

NUM_SHARES = 0

CELLS_INFO = {
    "$_AND_":   {"ins": ["A", "B"], "out": "Y"},
    "$_NAND_":  {"ins": ["A", "B"], "out": "Y"},
    "$_OR_":    {"ins": ["A", "B"], "out": "Y"},
    "$_NOR_":   {"ins": ["A", "B"], "out": "Y"},
    "$_XOR_":   {"ins": ["A", "B"], "out": "Y"},
    "$_XNOR_":  {"ins": ["A", "B"], "out": "Y"},
    "$_NOT_":   {"ins": ["A"], "out": "Y"},
    "$_ANDNOT_": {"ins": ["A", "B"], "out": "Y"},
    "$_ORNOT_":  {"ins": ["A", "B"], "out": "Y"},
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

def xnor_impl(a, b):
    return not_impl(xor_impl(a, b))


# def or_impl(a, b):
#     a_int, b_int = (type(a) is int), (type(b) is int)
#     if a_int and b_int:
#         return a | b
#     elif a_int:
#         return 1 if a else b
#     elif b_int:
#         return 1 if b else a
#     return orGate(a, b)

def or_impl(a, b):
    return not_impl(and_impl(not_impl(a), not_impl(b)))

def nand_impl(a, b):
    return not_impl(and_impl(a, b))

def nor_impl(a, b):
    return not_impl(or_impl(a, b))

def andnot_impl(a, b):
    return and_impl(a, not_impl(b))

def ornot_impl(a, b):
    return or_impl(a, not_impl(b))


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
    "$_NAND_":  nand_impl,
    "$_OR_":    or_impl,
    "$_NOR_":   nor_impl,
    "$_XOR_":   xor_impl,
    "$_XNOR_":  xnor_impl,
    "$_NOT_":   not_impl,
    "$_ANDNOT_": andnot_impl,
    "$_ORNOT_":  ornot_impl,
    "$_DFF_P_": dff_impl,
}

def parse_module(circuit_path):
    with open(circuit_path, "r") as f:
        data = json.load(f)
    modules = data["modules"]
    assert(len(modules) != 0)
    module_name = list(modules.keys())[0]
    module = modules[module_name]
    return module

def parse_spec(spec_path):
    with open(spec_path, "r") as f:
        return json.load(f)

def get_bit_names(module):
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
    return bit_names

def get_bit_defines(module):
    bit_defines = {}
    for cell_name, cell_info in module["cells"].items():
        cell_type = cell_info["type"]
        type_info = CELLS_INFO[cell_type]
        connections = cell_info["connections"]
        out_bit = connections[type_info["out"]][0]
        in_bits = [connections[port][0] for port in type_info["ins"]]
        bit_defines[out_bit] = (cell_type, in_bits)
    return bit_defines

def set_num_shares(num_shares):
    global NUM_SHARES
    if NUM_SHARES == 0:
        NUM_SHARES = num_shares
    assert(NUM_SHARES == num_shares)

def execute_circuit(ports, bit_defines, bit_names, spec):
    secrets = {}
    masks = {}
    outputs = []
    symbol_table = {}
    for port_id, port_info in ports.items():
        port_spec = spec[port_id]
        bits = port_info["bits"]
        if port_spec["type"] == "S":
            assert(port_info["direction"] == "input")
            num_secrets = port_spec["len"]
            assert(len(bits) % num_secrets == 0)
            num_shares = len(bits) // num_secrets
            set_num_shares(num_shares)
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
            assert(port_spec["len"] == "?" or port_spec["len"] == len(bits))
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
    for port_id, port_info in ports.items():
        port_spec = spec[port_id]
        bits = port_info["bits"]
        if port_spec["type"] == "O":
            assert(port_info["direction"] == "output")
            num_outputs = port_spec["len"]
            assert(len(bits) % num_outputs == 0)
            num_shares = len(bits) // num_outputs
            set_num_shares(num_shares)
            for i in range(num_outputs):
                positions = [j for j in range(i, len(bits), num_outputs)]
                share_bits = []
                shares = [evaluate(bits[p], bit_defines, symbol_table) for p in positions]
                outputs.append(tuple(shares))
    inverse_symbol_table = {sym.num: idx for idx, sym in symbol_table.items() if type(sym) is not int}
    return outputs, inverse_symbol_table

def get_args():
    parser = argparse.ArgumentParser(description="Encode a circuit for SILVER.")
    parser.add_argument("--circ", help="Path to the circuit JSON file")
    parser.add_argument("--spec", help="Path to the specification JSON file")

    return parser.parse_args()

def verify_circuit(outputs, inverse_symbol_table):
    AMOUNT_LEAKS = 100
    GLITCHES = True
    order = 1
    while order <= NUM_SHARES - 1:
        tups = checkSecurity(order, GLITCHES, "pini", *outputs)
        if tups[0] != 0: 
            print(tups)
            for t in tups[2]:
                print([bit_names[inverse_symbol_table[ti]][0] for ti in t])
            break
        order += 1

if __name__ == "__main__":
    args = get_args()
    module = parse_module(args.circ)
    spec = parse_spec(args.spec)
    bit_names = get_bit_names(module)
    bit_defines = get_bit_defines(module)
    outputs, inverse_symbol_table = execute_circuit(module["ports"], bit_defines, bit_names, spec)
    verify_circuit(outputs, inverse_symbol_table)
