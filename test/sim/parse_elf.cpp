#include "parse_elf.h"
#include <string>
#include <elfio/elfio.hpp>
#include <stdexcept>

using namespace std;

ElfInfo ParseElf(const string& filename) {
    ELFIO::elfio reader;
    if (!reader.load(filename))
        throw runtime_error("Couldn't open ELF");

    ElfInfo info;
    info.entry = reader.get_entry();
    info.print_dump = reader.sections[".print_dump"]->get_address();

#if F_RISCV_EXIT_INST_PRESENT == 0
    // Parse the .tohost and .fromhost sections if they exist
    for (const auto& section : reader.sections) {
        if (section->get_name() == ".tohost") {
            info.tohost = section->get_address();
            info.has_tohost = true;
        }
        if (section->get_name() == ".fromhost") {
            info.fromhost = section->get_address();
            info.has_fromhost = true;
        }
    }
#endif

    return info;
}