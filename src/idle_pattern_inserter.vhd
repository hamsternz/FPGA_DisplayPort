----------------------------------------------------------------------------------
-- Module Name: idle_pattern_inserter - Behavioral
--
-- Description: Cleanly switches from an internally generated idle pattern
--              and the input stream.
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
--  0.2 | 2015-09-19 | Expanded to four channels
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity idle_pattern_inserter is
        port ( 
            clk              : in  std_logic;
            channel_ready    : in  std_logic;
            source_ready     : in  std_logic;
            in_data          : in  std_logic_vector(72 downto 0); -- Bit 72 is the switch point indicator
            out_data         : out std_logic_vector(71 downto 0) := (others => '0')
        );
end entity; 

architecture arch of idle_pattern_inserter is
    signal count_to_switch   : unsigned(16 downto 0) := (others => '0');
    signal source_ready_last : std_logic := '0';
    signal idle_switch_point : std_logic := '0';
    
    signal idle_count : unsigned(12 downto 0) := (others => '0');    

    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0x3
    constant VB_ID  : std_logic_vector(8 downto 0) := "000001001";   -- 0x09  VB-ID with no video asserted 
    constant Mvid   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    

    signal idle_data: std_logic_vector(17 downto 0) := (others => '0');
    signal channel_ready_i    : std_logic;
    signal channel_ready_meta : std_logic;
        
begin

process(clk) 
    begin
        if rising_edge(clk) then
            if count_to_switch(16) = '1' then
                out_data  <= in_data(71 downto 0);
            else
                -- send idle pattern
                out_data   <= idle_data & idle_data & idle_data & idle_data;
            end if;
            if count_to_switch(16) = '0' then
                -- The last tick over requires the source to be ready
                -- and to be asserting that it is in the switch point.
                if count_to_switch(15 downto 0) = x"FFFF" then
                    -- Bit 72 is the switch point indicator
                    if source_ready = '1' and in_data(72)= '1' and idle_switch_point = '1' then
                        count_to_switch <= count_to_switch + 1;
                    end if;
                else
                   -- Wait while we send out at least 64k of idle patterns
                   count_to_switch <= count_to_switch + 1;
                end if;
            end if;
            ------------------------------------------------------------------------
            -- If either the source drops or the channel is not ready, then reset
            -- to emitting the idle pattern. 
            ------------------------------------------------------------------------
            if channel_ready_i = '0' or (source_ready = '0' and source_ready_last = '1') then
                count_to_switch <= (others => '0');
            end if;
            source_ready_last  <= source_ready;
            
            -------------------------------------------------------------------------------            
            -- We can either be odd or even aligned, depending on where the last BS symbol
            -- was seen. We need to send the next one 8192 symbols later (4096 cycles)
            -------------------------------------------------------------------------------            
            idle_switch_point <= '0';
                -- For the even aligment
            if idle_count = 0 then
                idle_data <= DUMMY & DUMMY;
            elsif idle_count = 2 then
                idle_data <= VB_ID & BS;
            elsif idle_count = 4 then
                idle_data <= Maud & Mvid;
            elsif idle_count = 6 then
                idle_data <= Mvid & VB_ID ;
            elsif idle_count = 8 then
                idle_data <= VB_ID & Maud;
            elsif idle_count = 10 then
                idle_data <= Maud & Mvid;
            elsif idle_count = 12 then
                idle_data <= Mvid & VB_ID;
            elsif idle_count = 14 then
                idle_data <= DUMMY & Maud;
                -- For the odd aligment
            elsif idle_count = 1 then
                idle_data <= BS & DUMMY;
            elsif idle_count = 3 then
                idle_data <= Mvid & VB_ID;             
            elsif idle_count = 5 then
                idle_data <= VB_ID & Maud;
            elsif idle_count = 7 then
                idle_data <= Maud & Mvid;
            elsif idle_count = 9 then
                idle_data <= Mvid & VB_ID;
            elsif idle_count = 11 then
                idle_data <= VB_ID & Maud;
            elsif idle_count = 12 then
                idle_data <= Mvid & VB_ID;
            elsif idle_count = 13 then
                idle_data <= Maud & Mvid;
            elsif idle_count = 15 then
                idle_data <= DUMMY & DUMMY;
            else
                idle_data <= DUMMY & DUMMY; -- can switch to the actual video at any other time
                idle_switch_point <= '1'; -- other than when the BS, VB-ID, Mvid, Maud sequence
            end if; 

            idle_count <= idle_count + 2;            
            -------------------------------------------------------  
            -- Sync with thE BS stream of the input signal but only 
            -- if we are switched over to it (indicated by the high
            -- bit of count_to_switch being set)
            -------------------------------------------------------  
            if count_to_switch(16) = '1' then
                if in_data(8 downto 0) = BS then
                    idle_count <= to_unsigned(2,idle_count'length);
                elsif in_data(17 downto 9) = BS then
                    idle_count <= to_unsigned(1,idle_count'length);
                end if; 
            end if; 
            channel_ready_i     <= channel_ready_meta; 
            channel_ready_meta  <= channel_ready;
        end if;
    end process;
end architecture;