/////////////////////////////////////////////
// `define INCLUDE_UART_RX_PARITY
// `define INCLUDE_UART_RX_OVERSAMPLE

module uart_rx #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 115200,
    parameter OVR = 16,
    parameter PARITY = 1
)(
    input rst,
    input clk,
    input rx,

    output reg ready,
    output reg error,
    output reg [7:0] val
);

initial begin
    ready = 0;
    error = 0;
    val = 0;
end


parameter S_IDLE       = 3'b00;
parameter S_DATA_BITS  = 3'b01;
parameter S_STOP_BIT   = 3'b10;
`ifdef INCLUDE_UART_RX_PARITY
parameter S_PARITY_BIT = 3'b11;
`endif

reg [1:0] state = S_IDLE;

wire search_en;
assign search_en = (state == S_IDLE) ? 1 : 0;

wire clk_baud;
wire bitval;

`ifdef INCLUDE_UART_RX_OVERSAMPLE
ovr_sync #(CLOCK_RATE, BAUD_RATE, OVR) sync (rst, clk, search_en, rx, clk_baud, bitval);
`else
simple_sync #(CLOCK_RATE, BAUD_RATE) sync (rst, clk, search_en, rx, clk_baud, bitval);
`endif

reg [2:0] at_bit = 0;

wire clk_en;
to_clk_en to_clk_en(rst, clk, clk_baud, clk_en);

always@(posedge clk)
    if(rst) begin
        ready <= 0;
        error <= 0;
        val <= 0;
        at_bit <= 0;
    end else if(clk_en) begin
        case(state)
            default:
                state <= S_IDLE;
            S_IDLE: begin
                state <= S_DATA_BITS;
                ready <= 0;
                error <= 0;
                val <= 0;
                at_bit <= 0;
            end
            S_DATA_BITS: begin
                state <= S_DATA_BITS;
                at_bit <= at_bit + 1;
                val <= (val >> 1) | (bitval << 7);
                if(at_bit == 7) begin
`ifdef INCLUDE_UART_RX_PARITY
                    state <= PARITY ? S_PARITY_BIT : S_STOP_BIT;
`else
                    state <= S_STOP_BIT;
`endif
                end
            end
`ifdef INCLUDE_UART_RX_PARITY
            S_PARITY_BIT: begin
                state <= S_STOP_BIT;
                error <= ~(bitval ^ (~^val));
            end
`endif
            S_STOP_BIT: begin
                state <= S_IDLE;
                error <= (error | ~bitval);
                ready <= ~(error | ~bitval);
            end
        endcase
    end

endmodule

/////////////////////////////////////////////
module ovr_sync #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 115200,
    parameter OVR = 8
) (
    input rst,
    input clk,

    input search_en,
    input rx,

    output reg clk_baud,
    output reg val
);

initial begin
    clk_baud = 0;
    val = 0;
end

parameter RATE = CLOCK_RATE / (BAUD_RATE * OVR);
parameter WIDTH = $clog2(RATE);
parameter WIDTH_OVR = $clog2(OVR);

reg [WIDTH:0] counter = 0;
reg [OVR-1: 0] last_vals = {OVR{1'b1}};

reg [WIDTH_OVR:0] counter2 = 0;

integer i;
reg [WIDTH_OVR:0] last_vals_sum;
always@(last_vals) begin
    last_vals_sum = 0;
    for(i=0; i<OVR; i=i+1)
        last_vals_sum = last_vals_sum + last_vals[i];
end

wire cur;
assign cur = last_vals_sum < (OVR/2) ? 0 : 1;


always@(posedge clk) begin
    if(rst) begin
        counter <= 0;
        last_vals <= {OVR{1'b1}};
        counter2 <= 0;

        clk_baud <= 0;
        val <= 0;

    end else begin
        counter <= counter + 1;
        if(counter >= RATE - 1) begin
            counter <= 0;
            last_vals <= (last_vals << 1) | rx;

            if(search_en) begin
                if(~last_vals[OVR-1] & ~cur) begin
                    counter2 <= 0;
                    clk_baud <= 1;
                    val <= cur;
                end else begin
                    clk_baud <= 0;
                    val <= 0;
                end
            end else begin
                counter2 <= counter2 + 1;
                if(counter2 >= OVR - 1) begin
                    counter2 <= 0;
                    val <= cur;
                end
                clk_baud <= counter2 < (OVR/2) ? 1 : 0;
            end
        end
    end

end



endmodule


/////////////////////////////////////////////
module simple_sync #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 115200
) (
    input rst,
    input clk,

    input search_en,
    input rx,

    output reg clk_baud,
    output reg val
);

initial begin
    clk_baud = 1;
    val = 0;
end

parameter RATE = CLOCK_RATE / (BAUD_RATE * 2);
parameter WIDTH = $clog2(RATE);

reg [WIDTH:0] counter = 0;
reg started = 0;

always@(posedge clk) begin
    if(rst) begin
        counter <= 0;
        started <= 0;
        clk_baud <= 1;
        val <= 0;
    end else begin
        if(counter < RATE-1) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;

            val <= started ? rx : 0;
            clk_baud <= started ? ~clk_baud : 1;
        end

        if(started) begin
            if(search_en & clk_baud) begin
                started <= 0;
                clk_baud <= 1;
            end
        end else begin
            if(search_en & ~rx) begin
                started <= 1;
                clk_baud <= 0;
                counter <= 0;
            end
        end
    end
end


endmodule

////////////////////////////////////////////////
module to_clk_en(
    input rst,
    input clk,
    input clk_in,
    output reg clk_en
);

reg buffer;
always@(posedge clk) begin
    if(rst) begin
        buffer <= clk;
        clk_en <= 0;
    end else begin
        if(!buffer & clk_in) clk_en <= 1;
        else clk_en <= 0;
        buffer <= clk_in;
    end
end

endmodule
