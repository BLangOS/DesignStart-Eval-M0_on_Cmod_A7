library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity CORTEX_M0_MPU_TOP is
  port(
    ExtClk      : in    std_logic;
    -- SWD Port
    SWCLK       : in    std_logic;
    SWDIO       : inout std_logic;
    -- GPIO-Ports
    btn         : in    std_logic_vector(1 downto 0);
    led         : out   std_logic_vector(1 downto 0);
    led0_b      : out   std_logic;
    led0_g      : out   std_logic;
    led0_r      : out   std_logic
  );
end CORTEX_M0_MPU_TOP;

architecture arch of CORTEX_M0_MPU_TOP is
  signal RESETn  : std_logic;
  signal RESET   : std_logic;
  signal CLK_PLL : std_logic;
  signal SWDO    : std_logic;
  signal SWDOEN  : std_logic;
  signal SWCLKs  : std_logic;
  signal SWDI    : std_logic;
  signal inputs  : std_logic_vector(31 downto 0);
  signal outputs : std_logic_vector(31 downto 0);

  -- Codefile
  constant Codefile    : string := "./../../../eclipse_WS/C_New/Debug/C_New.hex";

begin

  -- Generate system clock from external 12 MHz clock input ExtClk
  clkgen: entity work.ScaleClock
    port map (
      ExtClk => ExtClk,
      Reset  => RESET,
      SysClk => CLK_PLL
    );
    
  -- Microcontroller system
  MCU: entity work.CORTEX_M0_MPU
    generic map (
      -- System Timer Settings
      NOREF    => '0',       -- Reference Clock present
      SKEW     => '0',       -- no Skew
      TENMS    => x"01D4BF", -- ST Reload Value for 12 MHz
      -- Intel HEX Code File
      Codefile => Codefile
    )
    port map (
      CLK     => CLK_PLL,
      RESETn  => RESETn,
      RefCLK  => ExtClk,
      --
      SWCLK   => SWCLKs,
      SWDI    => SWDI,
      SWDO    => SWDO,      
      SWDOEN  => SWDOEN,
      -- GPIO-Ports
      inputs  => inputs,
      outputs => outputs
    );
    
  -- inputs
  inputs(31 downto 2) <= (others => '0');
  inputs( 1 downto 0) <= btn;
  -- outputs
  led    <= outputs(1 downto 0);
  led0_b <= not ( outputs(2) or outputs(5) or outputs(6) );
  led0_g <= not ( outputs(3) or outputs(5) or outputs(7) );
  led0_r <= not ( outputs(4) or outputs(6) or outputs(7) );

  -- PLL Reset Signal
  ResetGEN_PLL: process(ExtClk) is
    variable cnt : unsigned(4 downto 0) := (others=>'1');
  begin
    if rising_edge(ExtClk) then
      RESET <= '1'; -- assert Reset
      if cnt>0 then cnt:=cnt-1;
      else          RESET <= '0';
      end if;
    end if;
  end process;
  
  -- System Reset Signal
  SysResetGEN_System: process(CLK_PLL) is
    variable cnt : unsigned(4 downto 0) := (others=>'1');
  begin
    if rising_edge(CLK_PLL) then
      RESETn <= '0'; -- assert Reset
      if cnt>0 then cnt:=cnt-1;
      else          RESETn <= '1';
      end if;
    end if;
  end process;
  
  -- SWD interfacing
  SWDIO  <= SWDO when SWDOEN='1' else 'Z';
  SWDI   <= SWDIO;
  SWCLKs <= SWCLK;
  --
end arch;