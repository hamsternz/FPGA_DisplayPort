----------------------------------------------------------------------------------
-- Module Name: transceiver_gtp_dual - Behavioral
--
-- Description: A wrapper around the Xilinx Spartan 6 GTP Dual transceiver
-- 
----------------------------------------------------------------------------------
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
--  0.2 | 2015-09-18 | Move bit reordering here from the 8b/10b encoder
--  0.3 | 2015-09-30 | Created version for Spartan 6
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Transceiver is
    generic( use_hw_8b10b_support : std_logic := '0');
    Port ( mgmt_clk        : in  STD_LOGIC;
           powerup_channel : in  STD_LOGIC_VECTOR(3 downto 0);
           debug           : out std_logic_vector(7 downto 0);

           preemp_0p0      : in  STD_LOGIC;
           preemp_3p5      : in  STD_LOGIC;
           preemp_6p0      : in  STD_LOGIC;
           
           swing_0p4       : in  STD_LOGIC;
           swing_0p6       : in  STD_LOGIC;
           swing_0p8       : in  STD_LOGIC;

           tx_running      : out STD_LOGIC_VECTOR := (others => '0');

           symbolclk       : out STD_LOGIC;
           in_symbols      : in  std_logic_vector(79 downto 0);
                      
           gtptxp         : out std_logic_vector(3 downto 0);
           gtptxn         : out std_logic_vector(3 downto 0));
end transceiver;

architecture Behavioral of transceiver is
    signal gclk135            : STD_LOGIC;
    signal gclk135_unbuffered : STD_LOGIC;
    signal clkfb_for_135      : STD_LOGIC;

    signal powerup_pll     : std_logic_vector( 3 downto 0)  := "1111";
    signal powerup_refclk  : std_logic_vector( 3 downto 0)  := "1000";

    signal txdata_for_tx0  :   std_logic_vector(31 downto 0) := (others => '0');
    signal txchardispmode0 :   std_logic_vector( 3 downto 0) := (others => '0');
    signal txchardispval0  :   std_logic_vector( 3 downto 0) := (others => '0'); -- Note Forces negative disparity.
    signal is_kchar_tx0    :   std_logic_vector( 3 downto 0) := (others => '0');

    signal txdata_for_tx1  :   std_logic_vector(31 downto 0) := (others => '0');
    signal txchardispmode1 :   std_logic_vector( 3 downto 0) := (others => '0');
    signal txchardispval1  :   std_logic_vector( 3 downto 0) := (others => '0');
    signal is_kchar_tx1    :   std_logic_vector( 3 downto 0) := (others => '0');

    signal txdata_for_tx2  :   std_logic_vector(31 downto 0) := (others => '0');
    signal txchardispmode2 :   std_logic_vector( 3 downto 0) := (others => '0');
    signal txchardispval2  :   std_logic_vector( 3 downto 0) := (others => '0');
    signal is_kchar_tx2    :   std_logic_vector( 3 downto 0) := (others => '0');

    signal txdata_for_tx3  :   std_logic_vector(31 downto 0) := (others => '0');
    signal txchardispmode3 :   std_logic_vector( 3 downto 0) := (others => '0');
    signal txchardispval3  :   std_logic_vector( 3 downto 0) := (others => '0');
    signal is_kchar_tx3    :   std_logic_vector( 3 downto 0) := (others => '0');
  
    component gtpa1_dual_reset_controller is
    port ( clk               : in  STD_LOGIC;
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
           txpowerdown       : out STD_LOGIC_VECTOR(1 downto 0);
           gtpresetdone      : in  STD_LOGIC);
    end component;

    signal refclk        : std_logic_vector(3 downto 0);

    signal pllpowerdown  : std_logic_vector(3 downto 0);
    signal plllock       : std_logic_vector(3 downto 0);
    signal plllocken     : std_logic_vector(3 downto 0);
    signal gtpreset      : std_logic_vector(3 downto 0);
    signal txpowerdown   : std_logic_vector(7 downto 0);
    signal txreset       : std_logic_vector(3 downto 0);
    signal txresetdone   : std_logic_vector(3 downto 0);
    signal gtpresetdone  : std_logic_vector(3 downto 0);
    signal pll_in_use    : std_logic_vector(3 downto 0);
    signal gtpclkout     : std_logic_vector(7 downto 0);
    signal preemp_level   : std_logic_vector(2 downto 0); 
    signal swing_level    : std_logic_vector(3 downto 0); 

    signal txoutclk          : STD_LOGIC_vector(gtptxp'length-1 downto 0);

    signal txusrclk_u         : STD_LOGIC;
    signal txusrclk_buffered  : STD_LOGIC;
    signal txusrclk2_u        : STD_LOGIC;
    signal txusrclk2_buffered : STD_LOGIC;

    signal gtpclkout_buffered : STD_LOGIC;
    signal gtpclkout_divided  : STD_LOGIC;

    signal dcm_reset_sr       : STD_LOGIC_vector(3 downto 0);
    
    signal out_ref_clk    : std_logic_vector(3 downto 0);
    signal testlock0      : std_logic;
    signal testlock1      : std_logic;
    signal usrclklock     : std_logic;
begin

pll_gen135: PLL_BASE generic map (
      BANDWIDTH            => "HIGH",
      CLK_FEEDBACK         => "CLKFBOUT",
      COMPENSATION         => "INTERNAL",
      DIVCLK_DIVIDE        => 5,
      CLKFBOUT_MULT        => 54,
      CLKFBOUT_PHASE       => 0.000,
      CLKOUT0_DIVIDE       => 8,
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKIN_PERIOD         => 10.0,
      REF_JITTER           => 0.010)
   port map (
      CLKFBOUT            => clkfb_for_135,
      CLKOUT0             => gclk135_unbuffered,
      CLKOUT1             => open,
      CLKOUT2             => open,
      CLKOUT3             => open,
      CLKOUT4             => open,
      CLKOUT5             => open,
      LOCKED              => open,
      RST                 => '0',
      -- Input clock control
      CLKFBIN             => clkfb_for_135,
      CLKIN               => mgmt_clk);

gclk135_buf : BUFG
   port map (
      O   => gclk135,
      I   => gclk135_unbuffered
   );

    pll_in_use <= (0=>'1', others => '1');
    
    symbolclk    <= txusrclk2_buffered;
    
    preemp_level <= "110" when preemp_6p0 = '1' else   -- +6.0 db from table 3-30 in UG476
                    "100" when preemp_3p5 = '1' else   -- +3.5 db
                    "000";                             -- +0.0 db

    swing_level  <= "0110" when swing_0p8 = '1' else     -- 0.762 V (should be 0.8)
                    "0100" when swing_0p6 = '1' else     -- 0.578 V (should be 0.6)
                    "0011";                              -- 0.487 V + plus a bit more (should be 0.4)
   
i_bufg_txusrclk: BUFG PORT MAP (
        i => txusrclk_u,
        o => txusrclk_buffered
    );

i_bufg_txusrclk2: BUFG PORT MAP (
        i => txusrclk2_u,
        o => txusrclk2_buffered
    );

i_bufg_io2: BUFIO2 GENERIC MAP (
         DIVIDE => 1         
    ) PORT MAP (
        i => gtpclkout(0),
        ioclk => open,
        divclk => gtpclkout_buffered,
        serdesstrobe => open
    );
    
    debug(0) <= plllock(0);
    debug(1) <= plllock(1);
    debug(2) <= plllock(2);
    debug(3) <= plllock(3);
    debug(4) <= '1';
    debug(5) <= '1';
    debug(6) <= '1';
    debug(7) <= '1';
    
process(mgmt_clk, plllock(0))
   -- The DCM reset must be asserted for at least 3 cycles after
   -- the GTP PLL gets lock
   begin
      if plllock(0) = '0' then
         dcm_reset_sr <= (others => '1');
      elsif rising_edge(mgmt_clk) then
         dcm_reset_sr <= '0' & dcm_reset_sr(dcm_reset_sr'high downto 1);
      end if;
   end process;

DCM_SP_inst : DCM_SP
   generic map (
      CLKDV_DIVIDE => 2.0,
      CLKFX_DIVIDE => 4,
      CLKFX_MULTIPLY => 2, 
      CLKIN_DIVIDE_BY_2 => FALSE,
      CLKIN_PERIOD => 3.7,
      CLKOUT_PHASE_SHIFT => "NONE", 
      CLK_FEEDBACK => "1X",
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
      DFS_FREQUENCY_MODE => "LOW",
      DLL_FREQUENCY_MODE => "LOW",
      DSS_MODE => "NONE",
      DUTY_CYCLE_CORRECTION => TRUE,
      FACTORY_JF => X"c080",
      PHASE_SHIFT => 0,
      STARTUP_WAIT => FALSE
   )
   port map (
      CLK0     => txusrclk_u,
      CLK180   => open,
      CLK270   => open,
      CLK2X    => open, 
      CLK2X180 => open,
      CLK90    => open,   
      CLKDV    => txusrclk2_u,
      CLKFX    => open,
      CLKFX180 => open,
      LOCKED   => usrclklock,
      PSDONE   => open,
      STATUS   => open,
      CLKFB    => txusrclk_u,
      CLKIN    => gtpclkout_buffered, 
      DSSEN    => '0',
      PSCLK    => '0',
      PSEN     => '0',
      PSINCDEC => '0',
      RST      => dcm_reset_sr(0) 
   );
    
Inst_gtpa1_dual_reset_controller0: gtpa1_dual_reset_controller PORT MAP(
		clk               => mgmt_clk,
      powerup_pll       => powerup_pll(0),
      powerup_refclk    => powerup_refclk(0),
		powerup_channel   => powerup_channel(0),
		tx_running        => tx_running(0),
		pllpowerdown      => pllpowerdown(0),
		plllock           => plllock(0),
		plllocken         => plllocken(0),
      required_pll_lock => plllock(0),
      usrclklock        => usrclklock,
		gtpreset          => gtpreset(0),
		txreset           => txreset(0),
		txpowerdown       => txpowerdown(0*2+1 downto 0*2),
		gtpresetdone      => gtpresetdone(0) 
	);

Inst_gtpa1_dual_reset_controller1: gtpa1_dual_reset_controller PORT MAP(
		clk               => mgmt_clk,
      powerup_pll       => powerup_pll(1),
      powerup_refclk    => powerup_refclk(1),
		powerup_channel   => powerup_channel(1),
		tx_running        => tx_running(1),
		pllpowerdown      => pllpowerdown(1),
		plllock           => plllock(1),
		plllocken         => plllocken(1),
      required_pll_lock => plllock(0),  -- Clocked from PLL0 in the first tile
      usrclklock        => usrclklock,
		gtpreset          => gtpreset(1),
		txreset           => txreset(1),
		txpowerdown       => txpowerdown(1*2+1 downto 1*2),
		gtpresetdone      => gtpresetdone(1) 
	);

Inst_gtpa1_dual_reset_controller2: gtpa1_dual_reset_controller PORT MAP(
		clk               => mgmt_clk,
      powerup_pll       => powerup_pll(2),
      powerup_refclk    => powerup_refclk(2),
		powerup_channel   => powerup_channel(2),
		tx_running        => tx_running(2),
		pllpowerdown      => pllpowerdown(2),
		plllock           => plllock(2),
		plllocken         => plllocken(2),
      required_pll_lock => plllock(2),
      usrclklock        => usrclklock,
		gtpreset          => gtpreset(2),
		txreset           => txreset(2),
		txpowerdown       => txpowerdown(2*2+1 downto 2*2),
		gtpresetdone      => gtpresetdone(2) 
	);

Inst_gtpa1_dual_reset_controller3: gtpa1_dual_reset_controller PORT MAP(
		clk               => mgmt_clk,
      powerup_pll       => powerup_pll(3),
      powerup_refclk    => powerup_refclk(3),
		powerup_channel   => powerup_channel(3),
		tx_running        => tx_running(3),
		pllpowerdown      => pllpowerdown(3),
		plllock           => plllock(3),
		plllocken         => plllocken(3),
      required_pll_lock => plllock(2),   -- Clocked from PLL0 in the second tile
      usrclklock        => usrclklock,
		gtpreset          => gtpreset(3),
		txreset           => txreset(3),
		txpowerdown       => txpowerdown(3*2+1 downto 3*2),
		gtpresetdone      => gtpresetdone(3) 
	);

g_soft_8b10b: if use_hw_8b10b_support  = '0' generate 
    ---------------------------------------------------
    -- Data mapping when the input is raw binary values 
    ---------------------------------------------------
    -- First channel
    ---------------------------------------------------
    txdata_for_tx0( 0) <= in_symbols( 9);
    txdata_for_tx0( 1) <= in_symbols( 8);
    txdata_for_tx0( 2) <= in_symbols( 7);
    txdata_for_tx0( 3) <= in_symbols( 6);
    txdata_for_tx0( 4) <= in_symbols( 5);
    txdata_for_tx0( 5) <= in_symbols( 4);
    txdata_for_tx0( 6) <= in_symbols( 3);
    txdata_for_tx0( 7) <= in_symbols( 2);
    txchardispval0 (0) <= in_symbols( 1);
    txchardispmode0(0) <= in_symbols( 0);

    txdata_for_tx0( 8) <= in_symbols(19);
    txdata_for_tx0( 9) <= in_symbols(18);
    txdata_for_tx0(10) <= in_symbols(17);
    txdata_for_tx0(11) <= in_symbols(16);
    txdata_for_tx0(12) <= in_symbols(15);
    txdata_for_tx0(13) <= in_symbols(14);
    txdata_for_tx0(14) <= in_symbols(13);
    txdata_for_tx0(15) <= in_symbols(12);
    txchardispval0 (1) <= in_symbols(11);
    txchardispmode0(1) <= in_symbols(10);
    
    ---------------------------------------------------
    -- Second channel
    ---------------------------------------------------
    txdata_for_tx1( 0) <= in_symbols(29);
    txdata_for_tx1( 1) <= in_symbols(28);
    txdata_for_tx1( 2) <= in_symbols(27);
    txdata_for_tx1( 3) <= in_symbols(26);
    txdata_for_tx1( 4) <= in_symbols(25);
    txdata_for_tx1( 5) <= in_symbols(24);
    txdata_for_tx1( 6) <= in_symbols(23);
    txdata_for_tx1( 7) <= in_symbols(22);
    txchardispval1 (0) <= in_symbols(21);
    txchardispmode1(0) <= in_symbols(20);

    txdata_for_tx1( 8) <= in_symbols(39);
    txdata_for_tx1( 9) <= in_symbols(38);
    txdata_for_tx1(10) <= in_symbols(37);
    txdata_for_tx1(11) <= in_symbols(36);
    txdata_for_tx1(12) <= in_symbols(35);
    txdata_for_tx1(13) <= in_symbols(34);
    txdata_for_tx1(14) <= in_symbols(33);
    txdata_for_tx1(15) <= in_symbols(32);
    txchardispval1 (1) <= in_symbols(31);
    txchardispmode1(1) <= in_symbols(30);

    
    ---------------------------------------------------
    -- Third channel
    ---------------------------------------------------
    txdata_for_tx2( 0) <= in_symbols(49);
    txdata_for_tx2( 1) <= in_symbols(48);
    txdata_for_tx2( 2) <= in_symbols(47);
    txdata_for_tx2( 3) <= in_symbols(46);
    txdata_for_tx2( 4) <= in_symbols(45);
    txdata_for_tx2( 5) <= in_symbols(44);
    txdata_for_tx2( 6) <= in_symbols(43);
    txdata_for_tx2( 7) <= in_symbols(42);
    txchardispval2 (0) <= in_symbols(41);
    txchardispmode2(0) <= in_symbols(40);

    txdata_for_tx2( 8) <= in_symbols(59);
    txdata_for_tx2( 9) <= in_symbols(58);
    txdata_for_tx2(10) <= in_symbols(57);
    txdata_for_tx2(11) <= in_symbols(56);
    txdata_for_tx2(12) <= in_symbols(55);
    txdata_for_tx2(13) <= in_symbols(54);
    txdata_for_tx2(14) <= in_symbols(53);
    txdata_for_tx2(15) <= in_symbols(52);
    txchardispval2 (1) <= in_symbols(51);
    txchardispmode2(1) <= in_symbols(50);
    
    -------------------------------------
    -- Fourth channel    
    -------------------------------------
    txdata_for_tx3( 0) <= in_symbols(69);
    txdata_for_tx3( 1) <= in_symbols(68);
    txdata_for_tx3( 2) <= in_symbols(67);
    txdata_for_tx3( 3) <= in_symbols(66);
    txdata_for_tx3( 4) <= in_symbols(65);
    txdata_for_tx3( 5) <= in_symbols(64);
    txdata_for_tx3( 6) <= in_symbols(63);
    txdata_for_tx3( 7) <= in_symbols(62);
    txchardispval3 (0) <= in_symbols(61);
    txchardispmode3(0) <= in_symbols(60);

    txdata_for_tx3( 8) <= in_symbols(79);
    txdata_for_tx3( 9) <= in_symbols(78);
    txdata_for_tx3(10) <= in_symbols(77);
    txdata_for_tx3(11) <= in_symbols(76);
    txdata_for_tx3(12) <= in_symbols(75);
    txdata_for_tx3(13) <= in_symbols(74);
    txdata_for_tx3(14) <= in_symbols(73);
    txdata_for_tx3(15) <= in_symbols(72);
    txchardispval3 (1) <= in_symbols(71);
    txchardispmode3(1) <= in_symbols(70);
end generate;

g_hard_8b10b: if use_hw_8b10b_support  = '1' generate  
    ---------------------------------------------------
    -- Data mapping when the input is raw binary values 
    ---------------------------------------------------
    -- First channel
    txdata_for_tx0( 7 downto 0) <= in_symbols( 7 downto 0);
    is_kchar_tx0(0)             <= in_symbols( 8);
    txchardispval0(0)           <= in_symbols( 9);
    txchardispmode0(0)          <= '0';

    txdata_for_tx0(15 downto 8) <= in_symbols(17 downto 10);
    is_kchar_tx0(1)             <= in_symbols(18);
    txchardispval0(1)           <= in_symbols(19);
    txchardispmode0(1)          <= '0';

    -- Second channel
    txdata_for_tx1( 7 downto 0) <= in_symbols(27 downto 20);
    is_kchar_tx1(0)             <= in_symbols(28);
    txchardispmode1(0)          <= in_symbols(29); --force neg (txchardispval is 0)

    txdata_for_tx1(15 downto 8) <= in_symbols(37 downto 30);
    is_kchar_tx1(1)             <= in_symbols(38);
    txchardispmode1(1)          <= in_symbols(39); --force neg (txchardispval is 0)

    -- Third channel
    txdata_for_tx2( 7 downto 0) <= in_symbols(47 downto 40);
    is_kchar_tx2(0)             <= in_symbols(48);
    txchardispmode2(0)          <= in_symbols(49); --force neg (txchardispval is 0)

    txdata_for_tx2(15 downto 8) <= in_symbols(57 downto 50);
    is_kchar_tx2(1)             <= in_symbols(58);
    txchardispmode2(1)          <= in_symbols(59); --force neg (txchardispval is 0)

    -- Fourth channel
    txdata_for_tx3( 7 downto 0) <= in_symbols(67 downto 60);
    is_kchar_tx3(0)             <= in_symbols(68);
    txchardispmode3(0)          <= in_symbols(69); --force neg (txchardispval is 0)

    txdata_for_tx3(15 downto 8) <= in_symbols(77 downto 70);
    is_kchar_tx3(1)             <= in_symbols(78);
    txchardispmode3(1)          <= in_symbols(79);  --force neg (txchardispval is 0)
end generate;

   ----------------------------- GTPA1_DUAL Instance X0Y0 --------------------------   
   -- This is the driver for Display port channels 3 and 2.
   --
   -- The reference clock goes into the DisplayPort RX tile, so
   -- it needs to be configured to pass out the 135MHz reference
   -- out the to the other tile's CLKINEAST0/1 ports
   --
   -- 
   -------------------------------------------------------------
gtpa1_dual_X0Y0:GTPA1_DUAL
    generic map
    (
     SIM_REFCLK0_SOURCE          =>     ("100"),  -- CLK10
     SIM_REFCLK1_SOURCE          =>     ("100"),  -- CLK11
     PLL_SOURCE_0                =>     ("PLL0"),  -- Source from PLL 0
     PLL_SOURCE_1                =>     ("PLL1"),  -- Source from PLL 0

        --_______________________ Simulation-Only Attributes ___________________
        SIM_RECEIVER_DETECT_PASS    =>      (TRUE),
        SIM_TX_ELEC_IDLE_LEVEL      =>      ("Z"),
        SIM_VERSION                 =>      ("2.0"),
 
        SIM_GTPRESET_SPEEDUP        =>      (1),
        CLK25_DIVIDER_0             =>      (5),
        CLK25_DIVIDER_1             =>      (5),
        PLL_DIVSEL_FB_0             =>      (2), 
        PLL_DIVSEL_FB_1             =>      (2),  
        PLL_DIVSEL_REF_0            =>      (1), 
        PLL_DIVSEL_REF_1            =>      (1),
        CLK_OUT_GTP_SEL_0           =>      ("TXOUTCLK0"),
        CLK_OUT_GTP_SEL_1           =>      ("TXOUTCLK1"),
 
        

       --PLL Attributes
        CLKINDC_B_0                             =>     (TRUE),
        CLKRCV_TRST_0                           =>     (TRUE),
        OOB_CLK_DIVIDER_0                       =>     (4),
        PLL_COM_CFG_0                           =>     (x"21680a"),
        PLL_CP_CFG_0                            =>     (x"00"),
        PLL_RXDIVSEL_OUT_0                      =>     (1),
        PLL_SATA_0                              =>     (FALSE),
        PLL_TXDIVSEL_OUT_0                      =>     (1),
        PLLLKDET_CFG_0                          =>     ("111"),

       --
        CLKINDC_B_1                             =>     (TRUE),
        CLKRCV_TRST_1                           =>     (TRUE),
        OOB_CLK_DIVIDER_1                       =>     (4),
        PLL_COM_CFG_1                           =>     (x"21680a"),
        PLL_CP_CFG_1                            =>     (x"00"),
        PLL_RXDIVSEL_OUT_1                      =>     (1),
        PLL_SATA_1                              =>     (FALSE),
        PLL_TXDIVSEL_OUT_1                      =>     (1),
        PLLLKDET_CFG_1                          =>     ("111"),
        PMA_COM_CFG_EAST                        =>     (x"000008000"),
        PMA_COM_CFG_WEST                        =>     (x"00000a000"),
        TST_ATTR_0                              =>     (x"00000000"),
        TST_ATTR_1                              =>     (x"00000000"),

       --TX Interface Attributes
        TX_TDCC_CFG_0                           =>     ("11"),
        TX_TDCC_CFG_1                           =>     ("11"),

       --TX Buffer and Phase Alignment Attributes
        PMA_TX_CFG_0                            =>     (x"00082"),
        TX_BUFFER_USE_0                         =>     (TRUE),
        TX_XCLK_SEL_0                           =>     ("TXOUT"),
        TXRX_INVERT_0                           =>     ("111"),
        PMA_TX_CFG_1                            =>     (x"00082"),
        TX_BUFFER_USE_1                         =>     (TRUE),
        TX_XCLK_SEL_1                           =>     ("TXOUT"),
        TXRX_INVERT_1                           =>     ("111"),

       --TX Driver and OOB signalling Attributes
        CM_TRIM_0                               =>     ("00"),
        TX_IDLE_DELAY_0                         =>     ("011"),
        CM_TRIM_1                               =>     ("00"),
        TX_IDLE_DELAY_1                         =>     ("011"),

       --TX PIPE/SATA Attributes
        COM_BURST_VAL_0                         =>     ("1111"),
        COM_BURST_VAL_1                         =>     ("1111"),

       --RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
        AC_CAP_DIS_0                            =>     (TRUE),
        OOBDETECT_THRESHOLD_0                   =>     ("110"),
        PMA_CDR_SCAN_0                          =>     (x"6404040"),
        PMA_RX_CFG_0                            =>     (x"05ce089"),
        PMA_RXSYNC_CFG_0                        =>     (x"00"),
        RCV_TERM_GND_0                          =>     (FALSE),
        RCV_TERM_VTTRX_0                        =>     (TRUE),
        RXEQ_CFG_0                              =>     ("01111011"),
        TERMINATION_CTRL_0                      =>     ("10100"),
        TERMINATION_OVRD_0                      =>     (FALSE),
        TX_DETECT_RX_CFG_0                      =>     (x"1832"),
        AC_CAP_DIS_1                            =>     (TRUE),
        OOBDETECT_THRESHOLD_1                   =>     ("110"),
        PMA_CDR_SCAN_1                          =>     (x"6404040"),
        PMA_RX_CFG_1                            =>     (x"05ce089"),
        PMA_RXSYNC_CFG_1                        =>     (x"00"),
        RCV_TERM_GND_1                          =>     (FALSE),
        RCV_TERM_VTTRX_1                        =>     (TRUE),
        RXEQ_CFG_1                              =>     ("01111011"),
        TERMINATION_CTRL_1                      =>     ("10100"),
        TERMINATION_OVRD_1                      =>     (FALSE),
        TX_DETECT_RX_CFG_1                      =>     (x"1832"),

       --PRBS Detection Attributes
        RXPRBSERR_LOOPBACK_0                    =>     ('0'),
        RXPRBSERR_LOOPBACK_1                    =>     ('0'),

       --Comma Detection and Alignment Attributes
        ALIGN_COMMA_WORD_0                      =>     (1),
        COMMA_10B_ENABLE_0                      =>     ("1111111111"),
        DEC_MCOMMA_DETECT_0                     =>     (TRUE),
        DEC_PCOMMA_DETECT_0                     =>     (TRUE),
        DEC_VALID_COMMA_ONLY_0                  =>     (TRUE),
        MCOMMA_10B_VALUE_0                      =>     ("1010000011"),
        MCOMMA_DETECT_0                         =>     (TRUE),
        PCOMMA_10B_VALUE_0                      =>     ("0101111100"),
        PCOMMA_DETECT_0                         =>     (TRUE),
        RX_SLIDE_MODE_0                         =>     ("PCS"),
        ALIGN_COMMA_WORD_1                      =>     (1),
        COMMA_10B_ENABLE_1                      =>     ("1111111111"),
        DEC_MCOMMA_DETECT_1                     =>     (TRUE),
        DEC_PCOMMA_DETECT_1                     =>     (TRUE),
        DEC_VALID_COMMA_ONLY_1                  =>     (TRUE),
        MCOMMA_10B_VALUE_1                      =>     ("1010000011"),
        MCOMMA_DETECT_1                         =>     (TRUE),
        PCOMMA_10B_VALUE_1                      =>     ("0101111100"),
        PCOMMA_DETECT_1                         =>     (TRUE),
        RX_SLIDE_MODE_1                         =>     ("PCS"),

       --RX Loss-of-sync State Machine Attributes
        RX_LOS_INVALID_INCR_0                   =>     (8),
        RX_LOS_THRESHOLD_0                      =>     (128),
        RX_LOSS_OF_SYNC_FSM_0                   =>     (TRUE),
        RX_LOS_INVALID_INCR_1                   =>     (8),
        RX_LOS_THRESHOLD_1                      =>     (128),
        RX_LOSS_OF_SYNC_FSM_1                   =>     (TRUE),

       --RX Elastic Buffer and Phase alignment Attributes
        RX_BUFFER_USE_0                         =>     (TRUE),
        RX_EN_IDLE_RESET_BUF_0                  =>     (TRUE),
        RX_IDLE_HI_CNT_0                        =>     ("1000"),
        RX_IDLE_LO_CNT_0                        =>     ("0000"),
        RX_XCLK_SEL_0                           =>     ("RXREC"),
        RX_BUFFER_USE_1                         =>     (TRUE),
        RX_EN_IDLE_RESET_BUF_1                  =>     (TRUE),
        RX_IDLE_HI_CNT_1                        =>     ("1000"),
        RX_IDLE_LO_CNT_1                        =>     ("0000"),
        RX_XCLK_SEL_1                           =>     ("RXREC"),

       --Clock Correction Attributes
        CLK_COR_ADJ_LEN_0                       =>     (1),
        CLK_COR_DET_LEN_0                       =>     (1),
        CLK_COR_INSERT_IDLE_FLAG_0              =>     (FALSE),
        CLK_COR_KEEP_IDLE_0                     =>     (FALSE),
        CLK_COR_MAX_LAT_0                       =>     (18),
        CLK_COR_MIN_LAT_0                       =>     (16),
        CLK_COR_PRECEDENCE_0                    =>     (TRUE),
        CLK_COR_REPEAT_WAIT_0                   =>     (5),
        CLK_COR_SEQ_1_1_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_2_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_3_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_4_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_ENABLE_0                  =>     ("0000"),
        CLK_COR_SEQ_2_1_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_2_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_3_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_4_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_ENABLE_0                  =>     ("0000"),
        CLK_COR_SEQ_2_USE_0                     =>     (FALSE),
        CLK_CORRECT_USE_0                       =>     (FALSE),
        RX_DECODE_SEQ_MATCH_0                   =>     (TRUE),
        CLK_COR_ADJ_LEN_1                       =>     (1),
        CLK_COR_DET_LEN_1                       =>     (1),
        CLK_COR_INSERT_IDLE_FLAG_1              =>     (FALSE),
        CLK_COR_KEEP_IDLE_1                     =>     (FALSE),
        CLK_COR_MAX_LAT_1                       =>     (18),
        CLK_COR_MIN_LAT_1                       =>     (16),
        CLK_COR_PRECEDENCE_1                    =>     (TRUE),
        CLK_COR_REPEAT_WAIT_1                   =>     (5),
        CLK_COR_SEQ_1_1_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_2_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_3_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_4_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_ENABLE_1                  =>     ("0000"),
        CLK_COR_SEQ_2_1_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_2_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_3_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_4_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_ENABLE_1                  =>     ("0000"),
        CLK_COR_SEQ_2_USE_1                     =>     (FALSE),
        CLK_CORRECT_USE_1                       =>     (FALSE),
        RX_DECODE_SEQ_MATCH_1                   =>     (TRUE),

       --Channel Bonding Attributes
        CHAN_BOND_1_MAX_SKEW_0                  =>     (1),
        CHAN_BOND_2_MAX_SKEW_0                  =>     (1),
        CHAN_BOND_KEEP_ALIGN_0                  =>     (FALSE),
        CHAN_BOND_SEQ_1_1_0                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_2_0                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_3_0                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_4_0                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_ENABLE_0                =>     ("0000"),
        CHAN_BOND_SEQ_2_1_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_2_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_3_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_4_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_ENABLE_0                =>     ("0000"),
        CHAN_BOND_SEQ_2_USE_0                   =>     (FALSE),
        CHAN_BOND_SEQ_LEN_0                     =>     (1),
        RX_EN_MODE_RESET_BUF_0                  =>     (FALSE),
        CHAN_BOND_1_MAX_SKEW_1                  =>     (1),
        CHAN_BOND_2_MAX_SKEW_1                  =>     (1),
        CHAN_BOND_KEEP_ALIGN_1                  =>     (FALSE),
        CHAN_BOND_SEQ_1_1_1                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_2_1                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_3_1                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_4_1                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_ENABLE_1                =>     ("0000"),
        CHAN_BOND_SEQ_2_1_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_2_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_3_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_4_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_ENABLE_1                =>     ("0000"),
        CHAN_BOND_SEQ_2_USE_1                   =>     (FALSE),
        CHAN_BOND_SEQ_LEN_1                     =>     (1),
        RX_EN_MODE_RESET_BUF_1                  =>     (FALSE),

       --RX PCI Express Attributes
        CB2_INH_CC_PERIOD_0                     =>     (8),
        CDR_PH_ADJ_TIME_0                       =>     ("01010"),
        PCI_EXPRESS_MODE_0                      =>     (FALSE),
        RX_EN_IDLE_HOLD_CDR_0                   =>     (FALSE),
        RX_EN_IDLE_RESET_FR_0                   =>     (TRUE),
        RX_EN_IDLE_RESET_PH_0                   =>     (TRUE),
        RX_STATUS_FMT_0                         =>     ("PCIE"),
        TRANS_TIME_FROM_P2_0                    =>     (x"03c"),
        TRANS_TIME_NON_P2_0                     =>     (x"19"),
        TRANS_TIME_TO_P2_0                      =>     (x"064"),
        CB2_INH_CC_PERIOD_1                     =>     (8),
        CDR_PH_ADJ_TIME_1                       =>     ("01010"),
        PCI_EXPRESS_MODE_1                      =>     (FALSE),
        RX_EN_IDLE_HOLD_CDR_1                   =>     (FALSE),
        RX_EN_IDLE_RESET_FR_1                   =>     (TRUE),
        RX_EN_IDLE_RESET_PH_1                   =>     (TRUE),
        RX_STATUS_FMT_1                         =>     ("PCIE"),
        TRANS_TIME_FROM_P2_1                    =>     (x"03c"),
        TRANS_TIME_NON_P2_1                     =>     (x"19"),
        TRANS_TIME_TO_P2_1                      =>     (x"064"),

       --RX SATA Attributes
        SATA_BURST_VAL_0                        =>     ("100"),
        SATA_IDLE_VAL_0                         =>     ("100"),
        SATA_MAX_BURST_0                        =>     (10),
        SATA_MAX_INIT_0                         =>     (29),
        SATA_MAX_WAKE_0                         =>     (10),
        SATA_MIN_BURST_0                        =>     (5),
        SATA_MIN_INIT_0                         =>     (16),
        SATA_MIN_WAKE_0                         =>     (5),
        SATA_BURST_VAL_1                        =>     ("100"),
        SATA_IDLE_VAL_1                         =>     ("100"),
        SATA_MAX_BURST_1                        =>     (10),
        SATA_MAX_INIT_1                         =>     (29),
        SATA_MAX_WAKE_1                         =>     (10),
        SATA_MIN_BURST_1                        =>     (5),
        SATA_MIN_INIT_1                         =>     (16),
        SATA_MIN_WAKE_1                         =>     (5)
    ) 
    port map 
    (
     TXPOWERDOWN0                    =>      txpowerdown(5 downto 4),
     TXPOWERDOWN1                    =>      txpowerdown(7 downto 6),
     CLK00                           =>      '0',
     CLK01                           =>      '0',
     CLK10                           =>      '0',
     CLK11                           =>      '0',
     GCLK00                          =>      gclk135,
     GCLK01                          =>      gclk135,
     GCLK10                          =>      '0',
     GCLK11                          =>      '0',
     GTPRESET0                       =>      gtpreset(2),
     GTPRESET1                       =>      gtpreset(3),
     PLLLKDET0                       =>      plllock(2),
     PLLLKDET1                       =>      plllock(3),
     PLLLKDETEN0                     =>      plllocken(2),
     PLLLKDETEN1                     =>      plllocken(3),
     PLLPOWERDOWN0                   =>      pllpowerdown(2),
     PLLPOWERDOWN1                   =>      pllpowerdown(3),
     REFCLKPLL0                      =>      out_ref_clk(2),
     REFCLKPLL1                      =>      out_ref_clk(3),
     
     REFSELDYPLL0                    =>      "001", -- use GCLK135
     REFSELDYPLL1                    =>      "001", -- use GCLK135
     RESETDONE0                      =>      gtpresetdone(2),
     RESETDONE1                      =>      gtpresetdone(3),
     GTPCLKOUT0                      =>      gtpclkout(5 downto 4),
     GTPCLKOUT1                      =>      gtpclkout(7 downto 6),
     TXCHARDISPMODE0                 =>      TXCHARDISPMODE2,
     TXCHARDISPMODE1                 =>      TXCHARDISPMODE3,
     TXCHARDISPVAL0                  =>      TXCHARDISPVAL2,
     TXCHARDISPVAL1                  =>      TXCHARDISPVAL3,
     TXDATA0                         =>      txdata_for_tx2,
     TXDATA1                         =>      txdata_for_tx3,
     TXOUTCLK0                       =>      txoutclk(2),
     TXOUTCLK1                       =>      txoutclk(3),
     TXRESET0                        =>      txreset(2),
     TXRESET1                        =>      txreset(3),
     TXUSRCLK0                       =>      txusrclk_buffered,
     TXUSRCLK1                       =>      txusrclk_buffered,
     TXUSRCLK20                      =>      txusrclk2_buffered,
     TXUSRCLK21                      =>      txusrclk2_buffered,
     TXDIFFCTRL0                     =>      swing_level,
     TXDIFFCTRL1                     =>      swing_level,
     TXP0                            =>      gtptxp(2),
     TXN0                            =>      gtptxn(2),
     TXP1                            =>      gtptxp(3),
     TXN1                            =>      gtptxn(3),
     TXPREEMPHASIS0                  =>      preemp_level,
     TXPREEMPHASIS1                  =>      preemp_level,
     -- Only so resetdone works..
     RXUSRCLK0                       =>      txusrclk_buffered,
     RXUSRCLK1                       =>      txusrclk_buffered,
     RXUSRCLK20                      =>      txusrclk2_buffered,
     RXUSRCLK21                      =>      txusrclk2_buffered,

     TXCHARISK0                      =>      is_kchar_tx2,
     TXCHARISK1                      =>      is_kchar_tx3,
     TXENC8B10BUSE0                  =>      use_hw_8b10b_support,
     TXENC8B10BUSE1                  =>      use_hw_8b10b_support,
        ------------------------ Loopback and Powerdown Ports ----------------------
        LOOPBACK0                       =>      (others => '0'),
        LOOPBACK1                       =>      (others => '0'),
        RXPOWERDOWN0                    =>      "11", --- Maybe I should tie these low to allow the reset to finish?
        RXPOWERDOWN1                    =>      "11",
        --------------------------------- PLL Ports --------------------------------
        CLKINEAST0                      =>      '0',
        CLKINEAST1                      =>      '0',
        CLKINWEST0                      =>      '0',
        CLKINWEST1                      =>      '0',
        GTPTEST0                        =>      "00010000",
        GTPTEST1                        =>      "00010000",
        INTDATAWIDTH0                   =>      '1',
        INTDATAWIDTH1                   =>      '1',
        PLLCLK00                        =>      '0',
        PLLCLK01                        =>      '0',
        PLLCLK10                        =>      '0',
        PLLCLK11                        =>      '0',
        REFCLKOUT0                      =>      open,
        REFCLKOUT1                      =>      open,
        REFCLKPLL0                      =>      open,
        REFCLKPLL1                      =>      open,
        REFCLKPWRDNB0                   =>      '1',  -- Not used - should power down
        REFCLKPWRDNB1                   =>      '1',  -- Used- must be powered up
        TSTCLK0                         =>      '0',
        TSTCLK1                         =>      '0',
        TSTIN0                          =>      (others => '0'),
        TSTIN1                          =>      (others => '0'),
        TSTOUT0                         =>      open,
        TSTOUT1                         =>      open,
        ----------------------- Receive Ports - 8b10b Decoder ----------------------
        RXCHARISCOMMA0                  =>      open,
        RXCHARISCOMMA1                  =>      open,
        RXCHARISK0                      =>      open,
        RXCHARISK1                      =>      open,
        RXDEC8B10BUSE0                  =>      '1',
        RXDEC8B10BUSE1                  =>      '1',
        RXDISPERR0                      =>      open,
        RXDISPERR1                      =>      open,
        RXNOTINTABLE0                   =>      open,
        RXNOTINTABLE1                   =>      open,
        RXRUNDISP0                      =>      open,
        RXRUNDISP1                      =>      open,
        USRCODEERR0                     =>      '0',
        USRCODEERR1                     =>      '0',
        ---------------------- Receive Ports - Channel Bonding ---------------------
        RXCHANBONDSEQ0                  =>      open,
        RXCHANBONDSEQ1                  =>      open,
        RXCHANISALIGNED0                =>      open,
        RXCHANISALIGNED1                =>      open,
        RXCHANREALIGN0                  =>      open,
        RXCHANREALIGN1                  =>      open,
        RXCHBONDI                       =>      (others => '0'),
        RXCHBONDMASTER0                 =>      '0',
        RXCHBONDMASTER1                 =>      '0',
        RXCHBONDO                       =>      open,
        RXCHBONDSLAVE0                  =>      '0',
        RXCHBONDSLAVE1                  =>      '0',
        RXENCHANSYNC0                   =>      '0',
        RXENCHANSYNC1                   =>      '0',
        ---------------------- Receive Ports - Clock Correction --------------------
        RXCLKCORCNT0                    =>      open,
        RXCLKCORCNT1                    =>      open,
        --------------- Receive Ports - Comma Detection and Alignment --------------
        RXBYTEISALIGNED0                =>      open,
        RXBYTEISALIGNED1                =>      open,
        RXBYTEREALIGN0                  =>      open,
        RXBYTEREALIGN1                  =>      open,
        RXCOMMADET0                     =>      open,
        RXCOMMADET1                     =>      open,
        RXCOMMADETUSE0                  =>      '1',
        RXCOMMADETUSE1                  =>      '1',
        RXENMCOMMAALIGN0                =>      '0',
        RXENMCOMMAALIGN1                =>      '0',
        RXENPCOMMAALIGN0                =>      '0',
        RXENPCOMMAALIGN1                =>      '0',
        RXSLIDE0                        =>      '0',
        RXSLIDE1                        =>      '0',
        ----------------------- Receive Ports - PRBS Detection ---------------------
        PRBSCNTRESET0                   =>      '1',
        PRBSCNTRESET1                   =>      '1',
        RXENPRBSTST0                    =>      "000",
        RXENPRBSTST1                    =>      "000",
        RXPRBSERR0                      =>      open,
        RXPRBSERR1                      =>      open,
        ------------------- Receive Ports - RX Data Path interface -----------------
        RXDATA0                         =>      open,
        RXDATA1                         =>      open,
        RXDATAWIDTH0                    =>      "01",
        RXDATAWIDTH1                    =>      "01",
        RXRECCLK0                       =>      open,
        RXRECCLK1                       =>      open,
        RXRESET0                        =>      '0',
        RXRESET1                        =>      '0',
        ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GATERXELECIDLE0                 =>      '0',
        GATERXELECIDLE1                 =>      '0',
        IGNORESIGDET0                   =>      '1',
        IGNORESIGDET1                   =>      '1',
        RCALINEAST                      =>      (others =>'0'),
        RCALINWEST                      =>      (others =>'0'),
        RCALOUTEAST                     =>      open,
        RCALOUTWEST                     =>      open,
        RXCDRRESET0                     =>      '0',
        RXCDRRESET1                     =>      '0',
        RXELECIDLE0                     =>      open,
        RXELECIDLE1                     =>      open,
        RXEQMIX0                        =>      "11",
        RXEQMIX1                        =>      "11",
        RXN0                            =>      '0',
        RXN1                            =>      '0',
        RXP0                            =>      '1',
        RXP1                            =>      '1',
        ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
        RXBUFRESET0                     =>      '0',
        RXBUFRESET1                     =>      '0',
        RXBUFSTATUS0                    =>      open,
        RXBUFSTATUS1                    =>      open,
        RXENPMAPHASEALIGN0              =>      '0',
        RXENPMAPHASEALIGN1              =>      '0',
        RXPMASETPHASE0                  =>      '0',
        RXPMASETPHASE1                  =>      '0',
        RXSTATUS0                       =>      open,
        RXSTATUS1                       =>      open,
        --------------- Receive Ports - RX Loss-of-sync State Machine --------------
        RXLOSSOFSYNC0                   =>      open,
        RXLOSSOFSYNC1                   =>      open,
        -------------- Receive Ports - RX Pipe Control for PCI Express -------------
        PHYSTATUS0                      =>      open,
        PHYSTATUS1                      =>      open,
        RXVALID0                        =>      open,
        RXVALID1                        =>      open,
        -------------------- Receive Ports - RX Polarity Control -------------------
        RXPOLARITY0                     =>      '0',
        RXPOLARITY1                     =>      '0',
        ------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
        DADDR                           =>      (others=>'0'),
        DCLK                            =>      '0',
        DEN                             =>      '0',
        DI                              =>      (others => '0'),
        DRDY                            =>      open,
        DRPDO                           =>      open,
        DWE                             =>      '0',
        ---------------------------- TX/RX Datapath Ports --------------------------
        GTPCLKFBEAST                    =>      open,
        GTPCLKFBSEL0EAST                =>      "10",
        GTPCLKFBSEL0WEST                =>      "00",
        GTPCLKFBSEL1EAST                =>      "11",
        GTPCLKFBSEL1WEST                =>      "01",
        GTPCLKFBWEST                    =>      open,
        ------------------- Transmit Ports - 8b10b Encoder Control -----------------
        TXBYPASS8B10B0                  =>      "0000",
        TXBYPASS8B10B1                  =>      "0000",
        TXKERR0                         =>      open,
        TXKERR1                         =>      open,
        TXRUNDISP0                      =>      open,
        TXRUNDISP1                      =>      open,
        --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
        TXBUFSTATUS0                    =>      open,
        TXBUFSTATUS1                    =>      open,
        TXENPMAPHASEALIGN0              =>      '0',
        TXENPMAPHASEALIGN1              =>      '0',
        TXPMASETPHASE0                  =>      '0',
        TXPMASETPHASE1                  =>      '0',
        ------------------ Transmit Ports - TX Data Path interface -----------------
        TXDATAWIDTH0                    =>      "01",
        TXDATAWIDTH1                    =>      "01",
        --------------- Transmit Ports - TX Driver and OOB signalling --------------
        TXBUFDIFFCTRL0                  =>      "101",
        TXBUFDIFFCTRL1                  =>      "101",
        TXINHIBIT0                      =>      '0',
        TXINHIBIT1                      =>      '0',
        --------------------- Transmit Ports - TX PRBS Generator -------------------
        TXENPRBSTST0                    =>      "000",
        TXENPRBSTST1                    =>      "000",
        TXPRBSFORCEERR0                 =>      '0',
        TXPRBSFORCEERR1                 =>      '0',
        -------------------- Transmit Ports - TX Polarity Control ------------------
        TXPOLARITY0                     =>      '0',
        TXPOLARITY1                     =>      '0',
        ----------------- Transmit Ports - TX Ports for PCI Express ----------------
        TXDETECTRX0                     =>      '0',
        TXDETECTRX1                     =>      '0',
        TXELECIDLE0                     =>      '0',
        TXELECIDLE1                     =>      '0',
        TXPDOWNASYNCH0                  =>      '0',
        TXPDOWNASYNCH1                  =>      '0',
        --------------------- Transmit Ports - TX Ports for SATA -------------------
        TXCOMSTART0                     =>      '0',
        TXCOMSTART1                     =>      '0',
        TXCOMTYPE0                      =>      '0',
        TXCOMTYPE1                      =>      '0'
    );

    ----------------------------- GTPA1_DUAL Instance X1Y0 --------------------------   
    -- This is the driver for Display port channels 1 and 0.
    -- It is clocked from X0Y0 on gclk00 over the clkinwest1 ports
    ----------------------------------------------------------------------------------
gtpa1_dual_X1Y0:GTPA1_DUAL
    generic map
    (
 

     SIM_REFCLK0_SOURCE          =>     ("111"),
     SIM_REFCLK1_SOURCE          =>     ("111"),
     PLL_SOURCE_0                =>     ("PLL0"),  -- Source from PLL 0
     PLL_SOURCE_1                =>     ("PLL1"),  -- Source from PLL 0

        --_______________________ Simulation-Only Attributes ___________________
        SIM_RECEIVER_DETECT_PASS    =>      (TRUE),
        SIM_TX_ELEC_IDLE_LEVEL      =>      ("Z"),
        SIM_VERSION                 =>      ("2.0"),
 
        SIM_GTPRESET_SPEEDUP        =>      (1),
        CLK25_DIVIDER_0             =>      (5),
        CLK25_DIVIDER_1             =>      (5),
        PLL_DIVSEL_FB_0             =>      (2), 
        PLL_DIVSEL_FB_1             =>      (2),  
        PLL_DIVSEL_REF_0            =>      (1), 
        PLL_DIVSEL_REF_1            =>      (1),
        CLK_OUT_GTP_SEL_0           =>      ("TXOUTCLK0"),
        CLK_OUT_GTP_SEL_1           =>      ("TXOUTCLK1"),
 
        

       --PLL Attributes
        CLKINDC_B_0                             =>     (TRUE),
        CLKRCV_TRST_0                           =>     (TRUE),
        OOB_CLK_DIVIDER_0                       =>     (4),
        PLL_COM_CFG_0                           =>     (x"21680a"),
        PLL_CP_CFG_0                            =>     (x"00"),
        PLL_RXDIVSEL_OUT_0                      =>     (1),
        PLL_SATA_0                              =>     (FALSE),
        PLL_TXDIVSEL_OUT_0                      =>     (1),
        PLLLKDET_CFG_0                          =>     ("111"),

       --
        CLKINDC_B_1                             =>     (TRUE),
        CLKRCV_TRST_1                           =>     (TRUE),
        OOB_CLK_DIVIDER_1                       =>     (4),
        PLL_COM_CFG_1                           =>     (x"21680a"),
        PLL_CP_CFG_1                            =>     (x"00"),
        PLL_RXDIVSEL_OUT_1                      =>     (1),
        PLL_SATA_1                              =>     (FALSE),
        PLL_TXDIVSEL_OUT_1                      =>     (1),
        PLLLKDET_CFG_1                          =>     ("111"),
        PMA_COM_CFG_EAST                        =>     (x"000008000"),
        PMA_COM_CFG_WEST                        =>     (x"00000a000"),
        TST_ATTR_0                              =>     (x"00000000"),
        TST_ATTR_1                              =>     (x"00000000"),

       --TX Interface Attributes
        TX_TDCC_CFG_0                           =>     ("11"),
        TX_TDCC_CFG_1                           =>     ("11"),

       --TX Buffer and Phase Alignment Attributes
        PMA_TX_CFG_0                            =>     (x"00082"),
        TX_BUFFER_USE_0                         =>     (TRUE),
        TX_XCLK_SEL_0                           =>     ("TXOUT"),
        TXRX_INVERT_0                           =>     ("111"),
        PMA_TX_CFG_1                            =>     (x"00082"),
        TX_BUFFER_USE_1                         =>     (TRUE),
        TX_XCLK_SEL_1                           =>     ("TXOUT"),
        TXRX_INVERT_1                           =>     ("111"),

       --TX Driver and OOB signalling Attributes
        CM_TRIM_0                               =>     ("00"),
        TX_IDLE_DELAY_0                         =>     ("011"),
        CM_TRIM_1                               =>     ("00"),
        TX_IDLE_DELAY_1                         =>     ("011"),

       --TX PIPE/SATA Attributes
        COM_BURST_VAL_0                         =>     ("1111"),
        COM_BURST_VAL_1                         =>     ("1111"),

       --RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
        AC_CAP_DIS_0                            =>     (TRUE),
        OOBDETECT_THRESHOLD_0                   =>     ("110"),
        PMA_CDR_SCAN_0                          =>     (x"6404040"),
        PMA_RX_CFG_0                            =>     (x"05ce089"),
        PMA_RXSYNC_CFG_0                        =>     (x"00"),
        RCV_TERM_GND_0                          =>     (FALSE),
        RCV_TERM_VTTRX_0                        =>     (TRUE),
        RXEQ_CFG_0                              =>     ("01111011"),
        TERMINATION_CTRL_0                      =>     ("10100"),
        TERMINATION_OVRD_0                      =>     (FALSE),
        TX_DETECT_RX_CFG_0                      =>     (x"1832"),
        AC_CAP_DIS_1                            =>     (TRUE),
        OOBDETECT_THRESHOLD_1                   =>     ("110"),
        PMA_CDR_SCAN_1                          =>     (x"6404040"),
        PMA_RX_CFG_1                            =>     (x"05ce089"),
        PMA_RXSYNC_CFG_1                        =>     (x"00"),
        RCV_TERM_GND_1                          =>     (FALSE),
        RCV_TERM_VTTRX_1                        =>     (TRUE),
        RXEQ_CFG_1                              =>     ("01111011"),
        TERMINATION_CTRL_1                      =>     ("10100"),
        TERMINATION_OVRD_1                      =>     (FALSE),
        TX_DETECT_RX_CFG_1                      =>     (x"1832"),

       --PRBS Detection Attributes
        RXPRBSERR_LOOPBACK_0                    =>     ('0'),
        RXPRBSERR_LOOPBACK_1                    =>     ('0'),

       --Comma Detection and Alignment Attributes
        ALIGN_COMMA_WORD_0                      =>     (1),
        COMMA_10B_ENABLE_0                      =>     ("1111111111"),
        DEC_MCOMMA_DETECT_0                     =>     (TRUE),
        DEC_PCOMMA_DETECT_0                     =>     (TRUE),
        DEC_VALID_COMMA_ONLY_0                  =>     (TRUE),
        MCOMMA_10B_VALUE_0                      =>     ("1010000011"),
        MCOMMA_DETECT_0                         =>     (TRUE),
        PCOMMA_10B_VALUE_0                      =>     ("0101111100"),
        PCOMMA_DETECT_0                         =>     (TRUE),
        RX_SLIDE_MODE_0                         =>     ("PCS"),
        ALIGN_COMMA_WORD_1                      =>     (1),
        COMMA_10B_ENABLE_1                      =>     ("1111111111"),
        DEC_MCOMMA_DETECT_1                     =>     (TRUE),
        DEC_PCOMMA_DETECT_1                     =>     (TRUE),
        DEC_VALID_COMMA_ONLY_1                  =>     (TRUE),
        MCOMMA_10B_VALUE_1                      =>     ("1010000011"),
        MCOMMA_DETECT_1                         =>     (TRUE),
        PCOMMA_10B_VALUE_1                      =>     ("0101111100"),
        PCOMMA_DETECT_1                         =>     (TRUE),
        RX_SLIDE_MODE_1                         =>     ("PCS"),

       --RX Loss-of-sync State Machine Attributes
        RX_LOS_INVALID_INCR_0                   =>     (8),
        RX_LOS_THRESHOLD_0                      =>     (128),
        RX_LOSS_OF_SYNC_FSM_0                   =>     (TRUE),
        RX_LOS_INVALID_INCR_1                   =>     (8),
        RX_LOS_THRESHOLD_1                      =>     (128),
        RX_LOSS_OF_SYNC_FSM_1                   =>     (TRUE),

       --RX Elastic Buffer and Phase alignment Attributes
        RX_BUFFER_USE_0                         =>     (TRUE),
        RX_EN_IDLE_RESET_BUF_0                  =>     (TRUE),
        RX_IDLE_HI_CNT_0                        =>     ("1000"),
        RX_IDLE_LO_CNT_0                        =>     ("0000"),
        RX_XCLK_SEL_0                           =>     ("RXREC"),
        RX_BUFFER_USE_1                         =>     (TRUE),
        RX_EN_IDLE_RESET_BUF_1                  =>     (TRUE),
        RX_IDLE_HI_CNT_1                        =>     ("1000"),
        RX_IDLE_LO_CNT_1                        =>     ("0000"),
        RX_XCLK_SEL_1                           =>     ("RXREC"),

       --Clock Correction Attributes
        CLK_COR_ADJ_LEN_0                       =>     (1),
        CLK_COR_DET_LEN_0                       =>     (1),
        CLK_COR_INSERT_IDLE_FLAG_0              =>     (FALSE),
        CLK_COR_KEEP_IDLE_0                     =>     (FALSE),
        CLK_COR_MAX_LAT_0                       =>     (18),
        CLK_COR_MIN_LAT_0                       =>     (16),
        CLK_COR_PRECEDENCE_0                    =>     (TRUE),
        CLK_COR_REPEAT_WAIT_0                   =>     (5),
        CLK_COR_SEQ_1_1_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_2_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_3_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_4_0                       =>     ("0100000000"),
        CLK_COR_SEQ_1_ENABLE_0                  =>     ("0000"),
        CLK_COR_SEQ_2_1_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_2_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_3_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_4_0                       =>     ("0100000000"),
        CLK_COR_SEQ_2_ENABLE_0                  =>     ("0000"),
        CLK_COR_SEQ_2_USE_0                     =>     (FALSE),
        CLK_CORRECT_USE_0                       =>     (FALSE),
        RX_DECODE_SEQ_MATCH_0                   =>     (TRUE),
        CLK_COR_ADJ_LEN_1                       =>     (1),
        CLK_COR_DET_LEN_1                       =>     (1),
        CLK_COR_INSERT_IDLE_FLAG_1              =>     (FALSE),
        CLK_COR_KEEP_IDLE_1                     =>     (FALSE),
        CLK_COR_MAX_LAT_1                       =>     (18),
        CLK_COR_MIN_LAT_1                       =>     (16),
        CLK_COR_PRECEDENCE_1                    =>     (TRUE),
        CLK_COR_REPEAT_WAIT_1                   =>     (5),
        CLK_COR_SEQ_1_1_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_2_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_3_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_4_1                       =>     ("0100000000"),
        CLK_COR_SEQ_1_ENABLE_1                  =>     ("0000"),
        CLK_COR_SEQ_2_1_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_2_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_3_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_4_1                       =>     ("0100000000"),
        CLK_COR_SEQ_2_ENABLE_1                  =>     ("0000"),
        CLK_COR_SEQ_2_USE_1                     =>     (FALSE),
        CLK_CORRECT_USE_1                       =>     (FALSE),
        RX_DECODE_SEQ_MATCH_1                   =>     (TRUE),

       --Channel Bonding Attributes
        CHAN_BOND_1_MAX_SKEW_0                  =>     (1),
        CHAN_BOND_2_MAX_SKEW_0                  =>     (1),
        CHAN_BOND_KEEP_ALIGN_0                  =>     (FALSE),
        CHAN_BOND_SEQ_1_1_0                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_2_0                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_3_0                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_4_0                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_ENABLE_0                =>     ("0000"),
        CHAN_BOND_SEQ_2_1_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_2_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_3_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_4_0                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_ENABLE_0                =>     ("0000"),
        CHAN_BOND_SEQ_2_USE_0                   =>     (FALSE),
        CHAN_BOND_SEQ_LEN_0                     =>     (1),
        RX_EN_MODE_RESET_BUF_0                  =>     (FALSE),
        CHAN_BOND_1_MAX_SKEW_1                  =>     (1),
        CHAN_BOND_2_MAX_SKEW_1                  =>     (1),
        CHAN_BOND_KEEP_ALIGN_1                  =>     (FALSE),
        CHAN_BOND_SEQ_1_1_1                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_2_1                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_3_1                     =>     ("0110111100"),
        CHAN_BOND_SEQ_1_4_1                     =>     ("0011001011"),
        CHAN_BOND_SEQ_1_ENABLE_1                =>     ("0000"),
        CHAN_BOND_SEQ_2_1_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_2_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_3_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_4_1                     =>     ("0000000000"),
        CHAN_BOND_SEQ_2_ENABLE_1                =>     ("0000"),
        CHAN_BOND_SEQ_2_USE_1                   =>     (FALSE),
        CHAN_BOND_SEQ_LEN_1                     =>     (1),
        RX_EN_MODE_RESET_BUF_1                  =>     (FALSE),

       --RX PCI Express Attributes
        CB2_INH_CC_PERIOD_0                     =>     (8),
        CDR_PH_ADJ_TIME_0                       =>     ("01010"),
        PCI_EXPRESS_MODE_0                      =>     (FALSE),
        RX_EN_IDLE_HOLD_CDR_0                   =>     (FALSE),
        RX_EN_IDLE_RESET_FR_0                   =>     (TRUE),
        RX_EN_IDLE_RESET_PH_0                   =>     (TRUE),
        RX_STATUS_FMT_0                         =>     ("PCIE"),
        TRANS_TIME_FROM_P2_0                    =>     (x"03c"),
        TRANS_TIME_NON_P2_0                     =>     (x"19"),
        TRANS_TIME_TO_P2_0                      =>     (x"064"),
        CB2_INH_CC_PERIOD_1                     =>     (8),
        CDR_PH_ADJ_TIME_1                       =>     ("01010"),
        PCI_EXPRESS_MODE_1                      =>     (FALSE),
        RX_EN_IDLE_HOLD_CDR_1                   =>     (FALSE),
        RX_EN_IDLE_RESET_FR_1                   =>     (TRUE),
        RX_EN_IDLE_RESET_PH_1                   =>     (TRUE),
        RX_STATUS_FMT_1                         =>     ("PCIE"),
        TRANS_TIME_FROM_P2_1                    =>     (x"03c"),
        TRANS_TIME_NON_P2_1                     =>     (x"19"),
        TRANS_TIME_TO_P2_1                      =>     (x"064"),

       --RX SATA Attributes
        SATA_BURST_VAL_0                        =>     ("100"),
        SATA_IDLE_VAL_0                         =>     ("100"),
        SATA_MAX_BURST_0                        =>     (10),
        SATA_MAX_INIT_0                         =>     (29),
        SATA_MAX_WAKE_0                         =>     (10),
        SATA_MIN_BURST_0                        =>     (5),
        SATA_MIN_INIT_0                         =>     (16),
        SATA_MIN_WAKE_0                         =>     (5),
        SATA_BURST_VAL_1                        =>     ("100"),
        SATA_IDLE_VAL_1                         =>     ("100"),
        SATA_MAX_BURST_1                        =>     (10),
        SATA_MAX_INIT_1                         =>     (29),
        SATA_MAX_WAKE_1                         =>     (10),
        SATA_MIN_BURST_1                        =>     (5),
        SATA_MIN_INIT_1                         =>     (16),
        SATA_MIN_WAKE_1                         =>     (5)
    ) 
    port map 
    (
     TXPOWERDOWN0                    =>      txpowerdown(1 downto 0),
     TXPOWERDOWN1                    =>      txpowerdown(3 downto 2),
     CLK00                           =>      '0',
     CLK01                           =>      '0',
     CLK10                           =>      '0',
     CLK11                           =>      '0',
     GCLK00                          =>      '0',
     GCLK01                          =>      '0',
     GCLK10                          =>      '0',
     GCLK11                          =>      '0',
     CLKINEAST0                      =>      '0',
     CLKINEAST1                      =>      '0',
     CLKINWEST0                      =>      out_ref_clk(3),
     CLKINWEST1                      =>      out_ref_clk(3),
     GTPRESET0                       =>      gtpreset(0),
     GTPRESET1                       =>      gtpreset(1),
     PLLLKDET0                       =>      plllock(0),
     PLLLKDET1                       =>      plllock(1),
     PLLLKDETEN0                     =>      plllocken(0),
     PLLLKDETEN1                     =>      plllocken(1),
     PLLPOWERDOWN0                   =>      pllpowerdown(0),
     PLLPOWERDOWN1                   =>      pllpowerdown(1),
     REFSELDYPLL0                    =>      "111", -- use West clock
     REFSELDYPLL1                    =>      "111", -- use West clock
     RESETDONE0                      =>      gtpresetdone(0),
     RESETDONE1                      =>      gtpresetdone(1),
     GTPCLKOUT0                      =>      gtpclkout(1 downto 0),
     GTPCLKOUT1                      =>      gtpclkout(3 downto 2),
     TXCHARDISPMODE0                 =>      TXCHARDISPMODE0,
     TXCHARDISPMODE1                 =>      TXCHARDISPMODE1,
     TXCHARDISPVAL0                  =>      TXCHARDISPVAL0,
     TXCHARDISPVAL1                  =>      TXCHARDISPVAL1,
     TXDATA0                         =>      txdata_for_tx0,
     TXDATA1                         =>      txdata_for_tx1,
     TXOUTCLK0                       =>      txoutclk(0),
     TXOUTCLK1                       =>      txoutclk(1),
     TXRESET0                        =>      txreset(0),
     TXRESET1                        =>      txreset(1),
     TXUSRCLK0                       =>      txusrclk_buffered,
     TXUSRCLK1                       =>      txusrclk_buffered,
     TXUSRCLK20                      =>      txusrclk2_buffered,
     TXUSRCLK21                      =>      txusrclk2_buffered,
     TXDIFFCTRL0                     =>      swing_level,
     TXDIFFCTRL1                     =>      swing_level,
     TXP0                            =>      gtptxp(0),
     TXN0                            =>      gtptxn(0),
     TXP1                            =>      gtptxp(1),
     TXN1                            =>      gtptxn(1),
     TXPREEMPHASIS0                  =>      preemp_level,
     TXPREEMPHASIS1                  =>      preemp_level,
     -- Only so resetdone works..
     RXUSRCLK0                       =>      txusrclk_buffered,
     RXUSRCLK1                       =>      txusrclk_buffered,
     RXUSRCLK20                      =>      txusrclk2_buffered,
     RXUSRCLK21                      =>      txusrclk2_buffered,

     TXCHARISK0                      =>      is_kchar_tx0,
     TXCHARISK1                      =>      is_kchar_tx1,
     TXENC8B10BUSE0                  =>      use_hw_8b10b_support,
     TXENC8B10BUSE1                  =>      use_hw_8b10b_support,

        ------------------------ Loopback and Powerdown Ports ----------------------
        LOOPBACK0                       =>      (others => '0'),
        LOOPBACK1                       =>      (others => '0'),
        RXPOWERDOWN0                    =>      "11",
        RXPOWERDOWN1                    =>      "11",
        --------------------------------- PLL Ports --------------------------------
        GTPTEST0                        =>      "00010000",
        GTPTEST1                        =>      "00010000",
        INTDATAWIDTH0                   =>      '1',
        INTDATAWIDTH1                   =>      '1',
        PLLCLK00                        =>      '0',
        PLLCLK01                        =>      '0',
        PLLCLK10                        =>      '0',
        PLLCLK11                        =>      '0',
        REFCLKOUT0                      =>      open,
        REFCLKOUT1                      =>      open,
        REFCLKPLL0                      =>      open,
        REFCLKPLL1                      =>      open,
        REFCLKPWRDNB0                   =>      '1',  -- Not used - should power down
        REFCLKPWRDNB1                   =>      '1',  -- Used- must be powered up
        TSTCLK0                         =>      '0',
        TSTCLK1                         =>      '0',
        TSTIN0                          =>      (others => '0'),
        TSTIN1                          =>      (others => '0'),
        TSTOUT0                         =>      open,
        TSTOUT1                         =>      open,
        ----------------------- Receive Ports - 8b10b Decoder ----------------------
        RXCHARISCOMMA0                  =>      open,
        RXCHARISCOMMA1                  =>      open,
        RXCHARISK0                      =>      open,
        RXCHARISK1                      =>      open,
        RXDEC8B10BUSE0                  =>      '1',
        RXDEC8B10BUSE1                  =>      '1',
        RXDISPERR0                      =>      open,
        RXDISPERR1                      =>      open,
        RXNOTINTABLE0                   =>      open,
        RXNOTINTABLE1                   =>      open,
        RXRUNDISP0                      =>      open,
        RXRUNDISP1                      =>      open,
        USRCODEERR0                     =>      '0',
        USRCODEERR1                     =>      '0',
        ---------------------- Receive Ports - Channel Bonding ---------------------
        RXCHANBONDSEQ0                  =>      open,
        RXCHANBONDSEQ1                  =>      open,
        RXCHANISALIGNED0                =>      open,
        RXCHANISALIGNED1                =>      open,
        RXCHANREALIGN0                  =>      open,
        RXCHANREALIGN1                  =>      open,
        RXCHBONDI                       =>      (others => '0'),
        RXCHBONDMASTER0                 =>      '0',
        RXCHBONDMASTER1                 =>      '0',
        RXCHBONDO                       =>      open,
        RXCHBONDSLAVE0                  =>      '0',
        RXCHBONDSLAVE1                  =>      '0',
        RXENCHANSYNC0                   =>      '0',
        RXENCHANSYNC1                   =>      '0',
        ---------------------- Receive Ports - Clock Correction --------------------
        RXCLKCORCNT0                    =>      open,
        RXCLKCORCNT1                    =>      open,
        --------------- Receive Ports - Comma Detection and Alignment --------------
        RXBYTEISALIGNED0                =>      open,
        RXBYTEISALIGNED1                =>      open,
        RXBYTEREALIGN0                  =>      open,
        RXBYTEREALIGN1                  =>      open,
        RXCOMMADET0                     =>      open,
        RXCOMMADET1                     =>      open,
        RXCOMMADETUSE0                  =>      '1',
        RXCOMMADETUSE1                  =>      '1',
        RXENMCOMMAALIGN0                =>      '0',
        RXENMCOMMAALIGN1                =>      '0',
        RXENPCOMMAALIGN0                =>      '0',
        RXENPCOMMAALIGN1                =>      '0',
        RXSLIDE0                        =>      '0',
        RXSLIDE1                        =>      '0',
        ----------------------- Receive Ports - PRBS Detection ---------------------
        PRBSCNTRESET0                   =>      '1',
        PRBSCNTRESET1                   =>      '1',
        RXENPRBSTST0                    =>      "000",
        RXENPRBSTST1                    =>      "000",
        RXPRBSERR0                      =>      open,
        RXPRBSERR1                      =>      open,
        ------------------- Receive Ports - RX Data Path interface -----------------
        RXDATA0                         =>      open,
        RXDATA1                         =>      open,
        RXDATAWIDTH0                    =>      "01",
        RXDATAWIDTH1                    =>      "01",
        RXRECCLK0                       =>      open,
        RXRECCLK1                       =>      open,
        RXRESET0                        =>      '0',
        RXRESET1                        =>      '0',
        ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GATERXELECIDLE0                 =>      '0',
        GATERXELECIDLE1                 =>      '0',
        IGNORESIGDET0                   =>      '1',
        IGNORESIGDET1                   =>      '1',
        RCALINEAST                      =>      (others =>'0'),
        RCALINWEST                      =>      (others =>'0'),
        RCALOUTEAST                     =>      open,
        RCALOUTWEST                     =>      open,
        RXCDRRESET0                     =>      '0',
        RXCDRRESET1                     =>      '0',
        RXELECIDLE0                     =>      open,
        RXELECIDLE1                     =>      open,
        RXEQMIX0                        =>      "11",
        RXEQMIX1                        =>      "11",
        RXN0                            =>      '0',
        RXN1                            =>      '0',
        RXP0                            =>      '1',
        RXP1                            =>      '1',
        ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
        RXBUFRESET0                     =>      '0',
        RXBUFRESET1                     =>      '0',
        RXBUFSTATUS0                    =>      open,
        RXBUFSTATUS1                    =>      open,
        RXENPMAPHASEALIGN0              =>      '0',
        RXENPMAPHASEALIGN1              =>      '0',
        RXPMASETPHASE0                  =>      '0',
        RXPMASETPHASE1                  =>      '0',
        RXSTATUS0                       =>      open,
        RXSTATUS1                       =>      open,
        --------------- Receive Ports - RX Loss-of-sync State Machine --------------
        RXLOSSOFSYNC0                   =>      open,
        RXLOSSOFSYNC1                   =>      open,
        -------------- Receive Ports - RX Pipe Control for PCI Express -------------
        PHYSTATUS0                      =>      open,
        PHYSTATUS1                      =>      open,
        RXVALID0                        =>      open,
        RXVALID1                        =>      open,
        -------------------- Receive Ports - RX Polarity Control -------------------
        RXPOLARITY0                     =>      '0',
        RXPOLARITY1                     =>      '0',
        ------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
        DADDR                           =>      (others=>'0'),
        DCLK                            =>      '0',
        DEN                             =>      '0',
        DI                              =>      (others => '0'),
        DRDY                            =>      open,
        DRPDO                           =>      open,
        DWE                             =>      '0',
        ---------------------------- TX/RX Datapath Ports --------------------------
        GTPCLKFBEAST                    =>      open,
        GTPCLKFBSEL0EAST                =>      "10",
        GTPCLKFBSEL0WEST                =>      "00",
        GTPCLKFBSEL1EAST                =>      "11",
        GTPCLKFBSEL1WEST                =>      "01",
        GTPCLKFBWEST                    =>      open,
        ------------------- Transmit Ports - 8b10b Encoder Control -----------------
        TXBYPASS8B10B0                  =>      "0000",
        TXBYPASS8B10B1                  =>      "0000",
        TXKERR0                         =>      open,
        TXKERR1                         =>      open,
        TXRUNDISP0                      =>      open,
        TXRUNDISP1                      =>      open,
        --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
        TXBUFSTATUS0                    =>      open,
        TXBUFSTATUS1                    =>      open,
        TXENPMAPHASEALIGN0              =>      '0',
        TXENPMAPHASEALIGN1              =>      '0',
        TXPMASETPHASE0                  =>      '0',
        TXPMASETPHASE1                  =>      '0',
        ------------------ Transmit Ports - TX Data Path interface -----------------
        TXDATAWIDTH0                    =>      "01",
        TXDATAWIDTH1                    =>      "01",
        --------------- Transmit Ports - TX Driver and OOB signalling --------------
        TXBUFDIFFCTRL0                  =>      "101",
        TXBUFDIFFCTRL1                  =>      "101",
        TXINHIBIT0                      =>      '0',
        TXINHIBIT1                      =>      '0',
        --------------------- Transmit Ports - TX PRBS Generator -------------------
        TXENPRBSTST0                    =>      "000",
        TXENPRBSTST1                    =>      "000",
        TXPRBSFORCEERR0                 =>      '0',
        TXPRBSFORCEERR1                 =>      '0',
        -------------------- Transmit Ports - TX Polarity Control ------------------
        TXPOLARITY0                     =>      '0',
        TXPOLARITY1                     =>      '0',
        ----------------- Transmit Ports - TX Ports for PCI Express ----------------
        TXDETECTRX0                     =>      '0',
        TXDETECTRX1                     =>      '0',
        TXELECIDLE0                     =>      '0',
        TXELECIDLE1                     =>      '0',
        TXPDOWNASYNCH0                  =>      '0',
        TXPDOWNASYNCH1                  =>      '0',
        --------------------- Transmit Ports - TX Ports for SATA -------------------
        TXCOMSTART0                     =>      '0',
        TXCOMSTART1                     =>      '0',
        TXCOMTYPE0                      =>      '0',
        TXCOMTYPE1                      =>      '0'
    );
end Behavioral;