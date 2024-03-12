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
 * This module performs tests of the flash and RAM by reading known data from the flash, writing it into RAM
 * and reading it back to perform a checksum. A test for interrupts is also provided.
 *
 * The checksum is not sophisticated to lower the compute needs.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "memory_map.svh"
`include "csr.svh"
`include "io.svh"
`include "traps.svh"

module mem_space_test(
    input logic clk_in,
    output logic [7:0] led,
    input logic [1:0] btn,
    // SPI flash wires
    output logic flash_csn,
`ifdef SIMULATION
    output logic flash_clk,
`endif
    inout logic flash_mosi,
    inout logic flash_miso,
    inout logic flash_wpn,
    inout logic flash_holdn,
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

    // For SPI mode (ENABLE_QPI_MODE not defined) the minimum value is 16, for ENABLE_QPI_MODE the minimum value is 20.
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
`endif
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
    // Flash ports
    logic [31:0] core_addr_o;
    logic [31:0] core_data_i, core_data_o;
    logic [3:0] core_sel_o;
    logic core_we_o, core_stb_o, core_cyc_o, core_ack_i, core_err_i;

    // SDRAM ports
    logic [31:0] data_addr_o;
    logic [31:0] data_data_i, data_data_o;
    logic [3:0] data_sel_o;
    logic data_we_o, data_stb_o, data_cyc_o, data_ack_i, data_err_i;
    logic [2:0] data_addr_tag_w;
    // Event counters
    logic [31:0] incr_event_counters_o;
    // IO interrupt
    logic [31:0] io_interrupts_i;

    mem_space #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) mem_space_m(
    .clk_i              (clk),
    .rst_i              (reset),
    // Wishbone interface for reading instructions
    .core_stb_i         (core_stb_o),
    .core_cyc_i         (core_cyc_o),
    .core_sel_i         (core_sel_o),
    .core_we_i          (core_we_o),
    .core_addr_i        (core_addr_o),
    .core_data_i        (core_data_o),
    .core_ack_o         (core_ack_i),
    .core_err_o         (core_err_i),
    .core_data_o        (core_data_i),
    // Wishbone interface for reading and writing data
    .data_stb_i         (data_stb_o),
    .data_cyc_i         (data_cyc_o),
    .data_sel_i         (data_sel_o),
    .data_we_i          (data_we_o),
    .data_addr_i        (data_addr_o),
    .data_addr_tag_i    (data_addr_tag_w),
    .data_data_i        (data_data_o),
    .data_ack_o         (data_ack_i),
    .data_err_o         (data_err_i),
    .data_data_o        (data_data_i),
    // Device clocks
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
`else
    .led                (led_b),
    // PSRAM signals
    .psram_cen          (psram_cen),
    .psram_wen          (psram_wen),
    .psram_oen          (psram_oen),
    .psram_lbn          (psram_lbn),
    .psram_ubn          (psram_ubn),
    .psram_a            (psram_a),
    .psram_d            (psram_d),
`endif
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
    .flash_holdn        (flash_holdn));

    //==================================================================================================================
    // The test code
    //==================================================================================================================
    // 0: ROM & RAM checksum OK | 1, 2, 3: DEBUG
    localparam [1:0] CHECKSUM_LED = 2'h0;

    //==================================================================================================================
    // Flash
    //==================================================================================================================
    localparam RAM_OFFSET = 24'h00_0000;

    logic done_ram_rd, done_flash_rd, do_next_core_read, do_next_data_read, do_data_write, test_ok;
    // Test error
    localparam [2:0] TEST_ERROR_NONE = 3'h0;
    localparam [2:0] TEST_ERROR_CORE = 3'h1;
    localparam [2:0] TEST_ERROR_FLASH_CHECKSUM = 3'h2;
    localparam [2:0] TEST_ERROR_DATA = 3'h3;
    localparam [2:0] TEST_ERROR_RAM_CHECKSUM = 3'h4;
    localparam [2:0] TEST_ERROR_IRQ = 3'h5;
    logic [2:0] test_error;

    logic [31:0] rd_ram_checksum, RD_RAM_CHECKSUM, rd_flash_checksum, RD_FLASH_CHECKSUM;
    logic [15:0] rd_ram_count, RD_RAM_COUNT, rd_flash_count, RD_FLASH_COUNT;
    logic [2:0] RD_RAM_INCR, RD_FLASH_INCR;
    logic [31:0] data_wr_data, core_rd_address, data_rd_address, data_wr_address;

    task test_mem_task;
        if (start_test) begin
`ifdef D_CORE
            $display($time, " CORE: Test %0d", test_num);
`endif
            do_next_core_read <= 1'b0;
            do_next_data_read <= 1'b0;
            do_data_write <= 1'b0;

            rd_flash_checksum <= 0;
            rd_ram_checksum <= 0;
            rd_flash_count <= 0;
            rd_ram_count <= 0;

            data_rd_address <= `RAM_BEGIN_ADDR + RAM_OFFSET;
            core_rd_address <= `ROM_BEGIN_ADDR;

            data_addr_tag_w <= 0;
            (* parallel_case, full_case *)
            case (test_num)
                0: begin
                    // Read 1 byte from flash, write 1 byte to RAM, read 1 byte from RAM
                    RD_FLASH_COUNT <= 16'h1724;
                    RD_FLASH_INCR <= 3'h1;
                    RD_FLASH_CHECKSUM <= 32'h0000_34dc;
                    core_sel_o <= 4'b0001;

                    RD_RAM_COUNT <= 16'h1724;
                    RD_RAM_INCR <= 3'h1;
                    RD_RAM_CHECKSUM <= 32'h0000_34dc;
                    `ifdef BOARD_BLUE_WHALE led_a <= 16'h0;`endif
                end

                1: begin
                    // Read 2 bytes from flash, write 2 bytes to RAM, read 2 bytes from RAM
                    RD_FLASH_COUNT <= 16'h0b92;
                    RD_FLASH_INCR <= 3'h2;
                    RD_FLASH_CHECKSUM <= 32'h0003_4fc8;
                    core_sel_o <= 4'b0011;

                    RD_RAM_COUNT <= 16'h0b92;
                    RD_RAM_INCR <= 3'h2;
                    RD_RAM_CHECKSUM <= 32'h0003_4fc8;
                end

                2: begin
                    // Read 2 bytes from flash, write 2 bytes to RAM, read 4 bytes from RAM
                    RD_FLASH_COUNT <= 16'h0b92;
                    RD_FLASH_INCR <= 3'h2;
                    RD_FLASH_CHECKSUM <= 32'h0003_4fc8;
                    core_sel_o <= 4'b0011;

                    RD_RAM_COUNT <= 16'h05c9;
                    RD_RAM_INCR <= 3'h4;
                    RD_RAM_CHECKSUM <= 32'hd800_1834;
                end

                3: begin
                    // Read 4 bytes from flash, write 4 bytes to RAM, read 1 byte from RAM
                    RD_FLASH_COUNT <= 16'h05c9;
                    RD_FLASH_INCR <= 3'h4;
                    RD_FLASH_CHECKSUM <= 32'hd800_1834;
                    core_sel_o <= 4'b1111;

                    RD_RAM_COUNT <= 16'h1724;
                    RD_RAM_INCR <= 3'h1;
                    RD_RAM_CHECKSUM <= 32'h0000_34dc;
                end

                4: begin
                    // Read 4 bytes from flash, write 4 bytes to RAM, read 2 bytes from RAM
                    RD_FLASH_COUNT <= 16'h05c9;
                    RD_FLASH_INCR <= 3'h4;
                    RD_FLASH_CHECKSUM <= 32'hd800_1834;
                    core_sel_o <= 4'b1111;

                    RD_RAM_COUNT <= 16'h0b92;
                    RD_RAM_INCR <= 3'h2;
                    RD_RAM_CHECKSUM <= 32'h0003_4fc8;
                end

                5: begin
                    // Read 4 bytes from flash, write 4 bytes to RAM, read 4 bytes from RAM
                    RD_FLASH_COUNT <= 16'h05c9;
                    RD_FLASH_INCR <= 3'h4;
                    RD_FLASH_CHECKSUM <= 32'hd800_1834;
                    core_sel_o <= 4'b1111;

                    RD_RAM_COUNT <= 16'h05c9;
                    RD_RAM_INCR <= 3'h4;
                    RD_RAM_CHECKSUM <= 32'hd800_1834;
                end

                default: begin
                    // Invalid test number
                end
            endcase
            // Start reading from core
            do_next_core_read <= 1'b1;
        end else begin
            // Signals that stay on for only one clock cycle
            do_next_data_read <= 1'b0;
            do_data_write <= 1'b0;
            done_flash_rd <= 1'b0;
            do_next_core_read <= 1'b0;

            if (core_cyc_o & core_stb_o & core_ack_i) begin
                {core_stb_o, core_cyc_o} <= 2'b00;
`ifdef D_CORE_FINE
                $display($time, " CORE: Core data @[%h]: %h", core_addr_o, core_data_i);
`endif
                case (1'b1)
                    RD_FLASH_INCR[0]: begin
                        rd_flash_checksum <= rd_flash_checksum + (rd_flash_checksum ^ core_data_i[7:0]);
                        if (CHECKSUM_LED == 2'h2) begin
                            if (rd_flash_count == 0) led <= core_data_i[7:0];
                        end
                    end

                    RD_FLASH_INCR[1]: begin
                        rd_flash_checksum <= rd_flash_checksum + (rd_flash_checksum ^ core_data_i[15:0]);
                    end

                    RD_FLASH_INCR[2]: begin
                        rd_flash_checksum <= rd_flash_checksum + (rd_flash_checksum ^ core_data_i);
                    end
                endcase

                core_rd_address <= core_rd_address + RD_FLASH_INCR;
                rd_flash_count <= rd_flash_count + 1;
                // Write the flash data to RAM
                data_wr_data <= core_data_i;
                data_wr_address <= `RAM_BEGIN_ADDR + (core_addr_o - `ROM_BEGIN_ADDR) + RAM_OFFSET;
                do_data_write <= 1'b1;
            end else if (core_cyc_o & core_stb_o & core_err_i) begin
                {core_stb_o, core_cyc_o} <= 2'b00;
                test_error <= TEST_ERROR_CORE;
            end else if (do_next_core_read) begin
                core_addr_o <= core_rd_address;
                core_we_o <= 1'b0;
                // core_sel_o was set at the beginning of the test
                {core_stb_o, core_cyc_o} <= 2'b11;
            end else if (done_flash_rd) begin
                if (rd_flash_checksum == RD_FLASH_CHECKSUM) begin
                    if (CHECKSUM_LED == 2'h0) begin
                        led[test_num] <= 1'b1;
                        `ifdef BOARD_BLUE_WHALE led_a[test_num] <= 1'b1;`endif
                    end
                    // Start the reading from RAM
                    do_next_data_read <= 1'b1;
                end else begin
`ifdef D_CORE
                    $display($time, " CORE: Core checksum failed: %h, expected: %h.", rd_flash_checksum,
                                    RD_FLASH_CHECKSUM);
`endif
                    test_error <= TEST_ERROR_FLASH_CHECKSUM;
                end
            end else if (data_cyc_o & data_stb_o & data_ack_i) begin
                // A transaction is complete
                {data_stb_o, data_cyc_o} <= 2'b00;

                if (data_we_o) begin
`ifdef D_CORE_FINE
                    $display($time, " CORE: Data write complete %h -> @[%h]", data_data_o, data_addr_o);
`endif
                    if (rd_flash_count == RD_FLASH_COUNT) begin
                        done_flash_rd <= 1'b1;
                    end else begin
                        do_next_core_read <= 1'b1;
                    end
                end else begin
                    case (1'b1)
                        RD_RAM_INCR[0]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: Data read @[%h]: %h", data_addr_o, data_data_i[7:0]);
`endif
                            rd_ram_checksum <= rd_ram_checksum + (rd_ram_checksum ^ data_data_i[7:0]);
                            if (CHECKSUM_LED == 2'h3) begin
                                if (rd_ram_count == 0) led <= data_data_i[7:0];
                            end
                        end

                        RD_RAM_INCR[1]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: Data read @[%h]: %h", data_addr_o, data_data_i[15:0]);
`endif
                            rd_ram_checksum <= rd_ram_checksum + (rd_ram_checksum ^ data_data_i[15:0]);
                        end

                        RD_RAM_INCR[2]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: Data read @[%h]: %h", data_addr_o, data_data_i);
`endif
                            rd_ram_checksum <= rd_ram_checksum + (rd_ram_checksum ^ data_data_i);
                        end
                    endcase

                    rd_ram_count <= rd_ram_count + 1;
                    if (rd_ram_count == RD_RAM_COUNT - 1) begin
                        done_ram_rd <= 1'b1;
                    end else begin
                        data_rd_address <= data_rd_address + RD_RAM_INCR;
                        do_next_data_read <= 1'b1;
                    end
                end
            end else if (data_cyc_o & data_stb_o & data_err_i) begin
                {data_stb_o, data_cyc_o} <= 2'b00;
                test_error <= TEST_ERROR_DATA;
            end else if (do_next_data_read) begin
`ifdef D_CORE_FINE
                $display($time, " CORE: Reading data @[%h]", data_rd_address);
`endif
                do_next_data_read <= 1'b0;

                data_addr_o <= data_rd_address;
                data_we_o <= 1'b0;
                case (1'b1)
                    RD_RAM_INCR[0]: data_sel_o <= 4'b0001;
                    RD_RAM_INCR[1]: data_sel_o <= 4'b0011;
                    RD_RAM_INCR[2]: data_sel_o <= 4'b1111;
                endcase
                {data_stb_o, data_cyc_o} <= 2'b11;
            end else if (done_ram_rd) begin
                done_ram_rd <= 1'b0;
                if (rd_ram_checksum == RD_RAM_CHECKSUM) begin
`ifdef D_CORE
                    $display($time, " CORE: Core and data checksum OK.");
`endif
                    if (CHECKSUM_LED == 2'h0) begin
                        led[test_num] <= 1'b1;
                        `ifdef BOARD_BLUE_WHALE led_a[test_num + 8] <= 1'b1;`endif
                    end

                    test_ok <= 1'b1;
                end else begin
`ifdef D_CORE
                    $display($time, " CORE: Core checksum failed: %h, expected: %h.", rd_ram_checksum, RD_RAM_CHECKSUM);
`endif
                    test_error <= TEST_ERROR_RAM_CHECKSUM;
                end
            end else if (do_data_write) begin
                data_addr_o <= data_wr_address;
                data_data_o <= data_wr_data;
                data_we_o <= 1'b1;
                data_sel_o <= core_sel_o;
                {data_stb_o, data_cyc_o} <= 2'b11;
            end
        end
    endtask

    //==================================================================================================================
    // IO/CSR test
    //==================================================================================================================
    localparam [4:0] STATE_WRITE_MTVEC              = 5'h1;
    localparam [4:0] STATE_WRITE_MTVEC_READY        = 5'h2;
    localparam [4:0] STATE_READ_MTIME               = 5'h3;
    localparam [4:0] STATE_READ_MTIME_READY         = 5'h4;
    localparam [4:0] STATE_READ_MTIME_H             = 5'h5;
    localparam [4:0] STATE_READ_MTIME_H_READY       = 5'h6;
    localparam [4:0] STATE_WRITE_TIME_CMP           = 5'h7;
    localparam [4:0] STATE_WRITE_TIME_CMP_READY     = 5'h8;
    localparam [4:0] STATE_WRITE_TIME_CMP_H         = 5'h9;
    localparam [4:0] STATE_WRITE_TIME_CMP_H_READY   = 5'ha;
    localparam [4:0] STATE_WAIT_FOR_IRQ             = 5'hb;
    localparam [4:0] STATE_WRITE_MEPC               = 5'hc;
    localparam [4:0] STATE_WRITE_MEPC_READY         = 5'hd;
    localparam [4:0] STATE_ENTER_INTERRUPT          = 5'he;
    localparam [4:0] STATE_ENTER_INTERRUPT_READY    = 5'hf;
    localparam [4:0] STATE_WRITE_MIE                = 5'h10;
    localparam [4:0] STATE_WRITE_MIE_READY          = 5'h11;
    localparam [4:0] STATE_WRITE_MSTATUS            = 5'h12;
    localparam [4:0] STATE_WRITE_MSTATUS_READY      = 5'h13;
    localparam [4:0] STATE_EXIT_INTERRUPT           = 5'h14;
    localparam [4:0] STATE_EXIT_INTERRUPT_READY     = 5'h15;
    localparam [4:0] STATE_WRITE_MCAUSE             = 5'h16;
    localparam [4:0] STATE_WRITE_MCAUSE_READY       = 5'h17;

    localparam [4:0] STATE_ERROR                    = 5'h1e;
    localparam [4:0] STATE_DONE                     = 5'h1f;

    logic [4:0] state_m;
    logic [63:0] time_now, timecmp;
    task test_io_task;
        if (start_test) begin
`ifdef D_CORE
            $display($time, " CORE: Test %0d", test_num);
`endif
            state_m <= STATE_WRITE_MTVEC;
        end else begin
            (* parallel_case, full_case *)
            case (state_m)
                STATE_WRITE_MTVEC: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MTVEC;
                    core_data_o <= `ROM_BEGIN_ADDR;
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_MTVEC_READY;
                end

                STATE_WRITE_MTVEC_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        // Enable timer interrupts
                        state_m <= STATE_WRITE_MIE;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WRITE_MIE: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MIE;
                    core_data_o <= 0;
                    core_data_o[`IRQ_TIMER] <= 1'b1;

                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_MIE_READY;
                end

                STATE_WRITE_MIE_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        // Set the global interrupt bit
                        state_m <= STATE_WRITE_MSTATUS;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WRITE_MSTATUS: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MSTATUS;
                    core_data_o <= 0;
                    core_data_o[`MSTATUS_MIE_BIT] <= 1'b1;

                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_MSTATUS_READY;
                end

                STATE_WRITE_MSTATUS_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_READ_MTIME;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_READ_MTIME: begin
                    core_addr_o <= `IO_BEGIN_ADDR + `IO_MTIME;
                    core_we_o <= 1'b0;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_READ_MTIME_READY;
                end

                STATE_READ_MTIME_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        time_now[31:0] <= core_data_i;
                        state_m <= STATE_READ_MTIME_H;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_READ_MTIME_H: begin
                    core_addr_o <= `IO_BEGIN_ADDR + `IO_MTIMEH;
                    core_we_o <= 1'b0;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_READ_MTIME_H_READY;
                end

                STATE_READ_MTIME_H_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        time_now[63:32] <= core_data_i;
`ifdef D_CORE
                        $display($time, " CORE: IO/CSR Time read: %0d.", {core_data_i, time_now[31:0]});
`endif
                        timecmp <= {core_data_i, time_now[31:0]} + 500;
                        state_m <= STATE_WRITE_TIME_CMP;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WRITE_TIME_CMP: begin
                    core_addr_o <= `IO_BEGIN_ADDR + `IO_MTIMECMP;
                    core_data_o <= timecmp[31:0];
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_TIME_CMP_READY;
                end

                STATE_WRITE_TIME_CMP_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_WRITE_TIME_CMP_H;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WRITE_TIME_CMP_H: begin
                    core_addr_o <= `IO_BEGIN_ADDR + `IO_MTIMECMPH;
                    core_data_o <= timecmp[63:32];
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_TIME_CMP_H_READY;
                end

                STATE_WRITE_TIME_CMP_H_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_WAIT_FOR_IRQ;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WAIT_FOR_IRQ: begin
                    if (|io_interrupts_i) begin
`ifdef D_CORE
                        $display($time, " CORE: IO interrupt raised.");
`endif
                        state_m <= STATE_WRITE_MEPC;
                    end
                end

                STATE_WRITE_MEPC: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MEPC;
                    core_data_o <= `ROM_BEGIN_ADDR + 32'h0000_1234;
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_MEPC_READY;
                end

                STATE_WRITE_MEPC_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_WRITE_MCAUSE;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_WRITE_MCAUSE: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_MCAUSE;
                    core_data_o <= `IRQ_CODE_TIMER;
                    core_we_o <= 1'b1;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_WRITE_MCAUSE_READY;
                end

                STATE_WRITE_MCAUSE_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ENTER_INTERRUPT;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_ENTER_INTERRUPT: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_ENTER_TRAP;
                    core_we_o <= 1'b0;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_ENTER_INTERRUPT_READY;
                end

                STATE_ENTER_INTERRUPT_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_EXIT_INTERRUPT;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_EXIT_INTERRUPT: begin
                    core_addr_o <= `CSR_BEGIN_ADDR + `CSR_EXIT_TRAP;
                    core_we_o <= 1'b0;
                    core_sel_o <= 4'b1111;
                    {core_stb_o, core_cyc_o} <= 2'b11;

                    state_m <= STATE_EXIT_INTERRUPT_READY;
                end

                STATE_EXIT_INTERRUPT_READY: begin
                    if (core_cyc_o & core_stb_o & core_ack_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_DONE;
                    end else if (core_cyc_o & core_stb_o & core_err_i) begin
                        {core_stb_o, core_cyc_o} <= 2'b00;
                        state_m <= STATE_ERROR;
                    end
                end

                STATE_DONE: begin
                    if (CHECKSUM_LED == 2'h0) begin
                        led[test_num] <= 1'b1;
                        `ifdef BOARD_BLUE_WHALE led_a[test_num] <= 1'b1;`endif
                    end

                    test_ok <= 1'b1;
`ifdef D_CORE
                    $display($time, " CORE: IO/CSR test OK.");
`endif
                end

                STATE_ERROR: begin
                    test_error <= TEST_ERROR_IRQ;
`ifdef D_CORE
                    $display($time, " CORE: IO/CSR test failed.");
`endif
                end

                default: begin
                    // Invalid state machine
                end
            endcase
        end

    endtask

    //==================================================================================================================
    // The controller
    //==================================================================================================================
    // We need to stay minimum 100μs in reset for the benefit of the SDRAM. We wait 200μs.
    localparam RESET_CLKS = 200000 / CLK_PERIOD_NS;
    // At power-up reset is set to 1
    logic reset = 1'b1;
    // After reset we wait for the SDRAM and flash to be ready for use.
    logic reset_and_wait = 1'b1;
    // Number of clock periods that we stay in the reset state
    logic [15:0] reset_clks = 0;
    logic sleep, start_test;
    logic [2:0] test_num;
    logic [15:0] sleep_count;
    logic [31:0] blink_count;
    logic reset_btn_p = 1'b0;
    logic reset_btn = 1'b0;

    always @(posedge clk) begin
`ifdef BOARD_BLUE_WHALE
    // Button on the FPGA board
    //{reset_btn, reset_btn_p} <= {reset_btn_p, btn[0]};
    // Button on the extension board
    {reset_btn, reset_btn_p} <= {reset_btn_p, btn[1]};
`else
    {reset_btn, reset_btn_p} <= {reset_btn_p, btn[0]};
`endif

        case (1'b1)
            reset_btn: begin
                reset <= 1'b1;
                reset_and_wait <= 1'b1;
                reset_clks <= 0;
                led <= 0;
                `ifdef BOARD_BLUE_WHALE led_a <= 16'h0;`endif
            end

            reset_and_wait: begin
                reset_clks <= reset_clks + 16'h1;

                case (reset_clks)
                    0: begin
                        if (pll_locked) begin
`ifdef D_CORE
                            $display($time, " CORE: Reset start.");
`endif
                            start_test <= 1'b0;
                            sleep <= 1'b0;
                            test_ok <= 1'b0;
                            test_error <= TEST_ERROR_NONE;
                            {core_stb_o, core_cyc_o} <= 2'b00;
                            {data_stb_o, data_cyc_o} <= 2'b00;
                            blink_count <= 32'h0;
                        end else begin
                            // Back to zero to wait for PLL lock
                            reset_clks <= 0;
                        end
                    end

                    // Set the case value below to configure the duration of the reset assertion.
                    // We must account for the slowest clock.
                    40: begin
                        // The reset is complete
                        reset <= 1'b0;
`ifdef D_CORE
                        $display($time, " CORE: Reset complete.");
`endif
                    end

                    RESET_CLKS: begin
                        // We are done waiting. The SDRAM and the flash are now ready for use.
                        reset_and_wait <= 1'b0;
                        reset_clks <= 0;
                        // Start the first test
                        start_test <= 1'b1;
                        test_num <= 0;
                    end
                endcase
            end

            sleep: begin
                sleep_count <= sleep_count + 16'h1;
                if (sleep_count[15]) begin
                    sleep <= 1'b0;
                    // Start the tests from the beginning
                    start_test <= 1'b1;
                    test_num <= 0;

                    led <= 0;
                end
            end

            test_ok: begin
                test_ok <= 1'b0;
                if (test_num == 3'h6) begin
                    // Sleep before starting over
                    sleep <= 1'b1;
                    sleep_count <= 0;
                end else begin
                    // Start the next test
                    start_test <= 1'b1;
                    test_num <= test_num + 3'h1;
                end
            end

            |test_error: begin
                blink_count <= blink_count + 32'h1;
                (* parallel_case, full_case *)
                case (test_error)
                    TEST_ERROR_CORE: begin
                        // 2 seconds on, 2 seconds off
                        if (blink_count >= 2000000000/CLK_PERIOD_NS) begin
                            led[7] <= ~led[7];
                            `ifdef BOARD_BLUE_WHALE led_a[7] <= ~led[7];`endif
                            blink_count <= 32'h0;
                        end
                    end

                    TEST_ERROR_FLASH_CHECKSUM: begin
                        // 1 second on, 1 second off
                        if (blink_count >= 1000000000/CLK_PERIOD_NS) begin
                            led[7] <= ~led[7];
                            `ifdef BOARD_BLUE_WHALE led_a[7] <= ~led[7];`endif
                            blink_count <= 32'h0;
                        end
                    end

                    TEST_ERROR_DATA: begin
                        // 2 seconds on, 2 seconds off
                        if (blink_count >= 2000000000/CLK_PERIOD_NS) begin
                            led[7] <= ~led[7];
                            `ifdef BOARD_BLUE_WHALE led_a[15] <= ~led[7];`endif
                            blink_count <= 32'h0;
                        end
                    end

                    TEST_ERROR_RAM_CHECKSUM: begin
                        // 1 second on, 1 second off
                        if (blink_count >= 1000000000/CLK_PERIOD_NS) begin
                            led[7] <= ~led[7];
                            `ifdef BOARD_BLUE_WHALE led_a[15] <= ~led[7];`endif
                            blink_count <= 32'h0;
                        end
                    end

                    TEST_ERROR_IRQ: begin
                        // 0.5 second on, 0.5 second off
                        if (blink_count >= 500000000/CLK_PERIOD_NS) begin
                            led[7] <= ~led[7];
                            `ifdef BOARD_BLUE_WHALE led_a[7] <= ~led[7];`endif
                            blink_count <= 32'h0;
                        end
                    end

                    default: begin
                    end
                endcase
`ifdef SIMULATION
                $finish(0);
`endif
            end

            default: begin
                incr_event_counters_o <= 0;
                start_test <= 1'b0;
                if (test_num < 3'h6) test_mem_task;
                else test_io_task;
            end
        endcase
    end
endmodule
