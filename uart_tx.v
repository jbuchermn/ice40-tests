/////////////////////////////////////////////
`define INCLUDE_UART_TX_PARITY

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
parameter S_DATA_BITS  = 3'b001;
parameter S_STOP_BIT   = 3'b010;
parameter S_DONE       = 3'b011;

`ifdef INCLUDE_UART_TX_PARITY
parameter S_PARITY_BIT = 3'b100;
reg parity = 0;
`endif

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
        if(state == S_IDLE | counter != RATE-1) begin
            counter <= counter + 1;

            if(state == S_IDLE) begin
                if(start) begin
                    state <= S_DATA_BITS;
                    counter <= 0;
                    idx <= 0;

                    data <= val;
`ifdef INCLUDE_UART_TX_PARITY
                    parity <= 0;
`endif
                    tx <= 0;
                    done <= 0;
                end else begin
                    tx <= 1;
                    done <= 1;
                end
            end

        end else begin
            counter <= 0;

            case(state)
                default:
                    state <= S_IDLE;

                S_DATA_BITS: begin
`ifdef INCLUDE_UART_TX_PARITY
                    state <= idx == 7 ? (PARITY ? S_PARITY_BIT : S_STOP_BIT) : S_DATA_BITS;
                    parity <= parity ^ data[0];
`else
                    state <= idx == 7 ? S_STOP_BIT : S_DATA_BITS;
`endif
                    idx <= idx + 1;
                    data <= data >> 1;
                    tx <= data[0];
                end
`ifdef INCLUDE_UART_TX_PARITY
                S_PARITY_BIT: begin
                    state <= S_STOP_BIT;
                    tx <= parity;
                end
`endif
                S_STOP_BIT: begin
                    state <= S_DONE;
                    tx <= 1;
                end

                S_DONE: begin
                    state <= S_IDLE;
                    tx <= 1;
                    done <= 1;
                end
            endcase
        end

    end
end


endmodule
