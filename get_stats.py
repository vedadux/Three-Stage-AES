# coding: utf-8

import re
import json
import sys

GE = 0.798
RANDOM_BIT_GE = 39.4

def get_row(prefix, d, rand_names):
    module_name = prefix.split("/")[-1]
    assert(module_name[:4] == "syn_")
    module_name = module_name[4:]
    
    area_rex = re.compile(f"Chip area for (top )?module '\\\\{module_name}': (\d+\.\d+)")
    with open(f"{prefix}_{d}_stats.txt", "r") as f:
        area = float(area_rex.search(f.read()).groups()[1])
    
    with open(f"{prefix}_{d}_pre.json", "r") as f:
        data = json.load(f)
        found = False
        for m in data["modules"].keys():
            if module_name in m:
                found = True
                ports = data["modules"][m]["ports"]
                bits = sum([len(ports[name]["bits"]) for name in rand_names])
        assert(found)
    area_ge = area / GE
    area_prng = bits * RANDOM_BIT_GE
    print(f" {bits:3d} & {area_ge:7.1f} & {area_ge+area_prng:7.1f} \\\\")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"python3 {sys.argv[0]} PREFIX [RANDOM_NAMES...]")
    for d in range(2, 6):
        get_row(sys.argv[1], d, sys.argv[2:])