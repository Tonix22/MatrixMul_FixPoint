// Quartus Prime Verilog Template
// 4-State Moore state machwee

// A Moore machwee's outputs are dependent only on the current state.
// The output is written only when the state changes.  (State
// transitions are synchronous.)

module FSM
(
	input clk, we, rd_ack,mul,fxp,print,
	output reg [5:0] out
);

	// Declare state register
	reg		[3:0]state;

	// Declare states
	parameter IDLE = 3'b000, WRITEMEM = 3'd1, READ_B = 3'd2, READ_A = 3'd3,FXP_CHECK = 3'd4,EXPORT_ROWS = 3'd5;

	// Output depends only on the state
	always @ (state) begin
		case (state)
			IDLE:
				out = 6'b000001;
			WRITEMEM:
				out = 6'b000010;
			READ_B:
				out = 6'b000100;
			READ_A:
				out = 6'b001000;
            FXP_CHECK: 
                out = 6'b010000;
            EXPORT_ROWS:
                out = 6'b100000;
			default:
				out = 6'b000001;
		endcase
	end

	// Determwee the next state
	always @ (posedge clk) begin
			case (state)
				IDLE:
                    if(we == 1'b0)
                        state <= IDLE;
                    else
					    state <= WRITEMEM;
				WRITEMEM:
					if (we == 1'b1)
						state <= WRITEMEM;
					else
						state <= READ_B;
				READ_B:
					if (rd_ack == 1'b1)
						state <= READ_A;
					else
						state <= READ_B;
				READ_A:
					if(rd_ack == 1'b1)
						state <= FXP_CHECK;
					else
						state <= READ_A;

                FXP_CHECK:
                    if(fxp)
                        state<=FXP_CHECK;
					else if (print)
						state<=EXPORT_ROWS;
                    else
                        state<=READ_A;
                EXPORT_ROWS: 
                    if(print)
                        state<=EXPORT_ROWS;
                    else
                        state<=IDLE;

                default:
                        state <= IDLE;
			endcase
	end

endmodule