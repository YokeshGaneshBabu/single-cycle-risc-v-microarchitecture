module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_write,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        jal,
    output reg        jalr,
    output reg        lui,
    output reg        auipc,
    output reg [1:0]  alu_op,
    output reg [2:0]  imm_src
);
    always @(*) begin
        reg_write=0; mem_write=0; mem_read=0; mem_to_reg=0;
        alu_src=0; branch=0; jal=0; jalr=0; lui=0; auipc=0;
        alu_op=2'b00; imm_src=3'b000;
        case (opcode)
            7'b0110011: begin reg_write=1; alu_op=2'b10; end
            7'b0010011: begin reg_write=1; alu_src=1; alu_op=2'b11; end
            7'b0000011: begin reg_write=1; mem_read=1; mem_to_reg=1; alu_src=1; end
            7'b0100011: begin mem_write=1; alu_src=1; imm_src=3'b001; end
            7'b1100011: begin branch=1; alu_op=2'b01; imm_src=3'b010; end
            7'b1101111: begin reg_write=1; jal=1; imm_src=3'b011; end
            7'b1100111: begin reg_write=1; jalr=1; alu_src=1; end
            7'b0110111: begin reg_write=1; lui=1; imm_src=3'b100; end
            7'b0010111: begin reg_write=1; auipc=1; imm_src=3'b100; end
            default: begin end
        endcase
    end
endmodule
