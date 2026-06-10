# ================================================================
# ModelSim/QuestaSim run script
# Usage: from ModelSim Tcl console: do run_sim.do
# Make sure image_in.hex, image_meta.txt, program.hex are in sim/
# ================================================================

vlib work
vmap work work

vlog ../rtl/ALU.v
vlog ../rtl/ALUControl.v
vlog ../rtl/branch_unit.v
vlog ../rtl/regfile.v
vlog ../rtl/pc_reg.v
vlog ../rtl/imm_gen.v
vlog ../rtl/control_unit.v
vlog ../rtl/instr_mem.v
vlog ../rtl/data_mem.v
vlog ../rtl/riscv_cpu.v
vlog tb_imgproc.v

vsim -t 1ps -novopt work.tb_imgproc

run -all
quit -f
