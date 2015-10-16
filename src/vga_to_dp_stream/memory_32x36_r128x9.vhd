----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:22:40 10/12/2015 
-- Design Name: 
-- Module Name:    memory_32x36_r128x9 - Behavioral 
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

entity memory_32x36_r128x9 is
    Port ( clk_a  : in  STD_LOGIC;
           addr_a : in  STD_LOGIC_VECTOR (4 downto 0);
           data_a : in  STD_LOGIC_VECTOR (35 downto 0);
           we_a   : in  STD_LOGIC;
           
           clk_bc   : in  STD_LOGIC;
           addr_b : in STD_LOGIC_VECTOR (6 downto 0);
           data_b_0 : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
           data_b_1 : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0'));
end memory_32x36_r128x9;

architecture Behavioral of memory_32x36_r128x9 is
   type a_mem is array(0 to 31) of std_logic_vector(35 downto 0);
   signal mem : a_mem := (others => (others => '0'));
   signal this_b : std_logic_vector(addr_b'high-2 downto 0);
   signal next_b : std_logic_vector(addr_b'high-2 downto 0);
begin
   this_b <= std_logic_vector(unsigned(addr_b(addr_b'high downto 2))+1);
   next_b <= std_logic_vector(unsigned(addr_b(addr_b'high downto 2))+1);
process(clk_a)
   begin
      if rising_edge(clk_a) then
         if we_a = '1' then
            mem(to_integer(unsigned(addr_a))) <= data_a;
         end if;
      end if;
   end process;

process(clk_bc)
   begin
      if rising_edge(clk_bc) then
         case addr_b(1 downto 0) is 
            when "00"   =>  data_b_0 <= mem(to_integer(unsigned(this_b)))( 8 downto  0);
                            data_b_1 <= mem(to_integer(unsigned(this_b)))(17 downto  9);
                            
            when "01"   =>  data_b_0 <= mem(to_integer(unsigned(this_b)))(17 downto  9);
                            data_b_1 <= mem(to_integer(unsigned(this_b)))(26 downto 18);
            
            when others =>  data_b_0 <= mem(to_integer(unsigned(this_b)))(26 downto 18);
                            data_b_1 <= mem(to_integer(unsigned(next_b)))( 8 downto  0);
         end case;
     end if;
   end process;

end Behavioral;

