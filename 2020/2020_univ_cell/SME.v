module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;


parameter LOAD_STR = 0, LOAD_PAT = 1, CAL = 2, OUT = 3;
reg [2:0] state, next_state;
reg cal_done;

always@(posedge clk or posedge reset) begin
    if(reset) state <= LOAD_STR;
    else state <= next_state;
end

always@(*)begin
    case(state)
        LOAD_STR: next_state = isstring ? LOAD_STR : LOAD_PAT;
        LOAD_PAT: next_state = ispattern ? LOAD_PAT : CAL;
        CAL: next_state = cal_done ? OUT : CAL;
        OUT: next_state = isstring ? LOAD_STR : LOAD_PAT;
    endcase
end

reg [7:0] str[31:0], pat[7:0];
integer i;
reg [4:0] strptr;
reg [2:0] patptr;

//load str
always@(posedge clk or posedge reset) begin
    if(reset) begin
        for (i = 0; i<32 ; i=i+1) begin
            str[i] <= 8'd0;
        end
        strptr <= 5'd0;
    end
    else if(isstring)begin
        str[strptr] <= chardata;
        strptr <= strptr + 1;
    end
    else if(next_state == LOAD_STR) begin
        for (i = 0; i<32 ; i=i+1) begin
            str[i] <= 8'd0;
        end
        strptr <= 5'd0;
    end
end

//load pat
always@(posedge clk or posedge reset) begin
    if(reset) begin
        for (i = 0; i<8 ; i=i+1) begin
            pat[i] <= 8'd0;
        end
        patptr <= 3'd0;
    end
    else if(ispattern)begin
        pat[patptr] <= chardata;
        patptr <= patptr + 1;
    end
    else if(next_state == OUT) begin
        for (i = 0; i<8 ; i=i+1) begin
            pat[i] <= 8'd0;
        end
        patptr <= 3'd0;
    end
end


reg [4:0] find_str;
reg [2:0] find_pat;

reg match_start;
reg [4:0] match_cnt;

always@(posedge clk or posedge reset) begin
    if(reset) begin
        find_str <= 5'd0;
        find_pat <= 3'd0;
        match_index <= 5'd0;
        match_cnt   <= 5'd0;
    end
    else if(state == CAL)begin
        if(find_str < strptr) begin
            if(str[find_str] == pat[find_pat]) begin
                if(match_cnt == 0) match_index <= find_str;
                match_cnt <= match_cnt + 1;
                find_str <= find_str + 1;
                find_pat <= find_pat + 1;
            end
            else begin
                match_cnt<= 5'd0;
                find_str <= find_str + 1;
            end
        end
    end
    else if(state == OUT) begin
        find_str <= 5'd0;
        find_pat <= 3'd0;
        match_cnt<= 5'd0;
    end
end

//cal_done
always@(posedge clk or posedge reset) begin
    if(reset) cal_done <= 0;
    else if(next_state == CAL)begin
        if(strptr==0) cal_done <= 1;
        else if(find_str == strptr - 1) cal_done <= 1;
    end
    else if(state == OUT) cal_done <= 0;
end


//match
always@(posedge clk or posedge reset) begin
    if(reset) match <= 0;
    else if(next_state == OUT)begin
        if(match_cnt == patptr) match <= 1;
        else match <= 0;
    end
    else if(state == OUT) match <= 0;
end

//valid
always@(posedge clk or posedge reset) begin
    if(reset) valid <= 0;
    else if(next_state == OUT) valid <= 1;
    else if(state == OUT) valid <= 0;
end



endmodule
