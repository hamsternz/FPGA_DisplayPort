----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz< 
-- 
-- Module Name: dp_aux_messages - Behavioral
--
-- Description: Messages that will be sent over thr DisplayPort AUX interface
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

entity dp_aux_messages is
   port ( clk         : in std_logic;

         -- Interface to send messages
         msg_de      : in std_logic;
         msg         : in std_logic_vector(7 downto 0); 
         busy        : out std_logic;

         --- Interface to the AUX Channel
         aux_tx_wr_en : out std_logic;
         aux_tx_data  : out std_logic_vector(7 downto 0));
end dp_aux_messages;

architecture arch of dp_aux_messages is
    signal counter : unsigned(11 downto 0) := (others => '0');
begin

process(clk)
   begin
      if rising_edge(clk) then
         case counter is
            -- Write to I2C device at x50 (EDID)
            when x"010" => aux_tx_data <= x"40"; aux_tx_wr_en <= '1';
            when x"011" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"012" => aux_tx_data <= x"50"; aux_tx_wr_en <= '1';
            when x"013" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"014" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
         
            -- Read a block of EDID data
            when x"020" => aux_tx_data <= x"50"; aux_tx_wr_en <= '1';
            when x"021" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"022" => aux_tx_data <= x"50"; aux_tx_wr_en <= '1';
            when x"023" => aux_tx_data <= x"0F"; aux_tx_wr_en <= '1';

            -- Read Sink count
            when x"030" => aux_tx_data <= x"90"; aux_tx_wr_en <= '1';
            when x"031" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"032" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"033" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';

            -- Read DP configuration registers (12 of them)
            when x"040" => aux_tx_data <= x"90"; aux_tx_wr_en <= '1';
            when x"041" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"042" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"043" => aux_tx_data <= x"0B"; aux_tx_wr_en <= '1';

            -- Write DPCD powerstate D3 
            when x"050" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"051" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';
            when x"052" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"053" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"054" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';

            -- Set channel coding (8b/10b)
            when x"060" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"061" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"062" => aux_tx_data <= x"08"; aux_tx_wr_en <= '1';
            when x"063" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"064" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';

            -- Set link bandwidth 2.70 Gb/s
            when x"070" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"071" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"072" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"073" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"074" => aux_tx_data <= x"0A"; aux_tx_wr_en <= '1';

            -- Write Link Downspread
            when x"080" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"081" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"082" => aux_tx_data <= x"07"; aux_tx_wr_en <= '1';
            when x"083" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"084" => aux_tx_data <= x"10"; aux_tx_wr_en <= '1';

            -- Set link count 1
            when x"090" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"091" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"092" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"093" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"094" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';  -- Standard framing, one channel

            -- Set link count 2
            when x"0A0" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"0A1" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0A2" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0A3" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"0A4" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';

            -- Set link count 4
            when x"0B0" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"0B1" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0B2" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0B3" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"0B4" => aux_tx_data <= x"04"; aux_tx_wr_en <= '1';

            -- Set training pattern 1
            when x"0C0" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"0C1" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0C2" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"0C3" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"0C4" => aux_tx_data <= x"21"; aux_tx_wr_en <= '1';

            -- Read link status for all four lanes 
            when x"0D0" => aux_tx_data <= x"90"; aux_tx_wr_en <= '1';
            when x"0D1" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"0D2" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"0D3" => aux_tx_data <= x"07"; aux_tx_wr_en <= '1';

            --  Read the Adjust_Request registers
            when x"0E0" => aux_tx_data <= x"90"; aux_tx_wr_en <= '1';
            when x"0E1" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"0E2" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';
            when x"0E3" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';

            -- Set training pattern 2
            when x"0F0" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"0F1" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"0F2" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"0F3" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"0F4" => aux_tx_data <= x"22"; aux_tx_wr_en <= '1';

            -- Resd lane align status for all four lanes 
            when x"100" => aux_tx_data <= x"90"; aux_tx_wr_en <= '1';
            when x"101" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"102" => aux_tx_data <= x"04"; aux_tx_wr_en <= '1';
            when x"103" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';

            -- Turn off training patterns / Switch to normal
            when x"110" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"111" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"112" => aux_tx_data <= x"02"; aux_tx_wr_en <= '1';
            when x"113" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"114" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';  -- Scrambler enabled

            -- Set Premp level 0, votage 0.4V
            when x"140" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"141" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"142" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"143" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"144" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"145" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"146" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';
            when x"147" => aux_tx_data <= x"00"; aux_tx_wr_en <= '1';

            -- Set Premp level 0, votage 0.6V
            when x"160" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"161" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"162" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"163" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"164" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"165" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"166" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"167" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';

            -- Set Premp level 0, votage 0.8V  -- Max voltage
            when x"180" => aux_tx_data <= x"80"; aux_tx_wr_en <= '1';
            when x"181" => aux_tx_data <= x"01"; aux_tx_wr_en <= '1';
            when x"182" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"183" => aux_tx_data <= x"03"; aux_tx_wr_en <= '1';
            when x"184" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';
            when x"185" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';
            when x"186" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';
            when x"187" => aux_tx_data <= x"06"; aux_tx_wr_en <= '1';                
            when others => aux_tx_data <= x"00"; aux_tx_wr_en <= '0';
         end case;

         ----------------------------
         -- Move on to the next word?
         ----------------------------
         if counter(3 downto 0) = x"F" then
            busy <= '0';
         else
            counter <= counter+1;
         end if;

         ----------------------------------------
         -- Are we being asked to send a message?
         --
         -- But only do it of we are not already
         -- sending something!
         ----------------------------------------
         if msg_de = '1' and counter(3 downto 0) = x"F" then
            counter <= unsigned(msg & x"0");
            busy <= '1';
         end if;

      end if;
   end process;

end architecture;