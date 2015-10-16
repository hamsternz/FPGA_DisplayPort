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

entity colour_bars_3840 is
    port ( 
        clk         : in std_logic;
        new_frame   : in std_logic;
        next_pixels : in std_logic;
        y0          : out std_logic(7 downto 0);
        y1          : out std_logic(7 downto 0);
        cb          : out std_logic(7 downto 0);
        cr          : out std_logic(7 downto 0));
    );
end test_source_3840_2160_YCC_422_ch2;

architecture arch of colour_bars_3840 is 
    constant BAR0_Y : std_logic_vector(8 downto 0)  := "11110000"; 
    constant BAR0_Cb : std_logic_vector(8 downto 0) := "10000000";
    constant BAR0_Cr : std_logic_vector(8 downto 0) := "10000000";

    constant BAR1_Y0 : std_logic_vector(8 downto 0) := "111000000";   -- 0xC0
    constant BAR1_Y1 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    constant BAR1_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR1_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant BAR2_Y0 : std_logic_vector(8 downto 0) := "110100000";   -- 0xC0
    constant BAR2_Y1 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    constant BAR2_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR2_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant BAR3_Y0 : std_logic_vector(8 downto 0) := "110000000";   -- 0xC0
    constant BAR3_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR3_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant BAR4_Y0 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    constant BAR4_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR4_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant BAR5_Y0 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    constant BAR5_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR5_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant BAR6_Y0 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    constant BAR6_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant BAR6_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    signal   col_count     : unsigned(10 downto 0) := (others => '0');
    constant max_col_count : unsigned(10 downto 0) := to_unsigned(1919,12); -- (3840+32+48+112)*270/265-1

begin

    ------------------------------------------------------------------
    -- The M number here is almost magic. Here's how to calculate it.
    --
    -- The pixel clock is 265MHz, or 53/54 of the DisplayPort's 270MHz
    -- symbol rate. As I am using YCC 422 53 pixels are being sent 
    -- every 54 cycles, allowing a constant TU size of 54 symbols with
    -- one FE symbol for padding.
    --
    -- So you should expect M to be 53/54 * 0x80000 = 0x07DA12.
    -- 
    -- And you will be wrong. Bash your head against the wall for a 
    -- week wrong.
    --  
    -- Here's the right way. A line is sent every 2054 cycles of the
    -- 135 MHz clock, or 4108 link symbols. Each line is 4032 pixel  
    -- clocks (at 265 MHz). So the M value should be 4032/4108*0x80000
    -- = 514588.4 = 0x07DA1C. 
    --
    -- That small difference is enough to make things not work. 
    --
    -- So why the difference? It's because line length (4032) doesn't 
    -- divide evenly by 53. To get this bang-on you would need to add
    -- an extra 13 symbols every 52 lines, and as it needs to transmit 
    -- two symbols per cycle this would be awkward. 
    --
    -- However the second way gives actual pixel clock is 4032/4108*270 
    -- 265.004,868 MHz.
    --
    -- 
    -- The upside of this scheme is that an accurate Mvid[7:0] value 
    -- followingthe BS and VB_ID be constant for all raster lines. So 
    -- you can use any legal value you like.
    --
    -- The downside is that you have to drive your pixel generator from
    -- the transceiver's reference clock.
    --------------------------------------------------------------------
    M_value              <= x"07DA1C"; -- For 265MHz/270Mhz
    N_value              <= x"080000";

    H_visible            <= x"F00";  -- 3840
    H_total              <= x"FC0";  -- 4032
    H_sync_width         <= x"030";  -- 128
    H_start              <= x"0A0";  -- 160 

    V_visible            <= x"870";  -- 2160
    V_total              <= x"88F"; -- 2191
    V_sync_width         <= x"003";  -- 3
    V_start              <= x"01A";  -- 26
    
    H_vsync_active_high  <= '1';
    V_vsync_active_high  <= '1';
    flag_sync_clock      <= '1';
    flag_YCCnRGB         <= '1';
    flag_422n444         <= '1';
    flag_range_reduced   <= '1';
    flag_interlaced_even <= '0';
    flag_YCC_colour_709  <= '0';
    flags_3d_Indicators  <= (others => '0');
    bits_per_colour      <= "01000";
    stream_channel_count <= "010";

    ready              <= '1';
    data(72)           <= switch_point;
    data(71 downto 36) <= (others => '0');
process(clk)
     begin
        if rising_edge(clk) then
            switch_point <= '0';
            block_count <= block_count+1; 
            if col_count = 0 then
                if active_line = '1' then
                    data(35 downto 0) <= BE & DUMMY & BE & DUMMY;
                else
                    data(35 downto 0) <= DUMMY & DUMMY & DUMMY & DUMMY;
                end if; 
                phase       <= '0';
                block_count <= (others => '0');
                -- we do this here to get the VB_ID field correct
            elsif col_count < 1957 then
                ------------------------------------
                -- Pixel data goes here
                ------------------------------------
                if active_line = '1' then
                    if block_count = 26 then
                        if phase = '0' then
                            data(35 downto 0) <= FE & PIX_Cr & FE & PIX_Cb;
                        else
                            data(35 downto 0) <= FE & PIX_Y1 & FE & PIX_Y0;
                        end if;
                        block_count <= (others => '0');
                        phase <= not phase;
                    else
                        if phase = '0' then
                            data(35 downto 0) <= PIX_Y1 & PIX_Cr & PIX_Y0 & PIX_Cb;
                        else
                            data(35 downto 0) <= PIX_Cr & PIX_Y1 & PIX_Cb & PIX_Y0;
                        end if;
                        block_count <= block_count + 1; 
                    end if;
                else
                    data(35 downto 0) <= DUMMY & DUMMY & DUMMY & DUMMY;
                    switch_point <= '1';
                end if; 
            elsif col_count = 1957 then
                if active_line = '1' then
                    data(35 downto 0) <= VB_NVS & BS & VB_NVS & BS;
                else
                    data(35 downto 0) <= VB_VS  & BS & VB_VS  & BS;
                end if;
            elsif col_count = 1958 then
                data(35 downto 0) <= Maud  & Mvid & Maud  & Mvid;
            elsif col_count = 1959 then    
                if active_line = '1' then
                    data(35 downto 0) <= Mvid  & VB_NVS  & Mvid & VB_NVS;
                else 
                    data(35 downto 0) <= Mvid  & VB_VS  & Mvid & VB_VS;
                end if;
            elsif col_count = 1960 then   data(35 downto 0) <= DUMMY & Maud  & DUMMY & Maud;
            else                          data(35 downto 0) <= DUMMY & DUMMY & DUMMY & DUMMY; 
            end if;
            
            ----------------------------------
            -- When to update the active_line,
            -- use to set VB-ID field after 
            -- te BS symbols and control
            -- emitting pixels 
            ----------------------------------
            if col_count = 1956 then 
                if line_count = max_active_line then
                    active_line <= '0';
                end if;
            end if; 
                
            if col_count = max_col_count then 
                if line_count = max_line_count then
                    active_line <= '1';
                end if;               
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