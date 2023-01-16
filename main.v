module main #(
    parameter CLOCK_RATE = 100000000
)(
    input clk,
    input rst_n,

    output[7:0] led,

    input usb_rx,
    output usb_tx
);

parameter TARGET_RATE = 12;
parameter RATE = CLOCK_RATE / (2 * TARGET_RATE);
parameter WIDTH = $clog2(RATE);

reg [WIDTH - 1:0] counter;
reg dir;

initial begin
    counter = WIDTH'b0;
    led = 8'b1;
    dir = 1'b1;
end

always@(posedge clk) begin
    if(counter == RATE[WIDTH-1:0]) begin
        counter <= 0;
        if((led == 8'b10000000 && dir == 1'b1) || (led == 8'b00000001 && dir == 1'b0)) begin
            dir = ~dir;
        end

        if(dir == 1'b1) begin
            led = led << 1;
        end else begin
            led = led >> 1;
        end

    end else begin
        counter <= counter + 1'b1;
    end
end

endmodule
