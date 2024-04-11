# coding: utf-8

import z3
import functools

solver = z3.Solver()

def x(d): return (d) * (d-1) // 2

def y(d): 
    if d in (2, 3): return d - 1
    if d in (4, 5): return d
    assert(False)

NUM_SHARES = 5

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
    def __init__(self, name, width, latency=0):
        self.name = name
        self.width = width
        self.latency = latency
        self.SIZES[self.name] = self.width
    def split(self):
        assert(self.width % 2 == 0)
        return (Signal(f"{self.name}_l", self.width // 2, self.latency),
                Signal(f"{self.name}_h", self.width // 2, self.latency))


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


HPC1_REFS = {}
def get_hpc1_ref(name):
    global solver
    global HPC1_REFS
    if (name not in HPC1_REFS):
        v = z3.Int(f"{name}_hpc1_ref")
        solver.add(z3.Or(v == 0, v == 1))
        HPC1_REFS[name] = v
    return HPC1_REFS[name]


HPC3_REFS = {}
def get_hpc3_ref(name):
    global solver
    global HPC3_REFS
    if (name not in HPC3_REFS):
        v = z3.Int(f"{name}_hpc3_ref")
        solver.add(z3.Or(v == 0, v == 1))
        HPC3_REFS[name] = v
    return HPC3_REFS[name]


def hpc1(x_sig, y_sig, z_name, active):
    global solver
    assert(x_sig.width == y_sig.width)
    z_width = x_sig.width
    x_ref = get_hpc1_ref(x_sig.name)
    y_ref = get_hpc1_ref(y_sig.name)
    solver.add(z3.Implies(active, z3.Or(x_ref == 1, y_ref == 1)))
    z_lat = max_lat(x_ref + x_sig.latency, y_ref + y_sig.latency) + 1
    return Signal(z_name, z_width, z_lat)


def hpc3(x_sig, y_sig, z_name, active):
    assert(x_sig.width == y_sig.width)
    z_width = x_sig.width
    x_ref = get_hpc3_ref(x_sig.name)
    y_ref = get_hpc3_ref(y_sig.name)
    solver.add(z3.Implies(active, z3.Or(x_ref == 1, y_ref == 1)))
    z_lat = max_lat(x_sig.latency, y_sig.latency) + 1
    return Signal(z_name, z_width, z_lat)


MUL_TYPE = {}

def mul(x_sig, y_sig, z_name):
    global MUL_TYPE
    assert(x_sig.width == y_sig.width)
    z_width = x_sig.width
    choice = z3.Bool(f"{z_name}_is_hpc3")
    hpc3_gadget = hpc3(x_sig, y_sig, z_name, choice)
    hpc1_gadget = hpc1(x_sig, y_sig, z_name, z3.Not(choice))
    z_lat = z3.If(choice, hpc3_gadget.latency, hpc1_gadget.latency)
    assert(z_name not in MUL_TYPE)
    MUL_TYPE[z_name] = choice
    return Signal(z_name, z_width, z_lat)


a0 = Signal("a0", 4)
a1 = Signal("a1", 4)

b = mul(a0, a1, "b")
c = lin_comb([a0, a1, b], "c", 4)

d0 = mul(a0, c, "d0")
d1 = mul(a1, c, "d1")

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

ref_cost_hpc1 = [get_ref_cost_hpc1(ref, name) for name, ref in HPC1_REFS.items()]
ref_cost_hpc3 = [get_ref_cost_hpc3(ref, name) for name, ref in HPC3_REFS.items()]
ref_cost_outer = [get_mul_cost(is_hpc3, name) for name, is_hpc3 in MUL_TYPE.items()]
total_cost = functools.reduce(lambda a, b: a + b, ref_cost_hpc1 + ref_cost_hpc3 + ref_cost_outer)

rand_cost_hpc1 = [ref * y(NUM_SHARES) * Signal.SIZES[name] for name, ref in HPC1_REFS.items()]
rand_cost_hpc3 = [ref * x(NUM_SHARES) * Signal.SIZES[name] for name, ref in HPC3_REFS.items()]
rand_cost_outer = [x(NUM_SHARES) * Signal.SIZES[name] for name, is_hpc3 in MUL_TYPE.items()]
rand_cost = functools.reduce(lambda a, b: a + b, rand_cost_hpc1 + rand_cost_hpc3 + rand_cost_outer)


cost = None
while True:
    solver.push()
    if cost is not None:
        solver.add(total_cost < cost)
    res = solver.check()
    if res == z3.sat:
        model = solver.model()
        cost = model.eval(total_cost)
        print(f"\n\nArea cost: {cost.as_long()}")
        print(f"\n\nRand cost: {model.eval(rand_cost).as_long()}")        
        for r in HPC1_REFS.values():
            print(f"{r} = {model.eval(r)}")
        for r in HPC3_REFS.values():
            print(f"{r} = {model.eval(r)}")
        for c in MUL_TYPE.values():
            print(f"{c} = {model.eval(c)}")
    elif res == z3.unsat:
        break
    else:
        print("Unknown")
        break
    solver.pop()