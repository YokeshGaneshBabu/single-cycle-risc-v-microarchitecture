# Startup: initialize stack pointer then jump to C
.section .text.startup
.global _start
_start:
    # Stack at top of scratch region: 0x30000 (192KB mark)
    lui  sp, 0x30          # sp = 0x30000
    jal  ra, process_image # call C function
halt:
    j    halt              # infinite loop halt
