`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Montvydas Klumbys	
// 
// Create Date:    
// Design Name: 
// Module Name:    Keyboard 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	A module which is used to receive the DATA from PS2 type keyboard and translate that data into sensible codeword.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module ps2_keyboard(
	input CLK,	//board clock
	input reset, // *LC* you should always provide a posibility to reset your system
   input PS2_CLK,	//keyboard clock and data signals
   input PS2_DATA,
//	output reg scan_err,			//These can be used if the Keyboard module is used within a another module
//	output reg [10:0] scan_code,
//	output reg [3:0]COUNT,
//	output reg TRIG_ARR,
//	output reg [7:0]CODEWORD,
//   output reg [7:0] LED	//8 LEDs
   output reg key_pressed,              //*LC*
   output reg [7:0] key_pressed_code    //*LC* code of the key pressed, valid from "key_pressed == 1" until key releas
   );

	wire [7:0] ARROW_UP = 8'h75;	//codes for arrows
	wire [7:0] ARROW_DOWN = 8'h72;
	//wire [7:0] ARROW_LEFT = 8'h6B;
	//wire [7:0] ARROW_RIGHT = 8'h74;
	wire [7:0] EXTENDED = 8'hE0;	//codes 
	wire [7:0] RELEASED = 8'hF0;

	reg read;				//this is 1 if still waits to receive more bits 
	reg [11:0] count_reading;		//this is used to detect how much time passed since it received the previous codeword
	reg PREVIOUS_STATE;			//used to check the previous state of the keyboard clock signal to know if it changed
	reg scan_err;				//this becomes one if an error was received somewhere in the packet
	reg [10:0] scan_code;			//this stores 11 received bits
	reg [7:0] CODEWORD;			//this stores only the DATA codeword
	reg TRIG_ARR;				//this is triggered when full 11 bits are received
	reg [3:0]COUNT;				//tells how many bits were received until now (from 0 to 11)
	reg TRIGGER = 0;			//This acts as a 250 times slower than the board clock. 
	reg [7:0]DOWNCOUNTER = 0;		//This is used together with TRIGGER - look the code


	//Set initial values
	initial begin
		PREVIOUS_STATE = 1;		
		scan_err = 0;		
		scan_code = 0;
		COUNT = 0;			
		CODEWORD = 0;
//		LED = 0;
		read = 0;
		count_reading = 0;
	end

	always @(posedge CLK) begin				//This reduces the frequency 250 times
	   if (reset) begin      //*LC*
		   DOWNCOUNTER = 0;
			TRIGGER = 0;
		end else begin
			if (DOWNCOUNTER < 249) begin			//and uses variable TRIGGER as the new board clock 
				DOWNCOUNTER = DOWNCOUNTER + 1;
				TRIGGER = 0;
			end
			else begin
				DOWNCOUNTER = 0;
				TRIGGER = 1;
			end
		end
	end
	
	always @(posedge CLK) begin
      if (reset) count_reading = 0; //*LC*
	   else	
			if (TRIGGER) begin
				if (read)				//if it still waits to read full packet of 11 bits, then (read == 1)
					count_reading = count_reading + 1;	//and it counts up this variable
				else 						//and later if check to see how big this value is.
					count_reading = 0;			//if it is too big, then it resets the received data
			end
	end


	always @(posedge CLK) begin
   if (reset) begin //*LC*
	   read = 0;
		scan_err = 0;
		COUNT = 0;
		scan_code = 0;
		TRIG_ARR = 0;
		PREVIOUS_STATE = 1;
	end else begin
		if (TRIGGER) begin						//If the down counter (CLK/250) is ready
			if (PS2_CLK != PREVIOUS_STATE) begin			//if the state of Clock pin changed from previous state
				if (!PS2_CLK) begin				//and if the keyboard clock is at falling edge
					read = 1;				//mark down that it is still reading for the next bit
					scan_err = 0;				//no errors
					scan_code[10:0] = {PS2_DATA, scan_code[10:1]};	//add up the data received by shifting bits and adding one new bit
					COUNT = COUNT + 1;			//
				end
			end
			else if (COUNT == 11) begin				//if it already received 11 bits
				COUNT = 0;
				read = 0;					//mark down that reading stopped
				TRIG_ARR = 1;					//trigger out that the full pack of 11bits was received
				//calculate scan_err using parity bit
				if (!scan_code[10] || scan_code[0] || !(scan_code[1]^scan_code[2]^scan_code[3]^scan_code[4]
					^scan_code[5]^scan_code[6]^scan_code[7]^scan_code[8]
					^scan_code[9]))
					scan_err = 1;
				else 
					scan_err = 0;
			end	
			else  begin						//if it yet not received full pack of 11 bits
				TRIG_ARR = 0;					//tell that the packet of 11bits was not received yet
				if ((COUNT < 11) && (count_reading >= 4000)) begin	//and if after a certain time no more bits were received, then
					COUNT = 0;				//reset the number of bits received
					read = 0;				//and wait for the next packet
				end
			end
		   PREVIOUS_STATE = PS2_CLK;					//mark down the previous state of the keyboard clock
		end
	end
	end


//	always @(posedge CLK) begin
//	   if (reset) CODEWORD = 8'd0;// *LC*
//		else
//			if (TRIGGER) begin					//if the 250 times slower than board clock triggers
//				if (TRIG_ARR) begin				//and if a full packet of 11 bits was received
//					if (scan_err) begin			//BUT if the packet was NOT OK
//						CODEWORD = 8'd0;		//then reset the codeword register
//					end
//					else begin
//						CODEWORD = scan_code[8:1];	//else drop down the unnecessary  bits and transport the 7 DATA bits to CODEWORD reg
//					end				//notice, that the codeword is also reversed! This is because the first bit to received
//				end					//is supposed to be the last bit in the codeword…
//				else CODEWORD = 8'd0;				//not a full packet received, thus reset codeword
//			end
//			else CODEWORD = 8'd0;					//no clock trigger, no data…
//	end
	
	
//-----------------------------------------------------------------------------
//
// SoCLAb
//
// Luc Claesen 2020/05/05: adaptation to only detect one key press
//
// remark: "reset" signal should be added to all of the sequential circuits
// in this module
//
//-----------------------------------------------------------------------------
   parameter WAIT_KEY_PRESS = 0, WAIT_KEY_RELEASE = 1;
	reg       key_status = 0; // Status of FSM
	reg [7:0] key_code = 0, prev_key_code = 0;
	always@(posedge CLK)
		if (reset) begin
		   prev_key_code = 0;
			key_code = 0;
			key_status = 0;
			key_pressed = 0;
			key_pressed_code = 0;
		end else begin
		   key_pressed = 0;
			if (TRIGGER) begin
				if(TRIG_ARR) begin
					if(scan_err) begin
						prev_key_code = 0;
						key_code = 0;
						key_status = 0;
						key_pressed = 0;
					end else begin
						prev_key_code = key_code;
						key_code = scan_code[8:1];
						if (key_code != EXTENDED) begin // leave out extended key handling for the moment
							case (key_status)
								WAIT_KEY_PRESS: begin
								      if (key_code == RELEASED) begin
										   key_pressed = 0;
										end else begin
										   key_pressed_code = key_code;
										   key_pressed = 1;
										   key_status = WAIT_KEY_RELEASE;
										end
									end
								WAIT_KEY_RELEASE: begin
										if ((prev_key_code == RELEASED) && (key_code == key_pressed_code)) begin
											key_status = WAIT_KEY_PRESS;
										end 
										key_pressed = 0;
									end
							endcase
						end;
					end;
				end;
			end;
		end
 
	
endmodule 

