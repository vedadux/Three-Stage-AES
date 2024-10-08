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

import z3
import functools

solver = z3.Solver()

def x(d): return (d) * (d-1) // 2

def y(d): 
    if d in (2, 3): return d - 1
    if d in (4, 5): return d
    assert(False)

NUM_SHARES = 4

HPC1_COSTS = {
    4: { 2: 271.852000 ,
         3: 570.570000 ,
         4: 976.752000 ,
         5: 1490.930000, },
    2: { 2: 102.144000,
         3: 216.258000,
         4: 372.400000,
         5: 570.570000, }
}

HPC3_COSTS = {
    4: { 2: 354.578000 ,
         3: 804.650000 ,
         4: 1407.672000,
         5: 2232.006000, },
    2: { 2: 133.532000,
         3: 311.220000,
         4: 562.856000,
         5: 891.100000, }
}

GE = 0.798
RANDOM_BIT_COST = 39.4 * GE
MASKED_ZERO_COST = 9.044000

class Signal:
    SIZES = {}
    HPC1_REFS = {}
    HPC3_REFS = {}
    def __init__(self, name, width, latency=0, rhpc1=False, rhpc3=False):
        global solver
        self.name = name
        self.width = width
        self.latency = latency
        self.SIZES[self.name] = self.width
        
        rhpc1_new = z3.Bool(f"{name}_hpc1_ref")
        rhpc3_new = z3.Bool(f"{name}_hpc3_ref")
        self.HPC1_REFS[self.name] = rhpc1_new
        self.HPC3_REFS[self.name] = rhpc3_new
        
        self.hpc1_refresh = z3.Or(rhpc1_new, rhpc1)
        self.hpc3_refresh = z3.Or(rhpc3_new, rhpc3)
    def split(self):
        assert(self.width % 2 == 0)
        return (Signal(f"{self.name}_l", self.width // 2, self.latency, self.hpc1_refresh, self.hpc3_refresh),
                Signal(f"{self.name}_h", self.width // 2, self.latency, self.hpc1_refresh, self.hpc3_refresh))


def max_lat(*args):
    assert(len(args) >= 1)
    best = max(filter(lambda x: type(x) is int, args), default=None)
    sym_args = filter(lambda x: type(x) is not int, args)
    if best is None:
        return functools.reduce(lambda a, b: z3.If(a < b, b, a), sym_args)
    else:
        return functools.reduce(lambda a, b: z3.If(a < b, b, a), sym_args, best)


def lin_comb(sigs, z_name, z_width):
    latencies = map(lambda sig: sig.latency, sigs)
    return Signal(z_name, z_width, max_lat(*latencies))    

def bool2int(x):
    return z3.If(x, 1, 0)


def hpc1(x, y, z_name, active):
    global solver
    assert(x.width == y.width)
    z_width = x.width
    z_lat = max_lat(bool2int(x.hpc1_refresh) + x.latency, bool2int(y.hpc1_refresh) + y.latency) + 1
    solver.add(z3.Implies(active, z3.Or(x.hpc1_refresh, y.hpc1_refresh)))
    return Signal(z_name, z_width, z_lat)


def hpc3(x, y, z_name, active):
    global solver
    assert(x.width == y.width)
    z_width = x.width
    z_lat = max_lat(x.latency, y.latency) + 1
    solver.add(z3.Implies(active, z3.Or(x.hpc3_refresh, y.hpc3_refresh)))
    return Signal(z_name, z_width, z_lat)


MUL_TYPE = {}

def mul(x, y, z_name):
    global MUL_TYPE
    assert(x.width == y.width)
    z_width = x.width
    choice = z3.Bool(f"{z_name}_is_hpc3")
    hpc3_gadget = hpc3(x, y, f"{z_name}_hpc1_version", choice)
    hpc1_gadget = hpc1(x, y, f"{z_name}_hpc3_version", z3.Not(choice))
    z_lat = z3.If(choice, hpc3_gadget.latency, hpc1_gadget.latency)
    assert(z_name not in MUL_TYPE)
    MUL_TYPE[z_name] = choice
    return Signal(z_name, z_width, z_lat)

def new_sbox():
    a = Signal("a", 8)
    a0, a1 = a.split()

    a0_c = lin_comb([a0], "a0_c", 4)
    a1_c = lin_comb([a1], "a1_c", 4)

    b = mul(a0, a1, "b")
    c = lin_comb([a0, a1, b], "c", 4)

    d0 = mul(a0_c, c, "d0")
    d1 = mul(a1_c, c, "d1")

    cl, ch = c.split()
    e = mul(cl, ch, "e")
    f = lin_comb([cl, ch, e], "f", 2)

    d0l, d0h = d0.split()
    d1l, d1h = d1.split()
    gs = []
    for i,dd in enumerate([d0l, d0h, d1l, d1h]):
        gs.append(mul(f, dd, f"g{i}"))

    h = lin_comb(gs, "h", 8)
    solver.add(h.latency <= 4)


def old_sbox():
    a = Signal("a", 8)
    a0, a1 = a.split()

    a0_f = lin_comb([a0], "a0_f", 4)
    a1_f = lin_comb([a1], "a1_f", 4)

    b = mul(a0, a1, "b")
    c = lin_comb([a0, a1, b], "c", 4)

    cl, ch = c.split()
    cl_e = lin_comb([cl], "cl_e", 2)
    ch_e = lin_comb([ch], "ch_e", 2)
    
    d = mul(cl, ch, "d")
    e = lin_comb([cl, ch, d], "e", 2)
    fl = mul(ch_e, e, "fl")
    fh = mul(cl_e, e, "fh")
    f = lin_comb([fl, fh], "f", 4)
    
    g0 = mul(a1_f, f, "g0")
    g1 = mul(a0_f, f, "g1")
    
    h = lin_comb([g0, g1], "h", 8)
    solver.add(h.latency <= 4)


old_sbox()

def get_ref_cost_hpc1(ref, name):
    rand_bits = ref * y(NUM_SHARES) * Signal.SIZES[name]
    share_zero = ref * NUM_SHARES * Signal.SIZES[name]
    return rand_bits * int(RANDOM_BIT_COST) + share_zero * int(MASKED_ZERO_COST)

def get_ref_cost_hpc3(ref, name):
    rand_bits = ref * x(NUM_SHARES) * Signal.SIZES[name]
    return rand_bits * int(RANDOM_BIT_COST)

def get_mul_cost(is_hpc3, name):
    hpc3_cost = int(HPC3_COSTS[Signal.SIZES[name]][NUM_SHARES])
    hpc1_cost = int(HPC1_COSTS[Signal.SIZES[name]][NUM_SHARES])
    rand_bits = x(NUM_SHARES) * Signal.SIZES[name]
    return z3.If(is_hpc3, hpc3_cost, hpc1_cost) + rand_bits * int(RANDOM_BIT_COST)

ref_cost_hpc1 = [get_ref_cost_hpc1(ref, name) for name, ref in Signal.HPC1_REFS.items()]
ref_cost_hpc3 = [get_ref_cost_hpc3(ref, name) for name, ref in Signal.HPC3_REFS.items()]
ref_cost_outer = [get_mul_cost(is_hpc3, name) for name, is_hpc3 in MUL_TYPE.items()]
total_cost = functools.reduce(lambda a, b: a + b, ref_cost_hpc1 + ref_cost_hpc3 + ref_cost_outer)

rand_cost_hpc1 = [ref * y(NUM_SHARES) * Signal.SIZES[name] for name, ref in Signal.HPC1_REFS.items()]
rand_cost_hpc3 = [ref * x(NUM_SHARES) * Signal.SIZES[name] for name, ref in Signal.HPC3_REFS.items()]
rand_cost_outer = [x(NUM_SHARES) * Signal.SIZES[name] for name, is_hpc3 in MUL_TYPE.items()]
rand_cost = functools.reduce(lambda a, b: a + b, rand_cost_hpc1 + rand_cost_hpc3 + rand_cost_outer)


target_cost = total_cost

cost = None
while True:
    solver.push()
    if cost is not None:
        solver.add(target_cost < cost)
    res = solver.check()
    if res == z3.sat:
        model = solver.model()
        cost = model.eval(target_cost, True)
        print("\n")
        print(f"Target cost: {cost.as_long()}")
        print(f"Area cost: {model.eval(total_cost).as_long()}")
        print(f"Rand cost: {model.eval(rand_cost).as_long()}")        
        for r in Signal.HPC1_REFS.values():
            print(f"{r} = {model.eval(r)}")
        for r in Signal.HPC3_REFS.values():
            print(f"{r} = {model.eval(r)}")
        for c in MUL_TYPE.values():
            print(f"{c} = {model.eval(c)}")
    elif res == z3.unsat:
        break
    else:
        print("Unknown")
        break
    solver.pop()