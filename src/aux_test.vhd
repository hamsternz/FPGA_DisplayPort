----------------------------------------------------------------------------------
-- Module Name: Aux_test - Behavioral
--
-- Description: Testing that the DisplayPort AUX channel works
--              as I beleive it should!
--
-- Not used in the main project, just here for reference
-- 
----------------------------------------------------------------------------------
-- FPGA_DisplayPort from https://github.com/hamsternz/FPGA_DisplayPort
--
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
-- If you what to say thanks for this design how about trying PayPal to my?
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

Library UNISIM;
use UNISIM.vcomponents.all;

entity aux_test is 
	port (
		clk         : in    std_logic;  -- Needs to be a 100 MHz signal 
		debug_pmod  : out   std_logic_vector(7 downto 0);
        dp_tx_aux_p : inout std_logic;
        dp_tx_aux_n : inout std_logic;
        dp_rx_aux_p : inout std_logic;
        dp_rx_aux_n : inout std_logic;
        dp_tx_hpd   : in    std_logic 
		
	);
end aux_test;

architecture arch of aux_test is
	signal counter   : unsigned(6 downto 0) := (others => '0');
	signal cycle     : unsigned(10 downto 0) := (others => '0'); -- in 0.5us cycles
	signal ce        : std_logic := '0';

	signal aux_data : std_logic := '0';
	signal aux_mode : std_logic := '0';
	
	signal data_sr       : std_logic_vector(127 downto 0) := (others => '0');
	signal mode_sr       : std_logic_vector(127 downto 0) := (others => '0');
	constant test_data_1 : std_logic_vector(127 downto 0) := x"55555555"        -- Sync
	                                                    & x"F0"              -- Start
	                                                    & "01100101"         -- CMD 0100 - ????
	                                                    & "01010101"         -- Addr 19:16 = 0000
	                                                    & "0101010101010101" -- Addr 15:8  = 00000000	                                                    
	                                                    & "0110011001010101" -- '0' & I2C address of 0x50
	                                                    & "0101010101010101" -- Addr 15:8  = 00000000	                                                    
	                                                    & "0101010101010101" -- Addr 15:8  = 00000000	                                                    
	                                                    & x"F0";              -- Stop
	constant test_data_2 : std_logic_vector(111 downto 0) := x"55555555"        -- Sync
                                                           & x"F0"              -- Start
                                                           & "01100110"         -- CMD 0101    = read
                                                           & "01010101"         -- Addr 19:16  = 0000
                                                           & "0101010101010101" -- Addr 15:8   = 00000000                                                        
                                                           & "0110011001010101" -- '0' & I2C address of 0x50
                                                           & "0101010110101010" -- Length of 15 = 00001111
                                                           & x"F0";              -- Stop  

	signal snoop : std_logic;
	                                                    
begin

process(clk) 
    begin
        if rising_edge(clk) then 
            debug_pmod(7 downto 1) <= (others => '0');
            debug_pmod(0) <= snoop;
        end if;
    end process;
    
i_IOBUFDS_0 : IOBUFDS
   generic map (
      DIFF_TERM => FALSE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O   => snoop,
      IO  => dp_tx_aux_p,
      IOB => dp_tx_aux_n,
      I   => aux_data,
      T   => aux_mode
   );

-- Stub off the unused inputs
i_IOBUFDS_1 : IOBUFDS
      generic map (
         DIFF_TERM => FALSE,
         IBUF_LOW_PWR => TRUE,
         IOSTANDARD => "DEFAULT",
         SLEW => "SLOW")
      port map (
         O   => open,
         IO  => dp_rx_aux_p,
         IOB => dp_rx_aux_n,
         I   => '0',
         T   => '1'
      );
        
process(clk)
	begin
		if rising_edge(clk) then
		    if ce = '1' then
		      aux_mode <= mode_sr(mode_sr'high);
		      aux_data <= data_sr(data_sr'high); 
		       if cycle = "01111111111" then
		          data_sr(test_data_1'high downto 0) <= test_data_1;
		          mode_sr(test_data_1'high downto 0) <= (others => '0');
		       elsif cycle = "11111111111" then
		          data_sr(test_data_2'high downto 0) <= test_data_2;
                  mode_sr(test_data_2'high downto 0) <= (others => '0');
		       else
		          data_sr <= data_sr(data_sr'high-1 downto 0) & '0';
		          mode_sr <= mode_sr(mode_sr'high-1 downto 0) & '1';
		       end if;
		       cycle <= cycle+1;
		    end if;
            ---------------------------------------
			-- Generate a 1MHz clock enable signal
            ---------------------------------------
			if counter = 49 then
				ce      <= '1';
				counter <= (others => '0');
			else
				ce      <= '0';
				counter <= counter+1;
			end if;
		end if;
	end process;
end arch;