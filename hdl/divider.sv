/***********************************************************************************************************************
 *  ianv harris multicycle RISC-V rv32im
 *
 * Copyright (c) 2022 hirosh dabui <hirosh@dabui.de>
 *
 * Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby
 * granted, provided that the above copyright notice and this permission notice appear in all copies.
 *
 * The software is provided "as is" and the author disclaims all warranties with regard to this software including all
 * implied warranties of merchantability and fitness. In no event shall the author be liable for any special, direct,
 * indirect, or consequential damages or any damages whatsoever resulting from loss of use, data or profits,
 * whether in an action of contract, negligence or other tortious action, arising out of or in connection with the use
 * or performance of this software.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Division of two 32 bit numbers for DIV, DIVU, REM, REMU instructions.
 *
 * This code is a modified version of the above mentioned implementation.
 *
 * clk_i        -- The clock signal.
 * rst_i        -- Reset active high.
 * stb_i        -- The transaction starts on the posedge of this signal.
 * divident_i   -- The 32-bit number to divide.
 * divisor_i    -- The 32-bit number divisor_i,
 * is_signed_i  -- 1'b1 if the division is for signed numbers.
 * div_result_o -- The division result (for DIV and DIVU instructions).
 * rem_result_o -- The remainder result (for REM and REMU instructions).
 * ack_o        -- The transaction completes successfully on the posedge of this signal.
 **********************************************************************************************************************/
`ifdef ENABLE_RV32M_EXT
`timescale 1ns/1ns
`default_nettype none

module divider (
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic [31:0] divident_i,
    input logic [31:0] divisor_i,
    input logic is_signed_i,
    output logic [31:0] div_result_o,
    output logic [31:0] rem_result_o,
    output logic ack_o);

    // State machine
    localparam STATE_START  = 2'b00;
    localparam STATE_DIV    = 2'b01;
    localparam STATE_DONE   = 2'b10;
    logic [1:0] state_m;

    logic [4:0] bit_index;
    logic [31:0] divisor_i_abs;
    wire [31:0] div_result_o_next = {div_result_o[30:0], 1'b0};
    wire [31:0] rem_result_o_next = {rem_result_o[30:0], div_result_o[31]};
    wire [32:0] rem_result_o_sub_divident_i = rem_result_o_next - divisor_i_abs;

    //==================================================================================================================
    // Division
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            ack_o <= 1'b0;
            state_m <= STATE_START;
        end else begin
            (* parallel_case, full_case *)
            case (state_m)
                STATE_START: begin
                    ack_o <= 1'b0;

                    if (stb_i) begin
                        div_result_o <= is_signed_i & divident_i[31] ? ~divident_i + 1 : divident_i;
                        divisor_i_abs <= is_signed_i & divisor_i[31] ? ~divisor_i + 1 : divisor_i;
                        rem_result_o <= 0;

                        bit_index <= 0;
                        state_m <= STATE_DIV;
                    end
                end

                STATE_DIV: begin
                    bit_index <= bit_index + 1;
                    if (rem_result_o_sub_divident_i[32]) begin
                        rem_result_o <= rem_result_o_next;
                        div_result_o <= div_result_o_next;
                    end else begin
                        rem_result_o <= rem_result_o_sub_divident_i[31:0];
                        div_result_o <= div_result_o_next | 1'b1;
                    end

                    if (&bit_index) begin
                        state_m <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    div_result_o <= (is_signed_i & (divident_i[31] ^ divisor_i[31]) & |divisor_i) ?
                                                                    ~div_result_o + 1 : div_result_o;
                    rem_result_o <= (is_signed_i & divident_i[31]) ? ~rem_result_o + 1 : rem_result_o;

                    ack_o <= 1'b1;
                    state_m <= STATE_START;
                end
            endcase
        end
    end

endmodule
`endif
