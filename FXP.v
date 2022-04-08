
`include "config.v"

//TODO check if signed needed it
module FXP
(
    input [(`WORD_SIZE-1):0]DataA,
    input [(`WORD_SIZE-1):0]DataB,
    input [3:0]QI_in,
    input [3:0]QF_in,
    output [3:0]QI_out,
    output [3:0]QF_out,
    output [(`WORD_SIZE-1):0]Sum
);

wire [(`WORD_SIZE-1):0]Tp;


// Normal sum
assign Tp = DataA+DataB;

// Sign of sums. It will be used to detect overflow or underflow
assign sign_A = DataA[`WORD_SIZE-1];
assign sign_B = DataA[`WORD_SIZE-1];
assign sign_Tp = Tp[`WORD_SIZE-1];

// if they have the same sign, check the difference betwen DataA xor TP. If they don't have the same sign
// it mean there is an overflow
assign overflow  = (sign_A ^ sign_B) ? 1'b0:(sign_A^sign_Tp);

// if the integer sign bit is equal to the next bit, 
//this means that bit n-2 is irrelevant for integer part.
assign underflow =  ~(sign_Tp ^ Tp[`WORD_SIZE-2]);  

// if there is not overlow check if there is underflow
assign QI_out = overflow?QI_in+1'b1: 
                (underflow?
                (QI_in>1'b1)? // substract unitl there is one bit for integer part
                    (QI_in-1'b1):(QI_in):
                (QI_in)); // not underflow and not overflow

assign QF_out = overflow?QF_in-1'b1: 
                (underflow?
                (QF_in+1'b1):  // if there is underflow add fractional resolution
                (QF_in));   // if not bypass QF_in

// if the data had an overflow, concatenate right an extra bit space, and procees the sum with new QI
assign Result = ~(overflow)?Tp:({sign_A,DataA[`WORD_SIZE-1:1]}+{sign_B,DataB[`WORD_SIZE-1:1]});


endmodule