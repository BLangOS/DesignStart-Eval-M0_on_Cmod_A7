GCC_PATH       = L:/Tools/gcc-arm-none-eabi-9-2020-q2-update-win32/bin
COREUTILS_PATH = L:/Tools/coreutils-5.3.0-bin/bin

all: main.hex main.bin

main.o: main.S Makefile
	$(GCC_PATH)/arm-none-eabi-as.exe -ggdb -mthumb -mcpu=cortex-m0 -o main.o main.S

main.elf: main.o main.ld
	$(GCC_PATH)/arm-none-eabi-ld.exe -T main.ld main.o -o main.elf
  
main.bin: main.elf   
	$(GCC_PATH)/arm-none-eabi-objcopy.exe -S -O binary main.elf main.bin
	$(COREUTILS_PATH)/od.exe -w1 -t x1 -v -An main.bin > main.od
	$(GCC_PATH)/arm-none-eabi-size.exe main.elf
   
clean:
	$(COREUTILS_PATH)/rm main.elf main.o main.bin main.hex main_diss.txt main.od
    
main.hex: main.elf
	$(GCC_PATH)/arm-none-eabi-objcopy.exe -O ihex main.elf main.hex
	$(GCC_PATH)/arm-none-eabi-objdump.exe -h -t -j.vectors -j.text -j.data -j.bss -S main.elf > main_diss.txt
	$(GCC_PATH)/arm-none-eabi-size.exe main.elf
    