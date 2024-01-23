#!/usr/bin/bash

helpFunction()
{
    echo ""
    echo "Usage: $0 -u -w -p -s -m -h [-b <file name>] [-D <define>]"
    echo "    -u: ULX3S board."
    echo "    -w: Blue Whale board."
    echo "    -p: Run pipelined version."
    echo "    -s: Run sequential version."
    echo "    -m: Run the memory space test."
    echo "    -b: The name of the bin file to flash. Use this option only with -p -n."
    echo "    -D: define (e.g. -D CLK_PERIOD_NS)."
    echo "    -h: Help."
    exit 1 # Exit script after printing help
}


BOARD=""

# Flags added by default by the script
#
# ENABLE_RV32M_EXT:    Multiply and divide instructions support.
# ENABLE_ZICSR_EXT     Zicsr is required for Machine registers manipulation. Disabling it renders the Machine
#                          implementation useless.
# ENABLE_RV32C_EXT:    Enables/disables support for handling compressed RISC-V instructions.
# ENABLE_RV32A_EXT:    Atomic instructions support.
# ENABLE_HPM_COUNTERS: Enables support for High Performance Counters.
# QPI_MODE:            Use quad SPI for flash.
OPTIONS="-D ENABLE_RV32M_EXT -D ENABLE_ZICSR_EXT -D ENABLE_RV32C_EXT -D ENABLE_RV32A_EXT -D ENABLE_HPM_COUNTERS -D QPI_MODE"

APP_NAME=""
BIN_FILE=""
RAM_FILE=""
LPF_FILE=""
SPEED=""

while getopts "uwpsmhb:D:" flag; do
    case "${flag}" in
        u ) BOARD="BOARD_ULX3S" ;;
        w ) BOARD="BOARD_BLUE_WHALE" ;;
        p ) echo "Running pipeline version."; APP_NAME="risc_p" ;;
        s ) echo "Running sequential version."; APP_NAME="risc_s" ;;
        m ) echo "Running memory space test."; APP_NAME="mem_space_test" ;;
        D ) OPTIONS="$OPTIONS -D ${OPTARG}" ;;
        h ) helpFunction ;;
        b ) BIN_FILE=${OPTARG} ;;
        * ) helpFunction ;; #Invalid argument
    esac
done

if test -z "$APP_NAME"; then
    helpFunction
    exit 1
fi

if test -f "out.bit"; then
    rm out.bit
fi

if test -f "out.config"; then
    rm out.config
fi

if test -f "out.json"; then
    rm out.json
fi

if test -z "$BOARD"; then
    BOARD="BOARD_ULX3S"
fi

if [ "$BOARD" = "BOARD_ULX3S" ] ; then
    echo "Running on ULX3S."
    RAM_FILE="sdram.sv"
    LPF_FILE="ulx3s.lpf"
    SPEED="6"
else if [ "$BOARD" = "BOARD_BLUE_WHALE" ] ; then
    echo "Running on Blue Whale."
    RAM_FILE="psram.sv"
    LPF_FILE="blue_whale.lpf"
    SPEED="8"
fi
fi

if [ "$APP_NAME" = "mem_space_test" ] ; then
    openFPGALoader --board ulx3s --file-type bin -o 0x600000 --unprotect-flash --write-flash ../apps/TestBlob/TestBlob.bin
    yosys -p "synth_ecp5 -json out.json" -D $BOARD $OPTIONS uart_tx.sv uart_rx.sv utils.sv $RAM_FILE flash_master.sv io.sv timer.sv csr.sv ram_bus.sv mem_space.sv ecp5pll.sv mem_space_test.sv
    nextpnr-ecp5 --package CABGA381 --speed $SPEED --85k --freq 62.50 --json out.json --lpf $LPF_FILE --textcfg out.config
    ecppack --db ../prjtrellis-db out.config out.bit
    openFPGALoader -b ulx3s out.bit
else if [ "$APP_NAME" = "risc_s" ] ; then
    if test ! -z "$BIN_FILE"; then
        echo "Flashing bin file: $BIN_FILE ..."
        openFPGALoader --board ulx3s --file-type bin -o 0x600000 --unprotect-flash --write-flash $BIN_FILE
    fi
    yosys -p "synth_ecp5 -json out.json" -D $BOARD $OPTIONS uart_tx.sv uart_rx.sv decoder.sv regfile.sv utils.sv exec.sv divider.sv multiplier.sv flash_master.sv $RAM_FILE io.sv timer.sv csr.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_s.sv
    nextpnr-ecp5 --package CABGA381 --speed $SPEED --85k --freq 62.50 --json out.json --lpf $LPF_FILE --textcfg out.config
    ecppack --db ../prjtrellis-db out.config out.bit
    openFPGALoader -b ulx3s out.bit
else if [ "$APP_NAME" = "risc_p" ] ; then
    if test ! -z "$BIN_FILE"; then
        echo "Flashing bin file: $BIN_FILE ..."
        openFPGALoader --board ulx3s --file-type bin -o 0x600000 --unprotect-flash --write-flash $BIN_FILE
    fi
    yosys -p "synth_ecp5 -json out.json" -D $BOARD $OPTIONS uart_tx.sv uart_rx.sv decoder.sv regfile.sv utils.sv exec.sv divider.sv multiplier.sv flash_master.sv $RAM_FILE io.sv timer.sv csr.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_p.sv
    nextpnr-ecp5 --package CABGA381 --speed $SPEED --85k --freq 62.50 --json out.json --lpf $LPF_FILE --textcfg out.config
    ecppack --db ../prjtrellis-db out.config out.bit
    openFPGALoader -b ulx3s out.bit
fi
fi
fi
