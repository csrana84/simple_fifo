`timescale 1ns / 1ps
/*
define 6 counter/ 5- bit counter
module counter #(
parameter count_depth = 5
) (
input clock,
input reset,
output [count_depth-1:0] count 
);

alsways @(posedge clock, posedge reset)
begin
	if (reset)
		count <= count_depth'h0;
	else
		count <= count + 1;
end

endmodule


define 6 counter/ 5- bit counter
module counter #(
`ifdef cnt_cntrl
parameter count_depth = 5
`else
parameter count_depth = 6
`endif

) (
input clock,
input reset,
output [count_depth-1:0] count 
);

alsways @(posedge clock, posedge reset)
begin
	if (reset)
		count <= count_depth'h0;
	else
		count <= count + 1;
end

endmodule

timescale 
FIFO in Verilog. The FIFO can hold
   512 entries of data.
    - Inputs : 
        datain  : 4 Bit
        wr_clk  : 1 bit
        rd_clk  : 1 bit
        reset   : 1 bit
        push    : 1 bit
        pop     : 1 bit
    - Outputs : 
        dataout        : 4 Bit
        fifo_depth_wr  : 9 Bit  // FIFO Depth Synchronized to Write Clock
        fifo_depth_rd  : 9 Bit  // FIFO Depth Synchronized to Write Clock
        fifo_overflow  : 1 Bit
        fifo_underflow : 1 Bit
        fifo_full      : 1 Bit
        fifo_afull     : 1 Bit
*/
module fifo_design #(
	parameter DATA_WIDTH = 8,
	parameter ADDR_WIDTH = 7
) (
	input [DATA_WIDTH-1:0] datain,
	input wr_clk,
	input rd_clk,
	input reset,
	input push,
	input pop,

	output [DATA_WIDTH-1:0] dataout,
	output [ADDR_WIDTH-1:0] fifo_depth_wr,
	output [ADDR_WIDTH-1:0] fifo_depth_rd,
	output reg fifo_overflow,
	output reg fifo_underflow,
	output fifo_full,
	output fifo_afull
);
localparam FIFO_DEPTH = 2 ** ADDR_WIDTH;
// 512 depth 4 bit wide
reg [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
reg [ADDR_WIDTH:0] count_wr, count_wr1, count_rd, count_rd1;

wire empty, full;

// FIFO Write
always @(posedge wr_clk, posedge reset)
	if (reset) 
		count_wr <= 0;
	else if (push && !full)
	begin
		fifo_mem[count_wr[ADDR_WIDTH-1:0]] <= datain;
		count_wr <= count_wr + 1;
	end

// FIFO Read pointer
always @(posedge rd_clk, posedge reset)
	if (reset) 
		count_rd <= 0;
	else if (pop)
		count_rd <= count_rd + 1;

//
assign dataout = fifo_mem[count_rd[ADDR_WIDTH-1:0]];

//
// fifo full condition
// eg no read started yet 
// when write pointer = read pointer after one roll over
// write pointer delayed
always @(posedge wr_clk, posedge reset)
	if (reset) 
		count_wr1 <= 0;
	else
		count_wr1 <= count_wr;

assign full = (count_rd == {!count_wr[ADDR_WIDTH],count_wr[ADDR_WIDTH-1:0]});

// empty generation
// read pointer delayed
always @(posedge wr_clk, posedge reset)
	if (reset) 
		count_rd1 <= 0;
	else
		count_rd1 <= count_rd;

// empty 
assign empty = (count_rd == count_wr1);
//
assign fifo_depth_wr = count_wr[ADDR_WIDTH-1:0];
assign fifo_depth_rd = count_rd[ADDR_WIDTH-1:0];
assign fifo_full = full;
assign fifo_afull = empty;
//
always @ (push or full)
	if (push && full)
		fifo_overflow <= 1'b1;
	else 
		fifo_overflow <= 1'b0;
//
always @ (pop or empty)
	if (pop && empty)
		fifo_underflow <= 1'b1;
	else 
		fifo_underflow <= 1'b0;
//
endmodule