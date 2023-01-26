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
wire stalled;

parameter RX_BUF_WIDTH = 8;
parameter TX_BUF_WIDTH = 8;

wire [(8<<RX_BUF_WIDTH)-1:0] rx_buf;
wire [RX_BUF_WIDTH-1:0] rx_buf_written;

wire [(8<<TX_BUF_WIDTH)-1:0] tx_buf;
wire [TX_BUF_WIDTH-1:0] tx_buf_send;
wire [TX_BUF_WIDTH-1:0] tx_buf_sent;

dummy_feeder #(TX_BUF_WIDTH) feeder(
    rst,
    clk,

    tx_buf,
    tx_buf_send,
    tx_buf_sent,

    stalled
);


ft600_mode245 #(RX_BUF_WIDTH, TX_BUF_WIDTH) ft600(
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

reg [26:0] counter;
reg [RX_BUF_WIDTH-1:0] last_rx_buf_written = 0;
always@(posedge clk) begin
    if(rx_buf_written != last_rx_buf_written) counter <= counter + 1;
    last_rx_buf_written <= rx_buf_written;
end
// assign led = counter[26:19];
assign led = counter[7:0];


endmodule


/////////////////////////////////////////////
module dummy_feeder #(
    parameter TX_BUF_WIDTH = 4,

    parameter CLOCK_RATE = 100000000,
    parameter FREQ = 1000000
)(
    input rst,
    input clk,

    output reg [(8<<TX_BUF_WIDTH)-1:0] tx_buf,
    output reg [TX_BUF_WIDTH-1:0] tx_buf_send,
    input [TX_BUF_WIDTH-1:0] tx_buf_sent,

    output reg stalled
);

parameter RATE = CLOCK_RATE / FREQ;
parameter WIDTH = $clog2(RATE);

reg [WIDTH:0] counter = 0;
reg [7:0] value;

initial begin
    tx_buf_send = 0;
    counter = 0;
    value = 0;
end


always@(posedge clk) begin
    if(rst) begin
        tx_buf_send <= 0;
        counter <= 0;
        value <= 0;
    end else begin
        if(counter == RATE-1) begin
            counter <= 0;
            if(tx_buf_send + 1 == tx_buf_sent) begin
                stalled <= 1;
            end else begin
                stalled <= 0;

                tx_buf[tx_buf_send*8+:8] <= value;
                value <= value + 1;
                tx_buf_send <= tx_buf_send + 1;
            end
        end else
            counter <= counter+1;
    end
end

endmodule
