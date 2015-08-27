

---------------------------------------------------
--
-- +----+--------------------+--------------------+
-- |Word| Training pattern 1 | Training pattern 2 |
-- |    | Code  MSB    LSB   | Code   MSB     LSB |
-- +----+--------------------+-------------------+
-- |  0 | D10.2 1010101010   | K28.5- 0101111100  |
-- |  1 | D10.2 1010101010   | D11.6  0110001011  |
-- |  2 | D10.2 1010101010   | K28.5+ 1010000011  |
-- |  3 | D10.2 1010101010   | D11.6  0110001011  |
-- |  4 | D10.2 1010101010   | D10.2  1010101010  |
-- |  5 | D10.2 1010101010   | D10.2  1010101010  |
-- |  6 | D10.2 1010101010   | D10.2  1010101010  |
-- |  7 | D10.2 1010101010   | D10.2  1010101010  |
-- |  8 | D10.2 1010101010   | D10.2  1010101010  |
-- |  9 | D10.2 1010101010   | D10.2  1010101010  |
-- +----+--------------------+--------------------+
-- Patterns are transmitted LSB first.
---------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity training_and_channel_delay is
    port (
        clk            : in  std_logic;
        channel_delay  : in  std_logic_vector(1 downto 0);
        send_pattern_1 : in  std_logic;
        send_pattern_2 : in  std_logic;
        data_in        : in  std_logic_vector(19 downto 0);
        data_out       : out std_logic_vector(19 downto 0)
    );
end training_and_channel_delay;

architecture arch of training_and_channel_delay is    
    signal state            : std_logic_vector(3 downto 0)  := "0000";
    -- To implement the per-lane two-word delay
    signal data_out_0       : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_1       : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_2       : std_logic_vector(19 downto 0) := (others => '0');
    signal data_out_3       : std_logic_vector(19 downto 0) := (others => '0');
    --- Codes used during link training
    constant CODE_K28_5_NEG : std_logic_vector(9 downto 0) := "0101111100";
    constant CODE_K28_5_POS : std_logic_vector(9 downto 0) := "1010000011";
    constant CODE_D11_6     : std_logic_vector(9 downto 0) := "0110001011";
    constant CODE_D10_2     : std_logic_vector(9 downto 0) := "1010101010";
begin
    with channel_delay select data_out <= data_out_0 when "00",
                                          data_out_1 when "01",     
                                          data_out_2 when "10",     
                                          data_out_3 when others;   
                                          
process(clk)
    begin
        if rising_edge(clk) then
            data_out_3 <= data_out_2;
            data_out_2 <= data_out_1;
            data_out_1 <= data_out_0;

            case state is
                when x"5"   => state <= x"4"; data_out_0 <= CODE_D11_6 & CODE_K28_5_NEG; 
                when x"4"   => state <= x"3"; data_out_0 <= CODE_D11_6 & CODE_K28_5_POS;
                when x"3"   => state <= x"2"; data_out_0 <= CODE_D10_2 & CODE_D10_2;
                when x"2"   => state <= x"1"; data_out_0 <= CODE_D10_2 & CODE_D10_2;                               
                when x"1"   => state <= x"0"; data_out_0 <= CODE_D10_2 & CODE_D10_2;
                                if send_pattern_2 = '1' then
                                    state <= x"5";
                                elsif send_pattern_1 = '1' then
                                    state <= x"1";
                                end if;
                when others => state <= x"0"; data_out_0 <= data_in;
                                if send_pattern_2 = '1' then
                                    state <= x"5";
                                elsif send_pattern_1 = '1' then
                                    state <= x"1";
                                end if;
             end case;                
        end if;
    end process;
end architecture;