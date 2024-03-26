# coding: utf-8
import re
import sys

MODULE_RE = re.compile("^\s*(module|package)\s+([a-zA-Z0-9_]+)\s*(?:#?\(|;)", flags=re.MULTILINE)
GUARD_BEGIN_RE = re.compile("^\s*`ifndef\s+([a-zA-Z0-9_]+)\s*\n\s*`define\s+([a-zA-Z0-9_]+)\s*\n")
GUARD_END_RE = re.compile("\n\s*`endif\s*(?:\s+//(.*))$")
def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} SV_FILE")
        return 1
    data = ""
    try: 
        f = open(sys.argv[1], "r")
        data = f.read()
        f.close()
    except Exception as error:
        print(error)
        return 2
    modules = MODULE_RE.findall(data)
    if len(modules) == 0:
        print("[Error] Found no packages or modules")
        return 3
    elif len(modules) != 1:
        modules_str = ", ".join(" ".join(m) for m in modules)
        print(f"[Error] Found more than one package or module: {modules_str}")
        return 4
    print(f"[Info] Found {modules[0][0]}: {modules[0][1]}")
    
    guard_str = modules[0][1].upper() + "_SV"
    guard_begin = GUARD_BEGIN_RE.findall(data)
    guard_end = GUARD_END_RE.findall(data)

    if (len(guard_begin) == 0) ^ (len(guard_end) == 0):
        print("[Error] Found guard mismatch, fix your file")
        return 5
    elif (len(guard_begin) == 0) and (len(guard_end) == 0):
        print("[Info] Did not find any guards, adding them")
        sep = "" if (data[-1] == "\n") else "\n"
        data = f"`ifndef {guard_str}\n`define {guard_str}\n\n" + data + sep + f"`endif // {guard_str}\n"
    elif (len(guard_begin) != 1) or (len(guard_end) != 1):
        print("[Error] Matching problem, multiple guards")
        return 6
    else:
        assert((len(guard_begin) == 1) and (len(guard_end) == 1))
        print(guard_begin, guard_end)
        found_guards = list(set(guard_begin[0]).union([guard_end[0].strip()]))
        if "" in found_guards: 
            found_guards.remove("")
        if (len(found_guards) != 1):
            print(f"[Error] Found mismatched guards: {found_guards}, fix your file")
            return 7
        if (found_guards[0] != guard_str):
            print(f"[Warning] Found guard {found_guards[0]} does not match expected {guard_str}")
        begin_span = GUARD_BEGIN_RE.search(data).span()
        end_span = GUARD_END_RE.search(data).span()
        print("[Info] Replacing the existing guards")
        data = data[begin_span[1]:end_span[0]]
        data = f"`ifndef {guard_str}\n`define {guard_str}\n\n" + data + f"\n`endif // {guard_str}\n"
    
    try: 
        f = open(sys.argv[1], "w")
        f.write(data)
        f.close()
    except Exception as error:
        print(error)
        return 8
    return 0

if __name__ == "__main__":
    sys.exit(main())
    



