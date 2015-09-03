
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
           clock_adj_done  : out STD_LOGIC;
           align_adj_done  : out STD_LOGIC;

           preemp_0p0  : out STD_LOGIC := '0';
           preemp_3p5  : out STD_LOGIC := '0';
           preemp_6p0  : out STD_LOGIC := '0';
    
           swing_0p4   : out STD_LOGIC := '0';
           swing_0p6   : out STD_LOGIC := '0';
           swing_0p8   : out STD_LOGIC := '0');
end link_signal_mgmt;

architecture arch of link_signal_mgmt is
    signal power_mask    : std_logic_vector(3 downto 0) := "0000";
    signal preemp_level  : std_logic_vector(1 downto 0) := "00";
    signal voltage_level : std_logic_vector(1 downto 0) := "00";
begin
process(mgmt_clk)
    begin
        if rising_edge(mgmt_clk) then
            case source_channel_count is
                when "100" =>
                    case sink_channel_count is
                        when "100"  => active_channel_count <= "100"; power_mask <= "1111";
                        when "010"  => active_channel_count <= "010"; power_mask <= "0011";
                        when others => active_channel_count <= "001"; power_mask <= "0001";
                    end case;                        
                when "010" =>
                    case sink_channel_count is
                        when "100"  => active_channel_count <= "010"; power_mask <= "0011";
                        when "010"  => active_channel_count <= "010"; power_mask <= "0011";
                        when others => active_channel_count <= "001"; power_mask <= "0001";
                    end case;                                            
                when others =>
                    active_channel_count <= "001"; power_mask <= "0001";
            end case;
            if tx_powerup  = '1' then
                powerup_channel  <= power_mask;
            else
                powerup_channel  <= (others => '0');
                preemp_level     <= "00";
                voltage_level    <= "00";            
            end if;
        
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

            clock_adj_done   <= '1';
            align_adj_done   <= '1';            
        end if;
    end process;
end architecture;