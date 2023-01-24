module main #(
    parameter CLOCK_RATE = 100000000
)(
    input clk,
    input rst_n,

    output [7:0] led,

    input usb_rx,
    output usb_tx
);

wire ready;
wire error;
wire done;

wire [7:0] received;
wire [7:0] processed;

assign processed = received + 1;

reg [1:0] state = 0;

uart_rx #(CLOCK_RATE, 115200) uart_rx(~rst_n, clk, usb_rx, ready, error, received);
uart_tx #(CLOCK_RATE, 115200) uart_tx(~rst_n, clk, processed, state == 1, usb_tx, done);


reg [7:0] led_reg;
assign led = led_reg;

always@*
    if(error == 1'b1) 
        led_reg = 8'hFF;
    else if(ready == 1'b1)
        led_reg = received;
    else
        led_reg = 8'h00;

always@(posedge clk) begin
    case(state)
        0:
            if(ready) state <= 1;
        1:
            if(done) state <= 2;
        2:
            if(~ready) state <= 0;
    endcase
end
endmodule
