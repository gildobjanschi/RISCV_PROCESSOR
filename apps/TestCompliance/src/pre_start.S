.section .pretext.init, "ax"
.global _pre_start
_pre_start:

.option push
.option norelax
	/* Copy RAM data if any */
	lui t0, %hi(_ram_data_begin)
	addi t0, t0, %lo(_ram_data_begin)

	lui t3, %hi(_ram_data_end)
	addi t3, t3, %lo(_ram_data_end)

	/* Calculate the number of bytes to copy */
	sub t1, t3, t0
	/* Calculate the number of half words */
	srli t5, t1, 1

	/* Calculate if an additional byte needs to be copied */
	andi t6, t1, 1

	/* The address in ROM where RAM data is located. */
	lui t2, %hi(_rom_copy_to_ram_begin)
	addi t2, t2, %lo(_rom_copy_to_ram_begin)

copy_rom_to_ram_h_words:
	beq t5, zero, copy_rom_to_ram_bytes

	/* Load half word from ROM */
	lh t4, 0(t2)
	addi t2, t2, 2
	/* Store word in RAM */
	sh t4, 0(t0)
	addi t0, t0, 2

	/* Decrement the number of half words */
	addi t5, t5, -1
	j copy_rom_to_ram_h_words

copy_rom_to_ram_bytes:
	beq t6, zero, copy_rom_to_ram_done

	/* Load byte from ROM */
	lbu t4, 0(t2)

	/* Store byte in RAM */
	sb t4, 0(t0)

copy_rom_to_ram_done:

	/* Jump to _start */
	lui	t0, %hi(rvtest_init)
	addi t0, t0, %lo(rvtest_init)

.option pop
	jr 0(t0)
