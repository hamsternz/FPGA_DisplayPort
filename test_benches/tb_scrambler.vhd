----------------------------------------------------------------------------------
-- Module Name: tb_scrambler - Behavioral
--
-- Description: A testbench for the scrambler
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


entity tb_scrambler is
    Port ( a : in STD_LOGIC);
end tb_scrambler;

architecture Behavioral of tb_scrambler is
    component scrambler is
    Port ( clk        : in  STD_LOGIC;
           bypass0    : in  STD_LOGIC;
           bypass1    : in  STD_LOGIC;

           data0_in   : in  STD_LOGIC_VECTOR (7 downto 0);
           data0k_in  : in  STD_LOGIC;
           data1_in   : in  STD_LOGIC_VECTOR (7 downto 0);
           data1k_in  : in  STD_LOGIC;
           
           data0_out  : out STD_LOGIC_VECTOR (7 downto 0);
           data0k_out : out STD_LOGIC;
           data1_out  : out STD_LOGIC_VECTOR (7 downto 0);
           data1k_out : out STD_LOGIC);
    end component;

    signal clk        : STD_LOGIC := '0';

    singal bypass0    : STD_LOGIC := '0';
    signal data0_in   : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data0k_in  : STD_LOGIC := '0';
    singal bypass1    : STD_LOGIC := '0';
    signal data1_in   : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data1k_in  : STD_LOGIC := '0';
           
    signal data0_out  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data0k_out : STD_LOGIC := '0';
    signal data1_out  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data1k_out : STD_LOGIC := '0';

begin

process 
    begin
        clk <= '0'; 
        wait for 5 ns;
        clk <= '1'; 
        wait for 5 ns;
    end process;
        
uut: scrambler port map (
       clk        => clk,
       bypass0    => bypass0,
       bypass1    => bypass1,

       data0_in   => data0_in,
       data0k_in  => data0k_in,
       data1_in   => data1_in,
       data1k_in  => data1k_in,
       
       data0_out  => data0_out, 
       data0k_out => data0k_out, 
       data1_out  => data1_out,
       data1k_out => data1k_out);

end Behavioral;
