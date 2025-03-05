module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

parameter LOAD = 0, SORT = 1, PRINT = 2, IDLE = 3;
reg [1:0]state, next_state;
reg [9:0] Xdata [5:0], Ydata [5:0], tx, ty;
reg signed [10:0] Ax, Ay, Bx, By;
reg [3:0] cnt, ptrA, ptrB, plus, i;
wire signed [20:0] cross_product;

// fsm
always @(*) begin
    case (state)
        IDLE:begin
            next_state = LOAD;
        end
        LOAD:begin
            if(cnt >= 6) next_state = SORT;
            else next_state = LOAD;
        end
        SORT:begin
            if(ptrA == 4 && ptrB == 5) next_state = PRINT;
            else next_state = SORT;
        end
        PRINT:begin
            if(ptrA == 5) next_state = IDLE;
            else next_state = PRINT;
        end
    endcase 
end
 
always@(posedge clk or posedge reset) begin
    if(reset) begin
        state <= LOAD;
        tx <= 0;
        ty <= 0;
        for(i=0;i<6;i=i+1) begin
            Xdata[i] <= 0;
            Ydata[i] <= 0;
        end
        ptrA <= 1;
        ptrB <= 2;
        plus <= 0;
        valid <= 0;
        is_inside <= 0;
        cnt <= 0;
    end
    else begin
        state <= next_state;
        case (state)
            IDLE:begin
                valid <= 0;
                is_inside <= 0;
                cnt <= 0;
                ptrA <= 1;
                ptrB <= 2;
                plus <= 0;
            end
            LOAD:begin
                if(cnt == 0) begin
                    tx <= X;
                    ty <= Y;
                end
                else begin
                    Xdata[cnt-1] <= X;
                    Ydata[cnt-1] <= Y;
                end
                cnt <= cnt + 1;
            end
            SORT:begin
                if(cross_product > 0) begin //逆時針改為順時針
                    Xdata[ptrA] <= Xdata[ptrB];
                    Xdata[ptrB] <= Xdata[ptrA];
                    Ydata[ptrA] <= Ydata[ptrB];
                    Ydata[ptrB] <= Ydata[ptrA];
                end

                if(ptrA == 4 && ptrB == 5) begin
                    ptrA <= 0;
                    ptrB <= 1;
                end
                else if(ptrB < 5) begin
                    ptrB <= ptrB + 1;
                end
                else begin
                    ptrA <= ptrA + 1;
                    ptrB <= ptrA + 2;
                end
            end
            PRINT:begin
                if(cross_product > 0) begin
                    plus <= plus + 1;
                end

                if(ptrA == 5) begin
                    valid <= 1;
                    if(plus == 0 || plus == 6) is_inside <= 1;
                    else is_inside <= 0;
                end
                else if(ptrA == 4) begin
                    ptrA <= 5;
                    ptrB <= 0;
                end
                else begin
                    ptrA <= ptrA + 1;
                    ptrB <= ptrB + 1;
                end

            end
        endcase         
    end
end

assign cross_product = Ax * By - Bx * Ay;

always@(*)begin
    Ax = 0;
    Ay = 0;
    Bx = 0;
    By = 0;
    case(state)
        SORT:begin
            Ax = Xdata[ptrA] - Xdata[0];
            Ay = Ydata[ptrA] - Ydata[0];
            Bx = Xdata[ptrB] - Xdata[0];
            By = Ydata[ptrB] - Ydata[0];
        end
        PRINT:begin
            Ax = Xdata[ptrA] - tx;
            Ay = Ydata[ptrA] - ty;
            Bx = Xdata[ptrB] - Xdata[ptrA];
            By = Ydata[ptrB] - Ydata[ptrA];      
        end
    endcase
end
endmodule

