----------------------------------------------------------------
-- Module Name: gtx_tx_reset_controller - Behavioral
--
-- Description: Controls the power-up and reset of a GTX
--              high speed Transceiver
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
--  0.2 | 2015-09-17 | Syncrhonise txresetdone to remove timing errors
------------------------------------------------------------------------------------
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
    signal txresetdone_meta    : std_logic := '0';
    signal txresetdone_i       : std_logic := '0';
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
                    if txresetdone_i = '1' then
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
            
            txresetdone_i    <= txresetdone_meta;
            txresetdone_meta <= txresetdone;

        end if;
    end process;
end architecture;
