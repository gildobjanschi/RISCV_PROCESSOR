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
 * RAM driver module for a PSRAM (IS66WVE4M16EBLL-70BLI) featuring a wishbone interface.
 *
 * clk_i    -- The clock signal.
 * rst_i    -- Reset active high.
 * stb_i    -- The transaction starts on the posedge of this signal.
 * cyc_i    -- This signal is asserted for the duration of a cycle.
 * sel_i    -- The number of bytes to r/w (1 -> 4'b0001, 2 -> 4'b0011, 3 -> 4'b0111 or 4 bytes -> 4'b1111).
 * we_i     -- 1'b1 to write data, 1'b0 to read.
 * addr_i   -- The address from where data is read/written.
 * data_i   -- The input data to write.
 * ack_o    -- The transaction is completed on the posedge of this signal.
 * data_o   -- The data that was read.
 * PSRAM wires
 **********************************************************************************************************************/
`timescale 1ns / 1ns
`default_nettype none

module psram #(parameter [31:0] CLK_PERIOD_NS = 20) (
    // Wishbone interface
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [3:0] sel_i,
    input logic we_i,
    input logic [21:0] addr_i,
    input logic [31:0] data_i,
    output logic ack_o,
    output logic [31:0] data_o,
    // PSRAM wires
    output logic psram_cen,
    output logic psram_wen,
    output logic psram_oen,
    output logic psram_lbn,
    output logic psram_ubn,
    output logic [21:0] psram_a,
    inout logic [15:0] psram_d);

    /*
     * ZZ# is tied to VDD
     *
     * Name (Function)                  CE#     WE#     OE#     ZZ#
     * PSRAM_CMD_STANDBY                H       X       X       H
     * PSRAM_CMD_READ                   L       H       L       H
     * PSRAM_CMD_WRITE                  L       L       X       H
     */

    /*
     * During standby, the device current consumption is reduced to the level necessary to
     * perform the DRAM refresh operation. Standby operation occurs when CE# and ZZ# are HIGH.
     * The device will enter a reduced power state upon completion of a READ or WRITE
     * operations when the address and control inputs remain static for an extended period of time.
     * This mode will continue until a change occurs to the address or control inputs.
     */
    localparam [2:0] PSRAM_CMD_STANDBY = 3'b111;
    /*
     * Asynchronous READ Mode Operation
     */
    localparam [2:0] PSRAM_CMD_READ = 3'b010;
    /*
     * Asynchronous WRITE Mode Operation
     */
    localparam [2:0] PSRAM_CMD_WRITE = 3'b001;

    // The command issued
    logic [2:0] psram_cmd;
    assign {psram_cen, psram_wen, psram_oen} = psram_cmd;

    // Input/output 16-bit data bus
    logic [15:0] psram_d_i, psram_d_o;
    // .T = 0 -> psram_d is output; .T = 1 -> psram_d is input.
    TRELLIS_IO #(.DIR("BIDIR")) psram_d_io[15:0] (.B(psram_d), .I(psram_d_o), .T(psram_cmd != PSRAM_CMD_WRITE),
                                                    .O(psram_d_i));

    // The wishbone ack_o is cleared as soon as stb_i is cleared.
    logic sync_ack_o = 1'b0;
    assign ack_o = sync_ack_o & stb_i;

    /* The duration of the read and/or write cycle */
    localparam [3:0] TWRC_CLKS = (70 / CLK_PERIOD_NS) + 1;

    // The state machines
    localparam [1:0] STATE_IDLE     = 2'b00;
    localparam [1:0] STATE_READ     = 2'b01;
    localparam [1:0] STATE_WRITE    = 2'b10;
    logic [1:0] state_m;

    logic [3:0] wait_clock_cycles;
    logic next_word;

    //==================================================================================================================
    // PSRAM controller
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            sync_ack_o <= 1'b0;
            /*
             * PSRAM products include an on-chip voltage sensor that is used to launch the power-up
             * initialization process. Initialization will load the CR with its default settings.
             * VDD and VDDQ must be applied simultaneously. When they reach a stable level above
             * VDD, the device will require 150μs to complete its self-initialization process.
             * During the initialization period, CE# should remain HIGH. When initialization is complete,
             * the device is ready for normal operation.
             */
            psram_cmd <= PSRAM_CMD_STANDBY;
            {psram_ubn, psram_lbn} <= 2'b11;
            next_word <= 1'b0;

            state_m <= STATE_IDLE;
        end else begin
            // At the end of a transaction reset sync_ack_o
            if (sync_ack_o) sync_ack_o <= stb_i;

            (* parallel_case, full_case *)
            case (state_m)
                STATE_IDLE: begin
                    if (stb_i & cyc_i & ~sync_ack_o) begin
                        {psram_ubn, psram_lbn} <= ~sel_i;

                        if (we_i) begin
                            if (sel_i[3]) begin
                                psram_d_o <= next_word ? data_i[31:16] : data_i[15:0];
                                psram_a <= next_word ? addr_i + 1 : addr_i;
                            end else begin
                                psram_d_o <= data_i[15:0];
                                psram_a <= addr_i;
                            end

                            psram_cmd <= PSRAM_CMD_WRITE;
                            state_m <= STATE_WRITE;
                        end else begin
                            if (sel_i[3]) begin
                                psram_a <= next_word ? addr_i + 1 : addr_i;
                            end else begin
                                psram_a <= addr_i;
                            end

                            psram_cmd <= PSRAM_CMD_READ;
                            state_m <= STATE_READ;
                        end

                        wait_clock_cycles <= TWRC_CLKS;
                    end
                end

                STATE_READ: begin
                    wait_clock_cycles <= wait_clock_cycles - 4'h1;
                    if (wait_clock_cycles == 4'h1) begin
                        if (sel_i[3]) begin
                            if (next_word) begin
                                data_o[31:16] <= psram_d_i;
                                sync_ack_o <= 1'b1;
                            end else begin
                                data_o[15:0] <= psram_d_i;
                            end

                            next_word <= ~next_word;
                        end else begin
                            data_o[15:0] <= psram_d_i;
                            sync_ack_o <= 1'b1;
                        end

                        psram_cmd <= PSRAM_CMD_STANDBY;
                        state_m <= STATE_IDLE;
                    end
                end

                STATE_WRITE: begin
                    wait_clock_cycles <= wait_clock_cycles - 4'h1;
                    if (wait_clock_cycles == 4'h1) begin
                        if (sel_i[3]) begin
                            if (next_word) sync_ack_o <= 1'b1;
                            next_word <= ~next_word;
                        end else begin
                            sync_ack_o <= 1'b1;
                        end

                        psram_cmd <= PSRAM_CMD_STANDBY;
                        state_m <= STATE_IDLE;
                    end
                end

                default: begin
                    // Invalid state machine
                    state_m <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
