----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.08.2015 22:35:35
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
        gtptxp          : out std_logic;
        gtptxn          : out std_logic;    
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
            data0        : out std_logic_vector(7 downto 0);
            data0k       : out std_logic;
            data1        : out std_logic_vector(7 downto 0);
            data1k       : out std_logic;
            switch_point : out std_logic
        );
    end component;

    component idle_pattern_inserter is
        port ( 
            clk              : in  std_logic;
            channel_ready    : in  std_logic;
            source_ready     : in  std_logic;
            in_data0         : in  std_logic_vector(7 downto 0);
            in_data0k        : in  std_logic;
            in_data1         : in  std_logic_vector(7 downto 0);
            in_data1k        : in  std_logic;
            in_switch_point  : in  std_logic;

            out_data0        : out std_logic_vector(7 downto 0);
            out_data0k       : out std_logic;
            out_data1        : out std_logic_vector(7 downto 0);
            out_data1k       : out std_logic
        );
    end component;    
    
    component scrambler_reset_inserter is
        port ( 
            clk        : in  std_logic;
            in_data0   : in  std_logic_vector(7 downto 0);
            in_data0k  : in  std_logic;
            in_data1   : in  std_logic_vector(7 downto 0);
            in_data1k  : in  std_logic;
            out_data0  : out std_logic_vector(7 downto 0);
            out_data0k : out std_logic;
            out_data1  : out std_logic_vector(7 downto 0);
            out_data1k : out std_logic
        );
    end component;
    
    component scrambler is
        port ( 
            clk        : in  std_logic;
            bypass0    : in  std_logic;
            bypass1    : in  std_logic;
            in_data0   : in  std_logic_vector(7 downto 0);
            in_data0k  : in  std_logic;
            in_data1   : in  std_logic_vector(7 downto 0);
            in_data1k  : in  std_logic;
            out_data0  : out std_logic_vector(7 downto 0);
            out_data0k : out std_logic;
            out_data1  : out std_logic_vector(7 downto 0);
            out_data1k : out std_logic
        );
    end component;
    
    component data_to_8b10b is
        port ( 
            clk           : in  std_logic;
            data0         : in  std_logic_vector(7 downto 0);
            data0k        : in  std_logic;
            data0forceneg : in  std_logic;
            data1         : in  std_logic_vector(7 downto 0);
            data1k        : in  std_logic;
            data1forceneg : in  std_logic;
            symbol0       : out std_logic_vector(9 downto 0);
            symbol1       : out std_logic_vector(9 downto 0)
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
           powerup_channel : in  STD_LOGIC;

           preemp_0p0      : in  STD_LOGIC;
           preemp_3p5      : in  STD_LOGIC;
           preemp_6p0      : in  STD_LOGIC;
           
           swing_0p4       : in  STD_LOGIC;
           swing_0p6       : in  STD_LOGIC;
           swing_0p8       : in  STD_LOGIC;

           tx_running      : out STD_LOGIC;


           refclk0_p       : in  STD_LOGIC;
           refclk0_n       : in  STD_LOGIC;

           refclk1_p       : in  STD_LOGIC;
           refclk1_n       : in  STD_LOGIC;

--           TXOUTCLK       : out STD_LOGIC;
--           TXOUTCLKFABRIC : out STD_LOGIC;
--           TXOUTCLKPCS    : out STD_LOGIC;
           symbolclk    : out STD_LOGIC;
           
           txsymbol0      : in  std_logic_vector(9 downto 0);
           txsymbol1      : in  std_logic_vector(9 downto 0);

           gtptxp         : out std_logic;
           gtptxn         : out std_logic);
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

        in_data0           : in  std_logic_vector(7 downto 0);
        in_data0k          : in  std_logic;
        in_data1           : in  std_logic_vector(7 downto 0);
        in_data1k          : in  std_logic;

        out_data0          : out std_logic_vector(7 downto 0);
        out_data0k         : out std_logic;
        out_data0forceneg  : out std_logic;
        out_data1          : out std_logic_vector(7 downto 0);
        out_data1k         : out std_logic;
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
    
    signal tx_running       : std_logic := '0';

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
    
    signal test_signal_data0         : std_logic_vector(7 downto 0);
    signal test_signal_data0k        : std_logic;
    signal test_signal_data1         : std_logic_vector(7 downto 0);
    signal test_signal_data1k        : std_logic;
    signal test_signal_switch_point  : std_logic;
    signal test_signal_ready         : std_logic;

    signal signal_data0              : std_logic_vector(7 downto 0);
    signal signal_data0k             : std_logic;
    signal signal_data1              : std_logic_vector(7 downto 0);
    signal signal_data1k             : std_logic;

    signal sr_inserted_data0      : std_logic_vector(7 downto 0);
    signal sr_inserted_data0k     : std_logic;
    signal sr_inserted_data1      : std_logic_vector(7 downto 0);
    signal sr_inserted_data1k     : std_logic;
    
    signal scrambled_data0      : std_logic_vector(7 downto 0);
    signal scrambled_data0k     : std_logic;
    signal scrambled_data1      : std_logic_vector(7 downto 0);
    signal scrambled_data1k     : std_logic;
    signal scrambled_symbol0     : std_logic_vector(9 downto 0);
    signal scrambled_symbol1     : std_logic_vector(9 downto 0);
    --
    signal ch0_data0              : std_logic_vector(7 downto 0);
    signal ch0_data0k             : std_logic;
    signal ch0_data0forceneg      : std_logic;
    signal ch0_symbol0            : std_logic_vector(9 downto 0);
    --
    signal ch0_data1              : std_logic_vector(7 downto 0);
    signal ch0_data1k             : std_logic;
    signal ch0_data1forceneg      : std_logic;
    signal ch0_symbol1            : std_logic_vector(9 downto 0);
    signal hpd_irq     : std_logic;
    signal hpd_present : std_logic;

    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5

begin
process(symbolclk)
    begin
        if rising_edge(symbolclk) then
            if (ch0_data0k & ch0_data0) = BS or (ch0_data1k & ch0_data1) = BS then
                debug_pmod(6) <= '1';
            end if;
            
            if (ch0_data0k & ch0_data0) = BE or (ch0_data1k & ch0_data1) = BE then
                debug_pmod(6) <= '0';
            end if;
        end if;
    end process;

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

i_test_source: test_source port map ( 
            clk          => symbolclk,
            ready        => test_signal_ready,
            data0        => test_signal_data0,
            data0k       => test_signal_data0k,
            data1        => test_signal_data1,
            data1k       => test_signal_data1k,
            switch_point => test_signal_switch_point
        );

i_idle_pattern_inserter: idle_pattern_inserter  port map ( 
            clk              => symbolclk,
            channel_ready    => tx_link_established,
            source_ready     => test_signal_ready,
            
            in_data0        => test_signal_data0,
            in_data0k       => test_signal_data0k,
            in_data1        => test_signal_data1,
            in_data1k       => test_signal_data1k,
            in_switch_point => test_signal_switch_point,

            out_data0        => signal_data0,
            out_data0k       => signal_data0k,
            out_data1        => signal_data1,
            out_data1k       => signal_data1k
        );

i_scrambler_reset_inserter : scrambler_reset_inserter
        port map ( 
            clk        => symbolclk,
            in_data0   => signal_data0,
            in_data0k  => signal_data0k,
            in_data1   => signal_data1,
            in_data1k  => signal_data1k,
            out_data0  => sr_inserted_data0,
            out_data0k => sr_inserted_data0k,
            out_data1  => sr_inserted_data1,
            out_data1k => sr_inserted_data1k
        );

        -- Bypass the scrambler for the test pattens.
        
        scramble_bypass <= '1'; -- tx_clock_train or tx_align_train;  
i_scrambler : scrambler
        port map ( 
            clk        => symbolclk,
            bypass0    => scramble_bypass,
            bypass1    => scramble_bypass,
            in_data0   => sr_inserted_data0,
            in_data0k  => sr_inserted_data0k,
            in_data1   => sr_inserted_data1,
            in_data1k  => sr_inserted_data1k,
            out_data0  => scrambled_data0,
            out_data0k => scrambled_data0k,
            out_data1  => scrambled_data1,
            out_data1k => scrambled_data1k
        );

i_train_channel0: training_and_channel_delay port map (
        clk             => symbolclk,

        channel_delay   => "00",
        clock_train     => tx_clock_train,
        align_train     => tx_align_train, 
        
        in_data0          => scrambled_data0,
        in_data0k         => scrambled_data0k,
        in_data1          => scrambled_data1,
        in_data1k         => scrambled_data1k,

        out_data0         => ch0_data0,
        out_data0k        => ch0_data0k,
        out_data0forceneg => ch0_data0forceneg,
        out_data1         => ch0_data1,
        out_data1k        => ch0_data1k,
        out_data1forceneg => ch0_data1forceneg
    );

i_data_to_8b10b: data_to_8b10b port map ( 
        clk           => symbolclk,
        data0         => ch0_data0,
        data0k        => ch0_data0k,
        data0forceneg => ch0_data0forceneg,
        data1         => ch0_data1,
        data1k        => ch0_data1k,
        data1forceneg => ch0_data1forceneg,
        symbol0       => ch0_symbol0,
        symbol1       => ch0_symbol1
        );

i_tx0: Transceiver Port map ( 
       mgmt_clk        => clk,
       powerup_channel => powerup_channel(0),
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

       txsymbol0      => ch0_symbol0,
       txsymbol1      => ch0_symbol1,
                  
       gtptxp          => gtptxp,
       gtptxn          => gtptxn,
       symbolclk       => symbolclk);       
end Behavioral;
