
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
	
	output reg [2:0]
	);

	reg [2:0] state, next_state;
	parameter IDLE = 0, LOAD = 1, OUT_L0 = 2, OUT_L1 = 3;
	parameter k0 = 20'h0A89E, k1 = 20'h092D5, k2 = 20'h06D43, k3 = 20'h01004;
	parameter k4 = 20'hF8F71, k5 = 20'hF6E54, k6 = 20'hFA6D7, k7 = 20'hFC834, k8 = 20'hFAC19;
	wire [19:0] data;
	wire [44:0] data_tmp;
	reg [6:0] x, y;


	always@(*) begin
		case(state)
			IDLE:begin
				if(ready) next_state = LOAD;
				else next_state = IDLE;
			end
			LOAD:begin
				if(cnt>=9) next_state = OUT_L0;
				else next_state = LOAD;
			end
			OUT_L0:begin
				next_state = LOAD;
			end
			OUT_L1:begin
			end
		endcase
	end



	always @(posedge clk or posedge reset) begin
		if(reset) begin
			state <= IDLE;
			busy  <= 0;

			cwr   <= 0;
			caddr_wr <= 0;
			cdata_wr <= 0;

			crd   <= 0;
			caddr_rd <= 0;

			csel <= 0;
		end
		else begin
			state <= next_state;
			case(state)
				IDLE:begin
					busy  <= 1;
					iaddr <= 0;
					cnt   <= 0;
				end
				LOAD:begin
					cnt <= cnt + 1;
				end
				OUT_L0:begin
				end
				OUT_L1:begin
				end
			endcase
		end
	end

	always @(posedge clk or posedge reset) begin
		if(reset) begin
			iaddr <= 0;
		end
		else begin
			case(cnt)
				0: iaddr = caddr_wr;
				1: iaddr = caddr_wr;
				2: iaddr = caddr_wr;
				3: iaddr = caddr_wr - 1;
				4: iaddr = caddr_wr;
				5: iaddr = caddr_wr + 1;
				6: iaddr = caddr_wr;
				7: iaddr = caddr_wr;
				8: iaddr = caddr_wr;
			endcase
		end
	end

	always@(*) begin
		case(cnt)
		0: k_reg = k0;
		1: k_reg = k1;
		2: k_reg = k2;
		3: k_reg = k3;
		4: k_reg = k4;
		5: k_reg = k5;
		6: k_reg = k6;
		7: k_reg = k7;
		8: k_reg = k8;
		endcase
	end

	always@(*) begin
		case(cnt)
			0: x = caddr_wr > 64 ? ;
			1: k_reg = k1;
			2: k_reg = k2;
			3: k_reg = k3;
			4: k_reg = k4;
			5: k_reg = k5;
			6: k_reg = k6;
			7: k_reg = k7;
			8: k_reg = k8;
		endcase
	end

	assign x = iaddr - {y,6'd0};
	assign y = iaddr>>6; //從 0 開始
	


endmodule




