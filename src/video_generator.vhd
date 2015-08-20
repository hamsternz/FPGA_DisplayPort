----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.08.2015 21:08:13
-- Design Name: 
-- Module Name: video_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity video_generator is
    Port (  clk              : in  STD_LOGIC;
            h_visible_len    : in  std_logic_vector(11 downto 0) := (others => '0');
            h_blank_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            h_front_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            h_sync_len       : in  std_logic_vector(11 downto 0) := (others => '0');
            
            v_visible_len    : in  std_logic_vector(11 downto 0) := (others => '0');
            v_blank_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            v_front_len      : in  std_logic_vector(11 downto 0) := (others => '0');
            v_sync_len       : in  std_logic_vector(11 downto 0) := (others => '0');
            
            vid_blank        : out STD_LOGIC;
            vid_hsync        : out STD_LOGIC;
            vid_vsync        : out STD_LOGIC);
end video_generator;

architecture Behavioral of video_generator is
    signal h_counter : unsigned(11 downto 0) := (others => '0');
    signal v_counter : unsigned(11 downto 0) := (others => '0');
begin

process(clk)
    begin
        if rising_edge(clk) then
            -- Generate the sync and blanking signals
            if h_counter >= unsigned(h_front_len) and h_counter < unsigned(h_front_len) + unsigned(h_sync_len) then
                vid_hsync <= '1';
            else
                vid_hsync <= '0';
            end if;

            if v_counter >= unsigned(v_front_len) and v_counter < unsigned(v_front_len) + unsigned(v_sync_len) then
                vid_vsync <= '1';
            else
                vid_vsync <= '0';
            end if;
              
            if h_counter < unsigned(h_blank_len) or v_counter < unsigned(v_blank_len) then
                vid_blank <= '1';
            else
                vid_blank <= '0';
            end if;
            
            -- Manage the counters
            if h_counter = unsigned(h_visible_len)+unsigned(h_blank_len)-1 then
                h_counter <= (others => '0');
                if v_counter = unsigned(v_visible_len)+unsigned(v_blank_len)-1 then
                    v_counter <= (others => '0');
                else
                    v_counter <= v_counter+1;
                end if;
            else
                h_counter <= h_counter + 1;
            end if;
        end if;
    end process;
end Behavioral;
