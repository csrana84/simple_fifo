# simple_fifo

A Simple FIFO behavioral model,

FIFO in Verilog. The FIFO can hold
2^ADDR_WIDTH entries of data.

- Inputs : 
datain  : DATA_WIDTH Bit
wr_clk  : 1 bit
rd_clk  : 1 bit
reset   : 1 bit
push    : 1 bit
pop     : 1 bit

- Outputs : 
dataout        : DATA_WIDTH Bit
fifo_depth_wr  : ADDR_WIDTH Bit  // FIFO Depth Synchronized to Write Clock
fifo_depth_rd  : ADDR_WIDTH Bit  // FIFO Depth Synchronized to Write Clock
fifo_overflow  : 1 Bit
fifo_underflow : 1 Bit
fifo_full      : 1 Bit
fifo_afull     : 1 Bit