----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz< 
-- 
-- Module Name: aux_interface - Behavioral
--
-- Description: The low-level interface to the DisplayPort AUX channel.
--
-- This encapsulates a small RX and TX FIFO. To use place all the words you want
-- to send into the TX fifo, and then monitor 'busy' and 'timeout'. Any received
-- data will be in the RX FIFO.
-- 
----------------------------------------------------------------------------------
-- FPGA_DisplayPort from https://github.com/hamsternz/FPGA_DisplayPort
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field <hamster@snap.net.nz>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - 3 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
-- 
-- If you what to say thanks for this design either drop me an email, or how about 
-- trying PayPal to my email (hamster@snap.net.nz)?
--
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--------------------------------------------------------------------------------------
--  Ver | Date       | Change
--------+------------+---------------------------------------------------------------
--  0.1 | 2015-09-17 | Initial Version
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity aux_interface is
    port ( 
       clk          : in    std_logic;
       debug_pmod   : out   std_logic_vector(7 downto 0);
       ------------------------------
       dp_tx_aux_p  : inout std_logic;
       dp_tx_aux_n  : inout std_logic;
       dp_rx_aux_p  : inout std_logic;
       dp_rx_aux_n  : inout std_logic;
       ------------------------------
       tx_wr_en     : in    std_logic;
       tx_data      : in    std_logic_vector(7 downto 0);
       tx_full      : out   std_logic;
       ------------------------------                                  
       rx_rd_en     : in    std_logic;
       rx_data      : out   std_logic_vector(7 downto 0);
       rx_empty     : out   std_logic;
       ------------------------------
       busy         : out   std_logic := '0';
       timeout      : out   std_logic := '0'
     );
end aux_interface;

architecture arch of aux_interface is
	type a_small_buffer is array (0 to 31) of std_logic_vector(7 downto 0);

	------------------------------------------
    -- A small fifo to send data from
	------------------------------------------
	type t_tx_state is (tx_idle, tx_sync, tx_start, tx_send_data, tx_stop, tx_flush, tx_waiting);
    signal tx_state : t_tx_state := tx_idle;
    signal tx_fifo          : a_small_buffer;
	signal tx_rd_ptr        : unsigned(4 downto 0) := (others => '0');
	signal tx_wr_ptr        : unsigned(4 downto 0) := (others => '0');
	signal tx_wr_ptr_plus_1 : unsigned(4 downto 0) := (others => '0');

    signal timeout_count : unsigned(15 downto 0) := (others => '0');


    signal tx_empty   : std_logic := '0';
    signal tx_full_i  : std_logic := '0';
    signal tx_rd_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_rd_en   : std_logic := '0';
    
    signal snoop      : std_logic := '0';
    
    signal serial_data : std_logic := '0';
    signal tristate    : std_logic := '0';

    signal   bit_counter     : unsigned(7 downto 0) := (others => '0');
    constant bit_counter_max : unsigned(7 downto 0) := to_unsigned(49, 8);

    signal data_sr   : std_logic_vector(15 downto 0);
    signal busy_sr   : std_logic_vector(15 downto 0);
    
	type t_rx_state is (rx_waiting, rx_receiving_data, rx_done);
    signal rx_state         : t_rx_state := rx_waiting;
    signal rx_fifo          : a_small_buffer;
    signal rx_wr_ptr        : unsigned(4 downto 0) := (others => '0');
    signal rx_wr_ptr_plus_1 : unsigned(4 downto 0) := (others => '0');
    signal rx_rd_ptr        : unsigned(4 downto 0) := (others => '0');


    signal rx_reset   : std_logic;
    signal rx_empty_i : std_logic := '0';
    signal rx_full    : std_logic := '0';
    signal rx_wr_data : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_wr_en   : std_logic := '0';

    signal rx_count    : unsigned(5 downto 0) := (others => '0');
    signal rx_buffer   : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_bits     : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_a_bit    : std_logic := '0';
    signal rx_last     : std_logic := '0';
    signal rx_synced   : std_logic := '0';
    signal rx_meta     : std_logic := '0';
    signal rx_raw      : std_logic := '0'; 
    signal rx_finished : std_logic := '0'; 
    signal rx_holdoff  : std_logic_vector(9 downto 0) :=(others => '0');
begin
    debug_pmod(3 downto 0) <= "000" & snoop;
    
    ----------------------------------------------
    -- Async logic for the FIFO state and pointers
    ----------------------------------------------
    rx_wr_ptr_plus_1 <= rx_wr_ptr+1;
    tx_wr_ptr_plus_1 <= tx_wr_ptr+1;
    rx_empty_i <= '1' when rx_wr_ptr   = rx_rd_ptr else '0';
    rx_full    <= '1' when rx_wr_ptr_plus_1 = rx_rd_ptr else '0';
    tx_empty   <= '1' when tx_wr_ptr   = tx_rd_ptr else '0';
    tx_full_i  <= '1' when tx_wr_ptr_plus_1 = tx_rd_ptr else '0';
    rx_empty <= rx_empty_i;
    tx_full  <= tx_full_i;
    busy <= '0' when tx_empty = '1' and tx_state = tx_idle else '1';
  
clk_proc: process(clk)
	begin
		if rising_edge(clk) then
         ----------------------------------
         -- Defaults, overwritten as needed
         ----------------------------------
         tx_rd_en <= '0';
         rx_reset <= '0';
         timeout  <= '0';
         
         -----------------------------------
         -- Is it time to send the next bit?
         -----------------------------------
         if bit_counter = bit_counter_max then
             
             bit_counter <= (others => '0');            
             serial_data <= data_sr(data_sr'high);
             tristate    <= not busy_sr(busy_sr'high);
             data_sr     <= data_sr(data_sr'high-1 downto 0) & '0';
             busy_sr     <= busy_sr(busy_sr'high-1 downto 0) & '0';
             ---------------------------------------------------
             -- Logic to signal the RX module ignore the data we
             -- are actually sending for 10 cycles. This is save 
             -- as the sync pattern is quite long.
             -------------------------------------------
             if tx_state = tx_waiting then 
                 rx_holdoff <= rx_holdoff(rx_holdoff'high-1 downto 0) & '0';
             else
                 rx_holdoff <= (others => '1');
             end if;

             --------------------------------------------------
             -- Debug signals that are presented to the outside
             --------------------------------------------------
             case tx_state is 
                 when tx_idle      => debug_pmod(7 downto 4) <= x"0";  
                 when tx_sync      => debug_pmod(7 downto 4) <= x"1";
                 when tx_start     => debug_pmod(7 downto 4) <= x"2";
                 when tx_send_data => debug_pmod(7 downto 4) <= x"3";
                 when tx_stop      => debug_pmod(7 downto 4) <= x"4";
                 when tx_flush     => debug_pmod(7 downto 4) <= x"5";
                 when tx_waiting   => debug_pmod(7 downto 4) <= x"6";
                 when others       => debug_pmod(7 downto 4) <= x"A";
             end case;

             -------------------------------------
             -- What to do with with the FSM state
             -------------------------------------
             if busy_sr(busy_sr'high-1) = '0' then
                 case tx_state is
                     when tx_idle =>
                        if tx_empty = '0' then
                           data_sr <= "0101010101010101";
                           busy_sr <= "1111111111111111";
                           tx_state <= tx_sync;
                        end if;
                     when tx_sync =>
                        data_sr <= "0101010101010101";
                        busy_sr <= "1111111111111111";
                        tx_state <= tx_start;
                     when tx_start => 
                        -----------------------------------------------------
                        -- Just send the start pattern.
                        --
                        -- The TX fifo must have something in it to get here.
                        -----------------------------------------------------
                        data_sr <= "1111000000000000";
                        busy_sr <= "1111111100000000";
                        tx_state <= tx_send_data;
                        rx_reset <= '1';
                        tx_rd_en <= '1';
                     when tx_send_data =>
                        data_sr <= tx_rd_data(7) & not tx_rd_data(7) & tx_rd_data(6) & not tx_rd_data(6)
                                 & tx_rd_data(5) & not tx_rd_data(5) & tx_rd_data(4) & not tx_rd_data(4)
                                 & tx_rd_data(3) & not tx_rd_data(3) & tx_rd_data(2) & not tx_rd_data(2)
                                 & tx_rd_data(1) & not tx_rd_data(1) & tx_rd_data(0) & not tx_rd_data(0);
                        busy_sr <= "1111111111111111";
                        if tx_empty = '1' then
                           -- Send this word, and follow it up with a STOP
                           tx_state <= tx_stop;
                        else
                           -- Send this word, and also read the next one from the FIFO
                           tx_rd_en <= '1';                                  
                        end if;
                     when tx_stop =>
                        ------------------------
                        -- Send the STOP pattern
                        ------------------------
                        data_sr    <= "1111000000000000";
                        busy_sr    <= "1111111100000000";
                        tx_state   <= tx_flush;
                     when tx_flush =>
                        ---------------------------------------------
                        -- Just wait here until we are no longer busy
                        ---------------------------------------------
                        tx_state <= tx_waiting;
                     when others => NULL;
                 end case;
             end if;
         else
             ------------------------------------
             -- Not time yet to send the next bit
             ------------------------------------
             bit_counter <= bit_counter + 1;
         end if;
         
         -----------------------------------------------
         -- How the RX process indicates that we are now 
         -- free to send another transaction
         -----------------------------------------------
         if tx_state = tx_waiting and rx_finished = '1' then
             tx_state <= tx_idle;
         end if;

			---------------------------------------------
		   -- Managing the TX FIFO 
         -- As soon as a word appears in the FIFO it 
         -- is sent. As it takes 8us to send a byte, the 
         -- FIFO can be filled quicker than data is sent,
         -- ensuring we don't have underrun the TX FIFO 
         -- and send a short message.
			---------------------------------------------
		   if tx_full_i = '0' and tx_wr_en = '1' then
             tx_fifo(to_integer(tx_wr_ptr)) <= tx_data;
				tx_wr_ptr <= tx_wr_ptr+1;
			end if;

			if tx_empty = '0' and tx_rd_en = '1' then
				tx_rd_data <= tx_fifo(to_integer(tx_rd_ptr));
				tx_rd_ptr  <= tx_rd_ptr + 1;
			end if;
         --------------------------------------------------  
		   -- Managing the RX FIFO 
         --
         -- The contents of the FIFO is reset during the TX
         -- of a new transaction. Pointer updates are
         -- seperated from the data read / writes to allow
         -- the reset to work.
         --------------------------------------------------
         if rx_full = '0' and rx_wr_en = '1' then
            rx_fifo(to_integer(rx_wr_ptr)) <= rx_wr_data;
         end if;

         if rx_empty_i = '0' and rx_rd_en = '1' then
            rx_data   <= rx_fifo(to_integer(rx_rd_ptr));
         end if;

         if rx_reset = '1' then
            rx_wr_ptr <= rx_rd_ptr;
         else
            if rx_full = '0' and rx_wr_en = '1' then
               rx_wr_ptr <= rx_wr_ptr+1;
            end if;

            if rx_empty_i = '0' and rx_rd_en = '1' then
               rx_rd_ptr <= rx_rd_ptr + 1;
            end if;
			end if;
        
			------------------------------------------
			-- Manage the timeout. If it is 
         -- waiting for a reply for over 400us then
         -- signal a timeout to the upper FSM.
			------------------------------------------
			if bit_counter = bit_counter_max then 
            if tx_state = tx_waiting and tx_state = tx_waiting then 
               if timeout_count = 39999 then
    			      tx_state      <= tx_idle;
    			      timeout       <= '1';
    		      else
    		          timeout_count <= timeout_count + 1;
  			      end if;
  			   else
  			      timeout_count <= (others => '0');
			   end if;
			end if;
		end if;
	end process;

i_IOBUFDS_0 : IOBUFDS
       generic map (
          DIFF_TERM => TRUE,
          IBUF_LOW_PWR => TRUE,
          IOSTANDARD => "DEFAULT",
          SLEW => "SLOW")
       port map (
          O   => rx_raw,
          IO  => dp_tx_aux_p,
          IOB => dp_tx_aux_n,
          I   => serial_data,
          T   => tristate
       );

rx_proc: process(clk)
    begin
        if rising_edge(clk) then   
            rx_wr_en    <= '0';
            rx_finished <= '0';
            
            ----------------------------------
            -- Is it time to sample a new half-bit?
            ----------------------------------
            if rx_count = 49 then  
                rx_a_bit <= '1';
                rx_buffer <= rx_buffer(rx_buffer'high-1 downto 0) & rx_synced;
                rx_bits   <= rx_bits(rx_bits'high-1 downto 0) & '1';
                rx_count <= (others => '0');
            else
                rx_count <= rx_count+1;
                rx_a_bit <= '0';
            end if;

            ----------------------------------------
            -- Have we just sampled a new half-bit?
            ----------------------------------------
            if rx_a_bit = '1' then 
                case rx_state is
                    when rx_waiting =>
                        -----------------------------------------------------
                        -- Are we seeing the end of the SYNC/START sequence?
                        -----------------------------------------------------
                        if rx_buffer = "0101010111110000" then
                            rx_bits <= (others => '0');
                            if rx_holdoff(rx_holdoff'high) = '0' then
                                 --------------------------------------
                                 -- Yes, switch to receiving bits, but,
                                 -- but only if the TX modules hasn't
                                 -- transmitted for a short while....
                                 --------------------------------------
                                rx_state <= rx_receiving_data;
                            end if;
                        end if;
                    when rx_receiving_data =>
                        ---------------------------------------------------------
                        -- Have we just received the 16th half-bit of the a byte?
                        ---------------------------------------------------------
                        if rx_bits(rx_bits'high) = '1' then
                            rx_bits <= (others => '0');
                            ------------------------------------------------
                            -- Are we missing transistions that are required
                            -- for valid data bytes?
                            --
                            -- Or in other words, is this an error or (more 
                            -- usually) the STOP pattern?
                            -------------------------------------------------
                            if rx_buffer(15) = rx_buffer(14) or rx_buffer(13) = rx_buffer(12) or
                               rx_buffer(11) = rx_buffer(10) or rx_buffer( 9) = rx_buffer( 8) or
                               rx_buffer( 7) = rx_buffer( 6) or rx_buffer( 5) = rx_buffer( 4) or
                               rx_buffer( 3) = rx_buffer( 2) or rx_buffer( 1) = rx_buffer( 0) then
                               ----------------------------------------------------------
                               -- Yes, We finished receiving data, or truncate any errors
                               ----------------------------------------------------------
                                rx_state <= rx_waiting;
                                if rx_holdoff(rx_holdoff'high) = '0' then
                                    rx_finished <= '1';
                                end if;
                            else
                                ---------------------------------------------------
                                -- Looks like a valid byte, so write it to the FIFO
                                ----------------------------------------------------
                                rx_wr_data <= rx_buffer(15) & rx_buffer(13) & rx_buffer(11) & rx_buffer(9)
                                            & rx_buffer( 7) & rx_buffer( 5) & rx_buffer( 3) & rx_buffer(1);
                                rx_wr_en <= '1';
                            end if;
                        end if;
                    when rx_done =>
                        null; -- waiting to be reset (so I ignore noise!)
                    when others =>
                        rx_state <= rx_waiting;
                    end case;
            end if;
            -------------------------------------------------
            -- Detect the change on the AUX line, and 
            -- make sure we sample the data mid-way through
            -- the half-bit (e.g 0.25us, 0.75us, 1.25 us...)
            -- from when the last transition was seen.
            ------------------------------------------------
            if rx_synced /= rx_last then
                rx_count <= to_unsigned(25, 6);
            end if;
            
            -------------------------------------------------
            -- The transmitted resets the RX FSM when it is
            -- sending a request. This is a counter measure
            -- against line noise when neigher end is driving
            -- the link.
            -------------------------------------------------
            if rx_reset = '1' then
                rx_state <= rx_waiting;
            end if;

            rx_last   <= rx_synced;
            ----------------------------
            -- Synchronise the RX signal
            ----------------------------
            rx_synced <= rx_meta;
            snoop     <= rx_meta;
            --------------------------------------------------------
            -- This is done to convert Zs or Xs in simulations to 0s
            --------------------------------------------------------
            if rx_raw = '1' then
                rx_meta <= '1';
            else
                rx_meta <= '0';
            end if;
        end if;
    end process;
    
-- Stub off the unused inputs
i_IOBUFDS_1 : IOBUFDS
      generic map (
         DIFF_TERM => FALSE,
         IBUF_LOW_PWR => TRUE,
         IOSTANDARD => "DEFAULT",
         SLEW => "SLOW")
      port map (
         O   => open,
         IO  => dp_rx_aux_p,
         IOB => dp_rx_aux_n,
         I   => '0',
         T   => '1'
      );

end architecture;