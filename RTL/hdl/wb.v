//---------------------------
// Module: wb
// Description: White Balance Version 1.0
//  - cycle count: 259256
//  - timing: 4.5
//  - area: 26246
//---------------------------

module wb #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output wire done,

    // SRAM read data inputs 
    // SRAM_R for red channel
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r0,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r2,
    // SRAM_GB for green/blue channel 31~16:G ; 15~0:B
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb0,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb1,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb2,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb3,

    // SRAM read address outputs -> 1920*1080/16
    output reg [17-1:0] sram_raddr_r0,
    output reg [17-1:0] sram_raddr_r2,

    output reg [17-1:0] sram_raddr_gb0,
    output reg [17-1:0] sram_raddr_gb1,
    output reg [17-1:0] sram_raddr_gb2,
    output reg [17-1:0] sram_raddr_gb3,    

    // SRAM write address outputs -> 1920*1080/16
    output reg [17-1:0] sram_waddr_r0,
    output reg [17-1:0] sram_waddr_r2,

    output reg [17-1:0] sram_waddr_gb0,
    output reg [17-1:0] sram_waddr_gb1,
    output reg [17-1:0] sram_waddr_gb2,
    output reg [17-1:0] sram_waddr_gb3,

    // SRAM write enable outputs (neg.)
    output reg sram_wen_r0,
    output reg sram_wen_r2,

    output reg sram_wen_gb0,
    output reg sram_wen_gb1,
    output reg sram_wen_gb2,
    output reg sram_wen_gb3,    

    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    output reg [CH_NUM-1:0] sram_wordmask_r0,
    output reg [CH_NUM-1:0] sram_wordmask_r2,

    output reg [CH_NUM*2-1:0] sram_wordmask_gb0,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb1,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb2,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb3,

    // SRAM write data outputs
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0,
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2,

    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3
);

//---------------------------
// Variable Definitions
//---------------------------
// FSM 
parameter IDLE =            7'b000_0001,
          GET_MEAN_PL =     7'b000_0010,    // Preload 
          GET_MEAN =        7'b000_0100,
          GET_GAIN =        7'b000_1000,
          SCALE_PIXEL_PL =  7'b001_0000,    // Preload 
          SCALE_PIXEL =     7'b010_0000,
          FINISH =          7'b100_0000;

reg [7-1:0] state, state_nx;
reg cnt1, cnt1_nx;
reg [17-1:0] cnt131071, cnt131071_nx;
wire [17-1:0] cnt131071_add2 = cnt131071 + 2;
wire div_done;

// Input Reorganization
wire [LINEAR_BW-1:0] r [0:4-1];
wire [LINEAR_BW-1:0] g1 [0:4-1];
wire [LINEAR_BW-1:0] g2 [0:4-1];
wire [LINEAR_BW-1:0] b [0:4-1];

// temparary registers
reg [36-1:0] sum_R, sum_R_nx;
reg [36-1:0] sum_G, sum_G_nx;
reg [36-1:0] sum_B, sum_B_nx;

reg [18-1:0] sum_r;
reg [18-1:0] sum_g1;
reg [18-1:0] sum_g2;
reg [18-1:0] sum_b;

reg  [14-1:0] g_R, g_R_nx;
wire [14-1:0] g_G = 14'b00_0011_1001_0000;
reg  [14-1:0] g_B, g_B_nx;

// Adder 
wire [18-1:0] sum_r_nx;
wire [18-1:0] sum_g1_nx;
wire [18-1:0] sum_g2_nx;
wire [18-1:0] sum_b_nx;

// Divider
wire [14-1:0] quotient_r;
wire [14-1:0] quotient_b;

// Output preparation
wire [30-1:0] scaled [0:16-1]; 
wire [16-1:0] clipped [0:16-1];

//---------------------------
// FSM
//---------------------------
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

always @* begin
    state_nx = state;
    cnt1_nx = 0;
    cnt131071_nx = 0;

    case (state)
        IDLE: begin
            if (enable) state_nx = GET_MEAN_PL;
        end

        GET_MEAN_PL: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = GET_MEAN;
        end

        GET_MEAN: begin
            cnt131071_nx = cnt131071 + 1;
            if (cnt131071 == 17'd129599 + 17'd1) state_nx = GET_GAIN;
        end 

        GET_GAIN: begin
            if (div_done) state_nx = SCALE_PIXEL_PL; 
        end

        SCALE_PIXEL_PL: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = SCALE_PIXEL;
        end

        SCALE_PIXEL: begin
            cnt131071_nx = cnt131071 + 1;
            if (cnt131071 == 17'd129599) state_nx = FINISH;
        end

        FINISH: begin
            state_nx = IDLE;
        end
    endcase
end

assign done = (state == FINISH);

//---------------------------
// Module instantiation
//---------------------------
adder4to1 #(
    .XW(16),
    .YW(18)
) adder_sum_r (
    .x0(r[0]),
    .x1(r[1]),
    .x2(r[2]),
    .x3(r[3]),
    .y(sum_r_nx)
);

adder4to1 #(
    .XW(16),
    .YW(18)
) adder_sum_g1 (
    .x0(g1[0]),
    .x1(g1[1]),
    .x2(g1[2]),
    .x3(g1[3]),
    .y(sum_g1_nx)
);

adder4to1 #(
    .XW(16),
    .YW(18)
) adder_sum_g2 (
    .x0(g2[0]),
    .x1(g2[1]),
    .x2(g2[2]),
    .x3(g2[3]),
    .y(sum_g2_nx)
);

adder4to1 #(
    .XW(16),
    .YW(18)
) adder_sum_b (
    .x0(b[0]),
    .x1(b[1]),
    .x2(b[2]),
    .x3(b[3]),
    .y(sum_b_nx)
);

divider_uu #(
    .DIVIDEND_B(45),
    .DIVIDER_B(36),
    .QUOTIENT_B(14)
) divider_uu0 (
    .clk(clk),
    .en(state[3]),
    .dividend({sum_G, 9'b0}),
    .divider(sum_R),
    .quotient(quotient_r),
    .done(div_done)
);

divider_uu #(
    .DIVIDEND_B(45),
    .DIVIDER_B(36),
    .QUOTIENT_B(14)
) divider_uu1 (
    .clk(clk),
    .en(state[3]),
    .dividend({sum_G, 9'b0}),
    .divider(sum_B),
    .quotient(quotient_b),
    .done()
);


//---------------------------
// DataFlow
//---------------------------
always @(posedge clk) begin
    sum_r <= sum_r_nx;
    sum_g1 <= sum_g1_nx;
    sum_g2 <= sum_g2_nx;
    sum_b <= sum_b_nx;
    g_R <= g_R_nx;
    g_B <= g_B_nx;
end

always @(posedge clk) begin
    if (~srst_n) begin
        sum_R <= 36'd0;
        sum_G <= 36'd0;
        sum_B <= 36'd0;
    end
    else begin
        sum_R <= sum_R_nx;
        sum_G <= sum_G_nx;
        sum_B <= sum_B_nx;
    end
end

assign r[0] = sram_rdata_r0[CH_NUM*LINEAR_BW-1 : (CH_NUM-1)*LINEAR_BW];
assign r[1] = sram_rdata_r0[(CH_NUM-2)*LINEAR_BW-1 : (CH_NUM-3)*LINEAR_BW];
assign r[2] = sram_rdata_r2[CH_NUM*LINEAR_BW-1 : (CH_NUM-1)*LINEAR_BW];
assign r[3] = sram_rdata_r2[(CH_NUM-2)*LINEAR_BW-1 : (CH_NUM-3)*LINEAR_BW];

assign g1[0] = sram_rdata_gb0[(CH_NUM*2-2)*LINEAR_BW-1 : (CH_NUM*2-3)*LINEAR_BW];
assign g1[1] = sram_rdata_gb0[(CH_NUM*2-6)*LINEAR_BW-1 : (CH_NUM*2-7)*LINEAR_BW];
assign g1[2] = sram_rdata_gb2[(CH_NUM*2-2)*LINEAR_BW-1 : (CH_NUM*2-3)*LINEAR_BW];
assign g1[3] = sram_rdata_gb2[(CH_NUM*2-6)*LINEAR_BW-1 : (CH_NUM*2-7)*LINEAR_BW];

assign g2[0] = sram_rdata_gb1[(CH_NUM*2)*LINEAR_BW-1 : (CH_NUM*2-1)*LINEAR_BW];
assign g2[1] = sram_rdata_gb1[(CH_NUM*2-4)*LINEAR_BW-1 : (CH_NUM*2-5)*LINEAR_BW];
assign g2[2] = sram_rdata_gb3[(CH_NUM*2)*LINEAR_BW-1 : (CH_NUM*2-1)*LINEAR_BW];
assign g2[3] = sram_rdata_gb3[(CH_NUM*2-4)*LINEAR_BW-1 : (CH_NUM*2-5)*LINEAR_BW];

assign b[0] = sram_rdata_gb1[(CH_NUM*2-3)*LINEAR_BW-1 : (CH_NUM*2-4)*LINEAR_BW];
assign b[1] = sram_rdata_gb1[(CH_NUM*2-7)*LINEAR_BW-1 : 0];
assign b[2] = sram_rdata_gb3[(CH_NUM*2-3)*LINEAR_BW-1 : (CH_NUM*2-4)*LINEAR_BW];
assign b[3] = sram_rdata_gb3[(CH_NUM*2-7)*LINEAR_BW-1 : 0];

assign scaled[0]  = r[0]  * g_R;
assign scaled[1]  = g1[0] * g_G;
assign scaled[2]  = r[1]  * g_R;
assign scaled[3]  = g1[1] * g_G;
assign scaled[4]  = g2[0] * g_G;
assign scaled[5]  = b[0]  * g_B;
assign scaled[6]  = g2[1] * g_G;
assign scaled[7]  = b[1]  * g_B;
assign scaled[8]  = r[2]  * g_R;
assign scaled[9]  = g1[2] * g_G;
assign scaled[10] = r[3]  * g_R;
assign scaled[11] = g1[3] * g_G;
assign scaled[12] = g2[2] * g_G;
assign scaled[13] = b[2]  * g_B;
assign scaled[14] = g2[3] * g_G;
assign scaled[15] = b[3]  * g_B;

assign clipped[0]  = (scaled[0]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[0][23:10], 2'b0};    // clip & astype(np.uint16) only do truncation
assign clipped[1]  = (scaled[1]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[1][23:10], 2'b0};
assign clipped[2]  = (scaled[2]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[2][23:10], 2'b0};
assign clipped[3]  = (scaled[3]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[3][23:10], 2'b0};
assign clipped[4]  = (scaled[4]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[4][23:10], 2'b0};
assign clipped[5]  = (scaled[5]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[5][23:10], 2'b0};
assign clipped[6]  = (scaled[6]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[6][23:10], 2'b0};
assign clipped[7]  = (scaled[7]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[7][23:10], 2'b0};
assign clipped[8]  = (scaled[8]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[8][23:10], 2'b0};
assign clipped[9]  = (scaled[9]  > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[9][23:10], 2'b0};
assign clipped[10] = (scaled[10] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[10][25:10], 2'b0};
assign clipped[11] = (scaled[11] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[11][25:10], 2'b0};
assign clipped[12] = (scaled[12] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[12][25:10], 2'b0};
assign clipped[13] = (scaled[13] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[13][25:10], 2'b0};
assign clipped[14] = (scaled[14] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[14][25:10], 2'b0};
assign clipped[15] = (scaled[15] > {4'd0, 16'd65535, 10'd0}) ? 16'd65535 : {scaled[15][25:10], 2'b0};

always @*begin
    sum_R_nx = sum_R;
    sum_G_nx = sum_G;
    sum_B_nx = sum_B;

    g_R_nx = g_R;
    g_B_nx = g_B;

    sram_raddr_r0 = 0;
    sram_raddr_r2 = 0;
    sram_raddr_gb0 = 0;
    sram_raddr_gb1 = 0;
    sram_raddr_gb2 = 0;
    sram_raddr_gb3 = 0;

    sram_waddr_r0 = 0;
    sram_waddr_r2 = 0;
    sram_waddr_gb0 = 0;
    sram_waddr_gb1 = 0;
    sram_waddr_gb2 = 0;
    sram_waddr_gb3 = 0;

    sram_wen_r0 = 1'b1;
    sram_wen_r2 = 1'b1;
    sram_wen_gb0 = 1'b1;
    sram_wen_gb1 = 1'b1;
    sram_wen_gb2 = 1'b1;
    sram_wen_gb3 = 1'b1;

    sram_wordmask_r0 = {CH_NUM{1'b1}};
    sram_wordmask_r2 = {CH_NUM{1'b1}};
    sram_wordmask_gb0 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb1 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb2 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb3 = {CH_NUM*2{1'b1}};

    sram_wdata_r0 = 0;
    sram_wdata_r2 = 0;
    sram_wdata_gb0 = 0;
    sram_wdata_gb1 = 0;
    sram_wdata_gb2 = 0;
    sram_wdata_gb3 = 0;

    case (state)
        GET_MEAN_PL: begin
            sram_raddr_r0 = cnt1;
            sram_raddr_r2 = cnt1;
            sram_raddr_gb0 = cnt1;
            sram_raddr_gb1 = cnt1;
            sram_raddr_gb2 = cnt1;
            sram_raddr_gb3 = cnt1;

            sum_R_nx = 36'd0;
            sum_G_nx = 36'd0;
            sum_B_nx = 36'd0;
            g_R_nx = 0;
            g_B_nx = 0;
        end
        GET_MEAN: begin
            sram_raddr_r0 = cnt131071_add2;
            sram_raddr_r2 = cnt131071_add2;
            sram_raddr_gb0 = cnt131071_add2;
            sram_raddr_gb1 = cnt131071_add2;
            sram_raddr_gb2 = cnt131071_add2;
            sram_raddr_gb3 = cnt131071_add2;

            if (cnt131071 != 0) begin
                sum_R_nx = sum_R + sum_r;
                sum_G_nx = sum_G + sum_g1 + sum_g2;
                sum_B_nx = sum_B + sum_b;
            end
        end
        GET_GAIN: begin
            g_R_nx = quotient_r;       // ((sum_G / 2) * 2^10) / sum_R
            g_B_nx = quotient_b;       // ((sum_G / 2) * 2^10) / sum_B      
        end
        SCALE_PIXEL_PL: begin
            sram_raddr_r0 = cnt1;
            sram_raddr_r2 = cnt1;
            sram_raddr_gb0 = cnt1;
            sram_raddr_gb1 = cnt1;
            sram_raddr_gb2 = cnt1;
            sram_raddr_gb3 = cnt1;
        end
        SCALE_PIXEL: begin
            sram_raddr_r0 = cnt131071_add2;
            sram_raddr_r2 = cnt131071_add2;
            sram_raddr_gb0 = cnt131071_add2;
            sram_raddr_gb1 = cnt131071_add2;
            sram_raddr_gb2 = cnt131071_add2;
            sram_raddr_gb3 = cnt131071_add2;

            sram_waddr_r0 = cnt131071;
            sram_waddr_r2 = cnt131071;
            sram_waddr_gb0 = cnt131071;
            sram_waddr_gb1 = cnt131071;
            sram_waddr_gb2 = cnt131071;
            sram_waddr_gb3 = cnt131071;

            sram_wen_r0 = 1'b0;
            sram_wen_r2 = 1'b0;
            sram_wen_gb0 = 1'b0;
            sram_wen_gb1 = 1'b0;
            sram_wen_gb2 = 1'b0;
            sram_wen_gb3 = 1'b0;

            sram_wordmask_r0 = 4'b0101;
            sram_wordmask_r2 = 4'b0101;
            sram_wordmask_gb0 = 8'b1101_1101;
            sram_wordmask_gb1 = 8'b0110_0110;
            sram_wordmask_gb2 = 8'b1101_1101;
            sram_wordmask_gb3 = 8'b0110_0110;

            sram_wdata_r0 = {clipped[0], 16'b0, clipped[2], 16'b0};
            sram_wdata_r2 = {clipped[8], 16'b0, clipped[10], 16'b0};
            sram_wdata_gb0 = {16'b0, 16'b0, clipped[1], 16'd0, 16'd0, 16'd0, clipped[3], 16'd0};
            sram_wdata_gb1 = {clipped[4], 16'd0, 16'd0, clipped[5], clipped[6], 16'd0, 16'd0, clipped[7]};
            sram_wdata_gb2 = {16'b0, 16'b0, clipped[9], 16'd0, 16'd0, 16'd0, clipped[11], 16'd0};
            sram_wdata_gb3 = {clipped[12], 16'd0, 16'd0, clipped[13], clipped[14], 16'd0, 16'd0, clipped[15]};
        end
    endcase
end
endmodule
