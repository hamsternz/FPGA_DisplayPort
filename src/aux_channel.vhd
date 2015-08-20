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
		   clk             : in    std_logic;
		   debug_pmod      : out   std_logic_vector(7 downto 0);
		   ------------------------------
           edid_de         : out   std_logic;
           edid_addr       : out   std_logic_vector(7 downto 0);
		   edid_data       : out   std_logic_vector(7 downto 0);
		   ------------------------------
		   dp_tx_hp_detect : in    std_logic;
           dp_tx_aux_p     : inout std_logic;
           dp_tx_aux_n     : inout std_logic;
           dp_rx_aux_p     : inout std_logic;
           dp_rx_aux_n     : inout std_logic
		);
end entity;

architecture arch of aux_channel is
    type t_state is ( error, reset, check_presence, 
                    edid_block0, edid_block1, edid_block2, edid_block3,
                    edid_block4, edid_block5, edid_block6, edid_block7,
                    read_link_count, read_speed, 
                    set_link_count,set_speed);
    signal state            : t_state               := reset;
    signal next_state       : t_state               := reset;
    signal pulse_per_second : std_logic             := '0';
	signal pps_count        : unsigned(26 downto 0) := (9=>'1',others => '0');   
                            
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
	
	signal channel_busy    : std_logic;
	signal channel_timeout : std_logic;
	
	signal rx_byte_count   : unsigned(7 downto 0) := (others => '0');
	signal edid_addr_i     : unsigned(7 downto 0)  := (others => '0');
	
	signal just_read_from_rx :std_logic := '0';

begin


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
                rx_byte_count <= (others => '0');
                case next_state is
                when reset           => msg <= x"00";
                when check_presence  => msg <= x"01";
                when edid_block0     => msg <= x"02";
                when edid_block1     => msg <= x"02";
                when edid_block2     => msg <= x"02";
                when edid_block3     => msg <= x"02";
                when edid_block4     => msg <= x"02";
                when edid_block5     => msg <= x"02";
                when edid_block6     => msg <= x"02";
                when edid_block7     => msg <= x"02";
                when read_link_count => msg <= x"03";
                when read_speed      => msg <= x"04";
                when set_link_count  => msg <= x"05";
                when set_speed       => msg <= x"06";
                when error           => msg <= x"00";
                when others          => msg <= x"00";
                end case;
            end if;
            state <= next_state;

            -- Set the address and data enable for the EDID output
            edid_de   <= '0';
            edid_addr <= std_logic_vector(edid_addr_i);
            
            if channel_busy = '0' then
                case state is
                    when reset =>
                        if pulse_per_second = '1' then     				
                            next_state  <= check_presence;
                            edid_addr_i <= x"00";
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
                                edid_de     <= '1';                                
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
                                edid_de     <= '1';                                
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
                                edid_de     <= '1';                                
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
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
                                edid_addr_i <= edid_addr_i+1;
                                edid_data   <= aux_rx_data;
                                edid_de     <= '1';                                
                                if rx_byte_count = x"10" then
                                    next_state <= reset;
                                end if;                                       
                            end if;
                        end if;
                    when read_link_count =>
                    when read_speed =>
                    when set_link_count =>
                    when set_speed =>
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
