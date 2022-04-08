// Quartus Prime Verilog Template
// Single port RAM with single read/write address 
`include "config.v"

module Memory 
#(parameter DATA_WIDTH=`WORD_SIZE, parameter ADDR_WIDTH=`ADDRS_LEN,parameter PARALLEL_READ=`MATRIX_DIM)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1)*PARALLEL_READ:0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = {ram[addr_reg],ram[addr_reg+1],ram[addr_reg+2],
				ram[addr_reg+3],ram[addr_reg+4],ram[addr_reg+5],
				ram[addr_reg+6],ram[addr_reg+7]};

endmodule
