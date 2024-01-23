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
 * ROM
 * The maximum size of the bitstream is 5.5MB = 53EC60h. Rounded up to the start of the user space: 600000h.
 * The ROM size is 16MB (1000000h). The user size is: 1000000h - 600000h = a00000h
 *
 * RAM
 * ULX3S board: SDRAM is 16MB x 16 = 32MB. Size is 2000000h.
 * Blue Whale board: PSRAM is 4MB x 16 = 8MB
 **********************************************************************************************************************/
// This is the offset within the flash where app data can be stored
`define FLASH_OFFSET_ADDR   24'h60_0000

// Hardware memory map
`define ROM_BEGIN_ADDR  32'h0060_0000
`define ROM_SIZE        32'h00a0_0000

`define CSR_BEGIN_ADDR  32'h4000_0000
`define CSR_SIZE        32'h0000_1000

`define RAM_BEGIN_ADDR  32'h8000_0000
`ifdef BOARD_ULX3S
`define RAM_SIZE        32'h0200_0000
`else // BOARD_BLUE_WHALE
`define RAM_SIZE        32'h0080_0000
`endif // BOARD_ULX3S

`define IO_BEGIN_ADDR   32'hc000_0000
`define IO_SIZE         32'h0100_0000

/* Define a value that represens an invalid address within the memory map */
`define INVALID_ADDR    32'h1000_0000
