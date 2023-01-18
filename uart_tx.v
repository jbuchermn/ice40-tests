/////////////////////////////////////////////
module uart_tx #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 115200,
    parameter PARITY = 1
)(
    input rst,
    input clk,
    input [7:0] val,
    input start,

    output reg tx,
    output reg done
);

initial begin
    tx = 1;
    done = 1;
end

reg [7: 0] data = 0;
reg [2: 0] idx = 0;

parameter S_IDLE       = 3'b000;
parameter S_DATA_BITS  = 3'b010;
parameter S_PARITY_BIT = 3'b011;
parameter S_STOP_BIT   = 3'b100;

reg [2:0] state = S_IDLE;

parameter RATE = CLOCK_RATE / BAUD_RATE;
parameter WIDTH = $clog2(RATE);

reg [WIDTH:0] counter = 0;

always@(posedge clk) begin
    if(rst) begin
        data <= 0;
        idx <= 0;
        state <= S_IDLE;
        done <= 1;
        tx <= 1;
        counter <= 0;
    end else begin
        case(state)
            default:
                state <= S_IDLE;
            S_IDLE:
                if(start) begin
                    state <= S_DATA_BITS;
                    data <= val;
                    idx <= 0;

                    tx <= 0;
                    done <= 0;

                    counter <= 0;
                end else begin
                    tx <= 1;
                    done <= 1;
                end
            S_DATA_BITS: begin
                if(counter == RATE-1) begin
                    state <= idx == 7 ? (PARITY ? S_PARITY_BIT : S_STOP_BIT) : S_DATA_BITS;
                    idx <= idx + 1;
                    counter <= 0;

                    tx <= data[idx];
                end else begin
                    counter <= counter + 1;
                end
            end
            S_PARITY_BIT: begin
                if(counter == RATE-1) begin
                    state <= S_STOP_BIT;
                    counter <= 0;

                    tx <= ^data;
                end else begin
                    counter <= counter + 1;
                end
            end
            S_STOP_BIT: begin
                if(counter == RATE-1) begin
                    state <= S_IDLE;
                    counter <= 0;

                    tx <= 1;
                end else begin
                    counter <= counter + 1;
                end
            end

        endcase

    end
end


endmodule
