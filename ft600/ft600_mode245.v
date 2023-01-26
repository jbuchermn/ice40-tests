/////////////////////////////////////////////
module ft600_mode245 #(
    parameter RX_BUF_WIDTH = 4,
    parameter TX_BUF_WIDTH = 4
)(
    input rst,
    input clk,

    output reg [(8<<RX_BUF_WIDTH)-1:0] rx_buf,
    output reg [RX_BUF_WIDTH-1:0] rx_buf_written,

    input [(8<<TX_BUF_WIDTH)-1:0] tx_buf,
    input [TX_BUF_WIDTH-1:0] tx_buf_send,
    output reg [TX_BUF_WIDTH-1:0] tx_buf_sent,

    input ft_clk,
    inout [15: 0] ft_data,
    inout [1:0] ft_be,
    input ft_txe,
    input ft_rxf,
    output reg ft_oe,
    output reg ft_rd,
    output reg ft_wr
);

// TODO: Not a proper synchronisation
///////////////////////////////
reg [RX_BUF_WIDTH-1:0] _rx_buf_written;
reg [TX_BUF_WIDTH-1:0] _tx_buf_send;
reg [TX_BUF_WIDTH-1:0] _tx_buf_sent;

initial begin
    _rx_buf_written = 0;
    rx_buf_written = 0;

    _tx_buf_send = 0;
    _tx_buf_sent = 0;
    tx_buf_sent = 0;
end

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
///////////////////////////////

reg [15: 0] _ft_data;
reg [1:0] _ft_be;

assign ft_data = ft_oe ? _ft_data : 16'hz;
assign ft_be = ft_oe ? _ft_be : 16'hz;

parameter S_IDLE = 2'b00;
parameter S_READING = 2'b01;
parameter S_WRITING = 2'b10;

reg [1:0] state = 0;
reg [1:0] writing_n = 0;

initial begin
    rx_buf = 0;

    _ft_data = 16'hz;
    _ft_be = 2'hz;

    ft_oe = 1;
    ft_rd = 1;
    ft_wr = 1;

    state = S_IDLE;
    writing_n = 0;
end


always@(negedge ft_clk) begin
    if(rst) begin
        _ft_data <= 16'hz;
        _ft_be <= 2'hz;

        writing_n <= 0;

        ft_oe <= 1;
        ft_rd <= 1;
        ft_wr <= 1;
    end else begin
        if(state == S_IDLE) begin
            ft_oe <= 1;
            ft_rd <= 1;
            ft_wr <= 1;

        end else if(state == S_READING) begin
            ft_wr <= 1;
            if(ft_oe) begin
                ft_oe <= 0;
                ft_rd <= 1;
            end else if(ft_rd) begin
                ft_rd <= 0;
            end

        end else if(state == S_WRITING) begin
            if(_tx_buf_sent != _tx_buf_send) begin
                ft_rd <= 1;
                if(~ft_oe) begin
                    ft_oe <= 1;
                    ft_wr <= 1;
                end else begin
                    if (_tx_buf_sent + 1 == _tx_buf_send) begin
                        _ft_data[7:0] <= tx_buf[_tx_buf_sent*8 +:8];

                        _ft_be <= 2'b01;
                        ft_wr <= 0;

                        writing_n <= 1;

                    end else begin
                        _ft_data[7:0] <= tx_buf[_tx_buf_sent*8 +:8];
                        _ft_data[15:8] <= tx_buf[(_tx_buf_sent+1)*8 +:8];

                        _ft_be <= 2'b11;
                        ft_wr <= 0;

                        writing_n <= 2;
                    end
                end
            end
        end

        if(_tx_buf_sent == _tx_buf_send) ft_wr <= 1;
    end
end

always@(posedge ft_clk) begin
    if(rst) begin
        rx_buf <= 0;

        _rx_buf_written <= 0;
        _tx_buf_sent <= 0;

        state <= S_IDLE;

    end else begin
        if(~ft_rxf) begin
            state <= S_READING;

            if(~ft_oe & ~ft_rd) begin
                if(ft_be == 2'b11) begin
                    rx_buf[_rx_buf_written*8 +:8] <= ft_data[15:8];
                    rx_buf[(_rx_buf_written+1)*8 +:8] <= ft_data[7:0];

                    _rx_buf_written <= _rx_buf_written + 2;
                end else if(ft_be == 2'b01) begin
                    rx_buf[_rx_buf_written*8 +:8] <= ft_data[15:8];

                    _rx_buf_written <= _rx_buf_written + 1;
                end else if(ft_be == 2'b10) begin
                    rx_buf[_rx_buf_written*8 +:8] <= ft_data[7:0];

                    _rx_buf_written <= _rx_buf_written + 1;
                end
            end
        end else if(~ft_txe) begin
            state <= S_WRITING;
            _tx_buf_sent <= _tx_buf_sent + writing_n;
        end else begin
            state <= S_IDLE;
        end
    end
end

endmodule
