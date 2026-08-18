#ifndef __UTILS_H__
#define __UTILS_H__

#include "Vcpu_simple_tb.h"
#include "processor.h"
#include <cstdint>
#include <string>

using namespace std;

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
    uint8_t csr_we;
    uint8_t csr_rd_s;
    uint32_t csr_rdata;
    uint32_t csr_wdata;
};

static inline void AdvanceVerilatorTime(
    Vcpu_simple_tb& hw)
{
    hw.clk = 0;
    hw.eval();
    Verilated::timeInc(1000);

    hw.clk = 1;
    hw.eval();
    Verilated::timeInc(1000);
}

bool CompareInstInfo(const InstInfo& a, const InstInfo& b);

InstInfo GetSpikeInfo(processor_t* proc);
InstInfo GetVerilatorInfo(Vcpu_simple_tb* hw);
void print_info(const InstInfo& spike_info, const InstInfo& verilator_info, string dis);

#endif