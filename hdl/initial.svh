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
 * SIMULATION code common to all apps.
 **********************************************************************************************************************/
`ifndef BIN_FILE_NAME
`define BIN_FILE_NAME ""
`endif

    //==================================================================================================================
    // Initialization
    //==================================================================================================================
    initial begin
        if (`BIN_FILE_NAME != "") begin
            integer fd, bytes_read, file_index;
            logic [7:0] value_1;

            fd = $fopen(`BIN_FILE_NAME, "rb");
            if (fd) begin
                file_index = 0;
                bytes_read = 1;

                while (bytes_read > 0) begin
                    bytes_read = $fread(value_1, fd, file_index, 1);
                    if (bytes_read == 1) begin
                        sim_flash_slave_m.flash[`FLASH_OFFSET_ADDR + file_index] = value_1;
                        file_index = file_index + 1;
                    end else begin
                        $display($time, " SIM: Loaded %s to flash (%h bytes).", `BIN_FILE_NAME, file_index);
                    end
                end

                $fclose(fd);
            end else begin
                $display($time, " SIM: Error: File open error: %s", `BIN_FILE_NAME);
                $finish(0);
            end
        end else begin
            $display($time, " SIM: No .bin file specified. Use -D BIN_FILE_NAME option");
            $finish(0);
        end

`ifdef TEST_MODE
        $display($time, " SIM: Running test...");
`else
        $display($time, " SIM: CLK_PERIOD_NS: %0d ns.", `CLK_PERIOD_NS);
        $display($time, " SIM: ------------------------- Simulation begin ---------------------------");
`endif // TEST_MODE

`ifdef GENERATE_VCD
        $dumpfile("gtkwave.vcd");
/*
        $dumpvars(0, flash_ram_test_m.flash_master_m.clk_i);
        $dumpvars(0, flash_ram_test_m.flash_master_m.flash_clk);
        $dumpvars(0, flash_ram_test_m.flash_master_m.flash_csn);
        $dumpvars(0, flash_ram_test_m.flash_master_m.flash_mosi);
        $dumpvars(0, flash_ram_test_m.flash_master_m.flash_miso);
*/
        $dumpvars(0, mem_space_test_m.mem_space_m.sdram_m.clk_i);
        $dumpvars(0, mem_space_test_m.mem_space_m.sdram_m.sdram_clk);
/*
        $dumpvars(0, ram_test_m.sdram_m.stb_i);
        $dumpvars(0, ram_test_m.sdram_m.cyc_i);
        $dumpvars(0, ram_test_m.sdram_m.data_i);
        $dumpvars(0, ram_test_m.sdram_m.ack_o);
*/
`endif

`ifdef TEST_MODE
        #25000000
        $display($time, " SIM: !!!! Timeout: end of test not reached  !!!!");
`elsif SIMULATION
        #150000000

        $display($time, " SIM: ---------------------- Simulation end ------------------------");
`endif // SIMULATION

        $finish(0);
    end
