module random_grind(clock, rand_x, rand_y);
	input clock;
	output reg [11:0]rand_x;
	output reg [10:0]rand_y;
	reg [5:0] point_x, point_y = 10;
	
	parameter GAME_SIZE = 25;
	
	always @(posedge clock)
		point_x <= point_x + 3;	
	always @(posedge clock)
		point_y <= point_y + 1;
		
	always @(posedge clock) begin	
		if(point_x>62)
			rand_x <= 1899;
		else if (point_x<2)
			rand_x <= GAME_SIZE+GAME_SIZE/3;
		else
			rand_x <= (point_x * GAME_SIZE);
	end
	
	always @(posedge clock) begin	
		if(point_y>46)
			rand_y <= 159;
		else if (point_y<2)
			rand_y <= GAME_SIZE+GAME_SIZE/3;
		else
			rand_y <= (point_y * GAME_SIZE);
	end
endmodule