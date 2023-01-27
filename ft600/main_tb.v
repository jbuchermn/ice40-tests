`timescale 1ns / 1ps

/////////////////////////////////////////////
module main_tb();

parameter RX_BUF_WIDTH = 4;
parameter TX_BUF_WIDTH = 4;

reg clk;
reg rst_n;

reg ft_clk;
wire [15:0] ft_data;
wire [1:0] ft_be;
reg ft_txe;
reg ft_rxf;
wire ft_oe;
wire ft_rd;
wire ft_wr;


initial begin
    clk = 1'b0;
    // #2 // Phase
    forever #5 clk = ~clk; // 100MHz
end

initial begin
    ft_clk = 1'b0;
    #2 // Phase
    forever #5 ft_clk = ~ft_clk; // 100MHz
end

initial begin
    rst_n = 1'b0;
    #1000
    rst_n = 1'b1;
end

wire [7:0] led;

main m(
    clk,
    rst_n,

    led,

    ft_clk,
    ft_data,
    ft_be,
    ft_txe,
    ft_rxf,
    ft_oe,
    ft_rd,
    ft_wr
);

initial begin
    $dumpfile("main_wave.vcd");
    $dumpvars(0, clk);
    $dumpvars(0, rst_n);
    $dumpvars(0, led);
    $dumpvars(0, ft_clk);
    $dumpvars(0, ft_data);
    $dumpvars(0, ft_be);
    $dumpvars(0, ft_txe);
    $dumpvars(0, ft_rxf);
    $dumpvars(0, ft_oe);
    $dumpvars(0, ft_rd);
    $dumpvars(0, ft_wr);
    $dumpvars(0, m);

    ft_txe = 1'b1;
    ft_rxf = 1'b1;

    #10000;
    ft_txe = 1'b0;

    #20000;
    ft_txe = 1'b1;

    #20000;

    ft_rxf = 1'b0;


    $finish;
end
endmodule



