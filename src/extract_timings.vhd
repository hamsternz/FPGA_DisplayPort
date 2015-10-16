----------------------------------------------------------------------------------
-- Module Name: extract_timings.vhd - Behavioral
--
-- Description: Extract the timing constants from a VGA style 800x600 signal
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

entity extract_timings is
    Port ( pixel_clk     : in  STD_LOGIC;
           pixel_hblank  : in  STD_LOGIC;
           pixel_hsync   : in  STD_LOGIC;
           pixel_vblank  : in  STD_LOGIC;
           pixel_vsync   : in  STD_LOGIC;
           
           --------------------------------------------------
           -- These should be stable when ready is asserted
           --------------------------------------------------
           ready               : out std_logic := '0';
           h_visible           : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           v_visible           : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           h_total             : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           v_total             : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           h_sync_width        : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           v_sync_width        : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           h_start             : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           v_start             : out STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
           h_sync_active_high  : out std_logic := '0';
           v_sync_active_high  : out std_logic := '0');
end extract_timings;

architecture Behavioral of extract_timings is
   signal h_count            : unsigned(12 downto 0)  := (others => '0');
   signal h_sync_start_count : unsigned(12 downto 0)  := (others => '0');
   signal v_count            : unsigned(12 downto 0)  := (others => '0');
   signal v_sync_start_count : unsigned(12 downto 0)  := (others => '0');

   signal h_sync_width_i     : unsigned(12 downto 0)  := (others => '0');
   signal v_sync_width_i     : unsigned(12 downto 0)  := (others => '0');
   signal h_start_i          : unsigned(12 downto 0)  := (others => '0');
   signal v_start_i          : unsigned(12 downto 0)  := (others => '0');

   signal h_total_i          : unsigned(12 downto 0)  := (others => '0');
   signal v_total_i          : unsigned(12 downto 0)  := (others => '0');
   signal h_visible_i        : unsigned(12 downto 0)  := (others => '0');
   signal v_visible_i        : unsigned(12 downto 0)  := (others => '0');

   signal h_sync_when_active_i : std_logic := '0';
   signal v_sync_when_active_i : std_logic := '0';

   
   signal pc_hblank_last           : std_logic := '0';
   signal pc_hsync_last            : std_logic := '0';
   signal pc_line_start_toggle     : std_logic := '0';
   signal pc_vblank_last           : std_logic := '0';
   signal pc_vsync_last            : std_logic := '0';
   signal seen_enough              : unsigned(1 downto 0);
   
begin
   h_visible           <= std_logic_vector(h_visible_i);
   v_visible           <= std_logic_vector(v_visible_i);
   h_total             <= std_logic_vector(h_total_i);
   v_total             <= std_logic_vector(v_total_i);
   h_sync_width        <= std_logic_vector(h_sync_width_i);
   v_sync_width        <= std_logic_vector(v_sync_width_i);
   h_start             <= std_logic_vector(h_start_i);
   v_start             <= std_logic_vector(v_start_i);
   h_sync_active_high  <= h_sync_when_active_i;
   v_sync_active_high  <= v_sync_when_active_i;
              
process(pixel_clk)
   begin
      if rising_edge(pixel_clk) then
         --------------------------------------------------
         -- Counting the number of width and lines 
         -- of the input screen and other screen attributes
         --------------------------------------------------
         if pixel_hblank = '1' and pc_hblank_last = '0' then
            if h_visible_i /= h_count then
               seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
            end if;
            h_visible_i <= h_count;
            -------------------------------------------
            -- Remember the hsync state when the active 
            -- pixels end, this can be used to detect 
            -- an active high or active low hsync pulse
            -------------------------------------------
            h_sync_when_active_i <= not pixel_hsync;
         end if;
         
         ----------------------------------
         -- Start counting hsync and hstart 
         -- when the hsync signal becomes active
         ----------------------------------
         if pixel_hsync = h_sync_when_active_i and pc_hsync_last = not h_sync_when_active_i then
            h_sync_start_count <= (0 => '1', others => '0');
         else
            h_sync_start_count <= h_sync_start_count + 1;
         end if;
         
         -------------------------------------------------------
         -- Capture the hsync width on the change of hsync signal
         -------------------------------------------------------
         if pixel_hsync = not h_sync_when_active_i and pc_hsync_last = h_sync_when_active_i then
            if h_sync_width_i /= h_sync_start_count then
               seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
            end if;
            h_sync_width_i <= h_sync_start_count;
         end if;
            
         ----------------------------------------------------------
         -- Cycles from start of sync to start of active pixel data
         ----------------------------------------------------------
         if pixel_hblank = '0' and pc_hblank_last = '1' then
            if h_start_i /= h_sync_start_count then
               seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
            end if;
            h_start_i <= h_sync_start_count;
         end if;
        
         -------------------------------------------
         -- Capture the visible and total line width
         -------------------------------------=-----
         if pixel_hblank = '0' and pc_hblank_last = '1' then
            -- Capture the horizontal width
            if h_total_i /= h_count then
               seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
            end if;
            h_total_i <= h_count;
         end if;

         if pixel_hblank = '0' and pc_hblank_last = '1' then
            h_count    <= (others => '0');
            h_count(0) <= '1';
         else
            h_count <= h_count + 1;
         end if;

         ----------------------------------
         -- Now for the vertical timings. Count
         -- from when the first pixel (where hblank
         -- is and vblank are both zero).
         ----------------------------------
         if pixel_hblank = '0' and pc_hblank_last = '1' then

            ----------------------------------
            -- Start counting vsync and vstart 
            -- when the vsync signal becomes active
            ----------------------------------
            if pixel_vsync = v_sync_when_active_i and pc_vsync_last = not v_sync_when_active_i then
               v_sync_start_count <= (0 => '1', others => '0');
            else
               v_sync_start_count <= v_sync_start_count + 1;
            end if;

            
            if pixel_vsync = not v_sync_when_active_i and pc_vsync_last = v_sync_when_active_i then
               if v_sync_width_i /= v_sync_start_count  then
                  seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
               end if;
               v_sync_width_i <= v_sync_start_count;
            end if;
         
            if pc_vblank_last = '1' and pixel_vblank = '0' then
               if v_start_i /= v_sync_start_count  then
                  seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
               end if;
               v_start_i <= v_sync_start_count;
            end if;

            ----------------------------------------------
            -- Count the visible lines on the screen
            ----------------------------------------------
            if pixel_vblank = '1' and pc_vblank_last = '0' then
               if v_visible_i /= v_count then
                  seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
               end if;
               v_visible_i <= v_count;
               v_sync_when_active_i <= not pixel_vsync;
            end if;
         
            ----------------------------------------------
            -- Finally count the total lines on the screen
            ----------------------------------------------
            if pixel_vblank = '0' and pc_vblank_last = '1' then
               if v_total_i /= v_count then
                  seen_enough <= (others => '0');  -- unstable or must be changing video resolutions??
               end if;
               v_total_i <= v_count;
            end if;
            
            ---------------------------------
            -- See if things have been stable
            -- throughthe entire frame
            ---------------------------------
            if pixel_vblank = '0' and pc_vblank_last = '1' then
               if seen_enough < 2 then
                  seen_enough <= seen_enough + 1;            
               end if;
            end if;

            --------------------------
            -- Advance the row counter
            --------------------------
            if pixel_vblank = '0' and pc_vblank_last = '1' then
               v_count <= (0=>'1', others => '0');
            else
               v_count <= v_count + 1;
            end if;
            
            pc_vblank_last <= pixel_vblank;
            pc_vsync_last  <= pixel_vsync;
         end if;



         pc_hblank_last   <= pixel_hblank;
         pc_hsync_last    <= pixel_hsync;
         
         --------------------------------------------------
         -- We have to see two frames with identical is 
         -- timings before we declare that the source ready
         --------------------------------------------------
         if seen_enough = 2 then
            ready <= '1';
         else
            ready <= '0';
         end if;
      end if;
   end process;
end Behavioral;

