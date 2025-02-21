
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output reg [13:0] 	gray_addr;
output reg       	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output reg [13:0] 	lbp_addr;
output reg	lbp_valid;
output reg [7:0] 	lbp_data;
output reg	finish;


//====================================================================
reg [1:0] state, next_state;

parameter REQ = 0, LOAD = 1, CAL = 2;
reg [3:0] laod_cnt;
reg [8:0] lbp, lbp_total;
reg [63:0] get_addr, out_addr;
reg [7:0] gc, gp;
reg [63:0] k; //判斷輸出為0的位置

always @(*) begin
    case(state)
        REQ:begin
            if(gray_ready) next_state = LOAD;
            else next_state = REQ;
        end
        LOAD:begin
            if(laod_cnt >= 9) next_state = CAL;
            else next_state = LOAD;
        end
        CAL:begin
            next_state = REQ;
        end
    endcase
end

always@(posedge clk or posedge reset) begin
    if(reset) begin
        gray_addr <= 0;
        gray_req  <= 0;

        lbp_addr  <= 0;
        lbp_valid <= 0;
        lbp_data  <= 0;
        finish    <= 0;

        laod_cnt <= 0;
        out_addr <= 129;
        lbp <= 0;
        lbp_total <= 0;
        gc <= 0;
        gp <= 0;
        k  <= 254; 
        state <= REQ;
    end
    else begin
        state <= next_state;
        case(state)
            REQ:begin
                lbp <= 0;
                gray_req <= 1;
                lbp_valid <= 0;
                gray_addr <= out_addr;
                lbp_total <= 0;
            end
            LOAD:begin
                lbp_valid <= 0;
                gray_addr <= get_addr;
                lbp_total <= lbp_total + lbp;
                if(laod_cnt == 0) begin
                    gc <= gray_data;
                    laod_cnt <= laod_cnt + 1;
                end
                else if(laod_cnt >= 9) begin
                    laod_cnt <= 0;
                    gray_req <= 0;
                end
                else begin
                    laod_cnt <= laod_cnt + 1;
                    gp <= gray_data;
                end
            end
            CAL:begin
                if(out_addr >= 16254) begin
                    out_addr <= 129;
                    finish <= 1;
                end
                else if(out_addr == k) begin
                    out_addr <= out_addr + 3;
                    k <= k + 128;
                end
                else begin
                    out_addr <= out_addr + 1;
                end
                lbp_valid <= 1;
                lbp_data <= lbp_total;
                lbp_addr <= out_addr;
            end
        endcase
    end
end

always@(*)begin
    case(laod_cnt)
        0:get_addr = out_addr - 129;
        1:get_addr = out_addr - 128;
        2:get_addr = out_addr - 127;
        3:get_addr = out_addr - 1;
        4:get_addr = out_addr + 1;
        5:get_addr = out_addr + 127;
        6:get_addr = out_addr + 128;
        7:get_addr = out_addr + 129;
        default:get_addr = out_addr;
    endcase
end

// data會比get_addr晚一cycle給,比較就要再更晚一步比
always@(*)begin
    case(laod_cnt)
        2:lbp = gp >= gc ? 1 : 0;
        3:lbp = gp >= gc ? 2 : 0;
        4:lbp = gp >= gc ? 4 : 0;
        5:lbp = gp >= gc ? 8 : 0;
        6:lbp = gp >= gc ? 16 : 0;
        7:lbp = gp >= gc ? 32 : 0;
        8:lbp = gp >= gc ? 64 : 0;
        9:lbp = gp >= gc ? 128 : 0;
        default:lbp = 0;
    endcase
end
//====================================================================
endmodule
