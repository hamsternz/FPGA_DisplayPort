library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_test_source is
end entity;

architecture arch of tb_test_source is
	component test_source is
	    port ( 
	        clk    : in  std_logic;
	        data0  : out std_logic_vector(7 downto 0);
	        data0k : out std_logic;
	        data1  : out std_logic_vector(7 downto 0);
	        data1k : out std_logic
	    );
	end component;
	
	signal clk    : std_logic;
	signal data0  : std_logic_vector(7 downto 0);
    signal data0k : std_logic;
    signal data1  : std_logic_vector(7 downto 0);
    signal data1k : std_logic;

begin
uut: test_source port map ( 
	        clk    => clk,
	        data0  => data0,
	        data0k => data0k,
	        data1  => data1,
	        data1k => data1k
	    );
process 
    begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;
end architecture;
