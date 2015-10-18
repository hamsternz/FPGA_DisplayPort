----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: scrambler_all_channels - Behavioral
-- Description: A x^16+x^5+x^4+x^3+1 LFSR scxrambler for DisplayPort
-- 
--              Scrambler LFSR is reset when a K.28.0 passes through it,
--              as per the DisplayPort spec.
-- 
-- Verified against the table in Apprndix C of the "PCI Express Base 
-- Specification 2.1" which uses the same polynomial.
--
-- Here are the first 32 output words when data values of "00" are scrambled: 
--
--    | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
-- ---+------------------------------------------------
-- 00 | FF 17 C0 14 B2 E7 02 82 72 6E 28 A6 BE 6D BF 8D
-- 10 | BE 40 A7 E6 2C D3 E2 B2 07 02 77 2A CD 34 BE E0
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
--  0.1 | 2015-10-17 | Initial Version
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scrambler_all_channels is
    Port ( clk        : in  STD_LOGIC;
           bypass0    : in  STD_LOGIC;
           bypass1    : in  STD_LOGIC;
    
           in_data    : in  STD_LOGIC_VECTOR (71 downto 0);
           out_data   : out STD_LOGIC_VECTOR (71 downto 0) := (others => '0'));
end scrambler_all_channels;

architecture Behavioral of scrambler_all_channels is
    type a_delay_line is array(0 to 7) of STD_LOGIC_VECTOR (17 downto 0);   
    signal lfsr_state : STD_LOGIC_VECTOR (15 downto 0) := (others => '1');
    constant SR       : STD_LOGIC_VECTOR ( 8 downto 0)  := "100011100"; -- K28.0 ia used to reset the scrambler
    signal scramble_delay : a_delay_line := (others => (others => '0'));
begin

process(clk)
    variable s0 : STD_LOGIC_VECTOR (15 downto 0);
    variable s1 : STD_LOGIC_VECTOR (15 downto 0);
    variable flipping : STD_LOGIC_VECTOR (17 downto 0);
    
    begin
        if rising_edge(clk) then
            s0 := lfsr_state;

            -- generate intermediate scrambler state            
            if in_data(8 downto 0) = SR then
                s1 := x"FFFF";    
            else
                s1(0)  := s0(8);
                s1(1)  := s0(9);
                s1(2)  := s0(10);
                s1(3)  := s0(11)                       xor s0(8);
                s1(4)  := s0(12)            xor s0(8)  xor s0(9);
                s1(5)  := s0(13) xor s0(8)  xor s0(9)  xor s0(10);
                s1(6)  := s0(14) xor s0(9)  xor s0(10) xor s0(11);
                s1(7)  := s0(15) xor s0(10) xor s0(11) xor s0(12);
                s1(8)  := s0(0)  xor s0(11) xor s0(12) xor s0(13);
                s1(9)  := s0(1)  xor s0(12) xor s0(13) xor s0(14);
                s1(10) := s0(2)  xor s0(13) xor s0(14) xor s0(15);
                s1(11) := s0(3)  xor s0(14) xor s0(15);
                s1(12) := s0(4)  xor s0(15);
                s1(13) := s0(5);
                s1(14) := s0(6);
                s1(15) := s0(7);                
            end if;
    
            -- Update scrambler state
            if in_data(17 downto 9) = SR then
                lfsr_state <= x"FFFF";    
            else
                lfsr_state(0)  <= s1(8);
                lfsr_state(1)  <= s1(9);
                lfsr_state(2)  <= s1(10);
                lfsr_state(3)  <= s1(11)                       xor s1(8);
                lfsr_state(4)  <= s1(12)            xor s1(8)  xor s1(9);
                lfsr_state(5)  <= s1(13) xor s1(8)  xor s1(9)  xor s1(10);
                lfsr_state(6)  <= s1(14) xor s1(9)  xor s1(10) xor s1(11);
                lfsr_state(7)  <= s1(15) xor s1(10) xor s1(11) xor s1(12);
                lfsr_state(8)  <= s1(0)  xor s1(11) xor s1(12) xor s1(13);
                lfsr_state(9)  <= s1(1)  xor s1(12) xor s1(13) xor s1(14);
                lfsr_state(10) <= s1(2)  xor s1(13) xor s1(14) xor s1(15);
                lfsr_state(11) <= s1(3)  xor s1(14) xor s1(15);
                lfsr_state(12) <= s1(4)  xor s1(15);
                lfsr_state(13) <= s1(5);
                lfsr_state(14) <= s1(6);
                lfsr_state(15) <= s1(7);                
            end if;

            --------------------------------------------
            -- Calculate a vector of bits to be flipped
            --------------------------------------------        
            if in_data(8) = '0' and bypass0 = '0' then
                flipping(8 downto 0) := '0' & s0(8) & s0(9) & s0(10) & s0(11) & s0(12) & s0(13) & s0(14) & s0(15);
            else
                flipping(8 downto 0) := (others => '0');
            end if; 

            if in_data(17) = '0' and bypass1 = '0' then
                flipping(17 downto 9) := '0' & s1(8) & s1(9) & s1(10) & s1(11) & s1(12) & s1(13) & s1(14) & s1(15);
            else
                flipping(17 downto 9) := (others => '0');
            end if; 
            --------------------------------------------
            -- Apply vector to channel 0
            --------------------------------------------        
            out_data <= in_data xor (flipping & flipping & flipping & flipping );
            
        end if;
    end process;

end Behavioral;
