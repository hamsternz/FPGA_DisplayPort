----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:51:54 10/02/2015 
-- Design Name: 
-- Module Name:    gtpa1_dual_reset_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gtpa1_dual_reset_controller is
    Port ( -- control signals
           clk               : in  STD_LOGIC;
           powerup_refclk    : in  std_logic;
           powerup_pll       : in  std_logic;
           required_pll_lock : in  std_logic; -- PLL lock for the one that is driving this GTP
           usrclklock        : in  STD_LOGIC; -- PLL lock for the USRCLK/USRCLK2 clock signals
           powerup_channel   : in  STD_LOGIC;
           tx_running        : out STD_LOGIC;
           -- link to GTP signals
           refclken          : out STD_LOGIC;
           pllpowerdown      : out STD_LOGIC;
           plllock           : in  STD_LOGIC;
           plllocken         : out STD_LOGIC;
           gtpreset          : out STD_LOGIC;
           txreset           : out STD_LOGIC;
           txpowerdown       : out STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
           gtpresetdone      : in  STD_LOGIC);
end gtpa1_dual_reset_controller;

architecture Behavioral of gtpa1_dual_reset_controller is
   -- Next two are set to none-zero values to speed up simulation
   signal count_pll     : unsigned(15 downto 0) := (6=>'0',others => '1');
   signal count_channel : unsigned(15 downto 0) := (6=>'0',others => '1'); -- enough for 120us @ 100MHz 
   signal pll_state     : std_logic_vector(1 downto 0) := (others => '0');
   signal channel_state : std_logic_vector(1 downto 0) := (others => '0');
   signal gtpreset_for_pll : std_logic;
   signal gtpreset_for_ch : std_logic;

begin   
   refclken <= powerup_refclk;
   gtpreset <= gtpreset_for_pll and gtpreset_for_ch;

pll_fsm: process(clk) 
   begin
      if rising_edge(clk) then
         --------------------------------------------
         -- Turn on the PLLs if either channel needed
         --------------------------------------------
         if count_pll(count_pll'high) = '0' then
             count_pll <= count_pll + 1;
         end if;
         case pll_state is
            when "00"  =>  -- Disabled
               pllpowerdown <= '1';
               plllocken    <= '0';
               gtpreset_for_pll <= '1';

               if powerup_pll = '1' and count_pll(count_pll'high) = '1' then
                  pll_state <= "01";
                  count_pll <= (others => '0');
               end if;

            when "01"  =>  -- Power up PLLs
               pllpowerdown <= '0';
               plllocken    <= '1';
               gtpreset_for_pll <= '0';

               if plllock = '1' then
                  pll_state <= "10";
               elsif count_pll(count_pll'high) = '1' then  -- timeout, so retry
                  pll_state <= "00";
                  count_pll <= (6=>'0', others => '1');
               end if;

            when "10" => -- PLL running - look for lost lock
               pllpowerdown <= '0';
               plllocken    <= '1';
               gtpreset_for_pll <= '0';
               if plllock = '0' or powerup_pll = '0' then
                  pll_state <= "00";
                  count_pll <= (6=>'0', others => '1');
               end if;
            when others =>
               pllpowerdown <= '1';
               plllocken    <= '0';
               pll_state    <= "00";
               gtpreset_for_pll <= '1';
               count_pll <= (6=>'0', others => '1');
         end case;
      end if;
   end process;

channel_fsm: process(clk) 
   begin
      if rising_edge(clk) then
         ----------------------------------------------------
         -- Turn on the PLLs if either channel needs to be on
         ----------------------------------------------------
         
         if count_channel(count_channel'high) = '0' then
             count_channel <= count_channel + 1;
         end if;
         case channel_state is
            when "00"  =>  -- Disabled
               tx_running   <= '0';
               gtpreset_for_ch <= '1';
               txreset      <= '1';
               txpowerdown  <= "11";

               if powerup_channel = '1' and count_channel(count_channel'high) = '1' and required_pll_lock = '1' and usrclklock = '1' then
                  channel_state <= "10"; ---Note skipping looking for RESETDONE
                  count_channel <= (others => '0');
               end if;

            when "01"  =>  -- Power up the channel 
               tx_running   <= '0';
               gtpreset_for_ch     <= '0';
               txreset      <= '0';
               txpowerdown  <= "00";

               if gtpresetdone = '1' then
                  channel_state <= "10";
                  count_channel <= (others => '0');
               elsif count_channel(count_channel'high) = '1' or required_pll_lock = '0' or powerup_channel = '0' or usrclklock = '0' then 
                  -- timeout, or switch the channel off
                  channel_state <= "00";
                  count_channel <= (6=>'0', others => '1');
               end if;

            when "10" => -- Channel up and running
               tx_running      <= '1';
               gtpreset_for_ch <= '0';
               txreset         <= '0';
               txpowerdown     <= "00";

               if required_pll_lock = '0' or powerup_channel = '0' or usrclklock = '0' then 
                  -- Lock lost or channel to be dropped
                  channel_state <= "00";
                  count_channel <= (6=>'0', others => '1');
               end if;

            when others => --- error state
               tx_running    <= '0';
               txreset       <= '1';
               gtpreset_for_ch <= '1';
               txpowerdown   <= "11";
               channel_state <= "00";
               count_channel <= (6=>'0', others => '1');
         end case;
      end if;
   end process;

end Behavioral;

