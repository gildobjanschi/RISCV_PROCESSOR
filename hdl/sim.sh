########################################################################################################################
# Configure SIMULATION mode for iverilog with the following command line parameters:
#
# Use -D SIMULATION to enable simulation.
# Use -D TEST_MODE only for instruction testing (tests.sh)
# Use -D BIN_FILE_NAME in the command line to specify the application (RISC V code) bin file name
# Use -D D_STATS_FILE to generate a CSV file with execution timing data.
# Use -D D_CORE, D_CORE_FINE for core and trap debug messages
# Use -D D_MEM_SPACE for mem_space.sv messages
# Use -D D_SDRAM for SDRAM extra debugging
# Use -D D_FLASH_MASTER for FLASH debugging
# Use -D D_IO for IO messages (including printfs)
# Use -D D_TIMER for timer messages
# Use -D D_EXEC for instruction detailed messages
# Use -D GENERATE_VCD to generate a waveform file for GtkWave
#
# Note that all the -D flags above only apply if SIMULATION is enabled. For sythesis none of this flags are used.
########################################################################################################################
#!/usr/bin/bash

helpFunction()
{
    echo ""
    echo "Usage: $0 -u -w -p -m -h [-D <flag>]"
    echo "    -u: ULX3S board."
    echo "    -w: Blue Whale board."
    echo "    -p: Run RISC-V."
    echo "    -m: Run memory space test."
    echo "    -D: debug flags (e.g. -D D_CORE, -D D_EXEC, -D D_IO, -D BIN_FILE_NAME=\"<app_bin_file>\" ...)"
    echo "    -h: Help."
    exit 1
}

# Flags added by default by the script
#
# SIMULATION:           Use simulation mode
# CORE:                 Core debug messages
# CLK_PERIOD_NS:        The main clock period in nano seconds (can be overridden by the command line).
# ENABLE_RV32M_EXT:     Multiply and divide instructions support.
# ENABLE_RV32C_EXT:     Enables/disables support for handling compressed RISC-V instructions.
# ENABLE_RV32A_EXT:     Atomic instructions support.
# ENABLE_ZIFENCEI_EXT:  Zifencei extension
# ENABLE_MHPM:          Enables support for High Performance Counters.
# ENABLE_QPI_MODE             Use quad SPI for flash.
OPTIONS="-D SIMULATION -D D_CORE -D CLK_PERIOD_NS=20 -D ENABLE_RV32M_EXT -D ENABLE_RV32C_EXT -D ENABLE_RV32A_EXT -D ENABLE_ZIFENCEI_EXT -D ENABLE_MHPM -D ENABLE_QPI_MODE"

BOARD=""
APP_NAME=""
OUTPUT_FILE=out.sim
RAM_FILE=""
SIM_RAM_FILE=""

while getopts 'uwpmhD:' opt; do
    case "$opt" in
        u ) BOARD="BOARD_ULX3S" ;;
        w ) BOARD="BOARD_BLUE_WHALE" ;;
        p ) APP_NAME="risc_p" ;;
        m ) APP_NAME="mem_space_test" ;;
        D ) OPTIONS="$OPTIONS -D ${OPTARG}" ;;
        h ) helpFunction ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

if test -z "$APP_NAME"; then
    helpFunction
    exit 1
fi

if test -f "$OUTPUT_FILE"; then
    rm $OUTPUT_FILE
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

if [ "$APP_NAME" = "mem_space_test" ] ; then
    echo "Memory space test."
    iverilog -g2005-sv -D $BOARD $OPTIONS -D BIN_FILE_NAME=\"../apps/TestBlob/TestBlob.bin\" -o $OUTPUT_FILE uart_tx.sv uart_rx.sv utils.sv flash_master.sv $RAM_FILE io.sv timer.sv csr.sv io_bus.sv ram_bus.sv mem_space.sv ecp5pll.sv mem_space_test.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_mem_space_test.sv
    if [ $? -eq 0 ]; then
        vvp $OUTPUT_FILE
    fi
else if [ "$APP_NAME" = "risc_p" ] ; then
    echo "Running RISC-V."
    iverilog -g2005-sv -D $BOARD $OPTIONS -o $OUTPUT_FILE uart_tx.sv uart_rx.sv decoder.sv regfile.sv exec.sv multiplier.sv divider.sv utils.sv flash_master.sv $RAM_FILE io.sv timer.sv csr.sv io_bus.sv ram_bus.sv mem_space.sv ecp5pll.sv risc_p.sv sim_trellis.sv sim_flash_slave.sv $SIM_RAM_FILE sim_top_risc_p.sv
    if [ $? -eq 0 ]; then
        vvp $OUTPUT_FILE
    fi
fi
fi
