----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: dp_register_decode - Behavioral
--
-- Description:  Extract the display port parameters from the 
--               modes from a stream of display port register values
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dp_register_decode is
   port ( clk         : in std_logic;

          de          : in std_logic;
          data        : in std_logic_vector(7 downto 0);
          addr        : in std_logic_vector(7 downto 0);
          invalidate  : in std_logic;

          valid              : out std_logic := '0';
 
          revision           : out std_logic_vector(7 downto 0) := (others => '0');
          link_rate_2_70     : out std_logic := '0';
          link_rate_1_62     : out std_logic := '0';
          extended_framing   : out std_logic := '0';
          link_count          : out std_logic_vector(3 downto 0) := (others => '0');
          max_downspread     : out std_logic_vector(7 downto 0) := (others => '0');
          coding_supported   : out std_logic_vector(7 downto 0) := (others => '0');
          port0_capabilities : out std_logic_vector(15 downto 0) := (others => '0');
          port1_capabilities : out std_logic_vector(15 downto 0) := (others => '0');
          norp               : out std_logic_vector(7 downto 0) := (others => '0')
    );
end dp_register_decode;

architecture arch of dp_register_decode is 
begin

clk_proc: process(clk) 
	begin
		if rising_edge(clk) then
			if de = '1' then
				valid    <= '0';
				case addr is
					when x"00" => revision <= data;
					when x"01" => case data is 
					                 when x"0A"  => link_rate_2_70 <= '1'; link_rate_1_62 <= '1';
					                 when x"06"  => link_rate_2_70 <= '0'; link_rate_1_62 <= '1';
					                 when others => link_rate_2_70 <= '0'; link_rate_1_62 <= '0';
					              end case;
					when x"02" => extended_framing <= data(7);
			                      link_count       <= data(3 downto 0);		 
					when x"03" => max_downspread   <= data;
					when x"04" => norp             <= data;
					when x"05" => 
					when x"06" => coding_supported <= data;	
					when x"07" => 
					when x"08" => port0_capabilities( 7 downto 0) <= data;
					when x"09" => port0_capabilities(15 downto 8) <= data;
					when x"0A" => port1_capabilities( 7 downto 0) <= data;
					when x"0B" => port1_capabilities(15 downto 8) <= data;
                                  valid <= '1';
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
