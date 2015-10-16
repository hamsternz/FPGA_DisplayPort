----------------------------------------------------------------------------------
-- Module Name: data_stream_test - Behavioral
--
-- Description: For sumulating the data stream, without the TX modules.
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
--  0.2 | 2015-09-29 | Updated for Opsis
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_stream_test is
    port ( 
        symbolclk           : in    STD_LOGIC;
        symbols             : out   std_logic_vector(79 downto 0)
    );
end data_stream_test;

architecture Behavioral of data_stream_test is    
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

    component idle_pattern_inserter is
        port ( 
            clk              : in  std_logic;
            channel_ready    : in  std_logic;
            source_ready     : in  std_logic;
            in_data          : in  std_logic_vector(72 downto 0);
            out_data         : out std_logic_vector(71 downto 0)
        );
    end component;    
    
    component scrambler_reset_inserter is
        port ( 
            clk      : in  std_logic;
            in_data  : in  std_logic_vector(71 downto 0);
            out_data : out std_logic_vector(71 downto 0)
        );
    end component;
    
    component scrambler is
        port ( 
            clk        : in  std_logic;
            bypass0    : in  std_logic;
            bypass1    : in  std_logic; 
            in_data    : in  std_logic_vector(17 downto 0);
            out_data   : out std_logic_vector(17 downto 0)
        );
    end component;
    
    component data_to_8b10b is
        port ( 
            clk      : in  std_logic;
            forceneg : in  std_logic_vector(1 downto 0);
            in_data  : in  std_logic_vector(17 downto 0);
            out_data : out std_logic_vector(19 downto 0)
        );
    end component;

    component training_and_channel_delay is
    port (
        clk                : in  std_logic;
        channel_delay      : in  std_logic_vector(1 downto 0);
        clock_train        : in  std_logic;
        align_train        : in  std_logic;

        in_data            : in  std_logic_vector(17 downto 0);
        out_data           : out std_logic_vector(17 downto 0);
        out_data0forceneg  : out std_logic;
        out_data1forceneg  : out std_logic
    );
    end component;

    
    signal support_RGB444   : std_logic := '0';
    signal support_YCC444   : std_logic := '0';
    signal support_YCC422   : std_logic := '0';
    
    --------------------------------------------
    -- EDID data
    ---------------------------------------------
    signal edid_valid       : std_logic := '0';
    signal pixel_clock_x10k : std_logic_vector(15 downto 0) := (others => '0');
    
    signal h_visible_len    : std_logic_vector(11 downto 0) := (others => '0');
    signal h_blank_len      : std_logic_vector(11 downto 0) := (others => '0');
    signal h_front_len      : std_logic_vector(11 downto 0) := (others => '0');
    signal h_sync_len       : std_logic_vector(11 downto 0) := (others => '0');
    
    signal v_visible_len    : std_logic_vector(11 downto 0) := (others => '0');
    signal v_blank_len      : std_logic_vector(11 downto 0) := (others => '0');
    signal v_front_len      : std_logic_vector(11 downto 0) := (others => '0');
    signal v_sync_len       : std_logic_vector(11 downto 0) := (others => '0');
    signal interlaced       : std_logic := '0';
    --------------------------------------------
    -- Display port data
    ---------------------------------------------
    signal dp_valid              : std_logic := '0';
    signal dp_revision           : std_logic_vector(7 downto 0) := (others => '0');
    signal dp_link_rate_2_70     : std_logic := '0';
    signal dp_link_rate_1_62     : std_logic := '0';
    signal dp_extended_framing   : std_logic := '0';
    signal dp_link_count         : std_logic_vector(3 downto 0) := (others => '0');
    signal dp_max_downspread     : std_logic_vector(7 downto 0) := (others => '0');
    signal dp_coding_supported   : std_logic_vector(7 downto 0) := (others => '0');
    signal dp_port0_capabilities : std_logic_vector(15 downto 0) := (others => '0');
    signal dp_port1_capabilities : std_logic_vector(15 downto 0) := (others => '0');
    signal dp_norp               : std_logic_vector(7 downto 0) := (others => '0');
    --------------------------------------------------------------------------
    signal tx_powerup       : std_logic := '0';
    signal tx_clock_train   : std_logic := '0';
    signal tx_align_train   : std_logic := '0';    
    signal data_channel_0   : std_logic_vector(19 downto 0):= (others => '0');

    ------------------------------------------------
    signal tx_debug        : std_logic_vector(7 downto 0);
   
    signal sink_channel_count   : std_logic_vector(2 downto 0) := "000";
    signal source_channel_count : std_logic_vector(2 downto 0) := "010";
    signal active_channel_count : std_logic_vector(2 downto 0) := "000";
    signal stream_channel_count : std_logic_vector(2 downto 0) := "000";

    signal test_signal : std_logic_vector(8 downto 0);

    signal scramble_bypass        : std_logic;
    signal test_signal_ready      : std_logic;
    
    signal test_signal_data    : std_logic_vector(72 downto 0) := (others => '0');  -- With switching point
    signal msa_merged_data     : std_logic_vector(72 downto 0) := (others => '0');  -- With switching point
    signal signal_data         : std_logic_vector(71 downto 0) := (others => '0');
    signal sr_inserted_data    : std_logic_vector(71 downto 0) := (others => '0');    
    signal scrambled_data      : std_logic_vector(71 downto 0) := (others => '0');
    signal final_data          : std_logic_vector(71 downto 0) := (others => '0');
    signal force_parity_neg    : std_logic_vector( 7 downto 0) := (others => '0');
    
    signal hpd_irq     : std_logic;
    signal hpd_present : std_logic;

    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR     : std_logic_vector(8 downto 0) := "100011100";   -- K28.0

    constant delay_index : std_logic_vector(7 downto 0) := "11100100"; -- 3,2,1,0 for use as a lookup table in the generate loop
    signal count : unsigned(15 downto 0) := (others => '0');

begin
    sink_channel_count <= dp_link_count(2 downto 0);

i_test_source: test_source_800_600_RGB_444_ch4  port map ( 
--i_test_source: test_source_3840_2160_YCC_422_ch2  port map ( 
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

            clk          => symbolclk,
            ready        => test_signal_ready,
            data         => test_signal_data
        );

--i_insert_main_stream_attrbutes_one_channel: insert_main_stream_attrbutes_one_channel port map (
--i_insert_main_stream_attrbutes_two_channels: insert_main_stream_attrbutes_two_channels port map (
i_insert_main_stream_attrbutes_four_channels: insert_main_stream_attrbutes_four_channels port map (
            clk                  => symbolclk,
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
            in_data              => test_signal_data,
            -----------------------------------------------------
            -- The stream of pixel data going out
            -----------------------------------------------------
            out_data             => msa_merged_data
        );


i_idle_pattern_inserter: idle_pattern_inserter  port map ( 
            clk              => symbolclk,
            channel_ready    => '1',
            source_ready     => test_signal_ready,
            
            in_data          => msa_merged_data,
            out_data         => signal_data
        );

i_scrambler_reset_inserter: scrambler_reset_inserter
        port map ( 
            clk       => symbolclk,
            in_data   => signal_data,
            out_data  => sr_inserted_data
        );

g_per_channel: for i in 0 to 3 generate

i_scrambler:  scrambler
        port map ( 
            clk        => symbolclk,
            bypass0    => '1',
            bypass1    => '1',
            in_data    => sr_inserted_data(17+i*18 downto 0+i*18),
            out_data   => scrambled_data(17+i*18 downto 0+i*18)
        );

i_train_channel: training_and_channel_delay port map (
        clk               => symbolclk,

        channel_delay     => delay_index(1+i*2 downto 0+i*2),
        clock_train       => tx_clock_train,
        align_train       => tx_align_train, 
        
        in_data           => scrambled_data(17+i*18 downto 0+i*18),
        out_data          => final_data(17+i*18 downto 0+i*18),
        out_data0forceneg => force_parity_neg(0+i*2),
        out_data1forceneg => force_parity_neg(1+i*2)
    );

i_data_to_8b10b: data_to_8b10b port map ( 
        clk      => symbolclk,
        in_data  => final_data(17+i*18 downto 0+i*18),
        out_data => symbols(19+i*20 downto 0+i*20),
        forceneg => force_parity_neg(1+i*2 downto 0+i*2)
        );
    end generate;


end Behavioral;
