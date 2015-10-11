---------------------------------------------------
-- Module: training_and_channel_delay
--
-- Description: Allow the insertion of the training patterns into the symbol 
--              stream, and ensure a clean switch-over to the input channel
--
--              Also delay the symbols by the inter-channel skew (2 symbols per channel)
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
--  0.2 | 2015-09-18 | Resolve clock domain crossing issues
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
 
entity training_and_channel_delay is
    port (
        clk            : in  std_logic;
        channel_delay  : in  std_logic_vector(1 downto 0);
        clock_train    : in  std_logic;
        align_train    : in  std_logic;

        in_data        : in  std_logic_vector(17 downto 0);
        out_data       : out std_logic_vector(17 downto 0)  := (others => '0');
        out_data0forceneg  : out std_logic := '0';
        out_data1forceneg  : out std_logic := '0'
    );
end training_and_channel_delay;

architecture arch of training_and_channel_delay is    
    signal state             : std_logic_vector(3 downto 0)  := "0000";
    signal clock_train_meta  : std_logic := '0';
    signal clock_train_i     : std_logic := '0';
    signal align_train_meta  : std_logic := '0';
    signal align_train_i     : std_logic := '0';
    signal hold_at_state_one : std_logic_vector(9 downto 0) := "1111111111";
    
    constant CODE_K28_5    : std_logic_vector(8 downto 0) := "110111100";
    constant CODE_D11_6    : std_logic_vector(8 downto 0) := "011001011";
    constant CODE_D10_2    : std_logic_vector(8 downto 0) := "001001010";

    type a_delay_line    is array (0 to 8) of std_logic_vector(17 downto 0);
    type a_delay_line_fn is array (0 to 8) of std_logic_vector(1 downto 0);
    signal delay_line    : a_delay_line    := (others => (others => '0'));
    signal delay_line_fn : a_delay_line_fn := (others => (others => '0'));
 begin
    with channel_delay select out_data <= delay_line(5) when "00",
                                          delay_line(6) when "01",     
                                          delay_line(7) when "10",     
                                          delay_line(8) when others;
    with channel_delay select out_data0forceneg <= delay_line_fn(5)(0) when "00",
                                                   delay_line_fn(6)(0) when "01",     
                                                   delay_line_fn(7)(0) when "10",     
                                                   delay_line_fn(8)(0) when others;   
    with channel_delay select out_data1forceneg <= delay_line_fn(5)(0) when "00",
                                                   delay_line_fn(6)(0) when "01",     
                                                   delay_line_fn(7)(0) when "10",     
                                                   delay_line_fn(8)(0) when others;                                             
process(clk)
    begin
        if rising_edge(clk) then
           -- Move the dalay line along 
           delay_line(1 to 8)    <= delay_line(0 to 7);
           delay_line_fn(1 to 8) <= delay_line_fn(0 to 7);
           delay_line(0)         <= in_data;
           delay_line_fn(0)      <= (others => '0');

           -- Do we ened to hold at state 1 until valid data has filtered down the delay line?
           if align_train_i = '1' or clock_train_i = '1' then
               hold_at_state_one <= (others => '1');
            else
               hold_at_state_one <= '0' & hold_at_state_one(hold_at_state_one'high downto 1);
            end if;
            
            -- Do we need to overwrite the data in slot 5 with the sync patterns?
            case state is
                when x"5"   => state <= x"4"; delay_line(5) <= CODE_D11_6 & CODE_K28_5; delay_line_fn(5) <= (others => '1');
                when x"4"   => state <= x"3"; delay_line(5) <= CODE_D11_6 & CODE_K28_5; delay_line_fn(5) <= (others => '0');
                when x"3"   => state <= x"2"; delay_line(5) <= CODE_D10_2 & CODE_D10_2; delay_line_fn(5) <= (others => '0');
                when x"2"   => state <= x"1"; delay_line(5) <= CODE_D10_2 & CODE_D10_2; delay_line_fn(5) <= (others => '0');
                when x"1"   => state <= x"0"; delay_line(5) <= CODE_D10_2 & CODE_D10_2; delay_line_fn(5) <= (others => '0');
                                if align_train_i = '1' then
                                    state <= x"5";
                                elsif hold_at_state_one(0) = '1' then
                                    state <= x"1";
                                end if;
                when others => state <= x"0";
                                if align_train_i = '1' then
                                    state <= x"5";
                                elsif hold_at_state_one(0) = '1' then
                                    state <= x"1";
                                end if;
             end case;
             clock_train_meta <= clock_train;
             clock_train_i    <= clock_train_meta;
             align_train_meta <= align_train;
             align_train_i    <= align_train_meta;                
        end if;
    end process;
end architecture;