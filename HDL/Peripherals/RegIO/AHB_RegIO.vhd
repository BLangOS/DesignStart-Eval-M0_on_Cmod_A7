library ieee;
use ieee.std_logic_1164.all;
entity AHB_RegIO is
  port (
    HCLK    : in  std_logic;
    HRESETn : in  std_logic;
    --
    HSEL    : in  std_logic;
    HREADY  : in  std_logic;
    HTRANS  : in  std_logic_vector(1 downto 0);
    HWRITE  : in  std_logic;
    HADDR   : in  std_logic_vector(9 downto 0); -- 1kByte Address Space
    HSIZE   : in  std_logic_vector(2 downto 0);
    HWDATA  : in  std_logic_vector(31 downto 0);
    --
    HREADYOUT : out std_logic;
    HRESP     : out std_logic;
    HRDATA    : out std_logic_vector(31 downto 0);
    -- IOs
    Val_0     : in  std_logic_vector(31 downto 0);
    Val_1     : in  std_logic_vector(31 downto 0);
    Val_2     : in  std_logic_vector(31 downto 0);
    Reg_0     : out std_logic_vector(31 downto 0);
    Reg_1     : out std_logic_vector(31 downto 0);
    Reg_2     : out std_logic_vector(31 downto 0)
  );
end AHB_RegIO;

library ieee;
use ieee.numeric_std.all;
architecture arch of AHB_RegIO is
  signal SEL       : std_logic;
  signal w_OK      : std_logic;
  signal wr_seli_0 : std_logic;
  signal wr_seli_1 : std_logic;
  signal wr_seli_2 : std_logic;
  signal wr_sel_0  : std_logic;
  signal wr_sel_1  : std_logic;
  signal wr_sel_2  : std_logic;
  signal r_OK      : std_logic;
  signal rd_sel_0  : std_logic;
  signal rd_sel_1  : std_logic;
  signal rd_sel_2  : std_logic;
begin
  SEL <= HSEL and HTRANS(1) and HREADY;
  
  w_decode : process (SEL,HWRITE,HADDR,HSIZE)
  begin
    w_OK      <= '1';  
    wr_seli_0 <= '0';
    wr_seli_1 <= '0';
    wr_seli_2 <= '0';
    if SEL='1' and HWRITE='1' then
      if HSIZE="010" then -- allow only 32-Bit accesses
        case to_integer(unsigned(HADDR)) is
          when 0      => wr_seli_0 <= '1';
          when 4      => wr_seli_1 <= '1';
          when 8      => wr_seli_2 <= '1';
          when others => w_OK      <= '0';
        end case;
      else
        w_OK <= '0';
      end if;
    end if;
  end process;
  
  wr_reg: process(HCLK)
  begin
    if rising_edge(HCLK) then
      wr_sel_0 <= wr_seli_0;
      wr_sel_1 <= wr_seli_1;
      wr_sel_2 <= wr_seli_2;
      if wr_sel_0='1' then Reg_0 <= HWDATA; end if;
      if wr_sel_1='1' then Reg_1 <= HWDATA; end if;
      if wr_sel_2='1' then Reg_2 <= HWDATA; end if;
    end if;
  end process;

  r_decode : process (SEL,HWRITE,HADDR,HSIZE)
  begin
    r_OK     <= '1';  
    rd_sel_0 <= '0';
    rd_sel_1 <= '0';
    rd_sel_2 <= '0';
    if SEL='1' and HWRITE='0' then
      if HSIZE="010" then -- allow only 32-Bit accesses
        case to_integer(unsigned(HADDR)) is
          when 0      => rd_sel_0 <= '1';
          when 4      => rd_sel_1 <= '1';
          when 8      => rd_sel_2 <= '1';
          when others => r_OK     <= '0';
        end case;
      else
        r_OK <= '0';
      end if;
    end if;
  end process;

  rd_reg: process(HCLK)
  begin
    if rising_edge(HCLK) then
      if    rd_sel_0='1' then HRDATA <= Val_0;
      elsif rd_sel_1='1' then HRDATA <= Val_1;
      elsif rd_sel_2='1' then HRDATA <= Val_2;
      end if;
    end if;
  end process;
  
  FSM: process(HCLK)
    type States IS (OK,E1,E2,Err);
    variable State : States := OK;
  begin
    if rising_edge(HCLK) then
      if HRESETn='0' then
        State:=OK; HREADYOUT<='1'; HRESP<='0'; 
      else
        case State is
          when OK  => 
            if r_OK='1' and w_OK='1' then State:=OK; HREADYOUT<='1'; HRESP<='0';
            else                          State:=E1; HREADYOUT<='0'; HRESP<='1';
            end if;
          when E1  => State:=E2; HREADYOUT<='1'; HRESP<='1';
          when E2  => 
            if r_OK='1' and w_OK='1' then State:=OK; HREADYOUT<='1'; HRESP<='0';
            else                          State:=E1; HREADYOUT<='0'; HRESP<='1';
            end if;
          when Err => State := Err; HREADYOUT<='0'; HRESP<='1';
        end case;
      end if;
    end if;
  end process;
  
end arch;