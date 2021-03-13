library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity CORTEX_M0_MPU_tb is end;

use work.SWD_Test_pack.all;
architecture test of CORTEX_M0_MPU_tb is
  function expand_string(s:string) return string is
    variable result : string(1 to 40);
  begin
    result := (others=>' ');
    result(s'range) := s;
    return result;      
  end;
  --
  signal CLK         : std_logic := '0';
  signal RESETn      : std_logic := '1';
  signal RefCLK      : std_logic := '0';
  signal SWCLK       : std_logic := '0';
  signal SWDIO       : std_logic := '0';
  signal SWDO        : std_logic;        
  signal SWDOEN      : std_logic;
  signal ReadOK      : std_logic := '0';
  signal AP_found    : std_logic := '0';
  signal inputs      : std_logic_vector(31 downto 0);
  signal outputs     : std_logic_vector(31 downto 0);
  -- Code
  constant Codefile    : string := "../../C_Basic/C_Basic.hex";
begin

  DUT: entity work.CORTEX_M0_MPU
    generic map (
      -- System Timer Settings
      NOREF    => '0',       -- Reference Clock present
      SKEW     => '0',       -- no Skew
      TENMS    => x"00047F", -- ST Reload Value for 12 MHz
      -- Intel HEX codefile for Memory initialization
      Codefile => Codefile
    )
    port map (
      CLK    => CLK,
      RESETn => RESETn,
      --
      RefCLK => RefCLK,
      --
      SWCLK  => SWCLK,
      SWDI   => SWDIO,
      SWDO   => SWDO,    
      SWDOEN => SWDOEN,
      -- GPIO-Ports
      inputs  => inputs,
      outputs => outputs
    );
  
  CLK    <= not CLK after 10 ns;      -- 50 MHz
  RefCLK <= RefCLK  after 83.333333333333333333 ns; -- 12 MHz

  SWCLK  <= not SWCLK after 27 ns; -- ADI Clock
  SWDIO  <= SWDO when SWDOEN='1' else 'Z';
  

  -- stimulate inputs
  inputs(31 downto 0) <= x"00000000",
                         x"55555555" after 10 us,
                         x"00000000" after 25 us,
                         x"aaaaaaaa" after 90 us,
                         x"00000000" after 100 us;
  
  Stim: process
    variable ack            : std_logic_vector( 2 downto 0);
    variable read_data      : unsigned(31 downto 0);
    variable write_data     : unsigned(31 downto 0);
    variable rom_table_base : unsigned(31 downto 0);
    variable SCS_base       : unsigned(31 downto 0);
    variable DWT_base       : unsigned(31 downto 0);
    variable BPU_base       : unsigned(31 downto 0);
    variable actual         : string(1 to 40);
  begin
    --
    -- System Reset Pulse
    --
    actual := expand_string("reset");
    RESETn <= '0';
    for i in 1 to 10 loop
      wait until rising_edge(CLK);
    end loop;
    RESETn <= '1';
 
    wait for 2 us; 

    --
    -- ADI Line reset sequence
    SWDIO <= '1';
    for i in 1 to 50 loop
      wait until rising_edge(SWCLK);
    end loop;
    SWDIO <= '0';    
    wait until rising_edge(SWCLK);
    wait until rising_edge(SWCLK);

    --
    -- Read DPIDR Register
    actual := expand_string("Read DPIDR Register");
    SWD_Read(APnDP=>'0', A=>DP_DPIDR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
    actual := expand_string("Idle");
    SWD_Idle(count=>15, SWCLK=>SWCLK, SWDIO=>SWDIO);

    --    
    -- Write CTRL/STAT Register: Activate Debug Port
    actual := expand_string("Write CTRL/STAT Register");
    write_data := x"50_00_00_00";
    SWD_Write(APnDP=>'0', A=>DP_CTRL_STAT, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
    actual := expand_string("Idle");
    SWD_Idle(count=>5, SWCLK=>SWCLK, SWDIO=>SWDIO);
    --
    -- Read CTRL/STAT Register
    actual := expand_string("Read CTRL/STAT Register");
    SWD_Read(APnDP=>'0', A=>DP_CTRL_STAT, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
    actual := expand_string("Idle");
    SWD_Idle(count=>15, SWCLK=>SWCLK, SWDIO=>SWDIO);
    --
    for AP in 0 to 255 loop -- search available APs
      MEM_AP_Read(
        AP     => std_logic_vector(to_unsigned(AP,8)),
        Reg    => MEM_AP_IDR,
        SWCLK  => SWCLK,
        SWDIO  => SWDIO,
        ack    => ack,
        data   => read_data
      );

      if read_data=0 then AP_found <= '0';
      else                AP_found <= '1'; exit;
      end if;
      --
      -- check if interface is hanging, reset if yes
      --
      -- Read CTRL/STAT Register
      actual := expand_string("Read CTRL/STAT Register");
      SWD_Read(APnDP=>'0', A=>DP_CTRL_STAT, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
      actual := expand_string("Idle");
      SWD_Idle(count=>20, SWCLK=>SWCLK, SWDIO=>SWDIO);
      if read_data(5)='1' or read_data(7)='1' then
        --
        -- Write ABORT Register
        actual := expand_string("Write ABORT Register");
        write_data := x"0000001c";
        SWD_Write(APnDP=>'0', A=>"00", SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data );
        actual := expand_string("Idle");
        SWD_Idle(count=>20, SWCLK=>SWCLK, SWDIO=>SWDIO);
      end if;
      --
    end loop;
    --
    
    -- Write CSW Register (0x00), set word access
    actual := expand_string("Write CSW Register, set word access");
    -- Write CSW Register (0x00), set word access
    write_data := -- x"03000042";
    --      +------------------------------------------------------ Prot
    --      |      +----------------------------------------------- SPIDEN
    --      |      |               +------------------------------- Type
    --      |      |               |      +------------------------ Mode: Basic Mode
    --      |      |               |      |        +--------------- DeviceEn: Mem-AP enabled
    --      |      |               |      |        |    +---------- AddrInc: No increment
    --      |      |               |      |        |    |        +- Size: Word transfer
    --      V      V               V      V        V    V        V
    '0'&"0110000"&'0'&"0000000"&"0000"&"0000"&'0'&'1'&"00"&'0'&"010";
    MEM_AP_Write(
      AP    => x"00",
      Reg   => MEM_AP_CSW,
      SWCLK => SWCLK,
      SWDIO => SWDIO,
      ack   => ack, 
      data  => write_data
    );

    -- read the MEM-AP IDR-Register
    actual := expand_string("Read Mem-AP IDR Register");
    MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_IDR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
    
    -- read the MEM-AP BASE-Register
    actual := expand_string("Read Mem-AP BASE Register");
    MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_BASE, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
    if read_data(0)='1' then
      rom_table_base := unsigned(read_data(31 downto 12))&x"000";
    
      -- read the ROM Table at address 0xE00FF000
      actual := expand_string("Read ROM Table");
      -- read value 0xFFF0F003: Points to System Control Space (SCS) base address 0xE000E000
      write_data := rom_table_base; -- x"E00FF000";
      MEM_AP_Write(AP=>x"00", Reg=>MEM_AP_TAR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
      MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_DRW, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
      SCS_base := rom_table_base + (read_data(31 downto 12) & x"000");
      -- read value 0xFFF02003: DWT Points to DW base address 0xE0001000
      write_data := rom_table_base+x"004"; -- x"E00FF004";
      MEM_AP_Write(AP=>x"00", Reg=>MEM_AP_TAR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
      MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_DRW, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
      DWT_base := rom_table_base + (read_data(31 downto 12) & x"000");
      -- read value 0xFFF03003: BPU Points to BPU base address 0xE0002000
      write_data := rom_table_base+x"008"; -- x"E00FF008";
      MEM_AP_Write(AP=>x"00", Reg=>MEM_AP_TAR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
      MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_DRW, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
      BPU_base := rom_table_base + (read_data(31 downto 12) & x"000");
      -- read value 0x00000000: End of table marker
      write_data := rom_table_base+x"00C"; -- x"E00FF00C";
      MEM_AP_Write(AP=>x"00", Reg=>MEM_AP_TAR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
      MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_DRW, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
      -- read value 0x00000001: MEMTYPE Indicates that system memory is accessible on this memory map.
      write_data := rom_table_base+x"FCC"; -- x"E00FFFCC";
      MEM_AP_Write(AP=>x"00", Reg=>MEM_AP_TAR, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>write_data);
      MEM_AP_Read (AP=>x"00", Reg=>MEM_AP_DRW, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>ack, data=>read_data);
    else report "No ROM-Table found" severity error;
    end if;
    
    -- Set MEM-AP TAR to DHCSR register (offset 0xdf0) in SCS
    actual := expand_string("Set TAR");
    write_data := SCS_base + x"DF0"; -- 0xE000EDF0
    MEM_AP_Write(
      AP    => x"00",
      Reg   => MEM_AP_TAR,
      SWCLK => SWCLK,
      SWDIO => SWDIO,
      ack   => ack, 
      data  => write_data
    );
    -- Write to MEM-AP DRW, writing bits C_STOP and C_DEBUGEN of DHCSR-Register in SCS
    -- (the value will halt the CPU)
    actual := expand_string("Write DHCSR");
    write_data := x"A05F0003";
    MEM_AP_Write(
      AP    => x"00",
      Reg   => MEM_AP_DRW,
      SWCLK => SWCLK,
      SWDIO => SWDIO,
      ack   => ack, 
      data  => write_data
    );
    -- Write to MEM-AP DRW, resetting the bits C_STOP and C_DEBUGEN of DHCSR-Register in SCS
    -- (this will resume the CPU)
    actual := expand_string("Write DHCSR");
    write_data := x"A05F0000";
    MEM_AP_Write(
      AP    => x"00",
      Reg   => MEM_AP_DRW,
      SWCLK => SWCLK,
      SWDIO => SWDIO,
      ack   => ack, 
      data  => write_data
    );

    --
    --
    actual := expand_string("End of Test");
    wait;
  end process;
  
end test;