/////////////////////////////////////////////
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


parameter S_IDLE       = 3'b000;
parameter S_DATA_BITS  = 3'b010;
parameter S_PARITY_BIT = 3'b011;
parameter S_STOP_BIT   = 3'b100;

reg [2:0] state = S_IDLE;

wire search_en;
assign search_en = (state == S_IDLE) ? 1 : 0;

wire clk_baud;
reg clk_baud_last;
wire bitval;

ovr_sync #(CLOCK_RATE, BAUD_RATE, OVR) ovr_sync (rst, clk, search_en, rx, clk_baud, bitval);

reg [2:0] at_bit = 0;

always@(posedge clk)
    if(rst) begin
        ready = 0;
        error = 0;
        val = 0;
        state = S_IDLE;
    end else begin
        clk_baud_last <= clk_baud;
        if(clk_baud & ~clk_baud_last) begin
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
                        state <= PARITY ? S_PARITY_BIT : S_STOP_BIT;
                    end
                end
                S_PARITY_BIT: begin
                    state <= S_STOP_BIT;
                    error <= ~(bitval ^ (~^val));
                end
                S_STOP_BIT: begin
                    state <= S_IDLE;
                    error <= (error | ~bitval);
                    ready <= ~(error | ~bitval);
                end
            endcase
        end
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


