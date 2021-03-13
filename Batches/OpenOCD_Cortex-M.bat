@echo off

rem Minimum Configuration, for all Cortex-M Processors with SWD

rem Start OpenOCD Server
set OpenOCD_PATH= L:\tools\OpenOCD-20200729-0.10.0\bin
%OpenOCD_PATH%\openocd.exe -f Cortex-M.cfg

pause
