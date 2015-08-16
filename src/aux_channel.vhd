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
		   native_res_x    : out   std_logic_vector(11 downto 0);
		   native_res_y    : out   std_logic_vector(11 downto 0);
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
	signal coount          : unsigned(9 downto 0) := (others => '0');

    signal aux_tx_wr_en    : std_logic;
    signal aux_tx_data     : std_logic_vector(7 downto 0);

    signal aux_rx_rd_en    : std_logic;
    signal aux_rx_data     : std_logic_vector(7 downto 0);
	
	signal channel_busy    : std_logic;
	signal channel_timeout : std_logic;
	
	signal count           : unsigned(17 downto 0) := (others => '0');
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
		   ------------------------------
           busy        => channel_busy,
           timeout     => channel_timeout
    );

clk_proc: process(clK)
	begin
		if rising_edge(clk) then
			msg_de <= '0';

			if count = "01111111111111111" then
				msg_de <= '1';
				msg    <= x"01";
			end if;

			if count = "111111111111111111" then
				msg_de <= '1';
				msg    <= x"02";
			end if;
			count <= count+1;
		end if;
	end process;
end architecture;
