#include "sim.h"
#include "processor.h"
#include "htif.h"
#include "mmu.h"
#include "devices.h"

#include <iostream>
#include <vector>
#include <string>
#include <optional>

int main(int argc, char** argv)
{
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " program.elf\n";
        return 1;
    }

    std::vector<std::string> args = {
        std::string(argv[1])
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

    reg_t entry = sim.get_entry_point_public();

    auto proc = sim.get_core(0);
    proc->get_state()->pc = entry;

    auto state = proc->get_state();

    std::cout << "Initial PC = 0x"
            << std::hex
            << state->pc
            << "\n";

    std::cout << "Starting Spike\n";

    for (int i = 0; i < 20; i++)
    {
        proc->step(1);

        state_t * state = proc->get_state();

        std::cout
            << "PC = 0x"
            << std::hex
            << state->pc
            << "\tREGFILE = 0x"
            << std::hex
            << state->XPR[1]
            << "\n";
    }

    return 0;
}