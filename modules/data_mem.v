// Data memory — 256KB (65536 words of 32 bits)
// Supports byte, halfword, word access via funct3
// Loaded via $readmemh from image_in.hex at simulation start
module data_mem (
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    // 256KB = 65536 32-bit words
    reg [31:0] mem [0:65535];

    initial begin
        $readmemh("image_in.hex", mem, 0, 65535);
    end

    always @(*) begin
        read_data = mem_read ? mem[addr[17:2]] : 32'b0;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[17:2]] <= write_data;
    end

    // Dump output region after simulation (called by testbench)
    task dump_output;
        input [31:0] base_word;   // starting word index
        input [31:0] num_words;   // how many words to dump
        input [127:0] filename;
        integer i, f;
        begin
            f = $fopen(filename, "w");
            for (i = 0; i < num_words; i = i + 1)
                $fwrite(f, "%08h\n", mem[base_word + i]);
            $fclose(f);
        end
    endtask
endmodule
