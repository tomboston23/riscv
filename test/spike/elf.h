#ifndef __ELF_H__
#define __ELF_H__

#include <cstdint>
#include <string>

using namespace std;

struct ElfInfo {
    uint32_t entry = 0;
    uint32_t print_dump = 0;
#if F_RISCV_EXIT_INST_PRESENT == 0
    uint32_t tohost = 0;
    uint32_t fromhost = 0;

    bool has_tohost = false;
    bool has_fromhost = false;
#endif
};

ElfInfo ParseElf(const string& filename);

#endif