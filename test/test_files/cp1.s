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
    xor  x1, x0, x1
    sll  x1, x1, x1
    add  x0, x0, x0
    or  x0, x0, x0
    and  x0, x0, x0
    add  x0, x0, x0
    xor  x0, x0, x0
    srl  x0, x0, x0
    
    xor  x0, x0, x0      # x0 = x0 - x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    sub  x0, x0, x0
    
    and  x0, x0, x0      # x0 = x0 & x0
    and  x0, x0, x0
    and  x0, x0, x0
    and  x0, x0, x0
    and  x0, x0, x0
    and  x0, x0, x0
    
    or   x0, x0, x0      # x0 = x0 | x0
    or   x0, x0, x0
    or   x0, x0, x0
    or   x0, x0, x0
    or   x0, x0, x0
    or   x0, x0, x0
    
    xor  x0, x0, x0      # x0 = x0 ^ x0
    xor  x0, x0, x0
    xor  x0, x0, x0
    xor  x0, x0, x0
    xor  x0, x0, x0
    xor  x0, x0, x0
    
    sll  x0, x0, x0      # x0 = x0 << x0
    sll  x0, x0, x0
    sll  x0, x0, x0
    sll  x0, x0, x0
    
    srl  x0, x0, x0      # x0 = x0 >> x0 (logical)
    srl  x0, x0, x0
    srl  x0, x0, x0
    srl  x0, x0, x0
    
    sra  x0, x0, x0      # x0 = x0 >> x0 (arithmetic)
    sra  x0, x0, x0
    sra  x0, x0, x0
    sra  x0, x0, x0
    
    slt  x0, x0, x0      # x0 = (x0 < x0) ? 1 : 0
    slt  x0, x0, x0
    slt  x0, x0, x0
    slt  x0, x0, x0
    
    sltu x0, x0, x0      # x0 = (x0 < x0) ? 1 : 0 (unsigned)
    sltu x0, x0, x0
    sltu x0, x0, x0
    sltu x0, x0, x0
    
    # Mixed sequence for OOO testing
    add  x0, x0, x0
    sub  x0, x0, x0
    and  x0, x0, x0
    or   x0, x0, x0
    xor  x0, x0, x0
    sll  x0, x0, x0
    srl  x0, x0, x0
    sra  x0, x0, x0
    slt  x0, x0, x0
    sltu x0, x0, x0
    
    # Repeat for longer test sequence
    add  x0, x0, x0
    sub  x0, x0, x0
    and  x0, x0, x0
    or   x0, x0, x0
    xor  x0, x0, x0
    sll  x0, x0, x0
    srl  x0, x0, x0
    sra  x0, x0, x0
    slt  x0, x0, x0
    sltu x0, x0, x0
    
    # More adds for pipeline depth testing
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    add  x0, x0, x0
    
    # Addi with immediate=0 (only immediate that works without decode)
    addi x0, x0, 0       # NOP equivalent
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    
    # Final mixed sequence
    add  x0, x0, x0
    sub  x0, x0, x0
    xor  x0, x0, x0
    or   x0, x0, x0
    and  x0, x0, x0

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
    # No data needed for this 
    