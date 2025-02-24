
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

	reg [1:0] state, next_state;
	reg [3:0] Kptr;//Kernel ptr
	reg [19:0] pixels [65:0][65:0];
	reg [8:0] i, j, cnt;
	wire signed [39:0] k0, k1, k2, k3, k4, k5, k6, k7, k8;  // 40-bit 乘法結果
	wire signed [39:0] data_temp;
	wire signed [19:0] data, data_Relu;



	parameter LOAD = 0, CAL = 1, DONE = 2;

	always@(*) begin
		case(state)
			LOAD: begin
				if(iaddr >= 4095) next_state = CAL;
				else next_state = LOAD;
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
			state <= LOAD;
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
				LOAD:begin
					busy <= 1;
					if(i >= 66 && j >= 66) begin
						i <= 1;
						j <= 1;
						iaddr <= 0;
					end
					else if(iaddr >= 4095) begin
						i <= 1;
						j <= 1;
						cnt <= 0;
					end
					else if(cnt >= 64) begin
						i <= 1;
						j <= j+1;
						cnt <= 0;
					end
					else begin
						pixels[i][j] <= idata;
						i <= i + 1;
						cnt <= cnt + 1;
						iaddr <= iaddr + 1;
					end
					
				end
				CAL:begin
					if(cnt >= 64) begin
						i <= 1;
						j <= j+1;
						cnt <= 0;
					end
					else begin
						i <= i + 1;
						cnt <= cnt + 1;
					end
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


	assign k0 = ($signed(pixels[i-1][j-1]) * $signed(20'h0A89E)) >>> 16;
	assign k1 = ($signed(pixels[ i ][j-1]) * $signed(20'h092D5)) >>> 16;
	assign k2 = ($signed(pixels[i+1][j-1]) * $signed(20'h06D43)) >>> 16;
	assign k3 = ($signed(pixels[i-1][ j ]) * $signed(20'h01004)) >>> 16;
	assign k4 = ($signed(pixels[ i ][ j ]) * $signed(20'hF8F71)) >>> 16;
	assign k5 = ($signed(pixels[i+1][ j ]) * $signed(20'hF6E54)) >>> 16;
	assign k6 = ($signed(pixels[i-1][j+1]) * $signed(20'hFA6D7)) >>> 16;
	assign k7 = ($signed(pixels[ i ][j+1]) * $signed(20'hFC834)) >>> 16;
	assign k8 = ($signed(pixels[i+1][j+1]) * $signed(20'hFAC19)) >>> 16;

	// 加總後仍然是 40-bit
	assign data_temp = k0 + k1 + k2 + k3 + k4 + k5 + k6 + k7 + k8 + ($signed(20'h01310) <<< 16);

	// 取 20-bit 結果
	assign data = data_temp[35:16];  

	// ReLU 操作
	assign data_Relu = (data > 0) ? data : 0;


endmodule




