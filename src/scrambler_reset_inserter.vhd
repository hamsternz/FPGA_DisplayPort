----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz< 
-- 
-- Module Name: scrambler - Behavioral
--
-- Description: Implements the Display Dort scrambler
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity scrambler_reset_inserter is
        port ( 
            clk        : in  std_logic;
            in_data0   : in  std_logic_vector(7 downto 0);
            in_data0k  : in  std_logic;
            in_data1   : in  std_logic_vector(7 downto 0);
            in_data1k  : in  std_logic;
            out_data0  : out std_logic_vector(7 downto 0);
            out_data0k : out std_logic;
            out_data1  : out std_logic_vector(7 downto 0);
            out_data1k : out std_logic
        );
end entity;

architecture arch of scrambler_reset_inserter is
    signal   bs_count : unsigned(8 downto 0) := (others => '0');
    constant BS       : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR       : std_logic_vector(8 downto 0) := "100011100";   -- K28.0
begin

process(clk)
    begin
        if rising_edge(clk) then
            out_data0k <= in_data0k;
            out_data0  <= in_data0;
            
            out_data1k <= in_data1k;
            out_data1  <= in_data1;

            ------------------------------------------------
            -- Subsitute every 513nd Blank start (BS) symbol
            -- with a Scrambler Reset (SR) symbol. 
            ------------------------------------------------
            if in_data0k = '1' and in_data0 = BS(7 downto 0) then
                if bs_count = 511 then
                    out_data0 <= SR(7 downto 0);
                end if;
                bs_count <= bs_count + 1;
            end if;

            if in_data1k = '1' and in_data1 = BS(7 downto 0) then
                if bs_count = 511 then
                    out_data1 <= SR(7 downto 0);
                end if;
                bs_count <= bs_count + 1;
            end if;
        end if;
    end process;
end architecture;