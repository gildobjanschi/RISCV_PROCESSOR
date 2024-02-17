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
 * The bit indexes of events that are tracked by the machine performance counters. Up to 29 events can be defined.
 *
 * 'Instruction retired' is treated as special event to be counted in the code even though it is not counted by
 * one of the 29 performance counters. The machine uses a dedicated register (minstret) to count retired instructions.
 **********************************************************************************************************************/

`ifdef ENABLE_ZICNTR_EXT
`define EVENT_CYCLE             0
`define EVENT_TIME              1
`define EVENT_INSTRET           2
`endif // ENABLE_ZICNTR_EXT

`ifdef ENABLE_ZIHPM_EXT
// Performance events. Up to 29 can be defined.
`define EVENT_INSTR_FROM_ROM    3
`define EVENT_INSTR_FROM_RAM    4
`define EVENT_I_CACHE_HIT       5
`define EVENT_LOAD_FROM_ROM     6
`define EVENT_LOAD_FROM_RAM     7
`define EVENT_STORE_TO_RAM      8
`define EVENT_IO_LOAD           9
`define EVENT_IO_STORE          10
`define EVENT_CSR_LOAD          11
`define EVENT_CSR_STORE         12
`define EVENT_TIMER_INT         13
`define EVENT_EXTERNAL_INT      14
`endif // ENABLE_ZIHPM_EXT
