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
 * This is the top module for the mem_space test. It wraps the mem_space_test module and connects the
 * flash slave and the RAM simulator.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "memory_map.svh"

module sim_top_mem_space_test;

    logic [7:0] led;
    logic [1:0] btn;
    // Flash wires
    wire flash_csn;
    wire flash_clk;
    wire flash_mosi;
    wire flash_miso;
    wire flash_wpn;
    wire flash_holdn;
`ifdef BOARD_ULX3S
    logic wifi_gpio0;
    // SDRAM wires
    wire sdram_clk;
    wire sdram_cke;
    wire sdram_csn;
    wire sdram_wen;
    wire sdram_rasn;
    wire sdram_casn;
    wire [12:0] sdram_a;
    wire [1:0] sdram_ba;
    wire [1:0] sdram_dqm;
    wire [15:0] sdram_d;
`else // BOARD_BLUE_WHALE
    wire [15:0] led_a;
    wire [15:0] led_b;
    // RAM wires
    wire psram_cen;
    wire psram_wen;
    wire psram_oen;
    wire psram_lbn;
    wire psram_ubn;
    wire [21:0] psram_a;
    wire [15:0] psram_d;
`endif // BOARD_ULX3S

    mem_space_test mem_space_test_m (
        .clk_in         (1'b0),
        .led            (led),
        .btn            (btn),
        // SPI flash wires
        .flash_csn      (flash_csn),
        .flash_clk      (flash_clk),
        .flash_mosi     (flash_mosi),
        .flash_miso     (flash_miso),
        .flash_wpn      (flash_wpn),
        .flash_holdn    (flash_holdn),
`ifdef BOARD_ULX3S
        .wifi_gpio0     (wifi_gpio0),
        // RAM wires
        .sdram_clk      (sdram_clk),
        .sdram_cke      (sdram_cke),
        .sdram_csn      (sdram_csn),
        .sdram_wen      (sdram_wen),
        .sdram_rasn     (sdram_rasn),
        .sdram_casn     (sdram_casn),
        .sdram_a        (sdram_a),
        .sdram_ba       (sdram_ba),
        .sdram_dqm      (sdram_dqm),
        .sdram_d        (sdram_d)
`else // BOARD_BLUE_WHALE
        .led_a          (led_a),
        .led_b          (led_b),
        // RAM wires
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d)
`endif // BOARD_ULX3S
);

    sim_flash_slave #(.FLASH_PHYSICAL_SIZE(32'h0100_0000)) sim_flash_slave_m (
        .flash_csn      (flash_csn),
        .flash_clk      (flash_clk),
        .flash_mosi     (flash_mosi),
        .flash_miso     (flash_miso),
        .flash_wpn      (flash_wpn),
        .flash_holdn    (flash_holdn));

`ifdef BOARD_ULX3S
    sim_sdram #(.RAM_PHYSICAL_SIZE(32'h0200_0000)) sim_sdram_m (
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
`else // BOARD_BLUE_WHALE
    sim_psram #(.RAM_PHYSICAL_SIZE(32'h0200_0000)) sim_psram_m (
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d));
`endif
`include "initial.svh"
endmodule
