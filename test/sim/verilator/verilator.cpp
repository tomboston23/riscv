#include "parse_elf.h"
#include "csr.h"
#include "utils.h"

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

    ElfInfo elf = ParseElf(elf_file);

    bool pass_verilator = false;

    int order = 0;
    int verilator_cycles = 0;

    while (!pass_verilator)
    {
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

        if (order % 1000 == 0) {
            cout << "ORDER: " <<dec<<setw(7) << setfill(' ')<< order << ", PC: " << hex << verilator_info.pc << ", INST: " << hex << verilator_info.inst << endl;
        }

        // cout << "ORDER: " << order << " | PC: " <<hex<< verilator_info.pc << " | INST: " <<hex<< verilator_info.inst << endl;

        order++;

    }

    if (pass_verilator) {
        cout << "\n\033[32m -> PASSED: VERILATOR SIMULATION\033[0m\n";
    }

    // ofstream dumpFile(dump_file);
    // for (uint32_t i = elf.print_dump + 4; i < proc->get_mmu()->load<uint32_t>(elf.print_dump, (xlate_flags_t)0x0); i++) {
    //     char c = (char)proc->get_mmu()->load<uint8_t>(i, (xlate_flags_t)0x0);
    //     dumpFile << c;
    // }
    // dumpFile.close();

    float IPC = (float)order / (float)verilator_cycles;

    cout << "IPC: " << IPC << endl;

    return 0;
}