OUTPUT_ARCH( "riscv" )
ENTRY(_pre_start)

MEMORY
{
    ROM (rx) :   ORIGIN = 0x00600000, LENGTH = 0x00a00000
    RAM (wx!r) : ORIGIN = 0x80000000, LENGTH = 0x00080000
}

SECTIONS
{
	PROVIDE( _ram_data_begin = ORIGIN(RAM));
	.text.init : { *(.text.init) } > ROM
	. = ALIGN(0x1000);

	/* ROM address where RAM data begins */
	PROVIDE( _rom_copy_to_ram_begin = .);

	PROVIDE( _ram_data_begin = ORIGIN(RAM));
	.data : { *(.data) } > RAM AT > ROM
	PROVIDE( _ram_data_end = .);
	/* ---- ROM address where RAM data end ----- */
	.tohost : { *(.tohost) } > RAM
	. = ALIGN(0x1000);
	.bss : { *(.bss) } > RAM
	_end = .;
}

