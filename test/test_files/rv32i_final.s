.include "global_features.inc"

.section .text
.globl main

main:
    csrw mscratch, ra  # save ra in mscratch    
# ----------------------------
# Register initialization
# ----------------------------
    li x1,1
    li x2,2
    li x3,3
    li x4,4
    li x5,5
    li x6,6
    li x7,7
    li x8,8
    li x9,9

# ----------------------------
# Reg-Reg forwarding chain
# ----------------------------
    add x10,x1,x2
    sub x11,x10,x1
    xor x12,x11,x3
    or  x13,x12,x4
    and x14,x13,x5
    sll x15,x14,x1
    srl x16,x15,x1
    sra x17,x16,x1
    slt x18,x1,x2
    sltu x19,x2,x1

# ----------------------------
# Immediate ops
# ----------------------------
    addi x20,x0,-1
    slti x21,x20,0
    sltiu x22,x20,1
    xori x23,x20,0x55
    ori x24,x0,0xaa
    andi x25,x24,0xf
    slli x26,x1,5
    srli x27,x26,5
    srai x28,x20,2

# ----------------------------
# LUI/AUIPC
# ----------------------------
    lui x29,0x12345
    auipc x30,0

# ----------------------------
# Load/store tests
# ----------------------------
    la x5,data

    lb  x6,0(x5)
    lbu x7,0(x5)
    lh  x8,2(x5)
    lhu x9,2(x5)
    lw  x10,8(x5)

# load-use hazard
    add x11,x10,x1

# store forwarding
    sw x11,12(x5)
    lw x12,12(x5)
    add x13,x12,x2

    sb x1,16(x5)
    lb x14,16(x5)

    sh x2,18(x5)
    lh x15,18(x5)

# ----------------------------
# Branches
# ----------------------------
    beq x1,x1,beq_ok
    j fail
beq_ok:

    bne x1,x2,bne_ok
    j fail
bne_ok:

    blt x1,x2,blt_ok
    j fail
blt_ok:

    bge x2,x1,bge_ok
    j fail
bge_ok:

    bltu x1,x2,bltu_ok
    j fail
bltu_ok:

    bgeu x2,x1,bgeu_ok
    j fail
bgeu_ok:

# Branch forwarding
    add x16,x1,x2
    beq x16,x3,branch_fwd_ok
    j fail
branch_fwd_ok:

# Load->branch hazard
    lw x17,20(x5)
    beq x17,x0,loaded_zero
    j fail
loaded_zero:

# ----------------------------
# JAL/JALR
# ----------------------------
    jal x18,func
after_call:
    addi x19,x19,1
    j pass

func:
    addi x20,x20,5
    jalr x0,x18,0

fail: 
    ebreak # ebreak is not implemented in the HW so it will error out

pass: 
    csrr ra, mscratch # restore ra
    csrw mstatus, x19
    csrr x18, mstatus
    li x15, 0xFFFFFFFF
    csrw mstatus, x15
    li x15, 0xFFFFFFFF
    csrr x12, mstatus
    csrw mtvec, x15
    li x12, 0x12345678
    li x12, 0x12345678
    csrr x12, mtvec
    csrw stvec, x15
    csrw sepc, x15
    csrw mepc, x15
    ret

.section .data
.align 4
data:
    .byte 0x80
    .byte 0x7f
    .half 0xff00
    .half 0x1234
    .word 0x11223344
    .word 0
    .space 16
