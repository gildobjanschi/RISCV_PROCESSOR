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
 * SDRAM simulator
 *
 * ULX3S uses the IS42S16160G-7 SDRAM a 16 Meg x 16 SDRAM (4 Meg x 16 x 4 banks)
 * Rows     :8192   A[12:0]
 * Columns  :512    A[8:0]
 * Banks    :4      BA[1:0]
 *
 * SDRAM wires  -- SDRAM signals
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

module sim_sdram #(
    parameter [31:0] RAM_PHYSICAL_SIZE = 32'h0100_0000) (
    input logic sdram_clk,
    input logic sdram_cke,
    input logic sdram_csn,
    input logic sdram_wen,
    input logic sdram_rasn,
    input logic sdram_casn,
    input logic [12:0] sdram_a,
    input logic [1:0] sdram_ba,
    input logic [1:0] sdram_dqm,
    inout logic [15:0] sdram_d);

    /*
     * Name (Function)                                          CS# RAS#    CAS#    WE#     DQM     ADDR        DQ
     * COMMAND INHIBIT (NOP)                                    H   X       X       X       X       X           X
     * NO OPERATION (NOP)                                       L   H       H       H       X       X           X
     * ACTIVE (select bank and activate row)                    L   L       H       H       X       Bank/row    X
     * READ (select bank and column, and start READ burst)      L   H       L       H       L/H     Bank/col    X
     * WRITE (select bank and column, and start WRITE burst)    L   H       L       L       L/H     Bank/col    Valid
     * BURST TERMINATE                                          L   H       H       L       X       X           Active
     * PRECHARGE (Deactivate row in bank or banks)              L   L       H       L       X       Code        X
     * AUTO REFRESH or SELF REFRESH                             L   L       L       H       X       X           X
     * LOAD MODE REGISTER                                       L   L       L       L       X       Op-code     X
     * Write enable/output enable                               X   X       X       X       L       X           Active
     * Write inhibit/output High-Z                              X   X       X       X       H       X           High-Z
     */

    /*
     * The COMMAND INHIBIT function prevents new commands from being executed by the device,
     * regardless of whether the CLK signal is enabled. The device is effectively deselected.
     */
    localparam [3:0] SDRAM_CMD_INHIBIT = 4'b1000;
    /*
     * The NO OPERATION (NOP) command is used to perform a NOP to the selected device (CS# is LOW).
     * This prevents unwanted commands from being registered during idle or wait states.
     * Operations already in progress are not affected.
     */
    localparam [3:0] SDRAM_CMD_NOP = 4'b0111;
    /*
     * The ACTIVE command is used to activate a row in a particular bank for a subsequent access.
     * The value on the BA0, BA1 inputs selects the bank, and the address provided selects the row.
     * This row remains active for accesses until a PRECHARGE command is issued to that bank.
     * A PRECHARGE command must be issued before opening a different row in the same bank.
     */
    localparam [3:0] SDRAM_CMD_ACTIVE = 4'b0011;
    /*
     * The READ command is used to initiate a burst read access to an active row.
     * The values on the BA0 and BA1 inputs select the bank; the address provided selects the
     * starting column location.
     */
    localparam [3:0] SDRAM_CMD_READ = 4'b0101;
    /*
     * The WRITE command is used to initiate a burst write access to an active row.
     * The values on the BA0 and BA1 inputs select the bank; the address provided selects the
     * starting column location.
     */
    localparam [3:0] SDRAM_CMD_WRITE = 4'b0100;
    /*
     * The PRECHARGE command is used to deactivate the open row in a particular bank
     * or the open row in all banks.
     */
    localparam [3:0] SDRAM_CMD_PRECHARGE = 4'b0010;
    /*
     * AUTO REFRESH (CKE = H) is used during normal operation of the SDRAM and is analogous to
     * CAS#-BEFORE-RAS# (CBR) refresh in conventional DRAMs.
     * This command is nonpersistent, so it must be issued each time a refresh is required.
     */
    localparam [3:0] SDRAM_CMD_REFRESH = 4'b0001;
    /*
     * The mode registers are loaded via inputs A[n:0] (where An is the most significant address term), BA0, and BA1.
     */
    localparam [3:0] SDRAM_CMD_LOAD_MODE_REGISTER = 4'b0000;

    // The command issued
    logic [3:0] sdram_cmd;
    assign sdram_cmd = {sdram_csn, sdram_rasn, sdram_casn, sdram_wen};

    // Input/output 16-bit data bus
    logic [15:0] sdram_d_i, sdram_d_o;
    // .T = 0 -> pin is output; .T = 1 -> pin is input.
    TRELLIS_IO #(.DIR("BIDIR")) sdram_d_io[15:0] (.B (sdram_d), .I (sdram_d_o), .T (sdram_cmd == SDRAM_CMD_WRITE),
                                                    .O (sdram_d_i));

    logic [14:0] activated_row_bank = 0;
    logic [23:0] address;

    // RAM memory
    logic [15:0] ram[0:(RAM_PHYSICAL_SIZE/2)-1];

    //==================================================================================================================
    // SDRAM controller
    //==================================================================================================================
    always @(posedge sdram_clk) begin
        (* parallel_case, full_case *)
        case (sdram_cmd)
            SDRAM_CMD_INHIBIT, SDRAM_CMD_NOP, SDRAM_CMD_PRECHARGE, SDRAM_CMD_REFRESH,
                    SDRAM_CMD_LOAD_MODE_REGISTER: begin
                // NOP
            end

            SDRAM_CMD_ACTIVE: begin
                /*
                 * The address bits registered coincident with the ACTIVE command are used to select
                 * the bank and row to be accessed (BA[1:0] select the bank; A[12:0] select the row).
                 * The row remains active for accesses until a PRECHARGE command is issued to that bank.
                 * A PRECHARGE command must be issued before opening a different row in the same bank.
                 */
                activated_row_bank[14:13] = sdram_ba;
                activated_row_bank[12:0] = sdram_a;
`ifdef D_SIM_SDRAM
                $display($time, " SIM_SDRAM: Active %h", activated_row_bank);
`endif
            end

            SDRAM_CMD_READ: begin
                address = {activated_row_bank, sdram_a[8:0]};
                (* parallel_case, full_case *)
                case (sdram_dqm)
                    2'b00: begin
                        sdram_d_o = ram[address];
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Rd @[%h] LH: %h", address, sdram_d_o);
`endif
                    end

                    2'b10: begin
                        sdram_d_o[7:0] = ram[address][7:0];
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Rd @[%h] L: %h", address, sdram_d_o[7:0]);
`endif
                    end

                    2'b01: begin
                        sdram_d_o[15:8] = ram[address][15:8];
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Rd @[%h] H: %h", address, sdram_d_o[15:8]);
`endif
                    end

                    2'b11: begin
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Rd @[%h] with DQM = 11. [???]", address);
`endif
                    end
                endcase
            end

            SDRAM_CMD_WRITE: begin
                address = {activated_row_bank, sdram_a[8:0]};
                (* parallel_case, full_case *)
                case (sdram_dqm)
                    2'b00: begin
                        ram[address] <= sdram_d_i;
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Wr @[%h] LH: %h", address, sdram_d_i);
`endif
                    end

                    2'b10: begin
                        ram[address][7:0] <= sdram_d_i[7:0];
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Wr @[%h] L: %h", address, sdram_d_i[7:0]);
`endif
                    end

                    2'b01: begin
                        ram[address][15:8] <= sdram_d_i[15:8];
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Wr @[%h] H: %h", address, sdram_d_i[15:8]);
`endif
                    end

                    2'b11: begin
`ifdef D_SIM_SDRAM
                        $display($time, " SIM_SDRAM: Wr @[%h]: [???]", address);
`endif
                    end
                endcase
            end

            default: begin
            end
        endcase
    end
endmodule
