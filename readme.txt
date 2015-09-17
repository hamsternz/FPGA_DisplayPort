Hi, 

This is my work-in-progress implementation of DisplayPort. Currently works on a Xilinx Artix-7 FPGA on a Digilent Nexys Video Development Board. Hopefully it will soon work on others.

Status
======
Implements a working 800x600 display over a single 2.70Gb/s lane (90MHz pixel clock at 24bpp). Test pattern is for 800x600 @ 60Hz (40 MHz pixel clock)

- AUX channel works
- FSM for sink configuration works
- EDID reading works
- Channel monitoring works (ie. detects and corrects channel failures)
- Main stream works (i.e. can display video).
- Idle pattern generation works (for single channel)
- Scrambler works
- 8B/10B coding works.

TODO
====
- Everything that gets pixels into a valid stream (e.g. pixel steering, TU creation)
- Add more than one data channel.
- Enhance FSM to correctly handle voltage and pre-emphasis requests.
- Make Hot Plug work properly - currently just queries EDID as a proxy
- Convert white screen into a test patterns
- Audio / Secondary data packet support.

Notes on planning for Display Port implementation
=================================================

Source document 
---------------http://ftp.cis.nctu.edu.tw/csie/Software/X11/private/VeSaSpEcS/VESA_Document_Center_Video_Interface/DportV1.1.pdf

Progress and rough plan
-----------------------
1. AUX Channel as source - DONE
	Reseach encoding Manchester II, Sync words, blar blar blar,

2. Bitbash a read request from the AUX Channel - DONE

3. Make a sensible interface for sending packets to/from AUX channel - DONE
	Busy
	Byte FIFO to heading Sink
	FIFO Full

	Response FIFO from Sink
	FIFO empty.
	Timeout
   Usage is   
	Stuff data into FIFO
	Wait for 'response_received' or 'timeout' to be asserted. 	
	Read the response from the FIFO

4. Make state machine to do something useful  - DONE
	Read back EDID? 
	Check Lane config

5. Bring up the tranceivers as TX. - one of two DONE

6. The oh-so-painful training for the link. - DONE

7. Implement Scrambler - DONE

8. Word-bash a video frame across a single lane - DONE
	Merging of channels is a pain
	Video descriptor (MSA) needed for anything useful to happen

9. Make a sensible video interface - video clock does not need to be locked to pixel clock (yay!)
	clock
	clock_enable
	hsync
	vsync
	blank
	pixel_data (24 bpp?)

10. Think about supporting audio