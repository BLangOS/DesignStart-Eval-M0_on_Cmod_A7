#include <stdint.h>

// ---------------------------------------------------------------------------
// Test-Periperal
// ---------------------------------------------------------------------------
// 0ffset 0 Read:  Read Button from Board (only Bit 0 is relevant)
// Offset 0 Write: Write to LED register (Bits 0-7 are relevant)
// Offset 4: Hardware-Register that can be written and read
#define AHB_BASE 0x40000000
#define LED_BUTTON_REG (*((unsigned int *)AHB_BASE+0))
#define REG_1          (*((unsigned int *)AHB_BASE+1))

// ---------------------------------------------------------------------------
// Systick registers
// ---------------------------------------------------------------------------
#define SYST_CSR   (*((unsigned int *)0xE000E010))
#define SYST_RVR   (*((unsigned int *)0xE000E014))
#define SYST_CVR   (*((unsigned int *)0xE000E018))
#define SYST_CALIB (*((unsigned int *)0xE000E01C))
// System Control block
#define SHPR3      (*((unsigned int *)0xE000ED20))

volatile unsigned int systick_count=0;

// ---------------------------------------------------------------------------
// SysTick_Handler
// ---------------------------------------------------------------------------
void SysTick_Handler(void) {
  systick_count++;
}

// ---------------------------------------------------------------------------
// SysTick_Initialize
// ---------------------------------------------------------------------------
void SysTick_Initialize (uint32_t reload) {
  SYST_CSR = 0;               // Disable SysTick
  SYST_RVR = reload;          // Set reload register
  SHPR3 = SHPR3 | (0xff<<24); // Set interrupt priority of SysTick to lowest
  SYST_CVR = 0;               // Reset the SysTick counter value
  // CLKSOURCE: Selects the SysTick timer clock source:
  // 0 = reference clock
  // 1 = processor clock.
  // TICKINT: Enables SysTick exception request:
  // 0 = counting down to zero does not assert the SysTick exception request
  // 1 = counting down to zero to asserts the SysTick exception request.
  // ENABLE: Enables the counter:
  // 0 = counter disabled
  // 1 = counter enabled.
  SYST_CSR = (0<<2) | (1<<1) | (1<<0); // CLKSOURCE | TICKINT | ENABLE
}

int main(void) {
  int i=0;
  volatile int btn;
  int reg_1=0;
//  reg_1 = *((unsigned int*)0x10000000);
  SysTick_Initialize (SYST_CALIB); // Tick every 10ms using reference clock
  REG_1 = 0;
  while(1) {
//    reg_1 = REG_1 = REG_1+1;
//    reg_1 = *((unsigned int*)0x10000000);
//    reg_1 = *((unsigned int*)0x10000004);
//    reg_1 = *((unsigned int*)0x10000008);
//    reg_1 = *((unsigned int*)0x1000000c);
//    reg_1 = *((unsigned int*)0x10000010);
//    reg_1 = *((unsigned int*)0x10000004);
//    reg_1 = *((unsigned int*)0x10000018);
//    reg_1 = *((unsigned int*)0x1000001c);
    if (100<=systick_count) {
      systick_count=0;
      btn = LED_BUTTON_REG;
      if (1!=btn) {
        // Shift LED-Output
        LED_BUTTON_REG = 1<<i++; if (i==8) { i=0; }
      }
    }
    REG_1=4;
  }
  return 0;
}
