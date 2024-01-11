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
 * PSRAM simulator
 *
 * Blue Whale uses the IS66WVE4M16EBLL-70BLI PSRAM a 4 Meg x 16 PSRAM
 *
 * PSRAM wires
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

module sim_psram #(
    parameter [31:0] RAM_PHYSICAL_SIZE = 32'h0100_0000) (
    input logic psram_cen,
    input logic psram_wen,
    input logic psram_oen,
    input logic psram_lbn,
    input logic psram_ubn,
    input logic [21:0] psram_a,
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
    assign psram_cmd = {psram_cen, psram_wen, psram_oen};

    // Input/output 16-bit data bus
    logic [15:0] psram_d_i, psram_d_o;
    // .T = 0 -> pin is output; .T = 1 -> pin is input.
    TRELLIS_IO #(.DIR("BIDIR")) psram_d_io[15:0] (.B (psram_d), .I (psram_d_o), .T (psram_cmd == PSRAM_CMD_WRITE),
                                                    .O (psram_d_i));

    // RAM memory
    logic [15:0] ram[0:(RAM_PHYSICAL_SIZE/2)-1];

    logic [21:0] prev_psram_a = 0;
    //==================================================================================================================
    // PSRAM controller
    //==================================================================================================================
    always @(negedge psram_cen) begin
        case (psram_cmd)
            PSRAM_CMD_STANDBY: begin
                // NOP
            end

            PSRAM_CMD_WRITE: begin
                // Simulate the delays
                #70 prev_psram_a <= psram_a;

                (* parallel_case, full_case *)
                case ({psram_ubn, psram_lbn})
                    2'b00: begin
                        ram[psram_a] <= psram_d_i;
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Wr @[%h] LH: %h", psram_a, psram_d_i);
`endif
                    end

                    2'b10: begin
                        ram[psram_a][7:0] <= psram_d_i[7:0];
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Wr @[%h] L: %h", psram_a, psram_d_i[7:0]);
`endif
                    end

                    2'b01: begin
                        ram[psram_a][15:8] <= psram_d_i[15:8];
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Wr @[%h] H: %h", psram_a, psram_d_i[15:8]);
`endif
                    end

                    2'b11: begin
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Wr @[%h]: [???]", psram_a);
`endif
                    end
                endcase
            end

            PSRAM_CMD_READ: begin
                // Simulate the delays
                if (prev_psram_a[21:4] == psram_a[21:4]) begin
                    #25 prev_psram_a <= psram_a;
                end else begin
                    #70 prev_psram_a <= psram_a;
                end

                (* parallel_case, full_case *)
                case ({psram_ubn, psram_lbn})
                    2'b00: begin
                        psram_d_o = ram[psram_a];
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Rd @[%h] LH: %h", psram_a, psram_d_o);
`endif
                    end

                    2'b10: begin
                        psram_d_o[7:0] = ram[psram_a][7:0];
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Rd @[%h] L: %h", psram_a, psram_d_o[7:0]);
`endif
                    end

                    2'b01: begin
                        psram_d_o[15:8] = ram[psram_a][15:8];
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Rd @[%h] H: %h", psram_a, psram_d_o[15:8]);
`endif
                    end

                    2'b11: begin
`ifdef D_SIM_PSRAM
                        $display($time, " SIM_PSRAM: Rd @[%h] with UL = 11. [???]", psram_a);
`endif
                    end
                endcase
            end
        endcase

    end
endmodule
