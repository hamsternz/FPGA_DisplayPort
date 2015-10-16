--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:05:06 10/15/2015
-- Design Name:   
-- Module Name:   C:/repos/HDMI2USB-numato-opsis-sample-code/video/displayport/output/tb_800x600_compare.vhd
-- Project Name:  displayport_out
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: test_source_800_600_RGB_444_colourbars_ch1
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_800x600_compare IS
END tb_800x600_compare;
 
ARCHITECTURE behavior OF tb_800x600_compare IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT test_source_800_600_RGB_444_colourbars_ch1
    PORT(
         M_value : OUT  std_logic_vector(23 downto 0);
         N_value : OUT  std_logic_vector(23 downto 0);
         H_visible : OUT  std_logic_vector(11 downto 0);
         V_visible : OUT  std_logic_vector(11 downto 0);
         H_total : OUT  std_logic_vector(11 downto 0);
         V_total : OUT  std_logic_vector(11 downto 0);
         H_sync_width : OUT  std_logic_vector(11 downto 0);
         V_sync_width : OUT  std_logic_vector(11 downto 0);
         H_start : OUT  std_logic_vector(11 downto 0);
         V_start : OUT  std_logic_vector(11 downto 0);
         H_vsync_active_high : OUT  std_logic;
         V_vsync_active_high : OUT  std_logic;
         flag_sync_clock : OUT  std_logic;
         flag_YCCnRGB : OUT  std_logic;
         flag_422n444 : OUT  std_logic;
         flag_YCC_colour_709 : OUT  std_logic;
         flag_range_reduced : OUT  std_logic;
         flag_interlaced_even : OUT  std_logic;
         flags_3d_Indicators : OUT  std_logic_vector(1 downto 0);
         bits_per_colour : OUT  std_logic_vector(4 downto 0);
         stream_channel_count : OUT  std_logic_vector(2 downto 0);
         clk : IN  std_logic;
         ready : OUT  std_logic;
         data : OUT  std_logic_vector(72 downto 0)
        );
    END COMPONENT;
    
    COMPONENT test_source_800_600_RGB_444_ch1
    PORT(
         M_value : OUT  std_logic_vector(23 downto 0);
         N_value : OUT  std_logic_vector(23 downto 0);
         H_visible : OUT  std_logic_vector(11 downto 0);
         V_visible : OUT  std_logic_vector(11 downto 0);
         H_total : OUT  std_logic_vector(11 downto 0);
         V_total : OUT  std_logic_vector(11 downto 0);
         H_sync_width : OUT  std_logic_vector(11 downto 0);
         V_sync_width : OUT  std_logic_vector(11 downto 0);
         H_start : OUT  std_logic_vector(11 downto 0);
         V_start : OUT  std_logic_vector(11 downto 0);
         H_vsync_active_high : OUT  std_logic;
         V_vsync_active_high : OUT  std_logic;
         flag_sync_clock : OUT  std_logic;
         flag_YCCnRGB : OUT  std_logic;
         flag_422n444 : OUT  std_logic;
         flag_YCC_colour_709 : OUT  std_logic;
         flag_range_reduced : OUT  std_logic;
         flag_interlaced_even : OUT  std_logic;
         flags_3d_Indicators : OUT  std_logic_vector(1 downto 0);
         bits_per_colour : OUT  std_logic_vector(4 downto 0);
         stream_channel_count : OUT  std_logic_vector(2 downto 0);
         clk : IN  std_logic;
         ready : OUT  std_logic;
         data : OUT  std_logic_vector(72 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';

 	--Outputs
   signal a_M_value : std_logic_vector(23 downto 0);
   signal a_N_value : std_logic_vector(23 downto 0);
   signal a_H_visible : std_logic_vector(11 downto 0);
   signal a_V_visible : std_logic_vector(11 downto 0);
   signal a_H_total : std_logic_vector(11 downto 0);
   signal a_V_total : std_logic_vector(11 downto 0);
   signal a_H_sync_width : std_logic_vector(11 downto 0);
   signal a_V_sync_width : std_logic_vector(11 downto 0);
   signal a_H_start : std_logic_vector(11 downto 0);
   signal a_V_start : std_logic_vector(11 downto 0);
   signal a_H_vsync_active_high : std_logic;
   signal a_V_vsync_active_high : std_logic;
   signal a_flag_sync_clock : std_logic;
   signal a_flag_YCCnRGB : std_logic;
   signal a_flag_422n444 : std_logic;
   signal a_flag_YCC_colour_709 : std_logic;
   signal a_flag_range_reduced : std_logic;
   signal a_flag_interlaced_even : std_logic;
   signal a_flags_3d_Indicators : std_logic_vector(1 downto 0);
   signal a_bits_per_colour : std_logic_vector(4 downto 0);
   signal a_stream_channel_count : std_logic_vector(2 downto 0);
   signal a_ready : std_logic;
   signal a_data : std_logic_vector(72 downto 0);

   signal b_M_value : std_logic_vector(23 downto 0);
   signal b_N_value : std_logic_vector(23 downto 0);
   signal b_H_visible : std_logic_vector(11 downto 0);
   signal b_V_visible : std_logic_vector(11 downto 0);
   signal b_H_total : std_logic_vector(11 downto 0);
   signal b_V_total : std_logic_vector(11 downto 0);
   signal b_H_sync_width : std_logic_vector(11 downto 0);
   signal b_V_sync_width : std_logic_vector(11 downto 0);
   signal b_H_start : std_logic_vector(11 downto 0);
   signal b_V_start : std_logic_vector(11 downto 0);
   signal b_H_vsync_active_high : std_logic;
   signal b_V_vsync_active_high : std_logic;
   signal b_flag_sync_clock : std_logic;
   signal b_flag_YCCnRGB : std_logic;
   signal b_flag_422n444 : std_logic;
   signal b_flag_YCC_colour_709 : std_logic;
   signal b_flag_range_reduced : std_logic;
   signal b_flag_interlaced_even : std_logic;
   signal b_flags_3d_Indicators : std_logic_vector(1 downto 0);
   signal b_bits_per_colour : std_logic_vector(4 downto 0);
   signal b_stream_channel_count : std_logic_vector(2 downto 0);
   signal b_ready : std_logic;
   signal b_data : std_logic_vector(72 downto 0);

   signal d_M_value : std_logic_vector(23 downto 0);
   signal d_N_value : std_logic_vector(23 downto 0);
   signal d_H_visible : std_logic_vector(11 downto 0);
   signal d_V_visible : std_logic_vector(11 downto 0);
   signal d_H_total : std_logic_vector(11 downto 0);
   signal d_V_total : std_logic_vector(11 downto 0);
   signal d_H_sync_width : std_logic_vector(11 downto 0);
   signal d_V_sync_width : std_logic_vector(11 downto 0);
   signal d_H_start : std_logic_vector(11 downto 0);
   signal d_V_start : std_logic_vector(11 downto 0);
   signal d_H_vsync_active_high : std_logic;
   signal d_V_vsync_active_high : std_logic;
   signal d_flag_sync_clock : std_logic;
   signal d_flag_YCCnRGB : std_logic;
   signal d_flag_422n444 : std_logic;
   signal d_flag_YCC_colour_709 : std_logic;
   signal d_flag_range_reduced : std_logic;
   signal d_flag_interlaced_even : std_logic;
   signal d_flags_3d_Indicators : std_logic_vector(1 downto 0);
   signal d_bits_per_colour : std_logic_vector(4 downto 0);
   signal d_stream_channel_count : std_logic_vector(2 downto 0);
   signal d_ready : std_logic;
   signal d_data : std_logic_vector(72 downto 0);

   -- Clock period definitions
   constant flag_sync_clock_period : time := 10 ns;
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
uut1: test_source_800_600_RGB_444_colourbars_ch1 PORT MAP (
          M_value => a_M_value,
          N_value => a_N_value,
          H_visible => a_H_visible,
          V_visible => a_V_visible,
          H_total => a_H_total,
          V_total => a_V_total,
          H_sync_width => a_H_sync_width,
          V_sync_width => a_V_sync_width,
          H_start => a_H_start,
          V_start => a_V_start,
          H_vsync_active_high => a_H_vsync_active_high,
          V_vsync_active_high => a_V_vsync_active_high,
          flag_sync_clock => a_flag_sync_clock,
          flag_YCCnRGB => a_flag_YCCnRGB,
          flag_422n444 => a_flag_422n444,
          flag_YCC_colour_709 => a_flag_YCC_colour_709,
          flag_range_reduced => a_flag_range_reduced,
          flag_interlaced_even => a_flag_interlaced_even,
          flags_3d_Indicators => a_flags_3d_Indicators,
          bits_per_colour => a_bits_per_colour,
          stream_channel_count => a_stream_channel_count,
          clk => clk,
          ready => a_ready,
          data => a_data
        );
uut2: test_source_800_600_RGB_444_ch1 PORT MAP (
          M_value => b_M_value,
          N_value => b_N_value,
          H_visible => b_H_visible,
          V_visible => b_V_visible,
          H_total => b_H_total,
          V_total => b_V_total,
          H_sync_width => b_H_sync_width,
          V_sync_width => b_V_sync_width,
          H_start => b_H_start,
          V_start => b_V_start,
          H_vsync_active_high => b_H_vsync_active_high,
          V_vsync_active_high => b_V_vsync_active_high,
          flag_sync_clock => b_flag_sync_clock,
          flag_YCCnRGB => b_flag_YCCnRGB,
          flag_422n444 => b_flag_422n444,
          flag_YCC_colour_709 => b_flag_YCC_colour_709,
          flag_range_reduced => b_flag_range_reduced,
          flag_interlaced_even => b_flag_interlaced_even,
          flags_3d_Indicators => b_flags_3d_Indicators,
          bits_per_colour => b_bits_per_colour,
          stream_channel_count => b_stream_channel_count,
          clk => clk,
          ready => b_ready,
          data => b_data
        );


   d_M_value <= a_M_value xor b_M_value;
   d_N_value <= a_N_value xor b_N_value;
   d_H_visible <= a_H_visible xor b_H_visible;
   d_V_visible <= a_V_visible xor b_V_visible;
   d_H_total <= a_H_total xor b_H_total;
   d_V_total <= a_V_total xor b_V_total;
   d_H_sync_width <= a_H_sync_width xor b_H_sync_width;
   d_V_sync_width <= a_V_sync_width xor b_V_sync_width;
   d_H_start <= a_H_start xor b_H_start;
   d_V_start <= a_V_start xor b_V_start;
   d_H_vsync_active_high <= a_H_vsync_active_high xor b_H_vsync_active_high;
   d_V_vsync_active_high <= a_V_vsync_active_high xor b_V_vsync_active_high;
   d_flag_sync_clock <= a_flag_sync_clock xor b_flag_sync_clock;
   d_flag_YCCnRGB <= a_flag_YCCnRGB xor b_flag_YCCnRGB;
   d_flag_422n444 <= a_flag_422n444 xor b_flag_422n444;
   d_flag_YCC_colour_709 <= a_flag_YCC_colour_709 xor b_flag_YCC_colour_709;
   d_flag_range_reduced <= a_flag_range_reduced xor b_flag_range_reduced;
   d_flag_interlaced_even <= a_flag_interlaced_even xor b_flag_interlaced_even;
   d_flags_3d_Indicators <= a_flags_3d_Indicators xor b_flags_3d_Indicators;
   d_bits_per_colour <= a_bits_per_colour xor b_bits_per_colour;
   d_stream_channel_count <= a_stream_channel_count xor b_stream_channel_count;
   d_ready <= a_ready xor b_ready;
   d_data <= a_data xor b_data;


   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for flag_sync_clock_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
