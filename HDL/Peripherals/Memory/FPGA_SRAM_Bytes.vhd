-- ----------------------------------------------------------------------------
--  Abstract : FPGA BlockRam/OnChip SRAM
-- ----------------------------------------------------------------------------
-- The read operation is pipelined. Write operation is not pipelined.
-- Based on "cmsdk_fpga_sram" from ARM
-------------------------------------------------------------------------------
-- (c) B.Lang, HS-Osnabrueck.de
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity FPGA_SRAM is 
  generic (
    AW        : natural := 10;
    BASE_ADDR : natural := 0;
    IHexFILE  : string  := "C_Basic.hex"
  );
  port (
    -- Inputs
    CLK   : in  std_logic;
    ADDR  : in  std_logic_vector(AW-1 downto 0);
    WDATA : in  std_logic_vector(  31 downto 0);
    WREN  : in  std_logic_vector(   3 downto 0);
    CS    : in  std_logic;
    -- Outputs
    RDATA : out std_logic_vector(  31 downto 0)
  );
end FPGA_SRAM;

use work.intel_hex_pack.all;
architecture arch of FPGA_SRAM is
  constant AWT : integer := 2**AW-1;
  -- Memory Array
--  constant mem_content: mem_type(0 to AWT) := intel_hex_read(IHexFILE, BASE_ADDR, 2**(AW+2));
--  signal BRAM0 : byte_mem_type(0 to AWT) := extract_bytelane(0,mem_content);
--  signal BRAM1 : byte_mem_type(0 to AWT) := extract_bytelane(1,mem_content);
--  signal BRAM2 : byte_mem_type(0 to AWT) := extract_bytelane(2,mem_content);
--  signal BRAM3 : byte_mem_type(0 to AWT) := extract_bytelane(3,mem_content);
--
-- Altera Type initioalization
--  type byte_mem_type is array (natural range<>) of std_logic_vector(7 downto 0);
  signal BRAM0 : byte_mem_type(0 to AWT); -- := extract_bytelane(0,mem_content);
  signal BRAM1 : byte_mem_type(0 to AWT); -- := extract_bytelane(1,mem_content);
  signal BRAM2 : byte_mem_type(0 to AWT); -- := extract_bytelane(2,mem_content);
  signal BRAM3 : byte_mem_type(0 to AWT); -- := extract_bytelane(3,mem_content);
  attribute ram_init_file : string;
  attribute ram_init_file of BRAM0 : signal is IHexFILE&"_0.hex";
  attribute ram_init_file of BRAM1 : signal is IHexFILE&"_1.hex";
  attribute ram_init_file of BRAM2 : signal is IHexFILE&"_2.hex";
  attribute ram_init_file of BRAM3 : signal is IHexFILE&"_3.hex";
--
  -- internal signals
  signal addr_q0      : unsigned(AW-1 downto 0);
  signal addr_q1      : unsigned(AW-1 downto 0);
  signal write_enable : std_logic_vector(   3 downto 0);
  signal cs_reg       : std_logic;
  signal read_data    : std_logic_vector(  31 downto 0);
begin

  write_enable <= WREN and (3 downto 0 => CS);
  addr_q0      <= unsigned(ADDR);

  -- Delay Signals for read
  process (CLK)
  begin
    if rising_edge(CLK) then
      cs_reg  <= CS;
      addr_q1 <= addr_q0;
    end if;
  end process;

  -- Infer Block RAM - syntax is very specific.
  process (CLK)
  begin
    if rising_edge(CLK) then
      if write_enable(0)='1' then BRAM0(to_integer(addr_q0)) <= WDATA( 7 downto  0); end if;
      if write_enable(1)='1' then BRAM1(to_integer(addr_q0)) <= WDATA(15 downto  8); end if;
      if write_enable(2)='1' then BRAM2(to_integer(addr_q0)) <= WDATA(23 downto 16); end if;
      if write_enable(3)='1' then BRAM3(to_integer(addr_q0)) <= WDATA(31 downto 24); end if;
    end if;
  end process;
  
  read_data <= BRAM3(to_integer(addr_q1)) & BRAM2(to_integer(addr_q1)) & BRAM1(to_integer(addr_q1)) & BRAM0(to_integer(addr_q1));

  RDATA <= read_data when cs_reg='1' else (RDATA'range => '0');
  
end architecture;