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

               clock_adj_done  : out STD_LOGIC;
               equ_adj_done    : out STD_LOGIC;
               align_adj_done  : out STD_LOGIC;
        
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

           TXOUTCLK       : out STD_LOGIC;
           TXOUTCLKFABRIC : out STD_LOGIC;
           TXOUTCLKPCS    : out STD_LOGIC;
           
           TXDATA         : in std_logic_vector(19 downto 0);

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
		   swing_0p4           : in    std_logic;
           swing_0p6           : in    std_logic;
           swing_0p8           : in    std_logic;
           preemp_0p0          : in    STD_LOGIC;
           preemp_3p5          : in    STD_LOGIC;
           preemp_6p0          : in    STD_LOGIC;
           clock_adj_done      : in    STD_LOGIC;
           align_adj_done      : in    STD_LOGIC;
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
        clk            : in  std_logic;
        channel_delay  : in  std_logic_vector(1 downto 0);
        clock_train    : in  std_logic;
        align_train    : in  std_logic;
        data_in        : in  std_logic_vector(19 downto 0);
        data_out       : out std_logic_vector(19 downto 0)
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
    signal txoutclkfabric   : std_logic := '0';
    signal txoutclkpcs      : std_logic := '0';
    signal txusrclk         : std_logic := '0';
    signal txusrclk2        : std_logic := '0';
    
    signal tx_running       : std_logic := '0';

    signal powerup_channel : std_logic_vector(3 downto 0);
    signal clock_adj_done  : std_logic := '0';
    signal equ_adj_done    : std_logic := '0';
    signal align_adj_done  : std_logic := '0';
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
     
begin
process(clk)
    begin
        if rising_edge(clk) then
            case switches(3 downto 0) is
                when "0000" => leds <= h_visible_len(7 downto 0);
                when "0001" => leds <= "0000" & h_visible_len(11 downto 8);
                when "0010" => leds <= h_blank_len(7 downto 0);
                when "0011" => leds <= "0000" & h_blank_len(11 downto 8);
                when "0100" => leds <= h_front_len(7 downto 0);
                when "0101" => leds <= "0000" & h_front_len(11 downto 8);
                when "0110" => leds <= h_sync_len(7 downto 0);
                when "0111" => leds <= "0000" & h_sync_len(11 downto 8);
                when "1000" => leds <= h_visible_len(7 downto 0);
                when "1001" => leds <= "0000" & v_visible_len(11 downto 8);
                when "1010" => leds <= h_blank_len(7 downto 0);
                when "1011" => leds <= "0000" & v_blank_len(11 downto 8);
                when "1100" => leds <= h_front_len(7 downto 0);
                when "1101" => leds <= "0000" & v_front_len(11 downto 8);
                when "1110" => leds <= h_sync_len(7 downto 0);
                when others => leds <= "0000" & v_sync_len(11 downto 8);
            end case;
        end if;
    end process;
i_aux_channel: aux_channel port map ( 
		   clk             => clk,
		   debug_pmod      => interface_debug,
		   ------------------------------
           edid_de         => edid_de,
           dp_reg_de       => dp_reg_de,
           adjust_de       => adjust_de,
           status_de       => status_de,
           aux_addr        => aux_data,
		   aux_data        => aux_addr,
		   ------------------------------
		   link_count      => active_channel_count,

           preemp_0p0      => preemp_0p0, 
           preemp_3p5      => preemp_3p5,
           preemp_6p0      => preemp_6p0,           
           swing_0p4       => swing_0p4,
           swing_0p6       => swing_0p6,
           swing_0p8       => swing_0p8,
           clock_adj_done  => clock_adj_done,
           align_adj_done  => align_adj_done,
           
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

    debug_pmod(0) <= interface_debug(0);
    debug_pmod(1) <= tx_running;
    debug_pmod(2) <= tx_clock_train;
    debug_pmod(3) <= tx_align_train;
    debug_pmod(4) <= tx_powerup;
    debug_pmod(5) <= clock_adj_done;
    debug_pmod(6) <= equ_adj_done;
    debug_pmod(7) <= align_adj_done;

i_edid_decode: edid_decode port map ( 
           clk              => clk,    
           edid_de          => edid_de,
           edid_addr        => aux_data,
           edid_data        => aux_addr,
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
            data               => aux_data,
            addr               => aux_addr,
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

i_video_generator: video_generator Port map (
            clk              => clk,    
 
            h_visible_len    => h_visible_len,
            h_blank_len      => h_blank_len,
            h_front_len      => h_front_len,
            h_sync_len       => h_sync_len,
            
            v_visible_len    => v_visible_len,
            v_blank_len      => v_blank_len,
            v_front_len      => v_front_len,
            v_sync_len       => v_sync_len,
 
            vid_blank        => open,
            vid_hsync        => open,
            vid_vsync        => open);

--    debug_pmod(4) <= support_RGB444;
--    debug_pmod(5) <= support_YCC444;
--    debug_pmod(6) <= support_YCC422;
--    debug_pmod(7) <= dp_valid;


i_link_signal_mgmt:  link_signal_mgmt Port map (
        mgmt_clk        => clk,

        tx_powerup      => tx_powerup, 
        
        status_de       => status_de,
        adjust_de       => adjust_de,
        data            => aux_data,
        addr            => aux_addr,

        sink_channel_count   => sink_channel_count,
        source_channel_count => source_channel_count,
        active_channel_count => active_channel_count,

        powerup_channel => powerup_channel,

        clock_adj_done  => clock_adj_done,
        equ_adj_done    => equ_adj_done,
        align_adj_done  => align_adj_done,

        preemp_0p0      => preemp_0p0, 
        preemp_3p5      => preemp_3p5,
        preemp_6p0      => preemp_6p0,
            
        swing_0p4       => swing_0p4,
        swing_0p6       => swing_0p6,
        swing_0p8       => swing_0p8);

i_train_channel0: training_and_channel_delay port map (
        clk            => txoutclkfabric,

        channel_delay  => "00",
        clock_train    => tx_clock_train,
        align_train    => tx_align_train, 
        
        data_in        => x"33333",
        data_out       => data_channel_0
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

       txdata          => data_channel_0,

       gtptxp          => gtptxp,
       gtptxn          => gtptxn,
       
       txoutclk        => txoutclk,
       txoutclkfabric  => txoutclkfabric,
       txoutclkpcs     => txoutclkpcs);

    
end Behavioral;
