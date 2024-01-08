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
 * Values defining interrupt sources and synchronous exceptions.
 **********************************************************************************************************************/
`define IRQ_SOFTWARE        32'h0000_0003
`define IRQ_TIMER           32'h0000_0007
`define IRQ_EXTERNAL        32'h0000_000b

// Interrupt codes (for use in mcause)
`define IRQ_CODE_SOFTWARE   32'h8000_0003
`define IRQ_CODE_TIMER      32'h8000_0007
`define IRQ_CODE_EXTERNAL   32'h8000_000b

// Synchronous exception codes
`define EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED  32'h0000_0000
`define EX_CODE_INSTRUCTION_ACCESS_FAULT        32'h0000_0001
`define EX_CODE_ILLEGAL_INSTRUCTION             32'h0000_0002
`define EX_CODE_BREAKPOINT                      32'h0000_0003
`define EX_CODE_LOAD_ADDRESS_MISALIGNED         32'h0000_0004
`define EX_CODE_LOAD_ACCESS_FAULT               32'h0000_0005
`define EX_CODE_STORE_ADDRESS_MISALIGNED        32'h0000_0006
`define EX_CODE_STORE_ACCESS_FAULT              32'h0000_0007
`define EX_CODE_ECALL                           32'h0000_0008
