----------------------------------------------------------------------------------
-- Module Name: tb_training_and_channel_delay - Behavioral
--
-- Description: A testbench for training_and_channel_delay
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

entity tb_training_and_channel_delay is
end entity;

architecture tb of tb_training_and_channel_delay is
    component training_and_channel_delay is
    port (
        clk            : in  std_logic;
        channel_delay  : in  std_logic_vector(1 downto 0);
        send_pattern_1 : in  std_logic;
        send_pattern_2 : in  std_logic;
        data_in        : in  std_logic_vector(19 downto 0);
        data_out       : out std_logic_vector(19 downto 0)
    );
    end component;

    signal clk            : std_logic                     := '0';
    signal channel_delay  : std_logic_vector(1 downto 0)  := (others => '0');
    signal send_pattern_1 : std_logic                     := '0';
    signal send_pattern_2 : std_logic                     := '1';
    signal data_in        : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_0     : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_1     : std_logic_vector(19 downto 0) := (others => '0');

begin

clk_proc: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

stim_proc: process
    begin
        for i in 1 to 100 loop
            wait until rising_edge(clk);
        end loop;
        send_pattern_2 <= '0';
        data_in <= x"CCCCC";
        wait until rising_edge(clk);
        data_in <= x"33333";
        
    end process;
    
uut0: training_and_channel_delay port map (
        clk            => clk,
        channel_delay  => "00",
        send_pattern_1 => send_pattern_1,
        send_pattern_2 => send_pattern_2,
        data_in        => data_in,
        data_out       => data_out_0
    );

uut1: training_and_channel_delay port map (
        clk            => clk,
        channel_delay  => "01",
        send_pattern_1 => send_pattern_1,
        send_pattern_2 => send_pattern_2,
        data_in        => data_in,
        data_out       => data_out_1
    );
end architecture;