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

//======================================================================================================================
// Metastability flip-flop
//======================================================================================================================
module DFF_META (input logic reset, input logic D, input logic clk, output logic Q, output logic Q_pulse);
    logic Q_pipe = 1'b0;
    always @(posedge clk) begin
        if (reset) begin
            Q <= 1'b0;
            Q_pipe <= 1'b0;
            Q_pulse <= 1'b0;
        end else begin
            Q_pipe <= D;
            Q <= Q_pipe;

            if (Q_pipe & ~Q) Q_pulse <= 1'b1;

            if (Q_pulse) Q_pulse <= 1'b0;
        end
    end
endmodule

//======================================================================================================================
// Request
//======================================================================================================================
module DFF_REQUEST (input logic reset, input logic clk, input logic request_begin, input logic request_end,
                        output logic request_pending);
    logic in_progress;
    assign request_pending = in_progress ? ~request_end : request_begin;

    always @(posedge clk) begin
        if (reset) begin
            in_progress <= 1'b0;
        end else if (request_begin) begin
            in_progress <= 1'b1;
        end else if (request_end) begin
            in_progress <= 1'b0;
        end
    end
endmodule

//======================================================================================================================
// Rotates amt bits of data to the right
//======================================================================================================================
module barrel_shifter_right (input logic [31:0] data, input logic [4:0] amt, output logic [31:0] out);
    logic [31:0] s0, s1, s2, s3;

    assign s0 = amt[0] ? {data[0], data[31:1]} : data;
    assign s1 = amt[1] ? {s0[1:0], s0[31:2]} : s0;
    assign s2 = amt[2] ? {s1[3:0], s1[31:4]} : s1;
    assign s3 = amt[3] ? {s2[7:0], s2[31:8]} : s2;
    assign out = amt[4] ? {s3[15:0], s3[31:16]} : s3;
endmodule

//======================================================================================================================
// Rotates amt bits of data to the left
//======================================================================================================================
module barrel_shifter_left (input logic [31:0] data, input logic [4:0] amt, output logic [31:0] out);
    logic [31:0] s0, s1, s2, s3;

    assign s0 = amt[0] ? {data[30:0], data[31]} : data;
    assign s1 = amt[1] ? {s0[29:0], s0[31:30]} : s0;
    assign s2 = amt[2] ? {s1[27:0], s1[31:28]} : s1;
    assign s3 = amt[3] ? {s2[23:0], s2[31:24]} : s2;
    assign out = amt[4] ? {s3[15:0], s3[31:16]} : s3;
endmodule

//======================================================================================================================
// Count leading zeros
//======================================================================================================================
module count_leading_zeros #(
    parameter W_IN = 32,
    parameter W_OUT = $clog2(W_IN)) (
    input wire  [W_IN-1:0] in,
    output wire [W_OUT-1:0] out);

    generate
    if (W_IN == 2) begin: base
        assign out = !in[1];
    end else begin: recurse
        wire [W_OUT-2:0] half_count;
        wire [W_IN / 2-1:0] lhs = in[W_IN / 2 +: W_IN / 2];
        wire [W_IN / 2-1:0] rhs = in[0        +: W_IN / 2];
        wire left_empty = ~|lhs;

        count_leading_zeros #(.W_IN (W_IN / 2)) inner (.in (left_empty ? rhs : lhs), .out (half_count));

        assign out = {left_empty, half_count};
    end
    endgenerate
endmodule

//======================================================================================================================
// Count trailing zeros
//======================================================================================================================
module count_trailing_zeros #(
    parameter W_IN = 32,
    parameter W_OUT = $clog2(W_IN)) (
    input wire  [W_IN-1:0] in,
    output wire [W_OUT-1:0] out);

    generate
    if (W_IN == 2) begin: base
        assign out = !in[0];
    end else begin: recurse
        wire [W_OUT-2:0] half_count;
        wire [W_IN / 2-1:0] lhs = in[W_IN / 2 +: W_IN / 2];
        wire [W_IN / 2-1:0] rhs = in[0        +: W_IN / 2];
        wire right_empty = ~|rhs;

        count_trailing_zeros #(.W_IN (W_IN / 2)) inner (.in (right_empty ? lhs : rhs), .out (half_count));

        assign out = {right_empty, half_count};
    end
    endgenerate
endmodule

