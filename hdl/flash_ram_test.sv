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
 * This module performs tests of the flash and the RAM by reading known data from the flash, writing it into RAM
 * and reading it back to perform a checksum. It is designed for the ULX3S and Blue Whale FPGA boards.
 * It performs 8 bit, 16 bit and 32 bit tests. If the tests succeed LED[0] through LED[6] will turn on.
 * If tests fail LED[7] will turn on.
 *
 * The checksum is not sophisticated to lower the compute needs.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "memory_map.svh"

module flash_ram_test(
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
    localparam CLK_PERIOD_NS = `CLK_PERIOD_NS;
    // For SPI mode (QPI_MODE not defined) the minimum value is 16, for QPI_MODE the minimum value is 20.
    localparam FLASH_CLK_PERIOD_NS = 20;

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
    logic pll_locked = 1'b1;

`else // SIMULATION
    logic clk;
    logic flash_master_clk;
    logic flash_device_clk;

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
            .out1_hz(1000000000/FLASH_CLK_PERIOD_NS), .out1_deg(270)) pll_secondary( // 50MHz shifted
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
            .out1_hz(1000000000/FLASH_CLK_PERIOD_NS), .out1_deg(270)) pll_secondary( // 50MHz shifted
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
    assign pll_locked = pll_locked_main & pll_locked_secondary;

    // Provide the clock to the flash.
    logic flash_clk;
    logic tristate = 1'b0;
    USRMCLK u1 (.USRMCLKI(flash_clk), .USRMCLKTS(tristate));

`endif // SIMULATION

    logic sync_flash_ack_i_pulse;
    DFF_META dff_meta_flash_ack(.reset (reset), .D (flash_ack_i), .clk (clk), .Q_pulse(sync_flash_ack_i_pulse));

    //==================================================================================================================
    // Instantiate the modules
    //==================================================================================================================
    // Flash ports
    logic flash_stb_o, flash_cyc_o;
    logic [23:0] flash_addr_o;
    logic [3:0] flash_sel_o;
    logic [31:0] flash_data_i;
    logic flash_ack_i;

    flash_master #(.FLASH_CLK_PERIOD_NS(FLASH_CLK_PERIOD_NS)) flash_master_m (
        // Wishbone interface
        .clk_i          (flash_master_clk),
        .rst_i          (reset),
        .stb_i          (flash_stb_o),
        .cyc_i          (flash_cyc_o),
        .sel_i          (flash_sel_o),
        .addr_i         (flash_addr_o),
        .ack_o          (flash_ack_i),
        .data_o         (flash_data_i),
        // Flash clock
        .device_clk_i   (flash_device_clk),
        // Flash wires
        .flash_csn      (flash_csn),
        .flash_clk      (flash_clk),
        .flash_mosi     (flash_mosi),
        .flash_miso     (flash_miso),
        .flash_wpn      (flash_wpn),
        .flash_holdn    (flash_holdn));

`ifdef D_FLASH_ONLY_TEST
    // RAM ports
    logic [31:0] ram_data_o;
    logic ram_stb_o;
    logic ram_cyc_o;
    logic [3:0] ram_sel_o;
    logic ram_we_o;
    logic ram_ack_i;
    logic [31:0] ram_data_i;
`ifdef BOARD_ULX3S
    logic [23:0] ram_addr_o;
    sdram #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) sdram_m (
        // Wishbone interface
        .clk_i          (clk),
        .rst_i          (reset),
        .stb_i          (ram_stb_o),
        .cyc_i          (ram_cyc_o),
        .sel_i          (ram_sel_o),
        .we_i           (ram_we_o),
        .addr_i         (ram_addr_o),
        .data_i         (ram_data_o),
        .ack_o          (ram_ack_i),
        .data_o         (ram_data_i),
        // SDRAM clock
        .device_clk_i   (sdram_device_clk),
        // SDRAM signals
        .sdram_clk      (sdram_clk),
        .sdram_cke      (sdram_cke),
        .sdram_csn      (sdram_csn),
        .sdram_wen      (sdram_wen),
        .sdram_rasn     (sdram_rasn),
        .sdram_casn     (sdram_casn),
        .sdram_a        (sdram_a),
        .sdram_ba       (sdram_ba),
        .sdram_dqm      (sdram_dqm),
        .sdram_d        (sdram_d));
`else // BOARD_ULX3S
    logic [21:0] ram_addr_o;
    psram #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) psram_m (
        // Wishbone interface
        .clk_i          (clk),
        .rst_i          (reset),
        .stb_i          (ram_stb_o),
        .cyc_i          (ram_cyc_o),
        .sel_i          (ram_sel_o),
        .we_i           (ram_we_o),
        .addr_i         (ram_addr_o),
        .data_i         (ram_data_o),
        .ack_o          (ram_ack_i),
        .data_o         (ram_data_i),
        // PSRAM signals
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d));
`endif // BOARD_ULX3S
`endif // D_FLASH_ONLY_TEST
    //==================================================================================================================
    // The test code
    //==================================================================================================================
    // 0: Flash & RAM checksum OK | 1: Flash checksum OK | 2, 3: DEBUG
`ifdef D_FLASH_ONLY_TEST
    localparam [2:0] CHECKSUM_LED = 1;
`else
    localparam [2:0] CHECKSUM_LED = 0;
`endif
    localparam RAM_OFFSET = 24'h01_0000;

    //==================================================================================================================
    // Flash
    //==================================================================================================================
    logic do_next_ram_read_f, do_ram_write, test_done_flash_ok, test_done_flash_error;
    logic [31:0] wr_checksum;
    logic [31:0] WR_CHECKSUM;
    logic [15:0] wr_count;
    logic [15:0] WR_COUNT;
    logic [2:0] WR_INCR;
    logic [23:0] flash_address, ram_wr_address;
    logic [31:0] ram_wr_data;

    always @(posedge clk) begin
        if (reset) begin
            {flash_stb_o, flash_cyc_o} <= 2'b00;

            do_next_ram_read_f <= 1'b0;
            do_ram_write <= 1'b0;

            test_done_flash_ok <= 1'b0;
            test_done_flash_error <= 1'b0;

            if (CHECKSUM_LED == 1 || CHECKSUM_LED == 2) begin
                led <= 0;
            end
            `ifdef BOARD_BLUE_WHALE led_a <= 16'h0; `endif
        end else if (start_test) begin
            if (test_num == 0) begin
                if (CHECKSUM_LED == 1 || CHECKSUM_LED == 2) begin
                    led <= 0;
                end
                `ifdef BOARD_BLUE_WHALE led_a <= 16'h0;`endif
            end

            do_next_ram_read_f <= 1'b0;
            do_ram_write <= 1'b0;

            test_done_flash_ok <= 1'b0;
            test_done_flash_error <= 1'b0;

            wr_checksum <= 0;
            wr_count <= 0;

            flash_address <= `FLASH_OFFSET_ADDR;

            (* parallel_case, full_case *)
            case (test_num)
                0: begin
                    // Write 1, read 1
                    WR_COUNT <= 16'h1724;
                    WR_INCR <= 3'h1;
                    WR_CHECKSUM <= 32'h0000_34dc;
                    flash_sel_o <= 4'b0001;
                end

                1: begin
                    // Write 2, read 2
                    WR_COUNT <= 16'h0b92;
                    WR_INCR <= 3'h2;
                    WR_CHECKSUM <= 32'h0003_4fc8;
                    flash_sel_o <= 4'b0011;
                end

                2: begin
                    // Write 2, read 1
                    WR_COUNT <= 16'h0b92;
                    WR_INCR <= 3'h2;
                    WR_CHECKSUM <= 32'h0003_4fc8;
                    flash_sel_o <= 4'b0011;
                end

                3: begin
                    // Write 1, read 2
                    WR_COUNT <= 16'h1724;
                    WR_INCR <= 3'h1;
                    WR_CHECKSUM <= 32'h0000_34dc;
                    flash_sel_o <= 4'b0001;
                end

                4: begin
                    // Write 4, read 1
                    WR_COUNT <= 16'h05c9;
                    WR_INCR <= 3'h4;
                    WR_CHECKSUM <= 32'hd800_1834;
                    flash_sel_o <= 4'b1111;
                end

                5: begin
                    // Write 4, read 2
                    WR_COUNT <= 16'h05c9;
                    WR_INCR <= 3'h4;
                    WR_CHECKSUM <= 32'hd800_1834;
                    flash_sel_o <= 4'b1111;
                end

                6: begin
                    // Write 4, read 4
                    WR_COUNT <= 16'h05c9;
                    WR_INCR <= 3'h4;
                    WR_CHECKSUM <= 32'hd800_1834;
                    flash_sel_o <= 4'b1111;
                end

                default: begin
                    // Invalid test number
                end
            endcase
        end else begin
            // Signals that stay on for only one clock cycle
            do_next_ram_read_f <= 1'b0;
            do_ram_write <= 1'b0;
            test_done_flash_ok <= 1'b0;
            test_done_flash_error <= 1'b0;

            if (flash_cyc_o & flash_stb_o & sync_flash_ack_i_pulse) begin
                {flash_stb_o, flash_cyc_o} <= 2'b00;
`ifdef D_CORE_FINE
                $display($time, " CORE: Flash data @[%h]: %h", flash_addr_o, flash_data_i);
`endif
                case (1'b1)
                    WR_INCR[0]: begin
                        wr_checksum <= wr_checksum + (wr_checksum ^ flash_data_i[7:0]);
                        if (CHECKSUM_LED == 2) begin
                            if (wr_count == 0) led[7:0] <= flash_data_i[7:0];
                        end
                    end

                    WR_INCR[1]: begin
                        wr_checksum <= wr_checksum + (wr_checksum ^ flash_data_i[15:0]);
                    end

                    WR_INCR[2]: begin
                        wr_checksum <= wr_checksum + (wr_checksum ^ flash_data_i);
                    end
                endcase

                flash_address <= flash_address + WR_INCR;
                wr_count <= wr_count + 1;

                // Write the flash data to RAM
                ram_wr_data <= flash_data_i;
                ram_wr_address <= (flash_addr_o - `FLASH_OFFSET_ADDR) + RAM_OFFSET;
                do_ram_write <= 1'b1;
            end

            if (do_next_flash_read) begin
                flash_addr_o <= flash_address;
                // flash_sel_o was set at the beginning of the test
                {flash_stb_o, flash_cyc_o} <= 2'b11;
            end

            if (done_wr) begin
                if (wr_checksum == WR_CHECKSUM) begin
                    if (CHECKSUM_LED == 1) begin
                        led[test_num] <= 1'b1;
                    end
                    `ifdef BOARD_BLUE_WHALE led_a[test_num] <= 1'b1;`endif
// This flag is used by yosys.
`ifdef D_FLASH_ONLY_TEST
`ifdef D_CORE
                    $display($time, " CORE: Flash checksum OK");
`endif
                    // Flash test only
                    test_done_flash_ok <= 1'b1;
`else // D_FLASH_ONLY_TEST
                    // Start the reading from RAM
                    do_next_ram_read_f <= 1'b1;
`endif // D_FLASH_ONLY_TEST
                end else begin
                    if (CHECKSUM_LED == 1) begin
                        led[6] <= 1'b1;
                    end
                    `ifdef BOARD_BLUE_WHALE led_a[15] <= 1'b1;`endif
`ifdef D_CORE
                    $display($time, " CORE: Flash checksum failed: %h, expected: %h", wr_checksum, WR_CHECKSUM);
`endif
                    test_done_flash_error <= 1'b1;
                end
            end
        end
    end

    //==================================================================================================================
    // Start a rd/wr RAM transaction
    //==================================================================================================================
    task start_ram_transaction_task (input we, input [23:0] addr, input [2:0] byte_count, input [31:0] wr_data);
        ram_we_o <= we;
        {ram_stb_o, ram_cyc_o} <= 2'b11;
`ifdef BOARD_ULX3S
        ram_addr_o <= {1'b0, addr[23:1]};
`else // BOARD_BLUE_WHALE
        ram_addr_o <= {1'b0, addr[21:1]};
`endif

        case (byte_count)
            1: begin
                if (addr[0] == 1'b0) begin
                    ram_sel_o <= 4'b0001;
                    if (we) ram_data_o <= wr_data[7:0];
                end else begin
                    ram_sel_o <= 4'b0010;
                    if (we) ram_data_o[15:8] <= wr_data[7:0];
                end
            end

            2: begin
                if (we) ram_data_o[15:0] <= wr_data[15:0];
                ram_sel_o <= 4'b0011;
            end

            4: begin
                if (we) ram_data_o <= wr_data;
                ram_sel_o <= 4'b1111;
            end
        endcase
    endtask

    //==================================================================================================================
    // RAM
    //==================================================================================================================
    logic done_rd, done_wr, do_next_flash_read, do_next_ram_read_r;
    logic test_done_ram_ok, test_done_ram_error;
    logic [31:0] rd_checksum;
    logic [31:0] RD_CHECKSUM;
    logic [15:0] rd_count;
    logic [15:0] RD_COUNT;
    logic [2:0] RD_INCR;
    logic [23:0] ram_rd_address;

    always @(posedge clk) begin
        if (reset) begin
            {ram_stb_o, ram_cyc_o} <= 2'b00;

            done_rd <= 1'b0;
            done_wr <= 1'b0;

            do_next_flash_read <= 1'b0;
            do_next_ram_read_r <= 1'b0;

            test_done_ram_ok <= 1'b0;
            test_done_ram_error <= 1'b0;
            if (CHECKSUM_LED == 0 || CHECKSUM_LED == 3) led <= 0;
            `ifdef BOARD_BLUE_WHALE led_b <= 0; `endif
        end else if (start_test) begin
`ifdef D_CORE
            $display($time, " CORE: Test: %d", test_num);
`endif
            if (test_num == 0) begin
                if (CHECKSUM_LED == 0 || CHECKSUM_LED == 3) led <= 0;
                `ifdef BOARD_BLUE_WHALE led_b <= 0; `endif
            end

            rd_checksum <= 0;
            rd_count <= 0;

            ram_rd_address <= RAM_OFFSET;
            test_done_ram_ok <= 1'b0;

            (* parallel_case, full_case *)
            case (test_num)
                0: begin
                    // Write 1, read 1
                    RD_COUNT <= 16'h1724;
                    RD_INCR <= 3'h1;
                    RD_CHECKSUM <= 32'h0000_34dc;
                end

                1: begin
                    // Write 2, read 2
                    RD_COUNT <= 16'h0b92;
                    RD_INCR <= 3'h2;
                    RD_CHECKSUM <= 32'h0003_4fc8;
                end

                2: begin
                    // Write 2, read 1
                    RD_COUNT <= 16'h1724;
                    RD_INCR <= 3'h1;
                    RD_CHECKSUM <= 32'h0000_34dc;
                end

                3: begin
                    // Write 1, read 2
                    RD_COUNT <= 16'h0b92;
                    RD_INCR <= 3'h2;
                    RD_CHECKSUM <= 32'h0003_4fc8;
                end

                4: begin
                    // Write 4, read 1
                    RD_COUNT <= 16'h1724;
                    RD_INCR <= 3'h1;
                    RD_CHECKSUM <= 32'h0000_34dc;
                end

                5: begin
                    // Write 4, read 2
                    RD_COUNT <= 16'h0b92;
                    RD_INCR <= 3'h2;
                    RD_CHECKSUM <= 32'h0003_4fc8;
                end

                6: begin
                    // Write 4, read 4
                    RD_COUNT <= 16'h05c9;
                    RD_INCR <= 3'h4;
                    RD_CHECKSUM <= 32'hd800_1834;
                end

                default: begin
                    // Invalid test number
                end
            endcase
            // Start reading from flash
            do_next_flash_read <= 1'b1;
        end else begin
            done_wr <= 1'b0;
            do_next_flash_read <= 1'b0;
            test_done_ram_ok <= 1'b0;

            if (ram_cyc_o & ram_stb_o & ram_ack_i) begin
                // The transaction is complete
                {ram_stb_o, ram_cyc_o} <= 2'b00;
                if (ram_we_o) begin
`ifdef D_CORE_FINE
                    $display($time, " CORE: RAM wr @[%h] %h", ram_addr_o << 1, ram_data_o);
`endif
                    if (wr_count == WR_COUNT) begin
                        done_wr <= 1'b1;
                    end else begin
                        do_next_flash_read <= 1'b1;
                    end
                end else begin
                    case (1'b1)
                        RD_INCR[0]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: RAM rd data @[%h]: %h", ram_addr_o << 1,
                                        ram_sel_o[1:0] == 2'b01 ? ram_data_i[7:0] : ram_data_i[15:8]);
`endif
                            rd_checksum <= rd_checksum
                                    + (rd_checksum ^ (ram_sel_o[1:0] == 2'b01 ? ram_data_i[7:0] : ram_data_i[15:8]));
                            if (CHECKSUM_LED == 3) begin
                                if (rd_count == 0) led <= ram_data_i[7:0];
                            end
                        end

                        RD_INCR[1]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: RAM rd data @[%h]: %h", ram_addr_o << 1, ram_data_i[15:0]);
`endif
                            rd_checksum <= rd_checksum + (rd_checksum ^ ram_data_i[15:0]);
                        end

                        RD_INCR[2]: begin
`ifdef D_CORE_FINE
                            $display($time, " CORE: RAM rd data @[%h]: %h", (ram_addr_o << 1) - 1, ram_data_i);
`endif
                            rd_checksum <= rd_checksum + (rd_checksum ^ ram_data_i);
                        end
                    endcase

                    rd_count <= rd_count + 1;
                    if (rd_count == RD_COUNT - 1) begin
                        done_rd <= 1'b1;
                    end else begin
                        ram_rd_address <= ram_rd_address + RD_INCR;
                        do_next_ram_read_r <= 1'b1;
                    end
                end
            end

            if (do_next_ram_read_r | do_next_ram_read_f) begin
                do_next_ram_read_r <= 1'b0;

                start_ram_transaction_task (1'b0, ram_rd_address, RD_INCR, 0);
            end

            if (done_rd) begin
                done_rd <= 1'b0;
                if (rd_checksum == RD_CHECKSUM) begin
`ifdef D_CORE
                    $display($time, " CORE: Flash and RAM checksum OK");
`endif
                    if (CHECKSUM_LED == 0) led[test_num] <= 1'b1;
                    `ifdef BOARD_BLUE_WHALE led_b[test_num] <= 1'b1;`endif
                    test_done_ram_ok <= 1'b1;
                end else begin
`ifdef D_CORE
                    $display($time, " CORE: RAM checksum failed: %h, expected: %h", rd_checksum, RD_CHECKSUM);
`endif
                    if (CHECKSUM_LED == 0) led[7] <= 1'b1;
                    `ifdef BOARD_BLUE_WHALE led_b[15] <= 1'b1;`endif
                    test_done_ram_error <= 1'b1;
                end
            end

            if (do_ram_write) begin
                // Write to RAM the same number of bytes that you read from the flash
                start_ram_transaction_task (1'b1, ram_wr_address, WR_INCR, ram_wr_data);
            end

            if (test_done_flash_error) begin
                // We do this here so we can turn on the error LED
                if (CHECKSUM_LED == 0) led[6] <= 1'b1;
                test_done_ram_error <= 1'b1;
            end
        end
    end

    //==================================================================================================================
    // The controller
    //==================================================================================================================
    // We need to stay minimum 100μs in reset for the benefit of the RAM. We wait 200μs.
    localparam RESET_CLKS = 200000 / CLK_PERIOD_NS;
    // At power-up reset is set to 1
    logic reset = 1'b1;
    // After reset we wait for the SDRAM and flash to be ready for use.
    logic reset_and_wait = 1'b1;
    // Number of clock periods that we stay in the reset state
    logic [15:0] reset_clks = 0;
    logic start_test, sleep;
    logic [2:0] test_num;
    logic [15:0] sleep_count;
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
                        end else begin
                            // Back to zero to wait for PLL lock
                            reset_clks <= 0;
                        end
                    end

                    // Set the case value below to configure the duration of the reset assertion.
                    8: begin
                        // The reset is complete
                        reset <= 1'b0;
`ifdef D_CORE
                        $display($time, " CORE: Reset complete.");
`endif
                    end

                    RESET_CLKS: begin
                        // We are done waiting. The RAM and the flash are now ready for use.
                        reset_and_wait <= 1'b0;
                        reset_clks <= 0;
                        // Start the first test
                        start_test <= 1'b1;
                        test_num <= 0;
                    end
                endcase
            end

            sleep: begin
                sleep_count <= sleep_count + 1;
                if (sleep_count == 64000) begin
                    sleep <= 1'b0;
                    // Start the tests from the beginning
                    start_test <= 1'b1;
                    test_num <= 0;
                end
            end

            test_done_ram_ok | test_done_flash_ok: begin
                if (test_num == 6) begin
                    // Sleep before starting over
                    sleep <= 1'b1;
                    sleep_count <= 0;
                end else begin
                    // Start the next test
                    start_test <= 1'b1;
                    test_num <= test_num + 1;
                end
            end

            test_done_ram_error: begin
`ifdef SIMULATION
                $finish(0);
`endif
            end

            default: begin
                start_test <= 1'b0;
            end
        endcase
    end
endmodule
