library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity CORTEX_M0_MPU is
  generic (
    -- System Timer Settings
    NOREF : std_logic := '1';
    SKEW  : std_logic := '1';
    TENMS : std_logic_vector(23 downto 0) := x"000000";
    -- Intel HEX codefile for Memory initialization
    Codefile : string
  );
  port(
    CLK         : in  std_logic;
    RESETn      : in  std_logic;
    -- SysTick RefClk
    RefClk      : in  std_logic;
    -- SWD DEBUG Port (combine data lines with tri state buffer at top)
    SWCLK       : in  std_logic;
    SWDI        : in  std_logic;
    SWDO        : out std_logic;        
    SWDOEN      : out std_logic;
    -- GPIO-Ports
    inputs      : in  std_logic_vector(31 downto 0);
    outputs     : out std_logic_vector(31 downto 0)
  );

  -- Memory Decoding Types
  type SEGMENT_DESC is record
    seg_BASE   : unsigned(31 downto 0);   -- Segment Base
    seg_ldSIZE : natural;                 -- ld(Sement Size)
  end record SEGMENT_DESC;  
  type seg_array is array (natural range<>) of SEGMENT_DESC;
  type std_logic_vector32_array is array (natural range<>) of std_logic_vector(31 downto 0);
  -- Memory layout
  constant MEM_SEG            : natural := 0;
  constant SYC_SEG            : natural := 1;
  constant AHB_Peripheral_SEG : natural := 2;
  constant SEG_INFO   : seg_array := (
--  Number                 Base        ldSize
    MEM_SEG            => (x"00000000",14), -- 16kBytes Memory
    SYC_SEG            => (x"4001F000",12), --  4kBytes Segment for System Controller
    AHB_Peripheral_SEG => (x"40000000",10)  --  1kBytes Segment for Peripheral
  );
  constant NUM_SEG            : natural := SEG_INFO'LENGTH;

end CORTEX_M0_MPU;

architecture arch of CORTEX_M0_MPU is
  
  -- AHB-LITE MASTER PORT
  signal HCLK        : std_logic;
  signal HRESETn     : std_logic;
  signal HADDR       : std_logic_vector(31 downto 0);
  signal HBURST      : std_logic_vector( 2 downto 0);
  signal HMASTLOCK   : std_logic;
  signal HPROT       : std_logic_vector( 3 downto 0);
  signal HSIZE       : std_logic_vector( 2 downto 0);
  signal HTRANS      : std_logic_vector( 1 downto 0);
  signal HWDATA      : std_logic_vector(31 downto 0);
  signal HWRITE      : std_logic;
  signal HRDATA      : std_logic_vector(31 downto 0);
  signal HREADY      : std_logic;
  signal HRESP       : std_logic;

  -- APB Signals
  signal PCLK        : std_logic;
  signal PRESETn     : std_logic;
  signal PCLKG       : std_logic;
  signal PCLKEN      : std_logic;
  signal APBACTIVE   : std_logic;

  -- Interrupts
  signal NMI         : std_logic;
  signal IRQ         : std_logic_vector(31 downto 0);

  -- MISC
  signal FCLK        : std_logic;
  signal PORESETn    : std_logic;
  signal SYSRESETREQ : std_logic;
  signal LOCKUP      : std_logic;
  signal LOCKUPRESET : std_logic;

  -- Selection signals for AHB-Lite (one element for each segment)
  signal seg_hsel      : std_logic_vector(0 to NUM_SEG);
  signal seg_hready    : std_logic_vector(0 to NUM_SEG);
  signal seg_hrdata    : std_logic_vector32_array(0 to NUM_SEG);  
  signal seg_hresp     : std_logic_vector(0 to NUM_SEG);
--

begin
  --
  TheCore: entity work.CORTEX_M0_Core
    generic map (
      -- System Timer Settings
      NOREF => NOREF,
      SKEW  => SKEW,
      TENMS => TENMS
    )
    port map (
      -- External Clock and Reset
      Clk         => Clk,
      Resetn      => Resetn,
      -- Reference Clock for System Tier
      RefClk      => RefClk,
      -- AH-LITE MASTER PORT
      HCLK        => HCLK,  -- AHB clock
      HRESETn     => HRESETn,
      HADDR       => HADDR,
      HBURST      => HBURST,
      HMASTLOCK   => HMASTLOCK,
      HPROT       => HPROT,
      HSIZE       => HSIZE,
      HTRANS      => HTRANS,
      HWDATA      => HWDATA,
      HWRITE      => HWRITE,
      HRDATA      => HRDATA,
      HREADY      => HREADY,
      HRESP       => HRESP,
      -- APB-Signals
      PCLK        => PCLK,
      PRESETn     => PRESETn,
      PCLKG       => PCLKG,
      PCLKEN      => PCLKEN,
      APBACTIVE   => APBACTIVE,
      -- SWD DEBUG Port
      SWCLK       => SWCLK,
      SWDI        => SWDI,
      SWDO        => SWDO,          
      SWDOEN      => SWDOEN,       
      -- Interrupts
      NMI         => NMI,
      IRQ         => IRQ,
      -- System Control Signals
      FCLK        => FCLK,
      PORESETn    => PORESETn,
      SYSRESETREQ => SYSRESETREQ,
      LOCKUP      => LOCKUP,
      LOCKUPRESET => LOCKUPRESET
    );
    
  ---------------------------------------------------------------------  
  Interconnect: block
  ---------------------------------------------------------------------  
    signal seg_hsel_reg     : std_logic_vector(0 to NUM_SEG); -- new
  begin
    -- Address Decoder
    process(HADDR)  -- try to find a segment
	  variable found_selection : boolean;
    begin
	  seg_hsel(NUM_SEG) <= '1'; -- preselect default slave
	  found_selection := false;
      for i in 0 to NUM_SEG-1 loop
        seg_hsel(i) <= '0';
		assert SEG_INFO(i).seg_BASE(SEG_INFO(i).seg_ldSIZE-1 downto 0)=0
          report "Error: Segment not aligned" severity Error; 
        if (unsigned(HADDR) >= SEG_INFO(i).seg_BASE) and (unsigned(HADDR) < SEG_INFO(i).seg_BASE + 2**(SEG_INFO(i).seg_ldSIZE)) then
		  assert found_selection=false report "Error: segments overlap" severity Error;
          seg_hsel(i)       <= '1'; -- segment i selected
		  seg_hsel(NUM_SEG) <= '0'; -- deselect default slave
		  found_selection := true;
        end if;
      end loop;
    end process;
	
    -- AHB Lite Delay
    AHB_Lite_Delay: process(HCLK)
    begin
      if rising_edge(HCLK) then
        if HRESETn='0' then
          seg_hsel_reg     <= (others=>'0');
        elsif HREADY='1' then -- advance pipeline if HREADY is 1
          seg_hsel_reg     <= seg_hsel;
        end if;
      end if;
    end process;

    -- HREADY, HRDATA, HRESP Muxes
    MUX: process(seg_hsel_reg, seg_hready, seg_hrdata, seg_hresp)
    begin
      HREADY <= '1'; -- default is '1' if none is selected
      HRDATA <= (others=>'0');
      HRESP  <= '0';
      for i in seg_hsel_reg'range loop
        -- search for the selected slave
        -- one and only one of them should be selectet, at least it is the default slave
        if seg_hsel_reg(i)='1' then
          HREADY <= seg_hready(i);
          HRDATA <= seg_hrdata(i);
          HRESP  <= seg_hresp(i);
          exit;
        end if;
      end loop;
    end process;
	
  end block; -- Interconnect


  ---------------------------------------------------------------------  
  DefSlv: block -- Default Slave
  ---------------------------------------------------------------------  
    component cmsdk_ahb_default_slave is
      port (
        -- Inputs
        HCLK      : in  std_logic;                    -- Clock
        HRESETn   : in  std_logic;                    -- Reset
        HSEL      : in  std_logic;                    -- Slave select
        HTRANS    : in  std_logic_vector(1 downto 0); -- Transfer type
        HREADY    : in  std_logic;                    -- System ready
        -- Outputs
        HREADYOUT : out std_logic;                    -- Slave ready
        HRESP     : out std_logic                     -- Slave response
      );
    end component;      
  begin
    DefaultSlv: cmsdk_ahb_default_slave
      port map (
        -- Inputs
        HCLK      => HCLK,
        HRESETn   => HRESETn,
        HSEL      => seg_hsel(seg_hsel'LENGTH-1),
        HTRANS    => HTRANS,
        HREADY    => HREADY,
        -- Outputs
        HREADYOUT => seg_hready(seg_hsel'LENGTH-1),
        HRESP     => seg_hresp(seg_hsel'LENGTH-1)
      );
  end block;
  
  NMI     <= '0';
  IRQ     <= (31 downto 0 => '0');
  
  ---------------------------------------------------------------------  
  Memory: block -- Program and Data Memory
  ---------------------------------------------------------------------  
    component cmsdk_ahb_to_sram is
      generic ( AW : integer );
      port (
        -- AHB Inputs
        HCLK       : in  std_logic;
        HRESETn    : in  std_logic;
        HSEL       : in  std_logic;
        HADDR      : in  std_logic_vector(AW-1 downto 0);
        HTRANS     : in  std_logic_vector( 1 downto 0);
        HSIZE      : in  std_logic_vector( 2 downto 0);
        HWRITE     : in  std_logic;
        HWDATA     : in  std_logic_vector(31 downto 0);
        HREADY     : in  std_logic;
        -- AHB Outputs
        HREADYOUT  : out std_logic;
        HRDATA     : out std_logic_vector(31 downto 0);
        HRESP      : out std_logic;
        -- SRAM input
        SRAMRDATA  : in  std_logic_vector(31 downto 0);
        -- SRAM Outputs
        SRAMADDR   : out std_logic_vector(AW-3 downto 0);
        SRAMWDATA  : out std_logic_vector(31 downto 0);
        SRAMWEN    : out std_logic_vector( 3 downto 0);
        SRAMCS     : out std_logic
      );
    end component;
    --
	constant ld_MEM_SIZE : integer :=  SEG_INFO(MEM_SEG).seg_ldSIZE;
    signal MEM_ADDR  : std_logic_vector(ld_MEM_SIZE-3 downto 0);
    signal MEM_RDATA : std_logic_vector(31 downto 0);
    signal MEM_WDATA : std_logic_vector(31 downto 0);
    signal MEM_WEN   : std_logic_vector( 3 downto 0);
    signal MEM_CS    : std_logic;
    --
  begin
    -- 
    AHB2MEM: cmsdk_ahb_to_sram
      generic map (AW => ld_MEM_SIZE)
      port map (
        -- AHB Inputs
        HCLK      => HCLK,
        HRESETn   => HRESETn,
        HSEL      => seg_hsel(MEM_SEG), -- mem_hsel,
        HADDR     => HADDR(ld_MEM_SIZE-1 downto 0),
        HTRANS    => HTRANS,
        HSIZE     => HSIZE,
        HWRITE    => HWRITE,
        HWDATA    => HWDATA,
        HREADY    => HREADY,
        -- AHB Outputs
        HREADYOUT => seg_hready(MEM_SEG), -- mem_hreadyout,
        HRDATA    => seg_hrdata(MEM_SEG), -- mem_hrdata,
        HRESP     => seg_hresp(MEM_SEG),  -- mem_hresp,
        -- SRAM input
        SRAMRDATA => MEM_RDATA,
        -- SRAM Outputs
        SRAMADDR  => MEM_ADDR,
        SRAMWDATA => MEM_WDATA,
        SRAMWEN   => MEM_WEN,
        SRAMCS    => MEM_CS
      );
    TheMEM: entity work.FPGA_SRAM
      generic map (
        AW        => ld_MEM_SIZE-2,
        BASE_ADDR => 0,
        IHexFILE  => Codefile
      )
      port map (
        -- Inputs
        CLK   => HCLK,
        ADDR  => MEM_ADDR,
        WDATA => MEM_WDATA,
        WREN  => MEM_WEN,
        CS    => MEM_CS,
        -- Outputs
        RDATA => MEM_RDATA
      );
    --
  end block;

  ---------------------------------------------------------------------  
  System_Control: block
  ---------------------------------------------------------------------  
    component cmsdk_mcu_sysctrl is
      generic (BE: integer); -- Endianess: 0-little, 1-big
      port (
        FCLK         : in  std_logic;  -- Free running clock
        PORESETn     : in  std_logic;  -- power on reset
        -- AHB Inputs
        HCLK         : in  std_logic;
        HRESETn      : in  std_logic;
        HSEL         : in  std_logic;
        HADDR        : in  std_logic_vector(11 downto 0);
        HTRANS       : in  std_logic_vector( 1 downto 0);
        HSIZE        : in  std_logic_vector( 2 downto 0);
        HWRITE       : in  std_logic;
        HWDATA       : in  std_logic_vector(31 downto 0);
        HREADY       : in  std_logic;
        -- AHB Outputs
        HREADYOUT    : out std_logic;
        HRDATA       : out std_logic_vector(31 downto 0);
        HRESP        : out std_logic;
        -- Reset information
        SYSRESETREQ  : in  std_logic; -- System reset request
        WDOGRESETREQ : in  std_logic; -- Watchdog reset request
        LOCKUP       : in  std_logic; -- CPU locked up
        -- ECO revision number
        ECOREVNUM    : in  std_logic_vector(3 downto 0); -- ECO revision number
        -- System control signals
        REMAP        : out std_logic; -- memory remap
        PMUENABLE    : out std_logic; -- Power Management Unit enable, will be disabled in DesignStart version
        LOCKUPRESET  : out std_logic  -- Enable reset if lockup
      );
    end component;
	  constant ld_SYC_SIZE : integer :=  SEG_INFO(SYC_SEG).seg_ldSIZE;
  begin
    SYSC: cmsdk_mcu_sysctrl
      generic map (BE => 0)
      port map (
        FCLK         => FCLK,
        PORESETn     => PORESETn,
        -- AHB Inputs
        HCLK         => HCLK,
        HRESETn      => HRESETn,
        HSEL         => seg_hsel(SYC_SEG), -- sysctrl_hsel,
        HADDR        => HADDR(ld_SYC_SIZE-1 downto 0),
        HTRANS       => HTRANS,
        HSIZE        => HSIZE,
        HWRITE       => HWRITE,
        HWDATA       => HWDATA,
        HREADY       => HREADY,
        -- AHB Outputs
        HREADYOUT    => seg_hready(SYC_SEG), -- sysctrl_hreadyout,
        HRDATA       => seg_hrdata(SYC_SEG), -- sysctrl_hrdata,
        HRESP        => seg_hresp(SYC_SEG),  -- sysctrl_hresp,
        -- Reset information
        SYSRESETREQ  => SYSRESETREQ,
        WDOGRESETREQ => '0',
        LOCKUP       => LOCKUP,
        -- ECO revision number
        ECOREVNUM    => "0000",
        -- System control signals
        REMAP        => open,
        PMUENABLE    => open,
        LOCKUPRESET  => LOCKUPRESET
      );
  end block;
  ---------------------------------------------------------------------  
  User_Periperals: block
  ---------------------------------------------------------------------
    signal Reg_1, Reg_2 : std_logic_vector(31 downto 0);
--    signal inputs       : std_logic_vector(31 downto 0);
--    signal outputs      : std_logic_vector(31 downto 0);
  	constant ld_AHB_Peripheral_SIZE : integer :=  SEG_INFO(AHB_Peripheral_SEG).seg_ldSIZE;
  begin
  my_periperal: entity work.AHB_RegIO(arch)
    port map (
      HCLK      => HCLK,
      HRESETn   => HRESETn,
      --
      HSEL      => seg_hsel(AHB_Peripheral_SEG),
      HREADY    => HREADY,
      HTRANS    => HTRANS,
      HWRITE    => HWRITE,
      HADDR     => HADDR(ld_AHB_Peripheral_SIZE-1 downto 0),
      HSIZE     => HSIZE,
      HWDATA    => HWDATA,
      --
      HREADYOUT => seg_hready(AHB_Peripheral_SEG),
      HRESP     => seg_hresp(AHB_Peripheral_SEG),
      HRDATA    => seg_hrdata(AHB_Peripheral_SEG), 
      -- IOs
      Val_0     => inputs,
      Val_1     => Reg_1,
      Val_2     => Reg_2,
      Reg_0     => outputs,
      Reg_1     => Reg_1,
      Reg_2     => Reg_2
    );
  end block;
end arch;