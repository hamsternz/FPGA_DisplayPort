----------------------------------------------------------------------------------
-- Module Name: insert_main_stream_attrbutes_four_channels.vhd - Behavioral
--
-- Description: Add the Main Stream Attributes into a DisplayPort stream.
--
--              Places the MSA after the first VIB-ID which has the vblank 
--              bit set (after allowing for repeated VB-ID/Mvid/Maud sequences
-- 
--              The MSA requires up to 39 cycles (for signal channel) or
--              Only 12 cycles (for four channels).
--
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
--  0.1 | 2015-10-13 | Initial Version
------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity insert_main_stream_attrbutes_four_channels is
    port (
        clk                  : std_logic;
        -----------------------------------------------------
        -- This determines how the MSA is packed
        -----------------------------------------------------      
        active               : std_logic;
        -----------------------------------------------------
        -- The MSA values (some are range reduced and could 
        -- be 16 bits ins size)
        -----------------------------------------------------      
        M_value              : in std_logic_vector(23 downto 0);
        N_value              : in std_logic_vector(23 downto 0);
        H_visible            : in std_logic_vector(11 downto 0);
        V_visible            : in std_logic_vector(11 downto 0);
        H_total              : in std_logic_vector(11 downto 0);
        V_total              : in std_logic_vector(11 downto 0);
        H_sync_width         : in std_logic_vector(11 downto 0);
        V_sync_width         : in std_logic_vector(11 downto 0);
        H_start              : in std_logic_vector(11 downto 0);
        V_start              : in std_logic_vector(11 downto 0);
        H_vsync_active_high  : in std_logic;
        V_vsync_active_high  : in std_logic;
        flag_sync_clock      : in std_logic;
        flag_YCCnRGB         : in std_logic;
        flag_422n444         : in std_logic;
        flag_range_reduced   : in std_logic;
        flag_interlaced_even : in std_logic;
        flag_YCC_colour_709  : in std_logic;
        flags_3d_Indicators  : in std_logic_vector(1 downto 0);
        bits_per_colour      : in std_logic_vector(4 downto 0);
        -----------------------------------------------------
        -- The stream of pixel data coming in and out
        -----------------------------------------------------
        in_data              : in std_logic_vector(72 downto 0);
        out_data             : out std_logic_vector(72 downto 0) := (others => '0'));
end entity;

architecture arch of insert_main_stream_attrbutes_four_channels is
    constant SS     : std_logic_vector(8 downto 0) := "101011100";   -- K28.2
    constant SE     : std_logic_vector(8 downto 0) := "111111101";   -- K29.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5

    type t_msa is array(0 to 39) of std_logic_vector(8 downto 0);
    signal msa : t_msa := (others => (others => '0'));

    signal Misc0       : std_logic_vector(7 downto 0);
    signal Misc1       : std_logic_vector(7 downto 0);
    
    signal count       : signed(4 downto 0) := (others => '0');

    signal last_was_bs : std_logic := '0';
    signal armed       : std_logic := '0';
begin
    with bits_per_colour select misc0(7 downto 5)<= "000" when "00110",  --  6 bpc
                                                    "001" when "01000",  --  8 bpp
                                                    "010" when "01010",  -- 10 bpp
                                                    "011" when "01100",  -- 12 bpp
                                                    "100" when "10000",  -- 16 bpp 
                                                    "001" when others;   -- default to 8                                     
    misc0(4) <= flag_YCC_colour_709;
    misc0(3) <= flag_range_reduced;
    misc0(2 downto 1) <= "00" when flag_YCCnRGB = '0' else  -- RGB444
                         "01" when flag_422n444 = '1' else  -- YCC422
                         "10";                              -- YCC444
    misc0(0) <= flag_sync_clock;   
    misc1 <= "00000" & flags_3d_Indicators & flag_interlaced_even;
    
    --------------------------------------------
    -- Build data fields for 4 lane case.
    -- SS and SE symbols are set in declaration.
    --------------------------------------------

process(clk) 
    begin
        if rising_edge(clk) then
    	    -- default to copying the input data across
            out_data <= in_data;
  
            case count is
                when "00000" => NULL; -- while waiting for BS symbol
                when "00001" => NULL; -- reserved for VB-ID, Maud, Mvid 
                when "00010" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00011" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00100" => out_data(17 downto  0) <= SS & SS; 
                when "00101" => out_data(17 downto  0) <= "0" & M_value(15 downto 8)            & "0" & M_value(23 downto 16);
                when "00110" => out_data(17 downto  0) <= "0" & "0000" & H_total(11 downto 8)   & "0" & M_value( 7 downto  0);
                when "00111" => out_data(17 downto  0) <= "0" & "0000" & V_total(11 downto 8)   & "0" & H_total( 7 downto 0);
                when "01000" => out_data(17 downto  0) <= "0" & H_vsync_active_high & "000" & H_sync_width(11 downto 8) & "0" & V_total( 7 downto 0);
                when "01001" => out_data(17 downto  0) <= SE                                    & "0" & H_sync_width(7 downto 0);
                when others  => NULL; 
            end case;

            case count is
                when "00000" => NULL; -- while waiting for BS symbol
                when "00001" => NULL; -- reserved for VB-ID, Maud, Mvid 
                when "00010" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00011" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00100" => out_data(35 downto 18) <= SS & SS;
                when "00101" => out_data(35 downto 18) <= "0" & M_value(15 downto 8)            & "0" & M_value(23 downto 16);
                when "00110" => out_data(35 downto 18) <= "0" & "0000" & H_Start(11 downto 8)   & "0" & M_value( 7 downto  0);
                when "00111" => out_data(35 downto 18) <= "0" & "0000" & V_start(11 downto 8)   & "0" & H_start( 7 downto 0);
                when "01000" => out_data(35 downto 18) <= "0" & V_vsync_active_high & "000" & V_sync_width(11 downto 8) & "0" & V_start( 7 downto 0);
                when "01001" => out_data(35 downto 18) <= SE                                    & "0" & V_sync_width(7 downto 0);
                when others  => NULL; 
            end case;
                
            case count is
                when "00000" => NULL; -- while waiting for BS symbol
                when "00001" => NULL; -- reserved for VB-ID, Maud, Mvid 
                when "00010" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00011" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00100" => out_data(53 downto 36) <= SS & SS; 
                when "00101" => out_data(53 downto 36) <= "0" & M_value(15 downto  8)           & "0" & M_value(23 downto 16);
                when "00110" => out_data(53 downto 36) <= "0" & "0000" & H_visible(11 downto 8) & "0" & M_value( 7 downto 0);
                when "00111" => out_data(53 downto 36) <= "0" & "0000" & V_visible(11 downto 8) & "0" & H_visible( 7 downto 0);
                when "01000" => out_data(53 downto 36) <= "0" & "00000000"                      & "0" & V_visible( 7 downto 0);
                when "01001" => out_data(53 downto 36) <= SE                                    & "0" & "00000000";
                when others  => NULL; 
            end case;

            case count is
                when "00000" => NULL; -- while waiting for BS symbol
                when "00001" => NULL; -- reserved for VB-ID, Maud, Mvid 
                when "00010" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00011" => NULL; -- reserved for VB-ID, Maud, Mvid
                when "00100" => out_data(71 downto 54) <= SS & SS;
                when "00101" => out_data(71 downto 54) <= "0" & M_value(15 downto  8)     & "0" & M_value(23 downto 16);
                when "00110" => out_data(71 downto 54) <= "0" & N_value(23 downto 16)     & "0" & M_value( 7 downto 0);
                when "00111" => out_data(71 downto 54) <= "0" & N_value( 7 downto  0)     & "0" & N_value(15 downto  8); 
                when "01000" => out_data(71 downto 54) <= "0" & Misc1                     & "0" & Misc0;
                when "01001" => out_data(71 downto 54) <= SE                              & "0" & "00000000"; 
                when others  => NULL; 
            end case;

            -----------------------------------------------------------
            -- Update the counter
            ------------------------------------------------------------
            if count = "01010" then
                count <= (others => '0');
            elsif count /= "00000" then
                count <= count + 1;
            end if;

            ---------------------------------------------
            -- Was the BS in the channel 0's data1 symbol
            -- during the last cycle? 
            ---------------------------------------------            
            if last_was_bs = '1' then
                ---------------------------------
                -- This time in_ch0_data0 = VB-ID
                -- First, see if this is a line in 
                -- the VSYNC
                ---------------------------------
                if in_data(0) = '1' then
                    if armed = '1' then
                        count <= "00001";
                        armed <= '0';
                    end if;
                else
                    -- Not in the Vblank. so arm the trigger to send the MSA 
                    -- when the next BS with Vblank asserted occurs                      
                    armed <= active;
                end if;
            end if;

            ---------------------------------------------
            -- Is the BS in the channel 0's data0 symbol? 
            ---------------------------------------------
            if in_data(8 downto 0) = BS then
                ---------------------------------
                -- This time in_data(17 downto 9) = VB-ID
                -- First, see if this is a line in 
                -- the VSYNC
                ---------------------------------
                if in_data(9) = '1' then
                    if armed = '1' then
                        count <= "00001";
                        armed <= '0';
                    end if;
                else
                    -- Not in the Vblank. so arm the trigger to send the MSA 
                    -- when the next BS with Vblank asserted occurs                      
                    armed <= '1';
                end if;
            end if;
            
            ---------------------------------------------
            -- Is the BS in the channel 0's data1 symbol? 
            ---------------------------------------------
            if in_data(17 downto 9) = BS then
                last_was_bs <= '1';
            else
                last_was_bs <= '0';               
            end if;
        end if;
    end process;
end architecture;
