`timescale 1ns / 1ps

/////////////////////////////////////////////
module async_fifo_tb();

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 3;

reg rst;
reg w_clk;
reg r_clk;

initial begin
    w_clk = 1'b0;
    #2 // Phase
    forever #5 w_clk = ~w_clk; // 100MHz
end

initial begin
    r_clk = 1'b0;
    // #2 // Phase
    forever #5 r_clk = ~r_clk; // 100MHz
end

initial begin
    rst = 1'b1;
    #1000
    rst = 1'b0;
end

wire w_en;
wire [DATA_WIDTH-1:0] w_in;
wire w_full;

reg r_en;
wire [DATA_WIDTH-1:0] r_out;
wire r_empty;

async_fifo #(DATA_WIDTH, ADDR_WIDTH) fifo(
    rst,

    w_clk,
    w_en,
    w_in,
    w_full,

    r_clk,
    r_en,
    r_out,
    r_empty
);

reg [7:0] dummy;

count_feeder feed(
    rst,
    w_clk,
    w_en,
    w_in,
    w_full,

    dummy
);

initial begin
    $dumpfile("async_fifo_wave.vcd");
    $dumpvars(0, rst);
    $dumpvars(0, w_clk);
    $dumpvars(0, w_en);
    $dumpvars(0, w_in);
    $dumpvars(0, w_full);
    $dumpvars(0, r_clk);
    $dumpvars(0, r_en);
    $dumpvars(0, r_out);
    $dumpvars(0, r_empty);

    $dumpvars(0, fifo);
    $dumpvars(0, fifo.buffer[0]);
    $dumpvars(0, fifo.buffer[1]);
    $dumpvars(0, fifo.buffer[2]);
    $dumpvars(0, fifo.buffer[3]);

    r_en = 1'b0;


    #10000;
    r_en = 1;
    #15000;
    r_en = 0;
    #20000;
    r_en = 1;

    #100000;

    $finish;
end
endmodule
