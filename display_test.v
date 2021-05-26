module display_test1(CLOCK_50, KEY, SW, LEDR, PS2_CLK, PS2_DAT, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLK, VGA_SYNC_N, VGA_BLANK_N);

// INPUTS AND OUTPUTS
input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
inout PS2_CLK;
inout PS2_DAT;
output reg [9:0] LEDR;
output reg [7:0] VGA_R, VGA_G, VGA_B;
output reg VGA_HS, VGA_VS, VGA_CLK, VGA_SYNC_N, VGA_BLANK_N;

// VGA
reg red, green, blue;
wire [11:0] display_col; // horizontal counter
wire [10:0] display_row; // vertical counter
wire visible, clock, hsync, vsync;

// BUTTONS
assign reset = !KEY[0];
assign start = KEY[1];

// PS2 KEYBOARD
wire [7:0] key_pressed_code;
wire key_pressed;
reg [7:0] key_code = 0;

// PARAMETERS
// directions of snake
parameter UP    = 2'b00;
parameter DOWN  = 2'b01;
parameter LEFT  = 2'b10;
parameter RIGHT = 2'b11;
// keys
parameter KEY_UP    = 8'b00011101;
parameter KEY_DOWN  = 8'b00011011;
parameter KEY_LEFT  = 8'b00011100;
parameter KEY_RIGHT = 8'b00100011;
parameter KEY_ESC	  = 8'b01110110;
// horizontal and vertical sizes
parameter HOR_FIELD    = 1919;
parameter HOR_STR_SYNC = 2007;
parameter HOR_STP_SYNC = 2051;
parameter HOR_TOTAL    = 2199;
parameter VER_FIELD    = 1079;
parameter VER_STR_SYNC = 1083;
parameter VER_STP_SYNC = 1088;
parameter VER_TOTAL    = 1124;

// CLOCK FOR UPDATES
reg update_clock;
reg [49:0] counter;
parameter maxcount = 4777777;	//Max count for delay

//-----------------------------------------


reg [11:0] apple_x;
reg [10:0] apple_y;
wire [11:0] rand_x;
wire [10:0] rand_y;
wire lethal, non_lethal;

reg bad_collision, good_collision, game_over;
reg apple_in_x, apple_in_y, apple, border, found; //---------------------------------------------------------------Added border
integer apple_counter, count1, count2, count3;
reg [6:0] size, points_counter;
reg [11:0] snake_x[0:127];
reg [10:0] snake_y[0:127];
reg snake_head;
reg snake_body;
wire update, reset;

//reg [5:0] snake_col;  // horizontal position
//reg [4:0] snake_row;  // vertical position
reg [1:0] direction; //Direction of the snake
//
//parameter snakesize 		 = 32;
//parameter coloms 		    = 60;
//parameter rows 	       = 32;
//parameter bordersize     = 32;

//----------------------------------


PLL108MHz u1 (.refclk(CLOCK_50),
				  .rst(reset),
				  .outclk_0(clock));

vga_controller	# (.HOR_FIELD(HOR_FIELD),
						.HOR_STR_SYNC(HOR_STR_SYNC),
						.HOR_STP_SYNC(HOR_STP_SYNC),
						.HOR_TOTAL(HOR_TOTAL),
						.VER_FIELD(VER_FIELD),
						.VER_STR_SYNC(VER_STR_SYNC),
						.VER_STP_SYNC(VER_STP_SYNC),
						.VER_TOTAL(VER_TOTAL))
						
					vga ( .clock(clock),
							.reset(reset),
							.display_col(display_col),
							.display_row(display_row),
							.visible(visible),
							.hsync(hsync),
							.vsync(vsync));

ps2_keyboard ps2_keyboard (.CLK(clock),
									.reset(reset),
									.PS2_CLK(PS2_CLK),
									.PS2_DATA(PS2_DAT),
									.key_pressed(key_pressed),
									.key_pressed_code(key_pressed_code));
									
random_grind rg (.clock(clock),
					  .rand_x(rand_x),
					  .rand_y(rand_y));

// ---------------------------------------------

	
always@(posedge clock) begin
	// aantal punten worden weergegeven op de leds (dit zou uiteindelijk in het gameover scherm komen)
	LEDR[7:0] <= points_counter;
	
	apple_counter = apple_counter + 1;
	if(apple_counter == 1) begin
		apple_x <= 50;
		apple_y <= 50;
	end else begin	
		if(good_collision) begin
			// als de random coordinaten buiten het veld vallen wordt er een fixt waarde genomen, als ze erbinnen vallen niet
			if((rand_x<100) || (rand_x>1874) || (rand_y<100) || (rand_y>1020)) begin
				apple_x <= 100;
				apple_y <= 100;
			end else begin
				apple_x <= rand_x;
				apple_y <= rand_y;
			end
		end else if(~start) begin
			// als de random coordinaten buiten het veld vallen wordt er een fixt waarde genomen, als ze erbinnen vallen niet
			if((rand_x<100) || (rand_x>1874) || (rand_y<100) || (rand_y>1020)) begin
				apple_x <=340;
				apple_y <=430;
			end else begin
				apple_x <= rand_x;
				apple_y <= rand_y;
			end
		end
	end
end
	
always @(posedge clock) begin
	// kijkt of vga display signalen op de appel zit
	apple_in_x <= (display_col > apple_x && display_col < (apple_x + 25));
	apple_in_y <= (display_row > apple_y && display_row < (apple_y + 25));
	apple = apple_in_x && apple_in_y;
end
	
	
always@(posedge update_clock) begin
	if(start) begin
		// gaat van achter naar voor werken dus als dit de slang is [3][2][1][0] dan zullen alle waardes opschuiven door de for loop naar [][3][2][1] waardoor de lege wegvalt
		for(count1 = 127; count1 > 0; count1 = count1 - 1) begin
			if(count1 <= size - 1) begin
				snake_x[count1] = snake_x[count1 - 1];
				snake_y[count1] = snake_y[count1 - 1];
			end
		end
		
		// door deze case zal de [0] naar boven, onder, links of rechts gaan waardoor we terug een slang hebben van bijvoorbeeld [3][2][1]
		//																																										 [0]
		case(direction)
			UP    : snake_y[0] <= (snake_y[0] - 25);
			LEFT  : snake_x[0] <= (snake_x[0] - 25);
			DOWN  : snake_y[0] <= (snake_y[0] + 25);
			RIGHT : snake_x[0] <= (snake_x[0] + 25);
		endcase	
	end else if(~start) begin
		// hier gaan we alle waardes opnieuw instellen omdat we verloren zijn
		snake_x[0] <= 920;
		snake_y[0] <= 540;
		for(count3 = 1; count3 < 128; count3 = count3+1) begin
			snake_x[count3] = 910;
			snake_y[count3] = 540;
		end
	end
end
	
always@(posedge clock) begin
	found = 0;
	// er wordt gekeken of de coordinaten van de VGA nu op de body van de slang zitten of niet
	for(count2 = 1; count2 < size; count2 = count2 + 1) begin
		if(~found) begin				
			snake_body = ((display_col > snake_x[count2] && display_col < snake_x[count2]+25) && (display_row > snake_y[count2] && display_row < snake_y[count2]+25));
			found = snake_body;
		end
	end
end

always@(posedge clock) begin	
	// er wordt gekeken of de coordinaten van de VGA nu op het hoofd van de slang zitten of niet
	snake_head = (display_col > snake_x[0] && display_col < (snake_x[0]+25)) && (display_row > snake_y[0] && display_row < (snake_y[0]+25));
end
		
// kijkt of vga display signalen op de border of lichaam van de slang zit
assign lethal = border || snake_body;
// kijkt of vga display signalen op de appel zit
assign non_lethal = apple;
	
always @(posedge clock) begin
	if(non_lethal && snake_head) begin
		// slang eet een appel op
		good_collision <= 1;
		size = size + 1;
		points_counter = points_counter + 1;
	end else if(~start) begin
		// game start, dus alles gereset
		size = 1;
		points_counter = 0;		
	end else begin
		good_collision=0;
	end
end

always @(posedge clock) begin
	// als de slang de border of zichzelf raakt, is bad_collision
	if(lethal && snake_head) begin
		bad_collision<=1;
	end else begin 
		bad_collision=0;
	end
end

always @(posedge clock) begin
	// bad_collision = game over!
	if(bad_collision) begin
		game_over<=1;
	end else if (~start) begin
		game_over=0;
	end
end

always @(posedge clock) begin//---------------------------------------------------------------Added border function
	border <= (((display_col >= 0) && (display_col < 26) || (display_col >= 1894) && (display_col < 1920)) 
				 || ((display_row >= 0) && (display_row < 26) || (display_row >= 1054) && (display_row < 1080)));
end
	
always @(posedge clock or posedge reset) begin
	if (reset) begin
		red   = 1'b0;
		green = 1'b0;
		blue  = 1'b0;
	end else begin
		if (visible) begin
			red   = (apple || game_over);
			green = ((snake_head||snake_body) && ~game_over);
			blue  = (border && ~game_over);
		end
		else begin
			red   = 1'b0;
			green = 1'b0;
			blue  = 1'b0;
		end
	end
end

//Counter
always @(posedge clock or posedge reset) begin
	if(reset) begin
		update_clock = 0;
		counter = 0;
	end
	else begin
		if(counter < maxcount)
			counter = counter + 1;
		else begin
			counter = 0;
			update_clock <= ~update_clock;
		end
	end
end
	
always @(*) begin
	//Change the movements according to the direction
	case(key_pressed_code)
		KEY_LEFT: begin 
			direction = LEFT;		
		end
		KEY_UP: begin 
			direction = UP;	
		end
		KEY_DOWN: begin 
			direction = DOWN;
		end
		KEY_RIGHT: begin 
			direction = RIGHT;
		end
		default: begin
			LEDR[9:8] = 2'b00;
			direction <= direction;
		end	
	endcase	
end

// ---------------------------------------------
	
always @(*) begin
	VGA_R <= {8{red}};
	VGA_G <= {8{green}};
	VGA_B <= {8{blue}};
	
	VGA_HS <= hsync;
	VGA_VS <= vsync;
	
	VGA_CLK <= clock;
	VGA_SYNC_N <= 1'b0;
	VGA_BLANK_N <= hsync & vsync;
end

endmodule
