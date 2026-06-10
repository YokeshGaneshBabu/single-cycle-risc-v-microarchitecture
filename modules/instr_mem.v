// Instruction memory — 64KB (16384 instructions)
// Loaded via $readmemh from program.hex at simulation start
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:16383];

    initial begin
        $readmemh("program.hex", mem, 0, 16383);
    end

    assign instr = mem[addr[15:2]];
endmodule
