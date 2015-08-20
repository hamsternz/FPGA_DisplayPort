----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: edid_decode - Behavioral
--
-- Description:  Extract the default video timing and
--               modes from a stream of EDID data.
--
--               The Stream must end with EDID_addr of
--               0xFF so that the checksum can be 
--               verified and valid asserted
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity edid_decode is
   port ( clk              : in std_logic;

          edid_de          : in std_logic;
          edid_data        : in std_logic_vector(7 downto 0);
          edid_addr        : in std_logic_vector(7 downto 0);
          invalidate       : in std_logic;

          valid            : out std_logic := '0';

          support_RGB444   : out std_logic := '0';
          support_YCC444   : out std_logic := '0';
          support_YCC422   : out std_logic := '0';

          pixel_clock_x10k : out std_logic_vector(15 downto 0) := (others => '0');

          h_visible_len    : out std_logic_vector(11 downto 0) := (others => '0');
          h_blank_len      : out std_logic_vector(11 downto 0) := (others => '0');
          h_front_len      : out std_logic_vector(11 downto 0) := (others => '0');
          h_sync_len       : out std_logic_vector(11 downto 0) := (others => '0');

          v_visible_len    : out std_logic_vector(11 downto 0) := (others => '0');
          v_blank_len      : out std_logic_vector(11 downto 0) := (others => '0');
          v_front_len      : out std_logic_vector(11 downto 0) := (others => '0');
          v_sync_len       : out std_logic_vector(11 downto 0) := (others => '0');
		  interlaced       : out std_logic := '0');
end edid_decode;

architecture arch of edid_decode is 
   signal checksum         : unsigned(7 downto 0);
   signal checksum_next    : unsigned(7 downto 0);
   
begin
   checksum_next <=  checksum + unsigned(edid_data);

clk_proc: process(clk) 
	begin
		if rising_edge(clk) then
			if edid_de = '1' then
				checksum <= checksum_next;
				valid    <= '0';
				case edid_addr is
					when x"00" => -- reset the checksum
								  checksum <= unsigned(edid_data);
					when x"18" => -- Colour modes supported
								  support_rgb444 <= '1';
								  support_ycc444 <= edid_data(3);
								  support_ycc422 <= edid_data(4);
					-- Timing 0 - 1	
					when x"36" => pixel_clock_x10k( 7 downto 0) <= edid_data;
					when x"37" => pixel_clock_x10k(15 downto 8) <= edid_data;
				
					-- Timing 2 - 4	
					when x"38" => h_visible_len( 7 downto 0) <= edid_data;
					when x"39" => h_blank_len(7 downto 0)    <= edid_data;
					when x"3A" => h_visible_len(11 downto 8) <= edid_data(7 downto 4);
					              h_blank_len(11 downto 8)   <= edid_data(3 downto 0);

					-- Timing 5 - 7	
					when x"3B" => v_visible_len( 7 downto 0) <= edid_data;
					when x"3C" => v_blank_len(7 downto 0)    <= edid_data;
					when x"3D" => v_visible_len(11 downto 8) <= edid_data(7 downto 4);
					              v_blank_len(11 downto 8)   <= edid_data(3 downto 0);
					-- Timing 8 - 11
					when x"3E" => h_front_len( 7 downto 0)   <= edid_data;
					when x"3F" => h_sync_len(  7 downto 0)   <= edid_data;
					when x"40" => v_front_len( 3 downto 0)   <= edid_data(7 downto 4);
					              v_sync_len(  3 downto 0)   <= edid_data(3 downto 0);
					when x"41" => h_front_len( 9 downto 8)   <= edid_data(7 downto 6);
					              h_sync_len(  9 downto 8)   <= edid_data(5 downto 4);
					              v_front_len( 5 downto 4)   <= edid_data(3 downto 2);
					              v_sync_len(  5 downto 4)   <= edid_data(1 downto 0);
					-- Timing 11-16 not used - that is the physical 
					-- size and boarder.
					when x"7F" => if checksum_next = x"00" then
								     valid <= '1';
								  end if;
				    when others => NULL;
				end case;

				------------------------------------------------
				-- Allow for an external event to invalidate the 
				-- outputs (e.g. hot plug)
				------------------------------------------------
				if invalidate = '1' then
				   valid <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture;
