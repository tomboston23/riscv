#include "csr.h"
#include "processor.h"

csr_regfile_t GetCsrRegfile(reg_t csr) {
    switch (csr) {
        case CSR_SSTATUS:         return CSR_SSTATUS_REG;
        case CSR_SIE:             return CSR_SIE_REG;
        case CSR_STVEC:           return CSR_STVEC_REG;
        case CSR_SSCRATCH:        return CSR_SSCRATCH_REG;
        case CSR_SEPC:            return CSR_SEPC_REG;
        case CSR_SCAUSE:          return CSR_SCAUSE_REG;
        case CSR_STVAL:           return CSR_STVAL_REG;
        case CSR_SIP:             return CSR_SIP_REG;
        case CSR_MSTATUS:         return CSR_MSTATUS_REG;
        case CSR_MIE:             return CSR_MIE_REG;
        case CSR_MTVEC:           return CSR_MTVEC_REG;
        case CSR_MSTATUSH:        return CSR_MSTATUSH_REG;
        case CSR_MSCRATCH:        return CSR_MSCRATCH_REG;
        case CSR_MEPC:            return CSR_MEPC_REG;
        case CSR_MCAUSE:          return CSR_MCAUSE_REG;
        case CSR_MTVAL:           return CSR_MTVAL_REG;
        case CSR_MIP:             return CSR_MIP_REG;
        case CSR_MNSCRATCH:       return CSR_MNSCRATCH_REG;
        case CSR_MNEPC:           return CSR_MNEPC_REG;
        case CSR_MNCAUSE:         return CSR_MNCAUSE_REG;
        case CSR_MNSTATUS:        return CSR_MNSTATUS_REG;
        default:                  return (csr_regfile_t)0;
    }
    return (csr_regfile_t)0;
}