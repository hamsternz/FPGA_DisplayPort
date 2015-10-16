----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:39:08 10/12/2015 
-- Design Name: 
-- Module Name:    capture_test - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity capture_test is
    Port ( clk40 : in  STD_LOGIC;
           dp_clk : in  STD_LOGIC;
           dp_ch0_data_0 : out  STD_LOGIC_VECTOR (8 downto 0);
           dp_ch0_data_1 : out  STD_LOGIC_VECTOR (8 downto 0));
end capture_test;

architecture Behavioral of capture_test is
   component test_800_600_source is
    Port ( clk40  : in  STD_LOGIC;
           hblank : out  STD_LOGIC;
           hsync  : out  STD_LOGIC;
           vblank : out  STD_LOGIC;
           vsync  : out  STD_LOGIC;
           data   : out  STD_LOGIC_VECTOR (23 downto 0));
   end component;

   component extract_timings is
    Port ( pixel_clk     : in  STD_LOGIC;
           pixel_hblank  : in  STD_LOGIC;
           pixel_hsync   : in  STD_LOGIC;
           pixel_vblank  : in  STD_LOGIC;
           pixel_vsync   : in  STD_LOGIC;
           
           --------------------------------------------------
           -- These should be stable when 'ready' is asserted
           --------------------------------------------------
           ready              : out std_logic;
           h_visible          : out STD_LOGIC_VECTOR (12 downto 0);
           v_visible          : out STD_LOGIC_VECTOR (12 downto 0);
           h_total            : out STD_LOGIC_VECTOR (12 downto 0);
           v_total            : out STD_LOGIC_VECTOR (12 downto 0);
           h_sync_width       : out STD_LOGIC_VECTOR (12 downto 0);
           v_sync_width       : out STD_LOGIC_VECTOR (12 downto 0);
           h_start            : out STD_LOGIC_VECTOR (12 downto 0);
           v_start            : out STD_LOGIC_VECTOR (12 downto 0);
           h_sync_active_high : out std_logic;
           v_sync_active_high : out std_logic);
   end component ;
   
   component pixel_receiver is
    Port ( pixel_clk     : in  STD_LOGIC;
           pixel_data    : in  STD_LOGIC_VECTOR (23 downto 0);
           pixel_hblank  : in  STD_LOGIC;
           pixel_hsync   : in  STD_LOGIC;
           pixel_vblank  : in  STD_LOGIC;
           pixel_vsync   : in  STD_LOGIC;
           
           h_visible     : in STD_LOGIC_VECTOR (12 downto 0);

           dp_clk        : in  STD_LOGIC;
           ch0_data_0 : out  STD_LOGIC_VECTOR (8 downto 0);
           ch0_data_1 : out  STD_LOGIC_VECTOR (8 downto 0));
   end component ;


   signal pixel_data    : STD_LOGIC_VECTOR (23 downto 0);
   signal pixel_hblank  : STD_LOGIC;
   signal pixel_hsync   : STD_LOGIC;
   signal pixel_vblank  : STD_LOGIC;
   signal pixel_vsync   : STD_LOGIC;

   signal ready         : std_logic;
   signal h_visible     : STD_LOGIC_VECTOR (12 downto 0);
   signal v_visible     : STD_LOGIC_VECTOR (12 downto 0);
   signal h_total       : STD_LOGIC_VECTOR (12 downto 0);
   signal v_total       : STD_LOGIC_VECTOR (12 downto 0);
   signal h_sync_width  : STD_LOGIC_VECTOR (12 downto 0);
   signal v_sync_width  : STD_LOGIC_VECTOR (12 downto 0);
   signal h_start       : STD_LOGIC_VECTOR (12 downto 0);
   signal v_start       : STD_LOGIC_VECTOR (12 downto 0);
   signal h_sync_active_high  : std_logic;
   signal v_sync_active_high  : std_logic;

begin
source: test_800_600_source 
   Port map (
      clk40  => clk40,
      hblank => pixel_hblank,
      hsync  => pixel_hsync,
      vblank => pixel_vblank,
      vsync  => pixel_vsync,
      data   => pixel_data);

timings: extract_timings
    Port map ( 
           pixel_clk     => clk40,
           pixel_hblank  => pixel_hblank,
           pixel_hsync   => pixel_hsync,
           pixel_vblank  => pixel_vblank,
           pixel_vsync   => pixel_vsync,
           
           --------------------------------------------------
           -- These should be stable when ready is asserted
           --------------------------------------------------
           ready         => ready,
           h_visible     => h_visible,
           v_visible     => v_visible,
           h_total       => h_total,
           v_total       => v_total,
           h_sync_width  => h_sync_width,
           v_sync_width  => v_sync_width,
           h_start       => h_start,
           v_start       => v_start,
           h_sync_active_high => h_sync_active_high,
           v_sync_active_high => v_sync_active_high);

capture: pixel_receiver
    Port map ( 
           pixel_clk     => clk40,
           pixel_data    => pixel_data,
           pixel_hblank  => pixel_hblank,
           pixel_hsync   => pixel_hsync,
           pixel_vblank  => pixel_vblank,
           pixel_vsync   => pixel_vsync,
           
           h_visible     => h_visible,
           
           dp_clk        => dp_clk,
           ch0_data_0    => dp_ch0_data_0,
           ch0_data_1    => dp_ch0_data_1);

end Behavioral;

