`timescale 1ns / 1ps

/////////////////////////////////////////////
module ft600_mode245_tx_tb();

parameter RX_BUF_WIDTH = 4;
parameter TX_BUF_WIDTH = 4;

reg clk;
reg rst;

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
    #2 // Phase
    forever #5 clk = ~clk; // 100MHz
end

initial begin
    ft_clk = 1'b0;
    forever #5 ft_clk = ~ft_clk; // 100MHz
end

initial begin
    rst = 1'b1;
    #1000
    rst = 1'b0;
end

wire [(8<<RX_BUF_WIDTH)-1:0] rx_buf;
wire [3:0] rx_buf_written;
wire [3:0] tx_buf_sent;

wire [3:0] tx_buf_send;
wire [(8<<TX_BUF_WIDTH)-1:0] tx_buf;

wire stalled;

dummy_feeder feeder(
    rst,
    clk,

    tx_buf,
    tx_buf_send,
    tx_buf_sent,

    stalled
);



ft600_mode245 ft600(
    rst,
    clk,

    rx_buf,
    rx_buf_written,

    tx_buf,
    tx_buf_send,
    tx_buf_sent,

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
    $dumpfile("ft600_mode245_tx_wave.vcd");
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
    $dumpvars(0, tx_buf_sent);

    ft_txe = 1'b1;
    ft_rxf = 1'b1;

    #10000;
    ft_txe = 0;

    #32;
    ft_txe = 1;

    #100000;
    $finish;
end
endmodule
