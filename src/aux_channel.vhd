----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz< 
-- 
-- Module Name: aux_channel - Behavioral
--
-- Description: A more usable interface for sending/receiving data over the 
--              DisplayPort AUX channel. It also implements the timeout.
--
------------------------------------------------------------------------------------
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

entity aux_channel is
		port ( 
		   clk                 : in    std_logic;
		   debug_pmod          : out   std_logic_vector(7 downto 0);
		   ------------------------------
           edid_de             : out   std_logic;
           dp_reg_de           : out   std_logic;
           adjust_de           : out   std_logic;
           status_de           : out   std_logic;
           aux_addr            : out   std_logic_vector(7 downto 0);
		   aux_data            : out   std_logic_vector(7 downto 0);
		   ------------------------------
		   link_count          : in    std_logic_vector(2 downto 0);
		   ------------------------------
           hpd_irq             : in    std_logic;
           hpd_present         : in    std_logic;
		   ------------------------------
		   tx_powerup          : out   std_logic := '0';
		   tx_clock_train      : out   std_logic := '0';
		   tx_align_train      : out   std_logic := '0';
		   tx_link_established : out   std_logic := '0';
		   -------------------------------
		   swing_0p4           : in    std_logic;
		   swing_0p6           : in    std_logic;
		   swing_0p8           : in    std_logic;
           preemp_0p0          : in    STD_LOGIC;
           preemp_3p5          : in    STD_LOGIC;
           preemp_6p0          : in    STD_LOGIC;
           clock_locked        : in    STD_LOGIC;
           equ_locked          : in    STD_LOGIC;
           symbol_locked       : in    STD_LOGIC;
           align_locked        : in    STD_LOGIC;
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
                    read_sink_count, read_registers,
                    -- Link configuration states 
                    set_channel_coding, set_speed_270, set_downspread, set_link_count_1, set_link_count_2, set_link_count_4, 
                    -- Link training - clock recovery
                    clock_training, clock_voltage_0p4,  clock_voltage_0p6, clock_voltage_0p8,  clock_wait, clock_test, clock_adjust, clock_wait_after,
                    -- Link training - alignment and preemphasis
                    align_training, 
                    align_p0_V0p4, align_p0_V0p6, align_p0_V0p8,
                    align_p1_V0p4, align_p1_V0p6, align_p1_V0p8,
                    align_p2_V0p4, align_p2_V0p6, align_p2_V0p8,
                    align_wait0,   align_wait1,   align_wait2,   align_wait3,
                    align_test,    align_adjust,  align_wait_after,   
                    -- Link up.
                    switch_to_normal, link_established,
                    --
                    check_link, check_wait
                    );
                    
                    
    signal state            : t_state               := error;
    signal next_state       : t_state               := error;
    signal state_on_success : t_state               := error;
    signal retry_now : std_logic             := '0';
	signal retry_count        : unsigned(26 downto 0) := (9=>'1',others => '0');   
    signal link_check_now : std_logic             := '0';
 	signal link_check_count        : unsigned(26 downto 0) := (9=>'1',others => '0');   
    signal count_100us      : unsigned(14 downto 0) := to_unsigned(1000,15);
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
           tx_wr_en     : in    std_logic;
           tx_data      : in    std_logic_vector(7 downto 0);
           tx_full      : out   std_logic;
           ------------------------------                                  
           rx_rd_en     : in    std_logic;
           rx_data      : out   std_logic_vector(7 downto 0);
           rx_empty     : out   std_logic;
           ------------------------------
           busy         : out   std_logic;
           timeout      : out   std_logic
         );
    end component;


    signal adjust_de_active : std_logic := '0';
    signal dp_reg_de_active : std_logic := '0';
    signal edid_de_active   : std_logic := '0';                
    signal status_de_active : std_logic := '0';                
	signal msg_de           : std_logic := '0';
	signal msg              : std_logic_vector(7 downto 0);
	signal msg_busy         : std_logic := '0';

    signal aux_tx_wr_en    : std_logic;
    signal aux_tx_data     : std_logic_vector(7 downto 0);

    signal aux_rx_rd_en    : std_logic;
    signal aux_rx_data     : std_logic_vector(7 downto 0);
    signal aux_rx_empty    : std_logic;

    signal link_count_sink : std_logic_vector(7 downto 0);
	
	signal channel_busy    : std_logic;
	signal channel_timeout : std_logic;
	
    signal expected             : unsigned(7 downto 0);
	signal rx_byte_count        : unsigned(7 downto 0) := (others => '0');
	signal aux_addr_i           : unsigned(7 downto 0)  := (others => '0');
    signal reset_addr_on_change : std_logic;
	
	signal just_read_from_rx :std_logic := '0';
    signal powerup_mask  : std_logic_vector(3 downto 0);
    signal debug_pmod_i  : std_logic_vector(7 downto 0);
begin
    debug_pmod(0) <= debug_pmod_i(0);
    debug_pmod(1) <= status_de_active;
    debug_pmod(2) <= adjust_de_active;
    
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
		   debug_pmod  => debug_pmod_i, 
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
		    -------------------------------------------
		    -- Are we going to change state this cycle?
		    -------------------------------------------
            msg_de <= '0';
             
            if next_state /= state then
                -------------------------------------------------------------
                -- Get ready to count how many reply bytes have been received
                -------------------------------------------------------------
                rx_byte_count <= (others => '0');
                
                ---------------------------------------------------
                -- Controlling which FSM state to go to on success
                ---------------------------------------------------
                case next_state is
                    when reset              => state_on_success <= check_presence;
                    when check_presence     => state_on_success <= edid_block0;                        
                    when edid_block0        => state_on_success <= edid_block1;
                    when edid_block1        => state_on_success <= edid_block2;
                    when edid_block2        => state_on_success <= edid_block3;
                    when edid_block3        => state_on_success <= edid_block4;
                    when edid_block4        => state_on_success <= edid_block5;
                    when edid_block5        => state_on_success <= edid_block6;
                    when edid_block6        => state_on_success <= edid_block7;
                    when edid_block7        => state_on_success <= read_sink_count;
                    when read_sink_count    => state_on_success <= read_registers;        
                    when read_registers     => state_on_success <= set_channel_coding;
                    when set_channel_coding => state_on_success <= set_speed_270;                        
                    when set_speed_270      => state_on_success <= set_downspread;                        
                    when set_downspread     => case link_count is
                                                   when "001"  => state_on_success <= set_link_count_1;                        
                                                   when "010"  => state_on_success <= set_link_count_2;                        
                                                   when "100"  => state_on_success <= set_link_count_4;
                                                   when others => state_on_success <= error;
                                               end case;
                    when set_link_count_1   => state_on_success <= clock_training; 
                    when set_link_count_2   => state_on_success <= clock_training; 
                    when set_link_count_4   => state_on_success <= clock_training; 
                    ------- Display Port clock training -------------------                        
                    when clock_training     => state_on_success <= clock_voltage_0p4;
                    when clock_voltage_0p4  => state_on_success <= clock_wait;
                    when clock_voltage_0p6  => state_on_success <= clock_wait;
                    when clock_voltage_0p8  => state_on_success <= clock_wait;
                    when clock_wait         => state_on_success <= clock_test;                        
                    when clock_test         => state_on_success <= clock_adjust;
                    when clock_adjust       => state_on_success <= clock_wait_after;
                    when clock_wait_after   => if clock_locked = '1' then
                                                   state_on_success <= align_training;
                                               elsif swing_0p8 = '1' then
                                                   state_on_success <= clock_voltage_0p8;
                                               elsif swing_0p6 = '1' then                 
                                                   state_on_success <= clock_voltage_0p6;
                                               else
                                                   state_on_success <= clock_voltage_0p4;
                                               end if;
                    ------- Display Port Alignment traning ------------                        
                    when align_training     => if swing_0p8 = '1' then
                                                    state_on_success <= align_p0_V0p8;
                                               elsif swing_0p6 = '1' then                        
                                                    state_on_success <= align_p0_V0p6;
                                               else 
                                                    state_on_success <= align_p0_V0p4;
                                               end if;
                    when align_p0_V0p4      => state_on_success <= align_wait0;
                    when align_p0_V0p6      => state_on_success <= align_wait0;
                    when align_p0_V0p8      => state_on_success <= align_wait0;
                    when align_p1_V0p4      => state_on_success <= align_wait0;
                    when align_p1_V0p6      => state_on_success <= align_wait0;
                    when align_p1_V0p8      => state_on_success <= align_wait0;
                    when align_p2_V0p4      => state_on_success <= align_wait0;
                    when align_p2_V0p6      => state_on_success <= align_wait0;
                    when align_p2_V0p8      => state_on_success <= align_wait0;
                    when align_wait0        => state_on_success <= align_wait1;                        
                    when align_wait1        => state_on_success <= align_wait2;                        
                    when align_wait2        => state_on_success <= align_wait3;                        
                    when align_wait3        => state_on_success <= align_test;                        
                    when align_test         => state_on_success <= align_adjust;                        
                    when align_adjust       => state_on_success <= align_wait_after;
                    when align_wait_after   => if symbol_locked = '1' then
                                                   state_on_success <= switch_to_normal;
                                               elsif swing_0p8 = '1' then
                                                   if preemp_6p0 = '1' then
                                                       state_on_success <= align_p2_V0p8;
                                                   elsif preemp_3p5 = '1' then
                                                       state_on_success <= align_p1_V0p8;
                                                   else
                                                       state_on_success <= align_p0_V0p8;
                                                   end if;
                                               elsif swing_0p6 = '1' then                 
                                                   if preemp_6p0 = '1' then
                                                       state_on_success <= align_p2_V0p6;
                                                   elsif preemp_3p5 = '1' then
                                                       state_on_success <= align_p1_V0p6;
                                                   else
                                                       state_on_success <= align_p0_V0p6;
                                                   end if;
                                               else
                                                   if preemp_6p0 = '1' then
                                                       state_on_success <= align_p2_V0p4;
                                                   elsif preemp_3p5 = '1' then
                                                       state_on_success <= align_p1_V0p4;
                                                   else
                                                       state_on_success <= align_p0_V0p4;
                                                   end if;
                                               end if;                        
                    when switch_to_normal   => state_on_success <= link_established;  
                    when link_established   => state_on_success <= link_established;
                    when check_link         => state_on_success <= check_wait;
                    when check_wait         => if clock_locked  = '1' and equ_locked = '1' and symbol_locked = '1' and align_locked = '1' then
                                                  state_on_success <= link_established;
                                               else
                                                  state_on_success <= error;
                                               end if; 
                    when error              => state_on_success <= error;

                    when others =>
                end case;

                ------------------------------------------------------------
                -- Controlling what message will be sent, how many words are 
                -- expected back, and where it will be routed
                --
                -- NOTE: If you set 'expected' incorrectly then bytes will
                --       get left in the RX FIFO, potentially corrupting things
                ------------------------------------------------------------
                msg_de           <= '1';
                status_de_active <= '0';
                adjust_de_active <= '0';
                dp_reg_de_active <= '0';
                edid_de_active   <= '0';
                reset_addr_on_change <= '0';                
                case next_state is
                    when reset                 => msg <= x"00"; expected <= x"00";
                    when check_presence        => msg <= x"01"; expected <= x"01"; reset_addr_on_change <= '1';

                    when edid_block0           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block1           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block2           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block3           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block4           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block5           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block6           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    when edid_block7           => msg <= x"02"; expected <= x"11"; edid_de_active <= '1';
                    
                    when read_sink_count       => msg <= x"03"; expected <= x"02"; reset_addr_on_change <= '1';
                    when read_registers        => msg <= x"04"; expected <= x"0D"; dp_reg_de_active <= '1';
                    when set_channel_coding    => msg <= x"06"; expected <= x"01"; 
                    when set_speed_270         => msg <= x"07"; expected <= x"01"; 
                    when set_downspread        => msg <= x"08"; expected <= x"01"; 
                    when set_link_count_1      => msg <= x"09"; expected <= x"01"; 
                    when set_link_count_2      => msg <= x"0A"; expected <= x"01"; 
                    when set_link_count_4      => msg <= x"0B"; expected <= x"01"; 
                    
                    when clock_training        => msg <= x"0C"; expected <= x"01"; 
                    when clock_voltage_0p4     => msg <= x"14"; expected <= x"01";
                    when clock_voltage_0p6     => msg <= x"16"; expected <= x"01";
                    when clock_voltage_0p8     => msg <= x"18"; expected <= x"01";
                    when clock_wait            => msg <= x"00"; expected <= x"00";  reset_addr_on_change <= '1';
                    when clock_test            => msg <= x"0D"; expected <= x"09";  status_de_active <= '1'; reset_addr_on_change <= '1';
                    when clock_adjust          => msg <= x"0E"; expected <= x"03";  adjust_de_active <= '1';
                    when clock_wait_after      => msg <= x"00"; expected <= x"00"; 
                    
                    when align_training        => msg <= x"0F"; expected <= x"01";
                    when align_p0_V0p4         => msg <= x"14"; expected <= x"01";
                    when align_p0_V0p6         => msg <= x"16"; expected <= x"01";
                    when align_p0_V0p8         => msg <= x"18"; expected <= x"01";
                    when align_p1_V0p4         => msg <= x"24"; expected <= x"01";
                    when align_p1_V0p6         => msg <= x"26"; expected <= x"01";
                    when align_p1_V0p8         => msg <= x"28"; expected <= x"01";
                    when align_p2_V0p4         => msg <= x"34"; expected <= x"01";
                    when align_p2_V0p6         => msg <= x"36"; expected <= x"01";
                    when align_p2_V0p8         => msg <= x"38"; expected <= x"01";
                    when align_wait0           => msg <= x"00"; expected <= x"00";
                    when align_wait1           => msg <= x"00"; expected <= x"00";
                    when align_wait2           => msg <= x"00"; expected <= x"00";
                    when align_wait3           => msg <= x"00"; expected <= x"00";  reset_addr_on_change <= '1';
                    when align_test            => msg <= x"0D"; expected <= x"09";  status_de_active <= '1'; reset_addr_on_change <= '1';
                    when align_adjust          => msg <= x"0E"; expected <= x"03";  adjust_de_active <= '1';
                    when align_wait_after      => msg <= x"00"; expected <= x"00";
                    when switch_to_normal      => msg <= x"11"; expected <= x"01";
                    when link_established      => msg <= x"00"; expected <= x"00"; reset_addr_on_change <= '1';
                    when check_link            => msg <= x"0D"; expected <= x"09"; status_de_active <= '1'; 
                    when check_wait            => msg <= x"00"; expected <= x"00";
                    when error                 => msg <= x"00";
                    when others                => msg <= x"00";
                end case;

                --------------------------------------------------------
                -- Set the control signals the state for the link state,  
                -- transceivers andmain channel pipeline 
                --------------------------------------------------------
                tx_powerup   <= '0'; 
                tx_clock_train <= '0'; 
                tx_align_train <= '0'; 
                tx_link_established <= '0';
                case next_state is
                    when clock_training        => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_voltage_0p4     => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_voltage_0p6     => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_voltage_0p8     => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_wait            => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_test            => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_adjust          => tx_powerup <= '1'; tx_clock_train <= '1';
                    when clock_wait_after      => tx_powerup <= '1'; tx_clock_train <= '1';
                    
                    when align_training        => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p0_V0p4         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p0_V0p6         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p0_V0p8         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p1_V0p4         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p1_V0p6         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p1_V0p8         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p2_V0p4         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p2_V0p6         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_p2_V0p8         => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_wait0           => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_wait1           => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_wait2           => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_wait3           => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_test            => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_adjust          => tx_powerup <= '1'; tx_align_train <= '1';
                    when align_wait_after      => tx_powerup <= '1'; tx_align_train <= '1';
                    when switch_to_normal      => tx_powerup <= '1';
                    when link_established      => tx_powerup <= '1'; tx_link_established <= '1';
                    when check_link            => tx_powerup <= '1'; tx_link_established <= '1';
                    when check_wait            => tx_powerup <= '1'; tx_link_established <= '1';
                    when others                => NULL;
                end case;
            end if;

            --------------------------------------------------------
            -- Manage the small timer that counts how long we have 
            -- been in the current state (used for implementing 
            -- short waits for some FSM states) 
            --------------------------------------------------------
            if state = next_state then
                count_100us <= count_100us - 1;
            else
                count_100us <= to_unsigned(9999,15);                                        
                if reset_addr_on_change = '1' then
                    aux_addr_i <= (others => '0'); 
                end if;                                       
            end if;
            state <= next_state;
            
            -------------------------------------------------------------
            -- How a short wait is implemented...
            --
            -- Has the 100us pause expired, when no data was expected?
            -- If so, move to the next test.            
            -------------------------------------------------------------
            if expected = x"00" and count_100us(count_100us'high) = '1' then
                next_state <= state_on_success;
            end if;
            
            --------------------------------------------------------------
            -- Processing the data that has been received from the sink
            -- over the AUX channel. The data bytes are just streamed out
            -- to a downstream component that uses the values, and may 
            -- set flags that feed back in to control the FSM.
            --------------------------------------------------------------
            edid_de    <= '0';
            adjust_de  <= '0';
            dp_reg_de  <= '0';                                
            status_de  <= '0';
            if channel_busy = '0' then
                if just_read_from_rx = '1' then
                    -- Is this a short read?
                    if rx_byte_count /= expected-1 and aux_rx_empty = '1' then 
                        next_state <= error;
                    end if;
                                        
                    if rx_byte_count = x"00" then
                        --------------------------------------------------
                        -- Is the Ack missing? This doesn't work correctly
                        -- if only byte is expected, as it gets overwritten 
                        -- by the following 'if' statement.
                        --
                        -- Do not change this behaviour, by what it should do
                        -- is test for "In progress" or "Again" requests, and 
                        -- retry the current operation.
                        ------------------------------------------------------ 
                        if aux_rx_data /= x"00" then  
                            next_state <= error;
                        end if;
                        if rx_byte_count = expected-1 and aux_rx_empty = '1' then
                            next_state <= state_on_success;
                        end if;
                        ----------------------------------------------
                        -- Has the Sink indicated that we should retry
                        -- the current command, to allow the sink time
                        -- to process the request?
                        --
                        -- This only works if there is just one byte
                        -- in the FIFO. This only works for DPCD
                        -- transactions that aeert "AUX DEFER"
                        ----------------------------------------------
                        if aux_rx_data = x"20" then
                           -- just flip states to force a retry.
                            state      <= state_on_success;
                            next_state <= state;  
                        end if;
                    else
                        -------------------------------------------------------------------
                        -- Process a non-ack data byte, routing it out using the DE signals
                        -------------------------------------------------------------------
                        edid_de    <= edid_de_active;
                        adjust_de  <= adjust_de_active;
                        dp_reg_de  <= dp_reg_de_active;                                
                        status_de  <= status_de_active;                                

                        aux_data   <= aux_rx_data;
                        aux_addr   <= std_logic_vector(aux_addr_i);
                        aux_addr_i <= aux_addr_i+1;                        
                        
                        if rx_byte_count = expected-1 and aux_rx_empty = '1' then
                            next_state <= state_on_success;
                            if reset_addr_on_change = '1' then
                                aux_addr_i <= (others => '0'); 
                            end if;                                       
                        end if;
                    end if;
                end if;
            end if;

            -----------------------------------------------------
            -- Manage the AUX channel timeout and the retry to  
            -- establish a link. 
            -------------------------------------------------------------                            
--            if channel_timeout = '1' or (state /= reset and state /= link_established and retry_now = '1') then
            if channel_timeout = '1' or (state /= reset      and state /= link_established and 
			 	                             state /= check_link and  state /= check_wait      and retry_now = '1') then
                next_state <= reset;
                state      <= error;
            end if;
            
            -------------------------------------------------
            -- If the link was established, then every 
            -- now and then check the state of the link  
            -------------------------------------------------
            if state = link_established and link_check_now = '1' then
                next_state <= check_link;  
            end if;

            -------------------------------------------------
            -- If the full message has been received, then 
            -- read any waiting data out of the FIFO.
            -- Also update the count of bytes read.
            -------------------------------------------------
            if channel_busy = '0' and aux_rx_empty = '0' then
                just_read_from_rx <= '1';
            else                
                just_read_from_rx <= '0';
            end if;
            if just_read_from_rx = '1' then
                rx_byte_count <= rx_byte_count+1;
            end if;

            -----------------------------------------
            -- Manage the reset timer
            -----------------------------------------
			if retry_count = 0 then
			  retry_now   <= '1';
			  retry_count <= to_unsigned(49999999,27);
			else
			  retry_now   <= '0';
			  retry_count <= retry_count - 1;
			end if;
			if link_check_count = 0 then
	--		  link_check_now   <= '1';
			  -- PPS actually became a 2Hz pulse....
			  link_check_count <= to_unsigned(99999999,27);
			else
			  link_check_now   <= '0';
			  link_check_count <= link_check_count - 1;
			end if;
		end if;		
	end process;
end architecture;