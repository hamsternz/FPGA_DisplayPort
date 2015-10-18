----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz 
-- 
-- Module Name: data_to_8b10b - Behavioral
--
-- Description: A pipelined implmentation to convert two 8-bit data words and
--              two sets of flags into ANSI 8b/10b symbols for transmission by
--              a high speed serial interface.
--
-- NOTE: The bit order is flipped from what is in the table to match the order
--       in which the transceiver transmits the data (LSB first). The standard
--       requires that it is sent  MSB first.
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
--  0.2 | 2015-09-18 | Move bit reordering into the transceiver
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_to_8b10b is
        port ( 
            clk      : in  std_logic;
            in_data  : in  std_logic_vector(19 downto 0);
            out_data : out std_logic_vector(19 downto 0) := (others => '0')
        );
end entity;

architecture arch of data_to_8b10b is
    signal current_disparity_neg : std_logic := '0';

    -- Stage 2 stuff
    signal data0_2          : std_logic_vector(7 downto 0) := (others => '0');
    signal data0k_2         : std_logic  := '0';
    signal data1_2          : std_logic_vector(7 downto 0) := (others => '0');
    signal data1k_2         : std_logic  := '0';
    signal disparity0_neg_2 : std_logic := '0';
    signal disparity1_neg_2 : std_logic := '0';

    -- Stage 1 stuff
    signal disparity0_odd_1 : std_logic  := '0';
    signal data0_1          : std_logic_vector(7 downto 0) := (others => '0');
    signal data0k_1         : std_logic  := '0';
    signal data0forceneg_1  : std_logic  := '0';
    signal disparity1_odd_1 : std_logic  := '0';
    signal data1_1          : std_logic_vector(7 downto 0) := (others => '0');
    signal data1k_1         : std_logic  := '0';
    signal data1forceneg_1  : std_logic  := '0';

    constant disparity_d : std_logic_vector(255 downto 0) :=
        "00010110011111100111111011101000" &
        "11101001100000011000000100010111" &
        "11101001100000011000000100010111" &
        "00010110011111100111111011101000" &
        "11101001100000011000000100010111" &
        "11101001100000011000000100010111" &
        "11101001100000011000000100010111" &
        "00010110011111100111111011101000";

    constant disparity_k : std_logic_vector(255 downto 0) :=
        "00000000000000000000000000000000" &
        "00010000000000000000000000000000" &
        "00010000000000000000000000000000" &
        "00000000000000000000000000000000" &
        "00010000000000000000000000000000" &
        "00010000000000000000000000000000" &
        "00010000000000000000000000000000" &
        "00000000000000000000000000000000";

    type a_symbols is array(0 to 511) of std_logic_vector(9 downto 0);
    constant d_symbols : a_symbols := (
        -- Pos RD,       Neg RD
        "0110001011", "1001110100",  -- D0.0
        "1000101011", "0111010100",  -- D1.0
        "0100101011", "1011010100",  -- D2.0
        "1100010100", "1100011011",  -- D3.0
        "0010101011", "1101010100",  -- D4.0
        "1010010100", "1010011011",  -- D5.0
        "0110010100", "0110011011",  -- D6.0
        "0001110100", "1110001011",  -- D7.0
        "0001101011", "1110010100",  -- D8.0
        "1001010100", "1001011011",  -- D9.0
        "0101010100", "0101011011",  -- D10.0
        "1101000100", "1101001011",  -- D11.0
        "0011010100", "0011011011",  -- D12.0
        "1011000100", "1011001011",  -- D13.0
        "0111000100", "0111001011",  -- D14.0
        "1010001011", "0101110100",  -- D15.0
        "1001001011", "0110110100",  -- D16.0
        "1000110100", "1000111011",  -- D17.0
        "0100110100", "0100111011",  -- D18.0
        "1100100100", "1100101011",  -- D19.0
        "0010110100", "0010111011",  -- D20.0
        "1010100100", "1010101011",  -- D21.0
        "0110100100", "0110101011",  -- D22.0
        "0001011011", "1110100100",  -- D23.0
        "0011001011", "1100110100",  -- D24.0
        "1001100100", "1001101011",  -- D25.0
        "0101100100", "0101101011",  -- D26.0
        "0010011011", "1101100100",  -- D27.0
        "0011100100", "0011101011",  -- D28.0
        "0100011011", "1011100100",  -- D29.0
        "1000011011", "0111100100",  -- D30.0
        "0101001011", "1010110100",  -- D31.0
        "0110001001", "1001111001",  -- D0.1
        "1000101001", "0111011001",  -- D1.1
        "0100101001", "1011011001",  -- D2.1
        "1100011001", "1100011001",  -- D3.1
        "0010101001", "1101011001",  -- D4.1
        "1010011001", "1010011001",  -- D5.1
        "0110011001", "0110011001",  -- D6.1
        "0001111001", "1110001001",  -- D7.1
        "0001101001", "1110011001",  -- D8.1
        "1001011001", "1001011001",  -- D9.1
        "0101011001", "0101011001",  -- D10.1
        "1101001001", "1101001001",  -- D11.1
        "0011011001", "0011011001",  -- D12.1
        "1011001001", "1011001001",  -- D13.1
        "0111001001", "0111001001",  -- D14.1
        "1010001001", "0101111001",  -- D15.1
        "1001001001", "0110111001",  -- D16.1
        "1000111001", "1000111001",  -- D17.1
        "0100111001", "0100111001",  -- D18.1
        "1100101001", "1100101001",  -- D19.1
        "0010111001", "0010111001",  -- D20.1
        "1010101001", "1010101001",  -- D21.1
        "0110101001", "0110101001",  -- D22.1
        "0001011001", "1110101001",  -- D23.1
        "0011001001", "1100111001",  -- D24.1
        "1001101001", "1001101001",  -- D25.1
        "0101101001", "0101101001",  -- D26.1
        "0010011001", "1101101001",  -- D27.1
        "0011101001", "0011101001",  -- D28.1
        "0100011001", "1011101001",  -- D29.1
        "1000011001", "0111101001",  -- D30.1
        "0101001001", "1010111001",  -- D31.1
        "0110000101", "1001110101",  -- D0.2
        "1000100101", "0111010101",  -- D1.2
        "0100100101", "1011010101",  -- D2.2
        "1100010101", "1100010101",  -- D3.2
        "0010100101", "1101010101",  -- D4.2
        "1010010101", "1010010101",  -- D5.2
        "0110010101", "0110010101",  -- D6.2
        "0001110101", "1110000101",  -- D7.2
        "0001100101", "1110010101",  -- D8.2
        "1001010101", "1001010101",  -- D9.2
        "0101010101", "0101010101",  -- D10.2
        "1101000101", "1101000101",  -- D11.2
        "0011010101", "0011010101",  -- D12.2
        "1011000101", "1011000101",  -- D13.2
        "0111000101", "0111000101",  -- D14.2
        "1010000101", "0101110101",  -- D15.2
        "1001000101", "0110110101",  -- D16.2
        "1000110101", "1000110101",  -- D17.2
        "0100110101", "0100110101",  -- D18.2
        "1100100101", "1100100101",  -- D19.2
        "0010110101", "0010110101",  -- D20.2
        "1010100101", "1010100101",  -- D21.2
        "0110100101", "0110100101",  -- D22.2
        "0001010101", "1110100101",  -- D23.2
        "0011000101", "1100110101",  -- D24.2
        "1001100101", "1001100101",  -- D25.2
        "0101100101", "0101100101",  -- D26.2
        "0010010101", "1101100101",  -- D27.2
        "0011100101", "0011100101",  -- D28.2
        "0100010101", "1011100101",  -- D29.2
        "1000010101", "0111100101",  -- D30.2
        "0101000101", "1010110101",  -- D31.2
        "0110001100", "1001110011",  -- D0.3
        "1000101100", "0111010011",  -- D1.3
        "0100101100", "1011010011",  -- D2.3
        "1100010011", "1100011100",  -- D3.3
        "0010101100", "1101010011",  -- D4.3
        "1010010011", "1010011100",  -- D5.3
        "0110010011", "0110011100",  -- D6.3
        "0001110011", "1110001100",  -- D7.3
        "0001101100", "1110010011",  -- D8.3
        "1001010011", "1001011100",  -- D9.3
        "0101010011", "0101011100",  -- D10.3
        "1101000011", "1101001100",  -- D11.3
        "0011010011", "0011011100",  -- D12.3
        "1011000011", "1011001100",  -- D13.3
        "0111000011", "0111001100",  -- D14.3
        "1010001100", "0101110011",  -- D15.3
        "1001001100", "0110110011",  -- D16.3
        "1000110011", "1000111100",  -- D17.3
        "0100110011", "0100111100",  -- D18.3
        "1100100011", "1100101100",  -- D19.3
        "0010110011", "0010111100",  -- D20.3
        "1010100011", "1010101100",  -- D21.3
        "0110100011", "0110101100",  -- D22.3
        "0001011100", "1110100011",  -- D23.3
        "0011001100", "1100110011",  -- D24.3
        "1001100011", "1001101100",  -- D25.3
        "0101100011", "0101101100",  -- D26.3
        "0010011100", "1101100011",  -- D27.3
        "0011100011", "0011101100",  -- D28.3
        "0100011100", "1011100011",  -- D29.3
        "1000011100", "0111100011",  -- D30.3
        "0101001100", "1010110011",  -- D31.3
        "0110001101", "1001110010",  -- D0.4
        "1000101101", "0111010010",  -- D1.4
        "0100101101", "1011010010",  -- D2.4
        "1100010010", "1100011101",  -- D3.4
        "0010101101", "1101010010",  -- D4.4
        "1010010010", "1010011101",  -- D5.4
        "0110010010", "0110011101",  -- D6.4
        "0001110010", "1110001101",  -- D7.4
        "0001101101", "1110010010",  -- D8.4
        "1001010010", "1001011101",  -- D9.4
        "0101010010", "0101011101",  -- D10.4
        "1101000010", "1101001101",  -- D11.4
        "0011010010", "0011011101",  -- D12.4
        "1011000010", "1011001101",  -- D13.4
        "0111000010", "0111001101",  -- D14.4
        "1010001101", "0101110010",  -- D15.4
        "1001001101", "0110110010",  -- D16.4
        "1000110010", "1000111101",  -- D17.4
        "0100110010", "0100111101",  -- D18.4
        "1100100010", "1100101101",  -- D19.4
        "0010110010", "0010111101",  -- D20.4
        "1010100010", "1010101101",  -- D21.4
        "0110100010", "0110101101",  -- D22.4
        "0001011101", "1110100010",  -- D23.4
        "0011001101", "1100110010",  -- D24.4
        "1001100010", "1001101101",  -- D25.4
        "0101100010", "0101101101",  -- D26.4
        "0010011101", "1101100010",  -- D27.4
        "0011100010", "0011101101",  -- D28.4
        "0100011101", "1011100010",  -- D29.4
        "1000011101", "0111100010",  -- D30.4
        "0101001101", "1010110010",  -- D31.4
        "0110001010", "1001111010",  -- D0.5
        "1000101010", "0111011010",  -- D1.5
        "0100101010", "1011011010",  -- D2.5
        "1100011010", "1100011010",  -- D3.5
        "0010101010", "1101011010",  -- D4.5
        "1010011010", "1010011010",  -- D5.5
        "0110011010", "0110011010",  -- D6.5
        "0001111010", "1110001010",  -- D7.5
        "0001101010", "1110011010",  -- D8.5
        "1001011010", "1001011010",  -- D9.5
        "0101011010", "0101011010",  -- D10.5
        "1101001010", "1101001010",  -- D11.5
        "0011011010", "0011011010",  -- D12.5
        "1011001010", "1011001010",  -- D13.5
        "0111001010", "0111001010",  -- D14.5
        "1010001010", "0101111010",  -- D15.5
        "1001001010", "0110111010",  -- D16.5
        "1000111010", "1000111010",  -- D17.5
        "0100111010", "0100111010",  -- D18.5
        "1100101010", "1100101010",  -- D19.5
        "0010111010", "0010111010",  -- D20.5
        "1010101010", "1010101010",  -- D21.5
        "0110101010", "0110101010",  -- D22.5
        "0001011010", "1110101010",  -- D23.5
        "0011001010", "1100111010",  -- D24.5
        "1001101010", "1001101010",  -- D25.5
        "0101101010", "0101101010",  -- D26.5
        "0010011010", "1101101010",  -- D27.5
        "0011101010", "0011101010",  -- D28.5
        "0100011010", "1011101010",  -- D29.5
        "1000011010", "0111101010",  -- D30.5
        "0101001010", "1010111010",  -- D31.5
        "0110000110", "1001110110",  -- D0.6
        "1000100110", "0111010110",  -- D1.6
        "0100100110", "1011010110",  -- D2.6
        "1100010110", "1100010110",  -- D3.6
        "0010100110", "1101010110",  -- D4.6
        "1010010110", "1010010110",  -- D5.6
        "0110010110", "0110010110",  -- D6.6
        "0001110110", "1110000110",  -- D7.6
        "0001100110", "1110010110",  -- D8.6
        "1001010110", "1001010110",  -- D9.6
        "0101010110", "0101010110",  -- D10.6
        "1101000110", "1101000110",  -- D11.6
        "0011010110", "0011010110",  -- D12.6
        "1011000110", "1011000110",  -- D13.6
        "0111000110", "0111000110",  -- D14.6
        "1010000110", "0101110110",  -- D15.6
        "1001000110", "0110110110",  -- D16.6
        "1000110110", "1000110110",  -- D17.6
        "0100110110", "0100110110",  -- D18.6
        "1100100110", "1100100110",  -- D19.6
        "0010110110", "0010110110",  -- D20.6
        "1010100110", "1010100110",  -- D21.6
        "0110100110", "0110100110",  -- D22.6
        "0001010110", "1110100110",  -- D23.6
        "0011000110", "1100110110",  -- D24.6
        "1001100110", "1001100110",  -- D25.6
        "0101100110", "0101100110",  -- D26.6
        "0010010110", "1101100110",  -- D27.6
        "0011100110", "0011100110",  -- D28.6
        "0100010110", "1011100110",  -- D29.6
        "1000010110", "0111100110",  -- D30.6
        "0101000110", "1010110110",  -- D31.6
        "0110001110", "1001110001",  -- D0.7
        "1000101110", "0111010001",  -- D1.7
        "0100101110", "1011010001",  -- D2.7
        "1100010001", "1100011110",  -- D3.7
        "0010101110", "1101010001",  -- D4.7
        "1010010001", "1010011110",  -- D5.7
        "0110010001", "0110011110",  -- D6.7
        "0001110001", "1110001110",  -- D7.7
        "0001101110", "1110010001",  -- D8.7
        "1001010001", "1001011110",  -- D9.7
        "0101010001", "0101011110",  -- D10.7
        "1101001000", "1101001110",  -- D11.7
        "0011010001", "0011011110",  -- D12.7
        "1011001000", "1011001110",  -- D13.7
        "0111001000", "0111001110",  -- D14.7
        "1010001110", "0101110001",  -- D15.7
        "1001001110", "0110110001",  -- D16.7
        "1000110001", "1000110111",  -- D17.7
        "0100110001", "0100110111",  -- D18.7
        "1100100001", "1100101110",  -- D19.7
        "0010110001", "0010110111",  -- D20.7
        "1010100001", "1010101110",  -- D21.7
        "0110100001", "0110101110",  -- D22.7
        "0001011110", "1110100001",  -- D23.7
        "0011001110", "1100110001",  -- D24.7
        "1001100001", "1001101110",  -- D25.7
        "0101100001", "0101101110",  -- D26.7
        "0010011110", "1101100001",  -- D27.7
        "0011100001", "0011101110",  -- D28.7
        "0100011110", "1011100001",  -- D29.7
        "1000011110", "0111100001",  -- D30.7
        "0101001110", "1010110001"   -- D31.7
        );
    constant k_symbols : a_symbols := (
        -- Pos RD,       Neg RD
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.0
        "1100001011", "0011110100",  -- K28.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.0
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.1
        "1100000110", "0011111001",  -- K28.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.1
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.2
        "1100001010", "0011110101",  -- K28.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.2
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.3
        "1100001100", "0011110011",  -- K28.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.3
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.4
        "1100001101", "0011110010",  -- K28.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.4
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.5
        "1100000101", "0011111010",  -- K28.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.5
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K23.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K27.6
        "1100001001", "0011110110",  -- K28.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K29.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K30.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K31.6
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K0.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K1.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K2.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K3.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K4.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K5.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K6.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K7.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K8.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K9.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K10.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K11.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K12.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K13.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K14.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K15.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K16.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K17.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K18.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K19.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K20.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K21.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K22.7
        "0001010111", "1110101000",  -- K23.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K24.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K25.7
        "XXXXXXXXXX", "XXXXXXXXXX",  -- K26.7
        "0010010111", "1101101000",  -- K27.7
        "1100000111", "0011111000",  -- K28.7
        "0100010111", "1011101000",  -- K29.7
        "1000010111", "0111101000",  -- K30.7
        "XXXXXXXXXX", "XXXXXXXXXX"   -- K31.7
        );
    signal data0         : std_logic_vector(7 downto 0);
    signal data1         : std_logic_vector(7 downto 0);
    signal data0k        : std_logic;
    signal data1k        : std_logic;
    signal data0forceneg : std_logic;
    signal data1forceneg : std_logic;

begin
    data0         <= in_data(7 downto 0);
    data0k        <= in_data(8);
    data0forceneg <= in_data(9);
    data1         <= in_data(17 downto 10);
    data1k        <= in_data(18);
    data1forceneg <= in_data(19);
process(clk)
    variable index0 : unsigned(8 downto 0);
    variable index1 : unsigned(8 downto 0);
    begin
        if rising_edge(clk) then
            -----------------------------------------------------------
            -- Stage 3 - work out the final symbol based on the 
            -- disparity calcuated in stage 2 
            ----------------------------------------------------------
            index0 := unsigned(data0_2 & disparity0_neg_2);
            index1 := unsigned(data1_2 & disparity1_neg_2);
            if data0k_2 = '1' then
                out_data(9 downto 0) <= k_symbols(to_integer(index0));
            else
                out_data(9 downto 0) <= d_symbols(to_integer(index0));
            end if;
            if data1k_2 = '1' then
                out_data(19 downto 10) <= k_symbols(to_integer(index1));
            else
                out_data(19 downto 10) <= d_symbols(to_integer(index1));
            end if;

            -----------------------------------------------------------
            -- Stage 2 - work out the disparity for each symbol, and
            -- the disparity for the next set of symbols.
            ----------------------------------------------------------
            if data0forceneg = '0' then
                if data1forceneg = '0'  then
                    disparity0_neg_2      <= current_disparity_neg;
                    disparity1_neg_2      <= current_disparity_neg XOR disparity0_odd_1;
                    current_disparity_neg <= current_disparity_neg XOR disparity0_odd_1 XOR disparity1_odd_1;  
                else
                    disparity0_neg_2      <= current_disparity_neg;
                    disparity1_neg_2      <= '1';
                    current_disparity_neg <= '1' XOR disparity1_odd_1;  
                end if;     
            else
                if data1forceneg = '0'  then
                    disparity0_neg_2      <= '1';
                    disparity1_neg_2      <= '1' XOR disparity0_odd_1;
                    current_disparity_neg <= '1' XOR disparity0_odd_1 XOR disparity1_odd_1;  
                else
                    disparity0_neg_2      <= '1';
                    disparity1_neg_2      <= '1';
                    current_disparity_neg <= '1' XOR disparity1_odd_1;  
                end if;     
            end if;
            data0_2  <= data0_1;
            data0k_2 <= data0k_1;
            
            data1_2  <= data1_1;
            data1k_2 <= data1k_1;
        
            -----------------------------------------------------------
            -- Stage 1 - Look up the disparity for each data word
            ----------------------------------------------------------
            if data0k = '1' then 
                disparity0_odd_1 <= disparity_k(to_integer(unsigned(data0)));
            else 
                disparity0_odd_1 <= disparity_d(to_integer(unsigned(data0)));
            end if;
            data0_1          <= data0;
            data0k_1         <= data0k;
            data0forceneg_1  <= data0forceneg;

            if data1k = '1' then                 
                disparity1_odd_1 <= disparity_k(to_integer(unsigned(data1)));
            else 
                disparity1_odd_1 <= disparity_d(to_integer(unsigned(data1)));
            end if;
            data1_1          <= data1;
            data1k_1         <= data1k;
            data1forceneg_1  <= data1forceneg;
        end if;        
    end process;    
end architecture;