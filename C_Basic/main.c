#include <stdint.h>

extern uint32_t _end_stack;

volatile int b_bss;
volatile int b2_bss;

volatile int d_data =123456;

int main(void) {
  volatile int i = (int)&_end_stack;
  volatile int* p = (int*)0x00002000;
  while(1) {
      i=i+1;
      if (i%10 == 0) { *p =0xaaaa5555; }
      if (i%10 == 0) { b_bss=b_bss+1; }
      if (b_bss==40) {
        b_bss=0;
        *p =0xaaaa5555;
      }
  }
  return 0;
}