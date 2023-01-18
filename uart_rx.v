module uart_rx #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 115200,
    parameter OVR = 8,
    parameter OVR_LIMIT = 1
)(
    input rst_n,
    input clk,
    input rx,

    output reg ready,
    output reg error,
    output reg [7:0] val
);

parameter RATE = CLOCK_RATE / (BAUD_RATE * OVR);
parameter WIDTH = $clog2(RATE);
parameter OVR_WIDTH = $clog2(OVR);


parameter S_IDLE       = 3'b000;
parameter S_DATA_BITS  = 3'b010;
parameter S_PARITY_BIT = 3'b011;
parameter S_STOP_BIT   = 3'b100;


reg [WIDTH-1:0] counter = 0;
reg [OVR-1:0] cur_ovr = {OVR{1'b1}};
reg [OVR_WIDTH-1:0] sum_ovr = 0;
reg [OVR_WIDTH-1:0] counter_ovr = 0;

wire cur;
assign cur = sum_ovr < (OVR / 2) ? 1'b0 : 1'b1;

reg[OVR_WIDTH:0] cur_ovr_1;

integer i;
always@(cur_ovr) begin
    cur_ovr_1 = 0;
    for(i=0; i<OVR; i++)
        cur_ovr_1 = cur_ovr_1 + cur_ovr[i];
end


reg [2:0] state = S_IDLE;
reg [7:0] result = 0;
reg [2:0] result_idx = 0;


initial begin
    val = 8'h0;
    error = 1'b0;
    ready = 1'b0;
end


always @(posedge clk) begin
    counter <= counter + 1;

    if(counter == RATE[WIDTH-1:0]) begin
        counter <= 0;
        counter_ovr <= counter_ovr + 1;

        cur_ovr <= (cur_ovr << 1) | rx;

        sum_ovr <= sum_ovr + rx;
        if(counter_ovr == {OVR_WIDTH{1'b1}}) begin
            counter_ovr <= 0;
            sum_ovr <= 0;
        end

        case(state) 
            S_IDLE: begin
                if (cur_ovr_1 < OVR_LIMIT) begin
                    counter_ovr <= 0;
                    sum_ovr <= 0;

                    state <= S_DATA_BITS;

                    result <= 0;
                    result_idx <= 0;
                    ready <= 1'b0;
                    error <= 1'b0;
                end
            end

            S_DATA_BITS: begin
                if(counter_ovr == {OVR_WIDTH{1'b1}}) begin
                    state <= result_idx == 7 ? S_PARITY_BIT : S_DATA_BITS;

                    result <= (result >> 1) | (cur << 7);
                    result_idx <= result_idx + 1;
                end
            end

            S_PARITY_BIT: begin
                if(counter_ovr == {OVR_WIDTH{1'b1}}) begin
                    state <= S_STOP_BIT;

                    error <= ~(cur ^ (~^result));
                end
            end

            S_STOP_BIT: begin
                if(counter_ovr == {OVR_WIDTH{1'b1}}) begin
                    state <= (cur == 1'b1) ? S_IDLE : S_STOP_BIT;

                    val <= result;
                    error <= error | ~cur;
                    ready <= 1'b1;
                end
            end

            default:
                state <= S_IDLE;
        endcase

    end
end



endmodule
