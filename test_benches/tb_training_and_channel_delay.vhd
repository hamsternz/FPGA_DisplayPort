library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_training_and_channel_delay is
end entity;

architecture tb of tb_training_and_channel_delay is
    component training_and_channel_delay is
    port (
        clk            : in  std_logic;
        channel_delay  : in  std_logic_vector(1 downto 0);
        send_pattern_1 : in  std_logic;
        send_pattern_2 : in  std_logic;
        data_in        : in  std_logic_vector(19 downto 0);
        data_out       : out std_logic_vector(19 downto 0)
    );
    end component;

    signal clk            : std_logic                     := '0';
    signal channel_delay  : std_logic_vector(1 downto 0)  := (others => '0');
    signal send_pattern_1 : std_logic                     := '0';
    signal send_pattern_2 : std_logic                     := '1';
    signal data_in        : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_0     : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_1     : std_logic_vector(19 downto 0) := (others => '0');

begin

clk_proc: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

stim_proc: process
    begin
        for i in 1 to 100 loop
            wait until rising_edge(clk);
        end loop;
        send_pattern_2 <= '0';
        data_in <= x"CCCCC";
        wait until rising_edge(clk);
        data_in <= x"33333";
        
    end process;
    
uut0: training_and_channel_delay port map (
        clk            => clk,
        channel_delay  => "00",
        send_pattern_1 => send_pattern_1,
        send_pattern_2 => send_pattern_2,
        data_in        => data_in,
        data_out       => data_out_0
    );

uut1: training_and_channel_delay port map (
        clk            => clk,
        channel_delay  => "01",
        send_pattern_1 => send_pattern_1,
        send_pattern_2 => send_pattern_2,
        data_in        => data_in,
        data_out       => data_out_1
    );
end architecture;