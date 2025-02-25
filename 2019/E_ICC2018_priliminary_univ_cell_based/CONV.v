
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg	busy,	
	input		ready,	
			
	output reg [11:0]iaddr,
	input [19:0]idata,	
	
	output reg 	cwr,
	output reg [11:0]caddr_wr,
	output reg [19:0]cdata_wr,
	
	output reg 	crd,
	output reg [11:0]caddr_rd,
	input [19:0]cdata_rd,
	
	output reg [2:0]csel
	);

	reg [2:0] state, next_state;
	reg [3:0] Kptr;//Kernel ptr
	reg [19:0] pixels [65:0][65:0];
	reg [8:0] i, j, cnt;
	wire signed [39:0] k0, k1, k2, k3, k4, k5, k6, k7, k8;  // 40-bit 乘法結果
	wire signed [43:0] data_temp; // 10 個
	wire signed [19:0] data, data_Relu;
	wire [6:0] x, y, xc, yc;



	parameter LOAD = 0, CAL = 1, DONE = 2, LOAD_pre = 3, CAL_pre = 4;

	always@(*) begin
		case(state)
			LOAD_pre: begin
				next_state = LOAD;
			end
			LOAD: begin
				if(iaddr >= 4095) next_state = CAL_pre;
				else next_state = LOAD;
			end
			CAL_pre:begin
				next_state = CAL;
			end
			CAL:begin
				if(caddr_wr >= 4095) next_state = DONE;
				else next_state = CAL;
			end
			DONE:begin
			end
		endcase
	end



	always @(posedge clk or posedge reset) begin
		if(reset) begin
			state <= LOAD_pre;
			cnt <= 0;
			crd <= 0;
			cwr <= 0;
			iaddr <= 0;
			caddr_rd <= 0;
			cdata_wr <= 0;
			caddr_wr <= 0;
			csel <= 0;
			Kptr <= 0;
			busy <= 0;
			for(i=0; i<66; i=i+1)
				for(j=0;j<66;j=j+1)
					pixels[i][j] <= 0;
		end
		else begin
			state <= next_state;
			case(state)
				LOAD_pre:begin
					busy <= 1;
					pixels[x+1][y+1] <= idata; //zero-padding
				end
				LOAD:begin
					busy <= 1;
					pixels[x+1][y+1] <= idata;
					iaddr <= iaddr + 1;
				end
				CAL_pre:begin
					cwr <= 1;
					csel <= 3'b001;
					cdata_wr <= data_Relu;
				end
				CAL:begin
					cwr <= 1;
					csel <= 3'b001;
					caddr_wr <= caddr_wr + 1;
					cdata_wr <= data_Relu;
				end
				DONE:begin
					busy <= 0;
				end
			endcase
		end
		
	end

	assign x = iaddr - (y<<6);
	assign y = iaddr>>6; //從 0 開始

	assign xc = caddr_wr - (yc<<6);
	assign yc = caddr_wr>>6; //從 0 開始

	assign k0 = ($signed(pixels[ xc ][ yc ]) * $signed(20'h0A89E)); // 4.16 * 4.16 => 8.32 (40bit)
	assign k1 = ($signed(pixels[xc+1][ yc ]) * $signed(20'h092D5));
	assign k2 = ($signed(pixels[xc+2][ yc ]) * $signed(20'h06D43));
	assign k3 = ($signed(pixels[ xc ][yc+1]) * $signed(20'h01004));
	assign k4 = ($signed(pixels[xc+1][yc+1]) * $signed(20'hF8F71));
	assign k5 = ($signed(pixels[xc+2][yc+1]) * $signed(20'hF6E54));
	assign k6 = ($signed(pixels[ xc ][yc+2]) * $signed(20'hFA6D7));
	assign k7 = ($signed(pixels[xc+1][yc+2]) * $signed(20'hFC834));
	assign k8 = ($signed(pixels[xc+2][yc+2]) * $signed(20'hFAC19));

	assign data_temp = k0 + k1 + k2 + k3 + k4 + k5 + k6 + k7 + k8 + $signed(20'h01310); //40bit * 10(個) =>取44bit (12.32)
	assign data = (data_temp + (1 << 15)) >>> 16;  //小數第17位 四捨五入(第 17-bit 置 1)
	// ReLU 操作
	assign data_Relu = (data_temp > 0) ? data_temp : 0;


endmodule




