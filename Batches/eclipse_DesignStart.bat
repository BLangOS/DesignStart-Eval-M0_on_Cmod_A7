@echo off

rem Path to Windows Build Tools
PATH L:\tools\xpack-windows-build-tools-4.2.1-2\bin;%PATH%

rem Path to Eclipse executable
set ECLIPSE_PATH=L:\tools\eclipse-cpp-2020-09-R-win32-x86_64\eclipse
rem Path to Workspace
set WORKSPACE=L:\Eigene_Dateien\Home\Projekte\ARM\Cortex-M0_DesignStart\Eclipse_WS
rem Start Eclipse
start /B %ECLIPSE_PATH%\eclipse.exe -data %WORKSPACE%

rem Path to OpenOCD executable
set OpenOCD_PATH= L:\tools\OpenOCD-20200729-0.10.0\bin
rem start OpenOCD Server
%OpenOCD_PATH%\openocd.exe -f Cortex-M.cfg

pause
