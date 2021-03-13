use std.textio.all; -- typen "text" und "line"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all; -- "read"-funktion

package intel_hex_pack is

    type mem_type is array (natural range<>) of std_logic_vector(31 downto 0);
    type byte_mem_type is array (natural range<>) of std_logic_vector(7 downto 0);
  
    impure function intel_hex_read(
        file_name      : in string;
        mem_base       : in natural;
        mem_size       : in natural
    ) return mem_type;
    
    impure function extract_bytelane(
      bytelane:    in natural;
      mem_content: in mem_type
    ) return byte_mem_type;
    
end package;

package body intel_hex_pack is

    function hexchar_to_int(c : character) return integer is
        variable r : integer;
    begin
        case c is
            when '0' => r := 16#0#;
            when '1' => r := 16#1#;
            when '2' => r := 16#2#;
            when '3' => r := 16#3#;
            when '4' => r := 16#4#;
            when '5' => r := 16#5#;
            when '6' => r := 16#6#;
            when '7' => r := 16#7#;
            when '8' => r := 16#8#;
            when '9' => r := 16#9#;
            when 'a' => r := 16#a#;
            when 'b' => r := 16#b#;
            when 'c' => r := 16#c#;
            when 'd' => r := 16#d#;
            when 'e' => r := 16#e#;
            when 'f' => r := 16#f#;
            when 'A' => r := 16#A#;
            when 'B' => r := 16#B#;
            when 'C' => r := 16#C#;
            when 'D' => r := 16#D#;
            when 'E' => r := 16#E#;
            when 'F' => r := 16#F#;
            when others => 
                report "Ungueltiges Zeichen in Hex-String" severity failure;
                r := -1;
        end case;
        return r;
    end function;
    
    function hexstr_to_int(s : string(1 to 2)) return integer is
        variable r : integer := 0;
    begin
        for i in s'range loop
            r := r * 16 + hexchar_to_int(s(i));
        end loop;
        
        return r;
    end function;    
        
    impure function intel_hex_read(
        file_name      : in string;
        mem_base       : in natural;
        mem_size       : in natural
    ) return mem_type is
        file input_file           : text;
        variable input_line       : line;
        variable colon            : character;
        variable byte_count       : integer;
        variable address          : unsigned(31 downto 0) := x"00000000";
        variable byte_s           : string(1 to 2);
        variable byte_i           : integer range 0 to 255;
        variable byte_u           : unsigned(7 downto 0);
        variable csum             : unsigned(7 downto 0);
        variable offset           : unsigned(31 downto 0);
        variable word             : std_logic_vector(31 downto 0);
        variable mem_values       : mem_type(0 to mem_size / 4 - 1) := (others=>x"00000000");
        variable line_number      : integer := 0;
        variable open_status      : FILE_OPEN_STATUS;
        variable eof_record_seen  : boolean := false;
        variable byte_index       : integer range 0 to 3;
        
      begin
        assert mem_base mod mem_size = 0 report "Basisadresse des Speichers ist nicht Vielfaches seiner Groesse"  severity failure;
        assert mem_base mod 4 = 0        report "Basisadresse des Speichers ist nicht an Wortgrenze ausgerichtet" severity failure;
        
        file_open(open_status, input_file, file_name, READ_MODE);      
        
        if not (open_status = OPEN_OK) then
            report "Hex-Datei '" & file_name & "' konnte nicht geoeffnet werden." severity error;
            return mem_values;
        end if;
        
        -- One loop iteration per line in the input file
        while not (endfile(input_file) or eof_record_seen) loop
            line_number := line_number + 1;
        
            csum := x"00"; -- initialize check sum
            readline(input_file, input_line);
            
            read(input_line, colon);
            
            if colon /= ':' then
                report "Fehler in HEX-Datei " & file_name & " (Zeile " & integer'image(line_number) & "): Zeile beginnt nicht mit ':' sondern mit '" & colon &"'" severity warning;
                exit;
            end if;
            
            -- read and process byte_count
            read(input_line, byte_s);
            byte_i     := hexstr_to_int(byte_s);
            byte_u     := to_unsigned(byte_i, 8);
            csum       := csum + byte_u;
            byte_count := byte_i;
            
            -- read and process address
            read(input_line, byte_s);
            byte_i               := hexstr_to_int(byte_s);
            byte_u               := to_unsigned(byte_i, 8);
            csum                 := csum + byte_u;
            address(15 downto 8) := to_unsigned(byte_i, 8);
            
            read(input_line, byte_s);
            byte_i               := hexstr_to_int(byte_s);
            byte_u               := to_unsigned(byte_i, 8);
            csum                 := csum + byte_u;
            address(7 downto 0)  := to_unsigned(byte_i, 8);

            -- read and process record type
            read(input_line, byte_s);
            byte_i  := hexstr_to_int(byte_s);
            byte_u  := to_unsigned(byte_i, 8);
            csum    := csum + byte_u;
                
            if byte_i = 16#00# then -- Data Record
              
              -- Only lines with addresses in this memory's address range are processed
              if address >= mem_base and address + byte_count < mem_base + mem_size then            
            
                -- Compute local address offset
                offset := address - mem_base;
                
 
                for i in 0 to byte_count - 1 loop

                    -- read two character string from file
                    read(input_line, byte_s);
                    
                    -- convert character string to it's unsigned value
                    byte_u := to_unsigned(hexstr_to_int(byte_s), 8);

                    -- read old word
                    word := mem_values(to_integer(signed(offset)) / 4);
                    
                    -- modify word
                    byte_index := to_integer(offset mod 4);
                    word(8 * byte_index + 7 downto 8 * byte_index) := std_logic_vector(byte_u);

                    -- write modified word
                    mem_values(to_integer(signed(offset)) / 4) := word;
                    
                    csum  := csum + byte_u;              
                    offset := offset + 1;  
                end loop;
                
              end if;
              
            elsif byte_i = 16#01# then -- End of File Record
                eof_record_seen := true;

            elsif address=0 and byte_i = 16#02# then -- Extended Segment Address
              -- The lower nibble is prepended to all addresses that follow this record.
              -- This allows addressing up to one megabyte of address space.
              
              -- read first address byte
              read(input_line, byte_s);
              assert byte_s(2) = '0' report "Fehler in HEX-Datei (Zeile " & integer'image(line_number) & "): Unteres Nibble des High-Bytes der Segment-Adresse ist nicht 0." severity failure;                    
              byte_i                := hexstr_to_int(byte_s);
              byte_u                := to_unsigned(byte_i, 8);
              csum                  := csum + byte_u;
              address(31 downto 20) := x"000";
              address(19 downto 16) := to_unsigned(byte_i / 16, 4);
              
              -- read (and ignore) second address byte
              read(input_line, byte_s);
              assert byte_s = "00" report "Fehler in HEX-Datei (Zeile " & integer'image(line_number) & "): Low-Byte der Segment-Adresse ist nicht 0." severity failure;                    
              byte_i                := hexstr_to_int(byte_s);
              byte_u                := to_unsigned(byte_i, 8);
              csum                  := csum + byte_u;
              
            elsif byte_i = 16#03# then -- Start Segment Address (ignore)
              for i in 0 to byte_count - 1 loop
                read(input_line, byte_s);
                byte_i              := hexstr_to_int(byte_s);
                byte_u              := to_unsigned(byte_i, 8);
                csum                := csum + byte_u;
              end loop;
                 
            elsif address=0 and byte_i = 16#04# then -- Extended Linear Address
              read(input_line, byte_s);
              byte_i                := hexstr_to_int(byte_s);
              byte_u                := to_unsigned(byte_i, 8);
              csum                  := csum + byte_u;
              address(31 downto 24) := to_unsigned(byte_i, 8);
              
              read(input_line, byte_s);
              byte_i                := hexstr_to_int(byte_s);
              byte_u                := to_unsigned(byte_i, 8);
              csum                  := csum + byte_u;
              address(23 downto 16) := to_unsigned(byte_i, 8);
            
            elsif byte_i = 16#05# then -- Start Linear Address (ignore)
              for i in 0 to byte_count - 1 loop
                read(input_line, byte_s);
                byte_i               := hexstr_to_int(byte_s);
                byte_u               := to_unsigned(byte_i, 8);
                csum                 := csum + byte_u;
              end loop;

            else -- Unexpected Record
              report "Fehler in HEX-Datei (Zeile " & integer'image(line_number) & "): Dieser Record-Typ wird nicht unterstuetzt." severity failure;
                    
            end if;
                
            -- Verify check sum
            read(input_line, byte_s);
            byte_i := hexstr_to_int(byte_s);
            byte_u := to_unsigned(byte_i, 8);
            csum   := csum + byte_u;
            assert csum = 0 report "Fehler in HEX-Datei (Zeile " & integer'image(line_number) & "): Die Pruefsumme ist falsch." severity failure;
                    
        end loop;
        
        file_close(input_file);
        
        return mem_values;
    end function;

    impure function extract_bytelane(
      bytelane:    in natural;
      mem_content: in mem_type
    ) return byte_mem_type is
        variable byte_mem_values : byte_mem_type(mem_content'range) := (others=>x"00");
    begin
      if (bytelane>=0) and (bytelane <=3) then
        for i in mem_content'range loop
          byte_mem_values(i) := mem_content(i)(8*bytelane+7 downto 8*bytelane);
        end loop;
      else
        report "intel_hex_pack->extract_bytelane: wrong bytelane selected" severity error;
      end if;
      return byte_mem_values;
    end function;

end package body;