Hi, 

This is my work-in-progress implementation of DisplayPort. Currently works on a Xilinx Artix-7 FPGA on a Digilent Nexys Video Development Board, and the Spartan 6 LX45T on the Nomato Labs Opsis board. Hopefully it will soon work on others.

Status
======
Implements a 800x600 display over a one, two or four 2.70Gb/s lanes (depending on actual board's design). It also can display 3840x2160@30Hz YCC 422 over a two-channel interface. There is also a test source to display colourbars over 800x600.

Low-level transceiver blocks are supplied for Artix-7 and Spartan-6 LXT FPGAs. These will need to be revised to work with your particular FPGA board's layout.

Thanks
======
Greg Overkamp for his help with debugging streams
Tim Ansell for offering a Spartan 6 board with a DisplayPort interface.

TODO
====
- Support 1.62Gb/s link speeds
- Enhance FSM to correctly handle voltage and pre-emphasis change requests.
- Make Hot Plug work properly - currently just queries EDID registers every second as a proxy for HPD
- Make a sensible video interface - video clock does not need to be locked to pixel clock (yay!)
- Audio / Secondary data packet support
- The Spartan 6 Transceiver blocks could be tidied up - eg power down unused parts
- Get H/W support for 8b/10b implemented on Artix-7 - DONE
- Get H/W support for 8b/10b implemented on Spartan-6
- Remove debugging stubs
- Add 4k60 sample and 4k30 444 sample streams
- Add support for at least one Kintex-7 board
- Optimize resource usage by collapsing some of the pipeline stages - DONE
- Optimize resource usage by using only one scrambler LFSR and using that for all channels - DONE
- Put in timing exceptions to get a clean timing report

- All active channels transmit K symbols in the same cycle (excluding 2 cycle skew at end of pipeline) so could share a common K signal, reducing 72 bits down to 65 for most of the pipeline.

Usage prior to optimisations (as a note for later comparison)
+------------------------------------------------+--------------------------------------------+------------+------------+---------+------+-----+--------+--------+--------------+
|                    Instance                    |                   Module                   | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP48 Blocks |
+------------------------------------------------+--------------------------------------------+------------+------------+---------+------+-----+--------+--------+--------------+
| top_level                                      |                                      (top) |        711 |        639 |      16 |   56 | 697 |      0 |      1 |            0 |
|   (top_level)                                  |                                      (top) |         32 |          0 |       0 |   32 |   0 |      0 |      0 |            0 |
|   Inst_main_stream_processing                  |                     main_stream_processing |        230 |        206 |       0 |   24 | 294 |      0 |      0 |            0 |
|     g_per_channel[0].g2.i_data_to_8b10b        |                              data_to_8b10b |         44 |         44 |       0 |    0 |  61 |      0 |      0 |            0 |
|     g_per_channel[0].i_scrambler               |                                  scrambler |         17 |         17 |       0 |    0 |  16 |      0 |      0 |            0 |
|     g_per_channel[0].i_train_channel           |                 training_and_channel_delay |         21 |         11 |       0 |   10 |  32 |      0 |      0 |            0 |
|     g_per_channel[1].g2.i_data_to_8b10b        |                            data_to_8b10b_1 |         44 |         44 |       0 |    0 |  61 |      0 |      0 |            0 |
|     g_per_channel[1].i_scrambler               |                                scrambler_2 |         20 |         20 |       0 |    0 |  20 |      0 |      0 |            0 |
|     g_per_channel[1].i_train_channel           |               training_and_channel_delay_3 |         26 |         12 |       0 |   14 |  27 |      0 |      0 |            0 |
|     i_idle_pattern_inserter                    |                      idle_pattern_inserter |         49 |         49 |       0 |    0 |  67 |      0 |      0 |            0 |
|     i_scrambler_reset_inserter                 |                   scrambler_reset_inserter |          9 |          9 |       0 |    0 |  10 |      0 |      0 |            0 |
|   i_channel_management                         |                         channel_management |        315 |        299 |      16 |    0 | 302 |      0 |      0 |            0 |
|     (i_channel_management)                     |                         channel_management |          4 |          4 |       0 |    0 |   0 |      0 |      0 |            0 |
|     i_aux_channel                              |                                aux_channel |        305 |        289 |      16 |    0 | 292 |      0 |      0 |            0 |
|       (i_aux_channel)                          |                                aux_channel |        116 |        116 |       0 |    0 | 108 |      0 |      0 |            0 |
|       i_aux_messages                           |                            dp_aux_messages |         47 |         47 |       0 |    0 |  21 |      0 |      0 |            0 |
|       i_channel                                |                              aux_interface |        143 |        127 |      16 |    0 | 163 |      0 |      0 |            0 |
|     i_link_signal_mgmt                         |                           link_signal_mgmt |          6 |          6 |       0 |    0 |  10 |      0 |      0 |            0 |
|   i_test_source                                |                                test_source |        111 |        111 |       0 |    0 |  65 |      0 |      1 |            0 |
|     i_insert_main_stream_attrbutes_one_channel |   insert_main_stream_attrbutes_one_channel |         42 |         42 |       0 |    0 |  26 |      0 |      0 |            0 |
|     i_test_source                              | test_source_800_600_RGB_444_colourbars_ch1 |         69 |         69 |       0 |    0 |  39 |      0 |      1 |            0 |
|   i_tx0                                        |                                Transceiver |         23 |         23 |       0 |    0 |  36 |      0 |      0 |            0 |
|     (i_tx0)                                    |                                Transceiver |          0 |          0 |       0 |    0 |   0 |      0 |      0 |            0 |
|     g_tx[0].i_gtx_tx_reset_controller          |                    gtx_tx_reset_controller |         23 |         23 |       0 |    0 |  35 |      0 |      0 |            0 |
|     g_tx[1].i_gtx_tx_reset_controller          |                  gtx_tx_reset_controller_0 |          0 |          0 |       0 |    0 |   1 |      0 |      0 |            0 |
+------------------------------------------------+--------------------------------------------+------------+------------+---------+------+-----+--------+--------+--------------+
* Note: The sum of lower-level cells may be larger than their parent cells total, due to cross-hierarchy LUT combining
