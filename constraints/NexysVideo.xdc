##Clock Signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

set_property CFGBVS VCCO [current_design]

##Display Port
set_property -dict { PACKAGE_PIN AB10  IOSTANDARD LVDS_25  } [get_ports { dp_rx_aux_n }]; #IO_L8N_T1_13 Sch=dp_tx_aux_n
set_property -dict { PACKAGE_PIN AA9   IOSTANDARD LVDS_25  } [get_ports { dp_rx_aux_p }]; #IO_L8P_T1_13 Sch=dp_tx_aux_p
set_property -dict { PACKAGE_PIN AA11  IOSTANDARD LVDS_25  } [get_ports { dp_tx_aux_n }]; #IO_L9N_T1_DQS_13 Sch=dp_tx_aux_n
set_property -dict { PACKAGE_PIN AA10  IOSTANDARD LVDS_25  } [get_ports { dp_tx_aux_p }]; #IO_L9P_T1_DQS_13 Sch=dp_tx_aux_p
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { dp_tx_hp_detect }]; #IO_25_14 Sch=dp_tx_hpd
set_property -dict { PACKAGE_PIN F6  } [get_ports { refclk0_p }];
set_property -dict { PACKAGE_PIN E6  } [get_ports { refclk0_n }];
set_property -dict { PACKAGE_PIN F10 } [get_ports { refclk1_p }];
set_property -dict { PACKAGE_PIN E10 } [get_ports { refclk1_n }];
set_property -dict { PACKAGE_PIN B4  } [get_ports { gtptxp }];
set_property -dict { PACKAGE_PIN A4  } [get_ports { gtptxn }];


# DEBUG on JA
set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[0] }]; #IO_L10N_T1_D15_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[1] }]; #IO_L10P_T1_D14_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[2] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=ja[3]
set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[3] }]; #IO_L17N_T2_A13_D29_14 Sch=ja[4]
set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[4] }]; #IO_L9P_T1_DQS_14 Sch=ja[7]
set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[5] }]; #IO_L8N_T1_D12_14 Sch=ja[8]
set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[6] }]; #IO_L8P_T1_D11_14 Sch=ja[9]
set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[7] }]; #IO_L17P_T2_A14_D30_14 Sch=ja[10


set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { leds[0] }]; #IO_L15P_T2_DQS_13 Sch=led[0]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { leds[1] }]; #IO_L15N_T2_DQS_13 Sch=led[1]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { leds[2] }]; #IO_L17P_T2_13 Sch=led[2]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { leds[3] }]; #IO_L17N_T2_13 Sch=led[3]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS25 } [get_ports { leds[4] }]; #IO_L14N_T2_SRCC_13 Sch=led[4]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS25 } [get_ports { leds[5] }]; #IO_L16N_T2_13 Sch=led[5]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS25 } [get_ports { leds[6] }]; #IO_L16P_T2_13 Sch=led[6]
set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS25 } [get_ports { leds[7] }]; #IO_L5P_T0_13 Sch=led[7]


## Buttons
#set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS33 } [get_ports { btnc }]; #IO_L20N_T3_16 Sch=btnc
#set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS33 } [get_ports { btnd }]; #IO_L22N_T3_16 Sch=btnd
#set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS33 } [get_ports { btnl }]; #IO_L20P_T3_16 Sch=btnl
#set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS33 } [get_ports { btnr }]; #IO_L6P_T0_16 Sch=btnr
#set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS33 } [get_ports { btnu }]; #IO_0_16 Sch=btnu
#set_property -dict { PACKAGE_PIN G4  IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }]; #IO_L12N_T1_MRCC_35 Sch=cpu_resetn


##Switches
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS25  } [get_ports { switches[0] }]; #IO_L22P_T3_16 Sch=sw[0]
set_property -dict { PACKAGE_PIN F21 IOSTANDARD LVCMOS25  } [get_ports { switches[1] }]; #IO_25_16 Sch=sw[1]
set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS25  } [get_ports { switches[2] }]; #IO_L24P_T3_16 Sch=sw[2]
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS25  } [get_ports { switches[3] }]; #IO_L24N_T3_16 Sch=sw[3]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS25  } [get_ports { switches[4] }]; #IO_L6P_T0_15 Sch=sw[4]
set_property -dict { PACKAGE_PIN J16 IOSTANDARD LVCMOS25  } [get_ports { switches[5] }]; #IO_0_15 Sch=sw[5]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS25  } [get_ports { switches[6] }]; #IO_L19P_T3_A22_15 Sch=sw[6]
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS25  } [get_ports { switches[7] }]; #IO_25_15 Sch=sw[7]


