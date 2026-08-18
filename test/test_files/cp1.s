.include "global_features.inc"

.align 4
.section .text
.globl main
main:
    mv x31, ra # save ra in x31
    add  x22, x0, x0   
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
    
    li x5, 10   
    sub  x0, x0, x0
    sub  x0, x0, x0
loop:
    addi x1, x1, 1
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    blt x1, x5, loop
    
    and  x0, x0, x0     
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

    mv ra, x31 # restore ra
    ret

.section .data
_test_data:
    .word 0x12345678

.end