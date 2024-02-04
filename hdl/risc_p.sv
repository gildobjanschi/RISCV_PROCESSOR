/***********************************************************************************************************************
 * Copyright (c) 2024 Virgil Dobjanschi dobjanschivirgil@gmail.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of
 * the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * This module implements the RISC V pipelined execution.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "traps.svh"

module risc_p (
    input logic clk_in,
    output logic [7:0] led,
    input logic [2:0] btn,
    // SPI flash wires
    output logic flash_csn,
`ifdef SIMULATION
    output logic flash_clk,
`endif
    inout logic flash_mosi,
    inout logic flash_miso,
    inout logic flash_wpn,
    inout logic flash_holdn,
    // UART wires
    output logic ftdi_rxd,  // FPGA output: TXD
    input logic ftdi_txd,   // FPGA input : RXD
`ifdef BOARD_ULX3S
    output logic wifi_gpio0,
    // RAM wires
    output logic sdram_clk,
    output logic sdram_cke,
    output logic sdram_csn,
    output logic sdram_wen,
    output logic sdram_rasn,
    output logic sdram_casn,
    output logic [12:0] sdram_a,
    output logic [1:0] sdram_ba,
    output logic [1:0] sdram_dqm,
    inout logic [15:0] sdram_d
`else // BOARD_BLUE_WHALE
    output logic [15:0] led_a,
    output logic [15:0] led_b,
    // RAM wires
    output logic psram_cen,
    output logic psram_wen,
    output logic psram_oen,
    output logic psram_lbn,
    output logic psram_ubn,
    output logic [21:0] psram_a,
    inout logic [15:0] psram_d
`endif // BOARD_ULX3S
);

    //==================================================================================================================
    // Clocks
    //==================================================================================================================
    // For simulation use a period that is divisible by 4 (12, 16, 20).
    localparam CLK_PERIOD_NS = `CLK_PERIOD_NS;

    // For SPI mode (QPI_MODE not defined) the minimum value is 16, for QPI_MODE the minimum value is 20.
    localparam FLASH_CLK_PERIOD_NS = 20;

    // The period of the IO/timer clock
    localparam TIMER_CLK_PERIOD_NS = 100;

`ifdef SIMULATION
    logic clk = 1'b0;
    // Generate the simulator clock
    always #(CLK_PERIOD_NS/2) clk = ~clk;

    logic flash_master_clk = 1'b0;
    always #(FLASH_CLK_PERIOD_NS/2) flash_master_clk = ~flash_master_clk;

    // The flash clock
    logic flash_device_clk = 1'b0;
    logic [1:0] clk_gen_f = 2'b01;  // 270: 2'b01 | 180: 2'b10 | 90: 2'b11
    always #(FLASH_CLK_PERIOD_NS/4) begin
        flash_device_clk <= clk_gen_f[0] ^ clk_gen_f[1];
        clk_gen_f <= clk_gen_f + 2'b01;
    end

`ifdef BOARD_ULX3S
    // The SDRAM clock
    logic sdram_device_clk = 1'b0;
    logic [1:0] clk_gen_s = 2'b11;  // 270: 2'b01 | 180: 2'b10 | 90: 2'b11
    always #(CLK_PERIOD_NS/4) begin
        sdram_device_clk <= clk_gen_s[0] ^ clk_gen_s[1];
        clk_gen_s <= clk_gen_s + 2'b01;
    end
`endif // BOARD_ULX3S
    // The IO/timer clock
    logic timer_clk = 1'b0;
    always #(TIMER_CLK_PERIOD_NS/2) timer_clk = ~timer_clk;

    logic pll_locked = 1'b1;
`else // SIMULATION
    logic clk;
    logic flash_master_clk;
    logic flash_device_clk;
    logic timer_clk;

    logic pll_locked, pll_locked_main, pll_locked_secondary;
    logic [3:0]clocks_main;
    logic [3:0] clocks_secondary;

`ifdef BOARD_ULX3S
    // Set GPIO0 high (keep board from rebooting)
    assign wifi_gpio0 = 1'b1;

    ecp5pll #(.in_hz(25000000),
            .out0_hz(1000000000/CLK_PERIOD_NS),
            .out1_hz(1000000000/CLK_PERIOD_NS), .out1_deg(90)) pll_main(
            .clk_i(clk_in),
            .clk_o(clocks_main),
            .reset(1'b0),
            .standby(1'b0),
            .phasesel(2'b00),
            .phasedir(1'b0),
            .phasestep(1'b0),
            .phaseloadreg(1'b0),
            .locked(pll_locked_main));

    logic sdram_device_clk;
    assign sdram_device_clk = clocks_main[1];

    ecp5pll #(.in_hz(25000000),
            .out0_hz(1000000000/FLASH_CLK_PERIOD_NS), // 50MHz
            .out1_hz(1000000000/FLASH_CLK_PERIOD_NS), .out1_deg(270), // 50MHz shifted
            .out2_hz(1000000000/TIMER_CLK_PERIOD_NS)) pll_secondary(
            .clk_i(clk_in),
            .clk_o(clocks_secondary),
            .reset(1'b0),
            .standby(1'b0),
            .phasesel(2'b00),
            .phasedir(1'b0),
            .phasestep(1'b0),
            .phaseloadreg(1'b0),
            .locked(pll_locked_secondary));
`else // BOARD_BLUE_WHALE
    ecp5pll #(.in_hz(50000000),
            .out0_hz(1000000000/CLK_PERIOD_NS)) pll_main(
            .clk_i(clk_in),
            .clk_o(clocks_main),
            .reset(1'b0),
            .standby(1'b0),
            .phasesel(2'b00),
            .phasedir(1'b0),
            .phasestep(1'b0),
            .phaseloadreg(1'b0),
            .locked(pll_locked_main));

    ecp5pll #(.in_hz(50000000),
            .out0_hz(1000000000/FLASH_CLK_PERIOD_NS), // 50MHz
            .out1_hz(1000000000/FLASH_CLK_PERIOD_NS), .out1_deg(270), // 50MHz shifted
            .out2_hz(1000000000/TIMER_CLK_PERIOD_NS)) pll_secondary(
            .clk_i(clk_in),
            .clk_o(clocks_secondary),
            .reset(1'b0),
            .standby(1'b0),
            .phasesel(2'b00),
            .phasedir(1'b0),
            .phasestep(1'b0),
            .phaseloadreg(1'b0),
            .locked(pll_locked_secondary));
`endif // BOARD_ULX3S

    assign clk = clocks_main[0];
    assign flash_master_clk = clocks_secondary[0];
    assign flash_device_clk = clocks_secondary[1];
    assign timer_clk = clocks_secondary[2];
    assign pll_locked = pll_locked_main & pll_locked_secondary;

    // Provide the clock to the flash.
    logic flash_clk;
    logic tristate = 1'b0;
    USRMCLK u1 (.USRMCLKI(flash_clk), .USRMCLKTS(tristate));
`endif // SIMULATION

    //==================================================================================================================
    // Instantiate the modules
    //==================================================================================================================
    // Memory space ports
    // Core
    logic [31:0] core_addr_o;
    logic [31:0] core_data_i, core_data_o;
    logic [3:0] core_sel_o;
    logic core_we_o, core_stb_o, core_cyc_o, core_ack_i, core_err_i, core_data_tag_i;
    // Exec ports (we use the wire type to make it clear that this module is not using these signals)
    wire [31:0] data_addr_w, data_data_i_w, data_data_o_w;
    wire [3:0] data_sel_w;
    wire data_we_w, data_stb_w, data_cyc_w, data_ack_w, data_err_w, data_data_tag_w;
    wire [2:0] data_addr_tag_w;
    // Event counters
    logic [31:0] incr_event_counters_o;
    // IO interrupt
    logic [31:0] io_interrupts_i;

    // Decoder ports
    logic decoder_stb_o, decoder_cyc_o, decoder_load_rs1_rs2_i, decoder_ack_i, decoder_err_i;
    logic [31:0] decoder_instruction_o, decoder_op_imm_i;
    logic [6:0] decoder_op_type_i;
    logic [4:0] decoder_op_rd_i, decoder_op_rs1_i, decoder_op_rs2_i;

    // Regfile ports
    logic regfile_stb_read_o, regfile_cyc_read_o, regfile_ack_read_i;
    logic regfile_stb_write_o, regfile_cyc_write_o, regfile_ack_write_i;
    logic [4:0] regfile_op_rs1_o, regfile_op_rs2_o, regfile_op_rd_o;
    logic [31:0] regfile_reg_rs1_i, regfile_reg_rs2_i, regfile_reg_rd_o;

    // Exec ports
    logic exec_stb_o, exec_cyc_o, exec_instr_is_compressed_o, exec_ack_i, exec_err_i, exec_jmp_i, exec_mret_i;
    logic [31:0] exec_instr_addr_o, exec_instr_o, exec_op_imm_o, exec_rs1_o, exec_rs2_o, exec_rd_i, exec_next_addr_i;
    logic [31:0] exec_trap_mcause_i, exec_trap_mtval_i;
    logic [6:0] exec_op_type_o;
    logic [4:0] exec_op_rd_o, exec_op_rs1_o, exec_op_rs2_o;

    mem_space #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) mem_space_m(
        .clk_i              (clk),
        .rst_i              (reset),
        // Wishbone interface for reading instructions
        .core_addr_i        (core_addr_o),
        .core_data_i        (core_data_o),
        .core_stb_i         (core_stb_o),
        .core_cyc_i         (core_cyc_o),
        .core_sel_i         (core_sel_o),
        .core_we_i          (core_we_o),
        .core_ack_o         (core_ack_i),
        .core_err_o         (core_err_i),
        .core_data_o        (core_data_i),
        .core_data_tag_o    (core_data_tag_i),
        // Wishbone interface for reading and writing data
        .data_addr_i        (data_addr_w),
        .data_addr_tag_i    (data_addr_tag_w),
        .data_data_i        (data_data_i_w),
        .data_stb_i         (data_stb_w),
        .data_cyc_i         (data_cyc_w),
        .data_sel_i         (data_sel_w),
        .data_we_i          (data_we_w),
        .data_ack_o         (data_ack_w),
        .data_err_o         (data_err_w),
        .data_data_o        (data_data_o_w),
        .data_data_tag_o    (data_data_tag_w),
`ifdef BOARD_ULX3S
        .sdram_device_clk_i (sdram_device_clk),
        // SDRAM wires
        .sdram_clk          (sdram_clk),
        .sdram_cke          (sdram_cke),
        .sdram_csn          (sdram_csn),
        .sdram_wen          (sdram_wen),
        .sdram_rasn         (sdram_rasn),
        .sdram_casn         (sdram_casn),
        .sdram_a            (sdram_a),
        .sdram_ba           (sdram_ba),
        .sdram_dqm          (sdram_dqm),
        .sdram_d            (sdram_d),
`else //BOARD_ULX3S
        .led                (led_b),
        // PSRAM signals
        .psram_cen          (psram_cen),
        .psram_wen          (psram_wen),
        .psram_oen          (psram_oen),
        .psram_lbn          (psram_lbn),
        .psram_ubn          (psram_ubn),
        .psram_a            (psram_a),
        .psram_d            (psram_d),
`endif // BOARD_ULX3S
        .flash_master_clk_i (flash_master_clk),
        .flash_device_clk_i (flash_device_clk),
        .timer_clk_i        (timer_clk),
        .incr_event_counters_i  (incr_event_counters_o),
        // IO interrupts
        .io_interrupts_o    (io_interrupts_i),
        // Flash wires
        .flash_csn          (flash_csn),
        .flash_clk          (flash_clk),
        .flash_mosi         (flash_mosi),
        .flash_miso         (flash_miso),
        .flash_wpn          (flash_wpn),
        .flash_holdn        (flash_holdn),
        // UART wires
        .uart_txd_o         (ftdi_rxd), // FPGA output: TXD
        .uart_rxd_i         (ftdi_txd), // FPGA input: RXD
        .external_irq_i     (btn[2]));

    decoder decoder_m (
        .clk_i              (clk),
        .rst_i              (reset),
        .stb_i              (decoder_stb_o),
        .cyc_i              (decoder_cyc_o),
        .instr_i            (decoder_instruction_o),
        .instr_op_type_o    (decoder_op_type_i),
        .instr_op_rd_o      (decoder_op_rd_i),
        .instr_op_rs1_o     (decoder_op_rs1_i),
        .instr_op_rs2_o     (decoder_op_rs2_i),
        .instr_op_imm_o     (decoder_op_imm_i),
        .instr_load_rs1_rs2_o(decoder_load_rs1_rs2_i),
        .ack_o              (decoder_ack_i),
        .err_o              (decoder_err_i));

    regfile regfile_m (
        .clk_i              (clk),
        .rst_i              (reset),
        // Read
        .stb_read_i         (regfile_stb_read_o),
        .cyc_read_i         (regfile_cyc_read_o),
        .op_rs1_i           (regfile_op_rs1_o),
        .op_rs2_i           (regfile_op_rs2_o),
        .ack_read_o         (regfile_ack_read_i),
        .reg_rs1_o          (regfile_reg_rs1_i),
        .reg_rs2_o          (regfile_reg_rs2_i),
        // Write
        .stb_write_i        (regfile_stb_write_o),
        .cyc_write_i        (regfile_cyc_write_o),
        .op_rd_i            (regfile_op_rd_o),
        .reg_rd_i           (regfile_reg_rd_o),
        .ack_write_o        (regfile_ack_write_i));

    exec #(.CSR_BEGIN_ADDR(`CSR_BEGIN_ADDR)) exec_m (
        .clk_i              (clk),
        .rst_i              (reset),
        .stb_i              (exec_stb_o),
        .cyc_i              (exec_cyc_o),
        // Instruction to be executed
        .instr_addr_i       (exec_instr_addr_o),
        .instr_i            (exec_instr_o),
        .instr_is_compressed_i  (exec_instr_is_compressed_o),
        .instr_op_type_i    (exec_op_type_o),
        .instr_op_rd_i      (exec_op_rd_o),
        .instr_op_rs1_i     (exec_op_rs1_o),
        .instr_op_rs2_i     (exec_op_rs2_o),
        .instr_op_imm_i     (exec_op_imm_o),
        .rs1_i              (exec_rs1_o),
        .rs2_i              (exec_rs2_o),
        // Execution complete output
        .ack_o              (exec_ack_i),
        .err_o              (exec_err_i),
        .jmp_o              (exec_jmp_i),
        .mret_o             (exec_mret_i),
        .next_addr_o        (exec_next_addr_i),
        .rd_o               (exec_rd_i),
        // Trap ports
        .trap_mcause_o      (exec_trap_mcause_i),
        .trap_mtval_o       (exec_trap_mtval_i),
        // Read/write RAM/ROM/IO data for l(b/h/w) s(b/h/w) instructions
        .data_addr_o        (data_addr_w),
        .data_addr_tag_o    (data_addr_tag_w),
        .data_data_o        (data_data_i_w),
        .data_stb_o         (data_stb_w),
        .data_cyc_o         (data_cyc_w),
        .data_sel_o         (data_sel_w),
        .data_we_o          (data_we_w),
        .data_ack_i         (data_ack_w),
        .data_err_i         (data_err_w),
        .data_data_i        (data_data_o_w),
        .data_tag_i         (data_data_tag_w));

    //==================================================================================================================
    // Definitions
    //==================================================================================================================
    // The CPU state
    localparam STATE_RESET      = 2'b00;
    localparam STATE_RUNNING    = 2'b01;
    localparam STATE_TRAP       = 2'b10;
    localparam STATE_HALTED     = 2'b11;
    logic [1:0] cpu_state_m = STATE_RESET;

    // Trap state machines
    localparam TRAP_STATE_START                 = 4'h0;
    localparam TRAP_WRITE_MEPC_READY            = 4'h1;
    localparam TRAP_STATE_WRITE_MTVAL           = 4'h2;
    localparam TRAP_STATE_WRITE_MTVAL_READY     = 4'h3;
    localparam TRAP_STATE_WRITE_MCAUSE          = 4'h4;
    localparam TRAP_STATE_WRITE_MCAUSE_READY    = 4'h5;
    localparam TRAP_STATE_ENTER_TRAP            = 4'h6;
    localparam TRAP_STATE_ENTER_TRAP_READY      = 4'h7;
    localparam TRAP_STATE_ERROR                 = 4'h8;
    localparam TRAP_STATE_FETCH                 = 4'h9;
    logic [3:0] trap_state_m;

    logic [31:0] fetch_address;
    // Last writeback register index and register value
    logic [4:0] writeback_op_rd;
    logic [31:0] writeback_rd;

    logic [7:0] execute_trap;

    // Reset button meta stability handling
    logic reset = 1'b1;
    logic reset_btn;
`ifdef BOARD_BLUE_WHALE
    // Button on the FPGA board
    //DFF_META reset_meta_m (1'b0, btn[0], clk, reset_btn);
    // Button on the extension board
    DFF_META reset_meta_m (1'b0, btn[1], clk, reset_btn);
`else
    DFF_META reset_meta_m (1'b0, btn[0], clk, reset_btn);
`endif
    //==================================================================================================================
    // Pipeline FIFO variables
    //==================================================================================================================
    localparam PIPELINE_BITS = 2;
    localparam PIPELINE_SIZE = 2 ** PIPELINE_BITS;

    logic [PIPELINE_BITS-1:0] pipeline_rd_ptr, pipeline_wr_ptr, next_pipeline_rd_ptr, next_pipeline_wr_ptr;
    // Pipeline stall means that no new instructions will enter the pipeline. Instructions already in the pipeline
    // will still be processed.
    logic pipeline_full, pipeline_stall;
    assign pipeline_full = next_pipeline_wr_ptr == pipeline_rd_ptr;

    // The pipeline entry state
    localparam PL_E_EMPTY               = 3'b000;
    localparam PL_E_INSTR_FETCH_PENDING = 3'b001;
    localparam PL_E_INSTR_FETCHED       = 3'b010;
    localparam PL_E_INSTR_DECODE_PENDING= 3'b011;
    localparam PL_E_INSTR_DECODED       = 3'b100;
    localparam PL_E_REGFILE_READ_PENDING= 3'b101;
    localparam PL_E_REGFILE_READ        = 3'b110;
    localparam PL_E_EXEC_PENDING        = 3'b111;
    logic [2:0] pipeline_entry_status[0:PIPELINE_SIZE-1];

    logic [31:0] pipeline_instr_addr[0:PIPELINE_SIZE-1];
    logic [31:0] pipeline_instr[0:PIPELINE_SIZE-1];
    logic [7:0] pipeline_op_type[0:PIPELINE_SIZE-1];
    logic [4:0] pipeline_op_rd[0:PIPELINE_SIZE-1];
    logic [4:0] pipeline_op_rs1[0:PIPELINE_SIZE-1];
    logic [4:0] pipeline_op_rs2[0:PIPELINE_SIZE-1];
    logic [31:0] pipeline_op_imm[0:PIPELINE_SIZE-1];
    logic [31:0] pipeline_rs1[0:PIPELINE_SIZE-1];
    logic [31:0] pipeline_rs2[0:PIPELINE_SIZE-1];
    logic pipeline_trap[0:PIPELINE_SIZE-1];

    integer i;
    logic [PIPELINE_BITS-1:0] fetch_pending_entry, decode_pending_entry, regfile_read_pending_entry;
    logic [PIPELINE_BITS-1:0] decode_ptr, next_decode_ptr, regfile_read_ptr, next_regfile_read_ptr;
    logic [31:0] pipeline_trap_mcause, pipeline_trap_mepc, pipeline_trap_mtval;
    logic [31:0] next_fetch_address_plus_2, next_fetch_address_plus_4;

    always_comb begin
        next_pipeline_rd_ptr = pipeline_rd_ptr + 1;
        next_pipeline_wr_ptr = pipeline_wr_ptr + 1;

        next_fetch_address_plus_2 = fetch_address + 2;
        next_fetch_address_plus_4 = fetch_address + 4;

        next_decode_ptr = decode_ptr + 1;
        next_regfile_read_ptr = regfile_read_ptr + 1;
    end

    // Cache
    localparam CACHE_BITS = 5;
    localparam CACHE_SIZE = 2 ** CACHE_BITS;
    (* syn_ramstyle="auto" *)
    logic [31:0] i_cache_instr[0:CACHE_SIZE-1];
    (* syn_ramstyle="auto" *)
    logic [31:0] i_cache_addr[0:CACHE_SIZE-1];
    logic [CACHE_SIZE-1:0] i_cache_compressed;
    // Decoder cache
    logic [6:0] i_cache_decoder_op_type[0:CACHE_SIZE-1];
    logic [4:0] i_cache_decoder_op_rd[0:CACHE_SIZE-1];
    logic [4:0] i_cache_decoder_op_rs1[0:CACHE_SIZE-1];
    logic [4:0] i_cache_decoder_op_rs2[0:CACHE_SIZE-1];
    logic [31:0] i_cache_decoder_imm[0:CACHE_SIZE-1];
    logic [CACHE_SIZE-1:0] i_cache_decoder_load_rs1_rs2;
    logic [CACHE_SIZE-1:0] i_cache_has_decoded;

    logic [CACHE_BITS-1:0] i_cache_index, o_cache_index, d_cache_index, reset_cache_index;
    assign i_cache_index = fetch_address[CACHE_BITS:1];
    assign o_cache_index = core_addr_o[CACHE_BITS:1];

    //==================================================================================================================
    // The reset task
    //==================================================================================================================
    // We need to stay minimum 100μs in reset for the benefit of the SDRAM. We wait 200μs.
    localparam RESET_CLKS = 200000 / CLK_PERIOD_NS;
    // Number of clock periods that we stay in the reset state
    logic [15:0] reset_clks = 0;
    localparam RESET_STATE_ACTIVE   = 1'b0;
    localparam RESET_STATE_CACHE    = 1'b1;
    logic reset_state_m = RESET_STATE_ACTIVE;

    task reset_task;
        if (reset_state_m == RESET_STATE_ACTIVE) begin
            reset_clks <= reset_clks + 16'h1;

            case (reset_clks)
                0: begin
                    if (pll_locked) begin
`ifdef D_CORE
                        $display ($time, " CORE: Reset start.");
`endif
                        // Reset your variables
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        {decoder_stb_o, decoder_cyc_o} <= 2'b00;
                        {regfile_stb_read_o, regfile_cyc_read_o} <= 2'b00;
                        {regfile_stb_write_o, regfile_cyc_write_o} <= 2'b00;
                        {exec_stb_o, exec_cyc_o} <= 2'b00;

                        writeback_op_rd <= 0;

                        flush_pipeline_task (1'b0);
                        pipeline_trap_mcause <= 0;
                        execute_trap <= 0;

                        reset_cache_index <= 0;
                        reset_state_m <= RESET_STATE_CACHE;
                    end else begin
                        // Back to zero to wait for PLL lock
                        reset_clks <= 0;
                    end
                end

                // Set the case value below to configure the duration of the reset assertion.
                // We must account for the slowest clock.
                40: begin
                    // Reset is complete
                    reset <= 1'b0;
`ifdef D_CORE
                    $display ($time, " CORE: Reset complete.");
`endif
                    // Wait for the RAM to initialize (SDRAM 200μs)
                end

                RESET_CLKS: begin
`ifdef D_CORE
                    $display ($time, " CORE: Starting execution @[%h]...", `ROM_BEGIN_ADDR);
`endif
                    fetch_address <= `ROM_BEGIN_ADDR;
`ifdef D_STATS_FILE
                    stats_start_execution_time <= $time;
                    stats_prev_end_execution_time <= $time;
`endif

                    cpu_state_m <= STATE_RUNNING;
                end
            endcase
        end else if (reset_state_m == RESET_STATE_CACHE) begin
            i_cache_addr[reset_cache_index] <= `INVALID_ADDR;
            reset_cache_index <= reset_cache_index + 1;

            if (reset_cache_index == CACHE_SIZE - 1) begin
                i_cache_compressed <= 0;
                i_cache_has_decoded <= 0;
                reset_state_m <= RESET_STATE_ACTIVE;
            end
        end
    endtask

    //==================================================================================================================
    // Fetch instruction task
    //==================================================================================================================
    task fetch_instruction_task;
        // Add a new entry to the pipeline
        pipeline_instr_addr[pipeline_wr_ptr] <= fetch_address;
        pipeline_wr_ptr <= next_pipeline_wr_ptr;

        if (fetch_address[0]) begin
            // This trap cannot overwrite an exiting trap since it is the earliest occurence in the pipeline.
            if (~|pipeline_trap_mcause) begin
`ifdef D_CORE
                $display ($time, " CORE:    [%h] Fetch address misaligned @[%h]. Stall the pipeline.",
                        pipeline_wr_ptr, fetch_address);
`endif
                pipeline_trap_task (pipeline_wr_ptr, 1 << `EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED, fetch_address, 0);
            end else begin
`ifdef D_CORE
                $display ($time, " CORE:        -- Instruction address misaligned %h; ignoring (have trap already). --",
                            fetch_address);
`endif
            end
        end else if (i_cache_addr[i_cache_index] == fetch_address) begin
            if (i_cache_has_decoded[i_cache_index]) begin
                if (i_cache_decoder_load_rs1_rs2[i_cache_index]) begin
                    pipeline_entry_status[pipeline_wr_ptr] <= PL_E_INSTR_DECODED;
`ifdef D_CORE_FINE
                    $display ($time, " CORE:    [%h] Cache hit @[%h] -> PL_E_INSTR_DECODED.", pipeline_wr_ptr,
                                fetch_address);
`endif
                end else begin // No need to read RS1 and RS2
                    pipeline_entry_status[pipeline_wr_ptr] <= PL_E_REGFILE_READ;
`ifdef D_CORE_FINE
                    $display ($time, " CORE:    [%h] Cache hit @[%h] -> PL_E_REGFILE_READ.", pipeline_wr_ptr,
                                fetch_address);
`endif
                end
            end else begin
                pipeline_entry_status[pipeline_wr_ptr] <= PL_E_INSTR_FETCHED;
            end

            pipeline_instr[pipeline_wr_ptr] <= i_cache_instr[i_cache_index];
            pipeline_op_type[pipeline_wr_ptr] <= i_cache_decoder_op_type[i_cache_index];
            pipeline_op_rd[pipeline_wr_ptr] <= i_cache_decoder_op_rd[i_cache_index];
            pipeline_op_rs1[pipeline_wr_ptr] <= i_cache_decoder_op_rs1[i_cache_index];
            pipeline_op_rs2[pipeline_wr_ptr] <= i_cache_decoder_op_rs2[i_cache_index];
            pipeline_op_imm[pipeline_wr_ptr] <= i_cache_decoder_imm[i_cache_index];

            // Calculate the next fetch address
            fetch_address <= i_cache_compressed[i_cache_index] ? next_fetch_address_plus_2 : next_fetch_address_plus_4;
            // Set the cache LED
            `ifdef BOARD_BLUE_WHALE led_a[0] <= 1'b1;`endif

`ifdef ENABLE_HPM_COUNTERS
            incr_event_counters_o[`EVENT_I_CACHE_HIT] <= 1'b1;
`endif
        end else begin
            pipeline_entry_status[pipeline_wr_ptr] <= PL_E_INSTR_FETCH_PENDING;

            core_addr_o <= fetch_address;
            core_we_o <= 1'b0;
            core_sel_o <= 4'b1111;
            {core_stb_o, core_cyc_o} <= 2'b11;

            fetch_pending_entry <= pipeline_wr_ptr;

            // Fetch LED on
            led[0] <= 1'b1;
            // Clear the cache LED
            `ifdef BOARD_BLUE_WHALE led_a[0] <= 1'b0;`endif
`ifdef D_CORE_FINE
            $display ($time, " CORE:    [%h] Fetch @[%h] -> PL_E_INSTR_FETCH_PENDING.", pipeline_wr_ptr, fetch_address);
`endif
        end
    endtask

    //==================================================================================================================
    // Decode instruction task
    //==================================================================================================================
    task decode_instruction_task;
        if (pipeline_entry_status[decode_ptr] == PL_E_INSTR_FETCHED) begin
            pipeline_entry_status[decode_ptr] <= PL_E_INSTR_DECODE_PENDING;

            decoder_instruction_o <= pipeline_instr[decode_ptr];
            {decoder_stb_o, decoder_cyc_o} <= 2'b11;

            decode_pending_entry <= decode_ptr;

            // Decode LED on
            led[1] <= 1'b1;
            `ifdef BOARD_BLUE_WHALE led_a[1] <= 1'b1;`endif
`ifdef D_CORE_FINE
            $display ($time, " CORE:    [%h] Decode %h -> PL_E_INSTR_DECODE_PENDING.", decode_ptr,
                        pipeline_instr[decode_ptr]);
`endif
            d_cache_index <= pipeline_instr_addr[decode_ptr][CACHE_BITS:1];
            decode_ptr <= next_decode_ptr;
        end else if (pipeline_entry_status[decode_ptr] >= PL_E_INSTR_DECODED) begin
            // Skip this entry (instruction was found in the decoder cache).
            decode_ptr <= next_decode_ptr;
        end
    endtask

    //==================================================================================================================
    // Regfile read request
    //==================================================================================================================
    task regfile_read_task;
        if (pipeline_entry_status[regfile_read_ptr] == PL_E_INSTR_DECODED) begin
            pipeline_entry_status[regfile_read_ptr] <= PL_E_REGFILE_READ_PENDING;

            regfile_op_rs1_o <= pipeline_op_rs1[regfile_read_ptr];
            regfile_op_rs2_o <= pipeline_op_rs2[regfile_read_ptr];
            {regfile_stb_read_o, regfile_cyc_read_o} <= 2'b11;

            regfile_read_pending_entry <= regfile_read_ptr;

            // Regfile LED on
            led[2] <= 1'b1;
            `ifdef BOARD_BLUE_WHALE led_a[2] <= 1'b1;`endif
`ifdef D_CORE_FINE
            $display ($time, " CORE:    [%h] Regfile read rs1x%0d, rs2x%0d -> PL_E_REGFILE_READ_PENDING.",
                                regfile_read_ptr, pipeline_op_rs1[regfile_read_ptr], pipeline_op_rs2[regfile_read_ptr]);
`endif
            regfile_read_ptr <= next_regfile_read_ptr;
        end else if (pipeline_entry_status[regfile_read_ptr] >= PL_E_REGFILE_READ) begin
            // Skip this entry (instruction did not need loading of registers)
            regfile_read_ptr <= next_regfile_read_ptr;
        end
    endtask

    //==================================================================================================================
    // Exec task
    //==================================================================================================================
    task exec_task;
        pipeline_entry_status[pipeline_rd_ptr] <= PL_E_EXEC_PENDING;

        exec_instr_addr_o <= pipeline_instr_addr[pipeline_rd_ptr];
        exec_instr_o <= pipeline_instr[pipeline_rd_ptr];
        exec_instr_is_compressed_o <= pipeline_instr[pipeline_rd_ptr][1:0] != 2'b11;
        exec_op_type_o <= pipeline_op_type[pipeline_rd_ptr];
        exec_op_rd_o <= pipeline_op_rd[pipeline_rd_ptr];
        exec_op_rs1_o <= pipeline_op_rs1[pipeline_rd_ptr];
        exec_op_rs2_o <= pipeline_op_rs2[pipeline_rd_ptr];
        exec_op_imm_o <= pipeline_op_imm[pipeline_rd_ptr];
        /*
         * The writeback is handled also just before executing the next instruction. This is because
         * if a regfile read completed in the same cycle as the execution of the instruction that caused the
         * writeback there was no opportunity to update the register with the writeback value.
         */
        exec_rs1_o <= writeback_op_rd == pipeline_op_rs1[pipeline_rd_ptr] ?
                                                                    writeback_rd : pipeline_rs1[pipeline_rd_ptr];
        exec_rs2_o <= writeback_op_rd == pipeline_op_rs2[pipeline_rd_ptr] ?
                                                                    writeback_rd : pipeline_rs2[pipeline_rd_ptr];

        writeback_op_rd <= 0;
        writeback_rd <= 0;
        {exec_stb_o, exec_cyc_o} <= 2'b11;

        // Exec LED on
        led[3] <= 1'b1;
        `ifdef BOARD_BLUE_WHALE led_a[3] <= 1'b1;`endif
        `ifdef BOARD_BLUE_WHALE led_a[11:5] <= instr_op_type;`endif

`ifdef D_CORE_FINE
        $display ($time, " CORE:    [%h] Execute instruction @[%h] -> PL_E_EXEC_PENDING.", entry, instr_addr);
`endif
`ifdef D_STATS_FILE
        stats_start_execution_time <= $time;
`endif
    endtask

    //==================================================================================================================
    // Flush the pipeline (and optionally stall it)
    //==================================================================================================================
    task flush_pipeline_task (input stall);
        pipeline_stall <= stall;

        // Reset the pipeline
        pipeline_rd_ptr <= 0;
        pipeline_wr_ptr <= 0;

        // Clear the status of each entry. When an instruction fetch, decode, regfile read complete we check the
        // pending status of the corresponding pipeline entry. If the status is not PL_E_INSTR_FETCH_PENDING,
        // PL_E_INSTR_DECODE_PENDING or PL_E_REGFILE_READ_PENDING respectively it means that the pipeline was flushed
        // while these operations were pending.
        for (i=0; i<PIPELINE_SIZE; i = i + 1) begin
            pipeline_entry_status[i] <= PL_E_EMPTY;
            pipeline_op_rs1[i] <= 0;
            pipeline_op_rs2[i] <= 0;
            pipeline_trap[i] <= 1'b0;
        end

        decode_ptr <= 0;
        regfile_read_ptr <= 0;
`ifdef D_CORE_FINE
        $display ($time, " CORE:        Pipeline flushed; stall: %h.", stall);
`endif
    endtask

    //==================================================================================================================
    // Store trap data if an exeption occurs in the pipeline (EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED,
    // EX_CODE_ILLEGAL_INSTRUCTION, EX_CODE_INSTRUCTION_ACCESS_FAULT). The pipeline is frozen and the current entry
    // is marked as "ready for execution". We let the instructions in the pipeline execute normally until the pipeline
    // entry is encountered and then we handle the exception.
    //==================================================================================================================
    task pipeline_trap_task (input [PIPELINE_BITS-1:0] entry, input [31:0] mcause, input [31:0] mepc,
                                input [31:0] mtval);
        // Make this entry "ready for execution"
        pipeline_entry_status[entry] <= PL_E_REGFILE_READ;
        pipeline_trap[entry] <= 1'b1;

        // Store trap cause and related values.
        pipeline_trap_mcause <= mcause;
        pipeline_trap_mepc <= mepc;
        pipeline_trap_mtval <= mtval;
        // Stall the pipeline
        pipeline_stall <= 1'b1;
    endtask

    //==================================================================================================================
    // Handle interrupts and exceptions
    //==================================================================================================================
    task enter_trap_task;
        // Flush the pipeline and stall it.
        flush_pipeline_task (1'b1);

        cpu_state_m <= STATE_TRAP;
        trap_state_m <= TRAP_STATE_START;
    endtask

    //==================================================================================================================
    // The task that is setting up the trap in the machine CSR registers
    //==================================================================================================================
    task trap_task;
        (* parallel_case, full_case *)
        case (trap_state_m)
            TRAP_STATE_START: begin
                // If a transaction is pending (an instruction is read) wait for it to complete.
                // The pipeline was flushed so the result is ignored.
                if (core_cyc_o & core_stb_o & (core_ack_i | core_err_i)) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;
                    // Fetch instruction LED off
                    led[0] <= 1'b0;
                end else if (~core_cyc_o & ~core_stb_o & ~core_ack_i & ~core_err_i) begin
`ifdef D_CORE_FINE
                    $display ($time, " CORE:            Enter trap task; mcause = %h; mepc = %h; mtval: = %h.",
                                pipeline_trap_mcause, pipeline_trap_mepc, pipeline_trap_mtval);
`endif
                    led[6] <= 1'b1;
                    `ifdef BOARD_BLUE_WHALE led_a[13] <= ~pipeline_trap_mcause[31];`endif
                    `ifdef BOARD_BLUE_WHALE led_a[14] <= pipeline_trap_mcause[31];`endif

                    // Write the mepc CSR register
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MEPC;
                    core_data_o <= pipeline_trap_mepc;
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    trap_state_m <= TRAP_WRITE_MEPC_READY;
                end
            end

            TRAP_WRITE_MEPC_READY: begin
                // mepc write complete
                if (core_cyc_o & core_stb_o & core_ack_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    // For exceptions write mtval; for interrupts there is no need to write mtval.
                    if (pipeline_trap_mcause[31]) trap_state_m <= TRAP_STATE_WRITE_MCAUSE;
                    else trap_state_m <= TRAP_STATE_WRITE_MTVAL;
                end else if (core_cyc_o & core_stb_o & core_err_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    trap_state_m <= TRAP_STATE_ERROR;
                end
            end

            TRAP_STATE_WRITE_MTVAL: begin
                // Write the mtval CSR register
                core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MTVAL;
                core_data_o <= pipeline_trap_mtval;

                core_we_o <= 1'b1;
                core_sel_o <= 4'b1111;
                {core_stb_o, core_cyc_o} <= 2'b11;

                trap_state_m <= TRAP_STATE_WRITE_MTVAL_READY;
            end

            TRAP_STATE_WRITE_MTVAL_READY: begin
                // mtval write complete
                if (core_cyc_o & core_stb_o & core_ack_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    trap_state_m <= TRAP_STATE_WRITE_MCAUSE;
                end else if (core_cyc_o & core_stb_o & core_err_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    trap_state_m <= TRAP_STATE_ERROR;
                end
            end

            TRAP_STATE_WRITE_MCAUSE: begin
                // Write the mcause CSR register
                core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MCAUSE;
                core_data_o <= to_mcause_code(pipeline_trap_mcause);

                core_we_o <= 1'b1;
                core_sel_o <= 4'b1111;
                {core_stb_o, core_cyc_o} <= 2'b11;

                trap_state_m <= TRAP_STATE_WRITE_MCAUSE_READY;
            end

            TRAP_STATE_WRITE_MCAUSE_READY: begin
                // mcause write complete
                if (core_cyc_o & core_stb_o & core_ack_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    trap_state_m <= TRAP_STATE_ENTER_TRAP;
                end else if (core_cyc_o & core_stb_o & core_err_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;

                    trap_state_m <= TRAP_STATE_ERROR;
                end
            end

            TRAP_STATE_ENTER_TRAP: begin
                // Read the trap address
                core_addr_o <= `CSR_BEGIN_ADDR + `CSR_ENTER_TRAP;
                core_we_o <= 1'b0;
                core_sel_o <= 4'b1111;
                {core_stb_o, core_cyc_o} <= 2'b11;

                trap_state_m <= TRAP_STATE_ENTER_TRAP_READY;
            end

            TRAP_STATE_ENTER_TRAP_READY: begin
                if (core_cyc_o & core_stb_o & core_ack_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;
                    if (core_data_i[1]) begin
                        if (pipeline_trap_mcause[31]) begin
`ifdef D_CORE
                            $display ($time, " CORE:            Interrupt ignored: mtvec not set.");
`endif
                        end else begin
`ifdef D_CORE
                            $display ($time, " CORE:    --- Halting CPU: mtvec not set for exception: %h. ---",
                                        to_mcause_code(pipeline_trap_mcause));
`endif
                            // The CPU is halted with the mcause that was set earlier.
                            // Note that tests.sh rely on the fact that failed tests raise EX_CODE_BREAKPOINT and that
                            // in SIMULATION mode CPU should halt.
                            cpu_state_m <= STATE_HALTED;
                        end
                    end else begin
`ifdef D_CORE_FINE
                        $display ($time, " CORE:    Executing trap routine @[%h].", core_data_i);
`endif

                        execute_trap <= execute_trap + 1;
                    end

                    trap_state_m <= TRAP_STATE_FETCH;
                end else if (core_cyc_o & core_stb_o & core_err_i) begin
                    {core_stb_o, core_cyc_o} <= 2'b00;
                    trap_state_m <= TRAP_STATE_ERROR;
                end
            end

            TRAP_STATE_FETCH: begin
                pipeline_trap_mcause <= 0;

                fetch_address <= core_data_i[1] ? pipeline_trap_mepc : core_data_i;
                // Restart the pipeline
                pipeline_stall <= 1'b0;
                cpu_state_m <= STATE_RUNNING;
            end

            TRAP_STATE_ERROR: begin
                // This cannot happen (r/w to basic CSR registers), but the code is here for completeness.
`ifdef D_CORE
                $display ($time, " CORE:    --- Halting CPU: CSR error. ---");
`endif
                // A CSR error occured
                pipeline_trap_mcause <= 1 << `EX_CODE_ILLEGAL_INSTRUCTION;
                pipeline_trap_mepc <= 0;
                pipeline_trap_mtval <= core_addr_o;
                cpu_state_m <= STATE_HALTED;
            end

            default: begin
                // Invalid state machine
                trap_state_m <= TRAP_STATE_ERROR;
            end
        endcase
    endtask

    //==================================================================================================================
    // The running task
    //==================================================================================================================
    task running_task;
        // ------------------------------ Handle instruction read transactions -----------------------------------------
        if (core_stb_o & core_cyc_o & core_ack_i) begin
            {core_stb_o, core_cyc_o} <= 2'b00;
            // Fetch instruction LED off
            led[0] <= 1'b0;

            // Write the instruction into the cache.
            i_cache_addr[o_cache_index] <= core_addr_o;
            i_cache_instr[o_cache_index] <= core_data_i;
            i_cache_compressed[o_cache_index] <= ~core_data_tag_i;
            i_cache_has_decoded[o_cache_index] <= 1'b0;

            if (pipeline_entry_status[fetch_pending_entry] == PL_E_INSTR_FETCH_PENDING) begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Fetch complete @[%h] : %h.", fetch_pending_entry, core_addr_o,
                            core_data_i);
`endif
                pipeline_instr[fetch_pending_entry] <= core_data_i;
                pipeline_entry_status[fetch_pending_entry] <= PL_E_INSTR_FETCHED;

                // Setup the next fetch
                fetch_address <= core_data_tag_i ? next_fetch_address_plus_4 : next_fetch_address_plus_2;
            end else begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Ignoring fetch complete.", fetch_pending_entry);
`endif
            end
        end else if (core_stb_o & core_cyc_o & core_err_i) begin
            {core_stb_o, core_cyc_o} <= 2'b00;
            // Fetch instruction LED off
            led[0] <= 1'b0;

`ifdef D_CORE
            $display ($time, " CORE:        Illegal instruction address @[%h].", core_addr_o);
`endif
            // If a pipeline trap occurs during fetch we do not overwrite an existing trap (the instruction is latest).
            if (~|pipeline_trap_mcause) begin
`ifdef D_CORE
                $display ($time, " CORE:        --- Invalid instruction address %h. Stall the pipeline. ---",
                            core_addr_o);
`endif
                pipeline_trap_task (fetch_pending_entry, 1 << `EX_CODE_INSTRUCTION_ACCESS_FAULT, core_addr_o, 0);
            end else begin
`ifdef D_CORE
                $display ($time, " CORE:        --- Invalid instruction address %h; ignoring (have trap already). ---",
                                core_addr_o);
`endif
            end
        end else if (~(core_stb_o & core_cyc_o) & ~pipeline_stall & ~pipeline_full) begin
            fetch_instruction_task;
        end

        // ------------------------------------ Handle decoder transactions --------------------------------------------
        if (decoder_stb_o & decoder_cyc_o & decoder_ack_i) begin
            {decoder_stb_o, decoder_cyc_o} <= 2'b00;
            // Decode instruction LED off
            led[1] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[1] <= 1'b0;`endif

            // Cache the decoder data
            i_cache_has_decoded[d_cache_index] <= 1'b1;
            i_cache_decoder_op_type[d_cache_index] <= decoder_op_type_i;
            i_cache_decoder_op_rd[d_cache_index] <= decoder_op_rd_i;
            i_cache_decoder_op_rs1[d_cache_index] <= decoder_op_rs1_i;
            i_cache_decoder_op_rs2[d_cache_index] <= decoder_op_rs2_i;
            i_cache_decoder_imm[d_cache_index] <= decoder_op_imm_i;
            i_cache_decoder_load_rs1_rs2[d_cache_index] <= decoder_load_rs1_rs2_i;

            if (pipeline_entry_status[decode_pending_entry] == PL_E_INSTR_DECODE_PENDING) begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Decode complete.", decode_pending_entry);
`endif
                pipeline_op_type[decode_pending_entry] <= decoder_op_type_i;
                pipeline_op_rd[decode_pending_entry] <= decoder_op_rd_i;
                pipeline_op_rs1[decode_pending_entry] <= decoder_op_rs1_i;
                pipeline_op_rs2[decode_pending_entry] <= decoder_op_rs2_i;
                pipeline_op_imm[decode_pending_entry] <= decoder_op_imm_i;

                if (decoder_load_rs1_rs2_i) begin
                    pipeline_entry_status[decode_pending_entry] <= PL_E_INSTR_DECODED;
                end else begin // No need to read RS1 and RS2
                    pipeline_entry_status[decode_pending_entry] <= PL_E_REGFILE_READ;
                end
            end else begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Ignoring decode complete.", decode_pending_entry);
`endif
            end
        end else if (decoder_stb_o & decoder_cyc_o & decoder_err_i) begin
            {decoder_stb_o, decoder_cyc_o} <= 2'b00;
            // Decode instruction LED off
            led[1] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[1] <= 1'b0;`endif
`ifdef D_CORE
            $display ($time, " CORE:        --- Illegal instruction %h @[%h]. Stall the pipeline. ---",
                        decoder_instruction_o, pipeline_instr_addr[decode_pending_entry]);
`endif
            // This exception may overwrite a pipeline trap detected during fetch since the instruction is an older one.
            pipeline_trap_task (decode_pending_entry, 1 << `EX_CODE_ILLEGAL_INSTRUCTION,
                                pipeline_instr_addr[decode_pending_entry], decoder_instruction_o);
        end else if (~(decoder_stb_o & decoder_cyc_o)) begin
            decode_instruction_task;
        end

        // ------------------------------------ Handle regfile transactions --------------------------------------------
        if (regfile_stb_read_o & regfile_cyc_read_o & regfile_ack_read_i) begin
            {regfile_stb_read_o, regfile_cyc_read_o} <= 2'b00;
            // Regfile LED off
            led[2] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[2] <= 1'b0;`endif

            if (pipeline_entry_status[regfile_read_pending_entry] == PL_E_REGFILE_READ_PENDING) begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Regfile read complete rs1x%0d: %h, rs2x%0d: %h",
                            regfile_read_pending_entry, regfile_op_rs1_o, regfile_reg_rs1_i,
                            regfile_op_rs2_o, regfile_reg_rs2_i);
`endif
                pipeline_entry_status[regfile_read_pending_entry] <= PL_E_REGFILE_READ;

                pipeline_rs1[regfile_read_pending_entry] <= regfile_reg_rs1_i;
                pipeline_rs2[regfile_read_pending_entry] <= regfile_reg_rs2_i;
            end else begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Ignoring regfile read complete.", regfile_read_pending_entry);
`endif
            end
        end else if (~(regfile_stb_read_o & regfile_cyc_read_o)) begin
            regfile_read_task;
        end

        // -------------------------------------- Handle exec transactions ---------------------------------------------
        if (exec_stb_o & exec_cyc_o & exec_ack_i) begin
            {exec_stb_o, exec_cyc_o} <= 2'b00;
            // Exec LED off
            led[3] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[3] <= 1'b0;`endif

`ifdef D_STATS_FILE
            stats_prev_end_execution_time <= $time;
            /*
             * 1. Timestamp of the start of the instruction.
             * 2. The type of instruction from instructions.svh
             * 3. The duration of the instruction execution.
             * 4. The duration between the end of the previous instruction execution and the begining of this
             *      instruction execution.
             */
            $fdisplay (fd, "%0d, %0d, %0d, %0d", stats_start_execution_time + CLK_PERIOD_NS, exec_op_type_o,
                        ($time - stats_start_execution_time)/CLK_PERIOD_NS,
                        (stats_start_execution_time - stats_prev_end_execution_time)/CLK_PERIOD_NS);
`endif

            // Invalidate the pipeline entry
            pipeline_entry_status[pipeline_rd_ptr] <= PL_E_EMPTY;
            pipeline_op_rs1[pipeline_rd_ptr] <= 0;
            pipeline_op_rs2[pipeline_rd_ptr] <= 0;

            if (|exec_op_rd_o) begin
                // Write the destination register to the regfile
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Execution complete. Writeback rdx%0d = %h.", pipeline_rd_ptr,
                                exec_op_rd_o, exec_rd_i);
`endif
                regfile_op_rd_o <= exec_op_rd_o;
                regfile_reg_rd_o <= exec_rd_i;

                {regfile_stb_write_o, regfile_cyc_write_o} <= 2'b11;
                led[4] <= 1'b1;
                `ifdef BOARD_BLUE_WHALE led_a[4] <= 1'b1;`endif

                // Store the writeback rd register and register value so that when the pending regfile read completes
                // we update can the rs1 or rs2 with the value of the writeback register.
                writeback_op_rd <= exec_op_rd_o;
                writeback_rd <= exec_rd_i;

                for (i=0; i<PIPELINE_SIZE; i = i + 1) begin
                    /*
                     * If the status < PL_E_INSTR_DECODE_PENDING rs1 and rs2 are not yet known.
                     * If the status == PL_E_INSTR_DECODED, the correct rs1 and rs2 will read from regfile.
                     * If the status == PL_E_REGFILE_READ_PENDING the registers will be updated upon completion
                     * with the saved writeback_op_rd and writeback_rd... with one exception: the regfile read
                     * completed in the the current clock cycle so the status is not yet reflected in
                     * pipeline_entry_status (it is still PL_E_REGFILE_READ_PENDING).
                     * If the status == PL_E_REGFILE_READ update the registers. Note that there could be two
                     * entries with a status of PL_E_REGFILE_READ if an instruction takes a relatively long time to
                     * execute (eg. memory access).
                     *
                     * The pipeline entry status is not checked here since it won't give any added benefit.
                     */
                    if (pipeline_op_rs1[i] == exec_op_rd_o) pipeline_rs1[i] <= exec_rd_i;
                    if (pipeline_op_rs2[i] == exec_op_rd_o) pipeline_rs2[i] <= exec_rd_i;
                end
            end else begin
`ifdef D_CORE_FINE
                $display ($time, " CORE:    [%h] Execution complete.", pipeline_rd_ptr);
`endif
            end

            incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;

            case (1'b1)
                exec_mret_i: begin
                    if (execute_trap == 1) begin
                        led[6] <= 1'b0;
                        `ifdef BOARD_BLUE_WHALE led_a[13] <= 1'b0;`endif
                        `ifdef BOARD_BLUE_WHALE led_a[14] <= 1'b0;`endif
                    end
                    execute_trap <= execute_trap - 1;

                    // Flush the pipeline
                    flush_pipeline_task (1'b0);
                    pipeline_trap_mcause <= 0;

                    fetch_address <= exec_next_addr_i;
                end

                // Handle interrupts in the order of priority
                io_interrupts_i[`IRQ_EXTERNAL]: begin
                    pipeline_trap_mcause <= 32'h8000_0000 | 1 << `IRQ_EXTERNAL;
                    pipeline_trap_mepc <= exec_next_addr_i;
                    pipeline_trap_mtval <= 0;
                    enter_trap_task;
                end

                io_interrupts_i[`IRQ_TIMER]: begin
                    pipeline_trap_mcause <= 32'h8000_0000 | 1 << `IRQ_TIMER;
                    pipeline_trap_mepc <= exec_next_addr_i;
                    pipeline_trap_mtval <= 0;
                    enter_trap_task;
                end

                exec_jmp_i: begin
                    led[5] <= 1'b1;
                    `ifdef BOARD_BLUE_WHALE led_a[12] <= 1'b1;`endif
                    // Flush the pipeline
                    flush_pipeline_task (1'b0);
                    pipeline_trap_mcause <= 0;

                    fetch_address <= exec_next_addr_i;
`ifdef SIMULATION
                    if (exec_next_addr_i == exec_instr_addr_o) begin
                        looping_instruction <= 1'b1;
                        cpu_state_m <= STATE_HALTED;
                    end
`endif // SIMULATION
                end

                default: begin
                    // The program execution continues at exec_next_addr_i which is an incremental address (+2/+4)
                    led[5] <= 1'b0;
                    `ifdef BOARD_BLUE_WHALE led_a[12] <= 1'b0;`endif
                    // Advance in the pipeline
                    pipeline_rd_ptr <= next_pipeline_rd_ptr;
                end
            endcase
        end else if (exec_stb_o & exec_cyc_o & exec_err_i) begin
            {exec_stb_o, exec_cyc_o} <= 2'b00;
            // Exec LED off
            led[3] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[3] <= 1'b0;`endif
`ifdef D_STATS_FILE
            stats_prev_end_execution_time <= $time;
            $fdisplay (fd, "%0d, %0d, %0d, %0d", stats_start_execution_time + CLK_PERIOD_NS, exec_op_type_o,
                        ($time - stats_start_execution_time)/CLK_PERIOD_NS,
                        (stats_start_execution_time - stats_prev_end_execution_time)/CLK_PERIOD_NS);
`endif

`ifdef D_CORE_FINE
            $display ($time, " CORE:    [%h] Execution exception: %h.", pipeline_rd_ptr, exec_trap_mcause_i);
`endif
            // If multiple exceptions were raised, process the highest priority one (see Table 8.7)
            case (1'b1)
                exec_trap_mcause_i[`EX_CODE_INSTRUCTION_ACCESS_FAULT]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_INSTRUCTION_ACCESS_FAULT;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_ILLEGAL_INSTRUCTION]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_ILLEGAL_INSTRUCTION;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_ECALL]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_ECALL;
                end

                exec_trap_mcause_i[`EX_CODE_BREAKPOINT]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_BREAKPOINT;
                end

                exec_trap_mcause_i[`EX_CODE_LOAD_ADDRESS_MISALIGNED]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_LOAD_ADDRESS_MISALIGNED;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_STORE_ADDRESS_MISALIGNED]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_STORE_ADDRESS_MISALIGNED;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_LOAD_ACCESS_FAULT]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_LOAD_ACCESS_FAULT;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                exec_trap_mcause_i[`EX_CODE_STORE_ACCESS_FAULT]: begin
                    pipeline_trap_mcause <= 1 << `EX_CODE_STORE_ACCESS_FAULT;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end

                default: begin
`ifdef D_CORE_FINE
                    $display ($time, " CORE:            Unsupported exception: %h.", exec_next_addr_i);
`endif
                    // Break the execution.
                    pipeline_trap_mcause <= 1 << `EX_CODE_BREAKPOINT;
                    incr_event_counters_o[`EVENT_INSTRET] <= 1'b1;
                end
            endcase

            pipeline_trap_mepc <= exec_instr_addr_o;
            pipeline_trap_mtval <= exec_trap_mtval_i;
            enter_trap_task;
        end else if (~(exec_stb_o & exec_cyc_o) & (pipeline_entry_status[pipeline_rd_ptr] == PL_E_REGFILE_READ)) begin
            if (pipeline_trap[pipeline_rd_ptr]) begin
                /*
                 * Handle the exception that occured earlier in the pipeline (EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED,
                 * EX_CODE_ILLEGAL_INSTRUCTION, EX_CODE_INSTRUCTION_ACCESS_FAULT).
                 */
                enter_trap_task;
            end else begin
                exec_task;
            end
        end

        // ---------------------------------- Handle writeback transactions --------------------------------------------
        if (regfile_stb_write_o & regfile_cyc_write_o & regfile_ack_write_i) begin
            {regfile_stb_write_o, regfile_cyc_write_o} <= 2'b00;

            led[4] <= 1'b0;
            `ifdef BOARD_BLUE_WHALE led_a[4] <= 1'b0;`endif
        end
    endtask

    //==================================================================================================================
    // The CPU state machine
    //==================================================================================================================
    always @(posedge clk) begin
        if (reset_btn) begin
            reset_clks <= 0;
            reset_state_m <= RESET_STATE_ACTIVE;
            reset <= 1'b1;
            led <= 0;
            `ifdef BOARD_BLUE_WHALE led_a <= 16'h0;`endif

            cpu_state_m <= STATE_RESET;
        end else begin
            incr_event_counters_o <= 0;

            (* parallel_case, full_case *)
            case (cpu_state_m)
                STATE_RESET: begin
                    reset_task;
                end

                STATE_RUNNING: begin
                    running_task;
                end

                STATE_TRAP: begin
                    trap_task;
                end

                STATE_HALTED: begin
                    led[7] <= 1'b1;
                    `ifdef BOARD_BLUE_WHALE led_a[15] <= 1'b1;`endif
                end
            endcase
        end
    end

    //==================================================================================================================
    // Convert from mcause bits to mcause codes
    //==================================================================================================================
    function [31:0] to_mcause_code(input [31:0] mcause_bits);
        (* parallel_case, full_case *)
        case (mcause_bits)
            // Interrupts
            32'h8000_0080: to_mcause_code = `IRQ_CODE_TIMER;
            32'h8000_0800: to_mcause_code = `IRQ_CODE_EXTERNAL;
            // Exceptions
            32'h0000_0001: to_mcause_code = `EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED;
            32'h0000_0002: to_mcause_code = `EX_CODE_INSTRUCTION_ACCESS_FAULT;
            32'h0000_0004: to_mcause_code = `EX_CODE_ILLEGAL_INSTRUCTION;
            32'h0000_0008: to_mcause_code = `EX_CODE_BREAKPOINT;
            32'h0000_0010: to_mcause_code = `EX_CODE_LOAD_ADDRESS_MISALIGNED;
            32'h0000_0020: to_mcause_code = `EX_CODE_LOAD_ACCESS_FAULT;
            32'h0000_0040: to_mcause_code = `EX_CODE_STORE_ADDRESS_MISALIGNED;
            32'h0000_0080: to_mcause_code = `EX_CODE_STORE_ACCESS_FAULT;
            32'h0000_0100: to_mcause_code = `EX_CODE_ECALL;
            default: to_mcause_code = 32'h1f; // Undefined. See traps.svh
        endcase
    endfunction

`ifdef SIMULATION
    logic[3:0] finish_simulation;
    logic looping_instruction;
`ifdef D_STATS_FILE
    integer fd;
    integer stats_start_execution_time, stats_prev_end_execution_time;
`endif

    initial begin
        finish_simulation = 4'h2;
        looping_instruction = 1'b0;
`ifdef D_STATS_FILE
        fd = $fopen("out.csv", "w");
`endif
    end

    //==================================================================================================================
    // Convert from mcause bits to mcause string
    //==================================================================================================================
    function string to_mcause_bits_string(input [31:0] mcause_bits);
        (* parallel_case, full_case *)
        case (mcause_bits)
            // Exceptions
            32'h0000_0001: return "EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED";
            32'h0000_0002: return "EX_CODE_INSTRUCTION_ACCESS_FAULT";
            32'h0000_0004: return "EX_CODE_ILLEGAL_INSTRUCTION";
            32'h0000_0008: return "EX_CODE_BREAKPOINT";
            32'h0000_0010: return "EX_CODE_LOAD_ADDRESS_MISALIGNED";
            32'h0000_0020: return "EX_CODE_LOAD_ACCESS_FAULT";
            32'h0000_0040: return "EX_CODE_STORE_ADDRESS_MISALIGNED";
            32'h0000_0080: return "EX_CODE_STORE_ACCESS_FAULT";
            32'h0000_0100: return "EX_CODE_ECALL";
            default: return "Undefined";
        endcase
    endfunction

    //==================================================================================================================
    // Finish the simulation
    //==================================================================================================================
    always @(posedge clk) begin
        if (cpu_state_m == STATE_HALTED) begin
            if (finish_simulation > 0) begin
                finish_simulation <= finish_simulation - 4'h1;
            end else begin
                if (execute_trap > 0) begin
                    if (looping_instruction) begin
                        $display ($time, " CORE: ------- Halt: looping instruction @[%h]; exception: %s --------",
                                exec_instr_addr_o, to_mcause_bits_string(1 << mem_space_m.csr_m.mcause));
                    end else begin
                        $display ($time, " CORE: ------- Halt: executing trap @[%h]. --------",  exec_instr_addr_o);
                    end
                end else begin
`ifdef TEST_MODE
                    if (looping_instruction) begin
                        $display ($time, " CORE: ------- Pass -------");
                    end else if (pipeline_trap_mcause[`EX_CODE_BREAKPOINT]) begin
                        $display ($time, " CORE: !!!! Fail detected by test !!!!");
                    end else begin
                        // Test ended in a trap
                        $display ($time, " CORE: !!!! Fail: Exception: %s !!!!",
                                    to_mcause_bits_string(pipeline_trap_mcause));
                    end
`else
                    if (looping_instruction) begin
                        $display ($time, " CORE: ------------- Halt: looping instruction @[%h]. -------------",
                                    exec_instr_addr_o);
                    end else if (pipeline_trap_mcause[`EX_CODE_BREAKPOINT]) begin
                        $display ($time, " CORE: --------------------- Halt at breakpoint ----------------------");
                    end else begin
                        $display ($time, " CORE: ---------------- Halt due to exception: %s --------------------",
                                    to_mcause_bits_string(pipeline_trap_mcause));
                    end

`ifdef ENABLE_HPM_COUNTERS
                    $display ($time, " CORE: Cycles:                 %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_CYCLE]);
                    $display ($time, " CORE: Instructions retired:   %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_INSTRET]);
                    $display ($time, " CORE: Instructions from ROM:  %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_INSTR_FROM_ROM]);
                    $display ($time, " CORE: Instructions from RAM:  %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_INSTR_FROM_RAM]);
                    $display ($time, " CORE: I-Cache hits:           %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_I_CACHE_HIT]);
                    $display ($time, " CORE: Load from ROM:          %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_LOAD_FROM_ROM]);
                    $display ($time, " CORE: Load from RAM:          %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_LOAD_FROM_RAM]);
                    $display ($time, " CORE: Store to RAM:           %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_STORE_TO_RAM]);
                    $display ($time, " CORE: IO load:                %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_IO_LOAD]);
                    $display ($time, " CORE: IO store:               %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_IO_STORE]);
                    $display ($time, " CORE: CSR load:               %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_CSR_LOAD]);
                    $display ($time, " CORE: CSR store:              %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_CSR_STORE]);
                    $display ($time, " CORE: Timer interrupts:       %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_TIMER_INT]);
                    $display ($time, " CORE: External interrupts:    %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_EXTERNAL_INT]);
`else // ENABLE_HPM_COUNTERS
                    $display ($time, " CORE: Cycles:                 %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_CYCLE]);
                    $display ($time, " CORE: Instructions:           %0d",
                                                                mem_space_m.csr_m.mhpmcounter[`EVENT_INSTRET]);
`endif // ENABLE_HPM_COUNTERS
`endif // TEST_MODE
                end

`ifdef D_STATS_FILE
                $fclose(fd);
`endif
                // Finish the simulation
                $finish(0);
            end
        end
    end
`endif // SIMULATION
endmodule
