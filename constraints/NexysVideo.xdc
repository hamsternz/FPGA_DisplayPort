##Clock Signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]


##Display Port
set_property -dict { PACKAGE_PIN AB10  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_n }]; #IO_L8N_T1_13 Sch=dp_tx_aux_n
set_property -dict { PACKAGE_PIN AA11  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_n }]; #IO_L9N_T1_DQS_13 Sch=dp_tx_aux_n
set_property -dict { PACKAGE_PIN AA9   IOSTANDARD LVDS     } [get_ports { dp_tx_aux_p }]; #IO_L8P_T1_13 Sch=dp_tx_aux_p
set_property -dict { PACKAGE_PIN AA10  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_p }]; #IO_L9P_T1_DQS_13 Sch=dp_tx_aux_p
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { dp_tx_hpd }]; #IO_25_14 Sch=dp_tx_hpd

# DEBUG on JA
set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[0] }]; #IO_L10N_T1_D15_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[1] }]; #IO_L10P_T1_D14_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[2] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=ja[3]
set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[3] }]; #IO_L17N_T2_A13_D29_14 Sch=ja[4]
set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[4] }]; #IO_L9P_T1_DQS_14 Sch=ja[7]
set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[5] }]; #IO_L8N_T1_D12_14 Sch=ja[8]
set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[6] }]; #IO_L8P_T1_D11_14 Sch=ja[9]
set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33 } [get_ports { debug_pmod[7] }]; #IO_L17P_T2_A14_D30_14 Sch=ja[10


