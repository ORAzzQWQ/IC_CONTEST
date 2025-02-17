module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output reg [7:0]   dataout;
output reg      output_valid;
output reg      busy;

reg [2:0] state, next_state;
reg [7:0] img [35:0];
reg [5:0] cnt,mul,i;
reg [5:0] outcnt;
reg [5:0] out_x, out_y;


parameter Reflash = 0, Load = 1, Right = 2, Left = 3, Up = 4, Down = 5;
parameter DECODE = 0, LOAD = 1, CAL = 2, DISPLAY = 3;

always@(*) begin
    case(state)
        DECODE:begin
            if(cmd_valid) begin
                busy = 1;
                case(cmd)
                    Reflash:begin
                        next_state = DISPLAY;
                    end
                    Load:begin
                        next_state = LOAD;
                    end
                    default:begin
                        next_state = CAL;
                    end
                endcase
            end
            else begin
                busy = 0;
                next_state = DECODE;
            end
        end
        LOAD:begin
            busy = 1;
            if(cnt >= 35) next_state = DISPLAY;
            else next_state = LOAD;
        end
        CAL:begin
            busy = 1;
            next_state = DISPLAY;
        end
        DISPLAY:begin
            busy = 1;
            if(outcnt >= 8) next_state = DECODE;
            else next_state = DISPLAY;
        end
    endcase
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        state <= DECODE;
        cnt <= 0;
        outcnt <= 0;
        mul <= 0;
        busy <= 0;
        for(i=0;i<36; i=i+1)
            img[i] <= 0;
    end
    else begin
        state <= next_state;

        case(state)
            DECODE:begin
                cnt <= 0;
                outcnt <= 0;
                // busy <= 0;
                output_valid <= 0;
            end
            LOAD:begin
                // busy <= 1;
                img[cnt] <= datain;
                cnt <= cnt+1;
                out_x <= 2;
                out_y <= 2;
            end
            CAL:begin
                // busy <= 1;
                case(cmd)
                    Right:begin
                        if(out_x<3) out_x <= out_x+1;
                        else out_x <= out_x;
                    end
                    Left:begin
                        if(out_x>=1) out_x <= out_x-1;
                        else out_x <= out_x;
                    end
                    Up:begin
                        if(out_y>=1) out_y <= out_y-1;
                        else out_y <= out_y;
                    end
                    Down:begin
                        if(out_y<3) out_y <= out_y+1;
                        else out_y <= out_y;
                    end
                endcase
            end
            DISPLAY:begin
                // busy <= 1;
                output_valid <= 1;
                dataout <= img[mul];
                outcnt <= outcnt + 1;
            end
        endcase


    end
end

always@(*)begin
    if(outcnt < 3) mul = out_y*6 + out_x + outcnt;
    else if(outcnt < 6) mul = out_y*6 + out_x + outcnt +3;
    else mul = out_y*6 + out_x + outcnt + 6;
end
                                                                                     
endmodule
