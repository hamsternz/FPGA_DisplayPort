library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_aux_channel is
end entity;

architecture arch of tb_aux_channel is
	component top_level is 
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
	end component;

	signal clk         : std_logic := '0';
	signal debug_pmod : std_logic_vector(7 downto 0) := (others => '0');
    signal dp_tx_aux_p : std_logic := '0';
    signal dp_tx_aux_n : std_logic := '0';
    signal dp_rx_aux_p : std_logic := '0';
    signal dp_rx_aux_n : std_logic := '0';
    signal dp_tx_hpd   : std_logic := '0';


    signal refclk0_p       : STD_LOGIC;
    signal refclk0_n       : STD_LOGIC;
    signal refclk1_p       : STD_LOGIC := '1';
    signal refclk1_n       : STD_LOGIC := '0';
    signal gtptxp          : std_logic;
    signal gtptxn          : std_logic;    
begin

uut: top_level PORT MAP (
		clk    => clk,
		switches => (others => '0'),
		leds => open,
	    debug_pmod  => debug_pmod,
        dp_tx_aux_p => dp_tx_aux_p,
        dp_tx_aux_n => dp_tx_aux_n,
        dp_rx_aux_p => dp_rx_aux_p,
        dp_rx_aux_n => dp_rx_aux_n,  
        dp_tx_hp_detect => dp_tx_hpd,  
        refclk0_p  => refclk0_p,
        refclk0_n  => refclk0_n,
        refclk1_p  => refclk1_p,
        refclk1_n  => refclk1_n,
        gtptxp     => gtptxp,
        gtptxn     => gtptxn    
	);

process
    begin
        dp_tx_aux_p <= 'Z';
        dp_tx_aux_n <= 'Z';
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        for i in 0 to 15 loop
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 500 ns;
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 500 ns;
        end loop;

        dp_tx_aux_p <= '1';
        dp_tx_aux_n <= '0';
        wait for 2000 ns;
        dp_tx_aux_p <= '0';
        dp_tx_aux_n <= '1';
        wait for 2000 ns;

        for i in 0 to 7 loop
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 500 ns;
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 500 ns;
        end loop;

        dp_tx_aux_p <= '1';
        dp_tx_aux_n <= '0';
        wait for 2000 ns;
        dp_tx_aux_p <= '0';
        dp_tx_aux_n <= '1';
        wait for 2000 ns;
        dp_tx_aux_p <= 'Z';
        dp_tx_aux_n <= 'Z';


        for k in 0 to 7 loop
            wait until rising_edge(dp_tx_aux_p);
            wait until rising_edge(dp_tx_aux_p);
            wait until rising_edge(dp_tx_aux_p);
            wait for 100 us;
            -- Extra for the ACK
            for i in 0 to 16 loop
                dp_tx_aux_p <= '0';
                dp_tx_aux_n <= '1';
                wait for 500 ns;
                dp_tx_aux_p <= '1';
                dp_tx_aux_n <= '0';
                wait for 500 ns;
            end loop;
 
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 2000 ns;
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 2000 ns;

            for i in 0 to 7 loop
                dp_tx_aux_p <= '0';
                dp_tx_aux_n <= '1';
                wait for 500 ns;
                dp_tx_aux_p <= '1';
                dp_tx_aux_n <= '0';
                wait for 500 ns;
            end loop;

            for j in 0 to 15 loop
    
                dp_tx_aux_p <= '1';
                dp_tx_aux_n <= '0';
                wait for 500 ns;
                dp_tx_aux_p <= '0';
                dp_tx_aux_n <= '1';
                wait for 500 ns;
    
                for i in 1 to 7 loop
                    dp_tx_aux_p <= '0';
                    dp_tx_aux_n <= '1';
                    wait for 500 ns;
                    dp_tx_aux_p <= '1';
                    dp_tx_aux_n <= '0';
                    wait for 500 ns;
                end loop;
            end loop;
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 2000 ns;
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 2000 ns;
    
            dp_tx_aux_p <= 'Z';
            dp_tx_aux_n <= 'Z';
        end loop;

    end process;
process
	begin
		wait for 5 ns;
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
	end process;
	
process
    begin
        refclk0_p  <='1';
        refclk0_n  <='0';
        wait for 3.6 ns;
        refclk0_p  <='0';
        refclk0_n  <='1';
        wait for 3.6 ns;
    end process;

end architecture;