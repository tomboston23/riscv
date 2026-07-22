#include "sim.h"
#include "processor.h"
#include "htif.h"
#include "mmu.h"
#include "devices.h"
#include "global_features.h"

#include <iostream>
#include <vector>
#include <string>
#include <optional>
#include <elfio/elfio.hpp>

struct ElfInfo {
    uint32_t entry = 0;
#if F_RISCV_EXIT_INST_PRESENT == 0
    uint32_t tohost = 0;
    uint32_t fromhost = 0;

    bool has_tohost = false;
    bool has_fromhost = false;
#endif
};

ElfInfo ParseElf(const std::string& filename) {
    ELFIO::elfio reader;
    if (!reader.load(filename))
        throw std::runtime_error("Couldn't open ELF");

    ElfInfo info;
    info.entry = reader.get_entry();

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

int main(int argc, char** argv)
{
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " program.elf\n";
        return 1;
    }

    std::string filename = argv[1];

    std::vector<std::string> args = {
        filename
    };

    std::vector<std::pair<reg_t, abstract_mem_t*>> mems;

    auto mem = new mem_t(0x10000000); // 256 MB
    mems.push_back({0x80000000, mem});

    cfg_t cfg;

    sim_t sim(
        &cfg,
        false,
        mems,
        {},
        false,
        args,
        debug_module_config_t(),
        nullptr,
        false,
        nullptr,
        false,
        nullptr,
        std::nullopt
    );

    sim.start();

    ElfInfo elf = ParseElf(filename);

    auto proc = sim.get_core(0);
    proc->get_state()->pc = elf.entry;

    auto state = proc->get_state();

    std::cout << "Initial PC = 0x"
            << std::hex
            << state->pc
            << "\n";

    std::cout << "Starting Spike\n";

    bool pass = false;

    while (!pass)
    {
        state_t * state = proc->get_state();
        uint32_t inst = (uint32_t)proc->get_mmu()->load_insn(state->pc).insn.bits();
        uint32_t pc = state->pc;

        std::cout
            << "PC = 0x"
            << std::hex
            << pc
            << "\tINSTR = 0x"
            << std::hex
            << inst
            << "\n";

        proc->step(1);

#if F_RISCV_EXIT_INST_PRESENT == 1
        if (inst == F_RISCV_EXIT_INST) {
            std::cout << "EXIT INSTRUCTION HIT, EXITING...\n";
            break;
        }
#else 
        if (elf.has_tohost) {
            uint32_t value = proc->get_mmu()->load<uint32_t>((reg_t)elf.tohost, (xlate_flags_t)0x0);
            if (value != 0){
                std::cout << "TOHOST HIT, EXITING...\n";
                tohost_hit = true;
            }
        }
#endif

    }

    return 0;
}