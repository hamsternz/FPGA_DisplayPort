Hi, 

This is my work-in-progress implementation of DisplayPort. Currently works on a Xilinx Artix-7 FPGA on a Digilent Nexys Video Development Board, and the Spartan 6 LX45T on the Nomato Labs Opsis board. Hopefully it will soon work on others.

Status
======
Implements a 800x600 display over a one, two or four 2.70Gb/s lanes (depending on actual board). It also can display 3840x2160@30Hz over a two-channel interface. There is also a test source to display colourbars over 800x600.

Low level transceiver blocks are supplied for Artix-7 and Spartan-6 LXT FPGAs. These will need to be revised to work wiht your particular FPGA board's layout.

TODO
====
- Support 1.62Gb/s link speeds
- Enhance FSM to correctly handle voltage and pre-emphasis requests.
- Make Hot Plug work properly - currently just queries EDID as a proxy for HPD
- Make a sensible video interface - video clock does not need to be locked to pixel clock (yay!)
- Audio / Secondary data packet support
- The Spartan 6 Transceiver blocks could be tidied up - eg power down unused parts