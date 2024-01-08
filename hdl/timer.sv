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
 * This module implements mtime, mtimecmp from the Priviledged specification. Read and writes to mtime and mtimecmp
 * are assumed to be 32-bit (sel_i = 4'b1111). The module also implements interrupts for the timer.
 * The clock that drives the module is using a using a wall clock friendly frequency (10MHz, 100MHz) therefore the
 * module operates asynchronous to the main clock module that drives it (the IO module).
 *
 * clk_i        -- The clock signal.
 * rst_i        -- Reset active high.
 * stb_i        -- The data read request on the posedge of this signal.
 * cyc_i        -- The data read request on the posedge of this signal (same as stb_i).
 * addr_i       -- The address from where data is read/written.
 * data_i       -- The input data to write.
 * we_i         -- 1 to write data, 0 to read.
 * ack_o        -- The data request is complete on the posedge of this signal.
 * data_o       -- The data that was read (aligned to the least significant byte).
 * clr_irq_i    -- Clear the interrupt.
 * interrupt_o  -- Signal that an interrupt has occured.
***********************************************************************************************************************/
`timescale 1ns / 1ns
`default_nettype none

module timer #(parameter [31:0] TIMER_PERIOD_NS = 100) (
    // Wishbone interface
    input logic clk_i,
    input logic rst_i,
    input logic stb_i,
    input logic cyc_i,
    input logic [23:0] addr_i,
    input logic [31:0] data_i,
    input logic we_i,
    output logic ack_o,
    output logic [31:0] data_o,
    // Interrupt
    input logic clr_irq_i,
    output logic interrupt_o);

    // The timer uses a different clock that the main clock.
    logic sync_rst_i, sync_stb_i, sync_cyc_i, sync_clr_irq_i_pulse;
    DFF_META dff_meta_rst (.reset(1'b0), .D(rst_i), .clk(clk_i), .Q(sync_rst_i));
    DFF_META dff_meta_stb (.reset(sync_rst_i), .D(stb_i), .clk(clk_i), .Q(sync_stb_i));
    DFF_META dff_meta_cyc (.reset(sync_rst_i), .D(cyc_i), .clk(clk_i), .Q(sync_cyc_i));
    DFF_META dff_meta_irq (.reset(sync_rst_i), .D(clr_irq_i), .clk(clk_i), .Q_pulse(sync_clr_irq_i_pulse));

    logic [63:0] mtime, mtimecmp;

    //==================================================================================================================
    // Timer
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            ack_o <= 1'b0;

            mtime <= 0;
            mtimecmp <= 64'hffff_ffff_ffff_ffff;

            interrupt_o <= 1'b0;
        end else begin
            if (ack_o) ack_o <= sync_stb_i;

            mtime <= mtime + 1;
            // The timer interrupt bit is cleared by the main clock domain.
            if (sync_clr_irq_i_pulse) begin
                interrupt_o <= 1'b0;
`ifdef D_TIMER_FINE
                $display($time, " TIMER: IRQ cleared");
`endif
            end else if (mtime >= mtimecmp) begin
                interrupt_o <= 1'b1;
                // Invalidate timecmp to avoid further triggering on the interrupt.
                mtimecmp <= 64'hffff_ffff_ffff_ffff;
`ifdef D_TIMER
                $display($time, " TIMER: Timer interrupt raised.");
`endif
            end

            if (sync_stb_i & sync_cyc_i & ~ack_o) begin
                (* parallel_case, full_case *)
                case (addr_i[23:0])
                    `IO_MTIME: begin
                        if (~we_i) begin
`ifdef D_TIMER
                            $display($time, " TIMER: Read from IO_MTIME -> %h", mtime[31:0]);
`endif
                            data_o <= mtime[31:0];
                        end else begin
`ifdef D_TIMER
                            $display($time, " TIMER: Write to IO_MTIME -> %h", data_i);
`endif
                        end
                    end

                    `IO_MTIMEH: begin
                        if (~we_i) begin
`ifdef D_TIMER
                            $display($time, " TIMER: Read from IO_MTIMEH -> %h", mtime[63:32]);
`endif
                            data_o <= mtime[63:32];
                        end else begin
`ifdef D_TIMER
                            $display($time, " TIMER: Write to IO_MTIMEH -> %h", data_i);
`endif
                        end
                    end

                    `IO_MTIMECMP: begin
                        if (~we_i) begin
`ifdef D_TIMER
                            $display($time, " TIMER: Read from IO_MTIMECMP -> %h", mtimecmp[31:0]);
`endif
                            data_o <= mtimecmp[31:0];
                        end else begin
`ifdef D_TIMER
                            $display($time, " TIMER: Write to IO_MTIMECMP -> %h", data_i);
`endif
                            /*
                             * The interrupt remains pending/posted until mtimecmp becomes greater than
                             * mtime (typically as a result of writing mtimecmp).
                             */
                            mtimecmp[31:0] <= data_i;
                        end
                    end

                    `IO_MTIMECMPH: begin
                        if (~we_i) begin
`ifdef D_TIMER
                            $display($time, " TIMER: Read from IO_MTIMECMPH -> %h", mtimecmp[63:32]);
`endif
                            data_o <= mtimecmp[63:32];
                        end else begin
`ifdef D_TIMER
                            $display($time, " TIMER: Write to IO_MTIMECMPH -> %h", data_i);
`endif
                            mtimecmp[63:32] <= data_i;
                        end
                    end

                    default begin
                        // We do not raise an error if the port does not exist.
`ifdef D_TIMER
                        if (we_i) begin
                            $display($time, " TIMER: Write to unknown address @[%h] -> %h", addr_i, data_i);
                        end else begin
                            $display($time, " TIMER: Read from unknown address @[%h]", addr_i);
                        end
`endif
                    end
                endcase

                ack_o <= 1'b1;
            end
        end
    end
endmodule
