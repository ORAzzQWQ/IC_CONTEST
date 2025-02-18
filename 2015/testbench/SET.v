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
reg A[6:0][6:0], B[6:0][6:0];
reg [2:0] i, j, x_min_A, y_min_A, x_max_A, y_max_A, x_min_B, y_min_B, x_max_B, y_max_B;
reg [6:0] r1_s, r2_s, i_s, cnt;
reg cal_done;


reg [1:0] state, next_state;
parameter LOAD = 0, CAL = 1, OUT = 2;

always@(*) begin
    case(state)
        LOAD:begin
            if(en) next_state = CAL;
            else next_state = LOAD;
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
        busy <= 1;
        cnt <= 0;
        cal_done <= 0;
        for(i = 0; i<7; i=i+1)
            for(j = 0; j<7; j=j+1)begin
                A[i][j] <= 0;
                B[i][j] <= 0;
            end
    end
    else begin
        state <= next_state;
        case(state)
            LOAD:begin
                busy <= 0;
                {x1, y1, x2, y2} <= central[23:8];
                {r1, r2} <= radius[11:4];
                mode_reg <= mode;
            end
            CAL:begin
                busy <= 1;
                next_state = OUT;
                case(mode_reg)
                    2'b00:begin
                        for(i = 0; i<7; i=i+1)
                            for(j = 0; j<7; j=j+1)begin
                                A[i][j] <= 0;
                                B[i][j] <= 0;
                            end
                        cal_done <= 1;
                        // A[5][5] <= 1;
                        // for(i = x_min_A-1; i<x_max_A-1; i=i+1)begin
                        //     i_s = i*i;
                        //     // for(j = y_min_A-1; j<y_max_A-1; j=j+1)begin
                        //     //     if(i_s + j*j <= r1_s) begin
                        //     //         A[i][j] <= 1;
                        //     //         cnt <= cnt + 1;
                        //     //     end
                        //     //     else begin
                        //     //     end
                        //     // end
                        // end
                    end
                    2'b01:begin
                    end
                    2'b10:begin
                    end
                endcase
            end
            OUT:begin
                busy <= 1;
                next_state = LOAD;
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
    r1_s = r1*r1;
    r2_s = r2*r2;
end

endmodule
