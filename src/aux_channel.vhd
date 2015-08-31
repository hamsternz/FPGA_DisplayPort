----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz< 
-- 
-- Module Name: aux_channel - Behavioral
--
-- Description: A moreusable interface for sending/receiving data down the 
--              DisplayPort AUX channel. It also implements the timeout.
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity aux_channel is
		port ( 
		   clk                 : in    std_logic;
		   debug_pmod          : out   std_logic_vector(7 downto 0);
		   ------------------------------
           edid_de             : out   std_logic;
           dp_register_de      : out   std_logic;
           aux_addr            : out   std_logic_vector(7 downto 0);
		   aux_data            : out   std_logic_vector(7 downto 0);
		   ------------------------------
		   link_count          : in    std_logic_vector(1 downto 0);
		   ------------------------------
		   tx_powerup          : out   std_logic_vector(3 downto 0);
		   tx_pattern_1        : out   std_logic := '0';
		   tx_pattern_2        : out   std_logic := '0';
		   tx_link_established : out   std_logic := '0';
		   ------------------------------
		   dp_tx_hp_detect     : in    std_logic;
           dp_tx_aux_p         : inout std_logic;
           dp_tx_aux_n         : inout std_logic;
           dp_rx_aux_p         : inout std_logic;
           dp_rx_aux_n         : inout std_logic
		);
end entity;

architecture arch of aux_channel is
    type t_state is ( error, reset, check_presence,
                    -- Gathering Display information 
                    edid_block0, edid_block1, edid_block2, edid_block3,
                    edid_block4, edid_block5, edid_block6, edid_block7,
                    -- Gathering display Port information
                    read_rev, read_registers,
                    -- Link configuration states 
                    set_channel_coding, set_speed_270, set_downspread, set_link_count_1, set_link_count_2, set_link_count_4, 
                    -- Link training 
                    clock_training,     waiting_for_lock,      testing_for_lock,
                    alignment_training, waiting_for_alignment, testing_for_alignment,
                    link_established);
    signal state            : t_state               := reset;
    signal next_state       : t_state               := reset;
    signal pulse_per_second : std_logic             := '0';
	signal pps_count        : unsigned(26 downto 0) := (9=>'1',others => '0');   
    signal count_100us      : unsigned(14 downto 0) := (others => '0');
    component dp_aux_messages is
	port ( clk          : in  std_logic;
		   -- Interface to send messages
           msg_de       : in  std_logic;
		   msg          : in  std_logic_vector(7 downto 0); 
           busy         : out std_logic;
		   --- Interface to the AUX Channel
           aux_tx_wr_en : out std_logic;
		   aux_tx_data  : out std_logic_vector(7 downto 0)
		 );
	end component;

	component aux_interface is
        port ( 
           clk          : in    std_logic;
		   debug_pmod   : out   std_logic_vector(7 downto 0);
           ------------------------------
           dp_tx_aux_p  : inout std_logic;
           dp_tx_aux_n  : inout std_logic;
           dp_rx_aux_p  : inout std_logic;
           dp_rx_aux_n  : inout std_logic;
           ------------------------------
           tx_wr_en : in    std_logic;
           tx_data  : in    std_logic_vector(7 downto 0);
           tx_full  : out   std_logic;
           ------------------------------                                  
           rx_rd_en : in    std_logic;
           rx_data  : out   std_logic_vector(7 downto 0);
           rx_empty : out   std_logic;
           ------------------------------
           busy         : out   std_logic;
           timeout      : out   std_logic
         );
    end component;

	signal msg_de          : std_logic := '0';
	signal msg             : std_logic_vector(7 downto 0);
	signal msg_busy        : std_logic := '0';

    signal aux_tx_wr_en    : std_logic;
    signal aux_tx_data     : std_logic_vector(7 downto 0);

    signal aux_rx_rd_en    : std_logic;
    signal aux_rx_data     : std_logic_vector(7 downto 0);
    signal aux_rx_empty    : std_logic;

    signal link_count_sink : std_logic_vector(7 downto 0);
	
	signal channel_busy    : std_logic;
	signal channel_timeout : std_logic;
	
	signal rx_byte_count   : unsigned(7 downto 0) := (others => '0');
	signal aux_addr_i          : unsigned(7 downto 0)  := (others => '0');
	
	signal just_read_from_rx :std_logic := '0';
    signal powerup_mask  : std_logic_vector(3 downto 0);

begin

    with link_count select powerup_mask <= "0001" when "001",
                                           "0011" when "010",
                                           "1111" when "100",
                                           "0000" when others;
i_aux_messages: dp_aux_messages port map (
		   clk             => clk,
		   -- Interface to send messages
           msg_de          => msg_de,
		   msg             => msg,
           busy          => msg_busy,
		   --- Interface to the AUX Channel
           aux_tx_wr_en => aux_tx_wr_en,
		   aux_tx_data  => aux_tx_data
		 );

i_channel: aux_interface port map ( 
		   clk         => clk,
		   debug_pmod  => debug_pmod, 
		   ------------------------------
           dp_tx_aux_p => dp_tx_aux_p,
           dp_tx_aux_n => dp_tx_aux_n,
           dp_rx_aux_p => dp_rx_aux_p,
           dp_rx_aux_n => dp_rx_aux_n,
		   ------------------------------
           tx_wr_en    => aux_tx_wr_en,
		   tx_data     => aux_tx_data,
		   ------------------------------
           rx_rd_en    => aux_rx_rd_en,
           rx_data     => aux_rx_data,
           rx_empty    => aux_rx_empty,
		   ------------------------------
           busy        => channel_busy,
           timeout     => channel_timeout
    );
    aux_rx_rd_en <= (not channel_busy) and (not aux_rx_empty);
      
clk_proc: process(clK)
	begin
		if rising_edge(clk) then
		    -- Are we going to send out a new message this cycle?
            if next_state = state then
                msg_de <= '0';
            else
                msg_de <= '1';
                tx_link_established <= '0';
                tx_pattern_1        <= '0';
                tx_pattern_2        <= '0';
                tx_powerup          <= "0000";
                rx_byte_count <= (others => '0');
                case next_state is
                    when reset                 => msg <= x"00";
                    when check_presence        => msg <= x"01";
                    when edid_block0           => msg <= x"02";
                    when edid_block1           => msg <= x"02";
                    when edid_block2           => msg <= x"02";
                    when edid_block3           => msg <= x"02";
                    when edid_block4           => msg <= x"02";
                    when edid_block5           => msg <= x"02";
                    when edid_block6           => msg <= x"02";
                    when edid_block7           => msg <= x"02";
                    when read_rev              => msg <= x"03";
                    when read_registers        => msg <= x"04";
                    when set_channel_coding    => msg <= x"06";
                    when set_speed_270         => msg <= x"07";
                    when set_downspread        => msg <= x"08";
                    when set_link_count_1      => msg <= x"09";
                    when set_link_count_2      => msg <= x"0A";
                    when set_link_count_4      => msg <= x"0B";
                    when clock_training        => msg <= x"0C"; tx_powerup <= powerup_mask; tx_pattern_1 <= '1';
                    when waiting_for_lock      => msg <= x"00"; tx_powerup <= powerup_mask; tx_pattern_1 <= '1';
                    when testing_for_lock      => msg <= x"0D"; tx_powerup <= powerup_mask; tx_pattern_1 <= '1';
                    when alignment_training    => msg <= x"0E"; tx_powerup <= powerup_mask; tx_pattern_2 <= '1';
                    when waiting_for_alignment => msg <= x"0F"; tx_powerup <= powerup_mask; tx_pattern_2 <= '1';
                    when testing_for_alignment => msg <= x"0F"; tx_powerup <= powerup_mask; tx_pattern_2 <= '1';
                    when link_established      => msg <= x"00"; tx_powerup <= powerup_mask; tx_link_established <= '1';
                    when error                 => msg <= x"00";
                    when others                => msg <= x"00";
                end case;
            end if;
            state <= next_state;


            -- Counter for short pauses (tested by the high bit underflowing to '1'
            count_100us <= count_100us - 1;
            
            -- Set the address and data enable for the EDID output
            edid_de        <= '0';
            dp_register_de <= '0';
            aux_addr       <= std_logic_vector(aux_addr_i);
            
            if channel_busy = '0' then
                case state is
                    when reset =>
                        if pulse_per_second = '1' then     				
                            next_state  <= check_presence;
                            aux_addr_i <= x"00";
                        end if;
                        
                    when check_presence => 
                        if just_read_from_rx = '1' then  
                            if aux_rx_data = x"00" then
                                next_state <= edid_block0;                        
                            else
                                next_state <= error;
                            end if;
                        end if;

                    when edid_block0 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
                            
                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de    <= '1';                                
                                if rx_byte_count = x"10"then
                                    next_state <= edid_block1;
                                end if;                                       
                            end if;
                        end if;
                        
                    when edid_block1 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;

                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= edid_block2;
                                end if;                                       
                            end if;
                        end if;

                    when edid_block2 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
                            
                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de    <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= edid_block3;
                                end if;                                       
                            end if;
                        end if;

                    when edid_block3 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;

                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                   next_state <= edid_block4;
                                end if;                                       
                            end if;
                        end if;
                    when edid_block4 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
                            
                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de    <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= edid_block5;
                                end if;                                       
                            end if;
                        end if;
                    when edid_block5 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;

                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= edid_block6;
                                end if;                                       
                            end if;
                        end if;
                    when edid_block6 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
                    
                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= edid_block7;
                                end if;                                       
                            end if;
                        end if;
                    when edid_block7 =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 17 bytes)?
                            if rx_byte_count /= x"10" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;

                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= read_rev;
                                end if;                                       
                            end if;
                        end if;
                    when read_rev =>
                        if just_read_from_rx = '1' then
                            -- Is this a short read (expecting 2 bytes)?
                            if rx_byte_count /= x"01" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
    
                            if rx_byte_count = x"00" then 
                                if aux_rx_data /= x"00" then  
                                    next_state <= error;
                                end if;
                            else
                                aux_addr_i <= aux_addr_i+1;
                                aux_data   <= aux_rx_data;
                                dp_register_de     <= '1';                                
                                if rx_byte_count = x"01" then
                                    next_state <= read_registers;
                                end if;                                       
                            end if;
                        end if;
                    when read_registers =>
                            if just_read_from_rx = '1' then
                                -- Is this a short read (expecting 2 bytes)?
                                if rx_byte_count /= x"0C" and aux_rx_empty = '1' then 
                                    next_state <= error;
                                end if;
        
                                if rx_byte_count = x"00" then 
                                    if aux_rx_data /= x"00" then  
                                        next_state <= error;
                                    end if;
                                else
                                    link_count_sink <= aux_rx_data; 
                                    if rx_byte_count = x"0C" then
                                        next_state <= set_channel_coding;
                                        aux_addr_i <= (others => '0');
                                    end if;                                       
                                end if;
                            end if;
                    when set_channel_coding =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= set_speed_270;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                    when set_speed_270 =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= set_downspread;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                        
                    when set_downspread =>
                        if just_read_from_rx = '1' then  
                            if aux_rx_data = x"00" then
                                if rx_byte_count = x"00" then 
                                    case link_count is
                                        when x"01"  => next_state <= set_link_count_1;                        
                                        when x"02"  => next_state <= set_link_count_2;                        
                                        when x"04"  => next_state <= set_link_count_4;
                                        when others => next_state <= error;
                                    end case;
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                    
                    when set_link_count_1 =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= clock_training;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;

                    when set_link_count_2 =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= clock_training;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                            
                    when set_link_count_4 =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= clock_training;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                    when clock_training =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count = x"00" then 
                                if aux_rx_data = x"00" then
                                    next_state <= waiting_for_lock;
                                    count_100us <= to_unsigned(9999,15);                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;
                    when waiting_for_lock  =>
                        if count_100us(count_100us'high) = '1' then
                            next_state <= testing_for_lock;                        
                        end if;

                    when testing_for_lock =>
                        if just_read_from_rx = '1' then  
                            if rx_byte_count /= x"02" and aux_rx_empty = '1' then 
                                next_state <= error;
                            end if;
                            if rx_byte_count = x"02" then 
                                if aux_rx_data = x"00" then
                                    next_state <= waiting_for_lock;
                                    count_100us <= to_unsigned(9999,15);                        
    --                              next_state <= alignment_training;                        
                                else
                                    next_state <= error;
                                end if;
                            end if;
                        end if;

                    when alignment_training =>
                        if just_read_from_rx = '1' then  
                            if aux_rx_data = x"00" then
                                next_state <= waiting_for_alignment;                        
                                count_100us <= to_unsigned(9999,15);                        
                            else
                                next_state <= error;
                            end if;
                        end if;
                    when waiting_for_alignment =>
                        if count_100us(count_100us'high) = '1' then
                            next_state <= testing_for_alignment;                        
                        end if;
                        
                    when testing_for_alignment =>
                        if just_read_from_rx = '1' then  
                            if aux_rx_data = x"00" then
                                next_state <= link_established;                        
                            else
                                next_state <= error;
                            end if;
                        end if;
                    when link_established =>

                    when others =>
                end case;
            end if;
                            
            if channel_timeout = '1' or (state /= reset and pulse_per_second = '1') then
                next_state <= reset;
            end if;

            if channel_busy = '0' and aux_rx_empty = '0' then
                just_read_from_rx <= '1';
            else                
                just_read_from_rx <= '0';
            end if;

            if just_read_from_rx = '1' then
                rx_byte_count <= rx_byte_count+1;
            end if;

			if pps_count = 0 then
			  pulse_per_second <= '1';
			  pps_count        <= to_unsigned(99999999,27);
			else
			  pulse_per_second <= '0';
			  pps_count        <= pps_count - 1;
			end if;
		end if;		
	end process;
end architecture;
