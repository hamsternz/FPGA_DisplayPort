----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.08.2015 20:34:59
-- Design Name: 
-- Module Name: transceiver_clocking - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity transceiver_clocking is
    Port ( refclk0_p    : in STD_LOGIC;
           refclk0_n    : in STD_LOGIC;
           refclk1_p    : in STD_LOGIC;
           refclk1_n    : in STD_LOGIC;
           gtrefclk0    : out STD_LOGIC;
           gtrefclk1    : out STD_LOGIC);
end transceiver_clocking;

architecture Behavioral of transceiver_clocking is
    signal buffered_clk0 : std_logic;
    signal buffered_clk1 : std_logic;
begin

i_buff0: IBUFDS_GTE2 port map (
        I    => refclk0_p,
        IB   => refclk0_n,
        CEB  => '0',
        O    => gtrefclk0
    );

i_buff1: IBUFDS_GTE2 port map (
        I    => refclk1_p,
        IB   => refclk1_n,
        CEB  => '0',
        O    => gtrefclk1
    );
end Behavioral;
