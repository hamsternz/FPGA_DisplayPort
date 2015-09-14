----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: hotplug_decode - Behavioral
--
----------------------------------------------------------------------------------
-- The Hot Plug Detect signal has two uses, one is to to signal the physical 
-- connection of a sink device, and the other is to signal an interrupt if the 
--  state changes.
-- 
-- An interrupt is signalled by a 500us to 1ms '0' pulse. But from the spec
-- any pulse under 2ms is to be interperated as and IRQ
--
-- NOTE: Assumes that clk is running at 100MHz.
----------------------------------------------------------------------------------
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
