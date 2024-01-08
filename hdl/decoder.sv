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
 *  The RISC V instr_i decoder supports the following types of instr_is:
 *      1. RV32I 2.1 specification base instr_i set
 *      2. RV32M 2.0 The M (multiply/divide) extension
 *      3. RV32C 2.0 The C (compression) extension
 *      3. Zicsr 2.0 extension
 *
 * clk_i                -- The clock signal.
 * rst_i                -- Reset active high.
 * stb_i                -- The transaction starts on the posedge of this signal.
 * cyc_i                -- This signal is asserted for the duration of a cycle (same as stb_i).
 * instr_i              -- The 16/32 bit instr_i to be decoded.
 * instr_op_type_o      -- The decoded instruction type.
 * instr_op_rd_o        -- Destination register for applicable instructions.
 * instr_op_rs1_o       -- Source register 1 for applicable instructions.
 * instr_op_rs2_o       -- Source register 2 for applicable instructions.
 * instr_op_imm_o       -- The immediate value for applicable instructions.
 * instr_load_rs1_rs2_o -- 1'b1 if rs1 and/or rs2 need to be loaded from the regfile; 1'b0 otherwise.
 * ack_o                -- The transaction completes successfully on the posedge of this signal.
 * err_o                -- The transaction completes with an error on the posedge of this signal.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "instructions.svh"

module decoder (
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [31:0] instr_i,
    output logic [6:0] instr_op_type_o,
    output logic [4:0] instr_op_rd_o,
    output logic [4:0] instr_op_rs1_o,
    output logic [4:0] instr_op_rs2_o,
    output logic [31:0] instr_op_imm_o,
    output logic instr_load_rs1_rs2_o,
    output logic ack_o,
    output logic err_o);

    // Negate the ack_o as soon as the stb_i is deactivated.
    logic sync_ack_o = 1'b0;
    assign ack_o = sync_ack_o & stb_i;
    // Negate the err_o as soon as the stb_i is deactivated.
    logic sync_err_o = 1'b0;
    assign err_o = sync_err_o & stb_i;

    //==================================================================================================================
    // Decoder
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            {sync_ack_o, sync_err_o} <= 2'b00;
        end else begin
            if (sync_ack_o) sync_ack_o <= stb_i;
            if (sync_err_o) sync_err_o <= stb_i;

            if (stb_i & cyc_i & ~sync_ack_o & ~sync_err_o) begin
                // Assume success and set {sync_ack_o, sync_err_o} <= 2'b01 below if a decode error is encountered.
                {sync_ack_o, sync_err_o} <= 2'b10;
`ifdef ENABLE_RV32C_EXT
                decode_compressed_task;
`else // RV32C not supported
                decode_uncompressed_task;
`endif
            end
        end
    end

    //==================================================================================================================
    // Decode uncompressed instr_is
    //==================================================================================================================
    task decode_uncompressed_task;
        (* parallel_case, full_case *)
        case (instr_i[6:0])
            7'b1100011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_BEQ;
                    3'b001: instr_op_type_o <= `INSTR_TYPE_BNE;
                    3'b100: instr_op_type_o <= `INSTR_TYPE_BLT;
                    3'b101: instr_op_type_o <= `INSTR_TYPE_BGE;
                    3'b110: instr_op_type_o <= `INSTR_TYPE_BLTU;
                    3'b111: instr_op_type_o <= `INSTR_TYPE_BGEU;
                    default:instr_op_type_o <= {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= 0;
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_rs2_o <= instr_i[24:20];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b0000011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_LB;
                    3'b001: instr_op_type_o <= `INSTR_TYPE_LH;
                    3'b010: instr_op_type_o <= `INSTR_TYPE_LW;
                    3'b100: instr_op_type_o <= `INSTR_TYPE_LBU;
                    3'b101: instr_op_type_o <= `INSTR_TYPE_LHU;
                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= instr_i[11:7];
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[30:20]};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b0100011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_SB;
                    3'b001: instr_op_type_o <= `INSTR_TYPE_SH;
                    3'b010: instr_op_type_o <= `INSTR_TYPE_SW;
                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= 0;
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_rs2_o <= instr_i[24:20];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[30:25], instr_i[11:7]};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b0010011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_ADDI;
                    3'b010: instr_op_type_o <= `INSTR_TYPE_SLTI;
                    3'b011: instr_op_type_o <= `INSTR_TYPE_SLTIU;
                    3'b100: instr_op_type_o <= `INSTR_TYPE_XORI;
                    3'b110: instr_op_type_o <= `INSTR_TYPE_ORI;
                    3'b111: instr_op_type_o <= `INSTR_TYPE_ANDI;

                    3'b001: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SLLI;
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b101: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SRLI;
                            7'b0100000: instr_op_type_o <= `INSTR_TYPE_SRAI;
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= instr_i[11:7];
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[30:20]};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b0110011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_ADD;
                            7'b0100000: instr_op_type_o <= `INSTR_TYPE_SUB;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_MUL;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b001: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SLL;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_MULH;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b010: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SLT;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_MULHSU;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b011: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SLTU;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_MULHU;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b100: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_XOR;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_DIV;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b101: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_SRL;
                            7'b0100000: instr_op_type_o <= `INSTR_TYPE_SRA;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_DIVU;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b110: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_OR;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_REM;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end

                    3'b111: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:25])
                            7'b0000000: instr_op_type_o <= `INSTR_TYPE_AND;
`ifdef ENABLE_RV32M_EXT
                            7'b0000001: instr_op_type_o <= `INSTR_TYPE_REMU;
`endif
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase
                    end
                endcase

                instr_op_rd_o <= instr_i[11:7];
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_rs2_o <= instr_i[24:20];
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b1110011: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: begin
                        (* parallel_case, full_case *)
                        case (instr_i[31:20])
                            12'b0000000_00000: instr_op_type_o <= `INSTR_TYPE_ECALL;
                            12'b0000000_00001: instr_op_type_o <= `INSTR_TYPE_EBREAK;
                            12'b0011000_00010: instr_op_type_o <= `INSTR_TYPE_MRET;
                            12'b0001000_00101: instr_op_type_o <= `INSTR_TYPE_WFI;
                            default: {sync_ack_o, sync_err_o} <= 2'b01;
                        endcase

                        instr_op_rd_o <= 0;
                        instr_load_rs1_rs2_o <= 1'b0;
                    end

`ifdef ENABLE_ZISCR_EXT
                    3'b001: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRW;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_op_imm_o <= instr_i[31:20];
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b010: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRS;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_op_imm_o <= instr_i[31:20];
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b011: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRC;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_op_imm_o <= instr_i[31:20];
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b101: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRWI;
                        instr_op_imm_o <= instr_i[31:20];
                        instr_op_rd_o <= instr_i[11:7];
                        // Use rs1 as a 5 bit immediate value
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_load_rs1_rs2_o <= 1'b0;
                    end

                    3'b110: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRSI;
                        instr_op_imm_o <= instr_i[31:20];
                        instr_op_rd_o <= instr_i[11:7];
                        // Use rs1 as a 5 bit immediate value
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_load_rs1_rs2_o <= 1'b0;
                    end

                    3'b111: begin
                        instr_op_type_o <= `INSTR_TYPE_CSRRCI;
                        instr_op_imm_o <= instr_i[31:20];
                        instr_op_rd_o <= instr_i[11:7];
                        // Use rs1 as a 5 bit immediate value
                        instr_op_rs1_o <= instr_i[19:15];
                        instr_load_rs1_rs2_o <= 1'b0;
                    end
`endif
                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase
            end

            7'b0110111: begin
                instr_op_type_o <= `INSTR_TYPE_LUI;
                instr_op_rd_o <= instr_i[11:7];
                instr_op_imm_o <= {instr_i[31:12], 12'b0};
                instr_load_rs1_rs2_o <= 1'b0;
            end

            7'b0010111: begin
                instr_op_type_o <= `INSTR_TYPE_AUIPC;
                instr_op_rd_o <= instr_i[11:7];
                instr_op_imm_o <= {instr_i[31:12], 12'b0};
                instr_load_rs1_rs2_o <= 1'b0;
            end

            7'b1101111: begin
                instr_op_type_o <= `INSTR_TYPE_JAL;
                instr_op_rd_o <= instr_i[11:7];
                {instr_op_imm_o[31:20], instr_op_imm_o[10:1], instr_op_imm_o[11], instr_op_imm_o[19:12], instr_op_imm_o[0] } <=
                    {{12{instr_i[31]}}, instr_i[30:12], 1'b0};
                instr_load_rs1_rs2_o <= 1'b0;
            end

            7'b1100111: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_JALR;
                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= instr_i[11:7];
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[30:20]};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            7'b0001111: begin
                (* parallel_case, full_case *)
                case (instr_i[14:12])
                    3'b000: instr_op_type_o <= `INSTR_TYPE_FENCE;
                    default: {sync_ack_o, sync_err_o} <= 2'b01;
                endcase

                instr_op_rd_o <= instr_i[11:7];
                instr_op_rs1_o <= instr_i[19:15];
                instr_op_imm_o <= {{21{instr_i[31]}}, instr_i[30:20]};
                instr_load_rs1_rs2_o <= 1'b1;
            end

            default: begin
                {sync_ack_o, sync_err_o} <= 2'b01;
            end
        endcase

    endtask
`ifdef ENABLE_RV32C_EXT

    //==================================================================================================================
    // Decode compressed instr_is
    //==================================================================================================================
    task decode_compressed_task;

        (* parallel_case, full_case *)
        case (instr_i[1:0])
            2'b00: begin // Quadrant 0
                (* parallel_case, full_case *)
                case (instr_i[15:13])
                    3'b000: begin // C.ADDI4SPN
                        instr_op_type_o <= `INSTR_TYPE_ADDI;
                        instr_op_rd_o <= {1'b1, instr_i[4:2]};
                        instr_op_rs1_o <= 2; //x2
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 2'b00};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b010: begin // C.LW
                        instr_op_type_o <= `INSTR_TYPE_LW;
                        instr_op_rd_o <= {1'b1, instr_i[4:2]};
                        instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {instr_i[5], instr_i[12:10], instr_i[6], 2'b00};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b110: begin // C.SW
                        instr_op_type_o <= `INSTR_TYPE_SW;
                        instr_op_rd_o <= 0;
                        instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                        instr_op_rs2_o <= {1'b1, instr_i[4:2]};
                        instr_op_imm_o <= {instr_i[5], instr_i[12:10], instr_i[6], 2'b00};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    default: begin
                        {sync_ack_o, sync_err_o} <= 2'b01;
                    end
                endcase
            end

            2'b01: begin // Quadrant 1
                (* parallel_case, full_case *)
                case (instr_i[15:13])
                    3'b000: begin
                        if (instr_i[11:7] == 0) begin // C.NOP
                            instr_op_type_o <= `INSTR_TYPE_ADDI;
                            instr_op_rd_o <= 0;
                            instr_op_rs1_o <= 0;
                            instr_op_rs2_o <= 0;
                            instr_op_imm_o <= 0;
                            instr_load_rs1_rs2_o <= 1'b0;
                        end else begin // C.ADDI
                            instr_op_type_o <= `INSTR_TYPE_ADDI;
                            instr_op_rd_o <= instr_i[11:7];
                            instr_op_rs1_o <= instr_i[11:7];
                            instr_op_rs2_o <= 0;
                            instr_op_imm_o <= {{27{instr_i[12]}}, instr_i[6:2]};
                            instr_load_rs1_rs2_o <= 1'b1;
                        end
                    end

                    3'b001: begin // C.JAL
                        instr_op_type_o <= `INSTR_TYPE_JAL;
                        instr_op_rd_o <= 1; // x1
                        instr_op_rs1_o <= 0;
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {{21{instr_i[12]}}, instr_i[8], instr_i[10:9], instr_i[6],
                            instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], 1'b0};
                        instr_load_rs1_rs2_o <= 1'b0;
                    end

                    3'b010: begin // C.LI
                        instr_op_type_o <= `INSTR_TYPE_ADDI;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= 0;
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {{27{instr_i[12]}}, instr_i[6:2]};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b011: begin
                        if (instr_i[11:7] == 2) begin // C.ADDI16SP
                            instr_op_type_o <= `INSTR_TYPE_ADDI;
                            instr_op_rd_o <= 2; // x2
                            instr_op_rs1_o <= 2; // x2
                            instr_op_rs2_o <= 0;
                            instr_op_imm_o <= {{23{instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2],
                                                instr_i[6], 4'b0000};
                            instr_load_rs1_rs2_o <= 1'b1;
                        end else begin // C.LUI
                            instr_op_type_o <= `INSTR_TYPE_LUI;
                            instr_op_rd_o <= instr_i[11:7];
                            instr_op_rs1_o <= 0;
                            instr_op_rs2_o <= 0;
                            instr_op_imm_o <= {{26{instr_i[12]}}, instr_i[6:2], 12'b0};
                            instr_load_rs1_rs2_o <= 1'b0;
                        end
                    end

                    3'b100: begin
                        (* parallel_case, full_case *)
                        case (instr_i[11:10])
                            2'b00: begin // C.SRLI
                                instr_op_type_o <= `INSTR_TYPE_SRLI;
                                instr_op_rd_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs2_o <= 0;
                                instr_op_imm_o <= {{27{instr_i[12]}}, instr_i[6:2]};
                                instr_load_rs1_rs2_o <= 1'b1;
                            end

                            2'b01: begin // C.SRAI
                                instr_op_type_o <= `INSTR_TYPE_SRAI;
                                instr_op_rd_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs2_o <= 0;
                                instr_op_imm_o <= {{27{instr_i[12]}}, instr_i[6:2]};
                                instr_load_rs1_rs2_o <= 1'b1;
                            end

                            2'b10: begin // C.ANDI
                                instr_op_type_o <= `INSTR_TYPE_ANDI;
                                instr_op_rd_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                                instr_op_rs2_o <= 0;
                                instr_op_imm_o <= {{27{instr_i[12]}}, instr_i[6:2]};
                                instr_load_rs1_rs2_o <= 1'b1;
                            end

                            default: begin //2'b11
                                if (instr_i[12:10] == 3'b011) begin // C.SUB, C.XOR, C.OR, C.AND
                                    (* parallel_case, full_case *)
                                    case (instr_i[6:5])
                                        2'b00: instr_op_type_o <= `INSTR_TYPE_SUB;
                                        2'b01: instr_op_type_o <= `INSTR_TYPE_XOR;
                                        2'b10: instr_op_type_o <= `INSTR_TYPE_OR;
                                        default: instr_op_type_o <= `INSTR_TYPE_AND;
                                    endcase

                                    instr_op_rd_o <= {1'b1, instr_i[9:7]};
                                    instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                                    instr_op_rs2_o <= {1'b1, instr_i[4:2]};
                                    instr_op_imm_o <= 0;
                                    instr_load_rs1_rs2_o <= 1'b1;
                                end else begin
                                    {sync_ack_o, sync_err_o} <= 2'b01;
                                end
                            end
                        endcase
                    end

                    3'b101: begin // C.J
                        instr_op_type_o <= `INSTR_TYPE_JAL;
                        instr_op_rd_o <= 0;
                        instr_op_rs1_o <= 0;
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {{21{instr_i[12]}}, instr_i[8], instr_i[10:9], instr_i[6],
                            instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], 1'b0};
                        instr_load_rs1_rs2_o <= 1'b0;
                    end

                    3'b110: begin // C.BEQZ
                        instr_op_type_o <= `INSTR_TYPE_BEQ;
                        instr_op_rd_o <= 0;
                        instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {{24{instr_i[12]}}, instr_i[6:5], instr_i[2],
                                        instr_i[11:10], instr_i[4:3], 1'b0};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b111: begin // C.BNEZ
                        instr_op_type_o <= `INSTR_TYPE_BNE;
                        instr_op_rd_o <= 0;
                        instr_op_rs1_o <= {1'b1, instr_i[9:7]};
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {{24{instr_i[12]}}, instr_i[6:5], instr_i[2], instr_i[11:10],
                                        instr_i[4:3], 1'b0};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    default: begin
                        {sync_ack_o, sync_err_o} <= 2'b01;
                    end
                endcase
            end

            2'b10: begin // Quadrant 2
                (* parallel_case, full_case *)
                case (instr_i[15:13])
                    3'b000: begin // C.SLLI
                        instr_op_type_o <= `INSTR_TYPE_SLLI;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= instr_i[11:7];
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {instr_i[12], instr_i[6:2]};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b010: begin // C.LWSP
                        instr_op_type_o <= `INSTR_TYPE_LW;
                        instr_op_rd_o <= instr_i[11:7];
                        instr_op_rs1_o <= 2; // x2
                        instr_op_rs2_o <= 0;
                        instr_op_imm_o <= {4'b0, instr_i[3:2], instr_i[12], instr_i[6:4], 2'b00};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    3'b100: begin
                        if (instr_i[12] == 0) begin
                            if (instr_i[6:2] == 0) begin  // C.JR
                                instr_op_type_o <= `INSTR_TYPE_JALR;
                                instr_op_rd_o <= 0;
                                instr_op_rs1_o <= instr_i[11:7];
                                instr_op_rs2_o <= 0;
                                instr_op_imm_o <= 0;
                                instr_load_rs1_rs2_o <= 1'b1;
                            end else begin //C.MV
                                instr_op_type_o <= `INSTR_TYPE_ADD;
                                instr_op_rd_o <= instr_i[11:7];
                                instr_op_rs1_o <= 0;
                                instr_op_rs2_o <= instr_i[6:2];
                                instr_op_imm_o <= 0;
                                instr_load_rs1_rs2_o <= 1'b1;
                            end
                        end else begin
                            if (instr_i[6:2] == 0) begin
                                if (instr_i[11:7] == 0) begin // C.EBREAK
                                    instr_op_type_o <= `INSTR_TYPE_EBREAK;
                                    instr_op_rd_o <= 0;
                                    instr_op_rs1_o <= 0;
                                    instr_op_rs2_o <= 0;
                                    instr_op_imm_o <= 0;
                                    instr_load_rs1_rs2_o <= 1'b0;
                                end else begin // C.JALR
                                    instr_op_type_o <= `INSTR_TYPE_JALR;
                                    instr_op_rd_o <= 1; // x1
                                    instr_op_rs1_o <= instr_i[11:7];
                                    instr_op_rs2_o <= 0;
                                    instr_op_imm_o <= 0;
                                    instr_load_rs1_rs2_o <= 1'b1;
                                end
                            end else begin // C.ADD
                                instr_op_type_o <= `INSTR_TYPE_ADD;
                                instr_op_rd_o <= instr_i[11:7];
                                instr_op_rs1_o <= instr_i[11:7];
                                instr_op_rs2_o <= instr_i[6:2];
                                instr_op_imm_o <= 0;
                                instr_load_rs1_rs2_o <= 1'b1;
                            end
                        end
                    end

                    3'b110: begin // C.SWSP
                        instr_op_type_o <= `INSTR_TYPE_SW;
                        instr_op_rd_o <= 0;
                        instr_op_rs1_o <= 2; // x2
                        instr_op_rs2_o <= instr_i[6:2];
                        instr_op_imm_o <= {4'b0, instr_i[8:7], instr_i[12:9], 2'b00};
                        instr_load_rs1_rs2_o <= 1'b1;
                    end

                    default: begin
                        {sync_ack_o, sync_err_o} <= 2'b01;
                    end
                endcase
            end

            default: begin // Quadrant 3 (uncompressed instr_is)
                decode_uncompressed_task;
            end
        endcase
    endtask
`endif //ENABLE_RV32C_EXT
endmodule
