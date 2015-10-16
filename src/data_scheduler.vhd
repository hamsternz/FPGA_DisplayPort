----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:23:55 10/11/2015 
-- Design Name: 
-- Module Name:    data_scheduler - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_scheduler is
    Port ( clk                     : in  STD_LOGIC;
           toggle_on_end_of_hblank : in  STD_LOGIC;
           pixel_count             : in  STD_LOGIC_VECTOR (11 downto 0);
           lanes_in_use            : in  STD_LOGIC_VECTOR (2 downto 0);
           RGB_nYCC                : in  STD_LOGIC;
           hblank_or_vblank        : in  STD_LOGIC;
           pix_per_ms              : in  STD_LOGIC_VECTOR (19 downto 0);
           ------
           out0_BE      : out  STD_LOGIC;
           out0_PixData : out  STD_LOGIC;
           out0_FS      : out  STD_LOGIC;
           out0_FE      : out  STD_LOGIC;
           out0_BS      : out  STD_LOGIC;
           ----
           out1_BE      : out  STD_LOGIC;
           out1_PixData : out  STD_LOGIC;
           out1_FS      : out  STD_LOGIC;
           out1_FE      : out  STD_LOGIC;
           out1_BS      : out  STD_LOGIC);
end data_scheduler;

architecture Behavioral of data_scheduler is
   -- How many 135MHz cycles have been seen this line
   signal counter : unsigned(12 downto 0);
   
   constant cZo : std_logic_vector(2 downto 0) := "000";
   constant cBE : std_logic_vector(2 downto 0) := "001";
   constant cPD : std_logic_vector(2 downto 0) := "010";
   constant cFS : std_logic_vector(2 downto 0) := "011";
   constant cFE : std_logic_vector(2 downto 0) := "100";
   constant cBS : std_logic_vector(2 downto 0) := "101";
   
--  schedule :=
--   -- 1 & 0,   3 & 2,   5 & 4,   7 & 6,   9 & 8, 11 & 10, 13 & 12, 15 & 14, 17 & 16, 19 & 18, 21 & 20, 23 & 22, 25 & 24, 27 & 26, 29 & 28, 31 & 30, 33 & 32, 35 & 34, 37 & 36, 39 & 38, 41 & 40, 43 & 42, 45 & 44, 47 & 46, 49 & 48, 51 & 10, 53 & 52, 55 & 54, 57 & 56, 59 & 58, 61 & 60, 63 & 62,
--      cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cZo&cZo, cBE&cZo,
      
begin

process(clk) 
   begin
      if rising_edge(clk) then
         if toggle_on_end_of_hblank_synced /= toggle_on_end_of_hblank_synced_last then
            counter <= 0;
            active_period <= '1';
         else
            counter <= counter + 1;
         end if;
      end if;
   end process;

end Behavioral;

