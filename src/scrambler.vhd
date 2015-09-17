----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: scrambler - Behavioral
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
--  0.1 | 2015-09-17 | Initial Version
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scrambler is
    Port ( clk        : in  STD_LOGIC;
           bypass0    : in  STD_LOGIC;
           bypass1    : in  STD_LOGIC;
    
           in_data0   : in  STD_LOGIC_VECTOR (7 downto 0);
           in_data0k  : in  STD_LOGIC;
           in_data1   : in  STD_LOGIC_VECTOR (7 downto 0);
           in_data1k  : in  STD_LOGIC;
           
           out_data0  : out STD_LOGIC_VECTOR (7 downto 0);
           out_data0k : out STD_LOGIC;
           out_data1  : out STD_LOGIC_VECTOR (7 downto 0);
           out_data1k : out STD_LOGIC);
end scrambler;

architecture Behavioral of scrambler is
    signal lfsr_state : STD_LOGIC_VECTOR (15 downto 0) := (others => '1');
    constant SR       : STD_LOGIC_VECTOR (7 downto 0)  := "00011100"; -- K28.0 ia used to reset the scrambler
begin

process(clk)
    variable s0 : STD_LOGIC_VECTOR (15 downto 0);
    variable s1 : STD_LOGIC_VECTOR (15 downto 0);
    begin
        if rising_edge(clk) then
            s0 := lfsr_state;
            --------------------------------------------
            -- Process symbol 0
            --------------------------------------------        
            if in_data0k = '1' or bypass0 = '1' then
                -- Bypass the scrambler for 'K' symbols (but still update LFSR state!)
                out_data0  <= in_data0;
                out_data0k <= in_data0k;
            else
                out_data0(0) <= in_data0(0) xor s0(15);
                out_data0(1) <= in_data0(1) xor s0(14);
                out_data0(2) <= in_data0(2) xor s0(13);
                out_data0(3) <= in_data0(3) xor s0(12);
                out_data0(4) <= in_data0(4) xor s0(11);
                out_data0(5) <= in_data0(5) xor s0(10);
                out_data0(6) <= in_data0(6) xor s0( 9);
                out_data0(7) <= in_data0(7) xor s0( 8);                
                out_data0k <= '0';
            end if; 

            -- generate intermediate scrambler state            
            if in_data0k = '1' and in_data0 = SR then
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
    
            --------------------------------------------
            -- Process symbol 1
            --------------------------------------------        
            if in_data1k = '1' or bypass1 = '1' then
                -- Bypass the scrambler for 'K' symbols (but still update LFSR state!)
                out_data1  <= in_data1;
                out_data1k <= in_data1k;
            else
                -- Scramble symbol 1
                out_data1(0) <= in_data1(0) xor s1(15);
                out_data1(1) <= in_data1(1) xor s1(14);
                out_data1(2) <= in_data1(2) xor s1(13);
                out_data1(3) <= in_data1(3) xor s1(12);
                out_data1(4) <= in_data1(4) xor s1(11);
                out_data1(5) <= in_data1(5) xor s1(10);
                out_data1(6) <= in_data1(6) xor s1( 9);
                out_data1(7) <= in_data1(7) xor s1( 8);                
                out_data1k <= '0';
            end if; 

            -- Update scrambler state
            if in_data1k = '1' and in_data1 = SR then
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
        end if;
    end process;

end Behavioral;
