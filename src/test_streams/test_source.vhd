----------------------------------------------------------------------------------
-- Module Name: test_source - Behavioral
--
-- Description: Provides a valid stream of DisplayPort Video data
-- 
----------------------------------------------------------------------------------
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity test_source is
    Port ( clk : in  STD_LOGIC;
           stream_channel_count : out std_logic_vector(2 downto 0);
           ready : out  STD_LOGIC;
           data : out  STD_LOGIC_VECTOR (72 downto 0));
end test_source;

architecture Behavioral of test_source is
    component test_source_800_600_RGB_444_colourbars_ch1 is
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
    end component;

    component test_source_800_600_RGB_444_ch1 is
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
    end component;

    component test_source_3840_2160_YCC_422_ch2 is
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
    end component;

    component test_source_800_600_RGB_444_ch2 is
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
    end component;

    component test_source_800_600_RGB_444_ch4 is
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
    end component;

    component insert_main_stream_attrbutes_one_channel is
        port (
            clk                  : std_logic;
            -----------------------------------------------------
            -- This determines how the MSA is packed
            -----------------------------------------------------      
            active               : std_logic;
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              : in std_logic_vector(23 downto 0);
            N_value              : in std_logic_vector(23 downto 0);
            H_visible            : in std_logic_vector(11 downto 0);
            V_visible            : in std_logic_vector(11 downto 0);
            H_total              : in std_logic_vector(11 downto 0);
            V_total              : in std_logic_vector(11 downto 0);
            H_sync_width         : in std_logic_vector(11 downto 0);
            V_sync_width         : in std_logic_vector(11 downto 0);
            H_start              : in std_logic_vector(11 downto 0);
            V_start              : in std_logic_vector(11 downto 0);
            H_vsync_active_high  : in std_logic;
            V_vsync_active_high  : in std_logic;
            flag_sync_clock      : in std_logic;
            flag_YCCnRGB         : in std_logic;
            flag_422n444         : in std_logic;
            flag_YCC_colour_709  : in std_logic;
            flag_range_reduced   : in std_logic;
            flag_interlaced_even : in std_logic;
            flags_3d_Indicators  : in std_logic_vector(1 downto 0);
            bits_per_colour      : in std_logic_vector(4 downto 0);

            -----------------------------------------------------
            -- The stream of pixel data coming in and out
            -----------------------------------------------------
            in_data              : in  std_logic_vector(72 downto 0);
            out_data             : out std_logic_vector(72 downto 0));
    end component;


    component insert_main_stream_attrbutes_two_channels is
        port (
            clk                  : std_logic;
            -----------------------------------------------------
            -- This determines how the MSA is packed
            -----------------------------------------------------      
            active               : std_logic;
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              : in std_logic_vector(23 downto 0);
            N_value              : in std_logic_vector(23 downto 0);
            H_visible            : in std_logic_vector(11 downto 0);
            V_visible            : in std_logic_vector(11 downto 0);
            H_total              : in std_logic_vector(11 downto 0);
            V_total              : in std_logic_vector(11 downto 0);
            H_sync_width         : in std_logic_vector(11 downto 0);
            V_sync_width         : in std_logic_vector(11 downto 0);
            H_start              : in std_logic_vector(11 downto 0);
            V_start              : in std_logic_vector(11 downto 0);
            H_vsync_active_high  : in std_logic;
            V_vsync_active_high  : in std_logic;
            flag_sync_clock      : in std_logic;
            flag_YCCnRGB         : in std_logic;
            flag_422n444         : in std_logic;
            flag_YCC_colour_709  : in std_logic;
            flag_range_reduced   : in std_logic;
            flag_interlaced_even : in std_logic;
            flags_3d_Indicators  : in std_logic_vector(1 downto 0);
            bits_per_colour      : in std_logic_vector(4 downto 0);

            -----------------------------------------------------
            -- The stream of pixel data coming in and out
            -----------------------------------------------------
            in_data              : in  std_logic_vector(72 downto 0);
            out_data             : out std_logic_vector(72 downto 0));
    end component;

    component insert_main_stream_attrbutes_four_channels is
        port (
            clk                  : std_logic;
            -----------------------------------------------------
            -- This determines how the MSA is packed
            -----------------------------------------------------      
            active               : std_logic;
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              : in std_logic_vector(23 downto 0);
            N_value              : in std_logic_vector(23 downto 0);
            H_visible            : in std_logic_vector(11 downto 0);
            V_visible            : in std_logic_vector(11 downto 0);
            H_total              : in std_logic_vector(11 downto 0);
            V_total              : in std_logic_vector(11 downto 0);
            H_sync_width         : in std_logic_vector(11 downto 0);
            V_sync_width         : in std_logic_vector(11 downto 0);
            H_start              : in std_logic_vector(11 downto 0);
            V_start              : in std_logic_vector(11 downto 0);
            H_vsync_active_high  : in std_logic;
            V_vsync_active_high  : in std_logic;
            flag_sync_clock      : in std_logic;
            flag_YCCnRGB         : in std_logic;
            flag_422n444         : in std_logic;
            flag_YCC_colour_709  : in std_logic;
            flag_range_reduced   : in std_logic;
            flag_interlaced_even : in std_logic;
            flags_3d_Indicators  : in std_logic_vector(1 downto 0);
            bits_per_colour      : in std_logic_vector(4 downto 0);

            -----------------------------------------------------
            -- The stream of pixel data coming in and out
            -----------------------------------------------------
            in_data              : in  std_logic_vector(72 downto 0);
            out_data             : out std_logic_vector(72 downto 0));
    end component;

    signal M_value              : std_logic_vector(23 downto 0);
    signal N_value              : std_logic_vector(23 downto 0);
    signal H_visible            : std_logic_vector(11 downto 0);
    signal V_visible            : std_logic_vector(11 downto 0);
    signal H_total              : std_logic_vector(11 downto 0);
    signal V_total              : std_logic_vector(11 downto 0);
    signal H_sync_width         : std_logic_vector(11 downto 0);
    signal V_sync_width         : std_logic_vector(11 downto 0);
    signal H_start              : std_logic_vector(11 downto 0);
    signal V_start              : std_logic_vector(11 downto 0);
    signal H_vsync_active_high  : std_logic;
    signal V_vsync_active_high  : std_logic;
    signal flag_sync_clock      : std_logic;
    signal flag_YCCnRGB         : std_logic;
    signal flag_422n444         : std_logic;
    signal flag_YCC_colour_709  : std_logic;
    signal flag_range_reduced   : std_logic;
    signal flag_interlaced_even : std_logic;
    signal flags_3d_Indicators  : std_logic_vector(1 downto 0);
    signal bits_per_colour      : std_logic_vector(4 downto 0);

    signal raw_data             : std_logic_vector(72 downto 0) := (others => '0');  -- With switching point

begin

--i_test_source: test_source_3840_2160_YCC_422_ch2  port map ( 
--i_test_source: test_source_800_600_RGB_444_ch1  port map ( 
--i_test_source: test_source_800_600_RGB_444_ch2  port map ( 
--i_test_source: test_source_800_600_RGB_444_ch4  port map ( 
i_test_source: test_source_800_600_RGB_444_colourbars_ch1 port map (
            M_value              => M_value,
            N_value              => N_value,
            
            H_visible            => H_visible,
            H_total              => H_total,
            H_sync_width         => H_sync_width,
            H_start              => H_start,    
            
            V_visible            => V_visible,
            V_total              => V_total,
            V_sync_width         => V_sync_width,
            V_start              => V_start,
            H_vsync_active_high  => H_vsync_active_high,
            V_vsync_active_high  => V_vsync_active_high,
            flag_sync_clock      => flag_sync_clock,
            flag_YCCnRGB         => flag_YCCnRGB,
            flag_422n444         => flag_422n444,
            flag_range_reduced   => flag_range_reduced,
            flag_interlaced_even => flag_interlaced_even,
            flag_YCC_colour_709  => flag_YCC_colour_709,
            flags_3d_Indicators  => flags_3d_Indicators,
            bits_per_colour      => bits_per_colour, 
            stream_channel_count => stream_channel_count,

            clk          => clk,
            ready        => ready,
            data         => raw_data
        );

i_insert_main_stream_attrbutes_one_channel: insert_main_stream_attrbutes_one_channel port map (
--i_insert_main_stream_attrbutes_two_channels: insert_main_stream_attrbutes_two_channels port map (
--i_insert_main_stream_attrbutes_four_channels: insert_main_stream_attrbutes_four_channels port map (
            clk                  => clk,
            active               => '1',
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              => M_value,
            N_value              => N_value,

            H_visible            => H_visible,
            H_total              => H_total,
            H_sync_width         => H_sync_width,
            H_start              => H_start,    
     
            V_visible            => V_visible,
            V_total              => V_total,
            V_sync_width         => V_sync_width,
            V_start              => V_start,
            H_vsync_active_high  => H_vsync_active_high,
            V_vsync_active_high  => V_vsync_active_high,
            flag_sync_clock      => flag_sync_clock,
            flag_YCCnRGB         => flag_YCCnRGB,
            flag_422n444         => flag_422n444,
            flag_range_reduced   => flag_range_reduced,
            flag_interlaced_even => flag_interlaced_even,
            flag_YCC_colour_709  => flag_YCC_colour_709,
            flags_3d_Indicators  => flags_3d_Indicators,
            bits_per_colour      => bits_per_colour, 
            -----------------------------------------------------
            -- The stream of pixel data coming in
            -----------------------------------------------------
            in_data              => raw_data,
            -----------------------------------------------------
            -- The stream of pixel data going out
            -----------------------------------------------------
            out_data             => data
        );
end Behavioral;