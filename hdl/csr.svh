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
 * Machine CSR register address definitions.
 *
 * DEBUG and TRACE registers are not supported.
 **********************************************************************************************************************/
`define CSR_MSTATUS         12'h300
`define CSR_MISA            12'h301

`define CSR_MIE             12'h304
`define CSR_MTVEC           12'h305
`define CSR_MSTATUSH        12'h310
`define CSR_MCOUNTINIHIBIT  12'h320

`ifdef ENABLE_ZIHPM_EXT
`define CSR_MHPMEVENT3      12'h323
`define CSR_MHPMEVENT4      12'h324
`define CSR_MHPMEVENT5      12'h325
`define CSR_MHPMEVENT6      12'h326
`define CSR_MHPMEVENT7      12'h327
`define CSR_MHPMEVENT8      12'h328
`define CSR_MHPMEVENT9      12'h329
`define CSR_MHPMEVENT10     12'h32a
`define CSR_MHPMEVENT11     12'h32b
`define CSR_MHPMEVENT12     12'h32c
`define CSR_MHPMEVENT13     12'h32d
`define CSR_MHPMEVENT14     12'h32e
`define CSR_MHPMEVENT15     12'h32f
`define CSR_MHPMEVENT16     12'h330
`define CSR_MHPMEVENT17     12'h331
`define CSR_MHPMEVENT18     12'h332
`define CSR_MHPMEVENT19     12'h333
`define CSR_MHPMEVENT20     12'h334
`define CSR_MHPMEVENT21     12'h335
`define CSR_MHPMEVENT22     12'h336
`define CSR_MHPMEVENT23     12'h337
`define CSR_MHPMEVENT24     12'h338
`define CSR_MHPMEVENT25     12'h339
`define CSR_MHPMEVENT26     12'h33a
`define CSR_MHPMEVENT27     12'h33b
`define CSR_MHPMEVENT28     12'h33c
`define CSR_MHPMEVENT29     12'h33d
`define CSR_MHPMEVENT30     12'h33e
`define CSR_MHPMEVENT31     12'h33f
`endif // ENABLE_ZIHPM_EXT

`define CSR_MSCRATCH        12'h340
`define CSR_MEPC            12'h341
`define CSR_MCAUSE          12'h342
`define CSR_MTVAL           12'h343
`define CSR_MIP             12'h344
`define CSR_MTINST          12'h34a
`define CSR_MTVAL2          12'h34b

`define CSR_MCYCLE          12'hb00
`define CSR_MINSTRET        12'hb02

`ifdef ENABLE_ZIHPM_EXT
`define CSR_MHPMCOUNTER3    12'hb03
`define CSR_MHPMCOUNTER4    12'hb04
`define CSR_MHPMCOUNTER5    12'hb05
`define CSR_MHPMCOUNTER6    12'hb06
`define CSR_MHPMCOUNTER7    12'hb07
`define CSR_MHPMCOUNTER8    12'hb08
`define CSR_MHPMCOUNTER9    12'hb09
`define CSR_MHPMCOUNTER10   12'hb0a
`define CSR_MHPMCOUNTER11   12'hb0b
`define CSR_MHPMCOUNTER12   12'hb0c
`define CSR_MHPMCOUNTER13   12'hb0d
`define CSR_MHPMCOUNTER14   12'hb0e
`define CSR_MHPMCOUNTER15   12'hb0f
`define CSR_MHPMCOUNTER16   12'hb10
`define CSR_MHPMCOUNTER17   12'hb11
`define CSR_MHPMCOUNTER18   12'hb12
`define CSR_MHPMCOUNTER19   12'hb13
`define CSR_MHPMCOUNTER20   12'hb14
`define CSR_MHPMCOUNTER21   12'hb15
`define CSR_MHPMCOUNTER22   12'hb16
`define CSR_MHPMCOUNTER23   12'hb17
`define CSR_MHPMCOUNTER24   12'hb18
`define CSR_MHPMCOUNTER25   12'hb19
`define CSR_MHPMCOUNTER26   12'hb1a
`define CSR_MHPMCOUNTER27   12'hb1b
`define CSR_MHPMCOUNTER28   12'hb1c
`define CSR_MHPMCOUNTER29   12'hb1d
`define CSR_MHPMCOUNTER30   12'hb1e
`define CSR_MHPMCOUNTER31   12'hb1f
`endif // ENABLE_ZIHPM_EXT

`define CSR_MCYCLEH         12'hb80
`define CSR_MINSTRETH       12'hb82

`ifdef ENABLE_ZIHPM_EXT
`define CSR_MHPMCOUNTERH3   12'hb83
`define CSR_MHPMCOUNTERH4   12'hb84
`define CSR_MHPMCOUNTERH5   12'hb85
`define CSR_MHPMCOUNTERH6   12'hb86
`define CSR_MHPMCOUNTERH7   12'hb87
`define CSR_MHPMCOUNTERH8   12'hb88
`define CSR_MHPMCOUNTERH9   12'hb89
`define CSR_MHPMCOUNTERH10  12'hb8a
`define CSR_MHPMCOUNTERH11  12'hb8b
`define CSR_MHPMCOUNTERH12  12'hb8c
`define CSR_MHPMCOUNTERH13  12'hb8d
`define CSR_MHPMCOUNTERH14  12'hb8e
`define CSR_MHPMCOUNTERH15  12'hb8f
`define CSR_MHPMCOUNTERH16  12'hb90
`define CSR_MHPMCOUNTERH17  12'hb91
`define CSR_MHPMCOUNTERH18  12'hb92
`define CSR_MHPMCOUNTERH19  12'hb93
`define CSR_MHPMCOUNTERH20  12'hb94
`define CSR_MHPMCOUNTERH21  12'hb95
`define CSR_MHPMCOUNTERH22  12'hb96
`define CSR_MHPMCOUNTERH23  12'hb97
`define CSR_MHPMCOUNTERH24  12'hb98
`define CSR_MHPMCOUNTERH25  12'hb99
`define CSR_MHPMCOUNTERH26  12'hb9a
`define CSR_MHPMCOUNTERH27  12'hb9b
`define CSR_MHPMCOUNTERH28  12'hb9c
`define CSR_MHPMCOUNTERH29  12'hb9d
`define CSR_MHPMCOUNTERH30  12'hb9e
`define CSR_MHPMCOUNTERH31  12'hb9f
`endif // ENABLE_ZIHPM_EXT

`define CSR_MVENDORID       12'hf11
`define CSR_MARCHID         12'hf12
`define CRS_MIMPID          12'hf13
`define CSR_MHARTID         12'hf14
`define CSR_MCONFIGPTR      12'hf15

// Custom CSR addresses for trap handling
`define CSR_ENTER_TRAP      12'hff0
`define CSR_EXIT_TRAP       12'hff1

// Bit indexes for the mstatus register
`define MSTATUS_MIE_BIT     3
`define MSTATUS_MPIE_BIT    7
