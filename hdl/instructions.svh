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
 * The supported instructions are listed herein. The optional extension enable flags are set in sim.sh and fpga.sh:
 *
 * # ENABLE_RV32M_EXT:    Multiply and divide instructions support.
 * # ENABLE_RV32C_EXT:    Enables/disables support for handling compressed RISC-V instructions.
 * # ENABLE_RV32A_EXT:    Atomic instructions support.
 * # ENABLE_ZIFENCEI_EXT: Zifencei extension.
 * # ENABLE_ZICOND_EXT:   Conditional operations.
 * # ENABLE_ZBA_EXT, ENABLE_ZBB_EXT, ENABLE_ZBC_EXT, ENABLE_ZBS_EXT    : Bit manipulation extensions.
 **********************************************************************************************************************/
// RV32I instructions
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

// Zifencei extension
`ifdef ENABLE_ZIFENCEI_EXT
`define INSTR_TYPE_FENCE_I  7'd43
`endif

// Zicond extension
`ifdef ENABLE_ZICOND_EXT
`define INSTR_TYPE_ZERO_EQZ 7'd44
`define INSTR_TYPE_ZERO_NEZ 7'd45
`endif

// RV32M instructions
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

// Zicsr instructions
`define INSTR_TYPE_CSRRW    7'd58
`define INSTR_TYPE_CSRRS    7'd59
`define INSTR_TYPE_CSRRC    7'd60
`define INSTR_TYPE_CSRRWI   7'd61
`define INSTR_TYPE_CSRRSI   7'd62
`define INSTR_TYPE_CSRRCI   7'd63

// RV32A instructions
`ifdef ENABLE_RV32A_EXT
`define INSTR_TYPE_LR_W         7'd64
`define INSTR_TYPE_SC_W         7'd65
`define INSTR_TYPE_AMOSWAP_W    7'd66
`define INSTR_TYPE_AMOADD_W     7'd67
`define INSTR_TYPE_AMOXOR_W     7'd68
`define INSTR_TYPE_AMOAND_W     7'd69
`define INSTR_TYPE_AMOOR_W      7'd70
`define INSTR_TYPE_AMOMIN_W     7'd71
`define INSTR_TYPE_AMOMAX_W     7'd72
`define INSTR_TYPE_AMOMINU_W    7'd73
`define INSTR_TYPE_AMOMAXU_W    7'd74
`endif

// Zba instructions
`ifdef ENABLE_ZBA_EXT
`define INSTR_TYPE_SH1ADD   7'd75
`define INSTR_TYPE_SH2ADD   7'd76
`define INSTR_TYPE_SH3ADD   7'd77
`endif

// Zbb instructions
`ifdef ENABLE_ZBB_EXT
`define INSTR_TYPE_CLZ      7'd78
`define INSTR_TYPE_CPOP     7'd79
`define INSTR_TYPE_CTZ      7'd80
`define INSTR_TYPE_MAX      7'd81
`define INSTR_TYPE_MAXU     7'd82
`define INSTR_TYPE_MIN      7'd83
`define INSTR_TYPE_MINU     7'd84
`define INSTR_TYPE_ORC_B    7'd85
`define INSTR_TYPE_ORN      7'd86
`define INSTR_TYPE_REV8     7'd87
`define INSTR_TYPE_ROL      7'd88
`define INSTR_TYPE_ROR      7'd89
`define INSTR_TYPE_RORI     7'd90
`define INSTR_TYPE_SEXT_B   7'd91
`define INSTR_TYPE_SEXT_H   7'd92
`define INSTR_TYPE_XNOR     7'd93
`define INSTR_TYPE_ZEXT_H   7'd94
`endif

// Zbc instructions
`ifdef ENABLE_ZBC_EXT
`define INSTR_TYPE_CLMUL    7'd95
`define INSTR_TYPE_CLMULH   7'd96
`define INSTR_TYPE_CLMULR   7'd97
`endif

// Zbs instructions
`ifdef ENABLE_ZBS_EXT
`define INSTR_TYPE_BCLR     7'd98
`define INSTR_TYPE_BCLRI    7'd99
`define INSTR_TYPE_BEXT     7'd100
`define INSTR_TYPE_BEXTI    7'd101
`define INSTR_TYPE_BINV     7'd102
`define INSTR_TYPE_BINVI    7'd103
`define INSTR_TYPE_BSET     7'd104
`define INSTR_TYPE_BSETI    7'd105
`endif
