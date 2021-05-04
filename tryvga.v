

// Part 2 skeleton

	module tryvga
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;					
	// Declare your inputs and outputs here
	input [9:0] SW;
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [11:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire [14:0] background_counter;
	wire [10:0] naruto_counter;
	
	//assign x = SW[3:0];
	
	//assign colour = SW[9:7];
	//assign writeEn = KEY[1];
	wire [1:0]sel;
	//wire initialize_0;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			//Signals for the DAC to drive the monitor. 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;// i changed 1 to 4
		defparam VGA.BACKGROUND_IMAGE = "skyTree.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	//horizontal h1(KEY[3], KEY[2], KEY[1], CLOCK_50, x, y, writeEn );
//	drop d1(KEY[3], CLOCK_50, x, y, writeEn);
		datapath d3( KEY, CLOCK_50, KEY[3], sel, x, y,  writeEn, colour, background_counter, naruto_counter);
		fsm f4(naruto_counter, background_counter, CLOCK_50, KEY[3], sel );
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
endmodule
/////////////////////////////////////////////////////////////////////////////////////
module fsm(naruto_counter, background_counter, clock, reset, sel );
	input [14:0]background_counter;
	input [8:0]naruto_counter;
	input clock;
	input reset;
	output reg [1:0]sel;
	//output reg initialize_0;
	
	reg [5:0] current_state, next_state;
	localparam   draw_background = 5'd0,
					 draw_fall       = 5'd1,
                draw_horizontal = 5'd2,
					 wait_for_shown  = 5'd3;
	//reg  [26:0]wait_count;	
	

					 
	//state table for next state
	always@(*)
	begin//E
		case (current_state)
			draw_background: next_state = (background_counter == 32767)? draw_fall:draw_background ;// may need to change 19199to 19200, 19199might be the mistake
			draw_fall: next_state = draw_horizontal;//total = 1320
			draw_horizontal: next_state = (naruto_counter == 329) ? draw_background: draw_horizontal ;//wait_for_shown;
			//wait_for_shown: next_state = ( wait_count == 27'b000001011111010111100000111)? draw_background : wait_for_shown ;// tested that it works with or without the wait_for_shown and the wait_count register
			default: next_state = draw_background;
		endcase
	end//E
		
	//output logic for all state
	 always @(*)
    begin 
		  case(current_state)
		  draw_background: begin
				sel = 2'b00;
				end
		  draw_fall: begin
				sel = 2'b01;	
//				initialize_0 = 1'b1;
				end
		  draw_horizontal: begin
				sel = 2'b10;
				end		  
		  default: sel = 2'b00;
		  endcase
	 end
	 
	//current_state registers
	always@(posedge clock)
	begin
		if(!reset)
			current_state <= draw_background;
		else
			current_state <= next_state;
	end		
	
	//wait_count register// tested that it works with or without the wait_for_shown and the wait_count register
//	always@(posedge clock)
//	begin 
//		if(current_state == draw_fall ) wait_count <=27'b0;
//		else 
//			if(!reset) wait_count <=27'b0;
//			else
//				if(current_state == wait_for_shown) wait_count <= wait_count + 1;
//	end	
	
endmodule
/////////////////////////////////////////////////////////////////////////////////////
module datapath(KEY, clock, reset, sel, x, y, writeEn, colour, background_counter,naruto_counter);
	input [3:0]KEY;//   MISTAKE HERE
	input clock;
	input reset;
	input [1:0]sel;
	//input initialize_0;
	output reg[7:0]x;
	output reg[6:0]y;
	//output plot;
	output reg writeEn;
	output reg [11:0]colour;
	output [14:0]background_counter;
	output [8:0]naruto_counter;
	
	wire [7:0]horizon_x;
	wire [6:0]horizon_y;
	wire [7:0]drop_x;
	wire [6:0]drop_y;
	wire [7:0]sky_x;
	wire [6:0]sky_y;
	wire plot_horizontal;
	wire plot_drop;
	wire plot_sky;//not used yet
	wire [11:0]naruto_colour;//not used yet
	wire [11:0]drop_colour;//not used yet
	wire [11:0]sky_colour;
	
	always@(*)
		case(sel)
			2'b00:begin
						x = sky_x;
						y = sky_y;
						writeEn = 1'b1;// this might be mistake
						colour = sky_colour;

					end
			2'b01:begin 
						x = drop_x;
						y = drop_y;
						writeEn = plot_drop;
						colour = 12'b0;

					end
			2'b10:begin
						x = horizon_x;
						y = horizon_y;
						writeEn = 1'b1;// if wrong agian , change the plot_horizontal to plot_horizontal
						colour = naruto_colour;
					end
			default: begin 
						x = 0;
						y = 0;
						writeEn = 1'b1;
						colour = 4'b0001;
						end
		endcase
	
	wire W1, W2;
	
	horizontal h1(KEY[3], KEY[2], KEY[1],clock , horizon_x, horizon_y ,naruto_colour, naruto_counter );//, plot_horizontal
	drop d1(KEY[3], clock, drop_x, drop_y, plot_drop);
	betterBackground s1( KEY[3], clock, sky_x, sky_y, sky_colour ,background_counter);
		
endmodule
/////////////////////////////////////////////////////////////////////////////////////
module betterBackground( reset, clock, x, y , background_output, background_counter);
	//input initialize_0;
	input reset;
	input clock;
	output [7:0]x;
	output [6:0]y;
	output [11:0]background_output;
	output reg [14:0]background_counter;
	wire [14:0]address_background;
	
	assign address_background = background_counter[14:8]*160 + background_counter[7:0];
	//assign address_background = background_counter[14:0];//this is wrong and tested
	assign x = background_counter[7:0];
	assign y = background_counter[14:8];
	
	betterBack b1( address_background, clock, 4'b1111, 1'b0, background_output );
	

	
	always@(posedge clock) begin
		if(!reset)begin 
		background_counter <= 14'b0;
		end
		else
//			if(initialize_0) background_counter <= 14'b0;
//			else
				if(background_counter != 32767) background_counter <= background_counter + 1;
				else
					if(background_counter == 32767) background_counter <= 0;
	end

endmodule

module drop(reset, clock, x, y, plot);
	input reset;
	input clock;
	output reg [7:0]x;
	output reg [6:0]y;
	output reg plot;
	//reg [7:0]random;
	wire enable;
	reg [2:0]x_random;
//	wire [7:0]x_value;// need to check here
	//reg c;
	//output [3:0]block_count;
	always@(posedge clock) begin//Q
		
		if(!reset)begin
			x <= 100;//i use decimal due to lazyness
			//x <= $urandom%119;
			y <= 0;
			x_random <= 0;
			//c <= 0;
			
		end
		else
			if(enable)begin//W
				if(y != 120)begin//s
					y <= y + 1;
					plot <= 1;
				end//s
				else 
					if(y == 120)begin//a
						y <= 0;
						plot <= 1;
//						x <= c ? 60 : 100;  // x <= my_random_number()
//						c <= c + 1;
						case(x_random[2:0])
							3'b000: x = 56;
							3'b001: x = 99;
							3'b010: x = 35;
							3'b011: x = 110;
							3'b100: x = 5;
							3'b101: x = 140;
							3'b110: x = 20;
							3'b111: x = 40;
							//default: x = 20;
						endcase
						x_random <= x_random + 1;
					end//a
			end//W		
	end//Q
	
	

	
						
	rate_divide_counter r2 (clock, 27'b000000101111101011110000011, enable);
endmodule
//horizontal with naruto///////////////////////////////////////////////////////////////////////////////////
module horizontal(reset, left, right, clock, x, y,  naruto_colour ,naruto_counter);//plot,
	input reset;
	input left;
	input right;
	input clock;	
	//output reg plot;
	output [11:0]naruto_colour;
	output [7:0]x;
	output [6:0]y;
	output reg [8:0]naruto_counter;
	reg [7:0]ini_x;
	//parameter [5:0]ini_y;
	wire enable;
	//wire [7:0]x_random;
	
	//assign ini_y = 7'b1110011;
	
	always@(posedge clock) begin
		if(!reset)begin
			//x <= x_random;
			ini_x <= 80;
		end
		else 
			if(enable) begin//1st
				if(!left & (ini_x != 0)) begin// for the key, i inverted it here
					ini_x <= ini_x - 1;
					//plot <= 1'b1;
				end
				if(!right & (ini_x != 155) )begin
					ini_x <= ini_x + 1;
					//plot <= 1'b1;
				end
			end//1st
	end
	
	
	wire [8:0]address_naruto;
	assign address_naruto = naruto_counter[8:4]*15 + naruto_counter[3:0];
	person p1(address_naruto, clock, 4'b1111, 1'b0, naruto_colour );
	assign x = ini_x + {4'b0000, naruto_counter[3:0]};
	assign y = 7'b1100100 + {2'b00 , naruto_counter[8:4]};
	
		always@(posedge clock) begin
		if(!reset)begin 
		naruto_counter <= 11'b0;
		end
		else
//			if(initialize_0) background_counter <= 14'b0;
//			else
				if(naruto_counter != 329) naruto_counter <= naruto_counter + 1;
				else
					if(naruto_counter == 329) naruto_counter <= 0;
	end
	
	
	rate_divide_counter r1 (clock, 27'b000001011111010111100000111, enable);
endmodule
////	//test // anne taught me how to display the sprite with ram//not rom //test.v file corresponding to the ram file that we created
//reg [14:0]test_counter;
//wire [14:0]address_test;
//
//assign address_test = test_counter[14:8]*160 + test_counter[7:0];
//test test1(	address_test, clock, 3'b000, 1'b0, output_test);	//output gives you the colour of ur sprite
//
//always@(posedge clock) begin
//	x <= x_init + test_counter[7:0];
//	y <= y_init + test_counter[14:8];
//	colour_out <= output_test;

///////////////////////////////////////////////////////////////////////////////////////////
//module horizontal(reset, left, right, clock, x, y, plot );
//	input reset;
//	input left;
//	input right;
//	input clock;	
//	output reg [7:0]x;
//	output  [6:0]y;
//	output reg plot;
//
//	wire enable;
//	//wire [7:0]x_random;
//	
//	assign y = 7'b1110011;
//	
//	always@(posedge clock) begin
//		if(!reset)begin
//			//x <= x_random;
//			x <= 80;
//		end
//		else 
//			if(enable) begin//1st
//				if(!left & (x != 0)) begin// for the key, i inverted it here
//					x <= x - 1;
//					plot <= 1'b1;
//				end
//				if(!right & (x != 155) )begin
//					x <= x + 1;
//					plot <= 1'b1;
//				end
//			end//1st
//	end
//	
//	rate_divide_counter r1 (clock, 27'b000001011111010111100000111, enable);
//endmodule

//////////////////////////////////////////////////////////////////////////////////
module rate_divide_counter(clock, D, Enable);
	input clock;
	input [26:0]D;
	 reg [26:0]Q = 0;
	output Enable;
	//assign q_middle = D;
	
	always@(posedge clock)
		begin
			if( Q == 27'b0  )
				Q <= D;
			else 
				Q <= Q - 1;
		end
	assign Enable = (Q ==0) ? 1 : 0;
endmodule







