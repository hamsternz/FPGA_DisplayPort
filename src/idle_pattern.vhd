library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity idle_pattern is
    port ( 
        clk    : in  std_logic;
        data0  : out std_logic_vector(7 downto 0);
        data0k : out std_logic;
        data1  : out std_logic_vector(7 downto 0);
        data1k : out std_logic
    );
end idle_pattern;

architecture arch of idle_pattern is 
    signal count : unsigned(12 downto 0) := (others => '1');    

    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0x3
    constant VB_ID  : std_logic_vector(8 downto 0) := "000001001";   -- 0x00  VB-ID with no video asserted 
	constant Mvid   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    

    signal d0: std_logic_vector(8 downto 0);
    signal d1: std_logic_vector(8 downto 0);

begin
    data0   <= d0(7 downto 0);
    data0k  <= d0(8);
    data1   <= d1(7 downto 0);
    data1k  <= d1(8);

process(clk)
     begin
        if rising_edge(clk) then
            if count = 0 then
                d0 <= BS;
                d1 <= VB_ID;
            elsif count = 2 then
                d0 <= Mvid;
                d1 <= Maud;
            elsif count = 4 then
                d0 <= VB_ID;
                d1 <= Mvid;
            elsif count = 6 then
                d0 <= Maud;
                d1 <= VB_ID;
            elsif count = 8 then
                d0 <= Mvid;
                d1 <= Maud;
            elsif count = 10 then
                d0 <= VB_ID;
                d1 <= Mvid;
            elsif count = 12 then
                d0 <= Maud;
                d1 <= DUMMY;
            else
                d0 <= DUMMY;
                d1 <= DUMMY;
            end if; 
            count <= count + 2;
        end if;
            
     end process;
end architecture;