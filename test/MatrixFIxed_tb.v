`include "../config.v"
`timescale 10ns /1ns

module MatrixFIxed_tb();

reg src_clk;
reg we;
reg [(`WORD_SIZE-1):0] data_wr;
reg [(`ADDRS_LEN-1):0] addr;
wire signed [`WORD_SIZE-1:0] AB_Transpose;
wire [3:0] QI;
wire [3:0] QF;

always #1 src_clk=~src_clk;

Matrix_Mul Matrix_Mul_dut
(
    .src_clk(src_clk),
    .we(we),
	.data_wr(data_wr),
	.addr(addr),
	.AB_Transpose(AB_Transpose), // one element of the row at the time
	.QI(QI),
    .QF(QF)
);

integer data_file    ; // file handler
integer scan_file    ; // file handler
integer i;
reg [(`WORD_SIZE-1):0] captured_data;

initial begin

    //write memory
    we = 1'b1;
    data_file = $fopen("../PythonScripts/output.txt", "r");
    if (data_file == `NULL) 
    begin
        $display("data_file handle was NULL");
        $finish;
    end
    while(!$feof(data_file)) 
    begin
        scan_file = $fscanf(data_file, "%d\n", captured_data); 
        $display("val = %d",captured_data);
        data_wr = captured_data;
        #4
        addr = addr+1;
    end

end


endmodule