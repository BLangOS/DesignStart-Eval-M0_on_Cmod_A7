GCC_PATH       = L:/Tools/gcc-arm-none-eabi-9-2020-q2-update-win32/bin
COREUTILS_PATH = L:/Tools/coreutils-5.3.0-bin/bin

all: C_Basic.hex C_Basic.od

main.o: main.c Makefile
	$(GCC_PATH)/arm-none-eabi-gcc.exe -c -ggdb -mthumb -mcpu=cortex-m0 -o main.o main.c

Startup.o: Startup.c Makefile
	$(GCC_PATH)/arm-none-eabi-gcc.exe -c -ggdb -mthumb -mcpu=cortex-m0 -o Startup.o Startup.c

C_Basic.elf: main.o Startup.o C_Basic.ld
	$(GCC_PATH)/arm-none-eabi-gcc.exe -mcpu=cortex-m0 -mthumb -nostdlib -TC_Basic.ld main.o Startup.o -lgcc -o C_Basic.elf

C_Basic.od: C_Basic.elf   
	$(GCC_PATH)/arm-none-eabi-objcopy.exe -S -O binary C_Basic.elf C_Basic.bin
	$(COREUTILS_PATH)/od.exe -w1 -t x1 -v -An C_Basic.bin > C_Basic.od
	$(GCC_PATH)/arm-none-eabi-size.exe C_Basic.elf
   
clean:
	$(COREUTILS_PATH)/rm C_Basic.elf main.o Startup.o C_Basic.bin C_Basic.hex C_Basic_diss.txt C_Basic.od
    
C_Basic.hex: C_Basic.elf
	$(GCC_PATH)/arm-none-eabi-objcopy.exe -O ihex C_Basic.elf C_Basic.hex
	$(GCC_PATH)/arm-none-eabi-objdump.exe -h -t -j.vectors -j.text -j.data -j.bss -S C_Basic.elf > C_Basic_diss.txt
	$(GCC_PATH)/arm-none-eabi-size.exe C_Basic.elf
