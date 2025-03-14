module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid );

reg [2:0] serise[7:0];
reg [3:0] cnt, curMin, data_ready;
reg [2:0] ptr1, ptr2, i;
reg [2:0] state, next_state;
reg [9:0] CurCost;
reg [15:0] total;

parameter FIND_MAX = 0, FIND_MIN = 1, FLIP = 2, CAL = 3, FIN = 4;
always@(*) begin
    case(state)
        FIND_MAX: next_state = (serise[ptr1-1] > serise[ptr1]) ? FIND_MIN : FIND_MAX;
        FIND_MIN: next_state = (ptr2 < ptr1) ? FIND_MIN : FLIP;
        FLIP:     next_state = CAL;
        CAL:      next_state = (cnt == 9 || CurCost > MinCost)? FIN : CAL;
        FIN:      next_state = FIND_MAX;
        default:  next_state = FIN;
    endcase
end

always@(posedge CLK or posedge RST) begin
    if(RST) state <= CAL;
    else    state <= next_state;
end

always@(posedge CLK or posedge RST) begin
    if(RST) Valid <= 0;
    else if(total == 40319) Valid <= 1;
    else Valid <= 0;
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin 
        MatchCount <= 0;
        MinCost <= 10'd1023;
    end
    else begin
        case(state)
            FIN:begin
                if(CurCost == MinCost) MatchCount <= MatchCount + 1;
                else if(CurCost < MinCost) begin
                    MinCost <= CurCost;
                    MatchCount <= 1;
                end
            end
            default:begin
            end
        endcase
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        serise[0] <= 7;
        serise[1] <= 6;
        serise[2] <= 5;
        serise[3] <= 4;
        serise[4] <= 3;
        serise[5] <= 2;
        serise[6] <= 1;
        serise[7] <= 0;
        i <= 0;
    end
    else begin
        case(state)
            FIND_MIN:begin
                if(ptr1 == ptr2) begin
                    serise[curMin] <= serise[ptr1];
                    serise[ptr1]   <= serise[curMin];
                end
            end
            FLIP:begin
                for(i=0;i<ptr1[2:1]; i=i+1)begin
                    serise[i] <= serise[ptr1-1-i];
                    serise[ptr1-1-i] <= serise[i];
                end
            end
        endcase
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        ptr1 <= 1;
        ptr2 <= 0;
    end
    else begin
        case(state)
            FIND_MAX:if(serise[ptr1-1] < serise[ptr1]) ptr1 <= ptr1 + 1;
            FIND_MIN:if(ptr2 < ptr1) ptr2 <= ptr2 + 1;
            default:begin
                ptr1 <= 1;
                ptr2 <= 0;
            end
        endcase
    end
end

always@(posedge CLK or posedge RST) begin //cnt
    if(RST) begin
        cnt <= 0;
        data_ready <= 0;
    end
    else if(state == FIND_MIN) begin
        cnt <= 7-ptr1;
        data_ready <= 0;
    end
    else if(state == CAL)begin
        cnt <= cnt + 1;
        data_ready <= data_ready + 1;
    end
end

always@(posedge CLK or posedge RST) begin //W, J
    if(RST) begin
        J <= 0;
        W <= 0;
    end
    else if(state == CAL) begin
        case(cnt)
            0:begin
                J <= 0;
                W <= serise[7];
            end
            1:begin
                J <= 1;
                W <= serise[6];
            end
            2:begin
                J <= 2;
                W <= serise[5];
            end
            3:begin
                J <= 3;
                W <= serise[4];
            end
            4:begin
                J <= 4;
                W <= serise[3];
            end
            5:begin
                J <= 5;
                W <= serise[2];
            end
            6:begin
                J <= 6;
                W <= serise[1];
            end
            7:begin
                J <= 7;
                W <= serise[0];
            end
        endcase
    end
end

reg [9:0] CostSum [7:0];  // Prefix sum
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        CurCost <= 0;
        curMin <= 8;
        total  <= 0;

        CostSum[0] <= 0;
        CostSum[1] <= 0;
        CostSum[2] <= 0;
        CostSum[3] <= 0;
        CostSum[4] <= 0;
        CostSum[5] <= 0;
        CostSum[6] <= 0;
        CostSum[7] <= 0;
    end
    else begin
        case(state)
            FIND_MIN:begin
                if(serise[ptr2] > serise[ptr1]) begin
                    if(curMin == 8) curMin <= ptr2;
                    else curMin <= serise[ptr2] < serise[curMin] ? ptr2 : curMin;
                end
            end
            CAL:begin
                curMin <= 8;
                if (data_ready>1) begin
                    case(cnt)
                        2:begin
                            CostSum[7] <= Cost;
                            CurCost <= Cost;
                        end
                        3:begin
                            CostSum[6] <= CostSum[7] + Cost;
                            CurCost <= CostSum[7] + Cost;
                        end
                        4:begin
                            CostSum[5] <= CostSum[6] + Cost;
                            CurCost <= CostSum[6] + Cost;
                        end
                        5:begin
                            CostSum[4] <= CostSum[5] + Cost;
                            CurCost <= CostSum[5] + Cost;
                        end
                        6:begin
                            CostSum[3] <= CostSum[4] + Cost;
                            CurCost <= CostSum[4] + Cost;
                        end
                        7:begin
                            CostSum[2] <= CostSum[3] + Cost;
                            CurCost <= CostSum[3] + Cost;
                        end
                        8:begin
                            CostSum[1] <= CostSum[2] + Cost;
                            CurCost <= CostSum[2] + Cost;
                        end
                        9:begin
                            CostSum[0] <= CostSum[1] + Cost;
                            CurCost <= CostSum[1] + Cost;
                        end
                    endcase
                end
            end
            FIN:begin
                CurCost <= 0;
                total <= total + 1;
            end
        endcase
    end
end
endmodule


