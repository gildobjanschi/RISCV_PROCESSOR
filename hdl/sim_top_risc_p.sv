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
 * This is the top module for the pipelined RISC V simulator. It wraps the risc_p module and connects the
 * flash slave and the RAM simulator.
 **********************************************************************************************************************/
`timescale 1ns/1ns
`default_nettype none

`include "memory_map.svh"

module sim_top_risc_p;
    logic [7:0] led;
    logic [1:0] btn;
    logic external_irq;
    // Flash wires
    wire flash_csn;
    wire flash_clk;
    wire flash_mosi;
    wire flash_miso;
    wire flash_wpn;
    wire flash_holdn;
    // UART
    logic ftdi_rxd, ftdi_txd;
    assign ftdi_txd = ftdi_rxd;

`ifdef BOARD_ULX3S
    logic wifi_gpio0;
    // SDRAM wires
    wire sdram_clk;
    wire sdram_cke;
    wire sdram_csn;
    wire sdram_wen;
    wire sdram_rasn;
    wire sdram_casn;
    wire [12:0] sdram_a;
    wire [1:0] sdram_ba;
    wire [1:0] sdram_dqm;
    wire [15:0] sdram_d;
`else // BOARD_BLUE_WHALE
    wire [15:0] led_a;
    wire [15:0] led_b;
    // RAM wires
    wire psram_cen;
    wire psram_wen;
    wire psram_oen;
    wire psram_lbn;
    wire psram_ubn;
    wire [21:0] psram_a;
    wire [15:0] psram_d;
`endif // BOARD_ULX3S

    risc_p risc_p_m (
        .clk_in         (1'b0),
        .led            (led),
        .btn            (btn),
        // SPI flash wires
        .flash_csn      (flash_csn),
        .flash_clk      (flash_clk),
        .flash_mosi     (flash_mosi),
        .flash_miso     (flash_miso),
        .flash_wpn      (flash_wpn),
        .flash_holdn    (flash_holdn),
        // UART wires
        .ftdi_txd       (ftdi_txd), // FPGA output: TXD
        .ftdi_rxd       (ftdi_rxd), // FPGA input : RXD
        .external_irq   (external_irq),
`ifdef BOARD_ULX3S
        .wifi_gpio0     (wifi_gpio0),
        // RAM wires
        .sdram_clk      (sdram_clk),
        .sdram_cke      (sdram_cke),
        .sdram_csn      (sdram_csn),
        .sdram_wen      (sdram_wen),
        .sdram_rasn     (sdram_rasn),
        .sdram_casn     (sdram_casn),
        .sdram_a        (sdram_a),
        .sdram_ba       (sdram_ba),
        .sdram_dqm      (sdram_dqm),
        .sdram_d        (sdram_d)
`else // BOARD_BLUE_WHALE
        .led_a          (led_a),
        .led_b          (led_b),
        // RAM wires
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d)
`endif // BOARD_ULX3S
);

    sim_flash_slave #(.FLASH_PHYSICAL_SIZE(32'h0100_0000)) sim_flash_slave_m (
        .flash_csn      (flash_csn),
        .flash_clk      (flash_clk),
        .flash_mosi     (flash_mosi),
        .flash_miso     (flash_miso),
        .flash_wpn      (flash_wpn),
        .flash_holdn    (flash_holdn));

`ifdef BOARD_ULX3S
    sim_sdram #(.RAM_PHYSICAL_SIZE(32'h0200_0000)) sim_sdram_m (
        .sdram_clk      (sdram_clk),
        .sdram_cke      (sdram_cke),
        .sdram_csn      (sdram_csn),
        .sdram_wen      (sdram_wen),
        .sdram_rasn     (sdram_rasn),
        .sdram_casn     (sdram_casn),
        .sdram_a        (sdram_a),
        .sdram_ba       (sdram_ba),
        .sdram_dqm      (sdram_dqm),
        .sdram_d        (sdram_d));
`else // BOARD_BLUE_WHALE
    sim_psram #(.RAM_PHYSICAL_SIZE(32'h0200_0000)) sim_psram_m (
        .psram_cen      (psram_cen),
        .psram_wen      (psram_wen),
        .psram_oen      (psram_oen),
        .psram_lbn      (psram_lbn),
        .psram_ubn      (psram_ubn),
        .psram_a        (psram_a),
        .psram_d        (psram_d));
`endif

    logic[3:0] finish_simulation = 4'h4;
    integer exit_code = 0;
    initial begin
`ifdef D_STATS_FILE
        risc_p_m.fd = $fopen("out.csv", "w");
`endif
    end

    //==================================================================================================================
    // Convert from mcause bits to mcause string
    //==================================================================================================================
    function string to_mcause_bits_string(input [31:0] mcause_bits);
        (* parallel_case, full_case *)
        case (mcause_bits)
            // Exceptions
            32'h0000_0001: return "EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED";
            32'h0000_0002: return "EX_CODE_INSTRUCTION_ACCESS_FAULT";
            32'h0000_0004: return "EX_CODE_ILLEGAL_INSTRUCTION";
            32'h0000_0008: return "EX_CODE_BREAKPOINT";
            32'h0000_0010: return "EX_CODE_LOAD_ADDRESS_MISALIGNED";
            32'h0000_0020: return "EX_CODE_LOAD_ACCESS_FAULT";
            32'h0000_0040: return "EX_CODE_STORE_ADDRESS_MISALIGNED";
            32'h0000_0080: return "EX_CODE_STORE_ACCESS_FAULT";
            32'h0000_0100: return "EX_CODE_ECALL";
            default: return "Undefined";
        endcase
    endfunction

    //==================================================================================================================
    // Save the signature in test mode
    //==================================================================================================================
`ifdef TEST_MODE
    integer sign_fd, i;
    string bin_full_name, filename;
    logic found_last_back_slash = 1'b0;

    task save_signature_task (input [31:0] begin_addr, input [31:0] end_addr);
        begin_addr = begin_addr - `RAM_BEGIN_ADDR;
        end_addr = end_addr - `RAM_BEGIN_ADDR;
        if (end_addr > begin_addr) begin
            bin_full_name = `BIN_FILE_NAME;
            filename = {bin_full_name.substr(0, bin_full_name.len() - 4), "sig"};

            sign_fd = $fopen (filename, "w");
            if (sign_fd) begin
                for (i = begin_addr; i < end_addr; i = i + 4) begin
                    $fdisplay (sign_fd, "%h%h%h%h", sim_sdram_m.ram[i/2+1][15:8], sim_sdram_m.ram[i/2+1][7:0],
                                sim_sdram_m.ram[i/2][15:8], sim_sdram_m.ram[i/2][7:0]);
                end

                $fclose (sign_fd);
                //$display ($time, " SIM: Signature generated: %s (@[%h] - @[%h]).", filename, begin_addr, end_addr);
            end else begin
                $display ($time, " SIM:                                   FAIL [Cannot save signature file: %s.]",
                            filename);
                exit_code = 1;
            end
        end else begin
            $display ($time, " SIM:                                   FAIL [Cannot generate signature file: %s.]",
                        filename);
            exit_code = 1;
        end
    endtask
`endif

    //==================================================================================================================
    // Finish the simulation
    //==================================================================================================================
    always @(posedge risc_p_m.clk) begin
        if (risc_p_m.cpu_state_m == risc_p_m.STATE_HALTED) begin
            if (finish_simulation > 0) begin
                finish_simulation <= finish_simulation - 4'h1;
            end else begin
`ifdef TEST_MODE
                if (risc_p_m.looping_instruction) begin
                    save_signature_task (risc_p_m.regfile_m.cpu_reg[1], risc_p_m.regfile_m.cpu_reg[2]);
                end else if (risc_p_m.pipeline_trap_mcause[`EX_CODE_BREAKPOINT]) begin
                    $display ($time,
                                " SIM:\033[0;31m                                  FAIL [Breakpoint in test]\033[0m");
                    exit_code = 1;
                end else begin
                    // Test ended in a trap
                    $display ($time,
                                " SIM:\033[0;31m                                  FAIL [Exception in test: %s]\033[0m",
                                to_mcause_bits_string(risc_p_m.pipeline_trap_mcause));
                    exit_code = 1;
                end
`else // TEST_MODE
                if (risc_p_m.looping_instruction) begin
                    $display($time, " SIM: --------- Simulation end [Looping instruction @[%h]] -------------------",
                                risc_p_m.exec_instr_addr_o);
                end else if (risc_p_m.pipeline_trap_mcause[`EX_CODE_BREAKPOINT]) begin
                    $display($time, " SIM: --------- Simulation end [Breakpint] -----------------------");
                    exit_code = 1;
                end else begin
                    $display($time, " SIM: --------- Simulation end [Exception: %s] -----------------------",
                                to_mcause_bits_string(risc_p_m.pipeline_trap_mcause));
                    exit_code = 1;
                end

                $display ($time, " SIM: Cycles:                 %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_CYCLE]);
                $display ($time, " SIM: Instructions retired:   %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_INSTRET]);
`ifdef ENABLE_MHPM
                $display ($time, " SIM: Instructions from ROM:  %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_INSTR_FROM_ROM]);
                $display ($time, " SIM: Instructions from RAM:  %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_INSTR_FROM_RAM]);
                $display ($time, " SIM: I-Cache hits:           %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_I_CACHE_HIT]);
                $display ($time, " SIM: Load from ROM:          %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_LOAD_FROM_ROM]);
                $display ($time, " SIM: Load from RAM:          %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_LOAD_FROM_RAM]);
                $display ($time, " SIM: Store to RAM:           %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_STORE_TO_RAM]);
                $display ($time, " SIM: IO load:                %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_IO_LOAD]);
                $display ($time, " SIM: IO store:               %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_IO_STORE]);
                $display ($time, " SIM: CSR load:               %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_CSR_LOAD]);
                $display ($time, " SIM: CSR store:              %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_CSR_STORE]);
                $display ($time, " SIM: Timer interrupts:       %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_TIMER_INT]);
                $display ($time, " SIM: External interrupts:    %0d",
                                                        risc_p_m.mem_space_m.csr_m.mhpmcounter[`EVENT_EXTERNAL_INT]);
`endif // ENABLE_MHPM
`endif // TEST_MODE
`ifdef D_STATS_FILE
                $fclose (risc_p_m.fd);
`endif
                // Finish the simulation
                $finish (exit_code);
            end
        end
    end

`include "initial.svh"
endmodule
