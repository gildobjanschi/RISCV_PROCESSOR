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
 * Supported instructions
 **********************************************************************************************************************/
// The base ISA set
`define INSTR_TYPE_LUI      7'd1
`define INSTR_TYPE_AUIPC    7'd2
`define INSTR_TYPE_JAL      7'd3
`define INSTR_TYPE_JALR     7'd4
`define INSTR_TYPE_BEQ      7'd5
`define INSTR_TYPE_BNE      7'd6
`define INSTR_TYPE_BLT      7'd7
`define INSTR_TYPE_BGE      7'd8
`define INSTR_TYPE_BLTU     7'd9
`define INSTR_TYPE_BGEU     7'd10
`define INSTR_TYPE_LB       7'd11
`define INSTR_TYPE_LH       7'd12
`define INSTR_TYPE_LW       7'd13
`define INSTR_TYPE_LBU      7'd14
`define INSTR_TYPE_LHU      7'd15
`define INSTR_TYPE_SB       7'd16
`define INSTR_TYPE_SH       7'd17
`define INSTR_TYPE_SW       7'd18
`define INSTR_TYPE_ADDI     7'd19
`define INSTR_TYPE_SLTI     7'd20
`define INSTR_TYPE_SLTIU    7'd21
`define INSTR_TYPE_XORI     7'd22
`define INSTR_TYPE_ORI      7'd23
`define INSTR_TYPE_ANDI     7'd24
`define INSTR_TYPE_SLLI     7'd25
`define INSTR_TYPE_SRLI     7'd26
`define INSTR_TYPE_SRAI     7'd27
`define INSTR_TYPE_ADD      7'd28
`define INSTR_TYPE_SUB      7'd29
`define INSTR_TYPE_SLL      7'd30
`define INSTR_TYPE_SLT      7'd31
`define INSTR_TYPE_SLTU     7'd32
`define INSTR_TYPE_XOR      7'd33
`define INSTR_TYPE_SRL      7'd34
`define INSTR_TYPE_SRA      7'd35
`define INSTR_TYPE_OR       7'd36
`define INSTR_TYPE_AND      7'd37
`define INSTR_TYPE_FENCE    7'd38
`define INSTR_TYPE_ECALL    7'd39
`define INSTR_TYPE_EBREAK   7'd40
`define INSTR_TYPE_MRET     7'd41
`define INSTR_TYPE_WFI      7'd42

// The RV32M extension
`ifdef ENABLE_RV32M_EXT
`define INSTR_TYPE_MUL      7'd50
`define INSTR_TYPE_MULH     7'd51
`define INSTR_TYPE_MULHSU   7'd52
`define INSTR_TYPE_MULHU    7'd53
`define INSTR_TYPE_DIV      7'd54
`define INSTR_TYPE_DIVU     7'd55
`define INSTR_TYPE_REM      7'd56
`define INSTR_TYPE_REMU     7'd57
`endif

// The Zicsr extension
`ifdef ENABLE_ZISCR_EXT
`define INSTR_TYPE_CSRRW    7'd58
`define INSTR_TYPE_CSRRS    7'd59
`define INSTR_TYPE_CSRRC    7'd60
`define INSTR_TYPE_CSRRWI   7'd61
`define INSTR_TYPE_CSRRSI   7'd62
`define INSTR_TYPE_CSRRCI   7'd63
`endif
