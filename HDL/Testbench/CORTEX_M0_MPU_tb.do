#vlog ../verilog/cmsdk_clock_gate.v
vlog ../verilog/cmsdk_ahb_default_slave.v
vlog ../verilog/cmsdk_ahb_to_sram.v
vlog ../verilog/cmsdk_mcu_sysctrl.v
vlog ../verilog/cortexm0ds_logic.v
#vlog ../verilog/cmsdk_mcu_stclkctrl.v
vlog ../verilog/cmsdk_mcu_clkctrl.v

vcom -work work ../Peripherals/Memory/intel_hex_pack.vhd
vcom -work work ../Peripherals/Memory/FPGA_SRAM.vhd
vcom -work work ../Peripherals/RegIO/AHB_RegIO.vhd
vcom -work work ../MPU/CORTEX_M0_Core.vhd
vcom -work work ../MPU/CORTEX_M0_MPU.vhd
vcom -work work SWD_Test_pack.vhd
vcom -work work CORTEX_M0_MPU_tb.vhd

vsim work.cortex_m0_mpu_tb

config wave -signalnamewidth 1

add wave /cortex_m0_mpu_tb/CLK
add wave /cortex_m0_mpu_tb/RESETn
add wave -divider "======================="
add wave /cortex_m0_mpu_tb/SWCLK
add wave /cortex_m0_mpu_tb/SWDIO
add wave /cortex_m0_mpu_tb/SWDO
add wave /cortex_m0_mpu_tb/SWDOEN
add wave /cortex_m0_mpu_tb/ReadOK
add wave /cortex_m0_mpu_tb/AP_found
add wave -divider "======================="
add wave -hexadecimal /cortex_m0_mpu_tb/inputs   
add wave -hexadecimal /cortex_m0_mpu_tb/outputs   
add wave -divider "======================="

#add wave              /cortex_m0_mpu_tb/Stim/count
add wave              /cortex_m0_mpu_tb/Stim/ack
add wave -hexadecimal /cortex_m0_mpu_tb/Stim/write_data
add wave -hexadecimal /cortex_m0_mpu_tb/Stim/read_data
#add wave              /cortex_m0_mpu_tb/Stim/parity
add wave              /cortex_m0_mpu_tb/Stim/actual

add wave /cortex_m0_mpu_tb/DUT/TheCore/CDBGPWRUPREQ
add wave /cortex_m0_mpu_tb/DUT/TheCore/CDBGPWRUPACK

add wave -hexadecimal /cortex_m0_mpu_tb/DUT/TheCore/Processor/ProgramCounter
add wave              /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r0_o
add wave              /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r1_o
add wave              /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r2_o
add wave              /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r3_o

if (1) {

add wave -divider "= AHB-Lite Bus ========="
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HRESETn
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/TheCore/HADDR
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HBURST
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HMASTLOCK
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HPROT
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HSIZE
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HTRANS
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/TheCore/HWDATA
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HWRITE
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/TheCore/HRDATA
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HREADY
add wave              /cortex_m0_mpu_tb/DUT/TheCore/HRESP
}
if (1) {
add wave -divider "==MEM=================="
add wave              /cortex_m0_mpu_tb/DUT/seg_hsel(0)
add wave              /cortex_m0_mpu_tb/DUT/Interconnect/seg_hsel_reg(0)
add wave              /cortex_m0_mpu_tb/DUT/seg_hready(0)
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/seg_hrdata(0)
add wave              /cortex_m0_mpu_tb/DUT/seg_hresp(0)
add wave -divider "==SYC=================="
add wave              /cortex_m0_mpu_tb/DUT/seg_hsel(1)
add wave              /cortex_m0_mpu_tb/DUT/Interconnect/seg_hsel_reg(1)
add wave              /cortex_m0_mpu_tb/DUT/seg_hready(1)
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/seg_hrdata(1)
add wave              /cortex_m0_mpu_tb/DUT/seg_hresp(1)
add wave -divider "==AHB_RegIO=================="
add wave              /cortex_m0_mpu_tb/DUT/seg_hsel(2)
add wave              /cortex_m0_mpu_tb/DUT/Interconnect/seg_hsel_reg(2)
add wave              /cortex_m0_mpu_tb/DUT/seg_hready(2)
add wave -hexadecimal /cortex_m0_mpu_tb/DUT/seg_hrdata(2)
add wave              /cortex_m0_mpu_tb/DUT/seg_hresp(2)
add wave              /cortex_m0_mpu_tb/DUT/User_Periperals/my_periperal/w_OK
add wave              /cortex_m0_mpu_tb/DUT/User_Periperals/my_periperal/r_OK
add wave              /cortex_m0_mpu_tb/DUT/User_Periperals/my_periperal/FSM/State
add wave -divider "==defslv==============="
add wave              /cortex_m0_mpu_tb/DUT/Interconnect/seg_hsel_reg(3)
add wave              /cortex_m0_mpu_tb/DUT/Interconnect/seg_hsel_reg(3)
add wave              /cortex_m0_mpu_tb/DUT/seg_hready(3)
add wave              /cortex_m0_mpu_tb/DUT/seg_hresp(3)
add wave -divider "======================="
}

if (0) {
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/CODEHINTDE
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/WICSENSE
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r0_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r1_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r2_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r3_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r4_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r5_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r6_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r7_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r8_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r9_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r10_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r11_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r12_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_r14_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_msp_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_psp_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_pc_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_apsr_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_ipsr_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/CODENSEQ
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SPECHTRANS
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SWDO
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SWDOEN
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/TDO
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/nTDOEN
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/DBGRESTARTED
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/HALTED
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/TXEV
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/LOCKUP
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/GATEHCLK
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SLEEPING
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SLEEPDEEP
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/WAKEUP
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/SLEEPHOLDACKn
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/WICENACK
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/CDBGPWRUPREQ
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_tbit_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_control_o
add wave /cortex_m0_mpu_tb/DUT/TheCore/Processor/Cortex_M0/vis_primask_o
}

run 130 us

wave zoom full

