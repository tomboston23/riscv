#include "parse_elf.h"
#include "csr.h"
#include "utils.h"

#include "sim.h"
#include "processor.h"
#include "htif.h"
#include "mmu.h"
#include "devices.h"
#include "disasm.h"

#include "global_features.h"

#include "Vcpu_simple_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <vector>
#include <string>
#include <optional>
#include <fstream>
#include <cstdint>
#include <iomanip>

using namespace std;

int main(int argc, char** argv)
{

    string elf_file = argv[1];
    string log_file = argv[2];
    string dump_file = argv[3];

    vector<string> args = {
        elf_file
    };

    // Start Verilator

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 
    Vcpu_simple_tb hw; 
    hw.clk = 0; 
    hw.rst = 1; 

    for (int i = 0; i < 5; i++) {
        AdvanceVerilatorTime(hw);
    }

    hw.rst = 0;

    vector<pair<reg_t, abstract_mem_t*>> mems;

    auto mem = new mem_t(0x10000000); // 256 MB
    mems.push_back({0x80000000, mem});

    cfg_t cfg;
    cfg.isa = "RV32IM_ZICSR";

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
        nullopt
    );

    sim.start();

    ElfInfo elf = ParseElf(elf_file);

    auto proc = sim.get_core(0);
    proc->enable_log_commits();
    proc->get_state()->pc = elf.entry;
    auto state = proc->get_state();

    cout << "Starting Spike\n";

    bool pass_verilator = false;

    int order = 0;
    int verilator_cycles = 0;

    while (!pass_verilator)
    {
        state_t * state = proc->get_state();
        insn_t insn = proc->get_mmu()->load_insn(state->pc).insn;
        uint32_t pc = state->pc;

        InstInfo spike_info = GetSpikeInfo(proc);

        // Spike: step by 1
        proc->step(1);

        spike_info.pc_next = state->pc;        
        spike_info.order = order;
        spike_info.rd_v = state->XPR[spike_info.rd_s];
        if (spike_info.csr_we) {
            spike_info.csr_wdata = proc->get_csr(insn.csr());
        }


        // Verilator: start stepping until we get a commit
        do {
            AdvanceVerilatorTime(hw);
            verilator_cycles++;
        } while(!hw.commit_valid);

        
        if (Verilated::gotFinish()) {
            pass_verilator = true;
            break;
        }

        InstInfo verilator_info = GetVerilatorInfo(&hw);

        if (!CompareInstInfo(spike_info, verilator_info)) {
            AdvanceVerilatorTime(hw); // get an extra time step in for debug
            cout << "SPIKE MISMATCH\n";
            print_info(spike_info, verilator_info, proc->get_disassembler()->disassemble(insn.bits()));
            break;
        }

        if (order % 1000 == 0) {
            cout << "ORDER: " <<dec<<setw(7) << setfill(' ')<< order << ", PC: " << hex << spike_info.pc << ", INST: " << hex << spike_info.inst << endl;
        }

        // cout << "ORDER: " << order << " | PC: " <<hex<< spike_info.pc << " | INST: " <<hex<< spike_info.inst << endl;

        order++;

    }


    if (pass_verilator)
        cout << "\n\033[32m -> PASSED: SPIKE SIMULATION\033[0m\n";

    // cout << "Print dump: 0x" << hex << elf.print_dump << endl;
    // cout << "Dump addr: 0x" << hex << proc->get_mmu()->load<uint32_t>(elf.print_dump, (xlate_flags_t)0x0) << endl;

    ofstream dumpFile(dump_file);
    for (uint32_t i = elf.print_dump + 4; i < proc->get_mmu()->load<uint32_t>(elf.print_dump, (xlate_flags_t)0x0); i++) {
        char c = (char)proc->get_mmu()->load<uint8_t>(i, (xlate_flags_t)0x0);
        dumpFile << c;
    }
    dumpFile.close();

    float IPC = (float)order / (float)verilator_cycles;

    cout << "IPC: " << IPC << endl;

    return 0;
}