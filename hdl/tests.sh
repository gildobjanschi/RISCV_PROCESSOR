#!/usr/bin/bash

BOARD=""
OUTPUT_FILE=out.sim
RAM_FILE=""
SIM_RAM_FILE=""
# Flags added by default by the script
#
# SIMULATION:          Use simulation mode
# CLK_PERIOD_NS        The main clock period in nano seconds.
# ENABLE_RV32M_EXT:    Multiply and divide instructions support.
# ENABLE_ZISCR_EXT:    Zicsr is required for Machine registers manipulation. Disabling it renders the Machine
#                          implementation useless.
# ENABLE_RV32C_EXT:    Enables/disables support for handling compressed RISC-V instructions.
# ENABLE_RV32A_EXT:    Atomic instructions support.
# ENABLE_HPM_COUNTERS: Enables support for High Performance Counters.
# QPI_MODE:            Use quad SPI for flash.
OPTIONS="-D SIMULATION -D TEST_MODE -D CLK_PERIOD_NS=20 -D ENABLE_RV32M_EXT -D ENABLE_ZISCR_EXT -D ENABLE_RV32C_EXT -D ENABLE_RV32A_EXT -D ENABLE_HPM_COUNTERS -D QPI_MODE"

while getopts "uwpsh" flag; do
	case "${flag}" in
		u ) BOARD="BOARD_ULX3S" ;;
		w ) BOARD="BOARD_BLUE_WHALE" ;;
		p ) echo "Running pipeline version."; APP_NAME="risc_p" ;;
		s ) echo "Running sequential version."; APP_NAME="risc_s" ;;
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

doFunction()
{
	if test -f "$OUTPUT_FILE"; then
		rm $OUTPUT_FILE
	fi

	if [ "$APP_NAME" = "risc_s" ] ; then
		iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/TestCompliance/Release/$1\" -o $OUTPUT_FILE decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv uart_tx.sv uart_rx.sv timer.sv csr.sv mem_space.sv ecp5pll.sv risc_s.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_s.sv
		if [ $? -eq 0 ]; then
			vvp $OUTPUT_FILE
		fi
	else if [ "$APP_NAME" = "risc_p" ] ; then
		iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/TestCompliance/Release/$1\" -o $OUTPUT_FILE decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv uart_tx.sv uart_rx.sv timer.sv csr.sv mem_space.sv ecp5pll.sv risc_p.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_p.sv
		if [ $? -eq 0 ]; then
			vvp $OUTPUT_FILE
		fi
	fi
	fi
}

# RV32I instructions
doFunction "add-01.bin";
doFunction "addi-01.bin";
doFunction "and-01.bin";
doFunction "andi-01.bin";
doFunction "auipc-01.bin";
doFunction "beq-01.bin";
doFunction "bge-01.bin";
doFunction "bgeu-01.bin";
doFunction "blt-01.bin";
doFunction "bltu-01.bin";
doFunction "bne-01.bin";
doFunction "fence-01.bin";
doFunction "jal-01.bin";
doFunction "jalr-01.bin";
doFunction "misalign1-jalr-01.bin";
doFunction "lb-align-01.bin";
doFunction "lbu-align-01.bin";
doFunction "lh-align-01.bin";
doFunction "lhu-align-01.bin";
doFunction "lui-01.bin";
doFunction "lw-align-01.bin";
doFunction "or-01.bin";
doFunction "ori-01.bin";
doFunction "sb-align-01.bin";
doFunction "sh-align-01.bin";
doFunction "sll-01.bin";
doFunction "slli-01.bin";
doFunction "slt-01.bin";
doFunction "slti-01.bin";
doFunction "sltiu-01.bin";
doFunction "sltu-01.bin";
doFunction "sra-01.bin";
doFunction "srai-01.bin";
doFunction "srl-01.bin";
doFunction "srli-01.bin";
doFunction "sub-01.bin";
doFunction "sw-align-01.bin";
doFunction "xor-01.bin";
doFunction "xori-01.bin";

# Priviledged tests
doFunction "misalign2-jalr-01.bin";
doFunction "misalign-beq-01.bin";
doFunction "misalign-bge-01.bin";
doFunction "misalign-bgeu-01.bin";
doFunction "misalign-blt-01.bin";
doFunction "misalign-bltu-01.bin";
doFunction "misalign-bne-01.bin";
doFunction "misalign-jal-01.bin";
doFunction "misalign-lh-01.bin";
doFunction "misalign-lhu-01.bin";
doFunction "misalign-lw-01.bin";
doFunction "misalign-sh-01.bin";
doFunction "misalign-sw-01.bin";

# Compressed instructions
doFunction "cadd-01.bin";
doFunction "caddi-01.bin";
doFunction "caddi16sp-01.bin";
doFunction "caddi4spn-01.bin";
doFunction "cand-01.bin";
doFunction "candi-01.bin";
doFunction "cbeqz-01.bin";
doFunction "cbnez-01.bin";
doFunction "cjal-01.bin";
doFunction "cjalr-01.bin";
doFunction "cjr-01.bin";
doFunction "cli-01.bin";
doFunction "clui-01.bin";
doFunction "clw-01.bin";
doFunction "clwsp-01.bin";
doFunction "cmv-01.bin";
doFunction "cnop-01.bin";
doFunction "cor-01.bin";
doFunction "cslli-01.bin";
doFunction "csrai-01.bin";
doFunction "csrli-01.bin";
doFunction "csub-01.bin";
doFunction "csw-01.bin";
doFunction "cswsp-01.bin";
doFunction "cxor-01.bin";

# Multiply/Divide instructions
doFunction "mul-01.bin";
doFunction "mulh-01.bin";
doFunction "mulhsu-01.bin";
doFunction "mulhu-01.bin";
doFunction "div-01.bin";
doFunction "divu-01.bin";
doFunction "rem-01.bin";
doFunction "remu-01.bin";

# CSR instructions
doFunction "csr-01.bin";

# Atomic instructions
doFunction "amoadd.w-01.bin";
doFunction "amoand.w-01.bin";
doFunction "amomax.w-01.bin";
doFunction "amomaxu.w-01.bin";
doFunction "amomin.w-01.bin";
doFunction "amominu.w-01.bin";
doFunction "amoor.w-01.bin";
doFunction "amoswap.w-01.bin";
doFunction "amoxor.w-01.bin";
