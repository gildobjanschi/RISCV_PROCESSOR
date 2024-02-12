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
 * This module implements the access to CSRs defined in the RISC-V Priviledged specification, interrupt handling
 * and High Performance Counters.
 *
 * clk_i                -- The clock signal
 * rst_i                -- Reset active high
 * addr_i               -- The address from where data is read/written
 * data_i               -- The input data to write
 * stb_i                -- The transaction starts on the posedge of this signal
 * cyc_i                -- This signal is asserted for the duration of a cycle (same as stb_i).
 * we_i                 -- 1 to write data, 0 to read.
 * ack_o                -- The transaction completes successfully on the posedge of this signal
 * err_o                -- The transaction completes with an error on the posedge of this signal
 * data_o               -- The data that was read
 * incr_event_counters_i-- bits indicating which event counters to increment
 * io_interrupts_i      -- IO interrupts
 * io_interrupts_o      -- Bit indicating that an IO interrupt which was raised by IO needs to be serviced.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "events.svh"
`include "csr.svh"
`include "traps.svh"
`include "memory_map.svh"

module csr (
    // Wishbone interface
    input logic clk_i,
    input logic rst_i,
    input logic [11:0] addr_i,
    input logic [31:0] data_i,
    input logic stb_i,
    input logic cyc_i,
    input logic we_i,
    output logic ack_o,
    output logic err_o,
    output logic [31:0] data_o,
    // Increment event counters
    input logic [31:0] incr_event_counters_i,
    // Interrupt that occured(from IO)
    input logic [31:0] io_interrupts_i,
    // Indicate (to the core) that there are interrupts which need to be serviced.
    output logic [31:0] io_interrupts_o);

    // The wishbone ack_o and err_o are cleared as soon as stb_i is cleared.
    logic sync_ack_o = 1'b0;
    assign ack_o = sync_ack_o & stb_i;

    logic sync_err_o = 1'b0;
    assign err_o = sync_err_o & stb_i;

    // Machine CSR registers
    logic [31:0] mie, mip, mstatus, mepc, mcause, mtvec, mtval, misa, mstatush, mcountinhibit, mscratch, mtinst;

    logic [31:0] incr_events;
`ifdef ENABLE_HPM_COUNTERS
    // Define the number of counters to implement
    localparam HPM_COUNT = 5'd15;  // number of counters + 3 (mcycle, reserved and minstret)
    logic [31:0] incr_event_counters_internal;
    assign incr_events = incr_event_counters_internal | incr_event_counters_i;
`else
    localparam HPM_COUNT = 5'd3;  // mcycle, reserved and minstret are always enabled
    assign incr_events = incr_event_counters_i;
`endif  // ENABLE_HPM_COUNTERS
    logic [63:0] mhpmcounter[0:HPM_COUNT-1];
    logic [31:0] mhpmevent  [0:HPM_COUNT-1];
    logic [ 4:0] i;

    logic [31:0] mtvec_base, mtvec_interrupt_external, mtvec_interrupt_software, mtvec_interrupt_timer;
`ifdef TEST_MODE
    logic [31:0] sscratch;
`endif
    // Hide interrupts from the core when interrupts are disabled and/or when an interrupt is processed to avoid
    // preemption.
    assign io_interrupts_o = mstatus[`MSTATUS_MIE_BIT] ? mip : 0;

    //==================================================================================================================
    // Machine CSR register operations
    //==================================================================================================================
    task csr_task;
        // The request succeeds unless an error occurs in the case default block.
        {sync_ack_o, sync_err_o} <= 2'b10;

`ifdef D_CSR
        if (~we_i) begin
            $display($time, " CSR: Read [%h]", addr_i);
        end else begin
            $display($time, " CSR: Write [%h]: %h", addr_i, data_i);
        end
`endif
        (* parallel_case, full_case *)
        case (addr_i)
            `CSR_MISA: begin  // misa (ISA and extensions)
                if (~we_i) data_o <= misa;
                else misa <= data_i;
            end

            `CSR_MTVEC: begin  // mtvec (Machine trap-handler) base address.
                /*
                 * The mtvec register must always be implemented, but can contain a read-only value.
                 *
                 * The lowest 2 bits represent the MODE. The highest 30 bits are the 4 byte align BASE address.
                 *
                 * When MODE=Direct (0), all traps into machine mode cause the pc to be set to the address in
                 * the BASE field.
                 *
                 * When MODE=Vectored (1), all synchronous exceptions into machine mode cause the pc to be set
                 * to the address in the BASE field, whereas interrupts cause the pc to be set to the address
                 * in the BASE field plus four times the interrupt cause number.
                 * For example, a machine-mode counter interrupt causes the pc to be set to BASE+0x1c.
                 */
                if (~we_i) begin
                    data_o <= mtvec;
                end else begin
                    mtvec <= data_i;
                    mtvec_base <= {data_i[31:2], 2'b0};

                    if (data_i[1:0] == 2'b00) begin
                        // Direct mode
`ifdef D_CORE
                        $display($time, " CSR:    Direct mode mtvec: @[%h].", data_i);
`endif
                    end else if (data_i[1:0] == 2'b01) begin
                        // Vectored
`ifdef D_CORE
                        $display($time, " CSR:    Vectored mode mtvec: @[%h].", data_i);
`endif
                        mtvec_interrupt_external <= {data_i[31:2], 2'b0} + 8'h2c;
                        mtvec_interrupt_software <= {data_i[31:2], 2'b0} + 8'h0c;
                        mtvec_interrupt_timer <= {data_i[31:2], 2'b0} + 8'h1c;
                    end
                end
            end

            `CSR_MIE: begin  // mie (Machine Interrupt Enable)
                if (~we_i) data_o <= mie;
                else mie <= data_i;
            end

            `CSR_MIP: begin  // mip (Machine Interrupt Pending)
                if (~we_i) data_o <= mip;
                else mip <= data_i;
            end

            `CSR_MSTATUS: begin  // mstatus (Machine Status Register)
                if (~we_i) data_o <= mstatus;
                else mstatus <= data_i;
            end

            `CSR_MSTATUSH: begin  // mstatush (Machine Status Register)
                if (~we_i) data_o <= mstatush;
                else mstatush <= data_i;
            end

            `CSR_MCOUNTINIHIBIT: begin  // mcountinhibit (Machine Counter-Inhibit)
                if (~we_i) data_o <= mcountinhibit;
                else mcountinhibit <= data_i;
            end

            `CSR_MSCRATCH: begin  // mscratch (Scratch register for machine trap handler)
                /*
                 * The mscratch register is an MXLEN-bit read/write register dedicated for use
                 * by machine mode. Typically, it is used to hold a pointer to a machine-mode hart-local
                 * context space and swapped with a user register upon entry to an M-mode trap handler.
                 */
                if (~we_i) data_o <= mscratch;
                else mscratch <= data_i;
            end

            `CSR_MEPC: begin  // mepc (Machine exception program counter)
                /*
                 * When a trap is taken into M-mode, mepc is written with the virtual address of the
                 * instruction that was interrupted or that encountered the exception.
                 */
                if (~we_i) data_o <= mepc;
                else mepc <= data_i;
            end

            `CSR_MCAUSE: begin  // mcause (Machine trap cause)
                /*
                 * When a trap is taken into M-mode, mcause is written with a code indicating the event that
                 * caused the trap.
                 */
                if (~we_i) data_o <= mcause;
                else mcause <= data_i;
            end

            `CSR_MTVAL: begin  // mtval (Machine bad address or instruction)
                /*
                 * The Interrupt bit in the mcause register is set if the trap was caused by an interrupt.
                 * The Exception Code field contains a code identifying the last exception or interrupt.
                 * The Exception Code is a WLRL field, so is only guaranteed to hold supported exception codes.
                 */
                if (~we_i) data_o <= mtval;
                else mtval <= data_i;
            end

            `CSR_MTINST: begin  // mtinst (Machine Trap Instruction Register)
                /*
                 * When a trap is taken into M-mode, mtinst is written with a value that, if nonzero,
                 * provides information about the instruction that trapped, to assist software in handling the trap.
                 */
                if (~we_i) data_o <= mtinst;
                else mtinst <= data_i;
            end

            `CSR_MCYCLE: begin  // mcycle (Machine cycle counter)
                /*
                 * The mcycle CSR counts the number of clock cycles executed by the processor core on
                 * which the hart is running.
                 */
                if (~we_i) data_o <= mhpmcounter[`EVENT_CYCLE][31:0];
                //              else mhpmcounter[`EVENT_CYCLE][31:0] <= data_i;
            end

            `CSR_MINSTRET: begin  // minstret (Machine instructions-retired counter)
                /*
                 * The minstret CSR counts the number of instructions the hart has retired.
                 */
                if (~we_i) data_o <= mhpmcounter[`EVENT_INSTRET][31:0];
                //              else mhpmcounter[`EVENT_INSTRET][31:0] <= data_i;
            end

`ifdef ENABLE_HPM_COUNTERS
            `CSR_MHPMEVENT3, `CSR_MHPMEVENT4, `CSR_MHPMEVENT5, `CSR_MHPMEVENT6, `CSR_MHPMEVENT7, `CSR_MHPMEVENT8,
            `CSR_MHPMEVENT9, `CSR_MHPMEVENT10, `CSR_MHPMEVENT11, `CSR_MHPMEVENT12, `CSR_MHPMEVENT13, `CSR_MHPMEVENT14,
            `CSR_MHPMEVENT15, `CSR_MHPMEVENT16, `CSR_MHPMEVENT17, `CSR_MHPMEVENT18, `CSR_MHPMEVENT19, `CSR_MHPMEVENT20,
            `CSR_MHPMEVENT21, `CSR_MHPMEVENT22, `CSR_MHPMEVENT23, `CSR_MHPMEVENT24, `CSR_MHPMEVENT25, `CSR_MHPMEVENT26,
            `CSR_MHPMEVENT27, `CSR_MHPMEVENT28, `CSR_MHPMEVENT29, `CSR_MHPMEVENT30, `CSR_MHPMEVENT31: begin
                if (~we_i) data_o <= mhpmevent[addr_i-`CSR_MHPMEVENT3+12'h3];
                //              else mhpmevent[addr_i - `CSR_MHPMEVENT3 + 12'h3] <= data_i;
            end

            `CSR_MHPMCOUNTER3, `CSR_MHPMCOUNTER4, `CSR_MHPMCOUNTER5, `CSR_MHPMCOUNTER6,
            `CSR_MHPMCOUNTER7, `CSR_MHPMCOUNTER8, `CSR_MHPMCOUNTER9, `CSR_MHPMCOUNTER10,
            `CSR_MHPMCOUNTER11, `CSR_MHPMCOUNTER12, `CSR_MHPMCOUNTER13, `CSR_MHPMCOUNTER14,
            `CSR_MHPMCOUNTER15, `CSR_MHPMCOUNTER16, `CSR_MHPMCOUNTER17, `CSR_MHPMCOUNTER18,
            `CSR_MHPMCOUNTER19, `CSR_MHPMCOUNTER20, `CSR_MHPMCOUNTER21, `CSR_MHPMCOUNTER22,
            `CSR_MHPMCOUNTER23, `CSR_MHPMCOUNTER24, `CSR_MHPMCOUNTER25, `CSR_MHPMCOUNTER26,
            `CSR_MHPMCOUNTER27, `CSR_MHPMCOUNTER28, `CSR_MHPMCOUNTER29, `CSR_MHPMCOUNTER30,
            `CSR_MHPMCOUNTER31: begin
                if (~we_i) data_o <= mhpmcounter[addr_i-`CSR_MHPMCOUNTER3+12'h3][31:0];
                //              else mhpmcounter[addr_i - `CSR_MHPMCOUNTER3 + 12'h3][31:0] <= data_i;
            end

            `CSR_MHPMCOUNTERH3, `CSR_MHPMCOUNTERH4, `CSR_MHPMCOUNTERH5, `CSR_MHPMCOUNTERH6,
            `CSR_MHPMCOUNTERH7, `CSR_MHPMCOUNTERH8, `CSR_MHPMCOUNTERH9, `CSR_MHPMCOUNTERH10,
            `CSR_MHPMCOUNTERH11, `CSR_MHPMCOUNTERH12, `CSR_MHPMCOUNTERH13, `CSR_MHPMCOUNTERH14,
            `CSR_MHPMCOUNTERH15, `CSR_MHPMCOUNTERH16, `CSR_MHPMCOUNTERH17, `CSR_MHPMCOUNTERH18,
            `CSR_MHPMCOUNTERH19, `CSR_MHPMCOUNTERH20, `CSR_MHPMCOUNTERH21, `CSR_MHPMCOUNTERH22,
            `CSR_MHPMCOUNTERH23, `CSR_MHPMCOUNTERH24, `CSR_MHPMCOUNTERH25, `CSR_MHPMCOUNTERH26,
            `CSR_MHPMCOUNTERH27, `CSR_MHPMCOUNTERH28, `CSR_MHPMCOUNTERH29, `CSR_MHPMCOUNTERH30,
            `CSR_MHPMCOUNTERH31: begin
                if (~we_i) data_o <= mhpmcounter[addr_i-`CSR_MHPMCOUNTERH3+12'h3][63:32];
                //              else mhpmcounter[addr_i - `CSR_MHPMCOUNTERH3 + 12'h3][63:32] <= data_i;
            end
`endif
            `CSR_MCYCLEH: begin  // mcycleh (Upper 32 bits of mcycle)
                if (~we_i) data_o <= mhpmcounter[`EVENT_CYCLE][63:32];
                //              else mhpmcounter[`EVENT_CYCLE][63:32] <= data_i;
            end

            `CSR_MINSTRETH: begin  // minstreth (Upper 32 bits of minstret. Read only)
                if (~we_i) data_o <= mhpmcounter[`EVENT_INSTRET][63:32];
                //              else mhpmcounter[`EVENT_INSTRET][63:32] <= data_i;
            end

            `CSR_MVENDORID, `CSR_MARCHID, `CRS_MIMPID, `CSR_MHARTID, `CSR_MCONFIGPTR, `CSR_MTVAL2: begin
                /*
                 * The mvendorid CSR is a 32-bit read-only register providing the JEDEC manufacturer ID of the
                 * provider of the core. This register must be readable in any implementation,
                 * but a value of 0 can be returned to indicate the field is not implemented or that this is a
                 * non-commercial implementation.
                 */
                /*
                 * The marchid CSR is an MXLEN-bit read-only register encoding the base microarchitecture of the
                 * hart. This register must be readable in any implementation, but a value of 0 can be returned
                 * to indicate the field is not implemented. The combination of mvendorid and marchid should
                 * uniquely identify the type of hart microarchitecture that is implemented.
                 */
                /*
                 * The mimpid CSR provides a unique encoding of the version of the processor implementation.
                 * This register must be readable in any implementation, but a value of 0 can be returned to
                 * indicate that the field is not implemented. The Implementation value should reflect the
                 * design of the RISC-V processor itself and not any surrounding system.
                 */
                /*
                 * The mhartid CSR is an MXLEN-bit read-only register containing the integer ID of the hardware
                 * thread running the code. This register must be readable in any implementation. Hart IDs might
                 * not necessarily be numbered contiguously in a multiprocessor system, but at least one hart
                 * must have a hart ID of zero. Hart IDs must be unique within the execution environment.
                 */
                /*
                 * mconfigptr is an MXLEN-bit read-only CSR, that holds the physical address of a configuration
                 * data structure. Software can traverse this data structure to discover information about the
                 * harts, the platform, and their configuration.
                 */
                /*
                 * When a trap is taken into M-mode, mtval2 is written with additional exception-specific
                 * information, alongside mtval, to assist software in handling the trap.
                 */
                if (~we_i) data_o <= 0;
            end

            `CSR_ENTER_TRAP: begin
                /*
                 * We assume that the core has written the mepc and mcause before issuing a read for the trap address.
                 * mtval is also written for exceptions.
                 */
                mstatus[`MSTATUS_MPIE_BIT] <= mstatus[`MSTATUS_MIE_BIT];
                // Interrupts are disabled to prevent preemption.
                mstatus[`MSTATUS_MIE_BIT] <= 1'b0;

                (* parallel_case, full_case *)
                case (mcause)
                    `IRQ_CODE_EXTERNAL: begin
`ifdef D_CORE
                        data_o = mtvec[1:0] == 2'b01 ? mtvec_interrupt_external : mtvec_base;
                        $display($time, " CSR: [%h]: === INTERRUPT_EXTERNAL @[%h] ===", mepc, data_o);
`else
                        data_o <= mtvec[1:0] == 2'b01 ? mtvec_interrupt_external : mtvec_base;
`endif
`ifdef ENABLE_HPM_COUNTERS
                        incr_event_counters_internal[`EVENT_EXTERNAL_INT] <= 1'b1;
`endif
                    end

                    `IRQ_CODE_SOFTWARE: begin
`ifdef D_CORE
                        data_o = mtvec[1:0] == 2'b01 ? mtvec_interrupt_software : mtvec_base;
                        $display($time, " CSR: [%h]: === INTERRUPT_SOFTWARE @[%h] ===", mepc, data_o);
`else
                        data_o <= mtvec[1:0] == 2'b01 ? mtvec_interrupt_software : mtvec_base;
`endif
                    end

                    `IRQ_CODE_TIMER: begin
`ifdef D_CORE
                        data_o = mtvec[1:0] == 2'b01 ? mtvec_interrupt_timer : mtvec_base;
                        $display($time, " CSR: [%h]: === INTERRUPT_TIMER @[%h] ===", mepc, data_o);
`else
                        data_o <= mtvec[1:0] == 2'b01 ? mtvec_interrupt_timer : mtvec_base;
`endif
`ifdef ENABLE_HPM_COUNTERS
                        incr_event_counters_internal[`EVENT_TIMER_INT] <= 1'b1;
`endif
                    end

                    `EX_CODE_BREAKPOINT: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Breakpoint exception ===", mepc);
`endif
                    end

                    `EX_CODE_INSTRUCTION_ACCESS_FAULT: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Instruction access fault exception @[%h] ===", mepc, mtval);
`endif
                    end

                    `EX_CODE_ILLEGAL_INSTRUCTION: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Illegal instruction exception: %h ===", mepc, mtval);
`endif
                    end

                    `EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Instruction address misaligned exception @[%h] ===", mepc,
                                mtval);
`endif
                    end

                    `EX_CODE_ECALL: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === ECALL ===", mepc);
`endif
                    end

                    `EX_CODE_LOAD_ACCESS_FAULT: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Load access fault exception @[%h] ===", mepc, mtval);
`endif
                    end

                    `EX_CODE_STORE_ACCESS_FAULT: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Store access fault exception @[%h] ===", mepc, mtval);
`endif
                    end

                    `EX_CODE_LOAD_ADDRESS_MISALIGNED: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Load address misaligned exception @[%h] ===", mepc, mtval);
`endif
                    end

                    `EX_CODE_STORE_ADDRESS_MISALIGNED: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Store address misaligned exception @[%h] ===", mepc, mtval);
`endif
                    end

                    default: begin
                        data_o <= mtvec_base;
`ifdef D_CORE
                        $display($time, " CSR: [%h]: === Unhandled exception mcause=%h. mtval=%h ===", mepc, mcause,
                                    mtval);
`endif
                    end
                endcase
            end

            `CSR_EXIT_TRAP: begin
`ifdef D_CORE
                $display($time, " CSR: [%h]: === Exit interrupt. ===", mepc);
`endif
                mstatus[`MSTATUS_MIE_BIT] <= mstatus[`MSTATUS_MPIE_BIT];
                mstatus[`MSTATUS_MPIE_BIT] <= 1'b1;
                data_o <= mepc;
            end

`ifdef TEST_MODE
            12'h140: begin  // sscratch (for tests)
                if (~we_i) data_o <= sscratch;
                else sscratch <= data_i;
            end
`endif  // TEST_MODE

            default: begin
`ifdef D_CORE
                $display($time, " CSR: register [%h] not supported", addr_i);
`endif  // D_CORE
                /* Attempts to access a non-existent CSR raise an illegal instruction exception */
                {sync_ack_o, sync_err_o} <= 2'b01;
            end
        endcase
    endtask

    //==================================================================================================================
    // Provide r/w access to machine registers
    //==================================================================================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            {sync_ack_o, sync_err_o} <= 2'b00;

            // All performance counters are enabled.
            mcountinhibit <= 0;

            /* XLEN = 32 [30:31] = 01 */
            /* RV32I: [8] = 1 */
            misa <= 32'b0100_0000_0000_0000_0000_0001_0000_0000;
            /*
             * The Extensions field encodes the presence of the standard extensions, with a single
             * bit per letter of the alphabet (bit 0 encodes presence of     extension “A” ,
             * bit 1 encodes presence of extension “B”, through to bit 25 which encodes “Z”).
             * The “I” bit will be set for RV32I, RV64I, RV128I base ISAs.
             * At reset, the Extensions field shall contain the maximal set of supported extensions,
             * and I shall be selected over E if both are available.
             */
`ifdef ENABLE_RV32A_EXT
            /* Atomic extension */
            misa[0] <= 1'b1;
`endif  // ENABLE_RV32A_EXT
`ifdef ENABLE_RV32C_EXT
            /* The Compression extension */
            misa[2] <= 1'b1;
`endif  // ENABLE_RV32C_EXT
`ifdef ENABLE_RV32M_EXT
            /* Integer Multiply/Divide extension */
            misa[12] <= 1'b1;
`endif  // ENABLE_RV32M_EXT

            /*
             * MBE controls whether non-instruction-fetch memory accesses made from M-mode
             * (assuming mstatus.MPRV=0) are little-endian (MBE=0) or big-endian (MBE=1).
             * MBE[5]   = 0;
             *
             * If S-mode is not supported, SBE is read-only = 0.
             * SBE[4]   = 0; // S-mode not supported
             *
             * The rest of the bits are WPRI.
             * At reset if little-endian memory accesses are supported, the mstatush field MBE is reset to 0.
             */
            mstatush <= 0;

            /*
             * WPRI[0]  = 0;
             *
             * SIE[1]   = 0; // S-mode not supported
             *
             * WPRI[2]  = 0;
             *
             * Global interrupt-enable bit MIE is provided for M-mode. On reset the mstatus fields MIE is reset to 0.
             * MIE[3]   = 0;
             *
             * WPRI[4]  = 0;
             *
             * SPIE[5]  = 0; // S-mode not supported
             *
             * UBE[6]   = 0; // U-mode is not supported
             *
             * The MPIE field of mstatus is written with the value of the MIE field at the time of the trap;
             * the MIE field of mstatus is cleared.
             * MPIE[7]  = 0;
             *
             * SPP[8]   = 0; // S-mode not supported
             *
             * VS[10:9] = 0; // Floating point not supported
             *
             * MPP[12:11] = 0; // Only M mode supported
             *
             * FS[14:13] = 0; // Floating point not supported
             * XS[16:15] = 0; // Floating point not supported
             *
             * MPRV[17] = 0; // U-mode is not supported
             *
             * SUM[18]  = 0; // S-mode not supported
             *
             * When MXR=0, only loads from pages marked readable will succeed.
             * When MXR=1, loads from pages marked either readable or executable (R=1 or X=1) will succeed.
             * MXR[19]  = 0;
             *
             * TVM[20]  = 0; // S-mode not supported
             *
             * TW[21]   = 0; // TW is read-only 0 when there are no modes less privileged than M.
             *
             * TSR[22]  = 0; // S-mode not supported
             *
             * The rest of the bits to 31 are WPRI.
             */
            mstatus <= 0;

            // All interrupts are disabled
            mie <= 0;

            // There are no pending interrupts
            mip <= 0;

            // Machine Exception Program Counter
            mepc <= 0;

            /*
             * The mcause values after reset have implementation-specific interpretation, but the value 0 should
             * be returned on implementations that do not distinguish different reset conditions. Implementations
             * that distinguish different reset conditions should only use 0 to indicate the most complete reset.
             */
            mcause <= 0;

            mtval <= 0;

            mscratch <= 0;
            mtinst <= 0;

            /*
             * We set the last two bits to indicate that mtvec was not set by the machine.
             * (0 = DIRECT mode, 1 = VECTORED mode, 2 and 3 are reserved.)
             */
            mtvec <= `INVALID_ADDR;
            mtvec_base <= `INVALID_ADDR;
            mtvec_interrupt_external <= `INVALID_ADDR;
            mtvec_interrupt_software <= `INVALID_ADDR;
            mtvec_interrupt_timer <= `INVALID_ADDR;

            mhpmevent[`EVENT_CYCLE] <= 1 << `EVENT_CYCLE;
            mhpmevent[`EVENT_RESERVED] <= 1 << `EVENT_RESERVED;
            mhpmevent[`EVENT_INSTRET] <= 1 << `EVENT_INSTRET;

`ifdef ENABLE_HPM_COUNTERS
            // Set the event IDs supported in HW. These can be removed and set as needed in code.
            mhpmevent[`EVENT_INSTR_FROM_ROM] <= 1 << `EVENT_INSTR_FROM_ROM;
            mhpmevent[`EVENT_INSTR_FROM_RAM] <= 1 << `EVENT_INSTR_FROM_RAM;
            mhpmevent[`EVENT_I_CACHE_HIT] <= 1 << `EVENT_I_CACHE_HIT;
            mhpmevent[`EVENT_LOAD_FROM_ROM] <= 1 << `EVENT_LOAD_FROM_ROM;
            mhpmevent[`EVENT_LOAD_FROM_RAM] <= 1 << `EVENT_LOAD_FROM_RAM;
            mhpmevent[`EVENT_STORE_TO_RAM] <= 1 << `EVENT_STORE_TO_RAM;
            mhpmevent[`EVENT_IO_LOAD] <= 1 << `EVENT_IO_LOAD;
            mhpmevent[`EVENT_IO_STORE] <= 1 << `EVENT_IO_STORE;
            mhpmevent[`EVENT_CSR_LOAD] <= 1 << `EVENT_CSR_LOAD;
            mhpmevent[`EVENT_CSR_STORE] <= 1 << `EVENT_CSR_STORE;
            mhpmevent[`EVENT_TIMER_INT] <= 1 << `EVENT_TIMER_INT;
            mhpmevent[`EVENT_EXTERNAL_INT] <= 1 << `EVENT_EXTERNAL_INT;

            for (i = `EVENT_EXTERNAL_INT + 1; i < HPM_COUNT; i = i + 1) begin
                mhpmevent[i] <= 0;
            end

            incr_event_counters_internal <= 0;
`endif

            // Reset the event counters
            for (i = 0; i < HPM_COUNT; i = i + 1) begin
                mhpmcounter[i] <= 0;
            end
        end else begin
`ifdef ENABLE_HPM_COUNTERS
            incr_event_counters_internal <= 0;
`endif
            // Cycle counter
            if (~mcountinhibit[`EVENT_CYCLE]) begin
                mhpmcounter[`EVENT_CYCLE] <= mhpmcounter[`EVENT_CYCLE] + 1;
            end

            // Increment event counters
            for (i = `EVENT_INSTRET; i < HPM_COUNT; i = i + 1) begin
                if (~mcountinhibit[i] & (mhpmevent[i][i] == incr_events[i])) begin
                    mhpmcounter[i] <= mhpmcounter[i] + 1;
                end
            end

            /*
             * Filter IO interrupts with the interrupt enable flag and specific interrupt enable flags.
             */
            if (mstatus[`MSTATUS_MIE_BIT]) begin
                // A new interrupt is pending if the interrupt type is enabled in mie.
                mip <= mip | (io_interrupts_i & mie);
`ifdef D_CORE
                if (|io_interrupts_i) begin
                    $display($time, " CSR: New interrupts: %h. Enabled: %h. Pending now: %h.", io_interrupts_i, mie,
                         mip | (io_interrupts_i & mie));
                end
`endif
            end

            // At the end of a transaction reset ack_o and err_o
            if (sync_ack_o) sync_ack_o <= stb_i;
            if (sync_err_o) sync_err_o <= stb_i;
            if (stb_i & cyc_i & ~ack_o & ~err_o) begin
                csr_task;
            end
        end
    end

endmodule
