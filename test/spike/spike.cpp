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
#include <elfio/elfio.hpp>
#include <iomanip>

using namespace std;

struct ElfInfo {
    uint32_t entry = 0;
#if F_RISCV_EXIT_INST_PRESENT == 0
    uint32_t tohost = 0;
    uint32_t fromhost = 0;

    bool has_tohost = false;
    bool has_fromhost = false;
#endif
};

struct InstInfo {
    uint8_t valid;
    uint32_t pc;
    uint32_t pc_next; 
    uint32_t inst;
    uint8_t rd_s;
    uint32_t rd_v;
    uint8_t rs1_s;
    uint32_t rs1_v;
    uint8_t rs2_s;
    uint32_t rs2_v;
    uint8_t mem_wmask;
    uint8_t mem_rmask;
    uint32_t mem_wdata;
    uint32_t mem_rdata;
    uint32_t mem_addr;
    uint32_t order;
};

static inline void AdvanceVerilatorTime(
    Vcpu_simple_tb& hw)
{
    hw.clk = 0;
    hw.eval();
    Verilated::timeInc(1);

    hw.clk = 1;
    hw.eval();
    Verilated::timeInc(1);
}

bool CompareInstInfo(const InstInfo& a, const InstInfo& b) {
    if (a.pc != b.pc) return false;
    if (a.pc_next != b.pc_next) return false;
    if (a.inst != b.inst) return false;
    if (a.rd_s != b.rd_s) return false;
    if (a.rd_v != b.rd_v) return false;
    if (a.rs1_s != b.rs1_s) return false;
    if (a.rs1_v != b.rs1_v) return false;
    if (a.rs2_s != b.rs2_s) return false;
    if (a.rs2_v != b.rs2_v) return false;
    if (a.mem_wmask != b.mem_wmask) return false;
    if (a.mem_rmask != b.mem_rmask) return false;
    if (a.mem_rdata != b.mem_rdata) return false;
    if (a.mem_wdata != b.mem_wdata) return false;
    if (a.mem_addr != b.mem_addr) return false;

    return true;
}

InstInfo GetSpikeInfo(processor_t* proc) {
    state_t * state = proc->get_state();
    InstInfo info = {0};
    info.valid = 1;
    info.pc = state->pc;
    info.pc_next = state->pc + 4;

    info.inst = (uint32_t)proc->get_mmu()->load_insn(state->pc).insn.bits();
    insn_t insn(info.inst);

    // do some decoding
    info.rd_s = insn.rd();
    info.rs1_s = insn.rs1();
    info.rs2_s = insn.rs2();
    info.rs1_v = state->XPR[insn.rs1()];
    info.rs2_v = state->XPR[insn.rs2()];

    uint32_t load_addr = info.rs1_v + insn.i_imm();   // loads
    uint32_t store_addr = info.rs1_v + insn.s_imm();   // stores
    uint8_t mem_wmask = 0;
    uint8_t mem_rmask = 0;
    uint32_t load_data = 0;
    uint32_t mem_mask = 0;

    switch ((uint32_t)insn.opcode()) {
        case 0x03: // LOAD
            info.rs2_s = 0;
            info.rs2_v = 0;
            info.mem_addr = load_addr & ~(0x3);
            load_data = proc->get_mmu()->load<uint32_t>(info.mem_addr);
            switch ((uint32_t)insn.funct3()) {
                case 0x0: //LB, LBU
                case 0x4:
                    mem_rmask = 0b0001 << (load_addr & 0b11);
                    mem_mask = 0xFF << ((load_addr & 0b11) << 3);
                    break;
                case 0x1: //LH, LHU
                case 0x5:
                    mem_rmask = 0b0011 << (load_addr & 0b10);
                    mem_mask = 0xFFFF << ((load_addr & 0b10) << 3);
                    break;
                case 0x2: //LW
                    mem_rmask = 0xf;
                    mem_mask = 0xFFFFFFFF;
                    break;
            }

            info.mem_rdata = load_data & mem_mask;
            info.mem_rmask = mem_rmask;

            break;

        case 0x13:
        case 0x67:  // OP-IMM, JALR
            info.rs2_s = 0;
            info.rs2_v = 0;
            break;

        case 0x63: // BR
            info.rd_s = 0;
            break;

        case 0x23:  // STORE
            info.rd_s = 0;
            info.mem_addr = store_addr;
            info.mem_wdata = info.rs2_v;
            switch((uint32_t)insn.funct3()) {
                case 0x0: // SB
                    info.mem_wmask = 0b0001 << (store_addr & 0b11);
                    info.mem_wdata = (info.rs2_v & 0xFF) << ((store_addr & 0b11) << 3);
                    break;
                case 0x1: // SH
                    info.mem_wmask = 0b0011 << (store_addr & 0b10);
                    info.mem_wdata = (info.rs2_v & 0xFFFF) << ((store_addr & 0b10) << 3);
                    break;
                case 0x2: // SW
                    info.mem_wmask = 0xf;
                    info.mem_wdata = info.rs2_v;
                    break;
            }
            break;

        case 0x37: 
        case 0x17:
        case 0x6F:  // LUI, AUIPC, JAL
            info.rs1_s = 0;
            info.rs1_v = 0;
            info.rs2_s = 0;
            info.rs2_v = 0;
            break;
    }
    // Populate info with state data
    return info;
}

void print_u32_hex(string label, uint32_t value1, uint32_t value2) {
    if (value1 == value2){
        cout << setw(14) << setfill(' ') << label << " | 0x" << setw(8) << setfill('0')
              << hex << uppercase << value1 << " | 0x" << setw(8) << setfill('0') << hex << uppercase << value2 << " |\n";
    } else {
                cout << "-> " << setw(11) << setfill(' ') << label << " | 0x" << setw(8) << setfill('0')
              << hex << uppercase << value1 << " | 0x" << setw(8) << setfill('0') << hex << uppercase << value2 << " |\n";
    }
}

void print_u8_hex(string label, uint8_t value1, uint8_t value2) {
    if (value1 == value2) {
        cout << setw(14) << setfill(' ') << label << " | 0x" << setw(2) << setfill('0')
              << hex << uppercase << (int)value1 << "       | 0x" << setw(2) << setfill('0') << hex << uppercase << (int)value2 << "       |\n";
    } else {
        cout << "-> " << setw(11) << setfill(' ') << label << " | 0x" << setw(2) << setfill('0')
              << hex << uppercase << (int)value1 << "       | 0x" << setw(2) << setfill('0') << hex << uppercase << (int)value2 << "       |\n";
    }
}

void print_u8_int(string label, uint8_t value1, uint8_t value2) {
    if (value1 == value2) {
        cout << setw(14) << setfill(' ') << label << " | " << setw(2) << setfill('0') << (int)value1 << "         | " << setw(2) << setfill('0') << (int)value2 << "         |\n";
    } else {
        cout << "-> " << setw(11) << setfill(' ') << label << " | " << setw(2) << setfill('0') << (int)value1 << "         | " << setw(2) << setfill('0') << (int)value2 << "         |\n";
    }
}

void print_info(const InstInfo& spike_info, const InstInfo& verilator_info, string dis) {
    cout << "               |   Spike    | Verilator  | " << dis << "\n";
    cout << "               |------------|------------|\n";
    print_u32_hex("ORDER:", spike_info.order, verilator_info.order);
    print_u32_hex("PC:", spike_info.pc, verilator_info.pc);
    print_u32_hex("PC_NEXT:", spike_info.pc_next, verilator_info.pc_next);
    print_u32_hex("INST:", spike_info.inst, verilator_info.inst);
    print_u8_int("RD:", spike_info.rd_s, verilator_info.rd_s);
    print_u32_hex("RD_V:", spike_info.rd_v, verilator_info.rd_v);
    print_u8_int("RS1:", spike_info.rs1_s, verilator_info.rs1_s);
    print_u32_hex("RS1_V:", spike_info.rs1_v, verilator_info.rs1_v);
    print_u8_int("RS2:", spike_info.rs2_s, verilator_info.rs2_s);
    print_u32_hex("RS2_V:", spike_info.rs2_v, verilator_info.rs2_v);
    print_u32_hex("MEM_ADDR:", spike_info.mem_addr, verilator_info.mem_addr);
    print_u8_hex("MEM_WMASK:", spike_info.mem_wmask, verilator_info.mem_wmask);
    print_u32_hex("MEM_WDATA:", spike_info.mem_wdata, verilator_info.mem_wdata);
    print_u8_hex("MEM_RMASK:", spike_info.mem_rmask, verilator_info.mem_rmask);
    print_u32_hex("MEM_RDATA:", spike_info.mem_rdata, verilator_info.mem_rdata);
}

InstInfo GetVerilatorInfo(Vcpu_simple_tb* hw) {
    InstInfo info = {0};
    info.order = hw->order;
    info.valid = hw->commit_valid;
    info.pc = hw->commit_pc;
    info.pc_next = hw->commit_pc_next;
    info.inst = hw->commit_inst;
    info.rd_s = hw->commit_rd_s;
    info.rd_v = hw->commit_rd_v;
    info.rs1_s = hw->commit_rs1_s;
    info.rs1_v = hw->commit_rs1_v;
    info.rs2_s = hw->commit_rs2_s;
    info.rs2_v = hw->commit_rs2_v;
    info.mem_wmask = hw->commit_mem_wmask;
    info.mem_rmask = hw->commit_mem_rmask;
    info.mem_wdata = hw->commit_mem_wdata;
    info.mem_rdata = hw->commit_mem_rdata;
    info.mem_addr = hw->commit_mem_addr;
    info.order = hw->order;
    return info;
}

ElfInfo ParseElf(const string& filename) {
    ELFIO::elfio reader;
    if (!reader.load(filename))
        throw runtime_error("Couldn't open ELF");

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

    string elf_file = argv[1];
    string log_file = argv[2];

    vector<string> args = {
        elf_file
    };

    // Start Verilator

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 
    Vcpu_simple_tb hw; 
    hw.clk = 0; 
    hw.rst = 1; 
    hw.eval(); 

    for (int i = 0; i < 5; i++) {
        AdvanceVerilatorTime(hw);
    }

    hw.rst = 0;

    vector<pair<reg_t, abstract_mem_t*>> mems;

    auto mem = new mem_t(0x10000000); // 256 MB
    mems.push_back({0x80000000, mem});

    cfg_t cfg;
    cfg.isa = "RV32I";

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

    bool pass_spike = false;
    bool pass_verilator = false;

    int order = 0;
    int verilator_cycles = 0;

    while (!pass_spike && !pass_verilator)
    {
        state_t * state = proc->get_state();
        uint32_t inst = (uint32_t)proc->get_mmu()->load_insn(state->pc).insn.bits();
        uint32_t pc = state->pc;

        InstInfo spike_info = GetSpikeInfo(proc);

        // Spike: step by 1
        proc->step(1);

        spike_info.pc_next = state->pc;
        spike_info.order = order;
        spike_info.rd_v = state->XPR[spike_info.rd_s];


        // Verilator: start stepping until we get a commit
        do {
            AdvanceVerilatorTime(hw);
            verilator_cycles++;
        } while(!hw.commit_valid);

        InstInfo verilator_info = GetVerilatorInfo(&hw);

        if (!CompareInstInfo(spike_info, verilator_info)) {
            AdvanceVerilatorTime(hw); // get an extra time step in for debug
            cout << "SPIKE MISMATCH\n";
            print_info(spike_info, verilator_info, proc->get_disassembler()->disassemble(inst));
            break;
        }

#if F_RISCV_EXIT_INST_PRESENT == 1
        if (inst == F_RISCV_EXIT_INST) {
            pass_spike = true;
        }
        if (hw.commit_inst == F_RISCV_EXIT_INST) {
            pass_verilator = true;
        }
#else 
        if (elf.has_tohost) {
            uint32_t value = proc->get_mmu()->load<uint32_t>((reg_t)elf.tohost, (xlate_flags_t)0x0);
            if (value != 0){
                pass_spike = true;
            }
            if (verilator_info.mem_wmask != 0 && verilator_info.mem_wdata != 0 && verilator_info.mem_addr == elf.tohost) {
                pass_verilator = true;
            }
        }
#endif

        order++;

    }

    if (pass_spike != pass_verilator) {
        cout << "Inconsistency found between Spike and Verilator\n";
    } else if (pass_spike && pass_verilator){
        cout << "\n\033[32m -> PASSED: SPIKE SIMULATION\033[0m\n";
    }

    float IPC = (float)order / (float)verilator_cycles;

    cout << "IPC: " << IPC << endl;

    return 0;
}