----------------------------------------------------------------------------------
-- Module Name: test_source_800_600_RGB_444_ch4 - Behavioral
--
-- Description: Generate a valid DisplayPort symbol stream for testing. In this
--              case 800x600 white screen.   
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
--  0.1 | 2015-10-13 | Initial Version
----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_source_800_600_RGB_444_ch4 is
    port ( 
        -----------------------------------------------------
        -- The MSA values (some are range reduced and could 
        -- be 16 bits ins size)
        -----------------------------------------------------      
        M_value              : out std_logic_vector(23 downto 0);
        N_value              : out std_logic_vector(23 downto 0);
        H_visible            : out std_logic_vector(11 downto 0);
        V_visible            : out std_logic_vector(11 downto 0);
        H_total              : out std_logic_vector(11 downto 0);
        V_total              : out std_logic_vector(11 downto 0);
        H_sync_width         : out std_logic_vector(11 downto 0);
        V_sync_width         : out std_logic_vector(11 downto 0);
        H_start              : out std_logic_vector(11 downto 0);
        V_start              : out std_logic_vector(11 downto 0);
        H_vsync_active_high  : out std_logic;
        V_vsync_active_high  : out std_logic;
        flag_sync_clock      : out std_logic;
        flag_YCCnRGB         : out std_logic;
        flag_422n444         : out std_logic;
        flag_YCC_colour_709  : out std_logic;
        flag_range_reduced   : out std_logic;
        flag_interlaced_even : out std_logic;
        flags_3d_Indicators  : out std_logic_vector(1 downto 0);
        bits_per_colour      : out std_logic_vector(4 downto 0);
        stream_channel_count : out std_logic_vector(2 downto 0);

        clk    : in  std_logic;
        ready  : out std_logic;
        data   : out std_logic_vector(72 downto 0) := (others => '0')
    );
end test_source_800_600_RGB_444_ch4;

architecture arch of test_source_800_600_RGB_444_ch4 is 
    type a_test_data_blocks is array (0 to 64*6-1) of std_logic_vector(8 downto 0);
    
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0xAA
    constant SPARE  : std_logic_vector(8 downto 0) := "011111111";   -- 0xFF
    constant ZERO   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant PIX_80 : std_logic_vector(8 downto 0) := "011001100";   -- 0x80

    constant SS     : std_logic_vector(8 downto 0) := "101011100";   -- K28.2
    constant SE     : std_logic_vector(8 downto 0) := "111111101";   -- K29.7
    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR     : std_logic_vector(8 downto 0) := "100011100";   -- K28.0
    constant FS     : std_logic_vector(8 downto 0) := "111111110";   -- K30.7
    constant FE     : std_logic_vector(8 downto 0) := "111110111";   -- K23.7

    constant VB_VS  : std_logic_vector(8 downto 0) := "000000001";   -- 0x00  VB-ID with Vertical blank asserted 
    constant VB_NVS : std_logic_vector(8 downto 0) := "000000000";   -- 0x00  VB-ID without Vertical blank asserted
    constant Mvid   : std_logic_vector(8 downto 0) := "001101000";   -- 0x68
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    
    
    constant test_data_blocks : a_test_data_blocks := (
    --- Block 0 - Junk
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 

    --- Block 1 - 8 white pixels and padding
    PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, 
    FS,     DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  FE,  
    SPARE,  SPARE,  SPARE,  SPARE,  SPARE,  SPARE, SPARE, SPARE, SPARE, SPARE, 

    --- Block 2 - 8 white pixels and padding, VB-ID (-vsync), Mvid, MAud and junk
    PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, 
    BS,     VB_NVS,  MVID,   MAUD,  VB_NVS, MVID,  
    MAUD,   VB_NVS,  MVID,   MAUD,  VB_NVS, MVID,      
    MAUD,   DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    SPARE,  SPARE,  SPARE,  SPARE,  SPARE,  SPARE, SPARE, SPARE, SPARE, SPARE, 

    --- Block 3 - 8 white pixels and padding, VB-ID (+vsync), Mvid, MAud and junk
    PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, PIX_80, 
    BS,     VB_VS,  MVID,   MAUD,   VB_VS,  MVID,  
    MAUD,   DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY,  DUMMY, 
    SPARE,  SPARE,  SPARE,  SPARE,  SPARE,  SPARE, SPARE, SPARE, SPARE, SPARE, 

    --- Block 4 - DUMMY,Blank Start, VB-ID (+vsync), Mvid, MAud and junk
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    BS,    VB_VS, MVID,  MAUD,  VB_VS, MVID,  
    MAUD,  DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE,

    --- Block 5 - just blank end
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, BE,  
    SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE); 

    signal index : unsigned (8 downto 0) := (others => '0');  -- Index up to 32 x 64 symbol blocks
    signal d0: std_logic_vector(8 downto 0)  := (others => '0');
    signal d1: std_logic_vector(8 downto 0)  := (others => '0');
    signal line_count : unsigned(9 downto 0) := (others => '0');
    signal row_count  : unsigned(7 downto 0) := (others => '0');

        
    signal switch_point : std_logic := '0';

begin
    M_value              <= x"012F68";
    N_value              <= x"080000";
    H_visible            <= x"320";  -- 800
    V_visible            <= x"258";  -- 600
    H_total              <= x"420";  -- 1056
    V_total              <= x"274";  -- 628
    H_sync_width         <= x"080";  -- 128
    V_sync_width         <= x"004";   -- 4
    H_start              <= x"0D8";  -- 216 
    V_start              <= x"01b";  -- 37
    H_vsync_active_high  <= '0';
    V_vsync_active_high  <= '0';
    flag_sync_clock      <= '1';
    flag_YCCnRGB         <= '0';
    flag_422n444         <= '0';
    flag_range_reduced   <= '0';
    flag_interlaced_even <= '0';
    flag_YCC_colour_709  <= '0';
    flags_3d_Indicators  <= (others => '0');
    bits_per_colour      <= "01000";

    stream_channel_count <= "100"; 
    ready              <= '1';
    data(72)           <= switch_point;
    data(71 downto 54) <= d1 & d0;
    data(53 downto 36) <= d1 & d0; 
    data(35 downto 18) <= d1 & d0; 
    data(17 downto 0)  <= d1 & d0; 

process(clk)
     begin
        if rising_edge(clk) then
            d0   <= test_data_blocks(to_integer(index+0));
            d1   <= test_data_blocks(to_integer(index+1));
            if index(5 downto 0) = 52 then
                index(5 downto 0) <= (others => '0');
                if row_count = 131 then 
                    row_count <= (others => '0');
                    if line_count = 627 then
                        line_count <= (others => '0');
                    else
                        line_count <= line_count + 1;
                    end if;
                else  
                    row_count <= row_count +1;
                end if;

    --- Block 0 - Junk
    --- Block 1- 8 white pixels and padding
    --- Block 2 - 8 white pixels and padding, VB-ID (-vsync), Mvid, MAud and junk
    --- Block 3 - 8 white pixels and padding, VB-ID (+vsync), Mvid, MAud and junk
    --- Block 4 - DUMMY,Blank Start, VB-ID (+vsync), Mvid, MAud and junk
    --- Block 5 - just blank end
                
                index(8 downto 6) <= "000";  -- Dummy symbols
                switch_point <= '0';
                if line_count < 599 then -- lines of active video (except first and last)
                    if    row_count <  1 then  index(8 downto 6) <= "101";  -- Just blank end BE
                    elsif row_count < 100 then index(8 downto 6) <= "001";  -- Pixels plus fill                                                 
                    elsif row_count = 100 then index(8 downto 6) <= "010";  -- Pixels BS and VS-ID block (no VBLANK flag)       
                    end if;
                elsif line_count = 599 then  -- Last line of active video
                    if    row_count <  1 then  index(8 downto 6) <= "101";  -- Just blank end BE
                    elsif row_count < 100 then index(8 downto 6) <= "001";  -- Pixels plus fill 
                    elsif row_count = 100 then index(8 downto 6) <= "011";  -- Pixels BS and VS-ID block (with VBLANK flag)       
                    end if;
                else
                    -----------------------------------------------------------------
                    -- Allow switching to/from the idle pattern during the vertical blank
                    -----------------------------------------------------------------                        
                    if row_count < 100 then    switch_point <= '1';
                    elsif row_count = 100 then index(8 downto 6) <= "100";  -- Dummy symbols, BS and VS-ID block (with VBLANK flag)                        
                    end if;
                end if;
            else
                index <= index + 2;
            end if;
        end if;            
     end process;
end architecture;