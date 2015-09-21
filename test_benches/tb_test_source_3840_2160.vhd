----------------------------------------------------------------------------------
-- Module Name: tb_test_source_3840_2160 - Behavioral
--
-- Description: A testbench for tb_test_source
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
use IEEE.NUMERIC_STD.ALL;

entity tb_test_source_3840_2160 is
end entity;

architecture arch of tb_test_source_3840_2160 is
    component test_source_3840_2160_YCC_422_ch2 is
        port ( 
            clk    : in  std_logic;
            ready  : out std_logic;
            data   : out std_logic_vector(72 downto 0) := (others => '0')
        );
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
            in_data              : in std_logic_vector(72 downto 0);
            out_data             : out std_logic_vector(72 downto 0) := (others => '0'));
    end component;

    component idle_pattern_inserter is
        port ( 
            clk              : in  std_logic;
            channel_ready    : in  std_logic;
            source_ready     : in  std_logic;
            in_data          : in std_logic_vector(72 downto 0);
            out_data         : out std_logic_vector(71 downto 0) := (others => '0')
        );
    end component;    
	
    component scrambler_reset_inserter is
        port ( 
            clk        : in  std_logic;
            in_data    : in  std_logic_vector(71 downto 0);
            out_data   : out std_logic_vector(71 downto 0)
        );
    end component;
    
    component scrambler is
        port ( 
            clk       : in  std_logic;
            bypass0   : in  std_logic;
            bypass1   : in  std_logic;
            in_data   : in  std_logic_vector(17 downto 0);
            out_data  : out std_logic_vector(17 downto 0)
        );
    end component;

    component training_and_channel_delay is
    port (
        clk                : in  std_logic;
        channel_delay      : in  std_logic_vector(1 downto 0);
        clock_train        : in  std_logic;
        align_train        : in  std_logic;

        in_data           : in  std_logic_vector(17 downto 0);
        out_data          : out std_logic_vector(17 downto 0);
        out_data0forceneg  : out std_logic;
        out_data1forceneg  : out std_logic

    );
    end component;

    component data_to_8b10b is
        port ( 
            clk           : in  std_logic;
            forceneg      : in  std_logic_vector(1 downto 0);
            in_data       : in  std_logic_vector(17 downto 0);
            out_data      : out std_logic_vector(19 downto 0) := (others => '0')
        );
    end component;
 	
	signal clk                       : std_logic;

	signal test_signal_data          : std_logic_vector(72 downto 0);
    signal test_signal_ready         : std_logic;

    signal msa_merged_data           : std_logic_vector(72 downto 0);

    signal signal_data              : std_logic_vector(71 downto 0);

	signal sr_inserted_data   : std_logic_vector(71 downto 0);
	
    signal scramble_bypass  : std_logic := '1';
	signal scrambled_data   : std_logic_vector(17 downto 0);
    
    signal ch0_data         : std_logic_vector(17 downto 0);
    signal ch0_forceneg     : std_logic_vector(1 downto 0);
    signal ch0_symbols      : std_logic_vector(19 downto 0);
    signal dec0            : std_logic_vector(8 downto 0);
    
    signal rd : unsigned(9 downto 0) := (others => '0');

    signal c0s0 : std_logic_vector(8 downto 0);
    signal c0s1 : std_logic_vector(8 downto 0);
    signal c1s0 : std_logic_vector(8 downto 0);
    signal c1s1 : std_logic_vector(8 downto 0);
    signal ccount : unsigned(15 downto 0) := (others => '0'); 
begin
i_test_source: test_source_3840_2160_YCC_422_ch2 port map ( 
            clk   => clk,
            ready => test_signal_ready,
            data  => test_signal_data
        );

i_insert_main_stream_attrbutes_two_channels: insert_main_stream_attrbutes_two_channels port map (
            clk                  => clk,
            active               => '1',
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              => x"07DA13", -- For 265MHz/270Mhz
            N_value              => x"080000",

            H_visible            => x"F00",  -- 3840
            H_total              => x"FC0",  -- 4032
            H_sync_width         => x"030",  -- 128
            H_start              => x"0A0",  -- 160 
     
            V_visible            => x"870",  -- 2160
            V_total              => x"88F", -- 2191
            V_sync_width         => x"003",  -- 3
            V_start              => x"01A",  -- 26
            
            H_vsync_active_high  => '1',
            V_vsync_active_high  => '1',
            flag_sync_clock      => '1',
            flag_YCCnRGB         => '1',
            flag_422n444         => '1',
            flag_range_reduced   => '1',
            flag_interlaced_even => '0',
            flag_YCC_colour_709  => '0',
            flags_3d_Indicators  => (others => '0'),
            bits_per_colour      => "01000",


--            M_value              => x"012F68",
--            N_value              => x"080000",
--            H_visible            => x"320",  -- 800
--            V_visible            => x"258",  -- 600
--            H_total              => x"420",  -- 1056
--            V_total              => x"274",  -- 628
--            H_sync_width         => x"080",  -- 128
--            V_sync_width         => x"004",   -- 4
--            H_start              => x"0D8",  -- 216 
--            V_start              => x"01b",  -- 37
--            H_vsync_active_high  => '0',
--            V_vsync_active_high  => '0',
--            flag_sync_clock      => '1',
--            flag_YCCnRGB         => '0',
--            flag_422n444         => '0',
--            flag_range_reduced   => '0',
--            flag_interlaced_even => '0',
--            flag_YCC_colour_709  => '0',
--            flags_3d_Indicators  => (others => '0'),
--            bits_per_colour      => "01000",
            -----------------------------------------------------
            -- The stream of pixel data coming in
            -----------------------------------------------------
            in_data              => test_signal_data,
            -----------------------------------------------------
            -- The stream of pixel data going out
            -----------------------------------------------------
            out_data              => msa_merged_data);

i_idle_pattern_inserter: idle_pattern_inserter  port map ( 
            clk             => clk,
            channel_ready   => '1',
            source_ready    => test_signal_ready,
            
            in_data         => msa_merged_data,
            out_data        => signal_data
        );
    
i_scrambler_reset_inserter : scrambler_reset_inserter
        port map ( 
            clk       => clk,
            in_data   => signal_data,
            out_data  => sr_inserted_data
        );

        -- Bypass the scrambler for the test pattens.
        c0s0 <=  sr_inserted_data( 8 downto  0);
        c0s1 <=  sr_inserted_data(17 downto  9);
        c1s0 <=  sr_inserted_data(26 downto 18);
        c1s1 <=  sr_inserted_data(35 downto 27);
        
        scramble_bypass <= '1'; -- tx_clock_train or tx_align_train;  
i_scrambler : scrambler
        port map ( 
            clk       => clk,
            bypass0   => scramble_bypass,
            bypass1   => scramble_bypass,
            in_data   => sr_inserted_data(17 downto 0),
            out_data  => scrambled_data(17 downto 0)
        );


i_train_channel0: training_and_channel_delay port map (
        clk             => clk,

        channel_delay   => "00",
        clock_train     => '0',
        align_train     => '0', 
        
        in_data           => scrambled_data(17 downto 0),

        out_data          => ch0_data,
        out_data0forceneg => ch0_forceneg(0),
        out_data1forceneg => ch0_forceneg(1)
    );

i_data_to_8b10b: data_to_8b10b port map ( 
        clk           => clk,
        in_data       => ch0_data,
        forceneg      => ch0_forceneg,
        out_data      => ch0_symbols
        );

process(clK)
    begin
        if rising_edge(clk) then
            rd <= rd  - to_unsigned(10,10)
                + unsigned(ch0_symbols(0 downto 0))
                + unsigned(ch0_symbols(1 downto 1))
                + unsigned(ch0_symbols(2 downto 2))
                + unsigned(ch0_symbols(3 downto 3))
                + unsigned(ch0_symbols(4 downto 4))
                + unsigned(ch0_symbols(5 downto 5))
                + unsigned(ch0_symbols(6 downto 6))
                + unsigned(ch0_symbols(7 downto 7))
                + unsigned(ch0_symbols(8 downto 8))
                + unsigned(ch0_symbols(9 downto 9))
                + unsigned(ch0_symbols(10 downto 10))
                + unsigned(ch0_symbols(11 downto 11))
                + unsigned(ch0_symbols(12 downto 12))
                + unsigned(ch0_symbols(13 downto 13))
                + unsigned(ch0_symbols(14 downto 14))
                + unsigned(ch0_symbols(15 downto 15))
                + unsigned(ch0_symbols(16 downto 16))
                + unsigned(ch0_symbols(17 downto 17))
                + unsigned(ch0_symbols(18 downto 18))
                + unsigned(ch0_symbols(19 downto 19));                
        end if;
    end process;
    
--data_dec0: dec_8b10b port map (
--		RESET => '0',
--		RBYTECLK => clk,
--		AI => ch0_symbols(0), 
--		BI => ch0_symbols(1), 
--		CI => ch0_symbols(2), 
--		DI => ch0_symbols(3), 
--		EI => ch0_symbols(4), 
--		II => ch0_symbols(5),
--		FI => ch0_symbols(6),
--		GI => ch0_symbols(7), 
--		HI => ch0_symbols(8), 
--		JI => ch0_symbols(9),
--			
--		KO => dec0(8), 
--		HO => dec0(7),
--		GO => dec0(6), 
--		FO => dec0(5), 
--		EO => dec0(4), 
--		DO => dec0(3), 
--		CO => dec0(2), 
--		BO => dec0(1), 
--		AO => dec0(0) 
--	    );

process(clK)
    begin
        if rising_edge(clK) then
            
            if c0s0 = "111111011" then
               if c0s1(8) = '1' then
                ccount <= (others => '0');
               else
                ccount <= (0=>'1',others => '0');
               end if;
            elsif c0s1 = "111111011" then
                ccount <= (others => '0');
            elsif c0s0(8) = '0' and c0s1(8) = '0' then
                ccount <= ccount + 2;
            elsif c0s0(8) = '0' or c0s1(8) = '0' then
                ccount <= ccount +1;
            end if;
                           
        end if;
    end process;
process 
    begin
        clk <= '1';
        wait for 3.703 ns;
        clk <= '0';
        wait for 3.703 ns;
    end process;
end architecture;
