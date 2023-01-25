`timescale 1ns / 1ps

module uart_rx_tb();

reg clk;
reg rst;

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
end

initial begin
    rst = 1'b1;
    #1000
    rst = 1'b0;
end

reg rx;

wire ready;
wire error;
wire [7:0] val;

uart_rx #(100000000, 115200) uart(rst, clk, rx, ready, error, val);


integer i;
initial begin
    $dumpfile("uart_rx_wave.vcd");
    $dumpvars(0, clk);
    $dumpvars(0, rst);
    $dumpvars(0, rx);
    $dumpvars(0, ready);
    $dumpvars(0, error);
    $dumpvars(0, val);
    $dumpvars(0, uart);

    rx = 1'b1;
    #20000;

    for (i=0; i<3; i=i+1) begin
        rx = 1'b0; // Start bit
        #8680;
        rx = 1'b1; // Data bits
        #8680;
        rx = 1'b0;
        #8680;
        rx = 1'b1;
        #8680;
        rx = 1'b0;
        #8680;
        rx = 1'b1;
        #8680;
        rx = 1'b0;
        #8680;
        rx = 1'b0;
        #8680;
        rx = 1'b1;
        #8680;
        rx = 1'b0; // Parity
        #8680;
        rx = 1'b1; // Stop
        #20000;
    end

    $finish;
end
endmodule
