#include "mmu.h"
#include "csr.h"
#include "utils.h"

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

        case 0x73:  // SYSTEM
            reg_t csr = insn.csr();
            reg_t csr_val = proc->get_csr(csr);
            csr_regfile_t csr_reg = GetCsrRegfile(csr);
            
            switch ((uint32_t)insn.funct3()) {
                case 0x5: // CSRRWI - same as 0x1 without rs1
                    info.rs1_s = 0;
                    info.rs1_v = 0;
                case 0x1: // CSRRW
                    if (info.rd_s == 0) {
                        info.csr_rdata = 0;
                    } else {
                        info.csr_rdata = (uint32_t)csr_val;
                    }
                    info.csr_we = 1;
                    info.csr_rd_s = (uint8_t)csr_reg;
                    break;
                case 0x6: // CSRRSI
                case 0x7: // CSRRCI
                    info.rs1_s = 0;
                    info.rs1_v = 0;
                case 0x2: // CSRRS
                case 0x3: // CSRRC
                    if (insn.rs1() == 0) { // bits [19:15], both rs1 and z_imm
                        info.csr_we = 0;
                    } else {
                        info.csr_we = 1;
                    }
                    
                    info.csr_rd_s = (uint8_t)csr_reg;
                    info.csr_rdata = (uint32_t)csr_val;
                    break;
            }
            info.rs2_v = 0;
            info.rs2_s = 0;
            break;
    }
    // Populate info with state data
    return info;
}