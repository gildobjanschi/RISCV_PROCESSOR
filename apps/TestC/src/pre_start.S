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
	/* Calculate the number of words to copy. Sections are 4 bytes aligned. */
	srli t5, t1, 2

	/* The address in ROM where RAM data is located. */
	lui t2, %hi(_rom_copy_to_ram_begin)
	addi t2, t2, %lo(_rom_copy_to_ram_begin)

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
	bne t5, zero, copy_rom_to_ram_done

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


.section .text, "ax"
.globl trap_entry
.align 4
trap_entry:
    addi sp, sp, -136

	sw ra, 0(sp)
    sw sp, 4(sp)
    sw gp, 8(sp)
    sw tp, 12(sp)
    sw t0, 16(sp)
    sw t1, 20(sp)
    sw t2, 24(sp)
    sw s0, 28(sp)
    sw s1, 32(sp)
    sw a0, 36(sp)
    sw a1, 40(sp)
    sw a2, 44(sp)
    sw a3, 48(sp)
    sw a4, 52(sp)
    sw a5, 56(sp)
    sw a6, 60(sp)
    sw a7, 64(sp)

	// Save the interrupt/exception context
	csrr a1, mcause
	sw a1, 68(sp)
	csrr a1, mepc
	sw a1, 72(sp)
	csrr a1, mtval
	sw a1, 76(sp)

    sw s2, 80(sp)
    sw s3, 84(sp)
    sw s4, 88(sp)
    sw s5, 92(sp)
    sw s6, 96(sp)
    sw s7, 100(sp)
    sw s8, 104(sp)
    sw s9, 108(sp)
    sw s10, 112(sp)
    sw s11, 116(sp)
    sw t3, 120(sp)
    sw t4, 124(sp)
    sw t5, 128(sp)
    sw t6, 132(sp)

    jal handle_trap

	lw ra, 0(sp)
    lw sp, 4(sp)
    lw gp, 8(sp)
    lw tp, 12(sp)
    lw t0, 16(sp)
    lw t1, 20(sp)
    lw t2, 24(sp)
    lw s0, 28(sp)
    lw s1, 32(sp)

	// Restore the interrupt/exception context
	lw a1, 68(sp)
	csrw mcause, a1

	// Load mepc
	lw a2, 72(sp)

	// Load mtval (the instruction that caused the exception)
	lw a3, 76(sp)
	csrw mtval, a3

	// For interrupts leave mepc unchanged
	li a4, 0x80000000
	and a1, a1, a4
	beq a1, a4, 2f
	// For exceptions add +2/+4 to mepc
	// Adjust mepc with 2 or 4 (depends on the instruction being compressed or not)
	li a4, 3
	and a3, a3, a4
	bne a3, a4, 1f
	addi a2, a2, 2 // Add 2 and then add 2 more below
1:
	addi a2, a2, 2
2:
	// Save mepc
	csrw mepc, a2

    lw a0, 36(sp)
    lw a1, 40(sp)
    lw a2, 44(sp)
    lw a3, 48(sp)
    lw a4, 52(sp)
    lw a5, 56(sp)
    lw a6, 60(sp)
    lw a7, 64(sp)
    lw s2, 80(sp)
    lw s3, 84(sp)
    lw s4, 88(sp)
    lw s5, 92(sp)
    lw s6, 96(sp)
    lw s7, 100(sp)
    lw s8, 104(sp)
    lw s9, 108(sp)
    lw s10, 112(sp)
    lw s11, 116(sp)
    lw t3, 120(sp)
    lw t4, 124(sp)
    lw t5, 128(sp)
    lw t6, 132(sp)

    addi sp, sp, 136

    mret
