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
    /* Save x1 to the mscratch register */
    csrrw x0, mscratch, x1
    /* Load the address where we save the registers */
    lui	x1, %hi(cpu_area)
    addi x1, x1, %lo(cpu_area)
    /* The first location is unused. x0 is not saved and x1 is saved in the mscratch register. */
    sw x2, 4(x1)
    sw x3, 8(x1)
    sw x4, 12(x1)
    sw x5, 16(x1)
    sw x6, 20(x1)
    sw x7, 24(x1)
    sw x8, 28(x1)
    sw x9, 32(x1)
    sw x10, 36(x1)
    sw x11, 40(x1)
    sw x12, 44(x1)
    sw x13, 48(x1)
    sw x14, 52(x1)
    sw x15, 56(x1)
    sw x16, 60(x1)
    sw x17, 64(x1)
    sw x18, 68(x1)
    sw x19, 72(x1)
    sw x20, 76(x1)
    sw x21, 80(x1)
    sw x22, 84(x1)
    sw x23, 88(x1)
    sw x24, 92(x1)
    sw x25, 96(x1)
    sw x26, 100(x1)
    sw x27, 104(x1)
    sw x28, 108(x1)
    sw x29, 112(x1)
    sw x30, 116(x1)
    sw x31, 120(x1)

    jal handle_trap

    /* Load the address where we saved the registers */
    lui	x1, %hi(cpu_area)
    addi x1, x1, %lo(cpu_area)

    lw x2, 4(x1)
    lw x3, 8(x1)
    lw x4, 12(x1)
    lw x5, 16(x1)
    lw x6, 20(x1)
    lw x7, 24(x1)
    lw x8, 28(x1)
    lw x9, 32(x1)
    lw x10, 36(x1)
    lw x11, 40(x1)
    lw x12, 44(x1)
    lw x13, 48(x1)
    lw x14, 52(x1)
    lw x15, 56(x1)
    lw x16, 60(x1)
    lw x17, 64(x1)
    lw x18, 68(x1)
    lw x19, 72(x1)
    lw x20, 76(x1)
    lw x21, 80(x1)
    lw x22, 84(x1)
    lw x23, 88(x1)
    lw x24, 92(x1)
    lw x25, 96(x1)
    lw x26, 100(x1)
    lw x27, 104(x1)
    lw x28, 108(x1)
    lw x29, 112(x1)
    lw x30, 116(x1)
    lw x31, 120(x1)

    /* Restore x1 from the mscratch register */
    csrrw x1, mscratch, x0
    mret

.section .data
cpu_area:
    .fill 32,4,0x0
