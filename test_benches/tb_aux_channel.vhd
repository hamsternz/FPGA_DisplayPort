----------------------------------------------------------------------------------
-- Module Name: tb_aux_channel - Behavioral
--
-- Description: A testbench for the tb_aux_channel
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
        gtptxp          : out std_logic_vector(1 downto 0);
        gtptxn          : out std_logic_vector(1 downto 0);    
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
    signal gtptxp          : std_logic_vector(1 downto 0);
    signal gtptxn          : std_logic_vector(1 downto 0);    
    
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
        
        -- Reply with 00s
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
        
-- Now the display port version read
-- Reply with 00 01
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
        dp_tx_aux_p <= 'Z';
        dp_tx_aux_n <= 'Z';


-- Now the DisplayPort register read
-- Reply with 00 00 00 00 00 00 00 00 00 00 00 00 00
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

        for i in 0 to 13*8 loop
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
        
 --- register write 1
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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

 --- register write 2
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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

 --- register write downspread
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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


--- register write set link count
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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

--- register write link tranning pattern # 1 
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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

--- register write set link voltages 
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00s
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

--- register read - link status  
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait until rising_edge(dp_tx_aux_p);
        wait for 100 us;
        
        -- Reply with 00 01 00 00 
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
        
        for i in 0 to 6 loop
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 500 ns;
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 500 ns;
        end loop;

        dp_tx_aux_p <= '1';
        dp_tx_aux_n <= '0';
        wait for 500 ns;
        dp_tx_aux_p <= '0';
        dp_tx_aux_n <= '1';
        wait for 500 ns;

        for i in 0 to 7 loop
            dp_tx_aux_p <= '0';
            dp_tx_aux_n <= '1';
            wait for 500 ns;
            dp_tx_aux_p <= '1';
            dp_tx_aux_n <= '0';
            wait for 500 ns;
        end loop;

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


        wait;
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