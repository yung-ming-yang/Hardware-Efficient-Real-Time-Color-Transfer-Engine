module chroma_stats #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output wire done,

    // SRAM read data inputs 
    // SRAM_GB for green/blue channel 31~16:G ; 15~0:B
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_0,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_1,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_2,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_3,

    // SRAM read address outputs -> 1920*1080/16
    output reg [17-1:0] sram_raddr_0,
    output reg [17-1:0] sram_raddr_1,
    output reg [17-1:0] sram_raddr_2,
    output reg [17-1:0] sram_raddr_3,    

    output reg [19-1:0] mu_Cb, mu_Cr,
    output reg [27-1:0] sqr_sigma_Cb, sqr_sigma_Cr,

    // mul output
    input wire [32-1:0] cb_sqr_0,
    input wire [32-1:0] cb_sqr_1,
    input wire [32-1:0] cb_sqr_2,
    input wire [32-1:0] cb_sqr_3,
    input wire [32-1:0] cb_sqr_4,
    input wire [32-1:0] cb_sqr_5,
    input wire [32-1:0] cb_sqr_6,
    input wire [32-1:0] cb_sqr_7,
    input wire [32-1:0] cb_sqr_8,
    input wire [32-1:0] cb_sqr_9,
    input wire [32-1:0] cb_sqr_10,
    input wire [32-1:0] cb_sqr_11,
    input wire [32-1:0] cb_sqr_12,
    input wire [32-1:0] cb_sqr_13,
    input wire [32-1:0] cb_sqr_14,
    input wire [32-1:0] cb_sqr_15,
    input wire [32-1:0] cr_sqr_0,
    input wire [32-1:0] cr_sqr_1,
    input wire [32-1:0] cr_sqr_2,
    input wire [32-1:0] cr_sqr_3,
    input wire [32-1:0] cr_sqr_4,
    input wire [32-1:0] cr_sqr_5,
    input wire [32-1:0] cr_sqr_6,
    input wire [32-1:0] cr_sqr_7,
    input wire [32-1:0] cr_sqr_8,
    input wire [32-1:0] cr_sqr_9,
    input wire [32-1:0] cr_sqr_10,
    input wire [32-1:0] cr_sqr_11,
    input wire [32-1:0] cr_sqr_12,
    input wire [32-1:0] cr_sqr_13,
    input wire [32-1:0] cr_sqr_14,
    input wire [32-1:0] cr_sqr_15
);

//---------------------------
// Variable Definitions
//---------------------------

// FSM 
parameter IDLE =            7'b000_0001,
          SUM_PRE =         7'b000_0010,    // Preload 
          SUM =             7'b000_0100,
          EXPECT =          7'b000_1000,
          EXPECT_SQR =      7'b001_0000,  
          VAR =             7'b010_0000,
          FINISH =          7'b100_0000;

reg [7-1:0] state, state_nx;
reg cnt1, cnt1_nx;
reg [17-1:0] cnt131071, cnt131071_nx;
wire [17-1:0] cnt131071_add2 = cnt131071 + 2;

// Input Data Reorganization
wire [LINEAR_BW-1:0] Cb [0:16-1];
wire [LINEAR_BW-1:0] Cr [0:16-1];

// signal path1
// I am lazy to share adder now, so no adder module here
wire mu_div_done, mu_sqr_div_done;

// reg stage 1 to 2
reg [32-1:0] sqr_Cb [0:16-1];
reg [32-1:0] sqr_Cb_nx [0:16-1];
reg [32-1:0] sqr_Cr [0:16-1];
reg [32-1:0] sqr_Cr_nx [0:16-1];

// reg stage 2 to 3
reg [34-1:0] sum1st_sqr_Cb [0:4-1];
reg [34-1:0] sum1st_sqr_Cb_nx [0:4-1];
reg [34-1:0] sum1st_sqr_Cr [0:4-1];
reg [34-1:0] sum1st_sqr_Cr_nx [0:4-1];

// reg stage 3 to 4
reg [36-1:0] sum2nd_sqr_Cb, sum2nd_sqr_Cr;
reg [36-1:0] sum2nd_sqr_Cb_nx, sum2nd_sqr_Cr_nx;

// squre sum result
reg [53-1:0] sum3rd_sqr_Cb, sum3rd_sqr_Cr;
reg [53-1:0] sum3rd_sqr_Cb_nx, sum3rd_sqr_Cr_nx;

// reg stage 1 to 2
reg [18-1:0] sum1st_Cb [0:4-1];
reg [18-1:0] sum1st_Cb_nx [0:4-1];
reg [18-1:0] sum1st_Cr [0:4-1];
reg [18-1:0] sum1st_Cr_nx [0:4-1];

// reg stage 2 to 3
reg [20-1:0] sum2nd_Cb, sum2nd_Cr;
reg [20-1:0] sum2nd_Cb_nx, sum2nd_Cr_nx;

// sum result
reg [37-1:0] sum3rd_Cb, sum3rd_Cr;
reg [37-1:0] sum3rd_Cb_nx, sum3rd_Cr_nx;

// mu
reg [19-1:0] mu_Cb_nx, mu_Cr_nx;
wire [19-1:0] mu_Cb_div, mu_Cr_div;
reg [27-1:0] mu_sqr_Cb, mu_sqr_Cr;
reg [27-1:0] mu_sqr_Cb_nx, mu_sqr_Cr_nx;
wire [27-1:0] mu_sqr_Cb_div, mu_sqr_Cr_div;

// square mu 
wire [38-1:0] temp_sqr_mu_Cb, temp_sqr_mu_Cr;
reg [28-1:0] sqr_mu_Cb, sqr_mu_Cr;
reg [28-1:0] sqr_mu_Cb_nx, sqr_mu_Cr_nx;

// square sigma
reg [27-1:0] sqr_sigma_Cb_nx, sqr_sigma_Cr_nx;

// loop variable
integer i;

//---------------------------
// FSM
//---------------------------

// combinational
always @* begin
    state_nx = state;
    cnt1_nx = 0;
    cnt131071_nx = 0;

    case (state)
        IDLE: begin
            if (enable) state_nx = SUM_PRE;
        end

        SUM_PRE: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = SUM;
        end

        SUM: begin
            cnt131071_nx = cnt131071 + 1;
            if (cnt131071 == 17'd129599 + 17'd3) state_nx = EXPECT;
        end 

        EXPECT: begin
            if (mu_sqr_div_done) state_nx = EXPECT_SQR; 
        end

        EXPECT_SQR: begin
            state_nx = VAR;
        end

        VAR: begin
            state_nx = FINISH;
        end

        FINISH: begin
            state_nx = IDLE;
        end
    endcase
end

assign done = (state == FINISH);

// sequential
always @(posedge clk) begin
    if (!srst_n) begin
        state <= IDLE;
    end else begin
        state <= state_nx;
    end
end

always @(posedge clk) begin
    cnt1 <= cnt1_nx;
    cnt131071 <= cnt131071_nx;
end

//---------------------------
// SRAM Access
//---------------------------

// Input Data Reorganization
assign {Cb[0], Cr[0], Cb[1], Cr[1], Cb[2], Cr[2], Cb[3], Cr[3]}         = sram_rdata_0;
assign {Cb[4], Cr[4], Cb[5], Cr[5], Cb[6], Cr[6], Cb[7], Cr[7]}         = sram_rdata_1;
assign {Cb[8], Cr[8], Cb[9], Cr[9], Cb[10], Cr[10], Cb[11], Cr[11]}     = sram_rdata_2;
assign {Cb[12], Cr[12], Cb[13], Cr[13], Cb[14], Cr[14], Cb[15], Cr[15]} = sram_rdata_3;

// Output
always @*begin
    sram_raddr_0 = 0;
    sram_raddr_1 = 0;
    sram_raddr_2 = 0;
    sram_raddr_3 = 0;
    case (state)   
        SUM_PRE: begin
            sram_raddr_0 = cnt1;
            sram_raddr_1 = cnt1;
            sram_raddr_2 = cnt1;
            sram_raddr_3 = cnt1;
        end
        SUM: begin
            sram_raddr_0 = cnt131071_add2;
            sram_raddr_1 = cnt131071_add2;
            sram_raddr_2 = cnt131071_add2;
            sram_raddr_3 = cnt131071_add2;
        end
    endcase
end

//---------------------------
// Data Path
//---------------------------

// sum pipeline
always @* begin
    // Stage 1
    for (i = 0; i < 16; i = i + 1) begin
        sqr_Cb_nx[i] = sqr_Cb[i];
        sqr_Cr_nx[i] = sqr_Cr[i];
    end
    for (i = 0; i < 4; i = i + 1) begin
        sum1st_Cb_nx[i] = sum1st_Cb[i];
        sum1st_Cr_nx[i] = sum1st_Cr[i];
    end

    // Stage 2
    for (i = 0; i < 4; i = i + 1) begin
        sum1st_sqr_Cb_nx[i] = sum1st_sqr_Cb[i];
        sum1st_sqr_Cr_nx[i] = sum1st_sqr_Cr[i];
    end
    sum2nd_Cb_nx = sum2nd_Cb;
    sum2nd_Cr_nx = sum2nd_Cr;

    // Stage 3
    sum2nd_sqr_Cb_nx = sum2nd_sqr_Cb;
    sum2nd_sqr_Cr_nx = sum2nd_sqr_Cr;
    sum3rd_Cb_nx = sum3rd_Cb;
    sum3rd_Cr_nx = sum3rd_Cr;

    // Stage 4
    sum3rd_sqr_Cb_nx = sum3rd_sqr_Cb;
    sum3rd_sqr_Cr_nx = sum3rd_sqr_Cr;

    case (state)
        IDLE: begin
            sum3rd_Cb_nx = 0;
            sum3rd_Cr_nx = 0;
            sum3rd_sqr_Cb_nx = 0;
            sum3rd_sqr_Cr_nx = 0;
        end
        SUM: begin
            // Stage 1: square & sum1st
            sqr_Cb_nx[0]  = cb_sqr_0;
            sqr_Cb_nx[1]  = cb_sqr_1;
            sqr_Cb_nx[2]  = cb_sqr_2;
            sqr_Cb_nx[3]  = cb_sqr_3;
            sqr_Cb_nx[4]  = cb_sqr_4;
            sqr_Cb_nx[5]  = cb_sqr_5;
            sqr_Cb_nx[6]  = cb_sqr_6;
            sqr_Cb_nx[7]  = cb_sqr_7;
            sqr_Cb_nx[8]  = cb_sqr_8;
            sqr_Cb_nx[9]  = cb_sqr_9;
            sqr_Cb_nx[10] = cb_sqr_10;
            sqr_Cb_nx[11] = cb_sqr_11;
            sqr_Cb_nx[12] = cb_sqr_12;
            sqr_Cb_nx[13] = cb_sqr_13;
            sqr_Cb_nx[14] = cb_sqr_14;
            sqr_Cb_nx[15] = cb_sqr_15;
            sqr_Cr_nx[0]  = cr_sqr_0;
            sqr_Cr_nx[1]  = cr_sqr_1;
            sqr_Cr_nx[2]  = cr_sqr_2;
            sqr_Cr_nx[3]  = cr_sqr_3;
            sqr_Cr_nx[4]  = cr_sqr_4;
            sqr_Cr_nx[5]  = cr_sqr_5;
            sqr_Cr_nx[6]  = cr_sqr_6;
            sqr_Cr_nx[7]  = cr_sqr_7;
            sqr_Cr_nx[8]  = cr_sqr_8;
            sqr_Cr_nx[9]  = cr_sqr_9;
            sqr_Cr_nx[10] = cr_sqr_10;
            sqr_Cr_nx[11] = cr_sqr_11;
            sqr_Cr_nx[12] = cr_sqr_12;
            sqr_Cr_nx[13] = cr_sqr_13;
            sqr_Cr_nx[14] = cr_sqr_14;
            sqr_Cr_nx[15] = cr_sqr_15;

            for (i = 0; i < 4; i = i + 1) begin
                sum1st_Cb_nx[i] = Cb[i*4] + Cb[i*4+1] + Cb[i*4+2] + Cb[i*4+3];
                sum1st_Cr_nx[i] = Cr[i*4] + Cr[i*4+1] + Cr[i*4+2] + Cr[i*4+3];
            end

            // Stage 2: sum1st_sqr & sum2nd
            for (i = 0; i < 4; i = i + 1) begin
                sum1st_sqr_Cb_nx[i] = sqr_Cb[i*4] + sqr_Cb[i*4+1] + sqr_Cb[i*4+2] + sqr_Cb[i*4+3];
                sum1st_sqr_Cr_nx[i] = sqr_Cr[i*4] + sqr_Cr[i*4+1] + sqr_Cr[i*4+2] + sqr_Cr[i*4+3];
            end
            sum2nd_Cb_nx = sum1st_Cb[0] + sum1st_Cb[1] + sum1st_Cb[2] + sum1st_Cb[3];
            sum2nd_Cr_nx = sum1st_Cr[0] + sum1st_Cr[1] + sum1st_Cr[2] + sum1st_Cr[3];

            // Stage 3: sum2nd_sqr & sum3rd
            sum2nd_sqr_Cb_nx = sum1st_sqr_Cb[0] + sum1st_sqr_Cb[1] + sum1st_sqr_Cb[2] + sum1st_sqr_Cb[3];
            sum2nd_sqr_Cr_nx = sum1st_sqr_Cr[0] + sum1st_sqr_Cr[1] + sum1st_sqr_Cr[2] + sum1st_sqr_Cr[3];
            sum3rd_Cb_nx = ((cnt131071 >= 17'd2) && (cnt131071 != 17'd129602)) ? sum2nd_Cb + sum3rd_Cb : sum3rd_Cb;
            sum3rd_Cr_nx = ((cnt131071 >= 17'd2) && (cnt131071 != 17'd129602)) ? sum2nd_Cr + sum3rd_Cr : sum3rd_Cr;

            // Stage 4: squre sum result
            sum3rd_sqr_Cb_nx = (cnt131071 >= 17'd3) ? sum2nd_sqr_Cb + sum3rd_sqr_Cb : sum3rd_sqr_Cb;
            sum3rd_sqr_Cr_nx = (cnt131071 >= 17'd3) ? sum2nd_sqr_Cr + sum3rd_sqr_Cr : sum3rd_sqr_Cr;
        end
    endcase
end

// mu
always @* begin
    mu_Cb_nx = mu_Cb;
    mu_Cr_nx = mu_Cr;
    mu_sqr_Cb_nx = mu_sqr_Cb;
    mu_sqr_Cr_nx = mu_sqr_Cr;

    case (state)
        IDLE: begin
            mu_Cb_nx = 0;
            mu_Cr_nx = 0;
            mu_sqr_Cb_nx = 0;
            mu_sqr_Cr_nx = 0;
        end
        EXPECT: begin       
            mu_Cb_nx = (mu_div_done) ? mu_Cb_div : mu_Cb;
            mu_Cr_nx = (mu_div_done) ? mu_Cr_div : mu_Cr;
            mu_sqr_Cb_nx = (mu_sqr_div_done) ? mu_sqr_Cb_div : mu_sqr_Cb;
            mu_sqr_Cr_nx = (mu_sqr_div_done) ? mu_sqr_Cr_div : mu_sqr_Cr;
        end
    endcase
end

divider_uu #(
    .DIVIDEND_B(37),
    .DIVIDER_B(19),
    .QUOTIENT_B(19)
) divider_uu_mu_Cb (
    .clk(clk),
    .en(state[3]),
    .dividend({sum3rd_Cb}),
    .divider({11'd2025, 8'd0}),
    .quotient(mu_Cb_div),
    .done(mu_div_done)
);

divider_uu #(
    .DIVIDEND_B(37),
    .DIVIDER_B(19),
    .QUOTIENT_B(19)
) divider_uu_mu_Cr (
    .clk(clk),
    .en(state[3]),
    .dividend({sum3rd_Cr}),
    .divider({11'd2025, 8'd0}),
    .quotient(mu_Cr_div),
    .done()
);

divider_uu #(
    .DIVIDEND_B(53),
    .DIVIDER_B(27),
    .QUOTIENT_B(27)
) divider_uu_mu_sqr_Cb (
    .clk(clk),
    .en(state[3]),
    .dividend({sum3rd_sqr_Cb}),
    .divider({11'd2025, 16'd0}),
    .quotient(mu_sqr_Cb_div),
    .done(mu_sqr_div_done)
);

divider_uu #(
    .DIVIDEND_B(53),
    .DIVIDER_B(27),
    .QUOTIENT_B(27)
) divider_uu_mu_sqr_Cr (
    .clk(clk),
    .en(state[3]),
    .dividend({sum3rd_sqr_Cr}),
    .divider({11'd2025, 16'd0}),
    .quotient(mu_sqr_Cr_div),
    .done()
);

// square mu , sigma squared

assign temp_sqr_mu_Cb = mu_Cb * mu_Cb;
assign temp_sqr_mu_Cr = mu_Cr * mu_Cr;

always @* begin
    sqr_mu_Cb_nx = sqr_mu_Cb;
    sqr_mu_Cr_nx = sqr_mu_Cr;
    sqr_sigma_Cb_nx = sqr_sigma_Cb;
    sqr_sigma_Cr_nx = sqr_sigma_Cr;

    case (state)
        IDLE: begin
            sqr_mu_Cb_nx = 0;
            sqr_mu_Cr_nx = 0;
            sqr_sigma_Cb_nx = 0;
            sqr_sigma_Cr_nx = 0;
        end

        EXPECT_SQR: begin
            sqr_mu_Cb_nx = temp_sqr_mu_Cb[38-1:10];
            sqr_mu_Cr_nx = temp_sqr_mu_Cr[38-1:10];
        end

        VAR: begin
            sqr_sigma_Cb_nx = mu_sqr_Cb - sqr_mu_Cb[27-1:0];
            sqr_sigma_Cr_nx = mu_sqr_Cr - sqr_mu_Cr[27-1:0];
        end
    endcase
end

//---------------------------
// Sequential Logic
//---------------------------

// sum pipeline
always @(posedge clk) begin
    // reg stage 1 to 2
    for (i = 0; i < 16; i = i + 1) begin
        sqr_Cb[i] <= sqr_Cb_nx[i];
        sqr_Cr[i] <= sqr_Cr_nx[i];
    end

    // reg stage 2 to 3
    for (i = 0; i < 4; i = i + 1) begin
        sum1st_sqr_Cb[i] <= sum1st_sqr_Cb_nx[i];
        sum1st_sqr_Cr[i] <= sum1st_sqr_Cr_nx[i];
    end

    // reg stage 3 to 4
    sum2nd_sqr_Cb <= sum2nd_sqr_Cb_nx;
    sum2nd_sqr_Cr <= sum2nd_sqr_Cr_nx;

    // squre sum result
    sum3rd_sqr_Cb <= sum3rd_sqr_Cb_nx;
    sum3rd_sqr_Cr <= sum3rd_sqr_Cr_nx;

    // reg stage 1 to 2
    for (i = 0; i < 4; i = i + 1) begin
        sum1st_Cb[i] <= sum1st_Cb_nx[i];
        sum1st_Cr[i] <= sum1st_Cr_nx[i];
    end

    // reg stage 2 to 3
    sum2nd_Cb <= sum2nd_Cb_nx;
    sum2nd_Cr <= sum2nd_Cr_nx;

    // sum result
    sum3rd_Cb <= sum3rd_Cb_nx;
    sum3rd_Cr <= sum3rd_Cr_nx;
end

// mu, square mu , sigma squared
always @(posedge clk) begin
    // mu
    mu_Cb <= mu_Cb_nx;
    mu_Cr <= mu_Cr_nx;
    mu_sqr_Cb <= mu_sqr_Cb_nx;
    mu_sqr_Cr <= mu_sqr_Cr_nx;

    // square mu 
    sqr_mu_Cb <= sqr_mu_Cb_nx;
    sqr_mu_Cr <= sqr_mu_Cr_nx;

    // square sigma 
    sqr_sigma_Cb <= sqr_sigma_Cb_nx;
    sqr_sigma_Cr <= sqr_sigma_Cr_nx;
end
endmodule
