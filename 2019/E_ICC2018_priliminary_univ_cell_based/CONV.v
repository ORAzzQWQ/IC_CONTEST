
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
	
	output reg [2:0] csel
	);

	reg [3:0] state, next_state;
	parameter IDLE = 0, LOAD = 1, OUT_L0 = 2, READ_L1 = 3, OUT_L1 = 4, FIN = 5;
	parameter k0 = 20'h0A89E, k1 = 20'h092D5, k2 = 20'h06D43, k3 = 20'h01004;
	parameter k4 = 20'hF8F71, k5 = 20'hF6E54, k6 = 20'hFA6D7, k7 = 20'hFC834, k8 = 20'hFAC19;
	parameter bias = 20'h01310;

	reg [11:0] addr_cnt; //{y,x} y:addr_cnt[11:6] ,  x:addr_cnt[5:0]
	reg [3:0]  cnt;

	wire [5:0] x, y;

	assign x = addr_cnt[5:0];
	assign y = addr_cnt[11:6];

	reg signed [19:0] pix;
	reg signed [19:0] kernel;

	reg signed [19:0] max;

	always@(posedge clk or posedge reset)begin
		if(reset) state <= IDLE;
		else state <= next_state;
	end

	always@(*) begin
		case (state)
			IDLE:    next_state = LOAD;
			LOAD:    next_state = (cnt == 11) ? OUT_L0 : LOAD;
			OUT_L0:  next_state = (addr_cnt == 4095) ? READ_L1 : LOAD;
			READ_L1: next_state = (cnt == 4) ? OUT_L1 : READ_L1;
			OUT_L1:  next_state = (addr_cnt == 4030) ? FIN : READ_L1;
			FIN:     next_state = IDLE;
			default: next_state = IDLE;
		endcase
	end

	always@(posedge clk or posedge reset)begin
		if(reset) busy <= 0;
		else if(ready) busy <= 1;
		else if(state == FIN) busy <= 0;
	end

	always@(posedge clk or posedge reset)begin
		if(reset) begin
			addr_cnt <= 0;
		end
		else begin
			case (state)
				OUT_L0: addr_cnt <= addr_cnt + 1;
				OUT_L1: begin
					if(x==62) addr_cnt <= {y + 6'd2, 6'd0};
					else addr_cnt <= addr_cnt + 2;
				end
				default: addr_cnt <= addr_cnt;
			endcase
		end
	end

	always @(posedge clk or posedge reset) begin
		if(reset) cnt <= 0;
		else begin
			case (state)
				LOAD:    cnt <= cnt + 1;
				READ_L1: cnt <= cnt + 1;
				default: cnt <= 0;
			endcase
		end
	end

	always @(posedge clk or posedge reset) begin
		if(reset) iaddr <= 0;
		else if(state == LOAD) begin
			case(cnt)
				0: iaddr <= (y == 0 || x == 0) ? 20'd0 : {y - 6'd1, x - 6'd1}; 
				1: iaddr <= (y == 0) ? 20'd0 : {y - 6'd1, x};
				2: iaddr <= (y == 0 || x == 63) ? 20'd0 : {y - 6'd1, x + 6'd1};
				3: iaddr <= (x == 0) ? 20'd0 : {y, x - 6'd1};
				4: iaddr <= {y, x};
				5: iaddr <= (x == 63) ? 20'd0 : {y, x + 6'd1};
				6: iaddr <= (y == 63 || x == 0) ? 20'd0 : {y + 6'd1, x - 6'd1};
				7: iaddr <= (y == 63) ? 20'd0 : {y + 6'd1, x};
				8: iaddr <= (y == 63 || x == 63) ? 20'd0 : {y + 6'd1, x + 6'd1};
				default: iaddr <= iaddr;
			endcase
		end
	end

	always @(*) begin
		case(cnt)
			1: pix = (y == 0 || x == 0) ? 20'd0 : idata; 
			2: pix = (y == 0) ? 20'd0 : idata;
			3: pix = (y == 0 || x == 63) ? 20'd0 : idata;
			4: pix = (x == 0) ? 20'd0 : idata;
			5: pix = idata;
			6: pix = (x == 63) ? 20'd0 : idata;
			7: pix = (y == 63 || x == 0) ? 20'd0 : idata;
			8: pix = (y == 63) ? 20'd0 : idata;
			9: pix = (y == 63 || x == 63) ? 20'd0 : idata;
			default: pix = 20'd0;
		endcase
	end

	always @(*) begin
		case(cnt)
			1: kernel = k0;
			2: kernel = k1;
			3: kernel = k2;
			4: kernel = k3;
			5: kernel = k4;
			6: kernel = k5;
			7: kernel = k6;
			8: kernel = k7;
			9: kernel = k8;
			default: kernel = 0;
		endcase
	end

	wire signed [39:0] product_tmp;
	assign product_tmp = kernel * pix;

	reg signed [39:0] product_sum;
	always @(posedge clk or posedge reset) begin
		if(reset) product_sum <= 40'd0;
		else if(state == LOAD)begin
			case(cnt)
				0: product_sum <= 40'd0;
				1: product_sum <= product_sum + product_tmp;
				2: product_sum <= product_sum + product_tmp;
				3: product_sum <= product_sum + product_tmp;
				4: product_sum <= product_sum + product_tmp;
				5: product_sum <= product_sum + product_tmp;
				6: product_sum <= product_sum + product_tmp;
				7: product_sum <= product_sum + product_tmp;
				8: product_sum <= product_sum + product_tmp;
				9: product_sum <= product_sum + product_tmp;
				10: product_sum <= product_sum + {4'd0, bias, 1'b1, 15'd0}; //1'b1用於四捨五入
				default: product_sum <= product_sum; 
			endcase
		end
		else begin
			product_sum <= 40'd0;
		end
	end
	// reg signed [39:0] product_sum_reg;
	// always@(*) begin
	// 	product_sum_reg = product_sum[39] ? 20'd0 : product_sum[35:16];
	// end


	always@(posedge clk or posedge reset)begin
		if(reset) begin
			cwr <= 0;
			caddr_wr <= 0;
			cdata_wr <= 0;
		end
		else begin
			case (state)  
				OUT_L0:begin
					cwr <= 1;
					caddr_wr <= addr_cnt;
					cdata_wr <= product_sum[39] ? 20'd0 : product_sum[35:16];
				end
				OUT_L1:begin
					cwr <= 1;
					caddr_wr <= caddr_wr + 1;
					cdata_wr <= max;
				end
				default: begin
					cwr <= 0;
					cdata_wr <= 0;
				end
			endcase
		end
	end

	always@(posedge clk or posedge reset)begin
		if(reset) begin
			csel <= 3'b000;
		end
		else begin
			case (state)  
				OUT_L0: csel <= 3'b001;
				READ_L1:csel <= 3'b001;
				OUT_L1: csel <= 3'b011;
				default:csel <= 3'b000;
			endcase
		end
	end

	always @(posedge clk or posedge reset) begin
		if(reset) begin
			crd <= 0;
			caddr_rd <= 0;
		end
		else if(state == READ_L1) begin
			crd <= 1;
			case(cnt)
				0: caddr_rd <= {y, x}; 
				1: caddr_rd <= {y, x + 6'd1};
				2: caddr_rd <= {y + 6'd1, x};
				3: caddr_rd <= {y + 6'd1, x + 6'd1};
				default: caddr_rd <= caddr_rd;
			endcase
		end
		else begin
			crd <= 0;
			caddr_rd <= 0;
		end
	end

	always @(posedge clk or posedge reset) begin
		if(reset) max <= 0;
		else if(state == READ_L1) begin
			case(cnt)
				1: max <= cdata_rd; 
				2: max <= cdata_rd > max ? cdata_rd : max;
				3: max <= cdata_rd > max ? cdata_rd : max;
				4: max <= cdata_rd > max ? cdata_rd : max;
				default: max <= max;
			endcase
		end
		else begin
			max <= 0;
		end
	end
endmodule




