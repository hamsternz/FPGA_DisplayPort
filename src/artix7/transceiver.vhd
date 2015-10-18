----------------------------------------------------------------------------------
-- Module Name: transceiver - Behavioral
--
-- Description: A wrapper around the Xilinx 7-series GTX transceiver
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
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Transceiver is
    generic (
      use_hw_8b10b_support : std_logic  -- NOT YET IMPLEMENTED
   );
    Port ( mgmt_clk        : in  STD_LOGIC;
           powerup_channel : in  STD_LOGIC_VECTOR;

           preemp_0p0      : in  STD_LOGIC;
           preemp_3p5      : in  STD_LOGIC;
           preemp_6p0      : in  STD_LOGIC;
           
           swing_0p4       : in  STD_LOGIC;
           swing_0p6       : in  STD_LOGIC;
           swing_0p8       : in  STD_LOGIC;

           tx_running      : out STD_LOGIC_VECTOR := (others => '0');

           refclk0_p       : in  STD_LOGIC;
           refclk0_n       : in  STD_LOGIC;

           refclk1_p       : in  STD_LOGIC;
           refclk1_n       : in  STD_LOGIC;

           symbolclk       : out STD_LOGIC;
           in_symbols      : in  std_logic_vector(79 downto 0);

           debug          : out   std_logic_vector(7     downto 0) := (others => '0');
           
           gtptxp         : out std_logic_vector;
           gtptxn         : out std_logic_vector);
end transceiver;

architecture Behavioral of transceiver is

    signal txchardispmode  :   std_logic_vector( 4*gtptxp'length-1 downto 0)  := (others => '0');
    signal txchardispval   :   std_logic_vector( 4*gtptxp'length-1 downto 0)  := (others => '0');
    signal txdata_for_tx   :   std_logic_vector( 32*gtptxp'length-1 downto 0) := (others => '0');
    signal txdata_iskchark :   std_logic_vector( 4*gtptxp'length-1 downto 0)  := (others => '0');
    component gtx_tx_reset_controller is
    port (  clk             : in  std_logic;
            ref_clk         : in  std_logic;
            powerup_channel : in  std_logic;
            tx_running      : out std_logic;
            txreset         : out std_logic;
            txuserrdy       : out std_logic;
            txpmareset      : out std_logic;
            txpcsreset      : out std_logic;
            pllpd           : out std_logic;
            pllreset        : out std_logic;
            plllocken       : out std_logic;
            plllock         : in  std_logic;
            resetsel        : out std_logic;
            txresetdone     : in  std_logic);
    end component;

    signal refclk0        : std_logic;
    signal refclk1        : std_logic;
    signal ref_clk_fabric : std_logic_vector(gtptxp'high downto 0); -- need to connect;
    signal txreset        : std_logic_vector(gtptxp'high downto 0);
    signal txresetdone    : std_logic_vector(gtptxp'high downto 0);
    signal txpcsreset     : std_logic_vector(gtptxp'high downto 0);
    signal txpmareset     : std_logic_vector(gtptxp'high downto 0);
    signal txuserrdy      : std_logic_vector(gtptxp'high downto 0);
    signal pll0pd         : std_logic_vector(gtptxp'high downto 0);
    signal pll0reset      : std_logic_vector(gtptxp'high downto 0);
    signal pll0locken     : std_logic_vector(gtptxp'high downto 0);
    signal pll0lock       : std_logic;
    signal resetsel       : std_logic_vector(gtptxp'high downto 0);
    signal preemp_level   : std_logic_vector(4 downto 0); 
    signal swing_level    : std_logic_vector(3 downto 0); 

    constant PLL0_FBDIV_IN      :   integer := 4;
    constant PLL1_FBDIV_IN      :   integer := 1;
    constant PLL0_FBDIV_45_IN   :   integer := 5;
    constant PLL1_FBDIV_45_IN   :   integer := 4;
    constant PLL0_REFCLK_DIV_IN :   integer := 1;
    constant PLL1_REFCLK_DIV_IN :   integer := 1;
                   
    
    signal PLL0CLK        : STD_LOGIC;
    signal PLL0REFCLK     : STD_LOGIC;
    signal PLL1CLK        : STD_LOGIC;
    signal PLL1REFCLK     : STD_LOGIC;

    signal TXUSRCLK            : STD_LOGIC_vector(gtptxp'length-1 downto 0);
    signal TXUSRCLK2           : STD_LOGIC_vector(gtptxp'length-1 downto 0);
    signal tx_out_clk          : STD_LOGIC_vector(gtptxp'length-1 downto 0);
    signal tx_out_clk_buffered : STD_LOGIC;
begin
--    TXOUTCLKFABRIC <= ref_clk_fabric;
--    TXOUTCLK       <= tx_out_clk_buffered;
    symbolclk    <= tx_out_clk_buffered;
    
    preemp_level <= "10100" when preemp_6p0 = '1' else   -- +6.0 db from table 3-30 in UG476
                    "01101" when preemp_3p5 = '1' else   -- +3.5 db
                    "00000";                             -- +0.0 db

    swing_level  <= "1000" when swing_0p8 = '1' else     -- 0.8 V  
                    "0101" when swing_0p6 = '1' else     -- 0.6 V
                    "0010";                              -- 0.4 V

i_bufg: BUFG PORT MAP (
        i => tx_out_clk(0),
        o => tx_out_clk_buffered
    );
    
    

    -------------  GT txdata_i Assignments for 20 bit datapath  -------  
  

I_IBUFDS_GTE2_0 : IBUFDS_GTE2  
    port map
    (
        O               => 	refclk0,
        ODIV2           =>  open,
        CEB             => 	'0',
        I               => 	refclk0_p,
        IB              => 	refclk0_n
    );

I_IBUFDS_GTE2_1 : IBUFDS_GTE2  
    port map
    (
        O               => 	refclk1,
        ODIV2           =>  open,
        CEB             => 	'0',
        I               => 	refclk1_p,
        IB              => 	refclk1_n
    );

gtpe2_common_i : GTPE2_COMMON
    generic map
    (
            -- Simulation attributes
--            SIM_RESET_SPEEDUP    => WRAPPER_SIM_GTRESET_SPEEDUP,
--            SIM_PLL0REFCLK_SEL   => SIM_PLL0REFCLK_SEL,
--            SIM_PLL1REFCLK_SEL   => SIM_PLL1REFCLK_SEL,
--            SIM_VERSION          => ("2.0"),

            PLL0_FBDIV           => PLL0_FBDIV_IN     ,	
	        PLL0_FBDIV_45        => PLL0_FBDIV_45_IN  ,	
	        PLL0_REFCLK_DIV      => PLL0_REFCLK_DIV_IN,	
	        PLL1_FBDIV           => PLL1_FBDIV_IN     ,	
	        PLL1_FBDIV_45        => PLL1_FBDIV_45_IN  ,	
	        PLL1_REFCLK_DIV      => PLL1_REFCLK_DIV_IN,	            


       ------------------COMMON BLOCK Attributes---------------
        BIAS_CFG                                =>     (x"0000000000050001"),
        COMMON_CFG                              =>     (x"00000000"),

       ----------------------------PLL Attributes----------------------------
        PLL0_CFG                                =>     (x"01F03DC"),
        PLL0_DMON_CFG                           =>     ('0'),
        PLL0_INIT_CFG                           =>     (x"00001E"),
        PLL0_LOCK_CFG                           =>     (x"1E8"),
        PLL1_CFG                                =>     (x"01F03DC"),
        PLL1_DMON_CFG                           =>     ('0'),
        PLL1_INIT_CFG                           =>     (x"00001E"),
        PLL1_LOCK_CFG                           =>     (x"1E8"),
        PLL_CLKOUT_CFG                          =>     (x"00"),

       ----------------------------Reserved Attributes----------------------------
        RSVD_ATTR0                              =>     (x"0000"),
        RSVD_ATTR1                              =>     (x"0000")

        
    )
    port map
    (
        DMONITOROUT             => open,	
        ------------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
        DRPADDR                         =>      (others => '0'),
        DRPCLK                          =>      '0',
        DRPDI                           =>      (others => '0'),
        DRPDO                           =>      open,
        DRPEN                           =>      '0',
        DRPRDY                          =>      open,
        DRPWE                           =>      '0',
        ----------------- Common Block - GTPE2_COMMON Clocking Ports ---------------
        GTEASTREFCLK0                   =>      '0',
        GTEASTREFCLK1                   =>      '0',
        GTGREFCLK1                      =>      '0',
        GTREFCLK0                       =>      refclk0,
        GTREFCLK1                       =>      refclk1,
        GTWESTREFCLK0                   =>      '0',
        GTWESTREFCLK1                   =>      '0',
        PLL0OUTCLK                      =>      pll0clk,
        PLL0OUTREFCLK                   =>      pll0refclk,
        PLL1OUTCLK                      =>      pll1clk,
        PLL1OUTREFCLK                   =>      pll1refclk,
        -------------------------- Common Block - PLL Ports ------------------------
        PLL0FBCLKLOST                   =>      open,
        PLL0LOCK                        =>      pll0lock,
        PLL0LOCKDETCLK                  =>      mgmt_clk,
        PLL0LOCKEN                      =>      '1',
        PLL0PD                          =>      pll0pd(0),
        PLL0REFCLKLOST                  =>      open,
        PLL0REFCLKSEL                   =>      "001",  -- ref clock 0
        PLL0RESET                       =>      pll0reset(0),
        PLL1FBCLKLOST                   =>      open,
        PLL1LOCK                        =>      open,
        PLL1LOCKDETCLK                  =>      '0',
        PLL1LOCKEN                      =>      '1',
        PLL1PD                          =>      '1',
        PLL1REFCLKLOST                  =>      open,
        PLL1REFCLKSEL                   =>      "001",
        PLL1RESET                       =>      '0',
        ---------------------------- Common Block - Ports --------------------------
        BGRCALOVRDENB                   =>      '1',
        GTGREFCLK0                      =>      '0',
        PLLRSVD1                        =>      "0000000000000000",
        PLLRSVD2                        =>      "00000",
        REFCLKOUTMONITOR0               =>      open,
        REFCLKOUTMONITOR1               =>      open,
        ------------------------ Common Block - RX AFE Ports -----------------------
        PMARSVDOUT                      =>      open,
        --------------------------------- QPLL Ports -------------------------------
        BGBYPASSB                       =>      '1',
        BGMONITORENB                    =>      '1',
        BGPDB                           =>      '1',
        BGRCALOVRD                      =>      "11111",
        PMARSVD                         =>      "00000000",
        RCALENB                         =>      '1'
    );

g_tx: for i in 0 to gtptxp'high generate
    TXUSRCLK(i)       <= tx_out_clk_buffered;
    TXUSRCLK2(i)      <= tx_out_clk_buffered;

g_sw_8b10b: if use_hw_8b10b_support = '0' generate   
    txdata_for_tx(32*i+ 0) <= in_symbols(9+20*i);
    txdata_for_tx(32*i+ 1) <= in_symbols(8+20*i);
    txdata_for_tx(32*i+ 2) <= in_symbols(7+20*i);
    txdata_for_tx(32*i+ 3) <= in_symbols(6+20*i);
    txdata_for_tx(32*i+ 4) <= in_symbols(5+20*i);
    txdata_for_tx(32*i+ 5) <= in_symbols(4+20*i);
    txdata_for_tx(32*i+ 6) <= in_symbols(3+20*i);
    txdata_for_tx(32*i+ 7) <= in_symbols(2+20*i);
    txchardispval (4*i+ 0) <= in_symbols(1+20*i);
    txchardispmode(4*i+ 0) <= in_symbols(0+20*i);
    txdata_iskchark(4*i+0) <= '0'; -- does nothing!

    txdata_for_tx(32*i+ 8) <= in_symbols(19+20*i);
    txdata_for_tx(32*i+ 9) <= in_symbols(18+20*i);
    txdata_for_tx(32*i+10) <= in_symbols(17+20*i);
    txdata_for_tx(32*i+11) <= in_symbols(16+20*i);
    txdata_for_tx(32*i+12) <= in_symbols(15+20*i);
    txdata_for_tx(32*i+13) <= in_symbols(14+20*i);
    txdata_for_tx(32*i+14) <= in_symbols(13+20*i);
    txdata_for_tx(32*i+15) <= in_symbols(12+20*i);
    txchardispval (4*i+1)  <= in_symbols(11+20*i);
    txchardispmode(4*i+1)  <= in_symbols(10+20*i);
    txdata_iskchark(4*i+ 1) <= '0'; -- does nothing!
    end generate;


g_ww_8b10b: if use_hw_8b10b_support = '1' generate   
        txdata_for_tx(32*i+ 7 downto 32*i+ 0) <= in_symbols(7+20*i downto 0+20*i);
        txdata_iskchark(4*i+ 0)               <= in_symbols(8+20*i);
        txchardispval(4*i+ 0)                 <= '0';
        txchardispmode(4*i+ 0)                <= in_symbols(9+20*i);

        txdata_for_tx(32*i+ 15 downto 32*i+ 8) <= in_symbols(17+20*i downto 10+20*i);
        txdata_iskchark(4*i+1)                 <= in_symbols(18+20*i);
        txchardispval(4*i+1)                   <= '0';
        txchardispmode(4*i+1)                  <= in_symbols(19+20*i);
    end generate;

i_gtx_tx_reset_controller: gtx_tx_reset_controller
       port map (  clk         => mgmt_clk,
               ref_clk         => ref_clk_fabric(i),

               powerup_channel => powerup_channel(i),
               tx_running      => tx_running(i),

               pllpd           => pll0pd(i),
               pllreset        => pll0reset(i),
               plllocken       => pll0locken(i),
               plllock         => pll0lock,

               txreset         => txreset(i),
               txpmareset      => txpmareset(i),
               txpcsreset      => txpcsreset(i),
               txuserrdy       => txuserrdy(i),
               resetsel        => resetsel(i),
               txresetdone     => txresetdone(i));
 
gtpe2_i : GTPE2_CHANNEL
    generic map
    (

        --_______________________ Simulation-Only Attributes ___________________

        SIM_RECEIVER_DETECT_PASS   =>      ("TRUE"),
        SIM_RESET_SPEEDUP          =>      ("TRUE"),
        SIM_TX_EIDLE_DRIVE_LEVEL   =>      ("X"),
        SIM_VERSION                =>      ("2.0"),

       ------------------RX Byte and Word Alignment Attributes---------------
        ALIGN_COMMA_DOUBLE         =>     ("FALSE"),
        ALIGN_COMMA_ENABLE         =>     ("1111111111"),
        ALIGN_COMMA_WORD           =>     (1),
        ALIGN_MCOMMA_DET           =>     ("TRUE"),
        ALIGN_MCOMMA_VALUE         =>     ("1010000011"),
        ALIGN_PCOMMA_DET           =>     ("TRUE"),
        ALIGN_PCOMMA_VALUE         =>     ("0101111100"),
        SHOW_REALIGN_COMMA         =>     ("TRUE"),
        RXSLIDE_AUTO_WAIT          =>     (7),
        RXSLIDE_MODE               =>     ("OFF"),
        RX_SIG_VALID_DLY           =>     (10),

       ------------------RX 8B/10B Decoder Attributes---------------
        RX_DISPERR_SEQ_MATCH       =>     ("FALSE"),
        DEC_MCOMMA_DETECT          =>     ("FALSE"),
        DEC_PCOMMA_DETECT          =>     ("FALSE"),
        DEC_VALID_COMMA_ONLY       =>     ("FALSE"),

       ------------------------RX Clock Correction Attributes----------------------
        CBCC_DATA_SOURCE_SEL       =>     ("ENCODED"),
        CLK_COR_SEQ_2_USE          =>     ("FALSE"),
        CLK_COR_KEEP_IDLE          =>     ("FALSE"),
        CLK_COR_MAX_LAT            =>     (9),
        CLK_COR_MIN_LAT            =>     (7),
        CLK_COR_PRECEDENCE         =>     ("TRUE"),
        CLK_COR_REPEAT_WAIT        =>     (0),
        CLK_COR_SEQ_LEN            =>     (1),
        CLK_COR_SEQ_1_ENABLE       =>     ("1111"),
        CLK_COR_SEQ_1_1            =>     ("0100000000"),
        CLK_COR_SEQ_1_2            =>     ("0000000000"),
        CLK_COR_SEQ_1_3            =>     ("0000000000"),
        CLK_COR_SEQ_1_4            =>     ("0000000000"),
        CLK_CORRECT_USE            =>     ("FALSE"),
        CLK_COR_SEQ_2_ENABLE       =>     ("1111"),
        CLK_COR_SEQ_2_1            =>     ("0100000000"),
        CLK_COR_SEQ_2_2            =>     ("0000000000"),
        CLK_COR_SEQ_2_3            =>     ("0000000000"),
        CLK_COR_SEQ_2_4            =>     ("0000000000"),

       ------------------------RX Channel Bonding Attributes----------------------
        CHAN_BOND_KEEP_ALIGN       =>     ("FALSE"),
        CHAN_BOND_MAX_SKEW         =>     (1),
        CHAN_BOND_SEQ_LEN          =>     (1),
        CHAN_BOND_SEQ_1_1          =>     ("0000000000"),
        CHAN_BOND_SEQ_1_2          =>     ("0000000000"),
        CHAN_BOND_SEQ_1_3          =>     ("0000000000"),
        CHAN_BOND_SEQ_1_4          =>     ("0000000000"),
        CHAN_BOND_SEQ_1_ENABLE     =>     ("1111"),
        CHAN_BOND_SEQ_2_1          =>     ("0000000000"),
        CHAN_BOND_SEQ_2_2          =>     ("0000000000"),
        CHAN_BOND_SEQ_2_3          =>     ("0000000000"),
        CHAN_BOND_SEQ_2_4          =>     ("0000000000"),
        CHAN_BOND_SEQ_2_ENABLE     =>     ("1111"),
        CHAN_BOND_SEQ_2_USE        =>     ("FALSE"),
        FTS_DESKEW_SEQ_ENABLE      =>     ("1111"),
        FTS_LANE_DESKEW_CFG        =>     ("1111"),
        FTS_LANE_DESKEW_EN         =>     ("FALSE"),

       ---------------------------RX Margin Analysis Attributes----------------------------
        ES_CONTROL                 =>     ("000000"),
        ES_ERRDET_EN               =>     ("FALSE"),
        ES_EYE_SCAN_EN             =>     ("FALSE"),
        ES_HORZ_OFFSET             =>     (x"010"),
        ES_PMA_CFG                 =>     ("0000000000"),
        ES_PRESCALE                =>     ("00000"),
        ES_QUALIFIER               =>     (x"00000000000000000000"),
        ES_QUAL_MASK               =>     (x"00000000000000000000"),
        ES_SDATA_MASK              =>     (x"00000000000000000000"),
        ES_VERT_OFFSET             =>     ("000000000"),

       -------------------------FPGA RX Interface Attributes-------------------------
        RX_DATA_WIDTH                           =>     (20),

       ---------------------------PMA Attributes----------------------------
        OUTREFCLK_SEL_INV          =>     ("11"),
        PMA_RSV                    =>     (x"00000333"),
        PMA_RSV2                   =>     (x"00002040"),
        PMA_RSV3                   =>     ("00"),
        PMA_RSV4                   =>     ("0000"),
        RX_BIAS_CFG                =>     ("0000111100110011"),
        DMONITOR_CFG               =>     (x"000A00"),
        RX_CM_SEL                  =>     ("01"),
        RX_CM_TRIM                 =>     ("0000"),
        RX_DEBUG_CFG               =>     ("00000000000000"),
        RX_OS_CFG                  =>     ("0000010000000"),
        TERM_RCAL_CFG              =>     ("100001000010000"),
        TERM_RCAL_OVRD             =>     ("000"),
        TST_RSV                    =>     (x"00000000"),
        RX_CLK25_DIV               =>     (6),
        TX_CLK25_DIV               =>     (6),
        UCODEER_CLR                =>     ('0'),

       ---------------------------PCI Express Attributes----------------------------
        PCS_PCIE_EN                =>     ("FALSE"),

       ---------------------------PCS Attributes----------------------------
        PCS_RSVD_ATTR              =>     (x"000000000000"),

       -------------RX Buffer Attributes------------
        RXBUF_ADDR_MODE            =>     ("FAST"),
        RXBUF_EIDLE_HI_CNT         =>     ("1000"),
        RXBUF_EIDLE_LO_CNT         =>     ("0000"),
        RXBUF_EN                   =>     ("TRUE"),
        RX_BUFFER_CFG              =>     ("000000"),
        RXBUF_RESET_ON_CB_CHANGE   =>     ("TRUE"),
        RXBUF_RESET_ON_COMMAALIGN  =>     ("FALSE"),
        RXBUF_RESET_ON_EIDLE       =>     ("FALSE"),
        RXBUF_RESET_ON_RATE_CHANGE =>     ("TRUE"),
        RXBUFRESET_TIME            =>     ("00001"),
        RXBUF_THRESH_OVFLW         =>     (61),
        RXBUF_THRESH_OVRD          =>     ("FALSE"),
        RXBUF_THRESH_UNDFLW        =>     (4),
        RXDLY_CFG                  =>     (x"001F"),
        RXDLY_LCFG                 =>     (x"030"),
        RXDLY_TAP_CFG              =>     (x"0000"),
        RXPH_CFG                   =>     (x"C00002"),
        RXPHDLY_CFG                =>     (x"084020"),
        RXPH_MONITOR_SEL           =>     ("00000"),
        RX_XCLK_SEL                =>     ("RXREC"),
        RX_DDI_SEL                 =>     ("000000"),
        RX_DEFER_RESET_BUF_EN      =>     ("TRUE"),

       -----------------------CDR Attributes-------------------------
        RXCDR_CFG                  =>     (x"0001107FE206021081010"),
        RXCDR_FR_RESET_ON_EIDLE    =>     ('0'),
        RXCDR_HOLD_DURING_EIDLE    =>     ('0'),
        RXCDR_PH_RESET_ON_EIDLE    =>     ('0'),
        RXCDR_LOCK_CFG             =>     ("001001"),

       -------------------RX Initialization and Reset Attributes-------------------
        RXCDRFREQRESET_TIME        =>     ("00001"),
        RXCDRPHRESET_TIME          =>     ("00001"),
        RXISCANRESET_TIME          =>     ("00001"),
        RXPCSRESET_TIME            =>     ("00001"),
        RXPMARESET_TIME            =>     ("00011"),

       -------------------RX OOB Signaling Attributes-------------------
        RXOOB_CFG                  =>     ("0000110"),

       -------------------------RX Gearbox Attributes---------------------------
        RXGEARBOX_EN               =>     ("FALSE"),
        GEARBOX_MODE               =>     ("000"),

       -------------------------PRBS Detection Attribute-----------------------
        RXPRBS_ERR_LOOPBACK        =>     ('0'),

       -------------Power-Down Attributes----------
        PD_TRANS_TIME_FROM_P2      =>     (x"03c"),
        PD_TRANS_TIME_NONE_P2      =>     (x"3c"),
        PD_TRANS_TIME_TO_P2        =>     (x"64"),

       -------------RX OOB Signaling Attributes----------
        SAS_MAX_COM                =>     (64),
        SAS_MIN_COM                =>     (36),
        SATA_BURST_SEQ_LEN         =>     ("0101"),
        SATA_BURST_VAL             =>     ("100"),
        SATA_EIDLE_VAL             =>     ("100"),
        SATA_MAX_BURST             =>     (8),
        SATA_MAX_INIT              =>     (21),
        SATA_MAX_WAKE              =>     (7),
        SATA_MIN_BURST             =>     (4),
        SATA_MIN_INIT              =>     (12),
        SATA_MIN_WAKE              =>     (4),

       -------------RX Fabric Clock Output Control Attributes----------
        TRANS_TIME_RATE            =>     (x"0E"),

       --------------TX Buffer Attributes----------------
        TXBUF_EN                   =>     ("TRUE"),
        TXBUF_RESET_ON_RATE_CHANGE =>     ("TRUE"),
        TXDLY_CFG                  =>     (x"001F"),
        TXDLY_LCFG                 =>     (x"030"),
        TXDLY_TAP_CFG              =>     (x"0000"),
        TXPH_CFG                   =>     (x"0780"),
        TXPHDLY_CFG                =>     (x"084020"),
        TXPH_MONITOR_SEL           =>     ("00000"),
        TX_XCLK_SEL                =>     ("TXOUT"),

       -------------------------FPGA TX Interface Attributes-------------------------
        TX_DATA_WIDTH              =>     (20),

       -------------------------TX Configurable Driver Attributes-------------------------
        TX_DEEMPH0                 =>     ("000000"),
        TX_DEEMPH1                 =>     ("000000"),
        TX_EIDLE_ASSERT_DELAY      =>     ("110"),
        TX_EIDLE_DEASSERT_DELAY    =>     ("100"),
        TX_LOOPBACK_DRIVE_HIZ      =>     ("FALSE"),
        TX_MAINCURSOR_SEL          =>     ('0'),
        TX_DRIVE_MODE              =>     ("DIRECT"),
        TX_MARGIN_FULL_0           =>     ("1001110"),
        TX_MARGIN_FULL_1           =>     ("1001001"),
        TX_MARGIN_FULL_2           =>     ("1000101"),
        TX_MARGIN_FULL_3           =>     ("1000010"),
        TX_MARGIN_FULL_4           =>     ("1000000"),
        TX_MARGIN_LOW_0            =>     ("1000110"),
        TX_MARGIN_LOW_1            =>     ("1000100"),
        TX_MARGIN_LOW_2            =>     ("1000010"),
        TX_MARGIN_LOW_3            =>     ("1000000"),
        TX_MARGIN_LOW_4            =>     ("1000000"),

       -------------------------TX Gearbox Attributes--------------------------
        TXGEARBOX_EN               =>     ("FALSE"),

       -------------------------TX Initialization and Reset Attributes--------------------------
        TXPCSRESET_TIME            =>     ("00001"),
        TXPMARESET_TIME            =>     ("00001"),

       -------------------------TX Receiver Detection Attributes--------------------------
        TX_RXDETECT_CFG            =>     (x"1832"),
        TX_RXDETECT_REF            =>     ("100"),

       ------------------ JTAG Attributes ---------------
        ACJTAG_DEBUG_MODE          =>     ('0'),
        ACJTAG_MODE                =>     ('0'),
        ACJTAG_RESET               =>     ('0'),

       ------------------ CDR Attributes ---------------
        CFOK_CFG                   =>     (x"49000040E80"),
        CFOK_CFG2                  =>     ("0100000"),
        CFOK_CFG3                  =>     ("0100000"),
        CFOK_CFG4                  =>     ('0'),
        CFOK_CFG5                  =>     (x"0"),
        CFOK_CFG6                  =>     ("0000"),
        RXOSCALRESET_TIME          =>     ("00011"),
        RXOSCALRESET_TIMEOUT       =>     ("00000"),

       ------------------ PMA Attributes ---------------
        CLK_COMMON_SWING           =>     ('0'),
        RX_CLKMUX_EN               =>     ('1'),
        TX_CLKMUX_EN               =>     ('1'),
        ES_CLK_PHASE_SEL           =>     ('0'),
        USE_PCS_CLK_PHASE_SEL      =>     ('0'),
        PMA_RSV6                   =>     ('0'),
        PMA_RSV7                   =>     ('0'),

       ------------------ TX Configuration Driver Attributes ---------------
        TX_PREDRIVER_MODE          =>     ('0'),
        PMA_RSV5                   =>     ('0'),
        SATA_PLL_CFG               =>     ("VCO_3000MHZ"),

       ------------------ RX Fabric Clock Output Control Attributes ---------------
        RXOUT_DIV                  =>     (2),

       ------------------ TX Fabric Clock Output Control Attributes ---------------
        TXOUT_DIV                  =>     (2),

       ------------------ RX Phase Interpolator Attributes---------------
        RXPI_CFG0                  =>     ("000"),
        RXPI_CFG1                  =>     ('1'),
        RXPI_CFG2                  =>     ('1'),

       --------------RX Equalizer Attributes-------------
        ADAPT_CFG0                 =>     (x"00000"),
        RXLPMRESET_TIME            =>     ("0001111"),
        RXLPM_BIAS_STARTUP_DISABLE =>     ('0'),
        RXLPM_CFG                  =>     ("0110"),
        RXLPM_CFG1                 =>     ('0'),
        RXLPM_CM_CFG                            =>     ('0'),
        RXLPM_GC_CFG                            =>     ("111100010"),
        RXLPM_GC_CFG2                           =>     ("001"),
        RXLPM_HF_CFG                            =>     ("00001111110000"),
        RXLPM_HF_CFG2                           =>     ("01010"),
        RXLPM_HF_CFG3                           =>     ("0000"),
        RXLPM_HOLD_DURING_EIDLE                 =>     ('0'),
        RXLPM_INCM_CFG                          =>     ('0'),
        RXLPM_IPCM_CFG                          =>     ('1'),
        RXLPM_LF_CFG                            =>     ("000000001111110000"),
        RXLPM_LF_CFG2                           =>     ("01010"),
        RXLPM_OSINT_CFG                         =>     ("100"),

       ------------------ TX Phase Interpolator PPM Controller Attributes---------------
        TXPI_CFG0                               =>     ("00"),
        TXPI_CFG1                               =>     ("00"),
        TXPI_CFG2                               =>     ("00"),
        TXPI_CFG3                               =>     ('0'),
        TXPI_CFG4                               =>     ('0'),
        TXPI_CFG5                               =>     ("000"),
        TXPI_GREY_SEL                           =>     ('0'),
        TXPI_INVSTROBE_SEL                      =>     ('0'),
        TXPI_PPMCLK_SEL                         =>     ("TXUSRCLK2"),
        TXPI_PPM_CFG                            =>     (x"00"),
        TXPI_SYNFREQ_PPM                        =>     ("000"),

       ------------------ LOOPBACK Attributes---------------
        LOOPBACK_CFG                            =>     ('0'),
        PMA_LOOPBACK_CFG                        =>     ('0'),

       ------------------RX OOB Signalling Attributes---------------
        RXOOB_CLK_CFG                           =>     ("PMA"),

       ------------------TX OOB Signalling Attributes---------------
        TXOOB_CFG                               =>     ('0'),

       ------------------RX Buffer Attributes---------------
        RXSYNC_MULTILANE                        =>     ('1'),
        RXSYNC_OVRD                             =>     ('0'),
        RXSYNC_SKIP_DA                          =>     ('0'),

       ------------------TX Buffer Attributes---------------
        TXSYNC_MULTILANE                        =>     ('0'),
        TXSYNC_OVRD                             =>     ('0'),
        TXSYNC_SKIP_DA                          =>     ('0')


    )
    port map
    (
        --------------------------------- CPLL Ports -------------------------------
        GTRSVD                     =>      "0000000000000000",
        PCSRSVDIN                  =>      "0000000000000000",
        TSTIN                      =>      "11111111111111111111",
        ---------------------------- Channel - DRP Ports  --------------------------
        DRPADDR                    =>      (others => '0'),
        DRPCLK                     =>      '0',
        DRPDI                      =>      (others => '0'),
        DRPDO                      =>      open,
        DRPEN                      =>      '0',
        DRPRDY                     =>      open,
        DRPWE                      =>      '0',
        ------------------------------- Clocking Ports -----------------------------
        RXSYSCLKSEL                =>      "11",
        TXSYSCLKSEL                =>      "00",
        ----------------- FPGA TX Interface Datapath Configuration  ----------------
        TX8B10BEN                  =>      use_hw_8b10b_support,
        ------------------------ GTPE2_CHANNEL Clocking Ports ----------------------
        PLL0CLK                    =>      pll0clk,
        PLL0REFCLK                 =>      pll0refclk,
        PLL1CLK                    =>      pll1clk,
        PLL1REFCLK                 =>      pll1refclk,
        ------------------------------- Loopback Ports -----------------------------
        LOOPBACK                   =>      (others => '0'),
        ----------------------------- PCI Express Ports ----------------------------
        PHYSTATUS                  =>      open,
        RXRATE                     =>      (others => '0'),
        RXVALID                    =>      open,
        ----------------------------- PMA Reserved Ports ---------------------------
        PMARSVDIN3                      =>      '0',
        PMARSVDIN4                      =>      '0',
        ------------------------------ Power-Down Ports ----------------------------
        RXPD                            =>      "11",
        TXPD                            =>      "00",
        -------------------------- RX 8B/10B Decoder Ports -------------------------
        SETERRSTATUS                    =>      '0',
        --------------------- RX Initialization and Reset Ports --------------------
        EYESCANRESET                    =>      '0',
        RXUSERRDY                       =>      '0',
        -------------------------- RX Margin Analysis Ports ------------------------
        EYESCANDATAERROR                =>      open,
        EYESCANMODE                     =>      '0',
        EYESCANTRIGGER                  =>      '0',
        ------------------------------- Receive Ports ------------------------------
        CLKRSVD0                        =>      '0',
        CLKRSVD1                        =>      '0',
        DMONFIFORESET                   =>      '0',
        DMONITORCLK                     =>      '0',
        RXPMARESETDONE                  =>      open,
        SIGVALIDCLK                     =>      '0',
        ------------------------- Receive Ports - CDR Ports ------------------------
        RXCDRFREQRESET                  =>      '0',
        RXCDRHOLD                       =>      '0',
        RXCDRLOCK                       =>      open,
        RXCDROVRDEN                     =>      '0',
        RXCDRRESET                      =>      '0',
        RXCDRRESETRSV                   =>      '0',
        RXOSCALRESET                    =>      '0',
        RXOSINTCFG                      =>      "0010",
        RXOSINTDONE                     =>      open,
        RXOSINTHOLD                     =>      '0',
        RXOSINTOVRDEN                   =>      '0',
        RXOSINTPD                       =>      '0',
        RXOSINTSTARTED                  =>      open,
        RXOSINTSTROBE                   =>      '0',
        RXOSINTSTROBESTARTED            =>      open,
        RXOSINTTESTOVRDEN               =>      '0',
        ------------------- Receive Ports - Clock Correction Ports -----------------
        RXCLKCORCNT                     =>      open,
        ---------- Receive Ports - FPGA RX Interface Datapath Configuration --------
        RX8B10BEN                       =>      '0',
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        RXDATA                          =>      open,
        RXUSRCLK                        =>      '0',
        RXUSRCLK2                       =>      '0',
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        RXPRBSERR                       =>      open,
        RXPRBSSEL                       =>      (others => '0'),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        RXPRBSCNTRESET                  =>      '0',
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        RXCHARISCOMMA                   =>      open,
        RXCHARISK                       =>      open,
        RXDISPERR                       =>      open,
        RXNOTINTABLE                    =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GTPRXN                          =>      '0',
        GTPRXP                          =>      '0',
        PMARSVDIN2                      =>      '0',
        PMARSVDOUT0                     =>      open,
        PMARSVDOUT1                     =>      open,
        ------------------- Receive Ports - RX Buffer Bypass Ports -----------------
        RXBUFRESET                      =>      '0',
        RXBUFSTATUS                     =>      open,
        RXDDIEN                         =>      '0',
        RXDLYBYPASS                     =>      '1',
        RXDLYEN                         =>      '0',
        RXDLYOVRDEN                     =>      '0',
        RXDLYSRESET                     =>      '0',
        RXDLYSRESETDONE                 =>      open,
        RXPHALIGN                       =>      '0',
        RXPHALIGNDONE                   =>      open,
        RXPHALIGNEN                     =>      '0',
        RXPHDLYPD                       =>      '1',
        RXPHDLYRESET                    =>      '0',
        RXPHMONITOR                     =>      open,
        RXPHOVRDEN                      =>      '0',
        RXPHSLIPMONITOR                 =>      open,
        RXSTATUS                        =>      open,
        RXSYNCALLIN                     =>      '0',
        RXSYNCDONE                      =>      open,
        RXSYNCIN                        =>      '0',
        RXSYNCMODE                      =>      '0',
        RXSYNCOUT                       =>      open,
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        RXBYTEISALIGNED                 =>      open,
        RXBYTEREALIGN                   =>      open,
        RXCOMMADET                      =>      open,
        RXCOMMADETEN                    =>      '0',
        RXMCOMMAALIGNEN                 =>      '0',
        RXPCOMMAALIGNEN                 =>      '0',
        RXSLIDE                         =>      '0',
        ------------------ Receive Ports - RX Channel Bonding Ports ----------------
        RXCHANBONDSEQ                   =>      open,
        RXCHBONDEN                      =>      '0',
        RXCHBONDI                       =>      "0000",
        RXCHBONDLEVEL                   =>      (others => '0'),
        RXCHBONDMASTER                  =>      '0',
        RXCHBONDO                       =>      open,
        RXCHBONDSLAVE                   =>      '0',
        ----------------- Receive Ports - RX Channel Bonding Ports  ----------------
        RXCHANISALIGNED                 =>      open,
        RXCHANREALIGN                   =>      open,
        ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        DMONITOROUT                     =>      open,
        RXADAPTSELTEST                  =>      (others => '0'),
        RXDFEXYDEN                      =>      '0',
        RXOSINTEN                       =>      '1',
        RXOSINTID0                      =>      (others => '0'),
        RXOSINTNTRLEN                   =>      '0',
        RXOSINTSTROBEDONE               =>      open,
        ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        RXLPMLFOVRDEN                   =>      '0',
        RXLPMOSINTNTRLEN                =>      '0',
        -------------------- Receive Ports - RX Equailizer Ports -------------------
        RXLPMHFHOLD                     =>      '0',
        RXLPMHFOVRDEN                   =>      '0',
        RXLPMLFHOLD                     =>      '0',
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        RXOSHOLD                        =>      '0',
        RXOSOVRDEN                      =>      '0',
        ------------ Receive Ports - RX Fabric ClocK Output Control Ports ----------
        RXRATEDONE                      =>      open,
        ----------- Receive Ports - RX Fabric Clock Output Control Ports  ----------
        RXRATEMODE                      =>      '0',
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        RXOUTCLK                        =>      open,
        RXOUTCLKFABRIC                  =>      open,
        RXOUTCLKPCS                     =>      open,
        RXOUTCLKSEL                     =>      "010",
        ---------------------- Receive Ports - RX Gearbox Ports --------------------
        RXDATAVALID                     =>      open,
        RXHEADER                        =>      open,
        RXHEADERVALID                   =>      open,
        RXSTARTOFSEQ                    =>      open,
        --------------------- Receive Ports - RX Gearbox Ports  --------------------
        RXGEARBOXSLIP                   =>      '0',
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GTRXRESET                       =>      '1',
        RXLPMRESET                      =>      '1',
        RXOOBRESET                      =>      '0',
        RXPCSRESET                      =>      '0',
        RXPMARESET                      =>      '0',
        ------------------- Receive Ports - RX OOB Signaling ports -----------------
        RXCOMSASDET                     =>      open,
        RXCOMWAKEDET                    =>      open,
        ------------------ Receive Ports - RX OOB Signaling ports  -----------------
        RXCOMINITDET                    =>      open,
        ------------------ Receive Ports - RX OOB signalling Ports -----------------
        RXELECIDLE                      =>      open,
        RXELECIDLEMODE                  =>      "11",
        ----------------- Receive Ports - RX Polarity Control Ports ----------------
        RXPOLARITY                      =>      '0',
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        RXRESETDONE                     =>      open,
        --------------------------- TX Buffer Bypass Ports -------------------------
        TXPHDLYTSTCLK                   =>      '0',
        ------------------------ TX Configurable Driver Ports ----------------------
        TXPOSTCURSOR                    =>      "00000",
        TXPOSTCURSORINV                 =>      '0',
        TXPRECURSOR                     =>      preemp_level,
        TXPRECURSORINV                  =>      '0',
        -------------------- TX Fabric Clock Output Control Ports ------------------
        TXRATEMODE                      =>      '0',
        --------------------- TX Initialization and Reset Ports --------------------
        CFGRESET                        =>      '0',
        GTTXRESET                       =>      txreset(i),
        PCSRSVDOUT                      =>      open,
        TXUSERRDY                       =>      txuserrdy(i),
        ----------------- TX Phase Interpolator PPM Controller Ports ---------------
        TXPIPPMEN                       =>      '0',
        TXPIPPMOVRDEN                   =>      '0',
        TXPIPPMPD                       =>      '0',
        TXPIPPMSEL                      =>      '1',
        TXPIPPMSTEPSIZE                 =>      (others => '0'),
        ---------------------- Transceiver Reset Mode Operation --------------------
        GTRESETSEL                      =>      resetsel(i),
        RESETOVRD                       =>      '0',
        ------------------------------- Transmit Ports -----------------------------
        TXPMARESETDONE                  =>      open,
        ----------------- Transmit Ports - Configurable Driver Ports ---------------
        PMARSVDIN0                      =>      '0',
        PMARSVDIN1                      =>      '0',
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        TXDATA                          =>      txdata_for_tx(31+32*i downto 32*i),
        TXUSRCLK                        =>      txusrclk(i),
        TXUSRCLK2                       =>      txusrclk2(i),
        --------------------- Transmit Ports - PCI Express Ports -------------------
        TXELECIDLE                      =>      '0',
        TXMARGIN                        =>      (others => '0'),
        TXRATE                          =>      (others => '0'),
        TXSWING                         =>      '0',
        ------------------ Transmit Ports - Pattern Generator Ports ----------------
        TXPRBSFORCEERR                  =>      '0',
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        TX8B10BBYPASS                   =>      (others => '0'),
        TXCHARDISPMODE                  =>      txchardispmode(3+4*i downto 4*i),
        TXCHARDISPVAL                   =>      txchardispval(3+4*i downto 4*i),
        TXCHARISK                       =>      txdata_iskchark(3+4*i downto 4*i),
        ------------------ Transmit Ports - TX Buffer Bypass Ports -----------------
        TXDLYBYPASS                     =>      '1',
        TXDLYEN                         =>      '0',
        TXDLYHOLD                       =>      '0',
        TXDLYOVRDEN                     =>      '0',
        TXDLYSRESET                     =>      '0',
        TXDLYSRESETDONE                 =>      open,
        TXDLYUPDOWN                     =>      '0',
        TXPHALIGN                       =>      '0',
        TXPHALIGNDONE                   =>      open,
        TXPHALIGNEN                     =>      '0',
        TXPHDLYPD                       =>      '0',
        TXPHDLYRESET                    =>      '0',
        TXPHINIT                        =>      '0',
        TXPHINITDONE                    =>      open,
        TXPHOVRDEN                      =>      '0',
        ---------------------- Transmit Ports - TX Buffer Ports --------------------
        TXBUFSTATUS                     =>      open,
        ------------ Transmit Ports - TX Buffer and Phase Alignment Ports ----------
        TXSYNCALLIN                     =>      '0',
        TXSYNCDONE                      =>      open,
        TXSYNCIN                        =>      '0',
        TXSYNCMODE                      =>      '0',
        TXSYNCOUT                       =>      open,
        --------------- Transmit Ports - TX Configurable Driver Ports --------------
        GTPTXN                          =>      gtptxn(i),
        GTPTXP                          =>      gtptxp(i),
        TXBUFDIFFCTRL                   =>      "100",
        TXDEEMPH                        =>      '0',
        TXDIFFCTRL                      =>      swing_level,
        TXDIFFPD                        =>      '0',
        TXINHIBIT                       =>      '0',
        TXMAINCURSOR                    =>      "0000000",
        TXPISOPD                        =>      '0',
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        TXOUTCLK                        =>      tx_out_clk(i),
        TXOUTCLKFABRIC                  =>      ref_clk_fabric(i), --txoutclkfabric,
        TXOUTCLKPCS                     =>      open,
        TXOUTCLKSEL                     =>      "010",
        TXRATEDONE                      =>      open,
        --------------------- Transmit Ports - TX Gearbox Ports --------------------
        TXGEARBOXREADY                  =>      open,
        TXHEADER                        =>      (others => '0'),
        TXSEQUENCE                      =>      (others => '0'),
        TXSTARTSEQ                      =>      '0',
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        TXPCSRESET                      =>      txpcsreset(i),
        TXPMARESET                      =>      txpmareset(i),
        TXRESETDONE                     =>      txresetdone(i),
        ------------------ Transmit Ports - TX OOB signalling Ports ----------------
        TXCOMFINISH                     =>      open,
        TXCOMINIT                       =>      '0',
        TXCOMSAS                        =>      '0',
        TXCOMWAKE                       =>      '0',
        TXPDELECIDLEMODE                =>      '0',
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        TXPOLARITY                      =>      '0',
        --------------- Transmit Ports - TX Receiver Detection Ports  --------------
        TXDETECTRX                      =>      '0',
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        TXPRBSSEL                       =>      (others => '0')
    );
    end generate;
end Behavioral;
