module edge_detect(clock, reset, in, edge_out);
	input clock, reset, in;
	output edge_out;
	reg prev_in;
	
	always @(posedge clock or posedge reset)
		if (reset) 
			prev_in <= 0; 
		else 
			prev_in <= in;
		
		assign edge_out = in & !prev_in;
endmodule