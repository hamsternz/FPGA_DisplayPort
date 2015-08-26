----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.08.2015 20:19:52
-- Design Name: 
-- Module Name: pixel_x4_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- NOTE FOR THIS TO WORK CORRECTLY h_visible_en, h_blank_len, h_front_len & h_sync_len 
-- MUST BE DIVISIBLE BY 4!!!!!
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_x4_generator is
    port (
        clk_135            : in  std_logic;
    
        pixel_rate_div_10k : in  std_logic(15 downto 0); -- 0 to 643.5 MHz rates
    
        h_visible_len : in  std_logic(11 downto 0);
        h_blank_len   : in  std_logic(11 downto 0);
        h_front_len   : in  std_logic(11 downto 0);
        h_sync_len    : in  std_logic(11 downto 0);
        
        v_visible_len : in  std_logic(11 downto 0);
        v_blank_len   : in  std_logic(11 downto 0);
        v_front_len   : in  std_logic(11 downto 0);
        v_sync_len    : in  std_logic(11 downto 0);
        -----------------------------------------------
        px_de    : out std_logic;
        px_blank : out std_logic;
        px_vsync : out std_logic;
        px_hsync : out std_logic;
    
        p0_Cb    : out std_logic(7 downto 0);	
        p0_Y     : out std_logic(7 downto 0);	
    
        p1_Cr    : out std_logic(7 downto 0);	
        p1_Y     : out std_logic(7 downto 0);	
    
        p2_Cb    : out std_logic(7 downto 0);	
        p2_Y     : out std_logic(7 downto 0);	
        p2_blue  : out std_logic(7 downto 0);	
    
        p2_Cr    : out std_logic(7 downto 0);	
        p2_Y     : out std_logic(7 downto 0));
end entity;	

architecture arch of pixel_x4_generator is

    signal h_count_0      : unsigned(11 downto 0) := (others => '0');
    signal h_counter      : unsigned(11 downto 0) := (others => '0');
    signal v_counter      : unsigned(11 downto 0) := (others => '0');

    signal v_sync         : std_logic := '0';
    signal v_blank        : std_logic := '0';
    signal new_pixels     : std_logic := '0';

    signal phase_accumulator : unsigned(18 downto 0) := (others => '0');	
begin

clk_proc: process(clk_135) 
	begin
		if rising_edge(clk_135) then
		    h_total <= h_visible_len - h_blank_len;

		    -------------------------------------
		    -- Generate new pixels
		    -------------------------------------
		    px_de <= '0';
		    if new_pixels = '1' then
		       px_de <= '1';
		 	   -----------------
			   -- For all pixels
			   -----------------
		       -- Are we in the horizontal sync?
			   if h_count_0 >= h_front_len and h_count_0 < h_front_len+h_sync_len then
			       px_hsync <= '1';
			   else
			       px_hsync <= '0';
			   end if;

		       -- Are we in the horizontal blank?
			   px_blank <= '0';
		       if h_count_0 <  h_blank_len then
			       px_blank <= '1';
		       end if;

		       -- Are we in the vertical blank?
		       if v_count_0 <  v_blank_len then
			       px_blank <= '1';
		       end if;

		       -- Are we in the vertical sync?
    		   if v_count_0 > v_front_len or v_counter < v_front_len+v_sync_len then
    		       px_vsync <= '1';
    		   else
    		       px_vsync <= '0';
    		   end if;

			   -------------------
               -- Per pixel levels
			   -------------------
			   if h_count_0 < h_blank_len then
			       p0_cb     <= x"80";
			       p1_cb     <= x"80";
			       p2_cb     <= x"80";
			       p3_cb     <= x"80";
			       p0_y      <= x"10";
			       p1_y      <= x"10";
			       p2_y      <= x"10";
			       p3_y      <= x"10";
			   else
			       p0_cb     <= x"80";
			       p1_cb     <= x"80";
			       p2_cb     <= x"80";
			       p3_cb     <= x"80";
			       p0_y      <= std_logic_vector(h_count_0(7 downto 0));
			       p1_y      <= std_logic_vector(h_count_0(7 downto 0));
			       p2_y      <= std_logic_vector(h_count_0(7 downto 0));
			       p3_y      <= std_logic_vector(h_count_0(7 downto 0));
			   end if;
		   end if;

		   ---------------------------------------------
  		   -- Advance the counters and trigger the 
		   -- generation of four new pixels
  		   --------------------------------------------- 
		   if generate_pixels = '1' then
			 new_pixels <= '1';
	   	     h_count_0  <= h_counter;
	   	     v_count_0  <= v_counter;

		     if h_counter >= h_blank_len+h_visible_len-4 then
		       h_counter <= (others => '0');
			   if v_counter = v_blank_len + v_visible_len then
			      v_counter <= (others => '0');
			   else
		          v_counter <= v_counter + 1;
			   end if;
		     else
		       h_counter <= h_counter+4;
		     end if;
           else
			 new_pixels <= '0';
		   end if;

		   --------------------------------------------------
		   -- Generate a pulse at 1/4th the pixel clock rate
		   -- but in the clk_135 domain.
		   --------------------------------------------------
		   if phase_accumulator < pixel_rate_div_10k then
		      phase_accumulator <= phase_accumulator + (13500*4) - pixel_rate_div_10k;
			  generate_pixels   <= '1';
		   else
		      phase_accumulator <= phase_accumulator - pixel_rate_div_10k;
			  generate_pixels   <= '0';
		   end if;
		end if;
	end process;
end architecture;