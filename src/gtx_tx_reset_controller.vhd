----------------------------------------------------------------
-- Transceiver and channel PLL control
-- ===================================
-- 
-- 1. Initial reset state
--    Set GTTXRESET High, 
--    Set GTTXPMARESET low 
--    Set TXPCSRESET low.
--    Set CPLLPD high
--    Set GTRESETSEL low.
-- 
-- 2. Hold CPLLPD high until reference clock is seen on fabric
-- 
-- 3. Wait at least 500ns 
-- 
-- 4. Start up the channel PLL
--    Drop CPLLPD 
--    Assert CPLLLOCKEN
-- 
-- 5. Wait for CPLLLOCK to go high
-- 
-- 6. Start up the high speed transceiver
--    Assert GTTXUSERRDY
--    Drop GTTXRESET (you can use the CPLLLOCK signal is OK)
-- 
-- 7. Monitor GTTXRESETDONE until it goes high
-- 
-- The transceiver's TX Should then be operational. 
-- 
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gtx_tx_reset_controller is
    port (  clk             : in  std_logic;
            ref_clk         : in  std_logic;
            powerup_channel : in  std_logic;
            tx_running      : out std_logic := '0';
            txreset         : out std_logic := '1';
            txuserrdy       : out std_logic := '0';
            txpmareset      : out std_logic := '1';
            txpcsreset      : out std_logic := '1';
            pllpd           : out std_logic := '1';
            pllreset        : out std_logic;
            plllocken       : out std_logic := '1';
            plllock         : in  std_logic;
            resetsel        : out std_logic := '0';
            txresetdone     : in  std_logic);
end entity;

architecture arch of gtx_tx_reset_controller is
    signal state               : std_logic_vector(3 downto 0) := x"0";
    signal counter             : unsigned(7 downto 0) := (others => '0');
    signal ref_clk_counter     : unsigned(7 downto 0) := (others => '0');
    signal ref_clk_detect_last : std_logic := '0';
    signal ref_clk_detect      : std_logic := '0';
    signal ref_clk_detect_meta : std_logic := '0';
begin

process(ref_clk)
    begin
        if rising_edge(ref_clk) then
            ref_clk_counter <= ref_clk_counter + 1;
        end if;
    end process;

process(clk)
    begin
        if rising_edge(clk) then
            counter             <= counter + 1;
            case state is
                when x"0" => -- reset state;
                    txreset    <= '1';
                    txuserrdy  <= '0';
                    txpmareset <= '0';
                    txpcsreset <= '0';
                    pllpd      <= '1';
                    pllreset   <= '1';
                    plllocken  <= '0';
                    resetsel   <= '0';
                    state      <= x"1";

                when x"1" => -- wait for reference clock
                    counter <= (others => '0');
                    if ref_clk_detect /= ref_clk_detect_last then
                        state <= x"2";
                    end if;

                when x"2" => -- wait for 500ns
                    -- counter will set high bit after 128 cycles
                    if counter(counter'high) = '1' then
                        state <= x"3";
                    end if;

                when x"3" => -- start up the PLL
                    pllpd     <= '0';
                    pllreset  <= '0';
                    plllocken <= '1';
                    state      <= x"4";

                when x"4" => -- Waiting for the PLL to lock
                    if plllock = '1' then
                        state <= x"5";
                     end if;    

                when x"5" => -- Starting up the GTX
                    txreset   <= '0';
                    state     <= x"6";
                    counter   <= (others => '0');

                when x"6" => -- wait for 500ns
                    -- counter will set high bit after 128 cycles
                    if counter(counter'high) = '1' then
                        state <= x"7";
                    end if;

                when x"7" => 
                    txuserrdy <= '1';
                    if txresetdone = '1' then
                        state <= x"8";
                    end if;

                when x"8" =>
                    tx_running <= '1';    

                when others => -- Monitoring for it to have started up;
                    state <= x"0";

            end case;

            if powerup_channel = '0' then
                state <= x"0";
            end if;

            ref_clk_detect_last <= ref_clk_detect;
            ref_clk_detect      <= ref_clk_detect_meta;
            ref_clk_detect_meta <= ref_clk_counter(ref_clk_counter'high);
        end if;
    end process;
end architecture;
