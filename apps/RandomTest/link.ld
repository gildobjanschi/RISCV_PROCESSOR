OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    ROM (rx) :   ORIGIN = 0x00600000, LENGTH = 0x00a00000
    RAM (wx!r) : ORIGIN = 0x80000000, LENGTH = 0x00800000
}

SECTIONS
{
    .text : { *(.text) } > ROM
    . = ALIGN(0x1000);
    .tohost : { *(.tohost) } > RAM AT > ROM
    . = ALIGN(0x1000);
    .page_table : { *(.page_table) } > RAM AT > ROM
    .data : { *(.data) } > RAM AT > ROM
    .user_stack : { *(.user_stack) } > RAM AT > ROM
    .kernel_data : { *(.kernel_data) } > RAM AT > ROM
    .kernel_stack : { *(.kernel_stack) } > RAM AT > ROM
    .bss : { *(.bss) } > RAM AT > ROM
    _end = .;
}
