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


wire tx_en;
wire [15:0] tx_in; 
wire tx_full;

wire rx_en;
wire [15:0] rx_out;
wire rx_empty;

wire [7:0] dummy;

count_feeder feed(
    rst,
    clk,
    tx_en,
    tx_in,
    tx_full,

    dummy
);

count_reader read(
    rst,
    clk,
    rx_en,
    rx_out,
    rx_empty,

    led
);

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
    input full,

    output reg [7:0] status
);

reg [7:0] val;
reg [4:0] counter;

initial begin
    val = 0;
    en = 0;
    counter = 0;
end


always@(negedge clk) begin
    if(rst) begin
        val <= 0;
        out <= 0;
        en <= 0;
        counter <= 0;
        status <= 0;
    end else begin
        if(full) begin
            status <= 8'hF0;
        end else begin
            status <= 8'hEE;
        end
        // /* non saturated */
        // en <= 0;
        // if(~full) begin
        //     counter <= counter + 1;
        //     if(counter == 0) begin
        //         en <= 1;
        //         out <= (val << 8) | val;
        //         if(~full) begin
        //             val <= val + 1;
        //         end
        //     end
        // end

        /* saturated */
        if(~full) begin
            en <= 1;
            out <= (val << 8) | val;
            val <= val + 1;
        end else begin
            en <= 0;
        end
    end
end

endmodule

/////////////////////////////////////////////
module count_reader(
    input rst,
    input clk,

    output reg en,
    input [15:0] in,
    input empty,

    output reg [7:0] status
);

initial begin
    en = 1;
end

wire [7:0] first;
wire [7:0] second;
assign first = in[15:8];
assign second = in[7:0];
reg [7:0] value;

wire [7:0] n_first;
assign n_first = first + 1;

wire [7:0] n_value;
assign n_value = value + 1;

reg [23:0] errors;
reg [23:0] counter;

initial begin
    value = 0;

    errors = 0;
    counter = 0;
end


always@(posedge clk) begin
    if(rst) begin
        value <= 0;
        errors <= 0;
        counter <= 0;

        status <= 0;
    end else begin
        if(~empty) begin
            value <= second;
            if(first != n_value & second != n_first) errors <= errors + 2;
            else if((first != n_value) | (second != n_first)) errors <= errors + 1;

            counter <= counter + 2;

            // status <= counter[17:10]; //kB
            status <= errors[7:0];
        end
    end

end


endmodule
