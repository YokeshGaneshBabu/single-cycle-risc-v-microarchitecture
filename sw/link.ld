OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS {
    . = 0x00000000;
    .text : {
        *(.text.startup)
        *(.text*)
        *(.rodata*)
    }
    /DISCARD/ : { *(.comment) *(.riscv.attributes) *(.note*) *(.eh_frame*) }
}
