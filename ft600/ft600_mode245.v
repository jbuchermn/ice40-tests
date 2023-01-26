/////////////////////////////////////////////
module ft600_mode245 #(
    parameter RX_BUF_WIDTH = 4,
    parameter TX_BUF_WIDTH = 4
)(
    input rst,
    input clk,

    /* tx_en on posedge clk => append tx_input to FIFO */
    input tx_en,
    input [7:0] tx_in,
    output reg tx_full,

    /* rx_en on negedge clk => next posedge clk next value */
    input rx_en,
    output reg [7:0] rx_out,
    output reg rx_empty,

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

reg [7:0] rx_buf [0:(1<<RX_BUF_WIDTH)-1];
reg [7:0] tx_buf [0:(1<<TX_BUF_WIDTH)-1];

reg [TX_BUF_WIDTH-1:0] tx_read_addr;
reg [TX_BUF_WIDTH-1:0] tx_write_addr;
wire [TX_BUF_WIDTH-1:0] n_tx_read_addr;
assign n_tx_read_addr = tx_read_addr + 1;

wire [TX_BUF_WIDTH-1:0] n_tx_write_addr;
assign n_tx_write_addr = tx_write_addr + 1;

reg [RX_BUF_WIDTH-1:0] rx_read_addr;
reg [RX_BUF_WIDTH-1:0] rx_write_addr;

initial begin
    tx_full = 0;
    tx_read_addr = 0;
    tx_write_addr = 0;

    rx_out = 0;
    rx_empty = 0;
    rx_read_addr = 0;
    rx_write_addr = 0;
end


reg [15: 0] _ft_data;
reg [1:0] _ft_be;

assign ft_data = ft_oe ? _ft_data : 16'hz;
assign ft_be = ft_oe ? _ft_be : 16'hz;

parameter S_IDLE = 2'b00;
parameter S_READING = 2'b01;
parameter S_WRITING = 2'b10;

reg [1:0] state = 0;
reg [1:0] tx_pending = 0;

initial begin
    _ft_data = 16'hz;
    _ft_be = 2'hz;

    ft_oe = 1;
    ft_rd = 1;
    ft_wr = 1;

    state = S_IDLE;
    tx_pending = 0;
end

/////////////////////////////////////
// Clock domain FPGA
always@(posedge clk) begin
    if(rst) begin
        tx_full = 0;
        tx_read_addr = 0;
        tx_write_addr = 0;

    end else begin
        if(tx_en) begin
            if(~tx_full & n_tx_write_addr != tx_read_addr) begin
                tx_buf[tx_write_addr] <= tx_in;
                tx_write_addr <= n_tx_write_addr;
            end
        end
        tx_full <= n_tx_write_addr == tx_read_addr;
    end
end

always@(negedge clk) begin
    if(rst) begin
        rx_out = 0;
        rx_empty = 0;
        rx_read_addr = 0;
        rx_write_addr = 0;

    end else begin
        if(rx_en) begin
            if(rx_write_addr != rx_read_addr) begin
                rx_out <= rx_buf[rx_read_addr];
                rx_read_addr <= rx_read_addr + 1;
                rx_empty <= 0;
            end else begin
                rx_empty <= 1;
            end
        end
    end

end

// TODO: Domain crossing


/////////////////////////////////////
// Clock domain FT600
always@(negedge ft_clk) begin
    if(rst) begin
        _ft_data <= 16'hz;
        _ft_be <= 2'hz;

        tx_pending <= 0;

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
            tx_pending <= 0;
            if(tx_read_addr != tx_write_addr) begin
                ft_rd <= 1;
                if(~ft_oe) begin
                    ft_oe <= 1;
                    ft_wr <= 1;
                end else begin
                    if (n_tx_read_addr == tx_write_addr) begin
                        _ft_data[7:0] <= tx_buf[tx_read_addr];

                        _ft_be <= 2'b01;
                        ft_wr <= 0;

                        tx_pending <= 1;

                    end else begin
                        _ft_data[7:0] <= tx_buf[tx_read_addr];
                        _ft_data[15:8] <= tx_buf[n_tx_read_addr];

                        _ft_be <= 2'b11;
                        ft_wr <= 0;

                        tx_pending <= 2;
                    end
                end
            end
        end

        if(tx_read_addr == tx_write_addr) ft_wr <= 1;
    end
end

always@(posedge ft_clk) begin
    if(rst) begin
        state <= S_IDLE;

    end else begin
        if(~ft_rxf) begin
            state <= S_READING;

            if(~ft_oe & ~ft_rd) begin
                if(ft_be == 2'b11) begin
                    rx_buf[rx_write_addr] <= ft_data[15:8];
                    rx_buf[rx_write_addr+1] <= ft_data[7:0];

                    rx_write_addr <= rx_write_addr + 2;
                end else if(ft_be == 2'b01) begin
                    rx_buf[rx_write_addr] <= ft_data[15:8];

                    rx_write_addr <= rx_write_addr + 1;
                end else if(ft_be == 2'b10) begin
                    rx_buf[rx_write_addr] <= ft_data[7:0];

                    rx_write_addr <= rx_write_addr + 1;
                end
            end
        end else if(~ft_txe) begin
            state <= S_WRITING;
            tx_read_addr <= tx_read_addr + tx_pending;
        end else begin
            state <= S_IDLE;
        end
    end
end

endmodule
