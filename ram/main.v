/////////////////////////////////////////////
module main #(
    parameter CLOCK_RATE = 100000000
)(
    input clk,
    input rst_n,

    output [7:0] led,

);

parameter SIZE = 4;

reg [7:0] ram [0:SIZE];

reg [7:0] val = 0;
reg [$clog2(SIZE)-1:0] i = 0;

always@(posedge clk) begin
    ram[i] <= val;
    val <= val + 1;
    i <= i + 1;
end


reg [$clog2(SIZE)-1:0] j = 0;
always@(posedge clk) begin
    led <= ram[j];
    j <= j + 3;
end



endmodule
