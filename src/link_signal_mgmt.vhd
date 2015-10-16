----------------------------------------------------------------------------------
-- Module Name: link_signal_mgmt - Behavioral
--
-- Description: Controls the settings and state of the GTX transceivers based on
--              The registers that are read from the host.
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

entity link_signal_mgmt is
    Port ( mgmt_clk    : in  STD_LOGIC;

           tx_powerup  : in  STD_LOGIC;  -- Falling edge is used used as a reset too!
        
           status_de   : in  std_logic;
           adjust_de   : in  std_logic;
           addr        : in  std_logic_vector(7 downto 0);
           data        : in  std_logic_vector(7 downto 0);

           -------------------------------------------
           sink_channel_count   : in  std_logic_vector(2 downto 0);
           source_channel_count : in  std_logic_vector(2 downto 0);
           stream_channel_count : in  std_logic_vector(2 downto 0);
           active_channel_count : out std_logic_vector(2 downto 0);
           ---------------------------------------------------------
           powerup_channel : out std_logic_vector(3 downto 0) := (others => '0');
           -----------------------------------------
           clock_locked   : out STD_LOGIC;
           equ_locked     : out STD_LOGIC;
           symbol_locked  : out STD_LOGIC;
           align_locked   : out STD_LOGIC;

           preemp_0p0  : out STD_LOGIC := '0';
           preemp_3p5  : out STD_LOGIC := '0';
           preemp_6p0  : out STD_LOGIC := '0';
    
           swing_0p4   : out STD_LOGIC := '0';
           swing_0p6   : out STD_LOGIC := '0';
           swing_0p8   : out STD_LOGIC := '0');
end link_signal_mgmt;

architecture arch of link_signal_mgmt is
    signal power_mask     : std_logic_vector(3 downto 0) := "0000";
    signal preemp_level   : std_logic_vector(1 downto 0) := "00";
    signal voltage_level  : std_logic_vector(1 downto 0) := "00";
    signal channel_state  : std_logic_vector(23 downto 0):= (others => '0');
    signal channel_adjust : std_logic_vector(15 downto 0):= (others => '0');
    signal active_channel_count_i : std_logic_vector(2 downto 0);
    signal pipe_channel_count : std_logic_vector(2 downto 0);

begin
    active_channel_count <= active_channel_count_i;
process(mgmt_clk)
    begin
        if rising_edge(mgmt_clk) then
            ----------------------------------------------------------
            -- Work out how many channels will be active 
            -- (the min of source_channel_count and sink_channel_count
            --
            -- Also work out the power-up mask for the transceivers
            -----------------------------------------------------------
            case source_channel_count is
                when "100" =>
                    case sink_channel_count is
                        when "100"  => pipe_channel_count <= "100";
                        when "010"  => pipe_channel_count <= "010";
                        when others => pipe_channel_count <= "001";
                    end case;                        
                when "010" =>
                    case sink_channel_count is
                        when "100"  => pipe_channel_count <= "010";
                        when "010"  => pipe_channel_count <= "010";
                        when others => pipe_channel_count <= "001";
                    end case;                                            
                when others =>
                    pipe_channel_count <= "001";
            end case;
           
            case stream_channel_count is
                when "100" =>
                    case pipe_channel_count is
                        when "100"  => active_channel_count_i <= "100"; power_mask <= "1111";
                        when "010"  => active_channel_count_i <= "010"; power_mask <= "0000";
                        when others => active_channel_count_i <= "000"; power_mask <= "0000";
                    end case;                        
                when "010" =>
                    case pipe_channel_count is
                        when "100"  => active_channel_count_i <= "010"; power_mask <= "0011";
                        when "010"  => active_channel_count_i <= "010"; power_mask <= "0011";
                        when others => active_channel_count_i <= "000"; power_mask <= "0000";
                    end case;                                            
                when others =>
                    active_channel_count_i <= "001"; power_mask <= "0001";
            end case;

            
            ---------------------------------------------
            -- If the powerup is not asserted, then reset 
            -- everything.
            ---------------------------------------------
            if tx_powerup  = '1' then
                powerup_channel  <= power_mask;
            else
                powerup_channel  <= (others => '0');
                preemp_level     <= "00";
                voltage_level    <= "00";
                channel_state    <= (others => '0');
                channel_adjust   <= (others => '0');
            end if;
        
            ---------------------------------------------
            -- Decode the power and pre-emphasis levels
            ---------------------------------------------
            case preemp_level is 
                when "00"   => preemp_0p0 <= '1'; preemp_3p5 <= '0'; preemp_6p0 <= '0';
                when "01"   => preemp_0p0 <= '0'; preemp_3p5 <= '1'; preemp_6p0 <= '0';
                when others => preemp_0p0 <= '0'; preemp_3p5 <= '0'; preemp_6p0 <= '1';
            end case;

            case voltage_level is
                when "00"   => swing_0p4 <= '1';  swing_0p6 <= '0';  swing_0p8 <= '0';
                when "01"   => swing_0p4 <= '0';  swing_0p6 <= '1';  swing_0p8 <= '0';
                when others => swing_0p4 <= '0';  swing_0p6 <= '0';  swing_0p8 <= '1';
            end case;            

            -----------------------------------------------
            -- Receive the status data from the AUX channel
            -----------------------------------------------
            if status_de = '1' then
                case addr is 
                    when x"02" => channel_state( 7 downto  0) <= data;
                    when x"03" => channel_state(15 downto  8) <= data;                                  
                    when x"04" => channel_state(23 downto 16) <= data;                                  
                    when others => NULL;
                end case;
            end if;

            -----------------------------------------------
            -- Receive the channel adjustment request 
            -----------------------------------------------
            if adjust_de = '1' then
                case addr is 
                    when x"00" => channel_adjust( 7 downto 0) <= data;
                    when x"01" => channel_adjust(15 downto 8) <= data;                                  
                    when others => NULL;
                end case;
            end if;

            -----------------------------------------------
            -- Update the status signals based on the 
            -- register data recieved over from the AUX
            -- channel. 
            -----------------------------------------------
            clock_locked  <= '0';
            equ_locked    <= '0';
            symbol_locked <= '0';
            case active_channel_count_i is
                when "001"  => if (channel_state(3 downto 0) AND x"1") = x"1" then
                                  clock_locked <= '1';
                               end if;
                               if (channel_state(3 downto 0) AND x"3") = x"3" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(3 downto 0) AND x"7") = x"7" then
                                  symbol_locked <= '1';
                               end if;
                when "010"  => if (channel_state(7 downto 0) AND x"11") = x"11" then
                                  clock_locked <= '1';
                               end if;
                               if (channel_state(7 downto 0) AND x"33") = x"33" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(7 downto 0) AND x"77") = x"77" then
                                  symbol_locked <= '1';
                               end if;

                when "100"  => if (channel_state(15 downto 0) AND x"1111") = x"1111" then
                                 clock_locked <= '1';
                               end if;
                               if (channel_state(15 downto 0) AND x"3333") = x"3333" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(15 downto 0) AND x"7777") = x"7777" then
                                  symbol_locked <= '1';
                               end if;
                               
                when others => NULL;
            end case;
            align_locked <= channel_state(16);
        end if;
    end process;
end architecture;