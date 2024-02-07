#!/usr/bin/bash

BOARD=""
OUTPUT_FILE=out.sim
RAM_FILE=""
SIM_RAM_FILE=""
# Flags added by default by the script
#
# SIMULATION:          Use simulation mode
# TEST_MODE:           Test mode checks if the test terminated with or without errors..
# CLK_PERIOD_NS:       The main clock period in nano seconds.
# ENABLE_RV32M_EXT:    Multiply and divide instructions support.
# ENABLE_ZICSR_EXT:    Zicsr is required for Machine registers manipulation. Disabling it renders the Machine
#                          implementation useless.
# ENABLE_ZIFENCEI_EXT: Zifencei extension
# ENABLE_RV32C_EXT:    Enables/disables support for handling compressed RISC-V instructions.
# ENABLE_RV32A_EXT:    Atomic instructions support.
# ENABLE_HPM_COUNTERS: Enables support for High Performance Counters.
# QPI_MODE:            Use quad SPI for flash.
OPTIONS="-D SIMULATION -D TEST_MODE -D CLK_PERIOD_NS=20 -D ENABLE_RV32M_EXT -D ENABLE_ZICSR_EXT -D ENABLE_ZIFENCEI_EXT -D ENABLE_RV32C_EXT -D ENABLE_RV32A_EXT -D ENABLE_HPM_COUNTERS -D QPI_MODE"

while getopts "uwph" flag; do
	case "${flag}" in
		u ) BOARD="BOARD_ULX3S" ;;
		w ) BOARD="BOARD_BLUE_WHALE" ;;
		p ) echo "Running RISC-V."; APP_NAME="risc_p" ;;
		h ) helpFunction ;;
		* ) helpFunction ;; #Invalid argument
	esac
done

if test -z "$APP_NAME"; then
	APP_NAME="risc_p"
fi

if test -z "$BOARD"; then
	BOARD="BOARD_ULX3S"
fi

if [ "$BOARD" = "BOARD_ULX3S" ] ; then
	echo "Running on ULX3S."
	RAM_FILE="sdram.sv"
	SIM_RAM_FILE="sim_sdram.sv"
else if [ "$BOARD" = "BOARD_BLUE_WHALE" ] ; then
	echo "Running on Blue Whale."
	RAM_FILE="psram.sv"
	SIM_RAM_FILE="sim_psram.sv"
fi
fi

doCompliance()
{
	if test -f "$OUTPUT_FILE"; then
		rm $OUTPUT_FILE
	fi

	if [ "$APP_NAME" = "risc_p" ] ; then
		iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/TestCompliance/Release/$1\" -o $OUTPUT_FILE decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv uart_tx.sv uart_rx.sv timer.sv csr.sv io_bus.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_p.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_p.sv
		if [ $? -eq 0 ]; then
			vvp $OUTPUT_FILE
		fi
	fi
}

doRandom()
{
	if test -f "$OUTPUT_FILE"; then
		rm $OUTPUT_FILE
	fi

	if [ "$APP_NAME" = "risc_p" ] ; then
		iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/RandomTest/Release/$1\" -o $OUTPUT_FILE decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv uart_tx.sv uart_rx.sv timer.sv csr.sv io_bus.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_p.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_p.sv
		if [ $? -eq 0 ]; then
			vvp $OUTPUT_FILE
		fi
	fi
}

# RV32I instructions
doCompliance "add-01.bin";
doCompliance "addi-01.bin";
doCompliance "and-01.bin";
doCompliance "andi-01.bin";
doCompliance "auipc-01.bin";
doCompliance "beq-01.bin";
doCompliance "bge-01.bin";
doCompliance "bgeu-01.bin";
doCompliance "blt-01.bin";
doCompliance "bltu-01.bin";
doCompliance "bne-01.bin";
doCompliance "fence-01.bin";
doCompliance "jal-01.bin";
doCompliance "jalr-01.bin";
doCompliance "misalign1-jalr-01.bin";
doCompliance "lb-align-01.bin";
doCompliance "lbu-align-01.bin";
doCompliance "lh-align-01.bin";
doCompliance "lhu-align-01.bin";
doCompliance "lui-01.bin";
doCompliance "lw-align-01.bin";
doCompliance "or-01.bin";
doCompliance "ori-01.bin";
doCompliance "sb-align-01.bin";
doCompliance "sh-align-01.bin";
doCompliance "sll-01.bin";
doCompliance "slli-01.bin";
doCompliance "slt-01.bin";
doCompliance "slti-01.bin";
doCompliance "sltiu-01.bin";
doCompliance "sltu-01.bin";
doCompliance "sra-01.bin";
doCompliance "srai-01.bin";
doCompliance "srl-01.bin";
doCompliance "srli-01.bin";
doCompliance "sub-01.bin";
doCompliance "sw-align-01.bin";
doCompliance "xor-01.bin";
doCompliance "xori-01.bin";

# Priviledged tests
doCompliance "misalign2-jalr-01.bin";
doCompliance "misalign-beq-01.bin";
doCompliance "misalign-bge-01.bin";
doCompliance "misalign-bgeu-01.bin";
doCompliance "misalign-blt-01.bin";
doCompliance "misalign-bltu-01.bin";
doCompliance "misalign-bne-01.bin";
doCompliance "misalign-jal-01.bin";
doCompliance "misalign-lh-01.bin";
doCompliance "misalign-lhu-01.bin";
doCompliance "misalign-lw-01.bin";
doCompliance "misalign-sh-01.bin";
doCompliance "misalign-sw-01.bin";

# Compressed instructions
doCompliance "cadd-01.bin";
doCompliance "caddi-01.bin";
doCompliance "caddi16sp-01.bin";
doCompliance "caddi4spn-01.bin";
doCompliance "cand-01.bin";
doCompliance "candi-01.bin";
doCompliance "cbeqz-01.bin";
doCompliance "cbnez-01.bin";
doCompliance "cjal-01.bin";
doCompliance "cjalr-01.bin";
doCompliance "cjr-01.bin";
doCompliance "cli-01.bin";
doCompliance "clui-01.bin";
doCompliance "clw-01.bin";
doCompliance "clwsp-01.bin";
doCompliance "cmv-01.bin";
doCompliance "cnop-01.bin";
doCompliance "cor-01.bin";
doCompliance "cslli-01.bin";
doCompliance "csrai-01.bin";
doCompliance "csrli-01.bin";
doCompliance "csub-01.bin";
doCompliance "csw-01.bin";
doCompliance "cswsp-01.bin";
doCompliance "cxor-01.bin";

# Multiply/Divide instructions
doCompliance "mul-01.bin";
doCompliance "mulh-01.bin";
doCompliance "mulhsu-01.bin";
doCompliance "mulhu-01.bin";
doCompliance "div-01.bin";
doCompliance "divu-01.bin";
doCompliance "rem-01.bin";
doCompliance "remu-01.bin";

# CSR instructions
doCompliance "csr-01.bin";

# Atomic instructions
doCompliance "amoadd.w-01.bin";
doCompliance "amoand.w-01.bin";
doCompliance "amomax.w-01.bin";
doCompliance "amomaxu.w-01.bin";
doCompliance "amomin.w-01.bin";
doCompliance "amominu.w-01.bin";
doCompliance "amoor.w-01.bin";
doCompliance "amoswap.w-01.bin";
doCompliance "amoxor.w-01.bin";

# Google random tests (from sample)
doRandom "riscv_arithmetic_basic_test_0.bin";
doRandom "riscv_ebreak_debug_mode_test_0.bin";
doRandom "riscv_ebreak_test_0.bin";
doRandom "riscv_full_interrupt_test_0.bin";
doRandom "riscv_hint_instr_test_0.bin";
doRandom "riscv_illegal_instr_test_0.bin";
doRandom "riscv_jump_stress_test_0.bin";
doRandom "riscv_loop_test_0.bin";
doRandom "riscv_mmu_stress_test_0.bin";
doRandom "riscv_no_fence_test_0.bin";
doRandom "riscv_non_compressed_instr_test_0.bin";
doRandom "riscv_rand_instr_test_0.bin";
doRandom "riscv_rand_jump_test_0.bin";
doRandom "riscv_unaligned_load_store_test_0.bin";
