#!/usr/bin/bash

helpFunction()
{
    echo ""
    echo "Usage: $0 -u -w -p -h"
    echo "    -u: ULX3S board (default)"
    echo "    -w: Blue Whale board."
    echo "    -h: Help."
    exit 1 # Exit script after printing help
}

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
# ENABLE_RV32C_EXT:    Enables/disables support for handling compressed RISC-V instructions.
# ENABLE_RV32A_EXT:    Atomic instructions support.
# ENABLE_ZICSR_EXT:    Zicsr is required for Machine registers manipulation. Disabling it renders the Machine
#                          implementation useless.
# ENABLE_ZIFENCEI_EXT: Zifencei extension
# QPI_MODE:            Use quad SPI for flash.
OPTIONS="-D SIMULATION -D TEST_MODE -D CLK_PERIOD_NS=20 -D ENABLE_RV32M_EXT -D ENABLE_RV32C_EXT -D ENABLE_RV32A_EXT -D ENABLE_ZICSR_EXT -D ENABLE_ZIFENCEI_EXT -D QPI_MODE"

while getopts "uwph" flag; do
    case "${flag}" in
        u ) BOARD="BOARD_ULX3S" ;;
        w ) BOARD="BOARD_BLUE_WHALE" ;;
        h ) helpFunction ;;
        * ) helpFunction ;; #Invalid argument
    esac
done

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
    if test -f "$OUTPUT_FILE" ; then
        rm $OUTPUT_FILE
    fi

    if test -f "../apps/TestCompliance/Release/$1.bin" ; then
        iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/TestCompliance/Release/$1.bin\" -o $OUTPUT_FILE decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv uart_tx.sv uart_rx.sv timer.sv csr.sv io_bus.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_p.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_p.sv
        if [ $? -eq 0 ]; then
            vvp $OUTPUT_FILE
            if [ $? -eq 0 ]; then
                diff --text ../apps/TestCompliance/reference/$1.sig ../apps/TestCompliance/Release/$1.sig
                if [ $? -eq 0 ]; then
                    echo -e "\033[0;32m                                  PASS\033[0m"
                else
                    echo -e "\033[0;31m                                  FAIL [Signature mismatch]\033[0m"
                fi
            else
                echo -e "\033[0;31m                                  FAIL [Simulation failed]\033[0m"
            fi
        else
            echo -e "\033[0;31m                                  FAIL [Cannot build Verilog code]\033[0m"
        fi
    else
        echo -e "\033[0;31m                                  FAIL [Missing ../apps/TestCompliance/Release/$1.bin]\033[0m"
    fi
}

# RV32I instructions
doCompliance "add-01";
doCompliance "addi-01";
doCompliance "and-01";
doCompliance "andi-01";
doCompliance "auipc-01";
doCompliance "beq-01";
doCompliance "bge-01";
doCompliance "bgeu-01";
doCompliance "blt-01";
doCompliance "bltu-01";
doCompliance "bne-01";
doCompliance "fence-01";
doCompliance "jal-01";
doCompliance "jalr-01";
doCompliance "lb-align-01";
doCompliance "lbu-align-01";
doCompliance "lh-align-01";
doCompliance "lhu-align-01";
doCompliance "lui-01";
doCompliance "lw-align-01";
doCompliance "or-01";
doCompliance "ori-01";
doCompliance "sb-align-01";
doCompliance "sh-align-01";
doCompliance "sll-01";
doCompliance "slli-01";
doCompliance "slt-01";
doCompliance "slti-01";
doCompliance "sltiu-01";
doCompliance "sltu-01";
doCompliance "sra-01";
doCompliance "srai-01";
doCompliance "srl-01";
doCompliance "srli-01";
doCompliance "sub-01";
doCompliance "sw-align-01";
doCompliance "xor-01";
doCompliance "xori-01";

# Priviledged tests
doCompliance "ebreak";
doCompliance "ecall";
doCompliance "misalign1-jalr-01";
doCompliance "misalign2-jalr-01";
doCompliance "misalign-beq-01";
doCompliance "misalign-bge-01";
doCompliance "misalign-bgeu-01";
doCompliance "misalign-blt-01";
doCompliance "misalign-bltu-01";
doCompliance "misalign-bne-01";
doCompliance "misalign-jal-01";
# These tests are not supported since a word and a half word need to be aligned at even addresses.
#doCompliance "misalign-lh-01";
#doCompliance "misalign-lhu-01";
#doCompliance "misalign-lw-01";
#doCompliance "misalign-sh-01";
#doCompliance "misalign-sw-01";

# Compressed extension
doCompliance "cadd-01";
doCompliance "caddi-01";
doCompliance "caddi16sp-01";
doCompliance "caddi4spn-01";
doCompliance "cand-01";
doCompliance "candi-01";
doCompliance "cbeqz-01";
doCompliance "cbnez-01";
doCompliance "cebreak-01";
doCompliance "cj-01";
doCompliance "cjal-01";
doCompliance "cjalr-01";
doCompliance "cjr-01";
doCompliance "cli-01";
doCompliance "clui-01";
doCompliance "clw-01";
doCompliance "clwsp-01";
doCompliance "cmv-01";
doCompliance "cnop-01";
doCompliance "cor-01";
doCompliance "cslli-01";
doCompliance "csrai-01";
doCompliance "csrli-01";
doCompliance "csub-01";
doCompliance "csw-01";
doCompliance "cswsp-01";
doCompliance "cxor-01";

# Multiply/Divide extension
doCompliance "mul-01";
doCompliance "mulh-01";
doCompliance "mulhsu-01";
doCompliance "mulhu-01";
doCompliance "div-01";
doCompliance "divu-01";
doCompliance "rem-01";
doCompliance "remu-01";

# Zicsr extension
doCompliance "csr-01";

# Atomic extension
doCompliance "amoadd.w-01";
doCompliance "amoand.w-01";
doCompliance "amomax.w-01";
doCompliance "amomaxu.w-01";
doCompliance "amomin.w-01";
doCompliance "amominu.w-01";
doCompliance "amoor.w-01";
doCompliance "amoswap.w-01";
doCompliance "amoxor.w-01";

# Zifencei extension
# The test assumes that the instruction memory is writtable which is not the case in this implementation.
#doCompliance "Fencei";
