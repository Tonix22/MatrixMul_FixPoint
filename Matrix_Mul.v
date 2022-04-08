// Quartus Prime Verilog Template
// Signed multiply-accumulate
`include "config.v"

module Matrix_Mul
#(parameter BIT=`WORD_SIZE, DIM = `MATRIX_DIM)
(
	input src_clk,we,
	// Flatennig matrix NXN into N^2.
	//However we must take one row for cycle to acomplish pins requirments
	input [(`WORD_SIZE-1):0] data_wr,
	input [(`ADDRS_LEN-1):0] addr,
	output reg signed [BIT-1:0] VC, // one element of the row at the time
	output reg QI, QF
);

/// RAM ACCES
reg [(`ADDRS_LEN-1):0] addr_rd;
wire [(`WORD_SIZE-1)*`MATRIX_DIM:0] data_rd;

assign add_sel = we? addr:addr_rd;

Memory mem(
	.data(data_wr),
	.addr(add_sel),
	.we(we),
    .clk(src_clk),
	.q(data_rd)
);

/// MEMORY ACCES
reg mul_flag;
reg fxp_flag;
reg out_export;
wire [5:0] status;
// status
parameter IDLE = 1, WRITEMEM = 2, READ_B = 4, READ_A = 8,FXP_CHECK = 16,EXPORT_ROWS = 32;
FSM fsm(
	.clk(src_clk),
	.we(we),
	.mul(mul_flag),
	.fxp(fxp_flag),
	.print(out_export),
	.out(status)
);


wire [3:0]Q_int_inital  = 4'b1;
wire [3:0]Q_frac_intial = 4'hF;
wire [3:0]QI_out[0:2];
wire [3:0]QF_out[0:2];
wire [(`WORD_SIZE-1):0]Sum[0:2];

// multiplication variables
reg [3:0]row; // 8 rowth in 3 bit
reg hold;
reg [(`WORD_SIZE-1):0]A[0:`MATRIX_DIM];
reg [(`WORD_SIZE-1):0]B[0:`MATRIX_DIM];
reg [(`WORD_SIZE-1):0]C[0:`MATRIX_DIM];
reg [(`WORD_SIZE-1):0]TEMP[0:(`MATRIX_DIM/2)];
reg [2:0] fxp_stage;
integer i;

// independent sum blocks

FXP fxp_1 // merge TEMP[0] and TEMP[1]
(
	.DataA(TEMP[0]),
	.DataB(TEMP[1]),
	.QI_in(Q_int_inital),
	.QF_in(Q_frac_intial),
	.QI_out(QI_out[0]),
	.QF_out(QF_out[0]),
	.Sum(Sum[0])
);
FXP fxp_2 // merge TEMP[2] and TEMP[3]
(
	.DataA(TEMP[2]),
	.DataB(TEMP[3]),
	.QI_in(Q_int_inital),
	.QF_in(Q_frac_intial),
	.QI_out(QI_out[1]),
	.QF_out(QF_out[1]),
	.Sum(Sum[1])
);

assign Q_max_I = QI_out[0] > QI_out[1]?QI_out[0]:QI_out[1];
assign Q_min_F = QF_out[0] < QF_out[1]?QF_out[0]:QF_out[1];

FXP fxp3 // merge the last to sums
(
	.DataA(TEMP[0]),// we update this values in the always
	.DataB(TEMP[2]),// we update this values in the always
	.QI_in(Q_max_I),
	.QF_in(Q_min_F),
	.QI_out(QI_out[2]),
	.QF_out(QF_out[2]),
	.Sum(Sum[2])
);



always @(posedge src_clk) begin
	case (status)
		READ_B:
		begin
			if(!hold) begin
				addr_rd = `VECTOR_B_ADDR;
				hold = 1'b1;
			end
			else begin // wait for stable read of memory
				hold = 1'b0;
				{B[0],B[1],B[2],B[3],B[4],B[5],B[6],B[7]} = data_rd;
			end
		end

		READ_A:
			if(!hold)begin
				addr_rd = addr_rd + (row*4'h8);
				hold = 1'b1;
			end
			else begin // wait for stable read of memory
				hold = 1'b0;
				{A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7]} = data_rd;
				mul_flag = 1'b1;
			end
		
		// multiply A and B
		FXP_CHECK:
			if(fxp_stage == 0) begin
				// first time no FXP needed
				for (i=0;i<`MATRIX_DIM;i=i+1) begin
					C[i]=A[i]*B[i];
				end
				for (i=0;i<(`MATRIX_DIM/2);i=i+1) begin
					TEMP[i] = C[i*2]+C[(i*2)+1];
				end
				fxp_stage = fxp_stage+1;
			end
			else if (fxp_stage == 1) begin
				TEMP[0]=Sum[0]; 
				TEMP[2]=Sum[1];
				fxp_stage = fxp_stage+1;
			end
			else if (fxp_stage == 2) begin
				TEMP[0]=Sum[2];
				fxp_stage = fxp_stage+1;	
			end


		default: begin// IDLE, WRITEMEM, OTHER
			hold = 0;
			fxp_stage = 0;
			mul_flag = 0;
		end

		
	endcase
end

endmodule


