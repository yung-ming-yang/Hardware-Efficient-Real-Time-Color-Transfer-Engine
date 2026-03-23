module divider_uu #(
    parameter DIVIDEND_B = 24,
    parameter DIVIDER_B  = 18,
    parameter QUOTIENT_B = 10
)(
    input  wire                      clk,
    input  wire                      en,
    input  wire [DIVIDEND_B-1:0]     dividend,
    input  wire [DIVIDER_B-1:0]      divider,
    output reg  [QUOTIENT_B-1:0]     quotient,
    output reg                       done
);

// ------------------------------------------------------------
// Registers
// ------------------------------------------------------------
reg busy;
reg [DIVIDEND_B-1:0]       cnt_shift;      // shift counter: 1000...0 → 0000...1
reg [DIVIDEND_B-1:0]       dividend_reg;
reg [DIVIDEND_B-1:0]       quotient_reg;
reg [DIVIDER_B-1:0]        divider_reg;
reg [DIVIDER_B:0]          remainder_reg;

// ------------------------------------------------------------
// Combinational Wires (One Iteration Logic)
// ------------------------------------------------------------


wire [DIVIDER_B:0] divider_ext = {1'b0, divider_reg};               // extend for subtraction
wire [DIVIDER_B:0] rem_shifted = {remainder_reg[DIVIDER_B-1:0], dividend_reg[DIVIDEND_B-1]}; // shift remainder left and bring next MSB of dividend    

wire [DIVIDER_B:0] remainder_nx = (rem_shifted >= divider_ext) ? rem_shifted - divider_ext : rem_shifted;    // next remainder
wire [DIVIDEND_B-1:0] quotient_nx = (rem_shifted >= divider_ext) ? {quotient_reg[DIVIDEND_B-2:0], 1'b1} : {quotient_reg[DIVIDEND_B-2:0], 1'b0};   // quotient shift & append result bit
wire [DIVIDEND_B-1:0] dividend_nx = {dividend_reg[DIVIDEND_B-2:0], 1'b0};                  // dividend shift left by 1

// ------------------------------------------------------------
// Sequential Logic
// ------------------------------------------------------------
always @(posedge clk) begin
    divider_reg   <= {DIVIDER_B{1'b0}};
    dividend_reg  <= {DIVIDER_B{1'b0}};
    quotient_reg  <= {DIVIDEND_B{1'b0}};
    remainder_reg <= {(DIVIDER_B+1){1'b0}};
    quotient      <= {QUOTIENT_B{1'b0}};
    cnt_shift     <= {1'b1, {DIVIDEND_B-1{1'b0}}}; // 1000…0
    done <= 1'b0;
    busy <= 1'b0;
    if (en) begin
        if (!busy) begin
            divider_reg   <= divider;
            dividend_reg  <= dividend;
            quotient_reg  <= {DIVIDEND_B{1'b0}};
            remainder_reg <= {(DIVIDER_B+1){1'b0}};
            quotient      <= {QUOTIENT_B{1'b0}};
            cnt_shift     <= {1'b1, {DIVIDEND_B-1{1'b0}}}; // 1000…0
            done <= 1'b0;
            busy <= 1'b1;
        end else begin
            dividend_reg  <= dividend_nx;
            divider_reg   <= divider_reg;
            quotient_reg  <= quotient_nx;
            remainder_reg <= remainder_nx;
            busy <= 1'b1;
            if (divider == {DIVIDER_B{1'b0}}) begin     // divide by zero
                quotient <= {QUOTIENT_B{1'b1}};         // optional behavior
                done     <= 1'b1;
            end else if (cnt_shift[0] == 1'b1) begin    // last iteration
                quotient <= quotient_nx[QUOTIENT_B-1:0];
                done     <= 1'b1;     
            end else begin                              // continue iteration
                cnt_shift <= cnt_shift >> 1;
            end
        end
    end
end
endmodule
