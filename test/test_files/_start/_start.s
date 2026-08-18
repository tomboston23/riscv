.include "global_features.inc"

.align 4
.section .text.init
.global _start 
.global _get_print_buffer_start
.global _increment_print_buffer_start
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
    call _init_print_buffer
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

_init_print_buffer:
    la t0, print_dump
    mv t1, t0
    addi t1, t1, 4
    sw t1, 0(t0) # store the start address of the buffer in the first word
    ret

_get_print_buffer_start:
    la a0, print_dump
    lw a0, 0(a0) # load the current address of the buffer
    ret

_increment_print_buffer_start:
    la t0, print_dump
    lw t1, 0(t0) # load the current address of the buffer
    addi t1, t1, 1 # increment the address by 1
    sw t1, 0(t0) # store the new address back to the buffer
    ret

.section .print_dump
    .align 4
print_dump:
    .space 1024


.end