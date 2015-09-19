----------------------------------------------------------------------------------
-- Module Name: test_source_3840_2160_YCC_422_ch2 - Behavioral
--
-- Description: Generate a valid DisplayPort symbol stream for testing. In this
--              case a 3840x2160 @ 30p grey screen.   
-- Timings:
--     YCC 422, 8 bits per component
--     H Vis   3840   V Vis   2160
--     H Front   48   V Front    3
--     H Sync    32   V Sync     5
--     H Back   112   V Back    23
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

entity test_source_3840_2160_YCC_422_ch2 is
    port ( 
        clk    : in  std_logic;
        ready  : out std_logic;
        data   : out std_logic_vector(72 downto 0) := (others => '0')
    );
end test_source_3840_2160_YCC_422_ch2;

architecture arch of test_source_3840_2160_YCC_422_ch2 is 
    type a_test_data_blocks is array (0 to 64*18-1) of std_logic_vector(8 downto 0);
    
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0xAA
    constant ZERO   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant PIX_Y0 : std_logic_vector(8 downto 0) := "011000000";   -- 0xC0
    constant PIX_Y1 : std_logic_vector(8 downto 0) := "011000000";   -- 0xC0
    constant PIX_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant PIX_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant SS     : std_logic_vector(8 downto 0) := "101011100";   -- K28.2
    constant SE     : std_logic_vector(8 downto 0) := "111111101";   -- K29.7
    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR     : std_logic_vector(8 downto 0) := "100011100";   -- K28.0
    constant FS     : std_logic_vector(8 downto 0) := "111111110";   -- K30.7
    constant FE     : std_logic_vector(8 downto 0) := "111110111";   -- K23.7

    constant VB_VS  : std_logic_vector(8 downto 0) := "000000001";   -- 0x00  VB-ID with Vertical blank asserted 
    constant VB_NVS : std_logic_vector(8 downto 0) := "000000000";   -- 0x00  VB-ID without Vertical blank asserted
	constant Mvid   : std_logic_vector(8 downto 0) := "000000010";   -- 0x02
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    

    signal   col_count     : unsigned(11 downto 0) := (others => '0');
    constant max_col_count : unsigned(11 downto 0) := to_unsigned(2054,12); -- (3840+32+48+112)*270/265-1
    
    signal   line_count      : unsigned(11 downto 0) := (others => '0');
    constant max_line_count  : unsigned(11 downto 0) := to_unsigned(2182,12); -- 2160+5+3+23     -1
    constant max_active_line : unsigned(11 downto 0) := to_unsigned(2159,12); -- 2160+5+3+23     -1
    
    signal block_count  : unsigned(4 downto 0) := (others => '0');
    signal switch_point : std_logic := '0';
    signal active_line  : std_logic := '0';
    signal phase        : std_logic := '0';

begin
    ready              <= '1';
    data(72)           <= switch_point;
    data(71 downto 36) <= (others => '0');
process(clk)
     begin
        if rising_edge(clk) then
            switch_point <= '0';
            if col_count = 0 then
                if active_line = '1' then
                    data(35 downto 0) <= ZERO & ZERO & BE & BE;
                else
                    data(35 downto 0) <= ZERO & ZERO & DUMMY & DUMMY;
                end if; 
                phase       <= '0';
                block_count <= (others => '0');
                -- we do this here to get the VB_ID field correct
                if line_count = max_line_count then
                    active_line <= '1';
                end if; 
            elsif col_count < 3913 then
                ------------------------------------
                -- Pixel data goes here
                ------------------------------------
                if active_line = '1' then
                    if block_count = 26 then
                        if phase = '0' then
                            data(35 downto 0) <= FE & FE & PIX_Cr & PIX_Cb;
                        else
                            data(35 downto 0) <= FE & FE & PIX_Y1 & PIX_Y0;
                        end if;
                        block_count <= (others => '0');
                        phase <= not phase;
                    else
                        if phase = '0' then
                            data(35 downto 0) <= PIX_Y1 & PIX_Y0 & PIX_Cr & PIX_Cb;
                        else
                            data(35 downto 0) <= PIX_Cr & PIX_Cb & PIX_Y1 & PIX_Y0;
                        end if;
                        block_count <= block_count + 1; 
                    end if;
                else
                    data(35 downto 0) <= DUMMY & DUMMY & DUMMY & DUMMY;
                    switch_point <= '1';
                end if; 
            elsif col_count = 1956 then
                if active_line = '1' then
                    data(35 downto 0) <= VB_NVS & VB_NVS & BS & BS;
                else
                    data(35 downto 0) <= VB_VS  & VB_VS  & BS & BS;
                end if;
            elsif col_count = 3914 then
                data(35 downto 0) <= Maud  & Maud & Mvid  & Mvid;
            elsif col_count = 3915 then    
                if active_line = '1' then
                    data(35 downto 0) <= Mvid  & Mvid & VB_NVS  & VB_NVS;
                else 
                    data(35 downto 0) <= Mvid  & Mvid & VB_VS  & VB_VS;
                end if;
            elsif col_count = 3917 then   data(35 downto 0) <= DUMMY & DUMMY & Maud  & Maud;
            else                          data(35 downto 0) <= DUMMY & DUMMY & DUMMY & DUMMY; 
            end if;
            
            ----------------------------------
            -- Update the counters 
            ----------------------------------
            if col_count = max_col_count then
                col_count <= (others => '0');
                if line_count = max_line_count then
                    line_count <= (others => '0');
                else
                    line_count <= line_count + 1;
                end if; 
            else 
                col_count <= col_count + 1; 
            end if;
        end if;            
     end process;
end architecture;