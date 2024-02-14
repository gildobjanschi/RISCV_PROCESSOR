OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

MEMORY
{
    ROM (rx) :   ORIGIN = 0x00600000, LENGTH = 0x00a00000
    RAM (wx!r) : ORIGIN = 0x80000000, LENGTH = 0x00800000
}

SECTIONS
{
    .text.init : { *(.text.init) } > ROM
    /* ROM address where RAM data begins */
    PROVIDE( _rom_copy_to_ram_begin = .);
    .data : {
        _ram_data_begin = .;
        *(.data)
        _ram_data_end = .;
    } > RAM AT > ROM

    .tohost : {
        *(.tohost)
    } > RAM AT > ROM

    _end = .;
}
