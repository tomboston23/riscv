#include "utils.h"

#include <cstdint>
#include <string>
#include <iomanip>



using namespace std;

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
    if (a.csr_we != b.csr_we) return false;
    if (a.csr_rd_s != b.csr_rd_s) return false;
    if (a.csr_rdata != b.csr_rdata) return false;
    if (a.csr_wdata != b.csr_wdata) return false;

    return true;
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
    print_u8_int("CSR_WE:", spike_info.csr_we, verilator_info.csr_we);
    print_u8_int("CSR_RD_S:", spike_info.csr_rd_s, verilator_info.csr_rd_s);
    print_u32_hex("CSR_RDATA:", spike_info.csr_rdata, verilator_info.csr_rdata);
    print_u32_hex("CSR_WDATA:", spike_info.csr_wdata, verilator_info.csr_wdata);
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
    info.csr_wdata = hw->commit_csr_wdata;
    info.csr_rdata = hw->commit_csr_rdata;
    info.csr_we = hw->commit_csr_we;
    info.csr_rd_s = hw->commit_csr_rd_s;
    return info;
}
