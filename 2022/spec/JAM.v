module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid );

reg [3:0] serise[7:0];
reg [3:0] cnt, ptr1, ptr2, curMin, i;
reg [2:0] state, next_state;
reg [9:0] CurCost;
reg [15:0] total;

parameter FIND_MAX = 0, FIND_MIN = 1, FLIP = 2, CAL = 3, FIN = 4;
always@(*) begin
    case(state)
        FIND_MAX: next_state = (serise[ptr1-1] > serise[ptr1]) ? FIND_MIN : FIND_MAX;
        FIND_MIN: next_state = (ptr2 < ptr1) ? FIND_MIN : FLIP;
        FLIP:     next_state = CAL;
        CAL:      next_state = cnt == 9 ? FIN : CAL;
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
    if(RST) MatchCount <= 0;
    else begin
        case(state)
            FIN:begin
                if(CurCost == MinCost) MatchCount <= MatchCount + 1;
                else if(CurCost < MinCost) MatchCount <= 1;
                else MatchCount <= MatchCount;
            end
        endcase
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) MinCost <= 9'b111111111;
    else begin
        case(state)
            FIN:begin
                if(CurCost < MinCost) MinCost <= CurCost;
                else MinCost <= MinCost;
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
                for(i=0;i<ptr1[3:1]; i=i+1)begin
                    serise[i] <= serise[ptr1-1-i];
                    serise[ptr1-1-i] <= serise[i];
                end
            end
        endcase
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        J <= 0;
        W <= 0;
        cnt <= 0;
        CurCost <= 0;
        ptr1 <= 1;
        ptr2 <= 0;
        curMin <= 8;
        total  <= 0;
    end
    else begin
        case(state)
            FIND_MAX:begin
                if(serise[ptr1-1] < serise[ptr1]) ptr1 <= ptr1 + 1;
            end
            FIND_MIN:begin
                if(ptr2 < ptr1) ptr2 <= ptr2 + 1;
                if(serise[ptr2] > serise[ptr1]) begin
                    if(curMin == 8) curMin <= ptr2;
                    else curMin <= serise[ptr2] < serise[curMin] ? ptr2 : curMin;
                end
            end
            FLIP:begin
            end
            CAL:begin
                cnt <= cnt + 1;
                ptr1 <= 1;
                ptr2 <= 0;
                curMin <= 8;
                if(cnt < 8) begin
                    J   <= cnt;
                    W   <= serise[7-cnt];
                end
                if(cnt >= 2) CurCost <= CurCost + Cost;
            end
            FIN:begin
                cnt <= 0;
                CurCost <= 0;
                total <= total + 1;
            end
        endcase
    end
end

endmodule


