.include "global_features.inc"

.align 4
.section .text.init
.global _start
_start:
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    # Initialize the stack pointer, mtvec, stvec
    la sp, _stack_top
    la t0, _trap_handler
    csrw mtvec, t0
    csrw stvec, t0
_jump_to_main:
    call main
    j done

.if F_RISCV_EXIT_INST_PRESENT
done:
    .word F_RISCV_EXIT_INST
.else
done: 
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
.endif

_trap_handler:
    csrr x1, mstatus
    csrr x2, mepc
    addi x2, x2, 4
    csrw mepc, x2
    mret