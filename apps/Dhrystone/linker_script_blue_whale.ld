/* Specify the output as executable and linking format -> *.elf , and in 32 bits little endian */
OUTPUT_FORMAT( "elf32-littleriscv" )
/* Specify the output architecture is RISCV */
OUTPUT_ARCH( "riscv" )
ENTRY(_pre_start)

/* Define the stack size */
_STACK_SIZE = 0x400;

/* Define the heap size */
_HEAP_SIZE  = 0x400;

MEMORY
{
    ROM (rx) :   ORIGIN = 0x00600000, LENGTH = 0x00a00000
    RAM (wx!r) : ORIGIN = 0x80000000, LENGTH = 0x00080000
}

SECTIONS
{
	PROVIDE( _rom_begin = ORIGIN(ROM));
	.pretext :
	{
   		*(.pretext)
		. = ALIGN(4);
	} > ROM

	.preinit_array :
	{
		PROVIDE_HIDDEN (__preinit_array_start = .);
		*(.preinit_array)
		PROVIDE_HIDDEN (__preinit_array_end = .);
		. = ALIGN(4);
	} > ROM

	.init_array :
	{
		PROVIDE_HIDDEN (__init_array_start = .);
		*(SORT(.init_array.*))
		*(.init_array)
		PROVIDE_HIDDEN (__init_array_end = .);
		. = ALIGN(4);
	} > ROM

	.fini_array :
	{
		PROVIDE_HIDDEN (__fini_array_start = .);
		*(SORT(.fini_array.*))
		*(.fini_array)
		PROVIDE_HIDDEN (__fini_array_end = .);
		. = ALIGN(4);
	} > ROM

	/* ---- ROM address where RAM data begins ----- */
	PROVIDE( _ram_data_begin = ORIGIN(RAM));
	PROVIDE( _rom_copy_to_ram_begin = .);
	.text :
	{
    	PROVIDE(_text_start = .);
   		*(.text)
		*(.text.*)
		. = ALIGN(4);
    	PROVIDE(_text_end = .);
	} > RAM AT > ROM

	.rodata :
	{
		__rodata_start = .;
		KEEP (*(.rodata))
		KEEP (*(.rodata.*))
		. = ALIGN(4);
		__rodata_end = .;
	} > RAM AT > ROM

	.srodata :
	{
		__srodata_start = .;
		KEEP (*(.srodata))
		KEEP (*(.srodata.*))
		. = ALIGN(4);
		__srodata_end = .;
	} > RAM AT > ROM

	.data :
	{
		__data_start = .;
		KEEP (*(.data))
		KEEP (*(.data.*))
		. = ALIGN(4);
		__data_end = .;
	} > RAM AT > ROM

	PROVIDE( __global_pointer$ = . + 0x800);
	.sdata :
	{
		__sdata_start = .;
		KEEP (*(.sdata))
		KEEP (*(.sdata.*))
		. = ALIGN(4);
		__sdata_end = .;
	} > RAM AT > ROM

	/* thread-local data segment */
	.tdata :
	{
		_tdata_begin = .;
		KEEP (*(.tdata))
	    _tdata_end = .;
		. = ALIGN(4);
	} > RAM AT > ROM

	.sbss :
	{
		__sbss_start = .;
        *(.sbss .sbss.* .gnu.linkonce.sb.*)
		*(.scommon)
		. = ALIGN(4);
		__sbss_end = .;
	} > RAM
	PROVIDE( _ram_data_end = .);

	.bss :
	{
		_bss_start = .;
		KEEP (*(.bss))
		KEEP (*(.bss.*))
		. = ALIGN(4);
		_bss_end = .;
	} > RAM

	.tbss :
	{
		KEEP (*(.tbss))
		. = ALIGN(8);
		_tbss_end = .;
	} > RAM

	PROVIDE( _end = . );
	PROVIDE( end = . );
	PROVIDE( _rom_end = ORIGIN(ROM) + LENGTH(ROM));

  . = ALIGN(0x1000);
	.heap ALIGN(4) :
	{
		__heap_start = .;
		. = . + _HEAP_SIZE;
		. = ALIGN(4);
		__heap_end = .;
	} > RAM

	.stack ORIGIN(RAM) + LENGTH(RAM) - 8 - _STACK_SIZE:
	{
		__stack_end = .;
		. = . + _STACK_SIZE;
		. = ALIGN(4);
		__stack_start = .;
	} > RAM

	.arg ORIGIN(RAM) + LENGTH(RAM) - 8:
	{
		__arg_start = .;
		. = . + 8;
		. = ALIGN(4);
		__arg_end = .;
	} > RAM
}
