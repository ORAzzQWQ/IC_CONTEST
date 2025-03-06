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
        FIND_MAX:begin
            if(serise[ptr1-1] > serise[ptr1]) next_state = FIND_MIN;
            else next_state = FIND_MAX;
        end
        FIND_MIN:begin
            if(ptr2 < ptr1) next_state = FIND_MIN;
            else next_state = FLIP;
        end
        FLIP:begin
            next_state = CAL;
        end
        CAL:begin
            if(cnt==9) next_state = FIN;
            else next_state = CAL;
        end
        FIN:begin
            next_state = FIND_MAX;
        end
        default:begin
            next_state = FIN;
        end
    endcase
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        MatchCount <= 0;
        MinCost    <= 9'b111111111;
        Valid      <= 0;
        J <= 0;
        W <= 0;

        serise[0] <= 7;
        serise[1] <= 6;
        serise[2] <= 5;
        serise[3] <= 4;
        serise[4] <= 3;
        serise[5] <= 2;
        serise[6] <= 1;
        serise[7] <= 0;

        state <= CAL;
        cnt <= 0;
        CurCost <= 0;
        ptr1 <= 1;
        ptr2 <= 0;
        curMin <= 8;
        total  <= 0;
        i <= 0;
    end
    else begin
        state <= next_state;
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
                if(CurCost == MinCost) begin
                    MatchCount <= MatchCount + 1;
                end
                else if(CurCost < MinCost) begin
                    MinCost <= CurCost;
                    MatchCount <= 1;
                end
                if(total == 40319) begin
                    Valid <= 1;
                end
            end
        endcase
    end
end

endmodule


