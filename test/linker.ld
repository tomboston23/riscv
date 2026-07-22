OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ROM (rx) : ORIGIN = RAM_ORIGIN, LENGTH = 64K
    RAM (rw) : ORIGIN = RAM_ORIGIN + 64K, LENGTH = 64K
}

SECTIONS
{
    . = ORIGIN(RAM);

    .text : ALIGN(4)
    {
        *(.text.init)
        *(.text*)
    } > ROM

    .rodata : ALIGN(4)
    {
        *(.rodata*)
    } > ROM

    .data : ALIGN(4)
    {
        *(.data*)
    } > RAM

    .bss : ALIGN(4)
    {
        *(.bss*)
        *(COMMON)
    } > RAM

    _end = .;
}