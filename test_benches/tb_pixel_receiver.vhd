--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:15:58 10/12/2015
-- Design Name:   
-- Module Name:   C:/repos/HDMI2USB-numato-opsis-sample-code/video/displayport/output/tb_pixel_receiver.vhd
-- Project Name:  displayport_out
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pixel_receiver
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
 
ENTITY tb_pixel_receiver IS
END tb_pixel_receiver;
 
ARCHITECTURE behavior OF tb_pixel_receiver IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pixel_receiver
    PORT(
         pixel_clk : IN  std_logic;
         pixel_data : IN  std_logic_vector(23 downto 0);
         pixel_hblank : IN  std_logic;
         pixel_hsync : IN  std_logic;
         pixel_vblank : IN  std_logic;
         pixel_vsync : IN  std_logic;
         ready : OUT  std_logic;
         h_visible : OUT  std_logic_vector(12 downto 0);
         v_visible : OUT  std_logic_vector(12 downto 0);
         h_total : OUT  std_logic_vector(12 downto 0);
         v_total : OUT  std_logic_vector(12 downto 0);
         h_sync_wdith : OUT  std_logic_vector(12 downto 0);
         v_sync_width : OUT  std_logic_vector(12 downto 0);
         h_start : OUT  std_logic_vector(12 downto 0);
         v_start : OUT  std_logic_vector(12 downto 0);
         h_sync_active_high : IN  std_logic;
         v_sync_active_high : IN  std_logic;
         dp_clk : IN  std_logic;
         dp_ch0_data : OUT  std_logic_vector(8 downto 0);
         dp_ch1_data : OUT  std_logic_vector(8 downto 0);
         dp_ch2_data : OUT  std_logic_vector(8 downto 0);
         dp_ch3_data : OUT  std_logic_vector(8 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal pixel_clk : std_logic := '0';
   signal pixel_data : std_logic_vector(23 downto 0) := (others => '0');
   signal pixel_hblank : std_logic := '0';
   signal pixel_hsync : std_logic := '0';
   signal pixel_vblank : std_logic := '0';
   signal pixel_vsync : std_logic := '0';
   signal h_sync_active_high : std_logic := '0';
   signal v_sync_active_high : std_logic := '0';
   signal dp_clk : std_logic := '0';

 	--Outputs
   signal ready : std_logic;
   signal h_visible : std_logic_vector(12 downto 0);
   signal v_visible : std_logic_vector(12 downto 0);
   signal h_total : std_logic_vector(12 downto 0);
   signal v_total : std_logic_vector(12 downto 0);
   signal h_sync_wdith : std_logic_vector(12 downto 0);
   signal v_sync_width : std_logic_vector(12 downto 0);
   signal h_start : std_logic_vector(12 downto 0);
   signal v_start : std_logic_vector(12 downto 0);
   signal dp_ch0_data : std_logic_vector(8 downto 0);
   signal dp_ch1_data : std_logic_vector(8 downto 0);
   signal dp_ch2_data : std_logic_vector(8 downto 0);
   signal dp_ch3_data : std_logic_vector(8 downto 0);

   -- Clock period definitions
   constant pixel_clk_period : time := 25 ns;
   constant dp_clk_period    : time := 3.7 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pixel_receiver PORT MAP (
          pixel_clk => pixel_clk,
          pixel_data => pixel_data,
          pixel_hblank => pixel_hblank,
          pixel_hsync => pixel_hsync,
          pixel_vblank => pixel_vblank,
          pixel_vsync => pixel_vsync,
          ready => ready,
          h_visible => h_visible,
          v_visible => v_visible,
          h_total => h_total,
          v_total => v_total,
          h_sync_wdith => h_sync_wdith,
          v_sync_width => v_sync_width,
          h_start => h_start,
          v_start => v_start,
          h_sync_active_high => h_sync_active_high,
          v_sync_active_high => v_sync_active_high,
          dp_clk => dp_clk,
          dp_ch0_data => dp_ch0_data,
          dp_ch1_data => dp_ch1_data,
          dp_ch2_data => dp_ch2_data,
          dp_ch3_data => dp_ch3_data
        );

   -- Clock process definitions
   pixel_clk_process :process
   begin
		pixel_clk <= '0';
		wait for pixel_clk_period/2;
		pixel_clk <= '1';
		wait for pixel_clk_period/2;
   end process;
 
   dp_clk_process :process
   begin
		dp_clk <= '0';
		wait for dp_clk_period/2;
		dp_clk <= '1';
		wait for dp_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for pixel_clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
