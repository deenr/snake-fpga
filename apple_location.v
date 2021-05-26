
module appleLocation (VGA_clk, xCount, yCount, start, apple);
	input VGA_clk, xCount, yCount, start;
	wire [9:0] appleX;
	wire [8:0] appleY;
	reg apple_inX, apple_inY;
	output apple;
	wire [9:0]rand_X;
	wire [8:0]rand_Y;
	randomGrid rand1(VGA_clk, rand_X, rand_Y);
	
	assign appleX = 0;
	assign appleY = 0;
	
	always @(negedge VGA_clk)
	begin
		apple_inX <= (xCount > appleX && xCount < (appleX + 10));
		apple_inY <= (yCount > appleY && yCount < (appleY + 10));
	end
	
	assign apple = apple_inX && apple_inY;
endmodule