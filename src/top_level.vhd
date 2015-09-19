----------------------------------------------------------------------------------
-- Module Name: top_level - Behavioral
--
-- Description: Top level of my DisplayPort design.
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

entity top_level is
    port ( 
        clk             : in    std_logic;
        debug_pmod      : out   std_logic_vector(7 downto 0) := (others => '0');
        switches        : in    std_logic_vector(7 downto 0) := (others => '0');
        leds            : out   std_logic_vector(7 downto 0) := (others => '0');
        ------------------------------
        refclk0_p       : in  STD_LOGIC;
        refclk0_n       : in  STD_LOGIC;
        refclk1_p       : in  STD_LOGIC;
        refclk1_n       : in  STD_LOGIC;
        gtptxp          : out std_logic_vector(1 downto 0);
        gtptxn          : out std_logic_vector(1 downto 0);    
        ------------------------------
        dp_tx_hp_detect : in    std_logic;
        dp_tx_aux_p     : inout std_logic;
        dp_tx_aux_n     : inout std_logic;
        dp_rx_aux_p     : inout std_logic;
        dp_rx_aux_n     : inout std_logic
    );
end top_level;

architecture Behavioral of top_level is
    component hotplug_decode is
        port (clk     : in  std_logic;
              hpd     : in  std_logic;
              irq     : out std_logic := '0';
              present : out std_logic := '0');
    end component;

    component test_source is
        port ( 
            clk          : in  std_logic;
            ready        : out std_logic;
            data         : out std_logic_vector(72 downto 0)
        );
    end component;
    
    component test_source_800_600_RGB_444_ch1 is
        port ( 
            clk    : in  std_logic;
            ready  : out std_logic;
            data   : out std_logic_vector(72 downto 0) := (others => '0')
        );
    end component;

    component test_source_3840_2160_YCC_422_ch2 is
        port ( 
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

    component link_signal_mgmt is
        Port ( mgmt_clk    : in  STD_LOGIC;

               tx_powerup  : in  STD_LOGIC;  -- Used to reset
            
               status_de   : in  std_logic;
               adjust_de   : in  std_logic;
               addr        : in  std_logic_vector(7 downto 0);
	  	       data        : in  std_logic_vector(7 downto 0);

               sink_channel_count   : in  std_logic_vector(2 downto 0);
               source_channel_count : in  std_logic_vector(2 downto 0);
               active_channel_count : out std_logic_vector(2 downto 0);

               powerup_channel : out std_logic_vector(3 downto 0);

               clock_locked   : out STD_LOGIC;
               equ_locked     : out STD_LOGIC;
               symbol_locked  : out STD_LOGIC;
               align_locked   : out STD_LOGIC;
        
               preemp_0p0  : out STD_LOGIC;
               preemp_3p5  : out STD_LOGIC;
               preemp_6p0  : out STD_LOGIC;
        
               swing_0p4   : out STD_LOGIC;
               swing_0p6   : out STD_LOGIC;
               swing_0p8   : out STD_LOGIC);
    end component;
    
    component Transceiver is
    Port ( mgmt_clk        : in  STD_LOGIC;
           powerup_channel : in  STD_LOGIC_vector;

           preemp_0p0      : in  STD_LOGIC;
           preemp_3p5      : in  STD_LOGIC;
           preemp_6p0      : in  STD_LOGIC;
           
           swing_0p4       : in  STD_LOGIC;
           swing_0p6       : in  STD_LOGIC;
           swing_0p8       : in  STD_LOGIC;

           tx_running      : out STD_LOGIC_vector;


           refclk0_p       : in  STD_LOGIC;
           refclk0_n       : in  STD_LOGIC;

           refclk1_p       : in  STD_LOGIC;
           refclk1_n       : in  STD_LOGIC;

           symbolclk      : out STD_LOGIC;
           
           in_symbols     : in  std_logic_vector(79 downto 0);

           gtptxp         : out std_logic_vector;
           gtptxn         : out std_logic_vector);
    end component;

    component aux_channel is
		port ( 
		   clk                 : in    std_logic;
		   debug_pmod          : out   std_logic_vector(7 downto 0);
		   ------------------------------
           edid_de             : out   std_logic;
           dp_reg_de           : out   std_logic;
           adjust_de           : out   std_logic;
           status_de           : out   std_logic;
           aux_addr            : out   std_logic_vector(7 downto 0);
		   aux_data            : out   std_logic_vector(7 downto 0);
		   ------------------------------
           link_count          : in    std_logic_vector(2 downto 0);           
		   ------------------------------
		   -- Hot plug signals
           hpd_irq             : in std_logic;
           hpd_present         : in std_logic;

		   ------------------------------
		   swing_0p4           : in    std_logic;
           swing_0p6           : in    std_logic;
           swing_0p8           : in    std_logic;
           preemp_0p0          : in    STD_LOGIC;
           preemp_3p5          : in    STD_LOGIC;
           preemp_6p0          : in    STD_LOGIC;
           clock_locked        : in    STD_LOGIC;
           equ_locked          : in    STD_LOGIC;
           symbol_locked       : in    STD_LOGIC;
           align_locked        : in    STD_LOGIC;
		   ------------------------------
           tx_powerup          : out   std_logic := '0';
           tx_clock_train      : out   std_logic := '0';
           tx_align_train      : out   std_logic := '0';
           tx_link_established : out   std_logic := '0';
		   ------------------------------
		   dp_tx_hp_detect : in    std_logic;
           dp_tx_aux_p     : inout std_logic;
           dp_tx_aux_n     : inout std_logic;
           dp_rx_aux_p     : inout std_logic;
           dp_rx_aux_n     : inout std_logic
		);
    end component;

    component edid_decode is
       port ( clk              : in std_logic;
    
              edid_de          : in std_logic;
              edid_data        : in std_logic_vector(7 downto 0);
              edid_addr        : in std_logic_vector(7 downto 0);
              invalidate       : in std_logic;
    
              valid            : out std_logic := '0';
    
              support_RGB444   : out std_logic := '0';
              support_YCC444   : out std_logic := '0';
              support_YCC422   : out std_logic := '0';
    
              pixel_clock_x10k : out std_logic_vector(15 downto 0) := (others => '0');
    
              h_visible_len    : out std_logic_vector(11 downto 0) := (others => '0');
              h_blank_len      : out std_logic_vector(11 downto 0) := (others => '0');
              h_front_len      : out std_logic_vector(11 downto 0) := (others => '0');
              h_sync_len       : out std_logic_vector(11 downto 0) := (others => '0');
    
              v_visible_len    : out std_logic_vector(11 downto 0) := (others => '0');
              v_blank_len      : out std_logic_vector(11 downto 0) := (others => '0');
              v_front_len      : out std_logic_vector(11 downto 0) := (others => '0');
              v_sync_len       : out std_logic_vector(11 downto 0) := (others => '0');
              interlaced       : out std_logic := '0');
    end component;

    component dp_register_decode is
       port ( clk         : in std_logic;
    
              de          : in std_logic;
              data        : in std_logic_vector(7 downto 0);
              addr        : in std_logic_vector(7 downto 0);
              invalidate  : in std_logic;
    
              valid              : out std_logic := '0';
     
              revision           : out std_logic_vector(7 downto 0) := (others => '0');
              link_rate_2_70     : out std_logic := '0';
              link_rate_1_62     : out std_logic := '0';
              extended_framing   : out std_logic := '0';
              link_count         : out std_logic_vector(3 downto 0) := (others => '0');
              max_downspread     : out std_logic_vector(7 downto 0) := (others => '0');
              coding_supported   : out std_logic_vector(7 downto 0) := (others => '0');
              port0_capabilities : out std_logic_vector(15 downto 0) := (others => '0');
              port1_capabilities : out std_logic_vector(15 downto 0) := (others => '0');
              norp               : out std_logic_vector(7 downto 0) := (others => '0')
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

    component video_generator is
    Port (  clk              : in  STD_LOGIC;
            h_visible_len    : in  std_logic_vector(11 downto 0) := (others => '0');
            h_blank_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            h_front_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            h_sync_len       : in  std_logic_vector(11 downto 0) := (others => '0');
            
            v_visible_len    : in  std_logic_vector(11 downto 0) := (others => '0');
            v_blank_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            v_front_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            v_sync_len       : in  std_logic_vector(11 downto 0) := (others => '0');
            
            vid_blank        : out STD_LOGIC;
            vid_hsync        : out STD_LOGIC;
            vid_vsync        : out STD_LOGIC);
    end component;

    signal edid_de          : std_logic;
    signal dp_reg_de        : std_logic;
    signal adjust_de        : std_logic;
    signal status_de        : std_logic;
    signal aux_data         : std_logic_vector(7 downto 0);
    signal aux_addr         : std_logic_vector(7 downto 0);
    signal invalidate       : std_logic;
    
    
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

    ---------------------------------------------
    -- Transceiver signals
    ---------------------------------------------
    signal txresetdone      : std_logic := '0';
    signal txoutclk         : std_logic := '0';
    signal symbolclk        : std_logic := '0';
    
    signal tx_running       : std_logic_vector(3 downto 0) := (others => '0');

    signal powerup_channel : std_logic_vector(3 downto 0);
    signal clock_locked    : std_logic := '0';
    signal equ_locked      : std_logic := '0';
    signal symbol_locked   : std_logic := '0';
    signal align_locked    : std_logic := '0';
    
    signal preemp_0p0      : std_logic := '1';
    signal preemp_3p5      : STD_LOGIC := '0';
    signal preemp_6p0      : STD_LOGIC := '0';
           
    signal swing_0p4       : STD_LOGIC := '1';
    signal swing_0p6       : STD_LOGIC := '0';
    signal swing_0p8       : STD_LOGIC := '0';

    ------------------------------------------------
    signal tx_link_established : std_logic := '0';
    ------------------------------------------------
    signal interface_debug : std_logic_vector(7 downto 0);

    signal sink_channel_count   : std_logic_vector(2 downto 0) := "100";
    signal source_channel_count : std_logic_vector(2 downto 0) := "001";
    signal active_channel_count : std_logic_vector(2 downto 0) := "000";

    signal debug       : std_logic_vector(7 downto 0);
    signal test_signal : std_logic_vector(8 downto 0);

    signal scramble_bypass        : std_logic;
    signal test_signal_ready      : std_logic;
    
    signal test_signal_data    : std_logic_vector(72 downto 0);  -- With switching point
    signal msa_merged_data     : std_logic_vector(72 downto 0);  -- With switching point
    signal signal_data         : std_logic_vector(71 downto 0);
    signal sr_inserted_data    : std_logic_vector(71 downto 0);    
    signal scrambled_data      : std_logic_vector(71 downto 0);
    signal final_data          : std_logic_vector(71 downto 0);
    signal force_parity_neg    : std_logic_vector( 7 downto 0);
    signal symbols             : std_logic_vector(79 downto 0);
    
    signal hpd_irq     : std_logic;
    signal hpd_present : std_logic;

    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR     : std_logic_vector(8 downto 0) := "100011100";   -- K28.0

    constant delay_index : std_logic_vector(7 downto 0) := "11100100"; -- 3,2,1,0 for in the gneerate loop
begin

process(clk)
    begin
        if rising_edge(clk) then
            if status_de = '1' and aux_addr = x"02" then
               debug <= aux_data;
            end if;
            case switches(4 downto 0) is
                when "00000" => leds <= h_visible_len(7 downto 0);
                when "00001" => leds <= "0000" & h_visible_len(11 downto 8);
                when "00010" => leds <= h_blank_len(7 downto 0);
                when "00011" => leds <= "0000" & h_blank_len(11 downto 8);
                when "00100" => leds <= h_front_len(7 downto 0);
                when "00101" => leds <= "0000" & h_front_len(11 downto 8);
                when "00110" => leds <= h_sync_len(7 downto 0);
                when "00111" => leds <= "0000" & h_sync_len(11 downto 8);
                when "01000" => leds <= V_visible_len(7 downto 0);
                when "01001" => leds <= "0000" & v_visible_len(11 downto 8);
                when "01010" => leds <= V_blank_len(7 downto 0);
                when "01011" => leds <= "0000" & v_blank_len(11 downto 8);
                when "01100" => leds <= V_front_len(7 downto 0);
                when "01101" => leds <= "0000" & v_front_len(11 downto 8);
                when "01110" => leds <= V_sync_len(7 downto 0);
                when "01111" => leds <= "0000" & v_sync_len(11 downto 8);
                when others  => leds <= debug;
            end case;
        end if;
    end process;

i_hotplug_decode: hotplug_decode port map (
        clk => clk,
        hpd     => dp_tx_hp_detect,
        irq     => hpd_irq,
        present => hpd_present);

i_aux_channel: aux_channel port map ( 
		   clk             => clk,
		   debug_pmod      => interface_debug,
		   ------------------------------
           edid_de         => edid_de,
           dp_reg_de       => dp_reg_de,
           adjust_de       => adjust_de,
           status_de       => status_de,
           aux_addr        => aux_addr,
		   aux_data        => aux_data,
		   ------------------------------
		   link_count      => active_channel_count,
           hpd_irq         => hpd_irq,
           hpd_present     => hpd_present,
		   ------------------------------
           preemp_0p0      => preemp_0p0, 
           preemp_3p5      => preemp_3p5,
           preemp_6p0      => preemp_6p0,           
           swing_0p4       => swing_0p4,
           swing_0p6       => swing_0p6,
           swing_0p8       => swing_0p8,
           
           clock_locked    => clock_locked,
           equ_locked      => equ_locked,
           symbol_locked   => symbol_locked,
           align_locked    => align_locked,
           
		   ------------------------------
           tx_powerup          => tx_powerup,
           tx_clock_train      => tx_clock_train,
           tx_align_train      => tx_align_train,
           tx_link_established => tx_link_established,
		   ------------------------------
		   dp_tx_hp_detect => dp_tx_hp_detect,
           dp_tx_aux_p     => dp_tx_aux_p,
           dp_tx_aux_n     => dp_tx_aux_n,
           dp_rx_aux_p     => dp_rx_aux_p,
           dp_rx_aux_n     => dp_rx_aux_n
		);


i_edid_decode: edid_decode port map ( 
           clk              => clk,    
           edid_de          => edid_de,
           edid_addr        => aux_addr,
           edid_data        => aux_data,
           invalidate       => '0',
    
           valid            => edid_valid,
    
           support_RGB444   => support_RGB444,
           support_YCC444   => support_YCC444,
           support_YCC422   => support_YCC422,
    
           pixel_clock_x10k => pixel_clock_x10k,
    
           h_visible_len    => h_visible_len,
           h_blank_len      => h_blank_len,
           h_front_len      => h_front_len,
           h_sync_len       => h_sync_len,
    
           v_visible_len    => v_visible_len,
           v_blank_len      => v_blank_len,
           v_front_len      => v_front_len,
           v_sync_len       => v_sync_len,
           interlaced       => interlaced);

i_dp_reg_decode: dp_register_decode port map ( 
            clk                => clk,
            de                 => dp_reg_de,
            addr               => aux_addr,
            data               => aux_data,
            invalidate         => '0',
            valid              => dp_valid,
            
            revision           => dp_revision,
            link_rate_2_70     => dp_link_rate_2_70,
            link_rate_1_62     => dp_link_rate_1_62,
            extended_framing   => dp_extended_framing,
            link_count         => dp_link_count,
            max_downspread     => dp_max_downspread,
            coding_supported   => dp_coding_supported,
            port0_capabilities => dp_port0_capabilities,
            port1_capabilities => dp_port1_capabilities,
            norp               => dp_norp
       );

i_link_signal_mgmt:  link_signal_mgmt Port map (
        mgmt_clk        => clk,

        tx_powerup      => tx_powerup, 
        
        status_de       => status_de,
        adjust_de       => adjust_de,
        addr            => aux_addr,
        data            => aux_data,

        sink_channel_count   => sink_channel_count,
        source_channel_count => source_channel_count,
        active_channel_count => active_channel_count,

        powerup_channel => powerup_channel,

        clock_locked    => clock_locked,
        equ_locked      => equ_locked,
        symbol_locked   => symbol_locked,
        align_locked    => align_locked,

        preemp_0p0      => preemp_0p0, 
        preemp_3p5      => preemp_3p5,
        preemp_6p0      => preemp_6p0,
            
        swing_0p4       => swing_0p4,
        swing_0p6       => swing_0p6,
        swing_0p8       => swing_0p8);

    debug_pmod(0) <= interface_debug(0);
    debug_pmod(1) <= tx_clock_train;
    debug_pmod(2) <= tx_align_train;
    debug_pmod(3) <= tx_powerup;
    debug_pmod(4) <= clock_locked;
    debug_pmod(5) <= equ_locked;
 --   debug_pmod(6) <= symbol_locked;
    debug_pmod(7) <= tx_link_established;

--i_test_source: test_source_800_600_RGB_444_ch1  port map ( 
i_test_source: test_source_3840_2160_YCC_422_ch2  port map ( 
            clk          => symbolclk,
            ready        => test_signal_ready,
            data         => test_signal_data
        );

--i_insert_main_stream_attrbutes_one_channel: insert_main_stream_attrbutes_one_channel port map (
i_insert_main_stream_attrbutes_two_channels: insert_main_stream_attrbutes_two_channels port map (
            clk                  => symbolclk,
            active               => '1',
            -----------------------------------------------------
            -- The MSA values (some are range reduced and could 
            -- be 16 bits ins size)
            -----------------------------------------------------      
            M_value              => x"07DA13", -- For 265MHz/270Mhz
            N_value              => x"080000",
     
            V_visible            => x"870",  -- 2160
            V_total              => x"88F", -- 2191
            V_sync_width         => x"003",  -- 3
            V_start              => x"01A",  -- 26
            
            H_visible            => x"F00",  -- 3840
            H_total              => x"FC0",  -- 1056
            H_sync_width         => x"030",  -- 128
            H_start              => x"0A0",  -- 26 
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
            channel_ready    => tx_link_established,
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

g_per_channel: for i in 0 to gtptxp'high generate

i_scrambler:  scrambler
        port map ( 
            clk        => symbolclk,
            bypass0    => '0',
            bypass1    => '0',
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

i_tx0: Transceiver Port map ( 
       mgmt_clk        => clk,
       powerup_channel => powerup_channel,
       tx_running      => tx_running,

       preemp_0p0      => preemp_0p0, 
       preemp_3p5      => preemp_3p5,
       preemp_6p0      => preemp_6p0,
           
       swing_0p4       => swing_0p4,
       swing_0p6       => swing_0p6,
       swing_0p8       => swing_0p8,

       refclk0_p       => refclk0_p,
       refclk0_n       => refclk0_n,

       refclk1_p       => refclk1_p,
       refclk1_n       => refclk1_n,
       in_symbols      => symbols,
                  
       gtptxp          => gtptxp,
       gtptxn          => gtptxn,
       symbolclk       => symbolclk);       
end Behavioral;
