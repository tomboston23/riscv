from elftools.elf.elffile import ELFFile
import os
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("--out_file", required=True)
parser.add_argument("--elf_file", required=True)
parser.add_argument(
    "--entry_file",
    default=None,
    help="Optional output file that records the ELF entry point as a Make variable",
)

args = parser.parse_args()


def main():
    mem = {}

    with open(args.elf_file, "rb") as f:
        elf = ELFFile(f)
        entry = elf.header["e_entry"]
        entry_hex = f"{entry:08X}"
        print(f"entry=0x{entry_hex.lower()}")

        if args.entry_file:
            entry_dir = os.path.dirname(args.entry_file)
            if entry_dir:
                os.makedirs(entry_dir, exist_ok=True)
            with open(args.entry_file, "w", encoding="utf-8") as entry_fp:
                entry_fp.write(f"ELF_ENTRY := {entry_hex}\n")

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

    with open(args.out_file, "w", encoding="utf-8") as f:
        for addr, word in sorted(mem.items()):
            f.write(f"{addr:08X} {word:08X}\n")


if __name__ == "__main__":
    main()



