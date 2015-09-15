----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.08.2015 22:35:35
-- Design Name: 
-- Module Name: transceiver_test - Behavioral
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

entity transceiver_test is
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
end transceiver_test;

architecture Behavioral of transceiver_test is
    component test_source is
        port ( 
            clk    : in  std_logic;
            data0  : out std_logic_vector(7 downto 0);
            data0k : out std_logic;
            data1  : out std_logic_vector(7 downto 0);
            data1k : out std_logic
        );
    end component;
    
    component idle_pattern is
        port ( 
            clk    : in  std_logic;
            data0  : out std_logic_vector(7 downto 0);
            data0k : out std_logic;
            data1  : out std_logic_vector(7 downto 0);
            data1k : out std_logic
        );
    end component;

    component scrambler is
        port ( 
            clk        : in  std_logic;
            bypass0    : in  std_logic;            
            in_data0   : in  std_logic_vector(7 downto 0);
            in_data0k  : in  std_logic;
            bypass1    : in  std_logic;            
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

           txsymbol0      : in  std_logic_vector(9 downto 0);
           txsymbol1      : in  std_logic_vector(9 downto 0);
           symbolclk    : out STD_LOGIC;

           gtptxp         : out std_logic;
           gtptxn         : out std_logic);
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

    --------------------------------------------------------------------------
    signal tx_powerup       : std_logic := '0';
    signal tx_clock_train   : std_logic := '0';
    signal tx_align_train   : std_logic := '0';    
    signal data_channel_0   : std_logic_vector(19 downto 0):= (others => '0');
    ---------------------------------------------
    -- Transceiver signals
    ---------------------------------------------
    signal txresetdone      : std_logic := '0';
    signal symbolclk        : std_logic := '0';
    
    signal tx_running       : std_logic := '0';

    signal powerup_channel : std_logic_vector(3 downto 0) := (others => '0');
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

    signal test_signal_data0      : std_logic_vector(7 downto 0);
    signal test_signal_data0k     : std_logic;
    signal test_signal_data1      : std_logic_vector(7 downto 0);
    signal test_signal_data1k     : std_logic;
    signal test_signal_symbol0     : std_logic_vector(9 downto 0);
    signal test_signal_symbol1     : std_logic_vector(9 downto 0);
    --
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

begin
    
process(clk)
    begin
        if rising_edge(clk) then
            powerup_channel <= (others => '1');
        end if;
    end process;

i_test_source : idle_pattern port map ( 
            clk    => symbolclk,
            data0  => test_signal_data0,
            data0k => test_signal_data0k,
            data1  => test_signal_data1,
            data1k => test_signal_data1k
        );

i_scrambler : scrambler
        port map ( 
            clk        => symbolclk,
            bypass0       => '1',
            bypass1       => '1',
            in_data0   => test_signal_data0,
            in_data0k  => test_signal_data0k,
            in_data1   => test_signal_data1,
            in_data1k  => test_signal_data1k,
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
        
        in_data0          => test_signal_data0,
        in_data0k         => test_signal_data0k,
        in_data1          => test_signal_data1,
        in_data1k         => test_signal_data1k,

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
       symbolclk       => symbolclk, 

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
       gtptxn          => gtptxn);
    
end Behavioral;
