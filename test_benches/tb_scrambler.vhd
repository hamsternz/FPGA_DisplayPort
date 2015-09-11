----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: tb_scrambler - Behavioral
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


entity tb_scrambler is
    Port ( a : in STD_LOGIC);
end tb_scrambler;

architecture Behavioral of tb_scrambler is
    component scrambler is
    Port ( clk        : in  STD_LOGIC;
           bypass0    : in  STD_LOGIC;
           bypass1    : in  STD_LOGIC;

           data0_in   : in  STD_LOGIC_VECTOR (7 downto 0);
           data0k_in  : in  STD_LOGIC;
           data1_in   : in  STD_LOGIC_VECTOR (7 downto 0);
           data1k_in  : in  STD_LOGIC;
           
           data0_out  : out STD_LOGIC_VECTOR (7 downto 0);
           data0k_out : out STD_LOGIC;
           data1_out  : out STD_LOGIC_VECTOR (7 downto 0);
           data1k_out : out STD_LOGIC);
    end component;

    signal clk        : STD_LOGIC := '0';

    singal bypass0    : STD_LOGIC := '0';
    signal data0_in   : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data0k_in  : STD_LOGIC := '0';
    singal bypass1    : STD_LOGIC := '0';
    signal data1_in   : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data1k_in  : STD_LOGIC := '0';
           
    signal data0_out  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data0k_out : STD_LOGIC := '0';
    signal data1_out  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal data1k_out : STD_LOGIC := '0';

begin

process 
    begin
        clk <= '0'; 
        wait for 5 ns;
        clk <= '1'; 
        wait for 5 ns;
    end process;
        
uut: scrambler port map (
       clk        => clk,
       bypass0    => bypass0,
       bypass1    => bypass1,

       data0_in   => data0_in,
       data0k_in  => data0k_in,
       data1_in   => data1_in,
       data1k_in  => data1k_in,
       
       data0_out  => data0_out, 
       data0k_out => data0k_out, 
       data1_out  => data1_out,
       data1k_out => data1k_out);

end Behavioral;
