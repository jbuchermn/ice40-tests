`timescale 1ns / 1ps

/////////////////////////////////////////////
module ft600_mode245_rx_tb();

parameter RX_BUF_WIDTH = 4;
parameter TX_BUF_WIDTH = 4;

reg clk;
reg rst;

reg ft_clk;
reg [15:0] ft_data;
reg [1:0] ft_be;
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
    rst = 1'b1;
    #1000
    rst = 1'b0;
end

wire [15:0] _ft_data;
assign _ft_data = ft_data;

wire [1:0] _ft_be;
assign _ft_be = ft_be;

wire tx_en;
wire [15:0] tx_in;
wire tx_full;

wire rx_en;
wire [15:0] rx_out;
wire rx_empty;

wire [7:0] led;

count_reader read(
    rst,
    clk,
    rx_en,
    rx_out,
    rx_empty,

    led
);

ft600_mode245 ft600(
    rst,
    clk,

    tx_en,
    tx_in,
    tx_full,

    rx_en,
    rx_out,
    rx_empty,

    ft_clk,
    _ft_data,
    _ft_be,
    ft_txe,
    ft_rxf,
    ft_oe,
    ft_rd,
    ft_wr
);

initial begin
    $dumpfile("ft600_mode245_rx_wave.vcd");
    $dumpvars(0, clk);
    $dumpvars(0, rst);
    $dumpvars(0, ft_clk);
    $dumpvars(0, ft_data);
    $dumpvars(0, ft_be);
    $dumpvars(0, ft_txe);
    $dumpvars(0, ft_rxf);
    $dumpvars(0, ft_oe);
    $dumpvars(0, ft_rd);
    $dumpvars(0, ft_wr);
    $dumpvars(0, tx_en);
    $dumpvars(0, tx_in);
    $dumpvars(0, tx_full);
    $dumpvars(0, rx_en);
    $dumpvars(0, rx_out);
    $dumpvars(0, rx_empty);
    $dumpvars(0, ft600);
    $dumpvars(0, read);

    ft_txe = 1'b1;
    ft_rxf = 1'b1;
    ft_data = 16'h0123;
    ft_be = 2'b11;

    #1002;
    ft_rxf = 1'b0;

    #30
    ft_data = 16'h4567;

    #1000;
    ft_rxf = 1'b1;

    #20000;
    $finish;
end
endmodule



