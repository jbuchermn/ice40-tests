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

parameter RX_BUF_WIDTH = 8; // 2^8 * 16bit = 4096bit
parameter TX_BUF_WIDTH = 8; // 2^8 * 16bit = 4096bit


wire tx_en = 1;
wire rx_en = 1;
wire [15:0] tx_in = 16'hFEDC;
wire [15:0] rx_out;

assign led[2] = ~^rx_out;


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


/////////////////////////////////////////////
module count_feeder(
    input rst,
    input clk,

    output reg [15:0] out,
    input full
);

reg [7:0] val;

initial begin
    val = 0;
end

always@(posedge clk) begin
    if(rst) begin
        val <= 0;
        out <= 0;
    end else begin
        if(~full) begin
            out <= (val << 8) | ((val + 1)%256);
            val <= val + 2;
        end
    end
end

endmodule

