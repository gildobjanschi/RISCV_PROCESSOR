.section .pretext, "ax"
.global _pre_start
_pre_start:

.option push
.option norelax
    /* Load the stack pointer in x2 (sp) */
    lui	sp, %hi(__stack_start)
    addi sp, sp, %lo(__stack_start)

    /* Enable performace monitoring */
    /* EVENT_INSTR_FROM_ROM */
    li t0, 0x00000008
    csrrw x0, mhpmevent3, t0
    /* EVENT_INSTR_FROM_RAM */
    li t0, 0x00000010
    csrrw x0, mhpmevent4, t0
    /* EVENT_I_CACHE_HIT */
    li t0, 0x00000020
    csrrw x0, mhpmevent5, t0
    /* EVENT_LOAD_FROM_ROM */
    li t0, 0x00000040
    csrrw x0, mhpmevent6, t0
    /* EVENT_LOAD_FROM_RAM */
    li t0, 0x00000080
    csrrw x0, mhpmevent7, t0
    /* EVENT_STORE_TO_RAM */
    li t0, 0x00000100
    csrrw x0, mhpmevent8, t0
    /* EVENT_IO_LOAD */
    li t0, 0x00000200
    csrrw x0, mhpmevent9, t0
    /* EVENT_IO_STORE */
    li t0, 0x00000400
    csrrw x0, mhpmevent10, t0
    /* EVENT_CSR_LOAD */
    li t0, 0x00000800
    csrrw x0, mhpmevent11, t0
    /* EVENT_CSR_STORE */
    li t0, 0x00001000
    csrrw x0, mhpmevent12, t0
    /* EVENT_TIMER_INT */
    li t0, 0x00002000
    csrrw x0, mhpmevent13, t0
    /* EVENT_EXTERNAL_INT */
    li t0, 0x00004000
    csrrw x0, mhpmevent14, t0
    /* Enable performance monitor counters */
    li t0, 0xffffc000
    csrrw x0, mcountinhibit, t0

    /* Set the interrupt vector */
    la t0, trap_entry
    csrrw x0, mtvec, t0

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

    /* Enable external and timer interrupts */
    li t2, 0x00000880
    csrrs x0, mie, t2
    /* Enable the global interrupt flag (MIE) */
    li t2, 0x00000008
    csrrs x0, mstatus, t2
.option pop
    jr 0(t0)


.section .text, "ax"
.globl trap_entry
.align 4
trap_entry:
    addi sp, sp, -124

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
    sw s2, 68(sp)
    sw s3, 72(sp)
    sw s4, 76(sp)
    sw s5, 80(sp)
    sw s6, 84(sp)
    sw s7, 88(sp)
    sw s8, 92(sp)
    sw s9, 96(sp)
    sw s10, 100(sp)
    sw s11, 104(sp)
    sw t3, 108(sp)
    sw t4, 112(sp)
    sw t5, 116(sp)
    sw t6, 120(sp)

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
    lw a0, 36(sp)
    lw a1, 40(sp)
    lw a2, 44(sp)
    lw a3, 48(sp)
    lw a4, 52(sp)
    lw a5, 56(sp)
    lw a6, 60(sp)
    lw a7, 64(sp)
    lw s2, 68(sp)
    lw s3, 72(sp)
    lw s4, 76(sp)
    lw s5, 80(sp)
    lw s6, 84(sp)
    lw s7, 88(sp)
    lw s8, 92(sp)
    lw s9, 96(sp)
    lw s10, 100(sp)
    lw s11, 104(sp)
    lw t3, 108(sp)
    lw t4, 112(sp)
    lw t5, 116(sp)
    lw t6, 120(sp)

    addi sp, sp, 124

    mret
