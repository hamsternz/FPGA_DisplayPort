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
        clock_train    : in  std_logic;
        align_train    : in  std_logic;

        in_data0              : in  std_logic_vector(7 downto 0);
        in_data0k             : in  std_logic;
        in_data1              : in  std_logic_vector(7 downto 0);
        in_data1k             : in  std_logic;

        out_data0          : out std_logic_vector(7 downto 0);
        out_data0k         : out std_logic;
        out_data0forceneg  : out std_logic;
        out_data1          : out std_logic_vector(7 downto 0);
        out_data1k         : out std_logic;
        out_data1forceneg  : out std_logic
    );
end training_and_channel_delay;

architecture arch of training_and_channel_delay is    
    signal state            : std_logic_vector(3 downto 0)  := "0000";
    
    signal hold_at_state_1 : std_logic_vector(9 downto 0) := "1111111111";
    constant CODE_K28_5    : std_logic_vector(7 downto 0) := "10111100";
    constant CODE_D11_6    : std_logic_vector(7 downto 0) := "11001011";
    constant CODE_D10_2    : std_logic_vector(7 downto 0) := "01001010";

    type a_delay_line  is array (0 to 8) of std_logic_vector(7 downto 0);
    type a_delay_lineb is array (0 to 8) of std_logic;
    signal delay_line0   : a_delay_line  := (others => (others => '0'));
    signal delay_line0k  : a_delay_lineb := (others => '0');
    signal delay_line0f  : a_delay_lineb := (others => '0');
    signal delay_line1   : a_delay_line  := (others => (others => '0'));
    signal delay_line1k  : a_delay_lineb := (others => '0');
    signal delay_line1f  : a_delay_lineb := (others => '0');
    
    signal  hold_at_state_1_shift_reg : std_logic_vector(3 downto 0) := (others => '1');
begin
    with channel_delay select out_data0  <= delay_line0(5) when "00",
                                            delay_line0(6) when "01",     
                                            delay_line0(7) when "10",     
                                            delay_line0(8) when others;

    with channel_delay select out_data0k <= delay_line0k(5) when "00",
                                            delay_line0k(6) when "01",     
                                            delay_line0k(7) when "10",     
                                            delay_line0k(8) when others;   

    with channel_delay select out_data0forceneg <= delay_line0f(5) when "00",
                                                   delay_line0f(6) when "01",     
                                                   delay_line0f(7) when "10",     
                                                   delay_line0f(8) when others;   
                                              
    with channel_delay select out_data1  <= delay_line1(5) when "00",
                                            delay_line1(6) when "01",     
                                            delay_line1(7) when "10",     
                                            delay_line1(8) when others;   

    with channel_delay select out_data1k <= delay_line1k(5) when "00",
                                            delay_line1k(6) when "01",     
                                            delay_line1k(7) when "10",     
                                            delay_line1k(8) when others;   

    with channel_delay select out_data1forceneg <= delay_line1f(5) when "00",
                                                   delay_line1f(6) when "01",     
                                                   delay_line1f(7) when "10",     
                                                   delay_line1f(8) when others;   

                                          
process(clk)
    begin
        if rising_edge(clk) then
           -- Move the dalay line along 
           delay_line0(1 to 7)  <= delay_line0(0 to 6);
           delay_line0k(1 to 7) <= delay_line0k(0 to 6);
           delay_line0f(1 to 7) <= delay_line0f(0 to 6);
           delay_line1(1 to 7)  <= delay_line1(0 to 6);
           delay_line1k(1 to 7) <= delay_line1k(0 to 6);
           delay_line1f(1 to 7) <= delay_line1f(0 to 6);
           
           
           delay_line0(0)       <= in_data0;
           delay_line0k(0)      <= in_data0k;
           delay_line0f(0)      <= '0';
           delay_line1(0)       <= in_data1;
           delay_line1k(0)      <= in_data1k;
           delay_line1f(0)      <= '0';
           
           -- Do we ened to hold at state 1 until valid data has filtered down the delay line?
           if align_train = '1' or clock_train = '1' then
               hold_at_state_1_shift_reg <= (others => '1');
            else
               hold_at_state_1_shift_reg <= '0' & hold_at_state_1_shift_reg(hold_at_state_1_shift_reg'high downto 1);
            end if;
            
            -- Do we need to overwrite the data in slot 5 with the sync patterns?
            case state is
                when x"5"   => state <= x"4"; delay_line0k(5) <= '1'; delay_line0(5) <= CODE_K28_5; delay_line0f(5) <= '1';
                                              delay_line1k(5) <= '0'; delay_line1(5) <= CODE_D11_6; delay_line1f(5) <= '0';
                when x"4"   => state <= x"3"; delay_line0k(5) <= '1'; delay_line0(5) <= CODE_K28_5; delay_line0f(5) <= '0';
                                              delay_line1k(5) <= '0'; delay_line1(5) <= CODE_D11_6; delay_line1f(5) <= '0';
                when x"3"   => state <= x"2"; delay_line0k(5) <= '0'; delay_line0(5) <= CODE_D10_2; delay_line0f(5) <= '0';
                                              delay_line1k(5) <= '0'; delay_line1(5) <= CODE_D10_2; delay_line1f(5) <= '0';
                when x"2"   => state <= x"1"; delay_line0k(5) <= '0'; delay_line0(5) <= CODE_D10_2; delay_line0f(5) <= '0';
                                              delay_line1k(5) <= '0'; delay_line1(5) <= CODE_D10_2; delay_line1f(5) <= '0';
                when x"1"   => state <= x"0"; delay_line0k(5) <= '0'; delay_line0(5) <= CODE_D10_2; delay_line0f(5) <= '0';
                                              delay_line1k(5) <= '0'; delay_line1(5) <= CODE_D10_2; delay_line1f(5) <= '0';
                                if align_train = '1' then
                                    state <= x"5";
                                elsif hold_at_state_1_shift_reg(0) = '1' then
                                    state <= x"1";
                                end if;
                when others => state <= x"0";
                                if align_train = '1' then
                                    state <= x"5";
                                elsif hold_at_state_1_shift_reg(0) = '1' then
                                    state <= x"1";
                                end if;
             end case;                
        end if;
    end process;
end architecture;