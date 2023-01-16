module main(
    input clk,
    input rst_n,
    output[7:0] led,
    input usb_rx,
    output usb_tx
    );

    wire rst;

    assign led = usb_rx ? 8'hAA : 8'h55;
    assign usb_tx = usb_rx;
endmodule
