import re
import os
import sys


pattern1  = r'^(add|sub|or|and) r([0-9]|1[0-9]|2[0-9]|3[01]), (r([0-9]|1[0-9]|2[0-9]|3[01])|\$[0-9a-f]{2})(\s*//.*)*$'
pattern2  = r'^(inc|dec) r([0-9]|1[0-9]|2[0-9]|3[01])(\s*//.*)*$'
pattern3  = r'^(lsr|rsr) r([0-9]|1[0-9]|2[0-9]|3[01]), \$[0-7](\s*//.*)*$'
pattern4  = r'^jmp \$[0-9a-f]{4}(\s*//.*)*$'
pattern5  = r'^(jmps|jmpc) \$[0-9a-f]{4}, \$[01](\s*//.*)*$'
pattern6  = r"^ldl r([0-9]|1[0-9]|2[0-9]|3[01]), \$[0-9a-f]{2}(\s*//.*)*$"
pattern7  = r'^mov r([0-9]|1[0-9]|2[0-9]|3[01]), r([0-9]|1[0-9]|2[0-9]|3[01])(\s*//.*)*$'
pattern8  = r'^ld r([0-9]|1[0-9]|2[0-9]|3[01]), (x|x\+|y|y\+)(\s*//.*)*$'
pattern9  = r'^stl (x|x\+|y|y\+), \$[0-9a-f]{2}(\s*//.*)*$'
pattern10 = r'^st (x|x\+|y|y\+), r([0-9]|1[0-9]|2[0-9]|3[01])(\s*//.*)*$'
pattern11 = r'^(reti|nop)(\s*//.*)*$'


def compile(cmd, n):
    cmd = cmd.lower().strip()
    result = 0

    if (
        re.fullmatch(pattern1, cmd) is not None or
        re.fullmatch(pattern2, cmd) is not None or
        re.fullmatch(pattern3, cmd) is not None or
        re.fullmatch(pattern4, cmd) is not None or
        re.fullmatch(pattern5, cmd) is not None or
        re.fullmatch(pattern6, cmd) is not None or
        re.fullmatch(pattern7, cmd) is not None or
        re.fullmatch(pattern8, cmd) is not None or
        re.fullmatch(pattern9, cmd) is not None or
        re.fullmatch(pattern10, cmd) is not None or
        re.fullmatch(pattern11, cmd) is not None
    ):
        command = re.split(r',\s|\s|,|/', cmd)

        if (
            command[0] == "add" or
            command[0] == "sub" or
            command[0] == "or" or
            command[0] == "and"
        ):
            if command[0] == "add":
                result = 1 << 28
            if command[0] == "sub":
                result = 2 << 28
            if command[0] == "or":
                result = 3 << 28
            if command[0] == "and":
                result = 4 << 28

            result |= int(command[1][1:]) << 19

            if command[2][0] == '$':
                result |= 1 << 27
                result |= int(command[2][1:], 16)
            else:
                result |= int(command[2][1:]) << 11

        elif command[0] == "inc" or command[0] == "dec":
            if command[0] == "inc":
                result = 5 << 28
            if command[0] == "dec":
                result = 6 << 28

            result |= int(command[1][1:]) << 19

        elif command[0] == "lsr" or command[0] == "rsr":
            if command[0] == "lsr":
                result = 7 << 28
            if command[0] == "rsr":
                result = 8 << 28

            result |= int(command[1][1:]) << 19
            result |= int(command[2][1:], 16) << 25

        elif command[0] == "jmp":
            result = 9 << 28
            result |= int(command[1][1:], 16)

        elif command[0] == "jmps" or command[0] == "jmpc":
            result = 10 << 28

            if command[0] == "jmpc":
                result |= 1 << 24

            result |= int(command[1][1:], 16)
            result |= int(command[2][1:], 16) << 25

        elif command[0] == "ldl":
            result = 11 << 28
            result |= int(command[1][1:]) << 19
            result |= int(command[2][1:], 16)

        elif command[0] == "mov":
            result = 11 << 28
            result |= 1 << 27
            result |= int(command[1][1:]) << 19
            result |= int(command[2][1:]) << 11

        elif command[0] == "ld":
            result = 12 << 28
            result |= int(command[1][1:]) << 19

            if command[2] == "x":
                result |= 0 << 26
            if command[2] == "x+":
                result |= 1 << 26
            if command[2] == "y":
                result |= 2 << 26
            if command[2] == "y+":
                result |= 3 << 26

        elif command[0] == "stl":
            result = 13 << 28

            if command[1] == "x":
                result |= 0 << 26
            if command[1] == "x+":
                result |= 1 << 26
            if command[1] == "y":
                result |= 2 << 26
            if command[1] == "y+":
                result |= 3 << 26

            result |= int(command[2][1:], 16)

        elif command[0] == "st":
            result = 14 << 28

            if command[1] == "x":
                result |= 0 << 26
            if command[1] == "x+":
                result |= 1 << 26
            if command[1] == "y":
                result |= 2 << 26
            if command[1] == "y+":
                result |= 3 << 26

            result |= int(command[2][1:]) << 11

        elif command[0] == "reti":
            result = 15 << 28

        else:
            result = 0

    else:
        raise Exception("Command violation {0}:{1}".format(n, cmd))

    return result

def save_mem(in_path, out_path, name, size_mem):
    n = 1
    prgmem = []

    with open(in_path, 'r') as f:
        for line in f:
            prgmem.append(format(compile(line, n), '08X') + "\n")
            n += 1

    for i in range(size_mem - len(prgmem)):
        if len(prgmem) != size_mem - 1:
            prgmem.append("00000000\n")
        else:
            prgmem.append("00000000")

    with open(os.path.join(out_path, name + ".mem"), "w+") as f:
        f.writelines(prgmem)

def run_compiler(in_path, out_path, name, size_mem):
    save_mem(in_path, out_path, name, int(size_mem))


def main():
    if len(sys.argv) != 5:
        print("Usage:")
        print("  assembler.exe <input_file> <output_path> <name> <size_mem>")
        return

    in_path = sys.argv[1]
    out_path = sys.argv[2]
    name = sys.argv[3]
    size_mem = int(sys.argv[4])

    run_compiler(in_path, out_path, name, size_mem)

    print("File assembled successfully:")
    print(out_path + "/" + name + ".mem")


if __name__ == "__main__":
    main()