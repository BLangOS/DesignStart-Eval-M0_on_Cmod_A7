ENTRY(Reset_Handler)

/* Memory configuration for Cortex-M0 DesignStart */
BRAM_BASE = 0x00000000;
BRAM_SIZE = 16K;

MEMORY
{
    bram   :   ORIGIN = 0x00000000, LENGTH = BRAM_SIZE
}

_end_stack = BRAM_BASE + BRAM_SIZE;

SECTIONS {
    . = ORIGIN(bram);

    vectors :
    {
        *(.vectors)
    } >bram

    .text :
    {
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        _end_text = .;
    } >bram

    . = ALIGN(4);
    
    .data :
    {
        _start_data = .;
        *(.data)
        *(.data*)
        _end_data = .;
    } >bram

    . = ALIGN(4);

    .bss :
    {
        _start_bss = .;
        *(.bss)
        *(.bss*)
    } >bram
    . = ALIGN(4);
    _end_bss = .;

    _start_stack = .;
}

_end = .;
PROVIDE(end = .);