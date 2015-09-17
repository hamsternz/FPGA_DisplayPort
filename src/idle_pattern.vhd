----------------------------------------------------------------------------------
-- Module Name: idle_pattern - Behavioral
--
-- Description:  Generate a valid DisplayPort symbol stream for testing.
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
----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity idle_pattern is
    port ( 
        clk          : in  std_logic;
        data0        : out std_logic_vector(7 downto 0);
        data0k       : out std_logic;
        data1        : out std_logic_vector(7 downto 0);
        data1k       : out std_logic;
        switch_point : out std_logic
    );
end idle_pattern;

architecture arch of idle_pattern is 
    signal count : unsigned(12 downto 0) := (others => '0');    

    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0x3
    constant VB_ID  : std_logic_vector(8 downto 0) := "000001001";   -- 0x00  VB-ID with no video asserted 
	constant Mvid   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    
    constant D102   : std_logic_vector(8 downto 0) := "001001010";   -- D10.2

    signal d0: std_logic_vector(8 downto 0);
    signal d1: std_logic_vector(8 downto 0);

begin
    data0   <= d0(7 downto 0);
    data0k  <= d0(8);
    data1   <= d1(7 downto 0);
    data1k  <= d1(8);

process(clk)
     begin
        if rising_edge(clk) then
            switch_point <= '0';
            if count = 0 then
                d0 <= DUMMY;
                d1 <= DUMMY;
            elsif count = 2 then
                d0 <= BS;
                d1 <= VB_ID;
            elsif count = 4 then
                d0 <= Mvid;
                d1 <= Maud;
            elsif count = 6 then
                d0 <= VB_ID;
                d1 <= Mvid;
            elsif count = 8 then
                d0 <= Maud;
                d1 <= VB_ID;
            elsif count = 10 then
                d0 <= Mvid;
                d1 <= Maud;
            elsif count = 12 then
                d0 <= VB_ID;
                d1 <= Mvid;
            elsif count = 14 then
                d0 <= Maud;
                d1 <= DUMMY;
            elsif count = 16 then
                d0 <= DUMMY;
                d1 <= DUMMY;
            else
                d0 <= DUMMY;
                d1 <= DUMMY;
                switch_point <= '1';   -- can switch to the actual video at any other time  
                                       -- other than when the BS, VB-ID, Mvid, Maud sequence
            end if; 
            count <= count + 2;
        end if;
            
     end process;
end architecture;