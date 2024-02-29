/***********************************************************************************************************************
 *  kianv harris multicycle RISC-V rv32im
 *
 *  copyright (c) 2022 hirosh dabui <hirosh@dabui.de>
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
 * Multiplication of two 32 bit numbers for MUL, MULH, MULHSU, MULHU instructions.
 *
 * This code is a modified version of the above mentioned implementation.
 *
 * clk_i            -- The clock signal.
 * rst_i            -- Reset active high.
 * stb_i            -- The transaction starts on the posedge of this signal.
 * cyc_i            -- This signal is asserted for the duration of a cycle (same as stb_i).
 * op_1_i           -- The first 32-bit operand.
 * op_1_is_signed_i -- 1'b1 if the first operand is to be treated as a signed number.
 * op_2_i           -- The second 32-bit operand.
 * op_2_is_signed_i -- 1'b1 if the second operand is to be treated as a signed number.
 * result_upper_i   -- 1'b1 if the upper 32-bits of the result are to be returned (0 for lower 32-bits).
 * result_o         -- The multiplication result.
 * ack_o            -- The transaction completes successfully on the posedge of this signal.
 **********************************************************************************************************************/
`ifdef ENABLE_RV32M_EXT
`timescale 1ns/1ns
`default_nettype none

module multiplier (
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [31:0] op_1_i,
    input logic op_1_is_signed_i,
    input logic [31:0] op_2_i,
    input logic op_2_is_signed_i,
    input logic result_upper_i,
    output logic [31:0] result_o,
    output logic ack_o);

    // Negate the ack_o as soon as the stb_i is deactivated.
    logic sync_ack_o = 1'b0;
    assign ack_o = sync_ack_o & stb_i;

    logic [63:0] result_t, int_r;
    logic [31:0] op_1_abs;
    logic [31:0] op_2_abs;
    logic [4:0] bit_index;

    // State machine
    localparam STATE_START      = 3'b000;
    localparam STATE_INT_R      = 3'b001;
    localparam STATE_MUL        = 3'b010;
    localparam STATE_FINALIZE   = 3'b011;
    localparam STATE_DONE       = 3'b100;
    logic [2:0] state_m;

    //==================================================================================================================
    // Multiplier
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_m <= STATE_START;
            sync_ack_o <= 1'b0;
        end else begin
            (* parallel_case, full_case *)
            case (state_m)
                STATE_START: begin
                    if (sync_ack_o) sync_ack_o <= stb_i;

                    if (stb_i & cyc_i & ~sync_ack_o) begin
                        op_1_abs <= (op_1_is_signed_i & op_1_i[31]) ? ~op_1_i + 1 : op_1_i;
                        op_2_abs <= (op_2_is_signed_i & op_2_i[31]) ? ~op_2_i + 1 : op_2_i;

                        bit_index <= 0;
                        result_t <= 0;
                        state_m <= STATE_INT_R;
                    end
                end

                STATE_INT_R: begin
                    int_r <= (op_1_abs & {32{op_2_abs[bit_index]}}) << bit_index;
                    state_m <= STATE_MUL;
                end

                STATE_MUL: begin
                    result_t <= result_t + int_r;
                    bit_index <= bit_index + 1;
                    if (&bit_index) begin
                        if ((op_1_i[31] & op_1_is_signed_i) ^ (op_2_i[31] & op_2_is_signed_i)) begin
                            state_m <= STATE_FINALIZE;
                        end else begin
                            state_m <= STATE_DONE;
                        end
                    end else begin
                        state_m <= STATE_INT_R;
                    end
                end

                STATE_FINALIZE: begin
                    result_t <= ~result_t + 1;
                    state_m <= STATE_DONE;
                end

                STATE_DONE: begin
                    result_o <= result_upper_i ? result_t[63:32] : result_t[31:0];

                    sync_ack_o <= 1'b1;
                    state_m <= STATE_START;
                end
            endcase
        end
    end

endmodule
`endif
