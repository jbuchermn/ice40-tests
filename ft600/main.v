/////////////////////////////////////////////
module main(
    input clk,
    input rst_n,

    output [7:0] led,

    input ft_clk,
    inout [15:0] ft_data,
    inout [1:0] ft_be,
    input ft_txe,
    input ft_rxf,
    output ft_oe,
    output ft_rd,
    output ft_wr
);

wire rst;
assign rst = ~rst_n;

parameter RX_BUF_WIDTH = 8;
parameter TX_BUF_WIDTH = 8;


wire tx_en = 1;
wire rx_en = 1;
wire [7:0] tx_in = 8'hFE;
wire [7:0] rx_out;


ft600_mode245 #(RX_BUF_WIDTH, TX_BUF_WIDTH) ft600(
    rst,
    clk,

    tx_en,
    tx_in,
    led[0],

    rx_en,
    rx_out,
    led[1],

    ft_clk,
    ft_data,
    ft_be,
    ft_txe,
    ft_rxf,
    ft_oe,
    ft_rd,
    ft_wr
);


endmodule
