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
`ifdef ENABLE_RV32A_EXT
`include "tags.svh"
`endif

module io_bus #(
    parameter [31:0] CLK_PERIOD_NS = 20,
    parameter [31:0] TIMER_PERIOD_NS = 100) (
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [31:0] addr_i,
    input logic [2:0] addr_tag_i,
    input logic [31:0] data_i,
    input logic [3:0] sel_i,
    input logic we_i,
    output logic ack_o,
    output logic err_o,
    output logic [31:0] data_o,
    output logic data_tag_o,
    // IO clock
    input logic timer_clk_i,
    // Interrupts
    output logic [31:0] io_interrupts_o,
    // UART lines
    output logic uart_txd_o,    // FPGA output: TXD
    input logic uart_rxd_i,     // FPGA input: RXD
    // External interrupts
    input logic external_irq_i);

    io #(.CLK_PERIOD_NS(CLK_PERIOD_NS), .TIMER_PERIOD_NS(TIMER_PERIOD_NS)) io_m (
        // Wishbone interface
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .addr_i     (addr_i[23:0]),
        .data_i     (data_i),
`ifdef ENABLE_RV32A_EXT
        .stb_i      (io_stb_o),
        .cyc_i      (io_cyc_o),
`else
        .stb_i      (stb_i),
        .cyc_i      (cyc_i),
`endif
        .sel_i      (sel_i),
        .we_i       (we_i),
`ifdef ENABLE_RV32A_EXT
        .ack_o      (io_ack_i),
`else
        .ack_o      (ack_o),
`endif
        .err_o      (err_o),
        .data_o     (data_o),
        // IO clock
        .timer_clk_i    (timer_clk_i),
        // IO interrupts
        .io_interrupts_o(io_interrupts_o),
        // UART wires
        .uart_txd_o     (uart_txd_o),   // FPGA output: TXD
        .uart_rxd_i     (uart_rxd_i),   // FPGA input: RXD
        .external_irq_i (external_irq_i));

`ifdef ENABLE_RV32A_EXT
    logic io_ack_i;

    logic sync_ack = 1'b0;
    assign ack_o = (sync_ack | io_ack_i) & stb_i;

    // Control if transactions can start by gating the strobe and cycle of the IO.
    logic io_stb_o;
    assign io_stb_o = stb_i &&
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_NONE) ||
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_LRSC) && ~we_i) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i == reservation_addr)) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_LOCK}) && (addr_i != reservation_addr)) ||
                    (addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_UNLOCK}));

    logic io_cyc_o;
    assign io_cyc_o = cyc_i &&
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_NONE) ||
                    ((addr_tag_i[2:1] == `ADDR_TAG_MODE_LRSC) && ~we_i) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i == reservation_addr)) ||
                    ((addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_LOCK}) && (addr_i != reservation_addr)) ||
                    (addr_tag_i == {`ADDR_TAG_MODE_AMO, `ADDR_TAG_UNLOCK}));

    assign data_tag_o = (addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && we_i && (addr_i != reservation_addr);

    logic [31:0] reservation_addr;
    //==================================================================================================================
    // IO bus
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            reservation_addr <= `INVALID_ADDR;
            sync_ack <= 1'b0;
        end else begin
            sync_ack <= sync_ack ? stb_i : cyc_i & stb_i & we_i &
                            ((addr_tag_i == {`ADDR_TAG_MODE_LRSC, `ADDR_TAG_UNLOCK}) && (addr_i != reservation_addr));

            if (cyc_i & stb_i & (sync_ack | io_ack_i)) begin
                (* parallel_case, full_case *)
                case (addr_tag_i[2:1])
                    `ADDR_TAG_MODE_NONE: begin
                        /*
                         * Invalidate the reservation if a regular store instruction writes to the reservation address.
                         */
                        if (we_i && addr_i == reservation_addr) reservation_addr <= `INVALID_ADDR;
                    end

                    `ADDR_TAG_MODE_LRSC: begin
                        if (~we_i & (addr_tag_i[0] == `ADDR_TAG_LOCK)) begin
`ifdef D_IO_BUS
                            $display($time, " IO_BUS:    >>>> Register reservation @[%h]", addr_i);
`endif
                            // Register the reservation for lr.w
                            reservation_addr <= addr_i;
                        end else if (we_i & (addr_tag_i[0] == `ADDR_TAG_UNLOCK)) begin
                            /*
                             * Validate the reservation for sc.w. io_cyc_o and io_stb_o stay low and sync_ack
                             * is set above.
                             */
`ifdef D_IO_BUS
                            $display($time, " IO_BUS:    <<<< Valid reservation: %h; release reservation @[%h]",
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
`ifdef D_IO_BUS
                                $display($time, " IO_BUS:    >>>> AMO lock @[%h]", addr_i);
`endif
                                reservation_addr <= addr_i;
                            end else begin
                                // Wait until the address is unlocked.
                            end
                        end else if (we_i & (addr_tag_i[0] == `ADDR_TAG_UNLOCK)) begin
`ifdef D_IO_BUS
                            $display($time, " IO_BUS:    >>>> AMO unlock @[%h]", addr_i);
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
`endif // ENABLE_RV32A_EXT

endmodule
