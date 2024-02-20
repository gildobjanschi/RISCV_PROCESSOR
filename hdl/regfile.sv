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
 * 32-bit register file reads/writes to the 32 x 32-bit CPU registers of the RISC-V processor.
 *
 * If a read and a write occur in the same clock cycle the write transaction is handled first and the read
 * transaction remains pending until the next clock cycle.
 *
 * clk_i        -- The clock signal.
 * rst_i        -- Reset active high.
 * stb_read_i   -- Register(s) are read on the posedge of this signal.
 * op_rs1_i     -- The 5 bit index of the first register to read.
 * op_rs2_i     -- The 5 bit index of the second register to read.
 * ack_read_o   -- The register read transaction is complete on the posedge of this signal.
 * reg_rs1_o    -- The value of the first register.
 * reg_rs2_o    -- The value of the second register.
 * stb_write_i  -- The register is written on the posedge of this signal.
 * op_rd_i      -- The 5 bit index of the register to write.
 * reg_rd_i     -- The value of the register to write.
 * ack_write_o  -- The register write transaction is complete on the posedge of this signal.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

module regfile (
    input logic clk_i,
    input logic rst_i,
    // Read
    input logic stb_read_i,
    input logic [4:0] op_rs1_i,
    input logic [4:0] op_rs2_i,
    output logic ack_read_o,
    output logic [31:0] reg_rs1_o,
    output logic [31:0] reg_rs2_o,
    // Write
    input logic stb_write_i,
    input logic [4:0] op_rd_i,
    input logic [31:0] reg_rd_i,
    output logic ack_write_o);

    // The CPU registers
    (* syn_ramstyle="block_ram" *)
    logic [31:0] cpu_reg[0:31];

    logic stb_read_q;
    //==================================================================================================================
    // Read/write RISC V registers
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            cpu_reg[0] <= 0;

            ack_read_o <= 1'b0;
            ack_write_o <= 1'b0;
            stb_read_q <= 1'b1;
        end else begin
            if (ack_read_o) ack_read_o <= 1'b0;
            if (ack_write_o) ack_write_o <= 1'b0;
            if (stb_read_i) stb_read_q <= 1'b1;

            // Give priority to writes
            if (stb_write_i) begin
                if (op_rd_i) cpu_reg[op_rd_i] <= reg_rd_i;
                ack_write_o <= 1'b1;
            end else if (stb_read_i | stb_read_q) begin
                reg_rs1_o <= cpu_reg[op_rs1_i];
                reg_rs2_o <= cpu_reg[op_rs2_i];
                ack_read_o <= 1'b1;
                stb_read_q <= 1'b0;
            end
        end
    end
endmodule
