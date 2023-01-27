/////////////////////////////////////////////
module ft600_mode245 #(
    parameter RX_BUF_WIDTH = 4,
    parameter TX_BUF_WIDTH = 4
)(
    input rst,
    input clk,

    /* TX */
    input tx_en,
    input [15:0] tx_in,
    output tx_full,

    /* RX */
    input rx_en,
    output reg [15:0] rx_out,
    output rx_empty,

    /* FT600 pins */
    input ft_clk,
    inout [15: 0] ft_data,
    inout [1:0] ft_be,
    input ft_txe,
    input ft_rxf,
    output reg ft_oe,
    output reg ft_rd,
    output reg ft_wr
);

/* FIFO */
reg tx_r_en;
wire [15:0] tx_r_out;
wire tx_r_empty;

async_fifo #(16, TX_BUF_WIDTH) tx_fifo(
    rst,

    clk,
    tx_en,
    tx_in,
    tx_full,

    /* TX happens on negedge ft_clk */
    ~ft_clk,
    tx_r_en,
    tx_r_out,
    tx_r_empty
);

reg rx_w_en;
wire rx_w_full;

async_fifo #(16, RX_BUF_WIDTH) rx_fifo(
    rst,

    ft_clk,
    rx_w_en,
    ft_data,
    rx_w_full,

    /* RX happens on posedge ft_clk */
    clk,
    rx_en,
    rx_out,
    rx_empty
);

/* Piping */
assign ft_data = ft_oe ? tx_r_out : 16'hz;
assign ft_be = ft_oe ? 2'b11 : 2'hz; // We only support even-sized packets

/* State */
parameter S_IDLE = 2'b00;
parameter S_READING = 2'b01;
parameter S_WRITING = 2'b10;

reg [1:0] state;

initial begin
    rx_w_en = 0;
    tx_r_en = 0;

    ft_oe = 1;
    ft_rd = 1;
    ft_wr = 1;

    state = S_IDLE;
end

/* Clock domain FT600 */
always@(negedge ft_clk) begin
    if(rst) begin
        tx_r_en = 0;

        ft_oe = 1;
        ft_rd = 1;
        ft_wr = 1;

    end else begin
        tx_r_en <= 0;

        if(state == S_IDLE) begin
            ft_oe <= 1;
            ft_rd <= 1;
            ft_wr <= 1;

        end else if(state == S_READING) begin
            ft_oe <= 0;
            ft_wr <= 1;

        end else if(state == S_WRITING) begin
            ft_oe <= 1;
            ft_rd <= 1;

            tx_r_en <= ~tx_r_empty;
            ft_wr <= ~(~tx_r_empty & ft_oe);
        end
    end
end

always@(posedge ft_clk) begin
    if(rst) begin
        state = S_IDLE;
        rx_w_en = 0;

    end else begin
        if(~ft_rxf) begin
            state <= S_READING;

            rx_w_en <= ~rx_w_full;
            ft_rd <= ~(~rx_w_full & ~ft_oe);
        end else if(~ft_txe) begin
            state <= S_WRITING;
        end else begin
            state <= S_IDLE;
        end
    end
end

endmodule
