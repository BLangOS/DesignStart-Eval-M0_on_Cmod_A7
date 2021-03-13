/* startup.c */

#include <stdint.h>

/* Addresses pulled in from the linker script */
extern uint32_t _end_stack;
extern uint32_t _end_text;
extern uint32_t _start_data;
extern uint32_t _end_data;
extern uint32_t _start_bss;
extern uint32_t _end_bss;

/* Application main() called in reset handler */
extern int main(void);

#define WEAK_ALIAS(x) __attribute__ ((weak, alias(#x)))

/* Cortex M0 core interrupt handlers */
void Reset_Handler(void);
void NMI_Handler(void)        WEAK_ALIAS(Dummy_Handler);
void HardFault_Handler(void)  WEAK_ALIAS(Dummy_Handler);
void SVC_Handler(void)        WEAK_ALIAS(Dummy_Handler);
void PendSV_Handler(void)     WEAK_ALIAS(Dummy_Handler);
void SysTick_Handler(void)    WEAK_ALIAS(Dummy_Handler);

/* Cortex M0 DesignStart interrupt handlers */
void Int_00_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_01_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_02_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_03_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_04_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_05_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_06_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_07_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_08_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_09_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_10_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_11_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_12_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_13_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_14_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_15_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_16_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_17_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_18_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_19_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_20_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_21_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_22_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_23_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_24_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_25_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_26_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_27_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_28_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_29_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_30_Handler(void) WEAK_ALIAS(Dummy_Handler);
void Int_31_Handler(void) WEAK_ALIAS(Dummy_Handler);

void Dummy_Handler(void);

/* Stack top and vector handler table */
void *vector_table[] __attribute__ ((section(".vectors"))) = {
    &_end_stack,
    (void*)Reset_Handler+1,                 /*  1 */
    NMI_Handler,                            /*  2 */
    HardFault_Handler,                      /*  3 */
    0,0,0,0,0,0,0,                          /*  4-10 reserved */
    SVC_Handler,                            /* 11 */
    0,0,                                    /* 12-13 reserved */
    PendSV_Handler,                         /* 14 */
    SysTick_Handler,                        /* 15 */
    /* DesignStart Interrupts */
    Int_00_Handler,
    Int_01_Handler,
    Int_02_Handler,
    Int_03_Handler,
    Int_04_Handler,
    Int_05_Handler,
    Int_06_Handler,
    Int_07_Handler,
    Int_08_Handler,
    Int_09_Handler,
    Int_10_Handler,
    Int_11_Handler,
    Int_12_Handler,
    Int_13_Handler,
    Int_14_Handler,
    Int_15_Handler,
    Int_16_Handler,
    Int_17_Handler,
    Int_18_Handler,
    Int_19_Handler,
    Int_20_Handler,
    Int_21_Handler,
    Int_22_Handler,
    Int_23_Handler,
    Int_24_Handler,
    Int_25_Handler,
    Int_26_Handler,
    Int_27_Handler,
    Int_28_Handler,
    Int_29_Handler,
    Int_30_Handler,
    Int_31_Handler
};

void Reset_Handler(void) {
    uint8_t *src, *dst;

    /* Copy with byte pointers to obviate unaligned access problems */

#if 0
    /* Copy data section from Flash to RAM */
    src = (uint8_t *)&_end_text;
    dst = (uint8_t *)&_start_data;
    while (dst < (uint8_t *)&_end_data)
        *dst++ = *src++;
#endif

    /* Clear the bss section */
    dst = (uint8_t *)&_start_bss;
    while (dst < (uint8_t *)&_end_bss)
        *dst++ = 0;

    main();
}

void Dummy_Handler(void) {
    while (1)
        ;
}

#if 0
void _exit(void) {
    while(1){}
}
#endif