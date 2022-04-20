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

integer fd    ; // file handler
integer fd_wr ;
integer scan_file    ; // file handler
integer i;
integer nth_product;
reg [(`WORD_SIZE-1):0] captured_data;

initial begin

    //write memory
    src_clk = 1'b0;
    we = 1'b1;
    fd    = $fopen("../../PythonScripts/data.csv", "r");
    fd_wr = $fopen("../../PythonScripts/res.csv", "w");
    for(i=0;i<7;i=i+1) begin
        $fwrite(fd_wr,"D_%d ,QI_%d ,QF_%d ,",i,i,i);
    end
    $fwrite(fd_wr,"D_%d ,QI_%d ,QF_%d\n",i,i,i);

    if (fd == `NULL) 
    begin
        $display("data_file handle was NULL");
        $finish;
    end

    scan_file = $fscanf(fd, "%s\n", captured_data); //first line
    while(!$feof(fd)) 
    begin
        for(nth_product = 0;nth_product < 1;nth_product=nth_product+1) 
        begin
            // intial memory address
            addr = 7'h00;
            scan_file = $fscanf(fd, "%s\n", captured_data);//float line
            scan_file = $fscanf(fd, "%X,", captured_data);//row number
            // flatten matrix
            for(i=0;i<64;i=i+1) begin 
                scan_file = $fscanf(fd, "%X,", captured_data); // data
                #3
                data_wr = captured_data;
                #2
                addr    = addr+1;
                
                $display("val = %X",captured_data);
            end
            //vector
            for(i=0;i<8;i=i+1) begin
                scan_file = $fscanf(fd, "%X,", captured_data); // data
                #3
                data_wr = captured_data;
                #2
                addr    = addr+1;
                //$display("val = %X",captured_data);
            end
            scan_file = $fscanf(fd, "%s\n", captured_data);//end line
            #10;
            we = 1'b0;
            #200;
        end
        $fclose(fd_wr);
        $fclose(fd);
        $stop;

        data_wr = captured_data;
        #4
        addr = addr+1;
    end

end

/// print output
integer data_cnt = 0;
integer hold_repeat = 0;
always @(AB_Transpose) begin
    if(hold_repeat == 0)
        if(data_cnt !=7)
        begin
            $fwrite(fd_wr,"%X ,%d ,%d ,",AB_Transpose,QI,QF);
            data_cnt = data_cnt+1;
        end
        else begin
            $fwrite(fd_wr,"%X ,%d ,%d \n",AB_Transpose,QI,QF);
            data_cnt = 0;
            hold_repeat = 1;
        end
    else begin
        hold_repeat = 0;
    end
end


endmodule