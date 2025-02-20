
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;


//====================================================================
reg [1:0] state, next_state;

parameter REQ = 0, LOAD = 1, CAL = 2 ;
reg [2:0] laod_cnt, i, j;
reg [7:0] gp [7:0];
// reg [8:0] ;


always @(*) begin
    case(state)
        REQ:begin
        end
        LOAD:begin
            if(cnt >= 8) next_state = CAL;
        end
    endcase
end

always@(posedge clk or negedge reset) begin
    if(reset) begin
        laod_cnt <= 0;
        i <= 1;
        j <= 1;
        gray_req <= 0;
        if(gray_ready) state <= REQ;
    end
    else begin
        state <= next_state;
        case(state)
            REQ:begin
                gray_req <= 1;
                gp[laod_cnt] <=
            end
            LOAD:begin
                if(laod_cnt >= 8) begin
                    laod_cnt <= 0;
                    gray_req <= 0;
                    gray_addr <= 0;
                end
                else begin
                    laod_cnt <= laod_cnt + 1;
                    gray_addr <= ;
                    if(j <= 2)begin
                        if(i <= 2) begin
                            gp[laod_cnt] <= 
                            i <= i+1;
                        end
                        j <= j+1;
                    end
                end
            end
            CAL:begin

            end
        endcase
    end
end

//====================================================================
endmodule
