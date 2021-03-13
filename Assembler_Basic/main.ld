BRAM_BASE = 0x00000000;
BRAM_SIZE = 16K;

_INITIAL_STACKPOINTER = BRAM_BASE + BRAM_SIZE;

MEMORY {
	BRAM (rw) : ORIGIN = BRAM_BASE, LENGTH  = BRAM_SIZE
}

SECTIONS
{
	/* Read Only (Instructions) */
	.text : {
        *(.vectors)
		*(.text)
		*(.text.*)
		*(.rodata.*)
	} >BRAM
	/* Initialized Data */
	.data : {
		*(.sdata)
		*(.sdata.*)
		*(.data)
		*(.data.*)
	} >BRAM
	/* Uninitialized Data */
	.bss : {
		*(.bss)
		*(.bss.*)
		*(.sbss)
		*(.sbss.*)
	} >BRAM
}
