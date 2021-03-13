rem PATH %PATH%;L:\tools\gcc-arm-none-eabi-9-2020-q2-update-win32\bin
@arm-none-eabi-objdump.exe -h -j.text -j.data -j.bss %1.elf
@arm-none-eabi-objdump.exe -h -t -j.text -j.data -j.bss --source-comment %1.elf > %1_diss.txt
@arm-none-eabi-objcopy.exe -O ihex %1.elf %1.hex
@arm-none-eabi-objcopy.exe -i 4 -b 0 %1.hex %1_0.hex
@arm-none-eabi-objcopy.exe -i 4 -b 1 %1.hex %1_1.hex
@arm-none-eabi-objcopy.exe -i 4 -b 2 %1.hex %1_2.hex
@arm-none-eabi-objcopy.exe -i 4 -b 3 %1.hex %1_3.hex

