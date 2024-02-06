.section .pretext, "ax"
.global _pre_start
_pre_start:

.option push
.option norelax
	/* Load the stack pointer in x2 (sp) */
	lui	sp, %hi(__stack_start)
	addi sp, sp, %lo(__stack_start)

	/* Copy RAM data if any */
	lui t0, %hi(_ram_data_begin)
	addi t0, t0, %lo(_ram_data_begin)

	lui t3, %hi(_ram_data_end)
	addi t3, t3, %lo(_ram_data_end)

	/* Calculate the number of bytes to copy */
	sub t1, t3, t0

	lui t4, %hi(_rom_begin)
	addi t4, t4, %lo(_rom_begin)

	/* The address in ROM where RAM data is located. */
	lui t2, %hi(_rom_copy_to_ram_begin)
	addi t2, t2, %lo(_rom_copy_to_ram_begin)

	sub t4, t2, t4

	sub t1, t1, t4

	/* Calculate the number of words */
	srli t5, t1, 2

	beq t5, zero, copy_rom_to_ram_done
copy_rom_to_ram_words:
	/* Load word from ROM */
	lw t4, 0(t2)
	addi t2, t2, 4
	/* Store word in RAM */
	sw t4, 0(t0)
	addi t0, t0, 4

	/* Decrement the number of words */
	addi t5, t5, -1
	bne t5, zero, copy_rom_to_ram_words

copy_rom_to_ram_done:
	/* Reset the argc argv at the end of RAM - 8*/
	lui t0, %hi(__arg_start)
	addi t0, t0, %lo(__arg_start)

	lui t1, %hi(__arg_end)
	addi t1, t1, %lo(__arg_end)

clear_arg:
	sb zero, 0(t0)
	addi t0, t0, 1
	bne t0, t1, clear_arg

	/* Jump to _start */
	lui	t0, %hi(_start)
	addi t0, t0, %lo(_start)

.option pop
	jr 0(t0)


