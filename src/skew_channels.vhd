---------------------------------------------------
-- Module: skew_channels
--
-- Description:  Delay the symbols by the inter-channel skew (2 symbols per channel)
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



---------------------------------------------------
--
-- This is set up so the change over from test patters
-- to data happens seamlessly - e.g. the value for 
-- on data_in when send_patter_1 and send_pattern_2
-- are both become zero is guarranteed to be sent
--
-- +----+--------------------+--------------------+
-- |Word| Training pattern 1 | Training pattern 2 |
-- |    | Code  MSB    LSB   | Code   MSB     LSB |
-- +----+--------------------+-------------------+
-- |  0 | D10.2 1010101010   | K28.5- 0101111100  |
-- |  1 | D10.2 1010101010   | D11.6  0110001011  |
-- |  2 | D10.2 1010101010   | K28.5+ 1010000011  |
-- |  3 | D10.2 1010101010   | D11.6  0110001011  |
-- |  4 | D10.2 1010101010   | D10.2  1010101010  |
-- |  5 | D10.2 1010101010   | D10.2  1010101010  |
-- |  6 | D10.2 1010101010   | D10.2  1010101010  |
-- |  7 | D10.2 1010101010   | D10.2  1010101010  |
-- |  8 | D10.2 1010101010   | D10.2  1010101010  |
-- |  9 | D10.2 1010101010   | D10.2  1010101010  |
-- +----+--------------------+--------------------+
-- Patterns are transmitted LSB first.
---------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity skew_channels is
    port (
        clk            : in  std_logic;
        in_data        : in  std_logic_vector(79 downto 0);
        out_data       : out std_logic_vector(79 downto 0)  := (others => '0')
    );
end skew_channels;

architecture arch of skew_channels is    
    type a_delay_line    is array (0 to 2) of std_logic_vector(79 downto 0);
    signal delay_line    : a_delay_line    := (others => (others => '0'));
 begin
    out_data <= delay_line(2)(79 downto 60) & 
                delay_line(1)(59 downto 40) &
                delay_line(0)(39 downto 20) &
                in_data(19 downto  0);
process(clk)
    begin
        if rising_edge(clk) then
           -- Move the dalay line along 
           delay_line(1 to 2)    <= delay_line(0 to 1);
           delay_line(0)         <= in_data;
        end if;
    end process;
end architecture;