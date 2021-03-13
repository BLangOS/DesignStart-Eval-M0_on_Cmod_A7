library ieee;
use ieee.std_logic_1164.all;
entity CORTEX_M0_Core is
  generic (
    -- System Timer Settings
    NOREF : std_logic := '1';
    SKEW  : std_logic := '1';
    TENMS : std_logic_vector(23 downto 0) := x"000000"
  );
  port (
    -- External Clock and Reset
    Clk         : in  std_logic;
    Resetn      : in  std_logic;
    -- Reference Clock for System Tier
    RefClk      : in  std_logic;
    -- AH-LITE MASTER PORT
    HCLK        : out  std_logic;  -- AHB clock
    HRESETn     : out std_logic;
    HADDR       : out std_logic_vector(31 downto 0);
    HBURST      : out std_logic_vector( 2 downto 0);
    HMASTLOCK   : out std_logic;
    HPROT       : out std_logic_vector( 3 downto 0);
    HSIZE       : out std_logic_vector( 2 downto 0);
    HTRANS      : out std_logic_vector( 1 downto 0);
    HWDATA      : out std_logic_vector(31 downto 0);
    HWRITE      : out std_logic;
    HRDATA      : in  std_logic_vector(31 downto 0);
    HREADY      : in  std_logic;
    HRESP       : in  std_logic;
    -- APB-Signals
    PCLK        : out std_logic;
    PRESETn     : out std_logic;
    PCLKG       : out std_logic;
    PCLKEN      : out std_logic;
    APBACTIVE   : in  std_logic;
    -- SWD DEBUG Port
    SWCLK       : in  std_logic;
    SWDI        : in  std_logic;
    SWDO        : out std_logic;        
    SWDOEN      : out std_logic;       
    -- Interrupts
    NMI         : in  std_logic;
    IRQ         : in  std_logic_vector(31 downto 0);
    -- System Control Signals
    FCLK        : out std_logic;
    PORESETn    : out std_logic;
    SYSRESETREQ : out std_logic;
    LOCKUP      : out std_logic;
    LOCKUPRESET : in  std_logic
  );
end CORTEX_M0_Core;

architecture arch of CORTEX_M0_Core is
  -- Clock and Reset Signals
  signal FCLK_i        : std_logic;  -- free running clock
  signal PORESETn_i    : std_logic;
  signal HRESETn_i     : std_logic;
  signal DBGRESETn     : std_logic;
  -- POWER MANAGEMENT
  signal SLEEPING      : std_logic;
  signal SLEEPDEEP     : std_logic;
  -- MISC
  signal SYSRESETREQ_i : std_logic;
  signal LOCKUP_i      : std_logic;
  -- debug domain power-up signals
  signal CDBGPWRUPREQ  : std_logic;
  signal CDBGPWRUP     : std_logic;
  signal CDBGPWRUPACK  : std_logic;
  -- System Timer adaption
  signal RefClk1       : std_logic := '0';
  signal RefClk2       : std_logic := '0';
  signal STCALIB       : std_logic_vector(25 downto 0);
  signal STCLKEN       : std_logic := '0';
begin

  ---------------------------------------------------------------------  
  Processor: block -- Cortex-M0 Processor based on obfuscated model
  ---------------------------------------------------------------------  
    component cortexm0ds_logic is
      port (
        HADDR         : out std_logic_vector(31 downto 0);
        HBURST        : out std_logic_vector( 2 downto 0);
        HPROT         : out std_logic_vector( 3 downto 0);
        HSIZE         : out std_logic_vector( 2 downto 0);
        HTRANS        : out std_logic_vector( 1 downto 0);
        HWDATA        : out std_logic_vector(31 downto 0);
        HRDATA        : in  std_logic_vector(31 downto 0);
        CODEHINTDE    : out std_logic_vector( 2 downto 0);
        IRQ           : in  std_logic_vector(31 downto 0);
        STCALIB       : in  std_logic_vector(25 downto 0);
        IRQLATENCY    : in  std_logic_vector( 7 downto 0);
        ECOREVNUM     : in  std_logic_vector(27 downto 0);
        WICSENSE      : out std_logic_vector(33 downto 0);
        vis_r0_o      : out std_logic_vector(31 downto 0);
        vis_r1_o      : out std_logic_vector(31 downto 0);
        vis_r2_o      : out std_logic_vector(31 downto 0);
        vis_r3_o      : out std_logic_vector(31 downto 0);
        vis_r4_o      : out std_logic_vector(31 downto 0);
        vis_r5_o      : out std_logic_vector(31 downto 0);
        vis_r6_o      : out std_logic_vector(31 downto 0);
        vis_r7_o      : out std_logic_vector(31 downto 0);
        vis_r8_o      : out std_logic_vector(31 downto 0);
        vis_r9_o      : out std_logic_vector(31 downto 0);
        vis_r10_o     : out std_logic_vector(31 downto 0);
        vis_r11_o     : out std_logic_vector(31 downto 0);
        vis_r12_o     : out std_logic_vector(31 downto 0);
        vis_r14_o     : out std_logic_vector(31 downto 0);
        vis_msp_o     : out std_logic_vector(29 downto 0);
        vis_psp_o     : out std_logic_vector(29 downto 0);
        vis_pc_o      : out std_logic_vector(30 downto 0);
        vis_apsr_o    : out std_logic_vector( 3 downto 0);
        vis_ipsr_o    : out std_logic_vector( 5 downto 0);
        FCLK          : in  std_logic;                      -- Free running clock
        SCLK          : in  std_logic;                      -- system clock
        HCLK          : in  std_logic;                      -- AHB clock
        DCLK          : in  std_logic;                      -- Debug system clock
        PORESETn      : in  std_logic;
        DBGRESETn     : in  std_logic;
        HRESETn       : in  std_logic;
        SWCLKTCK      : in  std_logic;
        nTRST         : in  std_logic;
        HREADY        : in  std_logic;
        HRESP         : in  std_logic;
        SWDITMS       : in  std_logic;
        TDI           : in  std_logic;
        DBGRESTART    : in  std_logic;
        EDBGRQ        : in  std_logic;
        NMI           : in  std_logic;
        RXEV          : in  std_logic;
        STCLKEN       : in  std_logic;
        SLEEPHOLDREQn : in  std_logic;
        WICENREQ      : in  std_logic;
        CDBGPWRUPACK  : in  std_logic;
        SE            : in  std_logic;
        RSTBYPASS     : in  std_logic;
        HMASTLOCK     : out std_logic;
        HWRITE        : out std_logic;
        HMASTER       : out std_logic;
        CODENSEQ      : out std_logic;
        SPECHTRANS    : out std_logic;
        SWDO          : out std_logic;
        SWDOEN        : out std_logic;
        TDO           : out std_logic;
        nTDOEN        : out std_logic;
        DBGRESTARTED  : out std_logic;
        HALTED        : out std_logic;
        TXEV          : out std_logic;
        LOCKUP        : out std_logic;
        SYSRESETREQ   : out std_logic;
        GATEHCLK      : out std_logic;
        SLEEPING      : out std_logic;
        SLEEPDEEP     : out std_logic;
        WAKEUP        : out std_logic;
        SLEEPHOLDACKn : out std_logic;
        WICENACK      : out std_logic;
        CDBGPWRUPREQ  : out std_logic;
        vis_tbit_o    : out std_logic;
        vis_control_o : out std_logic;
        vis_primask_o : out std_logic
      );
    end component;
    signal ProgramCounter : std_logic_vector(31 downto 0) := (others =>'0');
  begin
    Cortex_M0: cortexm0ds_logic
      port map (
        -- Clock and Reset Signals
        FCLK          => FCLK_i,       -- Free running clock
        SCLK          => FCLK_i,       -- System clock
        HCLK          => FCLK_i,       -- AHB Bus clock
        DCLK          => FCLK_i,       -- Debug System clock
        PORESETn      => PORESETn_i,   -- PowerOn reset
        DBGRESETn     => DBGRESETn,    -- Debug System reset
        HRESETn       => HRESETn_i,    -- AHB Bus reset
        -- AHB Bus
        HADDR         => HADDR,
        HBURST        => HBURST,
        HMASTLOCK     => HMASTLOCK,       
        HPROT         => HPROT,
        HSIZE         => HSIZE,
        HTRANS        => HTRANS,
        HWDATA        => HWDATA,
        HWRITE        => HWRITE,          
        HRDATA        => HRDATA,
        HREADY        => HREADY,       -- ok
        HRESP         => HRESP,        -- ok
        -- SWD Interface
        SWCLKTCK      => SWCLK,        -- ok
        SWDITMS       => SWDI,         -- ok
        SWDO          => SWDO,
        SWDOEN        => SWDOEN,
        -- Interrupts
        NMI           => NMI,          -- ok
        IRQ           => IRQ,
        -- System Timer
        STCALIB       => STCALIB,
        STCLKEN       => STCLKEN,      -- ok
        -- Misc        
        LOCKUP        => LOCKUP_i,
        SYSRESETREQ   => SYSRESETREQ_i,
        SLEEPING      => SLEEPING,
        SLEEPDEEP     => SLEEPDEEP,
        -- debug domain power-up signals
        CDBGPWRUPACK  => CDBGPWRUPACK, -- ok
        CDBGPWRUPREQ  => CDBGPWRUPREQ,
        -- Unused Input and Output Signals
        CODEHINTDE    => open,
        IRQLATENCY    => ( 7 downto 0 => '0'),
        ECOREVNUM     => (27 downto 0 => '0'), -- Engineering Change Order (ECO) bit field
        WICSENSE      => open,      -- sleep mode
        vis_r0_o      => open,
        vis_r1_o      => open,
        vis_r2_o      => open,
        vis_r3_o      => open,
        vis_r4_o      => open,
        vis_r5_o      => open,
        vis_r6_o      => open,
        vis_r7_o      => open,
        vis_r8_o      => open,
        vis_r9_o      => open,
        vis_r10_o     => open,
        vis_r11_o     => open,
        vis_r12_o     => open,
        vis_r14_o     => open,
        vis_msp_o     => open,
        vis_psp_o     => open,
        vis_pc_o      => ProgramCounter(31 downto 1),
        vis_apsr_o    => open,
        vis_ipsr_o    => open,
        nTRST         => '1',          -- *nu*
        TDI           => '0',          -- *nu*
        DBGRESTART    => '0',          -- ok
        EDBGRQ        => '0',          -- ok --- External Debug Request
        RXEV          => '0',          -- ok -- receive event (WFE-Instruction)
        SLEEPHOLDREQn => '1',          -- ok
        WICENREQ      => '0',          -- *nu* -- sleep mode
        SE            => '0',          -- *nu* -- Scan enable DFT signal. (DFT-Design for testability)
        RSTBYPASS     => '0',          -- ok   -- Reset synchronization bypass DFT signal. 
        HMASTER       => open,
        CODENSEQ      => open,
        SPECHTRANS    => open,
        TDO           => open,
        nTDOEN        => open,
        DBGRESTARTED  => open,
        HALTED        => open,
        TXEV          => open,                -- transmit event (SEV-Instruction)
        GATEHCLK      => open,
        WAKEUP        => open,
        SLEEPHOLDACKn => open,
        WICENACK      => open,        -- sleep mode
        vis_tbit_o    => open,
        vis_control_o => open,
        vis_primask_o => open
      );
  end block;

  process(FCLK_i)
  begin
    if rising_edge(FCLK_i) then
      CDBGPWRUP    <= CDBGPWRUPREQ;
      CDBGPWRUPACK <= CDBGPWRUP;
    end if;
  end process;
    
  process(FCLK_i)
  begin
    if rising_edge(FCLK_i) then
      RefClk1 <= RefClk;
      RefClk2 <= RefClk1;
      STCLKEN <= not RefClk2 and RefClk1;
    end if;
  end process;
  STCALIB <= NOREF & SKEW & TENMS;
  
  ---------------------------------------------------------------------  
  CLKCTRL: block -- System Clock Control
  ---------------------------------------------------------------------  
    component cmsdk_mcu_clkctrl is
	    generic (CLKGATE_PRESENT: integer);
      port (
        XTAL1       : in  std_logic;  -- Clock source
        NRST        : in  std_logic;  -- active low external reset
        --
        APBACTIVE   : in  std_logic;  -- APB active status
        SLEEPING    : in  std_logic;  -- Sleep status
        SLEEPDEEP   : in  std_logic;  -- Deep Sleep status
        SYSRESETREQ : in  std_logic;  -- System reset request
        DBGRESETREQ : in  std_logic;  -- Debug reset request
        LOCKUP      : in  std_logic;  -- LOCKUP status
        LOCKUPRESET : in  std_logic;  -- Config - generation reset if locked up
        --
        CGBYPASS    : in  std_logic;  -- Clock gating bypass
        RSTBYPASS   : in  std_logic;  -- Reset by pass
        --
        XTAL2       : out std_logic;  -- Feedback for Crystal oscillator
        FCLK        : out std_logic;  -- Free running clock
        PCLK        : out std_logic;  -- Peripheral clock
        PCLKG       : out std_logic;  -- Gated PCLK for APB transfers
        PCLKEN      : out std_logic;  -- Clock divide control for AHB to APB bridge
        PORESETn    : out std_logic;  -- Power on reset
        DBGRESETn   : out std_logic;  -- Debug reset
        HRESETn     : out std_logic;  -- System and AHB reset
        PRESETn     : out std_logic   -- Peripheral reset
      );
    end component;
  begin
    CLKCTRL: cmsdk_mcu_clkctrl
	  generic map(CLKGATE_PRESENT => 0)
      port map (
        XTAL1       => CLK,           -- Clock source
        NRST        => RESETn,        -- active low external reset
        --
        APBACTIVE   => APBACTIVE,     -- APB active status
        SLEEPING    => SLEEPING,      -- Sleep status
        SLEEPDEEP   => SLEEPDEEP,     -- Deep Sleep status
        SYSRESETREQ => SYSRESETREQ_i, -- System reset request
        DBGRESETREQ => '0',           -- Debug reset request (maybe from PMU)
        LOCKUP      => LOCKUP_i,      -- LOCKUP status
        LOCKUPRESET => LOCKUPRESET,   -- Config - generation reset if locked up
        -- 
        CGBYPASS    => '0',           -- Clock gating bypass
        RSTBYPASS   => '0',           -- Reset by pass
        --
        XTAL2       => open,          -- Feedback for Crystal oscillator
        FCLK        => FCLK_i,        -- Free running clock
        PCLK        => PCLK,          -- Peripheral clock
        PCLKG       => PCLKG,         -- Gated PCLK for APB transfers
        PCLKEN      => PCLKEN,        -- Clock divide control for AHB to APB bridge
        PRESETn     => PRESETn,       -- Peripheral reset
        PORESETn    => PORESETn_i,    -- Power on reset
        DBGRESETn   => DBGRESETn,     -- Debug reset
        HRESETn     => HRESETn_i      -- System and AHB reset
      );
    HCLK        <= FCLK_i;
    HRESETn     <= HRESETn_i;
    FCLK        <= FCLK_i;
    LOCKUP      <= LOCKUP_i;
    PORESETn    <= PORESETn_i;
    SYSRESETREQ <= SYSRESETREQ_i;
  end block;

end arch;

