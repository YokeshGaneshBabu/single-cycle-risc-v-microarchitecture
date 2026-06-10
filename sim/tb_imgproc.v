`timescale 1ns/1ps
// ================================================================
// RISC-V Single-Cycle CPU — Image Processing Testbench
// Works with ModelSim (run_sim.do) and Icarus Verilog (iverilog)
//
// Required files in sim/ directory before running:
//   program.hex    — compiled RISC-V program
//   image_in.hex   — input image (from img_to_hex.py)
//   image_meta.txt — image dimensions (W H)
//
// Output:
//   image_out.hex  — memory dump (feed to hex_to_img.py)
// ================================================================
module tb_imgproc;

    reg clk, rst;
    riscv_cpu DUT (.clk(clk), .rst(rst));

    // 10 ns clock = 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    integer cycle;
    reg [31:0] prev_pc;
    integer    halt_streak;
    integer    i, f;

    initial begin
        rst         = 1;
        cycle       = 0;
        halt_streak = 0;
        prev_pc     = 32'hFFFFFFFF;

        $display("======================================================");
        $display(" RISC-V Image Processing Simulation");
        $display("======================================================");

        #25 rst = 0;
        $display("[%0t] Reset released, CPU running...", $time);

        forever begin
            @(posedge clk); #1;
            cycle = cycle + 1;

            // Progress report every 200k cycles
            if (cycle % 200000 == 0)
                $display("[%0d cycles] PC = %08h", cycle, DUT.pc);

            // Halt detection: PC stuck (j halt self-loop at 0x00000008)
            if (DUT.pc === prev_pc)
                halt_streak = halt_streak + 1;
            else begin
                halt_streak = 0;
                prev_pc = DUT.pc;
            end

            if (halt_streak >= 8) begin
                $display("");
                $display("[%0d cycles] CPU halted at PC = %08h", cycle, DUT.pc);
                $display("Dumping data memory to image_out.hex ...");

                // Write words 0..49151  (192KB: input + gray + edge regions)
                f = $fopen("image_out.hex", "w");
                for (i = 0; i < 49152; i = i + 1)
                    $fwrite(f, "%08h\n", DUT.DMEM.mem[i]);
                $fclose(f);

                $display("image_out.hex written.");
                $display("");
                $display("Next: python3 ../scripts/hex_to_img.py image_out.hex image_meta.txt");
                $display("======================================================");
                $finish;
            end

            // Safety timeout
            if (cycle >= 10000000) begin
                $display("[TIMEOUT] %0d cycles exceeded. PC = %08h", cycle, DUT.pc);
                $finish;
            end
        end
    end

endmodule
