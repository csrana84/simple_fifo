`timescale 1ns / 1ps
// testbench for fifo,
//
module tb_fifo;

reg clk_50MHz, clk_20MHz, fifo_reset, parallel_wr_rd;

reg [15:0] dummy_data_count;

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 3;

wire [DATA_WIDTH-1:0] datain;
reg [ADDR_WIDTH+1:0] fifo_wr_count, fifo_rd_count;
reg wr_clk_en, wr_clk_en_reg, rd_clk_en, rd_clk_en_reg, read_start, write_start; 

wire wr_clk, rd_clk;
wire push, pop;

wire [DATA_WIDTH-1:0] dataout;
wire [ADDR_WIDTH-1:0] fifo_depth_wr;
wire [ADDR_WIDTH-1:0] fifo_depth_rd;
wire fifo_overflow;
wire fifo_underflow;
wire fifo_full;
wire fifo_afull;

// -------------------------------
parameter SIZE = 3;
parameter WR_IDLE = 3'b000, FIFO_WR_START = 3'b001, WAIT_ST_WR = 3'b011;
reg [SIZE-1:0] wr_state, wr_state_next;
//
parameter RD_IDLE = 3'b000, FIFO_RD_START = 3'b001, WAIT_ST_RD = 3'b011;
reg [SIZE-1:0] rd_state, rd_state_next;
// -------------------------------
initial begin
	clk_50MHz = 0;
	forever #10 clk_50MHz = ~clk_50MHz;
end
//
initial begin
	clk_20MHz = 0;
	forever #25 clk_20MHz = ~clk_20MHz;
end
// -------------------------------
initial begin
	fifo_reset = 1;
	#40;
	fifo_reset = 0;
end 
// -------------------------------
fifo_design #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
) i_fifo_design (
	.datain         (datain),
	.wr_clk         (wr_clk),
	.rd_clk         (rd_clk),
	.reset          (fifo_reset),
	.push           (push),
	.pop            (pop),

	.dataout        (dataout),
	.fifo_depth_wr  (fifo_depth_wr),
	.fifo_depth_rd  (fifo_depth_rd),
	.fifo_overflow  (fifo_overflow),
	.fifo_underflow (fifo_underflow),
	.fifo_full      (fifo_full),
	.fifo_afull     (fifo_afull)
);
// -------------------------------
// ------ WR_FSM  Seq Logic ------
always @ (posedge clk_50MHz)
begin
	if (fifo_reset == 1'b1) begin
		wr_state <= WR_IDLE;
	end else begin
		wr_state <= wr_state_next;
	end
end
// -------------------------------
// ------ Code startes Here ------
always @ (wr_state or fifo_wr_count or write_start or parallel_wr_rd)
begin : FIFO_WR_FSM
	wr_state_next = WR_IDLE;
	wr_clk_en     = 1'b0;
	read_start    = 1'b0;

	case(wr_state)
		WR_IDLE : begin
			wr_state_next = FIFO_WR_START;
			wr_clk_en     = 1'b0;
			read_start    = 1'b0;
		end

		FIFO_WR_START : begin
			wr_clk_en     = 1'b1;
			if ((fifo_wr_count[ADDR_WIDTH+1]) && (!parallel_wr_rd)) begin
				wr_state_next = WAIT_ST_WR;
			end else begin
				wr_state_next = FIFO_WR_START;
			end
		end

		WAIT_ST_WR : begin
			wr_clk_en     = 1'b0;
			read_start    = 1'b1;
			if (write_start)
				wr_state_next = WR_IDLE;
			else
				wr_state_next = WAIT_ST_WR;
		end

		default : begin
			wr_state_next = WR_IDLE;
			wr_clk_en     = 1'b0;
			read_start    = 1'b0;
		end
	endcase
end
//
always @ (posedge clk_50MHz)
begin
	if (wr_clk_en)
		fifo_wr_count <= fifo_wr_count+1;
	else
		fifo_wr_count <= 0;
end
//
assign datain = dummy_data_count[DATA_WIDTH:1];
//
always @ (negedge clk_50MHz)
	wr_clk_en_reg <= wr_clk_en;
//
assign wr_clk = wr_clk_en_reg & clk_50MHz;
assign push   = (fifo_wr_count[0] == 1'b1) ? 1'b1 : 1'b0;
//
always @ (posedge clk_50MHz)
begin
	if (fifo_reset)
		dummy_data_count <= 0;
	else
		dummy_data_count <= dummy_data_count+1;
end
//

always @ (posedge clk_20MHz)
begin
	if (fifo_reset)
		parallel_wr_rd <= 1'b0;
	else if (fifo_underflow)
		parallel_wr_rd <= 1'b1;
end
// --------- WR  FSM END ---------
// -------------------------------
// ------ RD_FSM  Seq Logic ------
always @ (posedge clk_20MHz)
begin
	if (fifo_reset == 1'b1) begin
		rd_state <= RD_IDLE;
	end else begin
		rd_state <= rd_state_next;
	end
end
// -------------------------------
// ------ Code startes Here ------
always @ (rd_state or fifo_rd_count or read_start or parallel_wr_rd)
begin : FIFO_RD_FSM
	rd_state_next = RD_IDLE;
	rd_clk_en     = 1'b0;
	write_start   = 1'b0;

	case(rd_state)
		RD_IDLE : begin
			rd_clk_en     = 1'b0;
			write_start   = 1'b0;
			if (read_start || parallel_wr_rd)
				rd_state_next = FIFO_RD_START;
			else
				rd_state_next = RD_IDLE;
		end

		FIFO_RD_START : begin
			rd_clk_en     = 1'b1;
			if (fifo_rd_count[ADDR_WIDTH+1] == 1'b1) begin
				rd_state_next = WAIT_ST_RD;
			end else begin
				rd_state_next = FIFO_RD_START;
			end
		end

		WAIT_ST_RD : begin
			rd_state_next = RD_IDLE;
			rd_clk_en     = 1'b0;
			write_start   = 1'b1;
		end

		default : begin
			rd_state_next = RD_IDLE;
			rd_clk_en     = 1'b0;
			write_start   = 1'b0;
		end
	endcase
end
//
always @ (posedge clk_20MHz)
begin
	if (rd_clk_en)
		fifo_rd_count <= fifo_rd_count+1;
	else
		fifo_rd_count <= 0;
end
//
always @ (negedge clk_20MHz)
	rd_clk_en_reg <= rd_clk_en;
//
assign rd_clk = rd_clk_en_reg & clk_20MHz;
assign pop    = (fifo_rd_count[0] == 1'b1) ? 1'b1 : 1'b0;
//assign pop    = 1'b0;
//
// --------- RD  FSM END ---------
// -------------------------------

endmodule