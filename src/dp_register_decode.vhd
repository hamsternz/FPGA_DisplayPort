----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: dp_register_decode - Behavioral
--
-- Description:  Extract the display port parameters from the 
--               modes from a stream of display port register values
--
----------------------------------------------------------------------------------
-- FPGA_DisplayPort from https://github.com/hamsternz/FPGA_DisplayPort
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field <hamster@snap.net.nz>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - 3 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
-- 
-- If you what to say thanks for this design either drop me an email, or how about 
-- trying PayPal to my email (hamster@snap.net.nz)?
--
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--------------------------------------------------------------------------------------
--  Ver | Date       | Change
--------+------------+---------------------------------------------------------------
--  0.1 | 2015-09-17 | Initial Version
------------------------------------------------------------------------------------

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
