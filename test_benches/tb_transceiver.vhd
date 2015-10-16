----------------------------------------------------------------------------------
-- Module Name: tb_transceiver_test - Behavioral
--
-- Description: A testbench for the transceiver_test
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

entity tb_transceiver is
end entity;

architecture arch of tb_transceiver is
    component Transceiver is
    generic( use_hw_8b10b_support : std_logic := '0');    
    Port ( mgmt_clk        : in  STD_LOGIC;
           powerup_channel : in  STD_LOGIC_VECTOR;
           gclk27          : in  STD_LOGIC;

           preemp_0p0      : in  STD_LOGIC;
           preemp_3p5      : in  STD_LOGIC;
           preemp_6p0      : in  STD_LOGIC;
           
           swing_0p4       : in  STD_LOGIC;
           swing_0p6       : in  STD_LOGIC;
           swing_0p8       : in  STD_LOGIC;

           tx_running      : out STD_LOGIC_VECTOR := (others => '0');

           symbolclk       : out STD_LOGIC;
           in_symbols      : in  std_logic_vector(79 downto 0);
           
           gtptxp         : out std_logic_vector(3 downto 0);
           gtptxn         : out std_logic_vector(3 downto 0));
   end component;
      signal symbols : std_logic_vector(79 downto 0 ) := (others => '0');
    signal clk             : std_logic := '0';
	 signal symbolclk       : std_logic := '0';
    signal tx_running      : std_logic_vector(3 downto 0);    
    signal powerup_channel : std_logic_vector(3 downto 0) := "0000";    

    signal gtptxp          : std_logic_vector(3 downto 0);
    signal gtptxn          : std_logic_vector(3 downto 0);    
    signal gclk27          : STD_LOGIC := '1';
begin

uut: transceiver generic map (
      use_hw_8b10b_support => '1' 
   ) PORT MAP (
           mgmt_clk        => clk,
           powerup_channel => powerup_channel,
           gclk27          => gclk27,

           preemp_0p0      => '1',
           preemp_3p5      => '0',
           preemp_6p0      => '0',
           
           swing_0p4       => '1',
           swing_0p6       => '0',
           swing_0p8       => '0',

           tx_running      => tx_running,

           symbolclk       => symbolclk,
           in_symbols      => symbols,
           
           gtptxp          => gtptxp,
           gtptxn          => gtptxn
	);

process(symbolclk)
   begin
      if rising_edge(symbolclk) then
         if symbols(3 downto 0) = x"A" then                   
            symbols <= x"00000" & x"00000" & "0110111100" & "0110111100"   &   "0110111100" & "0000000000";
         else            
            symbols <= x"00000" & x"00000" & "0110111100" & "0110111100"   &   "0001001010" & "0001001010";
         end if;
      end if;
   end process;
process
	begin
		wait for 5 ns;
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
	end process;

process
    begin
        gclk27 <='0';
        wait for 18.5 ns;
        gclk27 <='1';
        wait for 18.5 ns;
    end process;


process
	begin
		wait for 25 ns;
		powerup_channel <= "0011";
		wait;
	end process;
	
end architecture;