//----------------------------------------------------------
// Module Name : Adder_4to1
// Description : Sum of absolute differences for 4 inputs
// Parameters  : XW      - Bit width of each input (unsigned)
//               YW      - Bit width of the output (unsigned)
//----------------------------------------------------------
module adder4to1 #(
    parameter XW      = 14,
    parameter YW      = 17
) (    
    input [XW-1:0] x0,
    input [XW-1:0] x1,
    input [XW-1:0] x2,
    input [XW-1:0] x3,
    output wire [YW-1:0] y
);
assign  y = x0 + x1 + x2 + x3;
endmodule