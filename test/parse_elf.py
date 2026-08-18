from elftools.elf.elffile import ELFFile
import os
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("--out_file", required=True)
parser.add_argument("--elf_file", required=True)
parser.add_argument(
    "--mk_file",
    default=None,
    help="Optional output file that records the ELF entry point as a Make variable",
)

args = parser.parse_args()

file_str = ""

def add_to_file_str(name, data):
    global file_str
    file_str += f"{name} := {data}\n"

def write_to_mk_file():
    if args.mk_file:
        mk_dir = os.path.dirname(args.mk_file)
        if mk_dir:
            os.makedirs(mk_dir, exist_ok=True)
        with open(args.mk_file, "w", encoding="utf-8") as mk_fp:
            mk_fp.write(file_str)


def main():
    mem = {}

    with open(args.elf_file, "rb") as f:
        elf = ELFFile(f)
        entry = elf.header["e_entry"]
        entry_hex = f"{entry:08X}"
        # print(f"entry=0x{entry_hex.lower()}")

        add_to_file_str("ELF_ENTRY", entry_hex)

        for seg in elf.iter_segments():
            if seg["p_type"] == "PT_LOAD":
                addr = seg["p_paddr"]
                data = seg.data()

                for offset in range(0, len(data), 4):
                    word = 0

                    for i in range(4):
                        if offset + i < len(data):
                            word |= data[offset + i] << (8 * i)   # little-endian

                    mem[(addr + offset)] = word

        for sec in elf.iter_sections():
            if sec.name == ".tohost":
                tohost_addr = sec["sh_addr"]
                print(f"Found .tohost section at address: 0x{tohost_addr:08X}")
                add_to_file_str("TOHOST_ADDR", f"{tohost_addr:08X}")
            if sec.name == ".fromhost":
                fromhost_addr = sec["sh_addr"]
                print(f"Found .fromhost section at address: 0x{fromhost_addr:08X}")
                add_to_file_str("FROMHOST_ADDR", f"{fromhost_addr:08X}")
            if sec.name == ".print_dump":
                print_dump_addr = sec["sh_addr"]
                print(f"Found .print_dump section at address: 0x{print_dump_addr:08X}")
                add_to_file_str("PRINT_DUMP_ADDR", f"{print_dump_addr:08X}")


    with open(args.out_file, "w", encoding="utf-8") as f:
        for addr, word in sorted(mem.items()):
            f.write(f"{addr:08X} {word:08X}\n")

    write_to_mk_file()


if __name__ == "__main__":
    main()



