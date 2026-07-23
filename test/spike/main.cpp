#include "sim.h"
#include "processor.h"
#include "htif.h"
#include "mmu.h"
#include "devices.h"
#include "global_features.h"

#include "Vcpu_simple_tb.h"
#include "verilated.h"

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

    std::string elf_file = argv[1];
    std::string log_file = argv[2];

    std::vector<std::string> args = {
        elf_file
    };

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vcpu_simple_tb hw;

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
        log_file.c_str(),
        false,
        nullptr,
        false,
        nullptr,
        std::nullopt
    );

    sim.start();

    ElfInfo elf = ParseElf(elf_file);

    auto proc = sim.get_core(0);
    proc->enable_log_commits();
    proc->get_state()->pc = elf.entry;

    auto state = proc->get_state();

    std::cout << "Initial PC = 0x"
            << std::hex
            << state->pc
            << "\n";

    std::cout << "Starting Spike\n";

    bool pass_spike = false;
    bool pass_verilator = false;

    while (!pass_spike && !pass_verilator)
    {
        state_t * state = proc->get_state();
        uint32_t inst = (uint32_t)proc->get_mmu()->load_insn(state->pc).insn.bits();
        uint32_t pc = state->pc;

        // std::cout << "PC = 0x" << std::hex << pc << " | INST = 0x" << inst << "\n";

        for (const auto &[reg, value] : state->log_reg_write) {
            if (reg == 0) continue;
            std::cout << "\tREG WRITE: x" << (reg>>4)
                    << " = 0x" << std::hex
                    << value.v[0] << std::endl;
        }

        for (const auto &[addr, value, size] : state->log_mem_write) {
            std::cout << "\tMEM WRITE: 0x" << std::hex << addr << " = 0x" << value << " (size: " << size << ")" << std::endl;
        }

        proc->step(1);

#if F_RISCV_EXIT_INST_PRESENT == 1
        if (inst == F_RISCV_EXIT_INST) {
            std::cout << "EXIT INSTRUCTION HIT, EXITING...\n";
            pass_spike = true;
            pass_verilator = true; // delete once verilator is working
        }
#else 
        if (elf.has_tohost) {
            uint32_t value = proc->get_mmu()->load<uint32_t>((reg_t)elf.tohost, (xlate_flags_t)0x0);
            if (value != 0){
                std::cout << "TOHOST HIT, EXITING...\n";
                pass_spike = true;
            }
        }
#endif

    }

    //reset
    hw.rst = 1;

    for (int i = 0; i < 5; i++) {

        hw.clk = 0;
        hw.eval();
        Verilated::timeInc(1);

        hw.clk = 1;
        hw.eval();
        Verilated::timeInc(1);
    }

    hw.rst = 0;

    for (int i = 0; i < 100 && !Verilated::gotFinish(); i++) {
        hw.eval();

        std::cout
            << "rst=" << (int)hw.rst
            << " clk=" << (int)hw.clk
            << "\n";

        std::cout << "cycle " << i
          << " time=" << Verilated::time()
          << " valid=" << (int)hw.commit_valid
          << " pc=" << std::hex << (int)hw.commit_pc
          << " inst=" << std::hex << (int)hw.commit_inst
          << std::endl;

        Verilated::timeInc(1);
    }

    return 0;
}