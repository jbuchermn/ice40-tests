`timescale 1ns / 1ps

/////////////////////////////////////////////
module ft600_mode245_rx_tb();

parameter RX_BUFFER = 16;
parameter TX_BUFFER = 16;

parameter RX_BUFFER_WIDTH = $clog2(RX_BUFFER);
parameter TX_BUFFER_WIDTH = $clog2(TX_BUFFER);

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

wire [8*RX_BUFFER-1:0] rx_buf;
wire [3:0] rx_buf_written;
reg [8*TX_BUFFER-1:0] tx_buf;
reg [3:0] tx_buf_send;
wire [3:0] tx_buf_sent;

wire [15:0] _ft_data;
assign _ft_data = ft_data;

wire [1:0] _ft_be;
assign _ft_be = ft_be;

ft600_mode245 ft600(
    rst,
    clk,

    rx_buf,
    rx_buf_written,

    tx_buf,
    tx_buf_send,
    tx_buf_sent,

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
    $dumpvars(0, ft600);
    $dumpvars(0, rx_buf);

    ft_txe = 1'b1;
    ft_rxf = 1'b1;
    ft_data = 16'h0123;
    ft_be = 2'b11;

    #20000;
    ft_rxf = 1'b0;

    #30
    ft_data = 16'h4567;

    #10
    ft_data = 16'h89AB;

    #10
    ft_data = 16'hCDEF;

    #10
    ft_data = 16'hFFEE;

    #10
    ft_data = 16'hDDCC;

    #10
    ft_data = 16'hBBAA;

    #10
    ft_data = 16'h9988;

    #10
    ft_data = 16'h7766;

    #10
    ft_data = 16'h55;
    ft_be = 2'b10;

    #10;
    ft_rxf = 1'b1;

    #20000;
    $finish;
end
endmodule



