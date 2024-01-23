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
`timescale 1ns / 1ns
`default_nettype none

`include "memory_map.svh"
`include "tags.svh"

module ram_bus #(
    parameter [31:0] CLK_PERIOD_NS = 20) (
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [3:0] sel_i,
    input logic we_i,
    input logic [31:0] addr_i,
    input logic [2:0] addr_tag_i,
    input logic [31:0] data_i,
    output logic ack_o,
    output logic [31:0] data_o,
    output logic data_tag_o,
`ifdef BOARD_ULX3S
    input logic sdram_device_clk_i,
    // SDRAM wires
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
`else //BOARD_ULX3S
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

    logic [31:0] ram_data_o;
    logic ram_ack_i;
`ifdef BOARD_ULX3S
    sdram #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) sdram_m (
        // Wishbone interface
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .addr_i         (addr_i[24:1]),
        .data_i         (sel_i == 4'b0001 ? (addr_i[0] == 0 ? {8'h0, data_i[7:0]} : {data_i[7:0], 8'h0}) : data_i),
        .stb_i          (ram_stb_o),
        .cyc_i          (ram_cyc_o),
        .sel_i          (sel_i == 4'b0001 ? (addr_i[0] == 0 ? sel_i : 4'b0010) : sel_i),
        .we_i           (we_i),
        .ack_o          (ram_ack_i),
        .data_o         (ram_data_o),
        // SDRAM clock
        .device_clk_i   (sdram_device_clk_i),
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
    psram #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) psram_m (
        // Wishbone interface
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .addr_i         (addr_i[22:1]),
        .data_i         (sel_i == 4'b0001 ? (addr_i[0] == 0 ? {8'h0, data_i[7:0]} : {data_i[7:0], 8'h0}) : data_i),
        .stb_i          (ram_stb_o),
        .cyc_i          (ram_cyc_o),
        .sel_i          (sel_i == 4'b0001 ? (addr_i[0] == 0 ? sel_i : 4'b0010) : sel_i),
        .we_i           (we_i),
        .ack_o          (ram_ack_i),
        .data_o         (ram_data_o),
        // PSRAM signals
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d));
`endif // BOARD_ULX3S

    logic sync_ack = 1'b0;
    assign ack_o = (sync_ack | ram_ack_i) & stb_i;

    // Control if transactions can start by gating the strobe and cycle of the RAM.
    logic ram_stb_o;
    assign ram_stb_o = stb_i &&
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_NONE) ||
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_LRSC) && ~we_i) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i == reservation_addr)) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_LOCK}) && (addr_i != reservation_addr)) ||
                    (addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_UNLOCK}));

    logic ram_cyc_o;
    assign ram_cyc_o = cyc_i &&
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_NONE) ||
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_LRSC) && ~we_i) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i == reservation_addr)) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_LOCK}) && (addr_i != reservation_addr)) ||
                    (addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_UNLOCK}));

    assign data_tag_o = (addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i != reservation_addr);

    assign data_o = sel_i == 4'b0001 ? (addr_i[0] == 0 ? ram_data_o[7:0] : ram_data_o[15:8]) : ram_data_o;

    logic [31:0] reservation_addr;
    //==================================================================================================================
    // Memory bus
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            reservation_addr <= `INVALID_ADDR;
            sync_ack <= 1'b0;
        end else begin
            sync_ack <= sync_ack ? stb_i : cyc_i & stb_i & we_i &
                            ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && (addr_i != reservation_addr));

            if (cyc_i & stb_i & (sync_ack | ram_ack_i)) begin
                (* parallel_case, full_case *)
                case (addr_tag_i[2:1])
                    `ADDR_TAG_MODE_NONE: begin
                        /*
                         * Invalidate the reservation if a regular store instruction writes to the reservation address.
                         */
                        if (we_i & addr_i == reservation_addr) reservation_addr <= `INVALID_ADDR;
                    end

                    `ADDR_TAG_MODE_LRSC: begin
                        if (~we_i & (addr_tag_i[0] == `ADDR_TAG_LOCK)) begin
`ifdef D_RAM_BUS
                            $display($time, " RAM_BUS:    >>>> Register reservation @[%h]", addr_i);
`endif
                            // Register the reservation for lr.w
                            reservation_addr <= addr_i;
                        end else if (we_i & (addr_tag_i[0] == `ADDR_TAG_UNLOCK)) begin
                            /*
                             * Validate the reservation for sc.w. ram_cyc_o and ram_stb_o stay low and sync_ack
                             * is set above.
                             */
`ifdef D_RAM_BUS
                            $display($time, " RAM_BUS:    <<<< Valid reservation: %h; release reservation @[%h]",
                                        addr_i == reservation_addr, addr_i);
`endif
                            /*
                             * Regardless of success or failure, executing an sc.w instruction invalidates any
                             * reservation held by this hart.
                             */
                            reservation_addr <= `INVALID_ADDR;
                        end
                    end

                    `ADDR_TAG_MODE_AMO: begin
                        if (~we_i & (addr_tag_i[0] == `ADDR_TAG_LOCK)) begin
                            if (reservation_addr == `INVALID_ADDR) begin
`ifdef D_RAM_BUS
                                $display($time, " RAM_BUS:    >>>> AMO lock @[%h]", addr_i);
`endif
                                reservation_addr <= addr_i;
                            end else begin
                                // Wait until the address is unlocked.
                            end
                        end else if (we_i & (addr_tag_i[0] == `ADDR_TAG_UNLOCK)) begin
`ifdef D_RAM_BUS
                            $display($time, " RAM_BUS:    >>>> AMO unlock @[%h]", addr_i);
`endif
                            reservation_addr <= `INVALID_ADDR;
                        end
                    end

                    default: begin
                        // This is an invalid case
                        reservation_addr <= `INVALID_ADDR;
                    end
                endcase
            end
        end
    end
endmodule
