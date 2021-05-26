module synchronizer(input clock, input reset, input sync_in, output reg sync_out);

reg sync_int;
always @(posedge clock)
   if (reset) begin
	   sync_int = 0; sync_out = 0;
   end else begin
	   sync_out = sync_int;
		sync_int = sync_in;
   end	

endmodule 