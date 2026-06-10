// Single-cycle RISC-V RV32I CPU
// Supports: R, I, S, B, J (JAL), I (JALR), U (LUI/AUIPC)
module riscv_cpu (
    input wire clk,
    input wire rst
);
    wire [31:0] pc, pc_next, pc_plus4, pc_target, pc_jalr;
    wire [31:0] instr, imm_ext;
    wire [31:0] rs1_data, rs2_data, alu_result;
    wire [31:0] alu_src_b, rd_write_data, mem_read_data;
    wire [4:0]  rs1, rs2, rd;
    wire [2:0]  funct3;
    wire [6:0]  funct7, opcode;
    wire [3:0]  alu_control;
    wire [1:0]  alu_op;
    wire [2:0]  imm_src;
    wire        reg_write, mem_write, mem_read, mem_to_reg;
    wire        alu_src, branch, jal, jalr, lui, auipc;
    wire        pc_src, zero, less;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // PC computation
    assign pc_plus4  = pc + 4;
    assign pc_target = pc + imm_ext;          // branch / JAL target
    assign pc_jalr   = (rs1_data + imm_ext) & ~32'h1; // JALR target

    assign pc_next = jalr  ? pc_jalr   :
                     (jal | pc_src) ? pc_target :
                     pc_plus4;

    // ALU B input
    assign alu_src_b = alu_src ? imm_ext : rs2_data;

    // Write-back: JAL/JALR write PC+4; LUI writes imm; AUIPC writes PC+imm; else normal
    assign rd_write_data = (jal | jalr)  ? pc_plus4   :
                           lui           ? imm_ext     :
                           auipc         ? pc_target   :
                           mem_to_reg    ? mem_read_data :
                           alu_result;

    pc_reg PC (
        .clk(clk), .rst(rst),
        .pc_next(pc_next), .pc(pc)
    );

    instr_mem IMEM (
        .addr(pc), .instr(instr)
    );

    control_unit CTRL (
        .opcode(opcode),
        .reg_write(reg_write), .mem_write(mem_write),
        .mem_read(mem_read),   .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),     .branch(branch),
        .jal(jal),             .jalr(jalr),
        .lui(lui),             .auipc(auipc),
        .alu_op(alu_op),       .imm_src(imm_src)
    );

    regfile RF (
        .clk(clk), .rst(rst),
        .reg_write(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .rd_data(rd_write_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    imm_gen IMMGEN (
        .instr(instr), .imm_src(imm_src), .imm_out(imm_ext)
    );

    ALUControl ALUCTRL (
        .alu_op(alu_op), .funct3(funct3), .funct7(funct7),
        .alu_control(alu_control)
    );

    ALU ALU_UNIT (
        .a(rs1_data), .b(alu_src_b),
        .alu_control(alu_control),
        .result(alu_result), .zero(zero), .less(less)
    );

    branch_unit BRANCH (
        .funct3(funct3), .zero(zero), .less(less),
        .branch(branch), .pc_src(pc_src)
    );

    data_mem DMEM (
        .clk(clk),
        .mem_write(mem_write), .mem_read(mem_read),
        .addr(alu_result),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );
endmodule
