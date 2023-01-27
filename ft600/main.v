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

parameter RX_BUF_WIDTH = 1; // 2^8 * 16bit = 4096bit
parameter TX_BUF_WIDTH = 4; // 2^8 * 16bit = 4096bit


wire tx_en;
wire [15:0] tx_in; 
wire tx_full;

reg rx_en;
wire [15:0] rx_out;
wire rx_empty;

initial begin
    rx_en = 0;
end

count_feeder feed(
    rst,
    clk,
    tx_en,
    tx_in,
    tx_full
);

assign led[0] = tx_full;
assign led[1] = tx_en;

ft600_mode245 #(RX_BUF_WIDTH, TX_BUF_WIDTH) ft600(
    rst,
    clk,

    tx_en,
    tx_in,
    tx_full,

    rx_en,
    rx_out,
    rx_empty,

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

    output reg en,
    output reg [15:0] out,
    input full
);

reg [7:0] val;
reg [3:0] counter;

initial begin
    val = 0;
    counter = 0;
    en = 0;
end

// always@(posedge clk) begin
//     if(rst) begin
//         val <= 0;
//         out <= 0;
//         counter <= 0;
//         en <= 0;
//     end else begin
//         if(~full) begin
//             en <= 0;
//             counter <= counter + 1;
//
//             if (counter == {4{1'b1}}) begin
//                 out <= ((val+1)%256 << 8) | val;
//                 val <= val + 2;
//                 en <= 1;
//             end
//         end
//     end
// end

always@(posedge clk) begin
    if(rst) begin
        val <= 0;
        out <= 0;
        counter <= 0;
        en <= 0;
    end else begin
        en <= 1;
        if(~full) begin
            out <= ((val+1)%256 << 8) | val;
            val <= val + 2;
        end
    end
end

endmodule

