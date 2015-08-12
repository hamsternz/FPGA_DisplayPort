Hi,

This is my work-in-progress implementation of DisplayPort.

There is not really anything to see yet.

Planning for Display Port.

Source document http://ftp.cis.nctu.edu.tw/csie/Software/X11/private/VeSaSpEcS/VESA_Document_Center_Video_Interface/DportV1.1.pdf

1. AUX Channel as source
	Reseach encoding Manchester II, Sync words, blar blar blar,

2. Bitbash a read request from the AUX Channel.

3. Make a sensible interface for sending packets to/from AUX channel
	Busy
	Byte FIFO to heading Sink
	FIFO Full
	Send to Sink

	Response FIFO from Sink
	FIFO empty.
        Response recevied
	Timeout
   Usage is  
	stuff data into fifo
	toggle "send to sink"	
	Wait for 'response_received' or 'timeout' to be asserted. 	

4. Make state machine to do something useful
	Read back EDID? 
	Check Lane config

5. Bring up the tranceivers as TX.

6. The oh-so-painful training for the link.
	

7. Word-bash a video frame across a single lane
	Merging of channels is a pain
	Video descriptor needed needed for anything useful

8. Make a sensible video interface - video clock does not need to be locked to pixel clock (yay!)
	clock
	clock_enable
	hsync
	vsync
	blank
	pixel_data (24 bpp?)

9. Think about supporting audio 