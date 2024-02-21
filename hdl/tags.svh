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
 * This module defines tags for the Wishbone interface.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

/* The number of bits used. This define is used for the tag variable bits. */
`define ADDR_TAG_BITS           3
/* All bits are off */
`define ADDR_TAG_NONE           3'b000

/* Bit 0 of the address tag signifies an access to CSR registers. Only CSR instructions set this bit. */
`define ADDR_TAG_CSR_INSTR      3'b001

/* Bit 1 and 2 of the address tag define the type of locking/reservation to be used in a R/W operation. */
`define ADDR_TAG_MODE_LRSC      3'b010
`define ADDR_TAG_MODE_AMO       3'b100
/* This mask selects only the two mode flags above. */
`define ADDR_TAG_MODE_MASK      3'b110
