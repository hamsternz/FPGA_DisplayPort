library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_test_source is
end entity;

architecture arch of tb_test_source is
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

    component dec_8b10b is	
    port(
		RESET : in std_logic ;	-- Global asynchronous reset (AH) 
		RBYTECLK : in std_logic ;	-- Master synchronous receive byte clock
		AI, BI, CI, DI, EI, II : in std_logic ;
		FI, GI, HI, JI : in std_logic ; -- Encoded input (LS..MS)		
		KO : out std_logic ;	-- Control (K) character indicator (AH)
		HO, GO, FO, EO, DO, CO, BO, AO : out std_logic 	-- Decoded out (MS..LS)
	    );
    end component;
 	
	signal clk                       : std_logic;

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

	signal sr_inserted_data0  : std_logic_vector(7 downto 0);
    signal sr_inserted_data0k : std_logic;
    signal sr_inserted_data1  : std_logic_vector(7 downto 0);
    signal sr_inserted_data1k : std_logic;

    signal scramble_bypass  : std_logic := '1';
	signal scrambled_data0  : std_logic_vector(7 downto 0);
    signal scrambled_data0k : std_logic;
    signal scrambled_data1  : std_logic_vector(7 downto 0);
    signal scrambled_data1k : std_logic;
    
    signal ch0_data0              : std_logic_vector(7 downto 0);
    signal ch0_data0k             : std_logic;
    signal ch0_data0forceneg      : std_logic;
    signal ch0_symbol0            : std_logic_vector(9 downto 0);
    --
    signal ch0_data1              : std_logic_vector(7 downto 0);
    signal ch0_data1k             : std_logic;
    signal ch0_data1forceneg      : std_logic;
    signal ch0_symbol1            : std_logic_vector(9 downto 0);
    
    signal dec0            : std_logic_vector(8 downto 0);
    
    signal rd : unsigned(9 downto 0) := (others => '0');
                     
begin
i_test_source: test_source port map ( 
            clk          => clk,
            ready        => test_signal_ready,
            data0        => test_signal_data0,
            data0k       => test_signal_data0k,
            data1        => test_signal_data1,
            data1k       => test_signal_data1k,
            switch_point => test_signal_switch_point
        );

i_idle_pattern_inserter: idle_pattern_inserter  port map ( 
            clk             => clk,
            channel_ready   => '1',
            source_ready    => test_signal_ready,
            
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
            clk        => clk,
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
            clk        => clk,
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
        clk             => clk,

        channel_delay   => "00",
        clock_train     => '0',
        align_train     => '0', 
        
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
        clk           => clk,
        data0         => ch0_data0,
        data0k        => ch0_data0k,
        data0forceneg => ch0_data0forceneg,
        data1         => ch0_data1,
        data1k        => ch0_data1k,
        data1forceneg => ch0_data1forceneg,
        symbol0       => ch0_symbol0,
        symbol1       => ch0_symbol1
        );

process(clK)
    begin
        if rising_edge(clk) then
            rd <= rd  - to_unsigned(10,10)
                + unsigned(ch0_symbol0(0 downto 0))
                + unsigned(ch0_symbol0(1 downto 1))
                + unsigned(ch0_symbol0(2 downto 2))
                + unsigned(ch0_symbol0(3 downto 3))
                + unsigned(ch0_symbol0(4 downto 4))
                + unsigned(ch0_symbol0(5 downto 5))
                + unsigned(ch0_symbol0(6 downto 6))
                + unsigned(ch0_symbol0(7 downto 7))
                + unsigned(ch0_symbol0(8 downto 8))
                + unsigned(ch0_symbol0(9 downto 9))
                + unsigned(ch0_symbol1(0 downto 0))
                + unsigned(ch0_symbol1(1 downto 1))
                + unsigned(ch0_symbol1(2 downto 2))
                + unsigned(ch0_symbol1(3 downto 3))
                + unsigned(ch0_symbol1(4 downto 4))
                + unsigned(ch0_symbol1(5 downto 5))
                + unsigned(ch0_symbol1(6 downto 6))
                + unsigned(ch0_symbol1(7 downto 7))
                + unsigned(ch0_symbol1(8 downto 8))
                + unsigned(ch0_symbol1(9 downto 9));                
        end if;
    end process;
    
data_dec0: dec_8b10b port map (
		RESET => '0',
		RBYTECLK => clk,
		AI => ch0_symbol0(0), 
		BI => ch0_symbol0(1), 
		CI => ch0_symbol0(2), 
		DI => ch0_symbol0(3), 
		EI => ch0_symbol0(4), 
		II => ch0_symbol0(5),
		FI => ch0_symbol0(6),
		GI => ch0_symbol0(7), 
		HI => ch0_symbol0(8), 
		JI => ch0_symbol0(9),
			
		KO => dec0(8), 
		HO => dec0(7),
		GO => dec0(6), 
		FO => dec0(5), 
		EO => dec0(4), 
		DO => dec0(3), 
		CO => dec0(2), 
		BO => dec0(1), 
		AO => dec0(0) 
	    );

process 
    begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;
end architecture;
