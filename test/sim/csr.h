#ifndef __CSR_H__
#define __CSR_H__

#include "processor.h"

enum csr_regfile_t {
    CSR_INVALID_REG         = 0X0,
    CSR_SSTATUS_REG         = 0X1,
    CSR_SIE_REG             = 0X2,
    CSR_STVEC_REG           = 0X3,
    CSR_SSCRATCH_REG        = 0X4,
    CSR_SEPC_REG            = 0X5,
    CSR_SCAUSE_REG          = 0X6,
    CSR_STVAL_REG           = 0X7,     
    CSR_SIP_REG             = 0X8,
    
    CSR_MSTATUS_REG         = 0X9,
    CSR_MIE_REG             = 0XA,
    CSR_MTVEC_REG           = 0XB,
    CSR_MSTATUSH_REG        = 0XC,
    CSR_MSCRATCH_REG        = 0XD,
    CSR_MEPC_REG            = 0XE,
    CSR_MCAUSE_REG          = 0XF,
    CSR_MTVAL_REG           = 0X10,
    CSR_MIP_REG             = 0X11,

    CSR_MNSCRATCH_REG       = 0X12,
    CSR_MNEPC_REG           = 0X13,
    CSR_MNCAUSE_REG         = 0X14,
    CSR_MNSTATUS_REG        = 0X15
};

csr_regfile_t GetCsrRegfile(reg_t csr); 

#endif