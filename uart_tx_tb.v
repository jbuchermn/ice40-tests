`timescale 1ns / 1ps

module uart_tx_tb();

reg clk;
reg rst;

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
end

initial begin
    rst = 1'b1;
    #100
    rst = 1'b0;
end

reg [7:0] val;
reg start;

wire done;
wire tx;

uart_tx #(100000000, 115200, 0) uart(rst, clk, val, start & done, tx, done);


integer i;
initial begin
    $dumpfile("uart_tx_wave.vcd");
    $dumpvars(0, clk);
    $dumpvars(0, rst);
    $dumpvars(0, tx);
    $dumpvars(0, start);
    $dumpvars(0, done);
    $dumpvars(0, val);
    $dumpvars(0, uart);

    val = 8'h95;
    start = 1;
    #500000;
    $finish;
end
endmodule
