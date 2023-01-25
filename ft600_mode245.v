/////////////////////////////////////////////
module ft600_mode245 #(
    parameter RX_BUFFER = 16,
    parameter TX_BUFFER = 16,

    parameter RX_BUFFER_WIDTH = $clog2(RX_BUFFER),
    parameter TX_BUFFER_WIDTH = $clog2(TX_BUFFER)
)(
    input rst,
    input clk,

    output reg [8*RX_BUFFER-1:0] rx_buf,
    output reg [RX_BUFFER_WIDTH-1:0] rx_buf_written,

    input [8*TX_BUFFER-1:0] tx_buf,
    input [TX_BUFFER_WIDTH-1:0] tx_buf_send,
    output reg [TX_BUFFER_WIDTH-1:0] tx_buf_sent,

    input ft_clk,
    inout [15: 0] ft_data,
    inout [1:0] ft_be,
    input ft_txe,
    input ft_rxf,
    output reg ft_oe,
    output reg ft_rd,
    output reg ft_wr
);

reg [RX_BUFFER_WIDTH-1:0] _rx_buf_written;
reg [TX_BUFFER_WIDTH-1:0] _tx_buf_send;
reg [TX_BUFFER_WIDTH-1:0] _tx_buf_sent;

reg [15: 0] _ft_data;
reg [1:0] _ft_be;

initial begin
    rx_buf = 0;

    _rx_buf_written = 0;
    rx_buf_written = 0;

    _tx_buf_send = 0;
    _tx_buf_sent = 0;
    tx_buf_sent = 0;

    _ft_data = 16'hz;
    _ft_be = 2'hz;

    ft_oe = 1;
    ft_rd = 1;
    ft_wr = 1;
end

assign ft_data = ft_oe ? _ft_data : 16'hz;
assign ft_be = ft_oe ? _ft_be : 16'hz;

always@(posedge clk) begin
    if(rst) begin
        rx_buf_written <= 0;
        tx_buf_sent <= 0;
        _tx_buf_send <= 0;
    end else begin
        rx_buf_written <= _rx_buf_written;
        tx_buf_sent <= _tx_buf_sent;
        _tx_buf_send <= tx_buf_send;
    end
end

// TODO: Set TX values on negedge (see pictures from FTDI)

always@(posedge ft_clk) begin

    if(rst) begin
        rx_buf <= 0;

        _rx_buf_written <= 0;
        _tx_buf_sent <= 0;

        _ft_data <= 16'hz;
        _ft_be <= 2'hz;

        ft_oe <= 1;
        ft_rd <= 1;
        ft_wr <= 1;

    end else if(~ft_rxf) begin
        ft_wr <= 1;
        if(ft_oe) begin
            ft_oe <= 0;
            ft_rd <= 1;
        end else if(ft_rd) ft_rd <= 0;
        else begin
            if(ft_be == 2'b11) begin
                rx_buf[_rx_buf_written*8 +:8] <= ft_data[15:8];
                rx_buf[((_rx_buf_written+1)%RX_BUFFER)*8 +:8] <= ft_data[7:0];

                _rx_buf_written <= (_rx_buf_written + 2)%RX_BUFFER;
            end else if(ft_be == 2'b01) begin
                rx_buf[_rx_buf_written*8 +:8] <= ft_data[15:8];

                _rx_buf_written <= (_rx_buf_written + 1)%RX_BUFFER;
            end else if(ft_be == 2'b10) begin
                rx_buf[_rx_buf_written*8 +:8] <= ft_data[7:0];

                _rx_buf_written <= (_rx_buf_written + 1)%RX_BUFFER;
            end
        end
    end else if(~ft_txe) begin
        if(_tx_buf_sent != _tx_buf_send) begin
            ft_rd <= 1;
            if(~ft_oe) begin
                ft_oe <= 1;
                ft_wr <= 1;
            end else begin
                if ((_tx_buf_sent + 1)%TX_BUFFER == _tx_buf_send) begin
                    _ft_data[7:0] <= tx_buf[_tx_buf_sent*8 +:8];

                    _ft_be <= 2'b01;
                    ft_wr <= 0;

                    _tx_buf_sent <= (_tx_buf_sent + 1)%TX_BUFFER;

                end else begin
                    _ft_data[7:0] <= tx_buf[_tx_buf_sent*8 +:8];
                    _ft_data[15:8] <= tx_buf[((_tx_buf_sent+1)%TX_BUFFER)*8 +:8];

                    _ft_be <= 2'b11;
                    ft_wr <= 0;

                    _tx_buf_sent <= (_tx_buf_sent + 2)%TX_BUFFER;
                end
            end
        end

    end else begin
        ft_oe <= 1;
        ft_rd <= 1;
        ft_wr <= 1;

    end

    if(_tx_buf_sent == _tx_buf_send) ft_wr <= 1;
end

endmodule
