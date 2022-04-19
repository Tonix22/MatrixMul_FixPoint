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
	output reg signed [BIT-1:0] AB_Transpose, // one element of the row at the time
	output reg [3:0] QI, 
	output reg [3:0] QF
);

/*
███╗   ███╗███████╗███╗   ███╗
████╗ ████║██╔════╝████╗ ████║
██╔████╔██║█████╗  ██╔████╔██║
██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║
██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║
╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝
                              
*/
reg [(`ADDRS_LEN-1):0] addr_rd;
wire [(`WORD_SIZE*`MATRIX_DIM)-1:0] data_rd;

wire [(`ADDRS_LEN-1):0] add_sel;
assign add_sel = we? addr:addr_rd;

Memory mem(
	.data(data_wr),
	.addr(add_sel),
	.we(we),
    .clk(src_clk),
	.q(data_rd)
);

/*
███████╗███████╗███╗   ███╗
██╔════╝██╔════╝████╗ ████║
█████╗  ███████╗██╔████╔██║
██╔══╝  ╚════██║██║╚██╔╝██║
██║     ███████║██║ ╚═╝ ██║
╚═╝     ╚══════╝╚═╝     ╚═╝
                           
*/
reg mul_flag;
reg fxp_flag;
reg print_flag;
reg rd_ack;
wire [5:0] status;
// status
parameter IDLE = 1, WRITEMEM = 2, READ_B = 4, READ_A = 8,FXP_CHECK = 16,EXPORT_ROWS = 32;
FSM fsm(
	.clk(src_clk),
	.we(we),
	.rd_ack(rd_ack),
	.mul(mul_flag),
	.fxp(fxp_flag),
	.print(print_flag),
	.out(status)
);


// multiplication variables
/*
███╗   ███╗██╗   ██╗██╗  ████████╗    ██╗   ██╗ █████╗ ██████╗ ███████╗
████╗ ████║██║   ██║██║  ╚══██╔══╝    ██║   ██║██╔══██╗██╔══██╗██╔════╝
██╔████╔██║██║   ██║██║     ██║       ██║   ██║███████║██████╔╝███████╗
██║╚██╔╝██║██║   ██║██║     ██║       ╚██╗ ██╔╝██╔══██║██╔══██╗╚════██║
██║ ╚═╝ ██║╚██████╔╝███████╗██║        ╚████╔╝ ██║  ██║██║  ██║███████║
╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝         ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
*/
// hold: internal flag to wait a clk cycle when memry read
reg hold;
reg addr_set;
reg signed [(`WORD_SIZE-1):0]A[0:`MATRIX_DIM-1];
reg signed [(`WORD_SIZE-1):0]B[0:`MATRIX_DIM-1];
reg signed [(2*`WORD_SIZE)-2:0]AB[0:`MATRIX_DIM-1];
//final vector result
reg signed [(`WORD_SIZE-1):0]C[0:`MATRIX_DIM-1];

// QI and QF for each result, it could vary for each element of vector
reg [(`WORD_SIZE-1):0]QI_vector[0:`MATRIX_DIM-1];
reg [(`WORD_SIZE-1):0]QF_vector[0:`MATRIX_DIM-1];

// partial sums and temporal variables
reg [(`WORD_SIZE-1):0]TEMP[0:(`MATRIX_DIM/2)-1];
reg [2:0] fxp_stage;
integer i;
// row number process, goes from 0-7
reg[2:0] row_cnt;
reg[2:0] export_cnt;

/*
███████╗██╗  ██╗██████╗      ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗
██╔════╝╚██╗██╔╝██╔══██╗    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝
█████╗   ╚███╔╝ ██████╔╝    ██║     ███████║█████╗  ██║     █████╔╝ 
██╔══╝   ██╔██╗ ██╔═══╝     ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ 
██║     ██╔╝ ██╗██║         ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗
╚═╝     ╚═╝  ╚═╝╚═╝          ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝
*/                                                               
// independent sum blocks
wire [3:0]Q_int_inital  = 4'b1;
wire [3:0]Q_frac_intial = 4'hF;
wire [3:0]QI_out[0:2];
wire [3:0]QF_out[0:2];
wire [(`WORD_SIZE-1):0]Sum[0:2];

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

reg [3:0]Q_max_I;
reg [3:0]Q_min_F;

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
/*
███╗   ███╗ █████╗ ██╗███╗   ██╗
████╗ ████║██╔══██╗██║████╗  ██║
██╔████╔██║███████║██║██╔██╗ ██║
██║╚██╔╝██║██╔══██║██║██║╚██╗██║
██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝                                
*/


always @(posedge src_clk) 
begin
	if(rd_ack == 1'b1) begin
		rd_ack = 1'b0;
	end
	case (status)
		/************* READ B ************/
		READ_B:
		begin
			if(addr_set == 1'b0) begin 
				addr_rd  = `VECTOR_B_ADDR;
				addr_set = 1'b1;
			end
			else if(!hold) begin
				hold = 1'b1;
				rd_ack = 1'b1;
			end
			else begin // wait for stable read of memory
				{B[0],B[1],B[2],B[3],B[4],B[5],B[6],B[7]} = data_rd;

				/*** FSM FLAGS *****/
				hold   = 1'b0;
				addr_set = 1'b0;
				addr_rd  = 7'b0;
				/*** FSM FLAGS *****/
			end
		end
		/************* READ A ************/
		READ_A:
		begin
			if(addr_set == 1'b0) begin
				addr_rd = addr_rd + (row_cnt*4'h8);
				addr_set = 1'b1;
			end
			else if(!hold)begin
				hold   = 1'b1;
				rd_ack = 1'b1;
			end
			else begin // wait for stable read of memory
				hold = 1'b0;
				{A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7]} = data_rd;
				/*** FSM FLAGS *****/
				fxp_flag = 1'b1;
				addr_set = 1'b0;
				/*** FSM FLAGS *****/
			end
		end
		/************* FXP_CHECK ************/
		// multiply A and B
		FXP_CHECK:
		begin 
			if(fxp_stage == 0) begin
				// first time no FXP check needed
				for (i=0;i<`MATRIX_DIM;i=i+1) begin
					AB[i] = A[i]*B[i];
					C[i]  =(AB[i][(2*`WORD_SIZE)-3:14]);// discard last bit and ignore 16
				end
				for (i=0;i<(`MATRIX_DIM/2);i=i+1) begin
					TEMP[i] = C[i*2]+C[(i*2)+1];
				end
				fxp_stage = fxp_stage+1;
			end
			else if (fxp_stage == 1) begin
				// adjust QI partcial sums if needed
				if(QI_out[0] > QI_out[1]) begin
					Q_max_I = QI_out[0];
					Q_min_F = QF_out[0];
					TEMP[0] = Sum[0];
					//Concatenate the most significant bit to the shortest integer part
					//and remove last fractional bit, to compensate the same QI.F format
					TEMP[2] = {Sum[1][(`WORD_SIZE-1)],Sum[1][(`WORD_SIZE-1):1]};
				end
				else if (QI_out[0] < QI_out[1]) begin
					Q_max_I = QI_out[1];
					Q_min_F = QF_out[1];
					//Concatenate the most significant bit to the shortest integer part
					//and remove last fractional bit, to compensate the same QI.F format 
					TEMP[0] = {Sum[0][(`WORD_SIZE-1)],Sum[0][(`WORD_SIZE-1):1]};
					TEMP[2]=Sum[1];
				end
				else begin // if not adjument neede it
					TEMP[0]=Sum[0]; 
					TEMP[2]=Sum[1];
				end
				fxp_stage = fxp_stage+1;
			end
			else if (fxp_stage == 2) begin
				C[row_cnt] = Sum[2]; // Nth row result
				QI_vector[row_cnt] = QI_out[2];
				QF_vector[row_cnt] = QF_out[2];

				if(row_cnt != 3'd7) 
				begin
					row_cnt = row_cnt+1'b1; // next row  proc
					fxp_stage  = 0; // clear counter stage
					fxp_flag   = 0; //
				end
				else begin
					row_cnt    = 3'b000; // reset column cnt
					print_flag = 1'b1;
				end
			
			end
		end
		/************* EXPORT_ROWS ************/
		EXPORT_ROWS:
		begin
			AB_Transpose = C[export_cnt];
			QI = QI_vector[export_cnt];
			QF = QF_vector[export_cnt];
			if(export_cnt != 3'd7)
				export_cnt = export_cnt+1;
			else begin
				export_cnt = 3'b000;
				print_flag = 1'b0;
			end
		end
		/************* DEFAULT ************/
		//Clear Flags and counters
		default://IDLE
		begin
			hold       = 1'b0;
			addr_set   = 1'b0;
			fxp_stage  = 1'b0;
			mul_flag   = 1'b0;
			rd_ack     = 1'b0;
			print_flag = 1'b0;
			row_cnt    = 3'b0;
			addr_rd    = 7'b0;
		end

	endcase
end

endmodule


