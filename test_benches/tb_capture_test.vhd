--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:18:41 10/12/2015
-- Design Name:   
-- Module Name:   C:/repos/HDMI2USB-numato-opsis-sample-code/video/displayport/output/tb_capture_test.vhd
-- Project Name:  displayport_out
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: capture_test
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
 
ENTITY tb_capture_test IS
END tb_capture_test;
 
ARCHITECTURE behavior OF tb_capture_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT capture_test
    PORT(
         clk40 : IN  std_logic;
         dp_clk : IN  std_logic;
         dp_ch0_data_0 : OUT  std_logic_vector(8 downto 0);
         dp_ch0_data_1 : OUT  std_logic_vector(8 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk40 : std_logic := '0';
   signal dp_clk : std_logic := '0';

 	--Outputs
   signal dp_ch0_data_0 : std_logic_vector(8 downto 0);
   signal dp_ch0_data_1 : std_logic_vector(8 downto 0);

   -- Clock period definitions
   constant clk40_period  : time := 25 ns;   --  40 MHz
   constant dp_clk_period : time := 3.7 ns;  -- 135 MHz
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: capture_test PORT MAP (
          clk40 => clk40,
          dp_clk => dp_clk,
          dp_ch0_data_0 => dp_ch0_data_0,
          dp_ch0_data_1 => dp_ch0_data_1
        );

   -- Clock process definitions
   clk40_process :process
   begin
		clk40 <= '0';
		wait for clk40_period/2;
		clk40 <= '1';
		wait for clk40_period/2;
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

      wait for clk40_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
