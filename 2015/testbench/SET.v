module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [3:0] x1, y1, x2, y2, r1, r2;
reg [1:0] mode_reg;
reg [3:0] i, j, x_min_A, y_min_A, x_max_A, y_max_A, x_min_B, y_min_B, x_max_B, y_max_B;
reg [6:0] cnt;
reg [2:0] cal_cnt;
reg [2:0] cal_done;
reg [3:0] i_bar, j_bar;


reg [1:0] state, next_state;
parameter LOAD = 0, CAL_p = 1, CAL = 2, OUT = 3;

reg [6:0] table_S [7:0];

initial begin
    table_S[0] = 7'd0;
    table_S[1] = 7'd1;
    table_S[2] = 7'd4;
    table_S[3] = 7'd9;
    table_S[4] = 7'd16;
    table_S[5] = 7'd25;
    table_S[6] = 7'd36;
    table_S[7] = 7'd49;
end

always@(*) begin
    case(state)
        LOAD:begin
            if(en) next_state = CAL;
            else next_state = LOAD;
        end
        CAL_p:begin
            next_state = CAL;
        end
        CAL:begin
            if(cal_done) next_state = OUT;
            else next_state = CAL;
        end
        OUT:begin
            next_state = LOAD;
        end
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= LOAD;
        x1 <= 0;
        y1 <= 0;
        x2 <= 0;
        y2 <= 0;
        r1 <= 0;
        r2 <= 0;
        r2 <= 0;
        i <= 0;
        j <= 0;
        busy <= 0;
        cnt <= 0;
        cal_cnt <= 0;
        cal_done <= 0;
        valid <= 0;
        cnt <= 0;
    end
    else begin
        state <= next_state;
        case(state)
            LOAD:begin
                busy <= 1;
                {x1, y1, x2, y2} <= central[23:8];
                {r1, r2} <= radius[11:4];
                mode_reg <= mode;
                i <= 1;
                j <= 1;
                cnt <= 0;
                cal_done <= 0;
            end
            CAL_p:begin
                i <= x_min_A;
                j <= y_min_A;
            end
            CAL:begin
                busy <= 1;
                case(mode_reg)
                    2'b00:begin
                        if(j <= y_max_A) begin
                            if(i <= x_max_A) begin
                                if(table_S[i_bar] + table_S[j_bar] <= table_S[r1]) cnt <= cnt + 1;
                                i <= i+1;
                            end
                            else begin
                                i <= x_min_A;
                                j <= j+1;
                            end
                        end
                        else begin
                            cal_done <= 1;
                            valid <= 1;
                        end
                    end
                    2'b01:begin
                    end
                    2'b10:begin
                    end
                endcase
            end
            OUT:begin
                busy <= 0;
                valid <= 0;
            end

        endcase
    end
    
end

always@(*) begin
    x_min_A = x1 - r1 >= 1 ? x1 - r1 : 1;
    y_min_A = y1 - r1 >= 1 ? y1 - r1 : 1;
    x_max_A = x1 + r1 >= 8 ? 8 : x1 + r1;
    y_max_A = y1 + r1 >= 8 ? 8 : y1 + r1;

    x_min_B = x2 - r2 >= 1 ? x2 - r2 : 1;
    y_min_B = y2 - r2 >= 1 ? y2 - r2 : 1;
    x_max_B = x2 + r2 >= 8 ? 8 : x2 + r2;
    y_max_B = y2 + r2 >= 8 ? 8 : y2 + r2;

    i_bar = i >= x1 ? i-x1 : x1-i;
    j_bar = j >= y1 ? j-y1 : y1-j;
    
    candidate = cnt;
end

endmodule
