library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package SWD_Test_pack is
  -- DP Register addresses
  constant DP_DPIDR          : std_logic_vector(1 downto 0) := "00"; -- RO
  constant DP_ABORT          : std_logic_vector(1 downto 0) := "00"; -- WO
  constant DP_CTRL_STAT      : std_logic_vector(1 downto 0) := "01"; -- RW
  constant DP_DLCR           : std_logic_vector(1 downto 0) := "01"; -- RW
  constant DP_TARGETID       : std_logic_vector(1 downto 0) := "01"; -- RO
  constant DP_DLPIDR         : std_logic_vector(1 downto 0) := "01"; -- RO
  constant DP_EVENTSTAT      : std_logic_vector(1 downto 0) := "01"; -- RO
  constant DP_SELECT         : std_logic_vector(1 downto 0) := "10"; -- WO
  constant DP_RDBUFF         : std_logic_vector(1 downto 0) := "11"; -- RO
  -- DP Register selections at address "01" (to be written in SELCT register)
  constant DP_BANK_CTRL_STAT : std_logic_vector(3 downto 0) := x"0"; -- RW
  constant DP_BANK_DLCR      : std_logic_vector(3 downto 0) := x"1"; -- RW
  constant DP_BANK_TARGETID  : std_logic_vector(3 downto 0) := x"2"; -- RO
  constant DP_BANK_DLPIDR    : std_logic_vector(3 downto 0) := x"3"; -- RO
  constant DP_BANK_EVENTSTAT : std_logic_vector(3 downto 0) := x"4"; -- RO
  -- SWD ACK responses
  constant DAP_OK    : std_logic_vector(2 downto 0) := "001";
  constant DAP_WAIT  : std_logic_vector(2 downto 0) := "010";
  constant DAP_FAULT : std_logic_vector(2 downto 0) := "100";
  
  -- MEM-AP register addresses
  constant MEM_AP_CSW  : std_logic_vector(7 downto 0) := x"00";
  constant MEM_AP_TAR  : std_logic_vector(7 downto 0) := x"04";
  constant MEM_AP_DRW  : std_logic_vector(7 downto 0) := x"0c";
  constant MEM_AP_BD0  : std_logic_vector(7 downto 0) := x"10";
  constant MEM_AP_BD1  : std_logic_vector(7 downto 0) := x"14";
  constant MEM_AP_BD2  : std_logic_vector(7 downto 0) := x"18";
  constant MEM_AP_BD3  : std_logic_vector(7 downto 0) := x"1c";
  constant MEM_AP_MBT  : std_logic_vector(7 downto 0) := x"20";
  constant MEM_AP_CFG  : std_logic_vector(7 downto 0) := x"f4";
  constant MEM_AP_BASE : std_logic_vector(7 downto 0) := x"f8";
  constant MEM_AP_IDR  : std_logic_vector(7 downto 0) := x"fc";
  
  
  procedure line_reset(signal SWCLK: in std_logic; signal SWDIO: out std_logic);

  procedure SWD_Read(
    constant APnDP: in    std_logic;
    constant A:     in    std_logic_vector(3 downto 2);
    signal   SWCLK: in    std_logic;
    signal   SWDIO: inout std_logic;
    variable ack:   out   std_logic_vector(2 downto 0);
    variable data:  out   unsigned(31 downto 0)
  );
  --
  procedure SWD_Write(
    constant APnDP: in    std_logic;
    constant A:     in    std_logic_vector(3 downto 2);
    signal   SWCLK: in    std_logic;
    signal   SWDIO: inout std_logic;
    variable ack:   out   std_logic_vector(2 downto 0);
    constant data:  in    unsigned(31 downto 0)
  );
  --
  procedure SWD_Idle(
    constant count: in    integer;
    signal   SWCLK: in    std_logic;
    signal   SWDIO: inout std_logic
  );
  
  --
  procedure MEM_AP_Read(
    constant AP:    in    std_logic_vector(7 downto 0);
    constant Reg:   in    std_logic_vector(7 downto 0);
    signal   SWCLK: in    std_logic;
    signal   SWDIO: inout std_logic;
    variable ack:   out   std_logic_vector(2 downto 0);
    variable data:  out   unsigned(31 downto 0)
  );
  --
  procedure MEM_AP_Write(
    constant AP:    in    std_logic_vector(7 downto 0);
    constant Reg:   in    std_logic_vector(7 downto 0);
    signal   SWCLK: in    std_logic;
    signal   SWDIO: inout std_logic;
    variable ack:   out   std_logic_vector(2 downto 0);
    constant data:  in    unsigned(31 downto 0)
  );
end SWD_Test_pack;

package body SWD_Test_pack is

    procedure line_reset(signal SWCLK: in std_logic; signal SWDIO: out std_logic) is
      constant reset_sequence: std_logic_vector(0 to 15) :=  "0111100111100111";
    begin
      wait until rising_edge(SWCLK); 
      -- 50 High Clock Periods
      SWDIO <= '1'; 
      for i in 1 to 50 loop 
        wait until rising_edge(SWCLK); 
      end loop;
      -- JTAG-to-SWD sequence
      for i in reset_sequence'range loop
        SWDIO <= reset_sequence(i);
        wait until rising_edge(SWCLK);
      end loop;
      -- 50 High Clock Periods
      SWDIO <= '1'; 
      for i in 1 to 50 loop -- 50 Cycles High
        wait until rising_edge(SWCLK); 
      end loop;
      -- Two Idle Cycles 
      SWDIO <= '0';
      for i in 0 to 1 loop
        wait until rising_edge(SWCLK); 
      end loop;
    end procedure;
    --
    procedure SWD_Read(
      constant APnDP: in    std_logic;
      constant A:     in    std_logic_vector(3 downto 2);
      signal   SWCLK: in    std_logic;
      signal   SWDIO: inout std_logic;
      variable ack:   out   std_logic_vector(2 downto 0);
      variable data:  out   unsigned(31 downto 0)
    ) is
      variable count:  integer := 0;
      variable ack_i:  std_logic_vector(ack'range);
      variable data_i: unsigned(data'range);
      variable parity: std_logic;
    begin
      wait until rising_edge(SWCLK); SWDIO <= '1';   -- Start
      wait until rising_edge(SWCLK); SWDIO <= APnDP; -- APnDP -> DP
      wait until rising_edge(SWCLK); SWDIO <= '1';   -- RnW -> R
      wait until rising_edge(SWCLK); SWDIO <= A(2);  -- A[2]
      wait until rising_edge(SWCLK); SWDIO <= A(3);  -- A[3]
      wait until rising_edge(SWCLK); SWDIO <= APnDP xor '1' xor A(2) xor A(3); -- Parity
      wait until rising_edge(SWCLK); SWDIO <= '0';  -- Stop
      wait until rising_edge(SWCLK); SWDIO <= '1';  -- Park
      wait until rising_edge(SWCLK); SWDIO <= 'Z';  -- Trn
      -- Target Ack
      count := 0;
      ack_i := (ack'range => 'U');
      wait until rising_edge(SWCLK);
      for i in 0 to 2 loop
        wait until falling_edge(SWCLK);
        --assert SWDOEN='1' report "No Response from Target" severity error;
        ack_i(count) := SWDIO;
        count := count+1;
      end loop;
      ack    := ack_i;
      data_i := (data'range => 'U');
      if ack_i="001" then
        -- Target data
        count  := 0;
        parity := '0';
        for i in 0 to 31 loop
          wait until falling_edge(SWCLK);
          --assert SWDOEN='1' report "No Response from Target" severity error;
          data_i(count) := SWDIO;
          count         := count+1;
          parity        := parity xor SWDIO;
        end loop;
        data := data_i;
        wait until falling_edge(SWCLK);
        -- check Target parity
        --assert SWDOEN='1'  report "No Response from Target" severity error;
        assert parity=SWDIO  report "Parity Error" severity Error;
        wait until rising_edge(SWCLK);
      else report "cannot read register" severity error;
      end if;
      --assert SWDOEN='0'  report "Target holds line" severity error;
      wait until rising_edge(SWCLK);  -- Trn
      SWDIO <= '0';
      wait until rising_edge(SWCLK);
    end procedure;
    --
    procedure SWD_Write(
      constant APnDP: in    std_logic;
      constant A:     in    std_logic_vector(3 downto 2);
      signal   SWCLK: in    std_logic;
      signal   SWDIO: inout std_logic;
      variable ack:   out   std_logic_vector(2 downto 0);
      constant data:  in    unsigned(31 downto 0)
    ) is
      variable count:  integer := 0;
      variable ack_i:  std_logic_vector(ack'range);
      variable parity: std_logic;
    begin
      wait until rising_edge(SWCLK); SWDIO <= '1';   -- Start
      wait until rising_edge(SWCLK); SWDIO <= APnDP; -- APnDP -> DP
      wait until rising_edge(SWCLK); SWDIO <= '0';   -- RnW -> R
      wait until rising_edge(SWCLK); SWDIO <= A(2);  -- A[2]
      wait until rising_edge(SWCLK); SWDIO <= A(3);  -- A[3]
      wait until rising_edge(SWCLK); SWDIO <= APnDP xor '0' xor A(2) xor A(3); -- Parity
      wait until rising_edge(SWCLK); SWDIO <= '0';   -- Stop
      wait until rising_edge(SWCLK); SWDIO <= '1';   -- Park
      wait until rising_edge(SWCLK); SWDIO <= 'Z';   -- Trn
      -- Target Ack
      count := 0;
      ack_i := (ack'range => 'U');
      wait until rising_edge(SWCLK);
      for i in 0 to 2 loop
        wait until falling_edge(SWCLK);
        --assert SWDOEN='1' report "No Response from Target" severity error;
        ack_i(count) := SWDIO;
        count := count+1;
      end loop;
      ack := ack_i;
      wait until rising_edge(SWCLK); -- Trn
      if ack_i="001" then
        count  := 0;
        parity := '0';
        for i in 0 to 31 loop
          wait until rising_edge(SWCLK);
          --assert SWDOEN='0' report "Illegal Response from Target" severity error;
          SWDIO   <= data(count);
          parity := parity xor data(count);
          count  := count+1;
        end loop;
        -- add Host parity
        --assert SWDOEN='0'  report "Illegal Response from Target" severity error;
        wait until rising_edge(SWCLK);
        SWDIO   <= parity;
      else report "cannot write register" severity error;
      end if;
      --assert SWDOEN='0'  report "Target holds line" severity error;
      wait until rising_edge(SWCLK);
      SWDIO <= '0';
      wait until rising_edge(SWCLK);
    end procedure;
    --
    procedure SWD_Idle(
      constant count: in    integer;
      signal   SWCLK: in    std_logic;
      signal   SWDIO: inout std_logic
    ) is
    begin
      SWDIO <= '0';
      for i in 1 to count loop
        wait until rising_edge(SWCLK);
      end loop;
    end procedure;
    
    --
    procedure MEM_AP_Read(
      constant AP:    in    std_logic_vector(7 downto 0);
      constant Reg:   in    std_logic_vector(7 downto 0);
      signal   SWCLK: in    std_logic;
      signal   SWDIO: inout std_logic;
      variable ack:   out   std_logic_vector(2 downto 0);
      variable data:  out   unsigned(31 downto 0)
    ) is
      variable write_data : unsigned(31 downto 0);
      --variable read_data  : unsigned(31 downto 0);
      variable acki       : std_logic_vector(2 downto 0);
    begin
      -- write DP_SELECT
      write_data := unsigned(AP) & x"0000" & unsigned(Reg(7 downto 4)) & x"0";
      SWD_Write(APnDP=>'0', A=>DP_SELECT, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>acki, data=>write_data);
      ack := acki;
      assert acki=DAP_OK report "MEM_AP_Read: cannot write DP_SELECT" severity failure;
      -- read AP register
      SWD_Read (APnDP=>'1', A=>Reg(3 downto 2), SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>acki, data=>data);
      ack := acki;
      assert acki=DAP_OK report "MEM_AP_Read: cannot read AP register" severity failure;
      -- read DP_RDBUFF
      SWD_Read (APnDP=>'0', A=>DP_RDBUFF, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>acki, data=>data);
      ack := acki;
      assert acki=DAP_OK report "MEM_AP_Read: cannot read DP_RDBUFF" severity failure;
    end procedure;
    --
    procedure MEM_AP_Write(
      constant AP:    in    std_logic_vector(7 downto 0);
      constant Reg:   in    std_logic_vector(7 downto 0);
      signal   SWCLK: in    std_logic;
      signal   SWDIO: inout std_logic;
      variable ack:   out   std_logic_vector(2 downto 0);
      constant data:  in    unsigned(31 downto 0)
    ) is
      variable write_data : unsigned(31 downto 0);
      --variable read_data  : unsigned(31 downto 0);
      variable acki       : std_logic_vector(2 downto 0);
    begin
      -- write DP_SELECT
      write_data := unsigned(AP) & x"0000" & unsigned(Reg(7 downto 4)) & x"0";
      SWD_Write(APnDP=>'0', A=>DP_SELECT, SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>acki, data=>write_data);
      ack := acki;
      assert acki=DAP_OK report "MEM_AP_Write: cannot write DP_SELECT" severity failure;
      -- write AP register
      SWD_Write(APnDP=>'1', A=>Reg(3 downto 2), SWCLK=>SWCLK, SWDIO=>SWDIO, ack=>acki, data=>data);
      ack := acki;
      assert acki=DAP_OK report "MEM_AP_Write: cannot write AP register" severity failure;
    end procedure;
end SWD_Test_pack;
