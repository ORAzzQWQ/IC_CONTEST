module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  [7:0]   dataout;
output          output_valid;
output          busy;

reg [2:0] state, next_state;
reg [7:0] img [5:0][5:0];
reg [5:0] cnt;
reg [5:0] outcnt;

parameter Reflash = 0, Load = 1, Right = 2, Left = 3, Up = 4, Down = 5;
parameter DECODE = 0, LOAD = 1, CAL = 2, DISPLAY = 3;

always@(*) begin
    case(state) begin
        DECODE:begin
            if(cmd_valid) begin
                case(cmd)begin
                    Reflash:begin
                        next_state = DISPLAY;
                    end
                    Load:begin
                        next_state = LOAD;
                    end
                    default:begin
                        next_state = CAL;
                    end
                end
                endcase
            end
            else begin
                next_state = DECODE;
            end
        end
        LOAD:begin
            if(cnt >= 36) next_state = DISPLAY;
            else next_state = LOAD;
        end
        CAL:begin
            next_state = DISPLAY;
        end
        DISPLAY:begin
            if(outcnt >= 9) next_state = DECODE;
            else next_state = DISPLAY;
        end
    end
    endcase
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        cnt <= 0;
        for(integer i=0;i<6;i++)
            for(integer j=0; j<6;j++)
                img[i][j] <= 0;
    end
    else begin
        state <= next_state;

        case(cmd) begin
            Reflash:begin

            end
            Load:begin
            end
            Right:begin
            end
            Left:begin
            end
            Up:begin
            end
            Down:begin
            end
        end
        endcase
    end
end


                                                                                     
endmodule
