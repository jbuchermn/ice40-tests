/////////////////////////////////////////////
module async_fifo #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input rst,

    /* Write domain */
    input w_clk,
    input w_en,
    input [DATA_WIDTH-1:0] w_in,
    output reg w_full,

    /* Read domain */
    input r_clk,
    input r_en,
    output reg [DATA_WIDTH-1:0] r_out,
    output reg r_empty
);

/*
 *  read MSB   0
 *  read       |
 *  addr       0 1 2 3 4 5 6 7
 *  written    <initial>
 *  write      |
 *  write MSB  0
 *
 *    => buffer empty
 *
 * ---------------------------------------
 *
 *  read MSB   0
 *  read       |
 *  addr       0 1 2 3 4 5 6 7
 *  written    x x x x x x x
 *  write                    |
 *  write MSB                0
 *
 *    => buffer contains elements, not full
 *
 * ---------------------------------------
 *
 *  read MSB   0
 *  read       |
 *  addr       0 1 2 3 4 5 6 7
 *  written    x x x x x x x x
 *  write      |
 *  write MSB  1
 *
 *    => buffer full
 *
 * ---------------------------------------
 *
 *  read MSB         0
 *  read             |
 *  addr       0 1 2 3 4 5 6 7
 *  written          x x x x x
 *  write      |
 *  write MSB  1
 *
 *    => buffer contains elements, not full
 *
 * ---------------------------------------
 *
 *  read MSB   1
 *  read       |
 *  addr       0 1 2 3 4 5 6 7
 *  written
 *  write      |
 *  write MSB  1
 *
 *    => buffer empty
 */

/* Pointers */
reg [DATA_WIDTH-1:0] buffer [0:(1<<ADDR_WIDTH)-1];

reg [ADDR_WIDTH:0] r_read_ptr;
reg [ADDR_WIDTH:0] w_write_ptr;

wire [ADDR_WIDTH:0] r_next_read_ptr;
assign r_next_read_ptr = r_read_ptr + 1;

wire [ADDR_WIDTH:0] w_next_write_ptr;
assign w_next_write_ptr = w_write_ptr + 1;

wire [ADDR_WIDTH-1:0] r_read_addr;
assign r_read_addr = r_read_ptr[ADDR_WIDTH-1:0];

wire [ADDR_WIDTH-1:0] w_write_addr;
assign w_write_addr = w_write_ptr[ADDR_WIDTH-1:0];

wire [ADDR_WIDTH:0] w_write_ptr_flip;
assign w_write_ptr_flip = (1 << ADDR_WIDTH) ^ w_write_ptr;

wire [ADDR_WIDTH:0] w_next_write_ptr_flip;
assign w_next_write_ptr_flip = (1 << ADDR_WIDTH) ^ w_next_write_ptr;

initial begin
    r_read_ptr = 0;
    w_write_ptr = 0;
    w_full = 0;
    r_empty = 0;
end

/* Gray-codes */
wire [ADDR_WIDTH:0] wg_write_ptr_flip;
bin2gray #(ADDR_WIDTH+1) b2g_wf(w_write_ptr_flip, wg_write_ptr_flip);

wire [ADDR_WIDTH:0] wg_next_write_ptr_flip;
bin2gray #(ADDR_WIDTH+1) b2g_nwf(w_next_write_ptr_flip, wg_next_write_ptr_flip);

wire [ADDR_WIDTH:0] rg_read_ptr;
bin2gray #(ADDR_WIDTH+1) b2g_r(r_read_ptr, rg_read_ptr);

wire [ADDR_WIDTH:0] rg_next_read_ptr;
bin2gray #(ADDR_WIDTH+1) b2g_nr(r_next_read_ptr, rg_next_read_ptr);

wire [ADDR_WIDTH:0] wg_read_ptr;
wire [ADDR_WIDTH:0] rg_write_ptr;
bin2gray_crossdomain #(ADDR_WIDTH+1) b2g_r_cd(rst, w_clk, r_read_ptr, wg_read_ptr);
bin2gray_crossdomain #(ADDR_WIDTH+1) b2g_w_cd(rst, r_clk, w_write_ptr, rg_write_ptr);


/* Write clock domain */
always@(posedge w_clk) begin
    if(rst) begin
        w_write_ptr = 0;
        w_full = 0;
    end else begin

        /* write_ptr_flip == read_ptr */
        if(wg_write_ptr_flip == wg_read_ptr) begin
            w_full <= 1;
        end else begin
            if(w_en & ~w_full) begin
                buffer[w_write_addr] <= w_in;
                w_write_ptr <= w_write_ptr + 1;
            end

            /* next_write_ptr_flip == read_ptr */
            w_full <= wg_next_write_ptr_flip == wg_read_ptr;
        end
    end
end


/* Read clock domain */
always@(posedge r_clk) begin
    if(rst) begin
        r_read_ptr = 0;
        r_empty = 0;
    end else begin

        /* read_ptr == write_ptr */
        if(rg_read_ptr == rg_write_ptr) begin
            r_empty <= 1;
        end else begin
            if(r_en & ~r_empty) begin
                r_out <= buffer[r_read_addr];
                r_read_ptr <= r_read_ptr + 1;
            end

            /* next_read_ptr == write_ptr */
            r_empty <= rg_next_read_ptr == rg_write_ptr;
        end
    end
end



endmodule

/////////////////////////////////////////////
module crossdomain #(
    parameter WIDTH = 1
)(
    input rst,
    input clk,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);

reg [WIDTH-1:0] tmp;

always@(posedge clk) begin
    if(rst) begin
        {out, tmp} <= 0;
    end else begin
        {out, tmp} <= {tmp, in};
    end
end

endmodule

/////////////////////////////////////////////
module bin2gray #(
    parameter WIDTH = 1
)(
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

assign out = (in >> 1) ^ in;

endmodule

/////////////////////////////////////////////
module bin2gray_crossdomain #(
    parameter WIDTH = 1
)(
    input rst,
    input clk,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

wire [WIDTH-1:0] gray;

bin2gray #(WIDTH) b2g(in, gray);
crossdomain #(WIDTH) cd(rst, clk, gray, out);

endmodule
