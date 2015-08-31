---------------------------------------------------
--
---------------------------------------------------
--
-- This is set up so the change over from test patters
-- to data happens seamlessly - e.g. the value for 
-- on data_in when send_patter_1 and send_pattern_2
-- are both become zero is guarranteed to be sent
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
    
    signal hold_at_state_1  : std_logic_vector(9 downto 0) := "1111111111";
    constant CODE_K28_5_NEG : std_logic_vector(9 downto 0) := "0101111100";
    constant CODE_K28_5_POS : std_logic_vector(9 downto 0) := "1010000011";
    constant CODE_D11_6     : std_logic_vector(9 downto 0) := "0110001011";
    constant CODE_D10_2     : std_logic_vector(9 downto 0) := "1010101010";

    type a_delay_line is array (0 to 8) of std_logic_vector(19 downto 0);
    signal delay_line : a_delay_line := (others => (others => '0'));
    
    signal  hold_at_state_1_shift_reg : std_logic_vector(3 downto 0) := (others => '1');
begin
    with channel_delay select data_out <= delay_line(5) when "00",
                                          delay_line(6) when "01",     
                                          delay_line(7) when "10",     
                                          delay_line(8) when others;   
                                          
process(clk)
    begin
        if rising_edge(clk) then
           -- Move the dalay line along 
           delay_line(1 to 7) <= delay_line(0 to 6);
           delay_line(0) <= data_in;
           
           -- Do we ened to hold at state 1 until valid data has filtered down the delay line?
           if send_pattern_2 = '1' or send_pattern_1 = '1' then
               hold_at_state_1_shift_reg <= (others => '1');
            else
               hold_at_state_1_shift_reg <= '0' & hold_at_state_1_shift_reg(hold_at_state_1_shift_reg'high downto 1);
            end if;
            
            -- Do we need to overwrite the data in slot 5 with the sync patterns?
            case state is
                when x"5"   => state <= x"4"; delay_line(5) <= CODE_D11_6 & CODE_K28_5_NEG; 
                when x"4"   => state <= x"3"; delay_line(5) <= CODE_D11_6 & CODE_K28_5_POS;
                when x"3"   => state <= x"2"; delay_line(5) <= CODE_D10_2 & CODE_D10_2;
                when x"2"   => state <= x"1"; delay_line(5) <= CODE_D10_2 & CODE_D10_2;                               
                when x"1"   => state <= x"0"; delay_line(5) <= CODE_D10_2 & CODE_D10_2;
                                if send_pattern_2 = '1' then
                                    state <= x"5";
                                elsif hold_at_state_1_shift_reg(0) = '1' then
                                    state <= x"1";
                                end if;
                when others => state <= x"0";
                                if send_pattern_2 = '1' then
                                    state <= x"5";
                                elsif hold_at_state_1_shift_reg(0) = '1' then
                                    state <= x"1";
                                end if;
             end case;                
        end if;
    end process;
end architecture;