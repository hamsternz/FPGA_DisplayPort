
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity link_signal_mgmt is
    Port ( mgmt_clk    : in  STD_LOGIC;

           tx_powerup  : in  STD_LOGIC;  -- Used to reset drive parameters too!
        
           status_de   : in  std_logic;
           adjust_de   : in  std_logic;
           addr        : in  std_logic_vector(7 downto 0);
           data        : in  std_logic_vector(7 downto 0);

           -------------------------------------------
           sink_channel_count   : in  std_logic_vector(2 downto 0);
           source_channel_count : in  std_logic_vector(2 downto 0);
           active_channel_count : out std_logic_vector(2 downto 0);
           ---------------------------------------------------------
           powerup_channel : out std_logic_vector(3 downto 0) := (others => '0');
           -----------------------------------------
           clock_locked   : out STD_LOGIC;
           equ_locked     : out STD_LOGIC;
           symbol_locked  : out STD_LOGIC;
           align_locked   : out STD_LOGIC;

           preemp_0p0  : out STD_LOGIC := '0';
           preemp_3p5  : out STD_LOGIC := '0';
           preemp_6p0  : out STD_LOGIC := '0';
    
           swing_0p4   : out STD_LOGIC := '0';
           swing_0p6   : out STD_LOGIC := '0';
           swing_0p8   : out STD_LOGIC := '0');
end link_signal_mgmt;

architecture arch of link_signal_mgmt is
    signal power_mask     : std_logic_vector(3 downto 0) := "0000";
    signal preemp_level   : std_logic_vector(1 downto 0) := "00";
    signal voltage_level  : std_logic_vector(1 downto 0) := "00";
    signal channel_state  : std_logic_vector(23 downto 0):= (others => '0');
    signal channel_adjust : std_logic_vector(15 downto 0):= (others => '0');
    signal active_channel_count_i : std_logic_vector(2 downto 0);
begin
    active_channel_count <= active_channel_count_i;
process(mgmt_clk)
    begin
        if rising_edge(mgmt_clk) then
            ----------------------------------------------------------
            -- Work out how many channels will be active 
            -- (the min of source_channel_count and sink_channel_count
            --
            -- Also work out the power-up mask for the transceivers
            -----------------------------------------------------------
            case source_channel_count is
                when "100" =>
                    case sink_channel_count is
                        when "100"  => active_channel_count_i <= "100"; power_mask <= "1111";
                        when "010"  => active_channel_count_i <= "010"; power_mask <= "0011";
                        when others => active_channel_count_i <= "001"; power_mask <= "0001";
                    end case;                        
                when "010" =>
                    case sink_channel_count is
                        when "100"  => active_channel_count_i <= "010"; power_mask <= "0011";
                        when "010"  => active_channel_count_i <= "010"; power_mask <= "0011";
                        when others => active_channel_count_i <= "001"; power_mask <= "0001";
                    end case;                                            
                when others =>
                    active_channel_count_i <= "001"; power_mask <= "0001";
            end case;
            
            ---------------------------------------------
            -- If the powerup is not asserted, then reset 
            -- everything.
            ---------------------------------------------
            if tx_powerup  = '1' then
                powerup_channel  <= power_mask;
            else
                powerup_channel  <= (others => '0');
                preemp_level     <= "00";
                voltage_level    <= "00";
                channel_state    <= (others => '0');
                channel_adjust   <= (others => '0');
            end if;
        
            ---------------------------------------------
            -- Decode the power and pre-emphasis levels
            ---------------------------------------------
            case preemp_level is 
                when "00"   => preemp_0p0 <= '1'; preemp_3p5 <= '0'; preemp_6p0 <= '0';
                when "01"   => preemp_0p0 <= '0'; preemp_3p5 <= '1'; preemp_6p0 <= '0';
                when others => preemp_0p0 <= '0'; preemp_3p5 <= '0'; preemp_6p0 <= '1';
            end case;

            case voltage_level is
                when "00"   => swing_0p4 <= '1';  swing_0p6 <= '0';  swing_0p8 <= '0';
                when "01"   => swing_0p4 <= '0';  swing_0p6 <= '1';  swing_0p8 <= '0';
                when others => swing_0p4 <= '0';  swing_0p6 <= '0';  swing_0p8 <= '1';
            end case;            

            -----------------------------------------------
            -- Receive the status data from the AUX channel
            -----------------------------------------------
            if status_de = '1' then
                case addr is 
                    when x"00" => channel_state( 7 downto  0) <= data;
                    when x"01" => channel_state(15 downto  8) <= data;                                  
                    when x"02" => channel_state(23 downto 16) <= data;                                  
                    when others => NULL;
                end case;
            end if;

            -----------------------------------------------
            -- Receive the channel adjsutment request 
            -----------------------------------------------
            if adjust_de = '1' then
                case addr is 
                    when x"00" => channel_adjust( 7 downto 0) <= data;
                    when x"01" => channel_adjust(15 downto 8) <= data;                                  
                    when others => NULL;
                end case;
            end if;

            -----------------------------------------------
            -- Update the status signals based on the 
            -- register data recieved over from the AUX
            -- channel. 
            -----------------------------------------------
            clock_locked  <= '0';
            equ_locked    <= '0';
            symbol_locked <= '0';
            case active_channel_count_i is
                when "001"  => if (channel_state(3 downto 0) AND x"1") = x"1" then
                                  clock_locked <= '1';
                               end if;
                               if (channel_state(3 downto 0) AND x"3") = x"3" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(3 downto 0) AND x"7") = x"7" then
                                  symbol_locked <= '1';
                               end if;
                when "010"  => if (channel_state(7 downto 0) AND x"11") = x"11" then
                                  clock_locked <= '1';
                               end if;
                               if (channel_state(7 downto 0) AND x"33") = x"33" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(7 downto 0) AND x"77") = x"77" then
                                  symbol_locked <= '1';
                               end if;

                when "100"  => if (channel_state(15 downto 0) AND x"1111") = x"1111" then
                                 clock_locked <= '1';
                               end if;
                               if (channel_state(15 downto 0) AND x"3333") = x"3333" then
                                  equ_locked <= '1';
                               end if;
                               if (channel_state(15 downto 0) AND x"7777") = x"7777" then
                                  symbol_locked <= '1';
                               end if;
                               
                when others => NULL;
            end case;
            align_locked <= channel_state(16);
        end if;
    end process;
end architecture;