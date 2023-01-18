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

wire [7:0] received;

uart_rx uart_rx(rst_n, clk, usb_rx, ready, error, received);

reg [7:0] led_reg;
assign led = led_reg;

always@*
    if(ready == 1'b1)
        if(error == 1'b1) led_reg = 8'hFF;
        else led_reg = received;
    else led_reg = 8'h00;

endmodule
