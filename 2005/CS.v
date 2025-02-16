`timescale 1ns/10ps
/*
 * IC Contest Computational System (CS)
*/
module CS(Y, X, reset, clk);

input clk, reset; 
input [7:0] X;
output [9:0] Y;

reg [10:0] sum;
reg [3:0] i;
reg [7:0] arr_X[8:0];

always@(posedge clk or posedge reset)begin
    if(reset) begin
       for(i=0 ; i<9 ; i=i+1) begin
            arr_X[i] <= 0;
        end
        sum <= 0;
        i <= 0;
    end
    else begin
        for(i=8 ; i>0 ; i=i-1) begin
            arr_X[i] <= arr_X[i-1];
        end
        arr_X[0] <= X;
        sum <= sum - arr_X[8] + X;
    end
end

reg [8:0] Xappr, Xavg;
reg [7:0] x0, x1, x2, x3, x4, x5, x6, x7, x8, cmp0, cmp1, cmp2, cmp3, cmp4, cmp5, cmp6;
assign Xavg = sum / 9;
assign x0 = (arr_X[0] <= Xavg) ? arr_X[0] : 0;
assign x1 = (arr_X[1] <= Xavg) ? arr_X[1] : 0;
assign x2 = (arr_X[2] <= Xavg) ? arr_X[2] : 0;
assign x3 = (arr_X[3] <= Xavg) ? arr_X[3] : 0;
assign x4 = (arr_X[4] <= Xavg) ? arr_X[4] : 0;
assign x5 = (arr_X[5] <= Xavg) ? arr_X[5] : 0;
assign x6 = (arr_X[6] <= Xavg) ? arr_X[6] : 0;
assign x7 = (arr_X[7] <= Xavg) ? arr_X[7] : 0;
assign x8 = (arr_X[8] <= Xavg) ? arr_X[8] : 0;

assign cmp0 = (x0 > x1) ? x0 : x1;
assign cmp1 = (x2 > x3) ? x2 : x3;
assign cmp2 = (x4 > x5) ? x4 : x5;
assign cmp3 = (x6 > x7) ? x6 : x7;

assign cmp4 = (cmp0 > cmp1) ? cmp0 : cmp1;
assign cmp5 = (cmp2 > cmp3) ? cmp2 : cmp3;

assign cmp6 = (cmp4 > cmp5) ? cmp4 : cmp5;

assign Xappr = (cmp6 > x8) ? cmp6 : x8;

assign Y = ((sum + Xappr)>>3) + Xappr;

endmodule

