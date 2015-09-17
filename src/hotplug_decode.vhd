----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: hotplug_decode - Behavioral
--
-- Description: The Hot Plug Detect signal has two uses, one is to to signal the 
--              physical connection of a sink device, and the other is to signal 
--              an interrupt if the  state changes.
-- 
--              An interrupt is signalled by a 500us to 1ms '0' pulse. But from 
--              the spec any pulse under 2ms is to be interperated as and IRQ
--
-- NOTE: Assumes that clk is running at 100MHz.
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

entity hotplug_decode is
    port (clk     : in  std_logic;
          hpd     : in  std_logic;
          irq     : out std_logic := '0';
          present : out std_logic := '0');
end entity;

architecture arch of hotplug_decode is
   signal hpd_meta1  : std_logic := '0';
   signal hpd_meta2  : std_logic := '0';
   signal hpd_synced : std_logic := '0';
   signal hpd_last   : std_logic := '0';

   signal pulse_count  : unsigned (17 downto 0);
begin

process(clk) 
    begin
        if rising_edge(clk) then
            irq <= '0';
            if hpd_last = '0' then
                if pulse_count = 2000000 then
                    if hpd_synced = '0' then
                        ----------------------------------
                        -- Sink has gone away for over 1ms
                        ----------------------------------
                        present <= '0';
                    else
                        ----------------------------------
                        -- Sink has been connected
                        ----------------------------------
                        present <= '1';
                    end if;
                else
                    -------------------------------------
                    if hpd_synced = '1' then
                        -------------------------------------
                        -- Signal is back, but less than 2ms
                        -- so signal an IRQ...
                        -------------------------------------
                        irq <= '1';
                    end if;
                    pulse_count <= pulse_count + 1;
                end if;
            else
                -------------------------------------------
                -- Reset the width counter while waiting 
                -- for the HPD signal to fall.
                -------------------------------------------
                pulse_count <= (others => '0');
            end if;
            hpd_last   <= hpd_synced;
            hpd_synced <= hpd_meta1;
            hpd_meta1  <= hpd_meta2;
            hpd_meta2  <= hpd;
        end if;
    end process;
end architecture;
