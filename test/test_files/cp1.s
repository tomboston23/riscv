# test ALU instructions that ONLY use x0. 
# that way we can verify fetch without needing any decode/alu logic
.include "global_features.inc"

.align 4
.section .text
.globl _start
    # simple program to test fetching and decoding
_start:
    # All operations: x0 = x0 OP x0
    # No immediates (except 0), no branches, no jumps
    # Just pure R-type with all register fields = x0
    
    add  x22, x0, x0      # x1 = x0 + x0
    addi x1, x0, 5
    la x2, _test_data
    lw x5, 0(x2)
    li x3, 0x0A0B0C0D
    sw x3, 0(x2)
    lw x5, 0(x2)
    add x5,x5,x5
    nop
    add x1, x1, x1
    add x1,x1,x1
    nop
    add x1,x1,x1
    nop
    nop
    sll  x1, x1, x1
    add  x0, x0, x0
    or  x0, x0, x0
    and  x0, x0, x0
    add  x0, x0, x0
    xor  x0, x0, x0
    srl  x0, x0, x0
    
    li x5, 10      # x0 = x0 - x0
    sub  x0, x0, x0
    sub  x0, x0, x0
loop:
    addi x1, x1, 1
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    blt x1, x5, loop
    
    and  x0, x0, x0      # x0 = x0 & x0
    and  x0, x0, x0
    and  x0, x0, x0
    and  x0, x0, x0
    and  x0, x0, x0
    auipc x16, 0x1
    lui  x1, 0xFFAA
    or   x0, x0, x0
    or   x0, x0, x0
    or   x0, x0, x0
    addi x1, x1, 0x712
    nop
    nop
    nop
    # sw   x1, 0(x16)
    nop
    nop
    nop
    # lw   x1, 0(x16)
    # lb   x1, 0(x16)
    # lbu  x1, 2(x16)
    # lh   x1, 2(x16)
    # lhu  x1, 0(x16)
    # lb   x1, 3(x16)
    nop
    nop
    nop
    j done
    nop
    nop
    nop
.if (F_RISCV_EXIT_INST_PRESENT == 1)
done:
    .word F_RISCV_EXIT_INST
.else
done: 
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
.endif
    
    # Program ends here - will just keep executing whatever follows
    # (likely faulting or wrapping around depending on your implementation)

.section .data
_test_data:
    .word 0x12345678