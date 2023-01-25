`timescale 1ns / 1ps

/////////////////////////////////////////////
module ft600_mode245_tx_tb();

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

wire [7:0] rx_buf [0:15];
wire [3:0] rx_buf_written;
wire [3:0] tx_buf_sent;

wire [3:0] tx_buf_send;
wire [7:0] tx_buf [0:15];

dummy_feeder feeder(
    rst,
    clk,

    tx_buf,
    tx_buf_send
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

    #100000;
    $finish;
end
endmodule


/////////////////////////////////////////////
module dummy_feeder #(
    parameter TX_BUFFER = 16,
    parameter TX_BUFFER_WIDTH = $clog2(TX_BUFFER),

    parameter CLOCK_RATE = 100000000,
    parameter FREQ = 50000000
)(
    input rst,
    input clk,

    output reg [7: 0] tx_buf [0:TX_BUFFER-1],
    output reg [TX_BUFFER_WIDTH-1:0] tx_buf_send
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
    end else begin
        if(counter == RATE-1) begin
            counter <= 0;
            tx_buf[tx_buf_send] <= value;
            value <= value + 1;
            tx_buf_send <= (tx_buf_send + 1)%TX_BUFFER;
        end else
            counter <= counter+1;
    end
end

endmodule
