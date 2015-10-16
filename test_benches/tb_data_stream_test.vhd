--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:29:05 10/08/2015
-- Design Name:   
-- Module Name:   C:/repos/HDMI2USB-numato-opsis-sample-code/video/displayport/output/tb_data_stream_test.vhd
-- Project Name:  displayport_out
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: data_stream_test
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
 
ENTITY tb_data_stream_test IS
END tb_data_stream_test;
 
ARCHITECTURE behavior OF tb_data_stream_test IS 
 
    COMPONENT data_stream_test
    PORT(
         symbolclk : IN  std_logic;
         symbols : OUT  std_logic_vector(79 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal symbolclk : std_logic := '0';

 	--Outputs
   signal symbol00 : std_logic_vector(9 downto 0);
   signal symbol01 : std_logic_vector(9 downto 0);
   signal symbol10 : std_logic_vector(9 downto 0);
   signal symbol11 : std_logic_vector(9 downto 0);
   signal symbol20 : std_logic_vector(9 downto 0);
   signal symbol21 : std_logic_vector(9 downto 0);
   signal symbol30 : std_logic_vector(9 downto 0);
   signal symbol31 : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant symbolclk_period : time := 7.4 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: data_stream_test PORT MAP (
          symbolclk => symbolclk,
          symbols( 9 downto  0) => symbol00,
          symbols(19 downto 10) => symbol01,
          symbols(29 downto 20) => symbol10,
          symbols(39 downto 30) => symbol11,
          symbols(49 downto 40) => symbol20,
          symbols(59 downto 50) => symbol21,
          symbols(69 downto 60) => symbol30,
          symbols(79 downto 70) => symbol31
        );

   -- Clock process definitions
   symbolclk_process :process
   begin
		symbolclk <= '0';
		wait for symbolclk_period/2;
		symbolclk <= '1';
		wait for symbolclk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for symbolclk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
