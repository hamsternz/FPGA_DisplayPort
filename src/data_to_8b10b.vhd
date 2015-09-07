library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_to_8b10b is
        port ( 
            clk           : in  std_logic;
            data0         : in  std_logic_vector(7 downto 0);
            data0k        : in  std_logic;
            data0forceneg : in  std_logic;
            data1         : in  std_logic_vector(7 downto 0);
            data1k        : in  std_logic;
            data1forceneg : in  std_logic;
            symbol0       : out std_logic_vector(9 downto 0);
            symbol1       : out std_logic_vector(9 downto 0)
        );
end entity;

architecture arch of data_to_8b10b is
    signal parity_k6b : std_logic_vector(0 downto 0) := "1";                                                        
    signal parity_k4b : std_logic_vector(7 downto 0) := "11111111";                                                       
                                                     
    signal current_disparity_neg : std_logic := '0';

    -- Stage 2 stuff
    signal data0_2          : std_logic_vector(7 downto 0) := (others => '0');
    signal data0k_2         : std_logic  := '0';
    signal data1_2          : std_logic_vector(7 downto 0) := (others => '0');
    signal data1k_2         : std_logic  := '0';
    signal disparity0_neg_2 : std_logic := '0';
    signal disparity1_neg_2 : std_logic := '0';

    -- Stage 1 stuff
    signal disparity0_odd_1 : std_logic  := '0';
    signal data0_1          : std_logic_vector(7 downto 0) := (others => '0');
    signal data0k_1         : std_logic  := '0';
    signal data0forceneg_1  : std_logic  := '0';
    signal disparity1_odd_1 : std_logic  := '0';
    signal data1_1          : std_logic_vector(7 downto 0) := (others => '0');
    signal data1k_1         : std_logic  := '0';
    signal data1forceneg_1  : std_logic  := '0';

    constant disparity_d : std_logic_vector(255 downto 0) := x"00000000" &   -- Dx.7
                                                             x"00000000" &   -- Dx.6
                                                             x"00000000" &   -- Dx.5
                                                             x"00000000" &   -- Dx.4
                                                             x"00000000" &   -- Dx.3
                                                             x"00000000" &   -- Dx.2
                                                             x"00000000" &   -- Dx.1
                                                             x"00000000";    -- Dx.0

    constant disparity_k : std_logic_vector(255 downto 0) := x"00000000" &   -- Kx.7
                                                             x"10000000" &   -- Kx.6
                                                             x"10000000" &   -- Kx.5
                                                             x"00000000" &   -- Kx.4
                                                             x"10000000" &   -- Kx.3
                                                             x"10000000" &   -- Kx.2
                                                             x"10000000" &   -- Kx.1
                                                             x"00000000";    -- Kx.0
begin

process(clk)
    begin
        if rising_edge(clk) then
            -----------------------------------------------------------
            -- Stage 3 - work out the final symbol based on the 
            -- disparity calcuated in stage 2 
            ----------------------------------------------------------
            symbol0 <= data0_2 & "00";
            symbol1 <= data1_2 & "00";

            -----------------------------------------------------------
            -- Stage 2 - work out the disparity for each symbol, and
            -- the disparity for the next set of symbols.
            ----------------------------------------------------------
            if data0forceneg = '0' then
                if data1forceneg = '0'  then
                    disparity0_neg_2      <= current_disparity_neg;
                    disparity1_neg_2      <= current_disparity_neg XOR disparity0_odd_1;
                    current_disparity_neg <= current_disparity_neg XOR disparity0_odd_1 XOR disparity1_odd_1;  
                else
                    disparity0_neg_2      <= current_disparity_neg;
                    disparity1_neg_2      <= '1';
                    current_disparity_neg <= '1' XOR disparity1_odd_1;  
                end if;     
            else
                if data1forceneg = '1'  then
                    disparity0_neg_2      <= '1';
                    disparity1_neg_2      <= '1' XOR disparity0_odd_1;
                    current_disparity_neg <= '1' XOR disparity0_odd_1 XOR disparity1_odd_1;  
                else
                    disparity0_neg_2      <= '1';
                    disparity1_neg_2      <= '1';
                    current_disparity_neg <= '1' XOR disparity1_odd_1;  
                end if;     
            end if;
            data0_2  <= data0_1;
            data0k_2 <= data0k_1;
            
            data1_2  <= data1_1;
            data1k_2 <= data1k_1;
        
            -----------------------------------------------------------
            -- Stage 1 - Look up the disparity for each data word
            ----------------------------------------------------------
            if data0k = '1' then 
                disparity0_odd_1 <= disparity_k(to_integer(unsigned(data0)));
            else 
                disparity0_odd_1 <= disparity_d(to_integer(unsigned(data0)));
            end if;
            data0_1          <= data0;
            data0k_1         <= data0k;
            data0forceneg_1  <= data0forceneg;

            if data1k = '1' then 
                disparity1_odd_1 <= disparity_k(to_integer(unsigned(data1)));
            else 
                disparity1_odd_1 <= disparity_d(to_integer(unsigned(data1)));
            end if;
            data1_1          <= data1;
            data1k_1         <= data1k;
            data1forceneg_1  <= data1forceneg;
        end if;        
    end process;    
end architecture;
