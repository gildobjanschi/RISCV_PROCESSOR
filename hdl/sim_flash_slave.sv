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
 * This module simulates a slave SPI flash in SPI and quad SPI modes.
 *
 * The following datasheet applies: https://www.issi.com/WW/pdf/25LP-WP128F.pdf
 *
 * flash_csn            -- Flash chip select output.
 * flash_clk            -- Flash SPI clock output (conditioned device_clk).
 * flash_mosi           -- Flash MOSI and QSPI bit 0.
 * flash_miso           -- Flash MISO and QSPI bit 1.
 * flash_wpn            -- Flash WP and QSPI bit 2.
 * flash_holdn          -- Flash HOLD and QSPI bit 3.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

module sim_flash_slave #(
    parameter [31:0] FLASH_PHYSICAL_SIZE = 32'h0010_0000)(
    // SPI flash wires
    input logic flash_csn,
    input logic flash_clk,
    inout logic flash_mosi,
    inout logic flash_miso,
    inout logic flash_wpn,
    inout logic flash_holdn);

    //==================================================================================================================
    // Flash device pin direction
    //==================================================================================================================
    // Set to 1 to output data during master RX cycles; 0 during master TX cycles.
    logic sim_out_en = 1'b0;
    // Set to 1 when the device is in quad SPI (QPI) mode
    logic qpi_mode = 1'b0;

    logic IO0_o = 1'b1, IO1_o = 1'b1, IO2_o = 1'b1, IO3_o = 1'b1;
    logic IO0_i, IO1_i, IO2_i, IO3_i;

    // In SPI mode flash_mosi, flash_wpn and flash_holdn are input pins (1).
    // In QPI mode flash_mosi, flash_wpn and flash_holdn are input pins (1) if sim_out_en == 0.
    logic pin_0_2_3_dir;
    assign pin_0_2_3_dir = qpi_mode ? ~sim_out_en : 1'b1;

    // In SPI mode flash_miso is an output pin (0)
    // In QPI mode flash_miso is an output (0) if sim_out_en == 1.
    logic pin_1_dir;
    assign pin_1_dir = qpi_mode ? ~sim_out_en : 1'b0;

    // .T = 0 -> pin is output; .T = 1 -> pin is input.
    TRELLIS_IO #(.DIR("BIDIR")) B0 (.B (flash_mosi), .I (IO0_o), .T (pin_0_2_3_dir), .O (IO0_i));
    TRELLIS_IO #(.DIR("BIDIR")) B1 (.B (flash_miso), .I (IO1_o), .T (pin_1_dir), .O (IO1_i));
    TRELLIS_IO #(.DIR("BIDIR")) B2 (.B (flash_wpn), .I (IO2_o), .T (pin_0_2_3_dir), .O (IO2_i));
    TRELLIS_IO #(.DIR("BIDIR")) B3 (.B (flash_holdn), .I (IO3_o), .T (pin_0_2_3_dir), .O (IO3_i));

    //==================================================================================================================
    // SPI state machine
    //==================================================================================================================
    // Rx and Tx buffers
    localparam SPI_BUFFER_SIZE = 32;

    // Flash memory
    logic [7:0] flash[0:FLASH_PHYSICAL_SIZE - 1];

    //==================================================================================================================
    // Receiving data from the master
    //==================================================================================================================
    localparam [2:0] STATE_IDLE             = 3'b000;
    localparam [2:0] STATE_RX_COMMAND       = 3'b001;
    localparam [2:0] STATE_RX_ADDRESS       = 3'b010;
    localparam [2:0] STATE_DUMMY_CYCLES     = 3'b011;
    localparam [2:0] STATE_TX_DATA          = 3'b100;
    logic [2:0] state_m = STATE_RX_COMMAND;

    logic [SPI_BUFFER_SIZE-1:0] spi_rx_buffer;

    logic [5:0] spi_rx_bits = 0;
    logic [23:0] address_offset;
    logic [3:0] spi_dummy_cycles;
    logic tx = 1'b0;

    always @(negedge flash_clk or posedge flash_csn) begin
        if (flash_csn) begin
            state_m <= STATE_RX_COMMAND;
            spi_rx_bits <= 0;
            tx <= 1'b0;
        end else begin
            (* parallel_case, full_case *)
            case (state_m)
                STATE_IDLE: begin
                end

                STATE_RX_COMMAND: begin
                    if (qpi_mode) begin
                        spi_rx_buffer = {spi_rx_buffer[SPI_BUFFER_SIZE - 5 : 0], IO3_i, IO2_i, IO1_i, IO0_i};
                    end else begin
                        spi_rx_buffer = {spi_rx_buffer[SPI_BUFFER_SIZE - 2 : 0], IO0_i};
                    end

                    spi_rx_bits = spi_rx_bits + (qpi_mode ? 4 : 1);
                    if (spi_rx_bits == 8) begin
                        case (spi_rx_buffer[7:0])
                            8'h35: begin
                                // Switch to QPI mode
                                if (qpi_mode == 0) begin
`ifdef D_SIM_FLASH_SLAVE
                                    $display($time, " SFS: Switch to QPI mode command.");
`endif
                                    qpi_mode <= 1;
                                end else begin
                                    $display($time, " SFS:     --- Error: already in QPI mode. ---");
                                end
                                state_m <= STATE_IDLE;
                            end

                            8'hF5: begin
                                // Switch to SPI mode
                                if (qpi_mode) begin
`ifdef D_SIM_FLASH_SLAVE
                                    $display($time, " SFS: Switch to SPI mode command.");
`endif
                                    qpi_mode <= 0;
                                end else begin
                                    $display($time, " SFS:     --- Error: already in SPI mode. ---");
                                end
                                state_m <= STATE_IDLE;
                            end

                            8'h66: begin
`ifdef D_SIM_FLASH_SLAVE
                                $display($time, " SFS: Reset enable.");
`endif
                                state_m <= STATE_IDLE;
                            end

                            8'h99: begin
`ifdef D_SIM_FLASH_SLAVE
                                $display($time, " SFS: Reset.");
`endif
                                state_m <= STATE_IDLE;
                            end

                            8'h0B: begin
`ifdef D_SIM_FLASH_SLAVE_FINE
                                $display($time, " SFS: Fast read command.");
`endif
                                spi_rx_bits <= 0;
                                if (qpi_mode) begin
                                    spi_dummy_cycles <= 6;
                                //end else if (DEVICE_CLK_ABOVE_80_MHZ == 0) begin
                                //  spi_dummy_cycles <= 0;
                                end else begin
                                    spi_dummy_cycles <= 8;
                                end

                                state_m <= STATE_RX_ADDRESS;
                            end

                            8'h03: begin
                                // SPI read
`ifdef D_SIM_FLASH_SLAVE_FINE
                                $display($time, " SFS: Normal read command.");
`endif
                                spi_rx_bits <= 0;
                                state_m <= STATE_RX_ADDRESS;
                            end

                            default: begin
                                $display($time, " SFS:     --- Error: unsupported flash cmd %h. ---", spi_rx_buffer[7:0]);
                                state_m <= STATE_IDLE;
                                spi_rx_bits <= 0;
                            end
                        endcase
                    end
                end

                STATE_RX_ADDRESS: begin
                    if (qpi_mode) begin
                        spi_rx_buffer = {spi_rx_buffer[SPI_BUFFER_SIZE - 5 : 0], IO3_i, IO2_i, IO1_i, IO0_i};
                    end else begin
                        spi_rx_buffer = {spi_rx_buffer[SPI_BUFFER_SIZE - 2 : 0], IO0_i};
                    end

                    spi_rx_bits = spi_rx_bits + (qpi_mode ? 4 : 1);
                    if (spi_rx_bits == 24) begin
`ifdef D_SIM_FLASH_SLAVE
                        $display($time, " SFS: Address @[%h]", spi_rx_buffer[23:0]);
`endif
                        address_offset = spi_rx_buffer[23:0];

                        if (spi_dummy_cycles > 0) begin
                            state_m <= STATE_DUMMY_CYCLES;
                        end else begin
                            state_m <= STATE_TX_DATA;
                        end
                    end
                end

                STATE_DUMMY_CYCLES: begin
                    if (spi_dummy_cycles == 1) begin
                        state_m <= STATE_TX_DATA;
                    end else begin
                        spi_dummy_cycles <= spi_dummy_cycles - 1;
                    end
                end

                STATE_TX_DATA: begin
                    tx <= 1'b1;
                    state_m <= STATE_IDLE;
                end

                default: begin
                    // Invalid state machine
                end
            endcase
        end
    end

    //==================================================================================================================
    // Sending data to the master
    //==================================================================================================================
    logic [SPI_BUFFER_SIZE-1:0] spi_tx_buffer;
    logic [5:0] spi_tx_bits = 0;

    always @(posedge flash_clk or posedge flash_csn) begin
        if (flash_csn) begin
            sim_out_en <= 1'b0;
            spi_tx_bits = 0;
        end else if (tx) begin
            if (spi_tx_bits == 0) begin
                spi_tx_buffer[31:24] = flash[address_offset];
                spi_tx_buffer[23:16] = flash[address_offset + 1];
                spi_tx_buffer[15:8] = flash[address_offset + 2];
                spi_tx_buffer[7:0] = flash[address_offset + 3];
            end

            if (qpi_mode) begin
                sim_out_en <= 1'b1;
                {IO3_o, IO2_o, IO1_o, IO0_o} <= spi_tx_buffer[31:28];
                spi_tx_buffer <= {spi_tx_buffer[27:0], 4'b0};
            end else begin
                IO1_o <= spi_tx_buffer[31];
                spi_tx_buffer <= {spi_tx_buffer[30:0], 1'b0};
            end

            spi_tx_bits <= spi_tx_bits + (qpi_mode ? 4 : 1);
        end
    end
endmodule
