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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
    component Transceiver is
    Port ( mgmt_clk        : in  STD_LOGIC;
           powerup_channel : in  STD_LOGIC;
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
		   clk             : in    std_logic;
		   debug_pmod      : out   std_logic_vector(7 downto 0);
		   ------------------------------
           edid_de         : out   std_logic;
           edid_addr       : out   std_logic_vector(7 downto 0);
		   edid_data       : out   std_logic_vector(7 downto 0);
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
    signal edid_data        : std_logic_vector(7 downto 0);
    signal edid_addr        : std_logic_vector(7 downto 0);
    signal invalidate       : std_logic;
    
    signal valid            : std_logic := '0';
    
    signal support_RGB444   : std_logic := '0';
    signal support_YCC444   : std_logic := '0';
    signal support_YCC422   : std_logic := '0';
    
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

    
--    signal PLL0CLK        : STD_LOGIC := '0';
--    signal gtrefclk0      : STD_LOGIC := '0';
--    signal PLL1CLK        : STD_LOGIC := '0';
--    signal gtrefclk1      : STD_LOGIC := '0';
--    signal gtrxreset      : STD_LOGIC := '0';
--    signal rxlpmreset     : STD_LOGIC := '0';
--    signal gttxreset      : STD_LOGIC := '0';
--    signal txuserrdy      : STD_LOGIC := '0';
--    signal txpmaresetdone : std_logic := '0';      
    signal txresetdone    : std_logic := '0';
    signal txoutclk       : std_logic := '0';
    signal txoutclkfabric : std_logic := '0';
    signal txoutclkpcs    : std_logic := '0';
    signal txusrclk       : std_logic := '0';
    signal txusrclk2      : std_logic := '0';

    signal tx_running     :  std_logic := '0';
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
--		   debug_pmod(0)   => debug_pmod(0),
--		   debug_pmod(7 downto 1) => open,
		   debug_pmod      => open,
		   ------------------------------
           edid_de         => edid_de,
           edid_addr       => edid_data,
		   edid_data       => edid_addr,
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
           edid_addr        => edid_data,
           edid_data        => edid_addr,
           invalidate       => '0',
    
           valid            => valid,
    
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
 
            vid_blank        => debug_pmod(1),
            vid_hsync        => debug_pmod(2),
            vid_vsync        => debug_pmod(3));

    debug_pmod(4) <= support_RGB444;
    debug_pmod(5) <= support_YCC444;
    debug_pmod(6) <= support_YCC422;
    debug_pmod(7) <= valid;


i_tx0: Transceiver Port map ( 
       mgmt_clk        => clk,
       powerup_channel => '1',
       tx_running      => tx_running,

       refclk0_p   => refclk0_p,
       refclk0_n   => refclk0_n,

       refclk1_p   => refclk1_p,
       refclk1_n   => refclk1_n,

       txdata     => "11001111110011000000",

       gtptxp         => gtptxp,
       gtptxn         => gtptxn,
       
       txoutclk       => txoutclk,
       txoutclkfabric => txoutclkfabric,
       txoutclkpcs    => txoutclkpcs);

    
end Behavioral;
