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
end test_source_3840_2160_YCC_422_ch2;

architecture arch of test_source_3840_2160_YCC_422_ch2 is 
    type a_test_data_blocks is array (0 to 64*18-1) of std_logic_vector(8 downto 0);
    
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0xAA
    constant ZERO   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    signal   PIX_Y0 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    signal   PIX_Y1 : std_logic_vector(8 downto 0) := "010000000";   -- 0xC0
    signal   PIX_Cb : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    signal   PIX_Cr : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

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

    signal   col_count     : unsigned(11 downto 0) := (others => '0');
    constant max_col_count : unsigned(11 downto 0) := to_unsigned(2053,12); -- (3840+32+48+112)*270/265-1
    
    signal   line_count      : unsigned(11 downto 0) := (others => '0');
    constant max_line_count  : unsigned(11 downto 0) := to_unsigned(2190,12); -- 2160+5+3+23     -1
    constant max_active_line : unsigned(11 downto 0) := to_unsigned(2159,12); -- 2160     -1
    
    signal block_count  : unsigned(5 downto 0) := (others => '0');
    signal switch_point : std_logic := '0';
    signal active_line  : std_logic := '1';
    signal phase        : std_logic := '0';

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
            
            if col_count = 1957  then
               -- flick to white  (R+G+B)
               PIX_Y0 <= std_logic_vector(to_unsigned(174, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned(174, 9));
               PIX_Cb <= std_logic_vector(to_unsigned(128, 9));
               PIX_Cr <= std_logic_vector(to_unsigned(128, 9));               
            elsif col_count = 279 then
               -- Should be yellow (G+R)
               PIX_Y0 <= std_logic_vector(to_unsigned(156, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned(156, 9));
               PIX_Cb <= std_logic_vector(to_unsigned( 47, 9));
               PIX_Cr <= std_logic_vector(to_unsigned(141, 9));
            elsif col_count = 559 then
               -- Should be Cyan (G+B)
               PIX_Y0 <= std_logic_vector(to_unsigned(127, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned(127, 9));
               PIX_Cb <= std_logic_vector(to_unsigned(155, 9));
               PIX_Cr <= std_logic_vector(to_unsigned( 47, 9));
            elsif col_count = 839 then
               -- Should be Green (G)
               PIX_Y0 <= std_logic_vector(to_unsigned(109, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned(109, 9));
               PIX_Cb <= std_logic_vector(to_unsigned( 74, 9));
               PIX_Cr <= std_logic_vector(to_unsigned( 60, 9));
            elsif col_count = 1118 then
               -- Should be Magenta (R+B)
               PIX_Y0 <= std_logic_vector(to_unsigned( 81, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned( 81, 9));
               PIX_Cb <= std_logic_vector(to_unsigned(182, 9));
               PIX_Cr <= std_logic_vector(to_unsigned(196, 9));
            elsif col_count = 1398 then
               -- Should be Red (R)
               PIX_Y0 <= std_logic_vector(to_unsigned( 63, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned( 63, 9));
               PIX_Cb <= std_logic_vector(to_unsigned(101, 9));
               PIX_Cr <= std_logic_vector(to_unsigned(209, 9));
            elsif col_count = 1678 then
               -- Should be Blue (B)
               PIX_Y0 <= std_logic_vector(to_unsigned( 34, 9));
               PIX_Y1 <= std_logic_vector(to_unsigned( 34, 9));
               PIX_Cb <= std_logic_vector(to_unsigned(209, 9));
               PIX_Cr <= std_logic_vector(to_unsigned(115, 9));
               
            end if;
            
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