module gamma # (
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16,
    parameter RGB_BW = 8,
    parameter HEIGHT = 1080,
    parameter WIDTH = 1920
) (
    input clk,
    input srst_n,
    input enable,
    output wire done,

    input [CH_NUM*LINEAR_BW-1:0] sram_rdata_r0,
    // input [CH_NUM*LINEAR_BW-1:0] sram_rdata_r1,
    // input [CH_NUM*LINEAR_BW-1:0] sram_rdata_r2,
    // input [CH_NUM*LINEAR_BW-1:0] sram_rdata_r3,
    input [CH_NUM*LINEAR_BW*2-1:0] sram_rdata_gb0,
    // input [CH_NUM*LINEAR_BW*2-1:0] sram_rdata_gb1,
    // input [CH_NUM*LINEAR_BW*2-1:0] sram_rdata_gb2,
    // input [CH_NUM*LINEAR_BW*2-1:0] sram_rdata_gb3,

    output reg [17-1:0] sram_raddr_gamma,
    output reg [17-1:0] sram_waddr_gamma,

    output reg sram_wen_gamma,

    output wire [CH_NUM-1:0] sram_wordmask_gamma_r,
    output wire [CH_NUM*2-1:0] sram_wordmask_gamma_gb,

    output wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r0,
    output wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r1,
    output wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r2,
    output wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r3,
    output wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb0,
    output wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb1,
    output wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb2,
    output wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb3,

    input wire [8-1:0] white_point,
    input wire wp_get,
    output wire gamma_hist_start,
    output wire gamma_cdf_begin,
    output wire [LINEAR_BW-1:0] gamma_hist_in,

    input wire [28-1:0] norm_r0_0_nx_tmp,
    input wire [28-1:0] norm_r0_1_nx_tmp,
    input wire [28-1:0] norm_r0_2_nx_tmp,
    input wire [28-1:0] norm_r0_3_nx_tmp,
    input wire [28-1:0] norm_r1_0_nx_tmp,
    input wire [28-1:0] norm_r1_1_nx_tmp,
    input wire [28-1:0] norm_r1_2_nx_tmp,
    input wire [28-1:0] norm_r1_3_nx_tmp,
    input wire [28-1:0] norm_r2_0_nx_tmp,
    input wire [28-1:0] norm_r2_1_nx_tmp,
    input wire [28-1:0] norm_r2_2_nx_tmp,
    input wire [28-1:0] norm_r2_3_nx_tmp,
    input wire [28-1:0] norm_r3_0_nx_tmp,
    input wire [28-1:0] norm_r3_1_nx_tmp,
    input wire [28-1:0] norm_r3_2_nx_tmp,
    input wire [28-1:0] norm_r3_3_nx_tmp,
    input wire [28-1:0] norm_g0_0_nx_tmp,
    input wire [28-1:0] norm_g0_1_nx_tmp,
    input wire [28-1:0] norm_g0_2_nx_tmp,
    input wire [28-1:0] norm_g0_3_nx_tmp,
    input wire [28-1:0] norm_g1_0_nx_tmp,
    input wire [28-1:0] norm_g1_1_nx_tmp,
    input wire [28-1:0] norm_g1_2_nx_tmp,
    input wire [28-1:0] norm_g1_3_nx_tmp,
    input wire [28-1:0] norm_g2_0_nx_tmp,
    input wire [28-1:0] norm_g2_1_nx_tmp,
    input wire [28-1:0] norm_g2_2_nx_tmp,
    input wire [28-1:0] norm_g2_3_nx_tmp,
    input wire [28-1:0] norm_g3_0_nx_tmp,
    input wire [28-1:0] norm_g3_1_nx_tmp,
    input wire [28-1:0] norm_g3_2_nx_tmp,
    input wire [28-1:0] norm_g3_3_nx_tmp,
    input wire [28-1:0] norm_b0_0_nx_tmp,
    input wire [28-1:0] norm_b0_1_nx_tmp,
    input wire [28-1:0] norm_b0_2_nx_tmp,
    input wire [28-1:0] norm_b0_3_nx_tmp,
    input wire [28-1:0] norm_b1_0_nx_tmp,
    input wire [28-1:0] norm_b1_1_nx_tmp,
    input wire [28-1:0] norm_b1_2_nx_tmp,
    input wire [28-1:0] norm_b1_3_nx_tmp,
    input wire [28-1:0] norm_b2_0_nx_tmp,
    input wire [28-1:0] norm_b2_1_nx_tmp,
    input wire [28-1:0] norm_b2_2_nx_tmp,
    input wire [28-1:0] norm_b2_3_nx_tmp,
    input wire [28-1:0] norm_b3_0_nx_tmp,
    input wire [28-1:0] norm_b3_1_nx_tmp,
    input wire [28-1:0] norm_b3_2_nx_tmp,
    input wire [28-1:0] norm_b3_3_nx_tmp,
    output reg [16-1:0] wp_inv
);

    localparam STEP = 20;
    localparam WIDTH_END = WIDTH / STEP;
    localparam ROW_END = HEIGHT / STEP;
    localparam BIN_NUM = 256;
    localparam BIN_BW = 13;
    localparam BIN_NUM_BW = 8;
    localparam QUOTIENT_B = 16;

    localparam  IDLE        = 3'd0,
                CAL_HIST    = 3'd1,
                WAIT_CDF    = 3'd2,
                CAL_WP      = 3'd3,
                NORM        = 3'd4,
                WAIT_WRITE  = 3'd5,
                DONE        = 3'd6;

    reg [17-1:0] sram_raddr_ff;
    reg [7-1:0] width_cnt, width_cnt_next;
    reg [6-1:0] row_cnt, row_cnt_next;
    
    
    wire cdf_begin_next = (row_cnt == ROW_END - 1 && width_cnt == WIDTH_END - 1);
    reg cdf_begin;
    wire match_done;
    reg [LINEAR_BW-1:0] hist_in;

    reg [2:0] state, state_nx;
    wire [QUOTIENT_B-1:0] div_out;
    reg [QUOTIENT_B-1:0] wp_inv_next;
    wire div_done;

    assign gamma_cdf_begin = cdf_begin;
    assign gamma_hist_start = state == CAL_HIST;
    assign gamma_hist_in = hist_in;

    wire norm_done = (sram_raddr_gamma == HEIGHT*WIDTH/16);
    wire write_done = (sram_waddr_gamma == HEIGHT*WIDTH/16);
    assign done = state == DONE;

    wire [LINEAR_BW-1:0] r_pixel = sram_rdata_r0[LINEAR_BW*3 +: LINEAR_BW];
    wire [LINEAR_BW-1:0] g_pixel = sram_rdata_gb0[LINEAR_BW*7 +: LINEAR_BW];
    wire [LINEAR_BW-1:0] b_pixel = sram_rdata_gb0[LINEAR_BW*6 +: LINEAR_BW];

    reg [11-1:0] norm_r0_0, norm_r0_1, norm_r0_2, norm_r0_3;
    reg [11-1:0] norm_r1_0, norm_r1_1, norm_r1_2, norm_r1_3;
    reg [11-1:0] norm_r2_0, norm_r2_1, norm_r2_2, norm_r2_3;
    reg [11-1:0] norm_r3_0, norm_r3_1, norm_r3_2, norm_r3_3;

    reg [11-1:0] norm_g0_0, norm_g0_1, norm_g0_2, norm_g0_3;
    reg [11-1:0] norm_g1_0, norm_g1_1, norm_g1_2, norm_g1_3;
    reg [11-1:0] norm_g2_0, norm_g2_1, norm_g2_2, norm_g2_3;
    reg [11-1:0] norm_g3_0, norm_g3_1, norm_g3_2, norm_g3_3;

    reg [11-1:0] norm_b0_0, norm_b0_1, norm_b0_2, norm_b0_3;
    reg [11-1:0] norm_b1_0, norm_b1_1, norm_b1_2, norm_b1_3;
    reg [11-1:0] norm_b2_0, norm_b2_1, norm_b2_2, norm_b2_3;
    reg [11-1:0] norm_b3_0, norm_b3_1, norm_b3_2, norm_b3_3;

    // wire [28-1:0] norm_r0_0_nx_tmp = sram_rdata_r0[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r0_1_nx_tmp = sram_rdata_r0[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r0_2_nx_tmp = sram_rdata_r0[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r0_3_nx_tmp = sram_rdata_r0[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r1_0_nx_tmp = sram_rdata_r1[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r1_1_nx_tmp = sram_rdata_r1[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r1_2_nx_tmp = sram_rdata_r1[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r1_3_nx_tmp = sram_rdata_r1[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r2_0_nx_tmp = sram_rdata_r2[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r2_1_nx_tmp = sram_rdata_r2[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r2_2_nx_tmp = sram_rdata_r2[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r2_3_nx_tmp = sram_rdata_r2[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r3_0_nx_tmp = sram_rdata_r3[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r3_1_nx_tmp = sram_rdata_r3[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r3_2_nx_tmp = sram_rdata_r3[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_r3_3_nx_tmp = sram_rdata_r3[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;

    // wire [28-1:0] norm_g0_0_nx_tmp = sram_rdata_gb0[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g0_1_nx_tmp = sram_rdata_gb0[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g0_2_nx_tmp = sram_rdata_gb0[LINEAR_BW*5 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g0_3_nx_tmp = sram_rdata_gb0[LINEAR_BW*7 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g1_0_nx_tmp = sram_rdata_gb1[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g1_1_nx_tmp = sram_rdata_gb1[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g1_2_nx_tmp = sram_rdata_gb1[LINEAR_BW*5 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g1_3_nx_tmp = sram_rdata_gb1[LINEAR_BW*7 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g2_0_nx_tmp = sram_rdata_gb2[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g2_1_nx_tmp = sram_rdata_gb2[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g2_2_nx_tmp = sram_rdata_gb2[LINEAR_BW*5 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g2_3_nx_tmp = sram_rdata_gb2[LINEAR_BW*7 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g3_0_nx_tmp = sram_rdata_gb3[LINEAR_BW*1 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g3_1_nx_tmp = sram_rdata_gb3[LINEAR_BW*3 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g3_2_nx_tmp = sram_rdata_gb3[LINEAR_BW*5 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_g3_3_nx_tmp = sram_rdata_gb3[LINEAR_BW*7 +: LINEAR_BW] * wp_inv;

    // wire [28-1:0] norm_b0_0_nx_tmp = sram_rdata_gb0[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b0_1_nx_tmp = sram_rdata_gb0[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b0_2_nx_tmp = sram_rdata_gb0[LINEAR_BW*4 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b0_3_nx_tmp = sram_rdata_gb0[LINEAR_BW*6 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b1_0_nx_tmp = sram_rdata_gb1[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b1_1_nx_tmp = sram_rdata_gb1[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b1_2_nx_tmp = sram_rdata_gb1[LINEAR_BW*4 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b1_3_nx_tmp = sram_rdata_gb1[LINEAR_BW*6 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b2_0_nx_tmp = sram_rdata_gb2[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b2_1_nx_tmp = sram_rdata_gb2[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b2_2_nx_tmp = sram_rdata_gb2[LINEAR_BW*4 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b2_3_nx_tmp = sram_rdata_gb2[LINEAR_BW*6 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b3_0_nx_tmp = sram_rdata_gb3[LINEAR_BW*0 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b3_1_nx_tmp = sram_rdata_gb3[LINEAR_BW*2 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b3_2_nx_tmp = sram_rdata_gb3[LINEAR_BW*4 +: LINEAR_BW] * wp_inv;
    // wire [28-1:0] norm_b3_3_nx_tmp = sram_rdata_gb3[LINEAR_BW*6 +: LINEAR_BW] * wp_inv;

    wire [11-1:0] norm_r0_0_nx = norm_r0_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r0_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r0_1_nx = norm_r0_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r0_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r0_2_nx = norm_r0_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r0_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r0_3_nx = norm_r0_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r0_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r1_0_nx = norm_r1_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r1_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r1_1_nx = norm_r1_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r1_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r1_2_nx = norm_r1_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r1_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r1_3_nx = norm_r1_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r1_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r2_0_nx = norm_r2_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r2_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r2_1_nx = norm_r2_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r2_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r2_2_nx = norm_r2_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r2_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r2_3_nx = norm_r2_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r2_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r3_0_nx = norm_r3_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r3_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r3_1_nx = norm_r3_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r3_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r3_2_nx = norm_r3_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r3_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_r3_3_nx = norm_r3_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_r3_3_nx_tmp[24 -: 11];

    wire [11-1:0] norm_g0_0_nx = norm_g0_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g0_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g0_1_nx = norm_g0_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g0_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g0_2_nx = norm_g0_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g0_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g0_3_nx = norm_g0_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g0_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g1_0_nx = norm_g1_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g1_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g1_1_nx = norm_g1_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g1_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g1_2_nx = norm_g1_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g1_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g1_3_nx = norm_g1_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g1_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g2_0_nx = norm_g2_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g2_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g2_1_nx = norm_g2_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g2_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g2_2_nx = norm_g2_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g2_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g2_3_nx = norm_g2_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g2_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g3_0_nx = norm_g3_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g3_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g3_1_nx = norm_g3_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g3_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g3_2_nx = norm_g3_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g3_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_g3_3_nx = norm_g3_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_g3_3_nx_tmp[24 -: 11];

    wire [11-1:0] norm_b0_0_nx = norm_b0_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b0_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b0_1_nx = norm_b0_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b0_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b0_2_nx = norm_b0_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b0_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b0_3_nx = norm_b0_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b0_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b1_0_nx = norm_b1_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b1_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b1_1_nx = norm_b1_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b1_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b1_2_nx = norm_b1_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b1_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b1_3_nx = norm_b1_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b1_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b2_0_nx = norm_b2_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b2_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b2_1_nx = norm_b2_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b2_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b2_2_nx = norm_b2_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b2_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b2_3_nx = norm_b2_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b2_3_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b3_0_nx = norm_b3_0_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b3_0_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b3_1_nx = norm_b3_1_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b3_1_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b3_2_nx = norm_b3_2_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b3_2_nx_tmp[24 -: 11];
    wire [11-1:0] norm_b3_3_nx = norm_b3_3_nx_tmp[27:24] != 0 ? 11'd1024 : norm_b3_3_nx_tmp[24 -: 11];

    wire [11-1:0] gamma_out_r0_0, gamma_out_r0_1, gamma_out_r0_2, gamma_out_r0_3;
    wire [11-1:0] gamma_out_r1_0, gamma_out_r1_1, gamma_out_r1_2, gamma_out_r1_3;
    wire [11-1:0] gamma_out_r2_0, gamma_out_r2_1, gamma_out_r2_2, gamma_out_r2_3;
    wire [11-1:0] gamma_out_r3_0, gamma_out_r3_1, gamma_out_r3_2, gamma_out_r3_3;
    wire [11-1:0] gamma_out_g0_0, gamma_out_g0_1, gamma_out_g0_2, gamma_out_g0_3;
    wire [11-1:0] gamma_out_g1_0, gamma_out_g1_1, gamma_out_g1_2, gamma_out_g1_3;
    wire [11-1:0] gamma_out_g2_0, gamma_out_g2_1, gamma_out_g2_2, gamma_out_g2_3;
    wire [11-1:0] gamma_out_g3_0, gamma_out_g3_1, gamma_out_g3_2, gamma_out_g3_3;
    wire [11-1:0] gamma_out_b0_0, gamma_out_b0_1, gamma_out_b0_2, gamma_out_b0_3;
    wire [11-1:0] gamma_out_b1_0, gamma_out_b1_1, gamma_out_b1_2, gamma_out_b1_3;
    wire [11-1:0] gamma_out_b2_0, gamma_out_b2_1, gamma_out_b2_2, gamma_out_b2_3;
    wire [11-1:0] gamma_out_b3_0, gamma_out_b3_1, gamma_out_b3_2, gamma_out_b3_3;


    reg [1:0] wen_buf;
    reg [17*2-1:0] waddr_buf;

    assign sram_wordmask_gamma_r = sram_wen_gamma ? 4'hF : 4'h0;
    assign sram_wordmask_gamma_gb = sram_wen_gamma ? 8'hFF : 8'h00;

    wire [19-1:0] rgb_out_r0_0_tmp = gamma_out_r0_0 * 9'h1FF;
    wire [19-1:0] rgb_out_r0_1_tmp = gamma_out_r0_1 * 9'h1FF;
    wire [19-1:0] rgb_out_r0_2_tmp = gamma_out_r0_2 * 9'h1FF;
    wire [19-1:0] rgb_out_r0_3_tmp = gamma_out_r0_3 * 9'h1FF;
    wire [19-1:0] rgb_out_r1_0_tmp = gamma_out_r1_0 * 9'h1FF;
    wire [19-1:0] rgb_out_r1_1_tmp = gamma_out_r1_1 * 9'h1FF;
    wire [19-1:0] rgb_out_r1_2_tmp = gamma_out_r1_2 * 9'h1FF;
    wire [19-1:0] rgb_out_r1_3_tmp = gamma_out_r1_3 * 9'h1FF;
    wire [19-1:0] rgb_out_r2_0_tmp = gamma_out_r2_0 * 9'h1FF;
    wire [19-1:0] rgb_out_r2_1_tmp = gamma_out_r2_1 * 9'h1FF;
    wire [19-1:0] rgb_out_r2_2_tmp = gamma_out_r2_2 * 9'h1FF;
    wire [19-1:0] rgb_out_r2_3_tmp = gamma_out_r2_3 * 9'h1FF;
    wire [19-1:0] rgb_out_r3_0_tmp = gamma_out_r3_0 * 9'h1FF;
    wire [19-1:0] rgb_out_r3_1_tmp = gamma_out_r3_1 * 9'h1FF;
    wire [19-1:0] rgb_out_r3_2_tmp = gamma_out_r3_2 * 9'h1FF;
    wire [19-1:0] rgb_out_r3_3_tmp = gamma_out_r3_3 * 9'h1FF;
    wire [19-1:0] rgb_out_g0_0_tmp = gamma_out_g0_0 * 9'h1FF;
    wire [19-1:0] rgb_out_g0_1_tmp = gamma_out_g0_1 * 9'h1FF;
    wire [19-1:0] rgb_out_g0_2_tmp = gamma_out_g0_2 * 9'h1FF;
    wire [19-1:0] rgb_out_g0_3_tmp = gamma_out_g0_3 * 9'h1FF;
    wire [19-1:0] rgb_out_g1_0_tmp = gamma_out_g1_0 * 9'h1FF;
    wire [19-1:0] rgb_out_g1_1_tmp = gamma_out_g1_1 * 9'h1FF;
    wire [19-1:0] rgb_out_g1_2_tmp = gamma_out_g1_2 * 9'h1FF;
    wire [19-1:0] rgb_out_g1_3_tmp = gamma_out_g1_3 * 9'h1FF;
    wire [19-1:0] rgb_out_g2_0_tmp = gamma_out_g2_0 * 9'h1FF;
    wire [19-1:0] rgb_out_g2_1_tmp = gamma_out_g2_1 * 9'h1FF;
    wire [19-1:0] rgb_out_g2_2_tmp = gamma_out_g2_2 * 9'h1FF;
    wire [19-1:0] rgb_out_g2_3_tmp = gamma_out_g2_3 * 9'h1FF;
    wire [19-1:0] rgb_out_g3_0_tmp = gamma_out_g3_0 * 9'h1FF;
    wire [19-1:0] rgb_out_g3_1_tmp = gamma_out_g3_1 * 9'h1FF;
    wire [19-1:0] rgb_out_g3_2_tmp = gamma_out_g3_2 * 9'h1FF;
    wire [19-1:0] rgb_out_g3_3_tmp = gamma_out_g3_3 * 9'h1FF;
    wire [19-1:0] rgb_out_b0_0_tmp = gamma_out_b0_0 * 9'h1FF;
    wire [19-1:0] rgb_out_b0_1_tmp = gamma_out_b0_1 * 9'h1FF;
    wire [19-1:0] rgb_out_b0_2_tmp = gamma_out_b0_2 * 9'h1FF;
    wire [19-1:0] rgb_out_b0_3_tmp = gamma_out_b0_3 * 9'h1FF;
    wire [19-1:0] rgb_out_b1_0_tmp = gamma_out_b1_0 * 9'h1FF;
    wire [19-1:0] rgb_out_b1_1_tmp = gamma_out_b1_1 * 9'h1FF;
    wire [19-1:0] rgb_out_b1_2_tmp = gamma_out_b1_2 * 9'h1FF;
    wire [19-1:0] rgb_out_b1_3_tmp = gamma_out_b1_3 * 9'h1FF;
    wire [19-1:0] rgb_out_b2_0_tmp = gamma_out_b2_0 * 9'h1FF;
    wire [19-1:0] rgb_out_b2_1_tmp = gamma_out_b2_1 * 9'h1FF;
    wire [19-1:0] rgb_out_b2_2_tmp = gamma_out_b2_2 * 9'h1FF;
    wire [19-1:0] rgb_out_b2_3_tmp = gamma_out_b2_3 * 9'h1FF;
    wire [19-1:0] rgb_out_b3_0_tmp = gamma_out_b3_0 * 9'h1FF;
    wire [19-1:0] rgb_out_b3_1_tmp = gamma_out_b3_1 * 9'h1FF;
    wire [19-1:0] rgb_out_b3_2_tmp = gamma_out_b3_2 * 9'h1FF;
    wire [19-1:0] rgb_out_b3_3_tmp = gamma_out_b3_3 * 9'h1FF;

    wire [RGB_BW-1:0] rgb_out_r0_0 = rgb_out_r0_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r0_1 = rgb_out_r0_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r0_2 = rgb_out_r0_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r0_3 = rgb_out_r0_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r1_0 = rgb_out_r1_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r1_1 = rgb_out_r1_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r1_2 = rgb_out_r1_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r1_3 = rgb_out_r1_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r2_0 = rgb_out_r2_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r2_1 = rgb_out_r2_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r2_2 = rgb_out_r2_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r2_3 = rgb_out_r2_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r3_0 = rgb_out_r3_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r3_1 = rgb_out_r3_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r3_2 = rgb_out_r3_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_r3_3 = rgb_out_r3_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g0_0 = rgb_out_g0_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g0_1 = rgb_out_g0_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g0_2 = rgb_out_g0_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g0_3 = rgb_out_g0_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g1_0 = rgb_out_g1_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g1_1 = rgb_out_g1_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g1_2 = rgb_out_g1_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g1_3 = rgb_out_g1_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g2_0 = rgb_out_g2_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g2_1 = rgb_out_g2_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g2_2 = rgb_out_g2_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g2_3 = rgb_out_g2_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g3_0 = rgb_out_g3_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g3_1 = rgb_out_g3_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g3_2 = rgb_out_g3_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_g3_3 = rgb_out_g3_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b0_0 = rgb_out_b0_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b0_1 = rgb_out_b0_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b0_2 = rgb_out_b0_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b0_3 = rgb_out_b0_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b1_0 = rgb_out_b1_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b1_1 = rgb_out_b1_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b1_2 = rgb_out_b1_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b1_3 = rgb_out_b1_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b2_0 = rgb_out_b2_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b2_1 = rgb_out_b2_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b2_2 = rgb_out_b2_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b2_3 = rgb_out_b2_3_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b3_0 = rgb_out_b3_0_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b3_1 = rgb_out_b3_1_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b3_2 = rgb_out_b3_2_tmp[18 -: RGB_BW];
    wire [RGB_BW-1:0] rgb_out_b3_3 = rgb_out_b3_3_tmp[18 -: RGB_BW];

    // reg [RGB_BW-1:0] rgb_out_r0_0, rgb_out_r0_1, rgb_out_r0_2, rgb_out_r0_3;
    // reg [RGB_BW-1:0] rgb_out_r1_0, rgb_out_r1_1, rgb_out_r1_2, rgb_out_r1_3;
    // reg [RGB_BW-1:0] rgb_out_r2_0, rgb_out_r2_1, rgb_out_r2_2, rgb_out_r2_3;
    // reg [RGB_BW-1:0] rgb_out_r3_0, rgb_out_r3_1, rgb_out_r3_2, rgb_out_r3_3;

    // reg [RGB_BW-1:0] rgb_out_g0_0, rgb_out_g0_1, rgb_out_g0_2, rgb_out_g0_3;
    // reg [RGB_BW-1:0] rgb_out_g1_0, rgb_out_g1_1, rgb_out_g1_2, rgb_out_g1_3;
    // reg [RGB_BW-1:0] rgb_out_g2_0, rgb_out_g2_1, rgb_out_g2_2, rgb_out_g2_3;
    // reg [RGB_BW-1:0] rgb_out_g3_0, rgb_out_g3_1, rgb_out_g3_2, rgb_out_g3_3;

    // reg [RGB_BW-1:0] rgb_out_b0_0, rgb_out_b0_1, rgb_out_b0_2, rgb_out_b0_3;
    // reg [RGB_BW-1:0] rgb_out_b1_0, rgb_out_b1_1, rgb_out_b1_2, rgb_out_b1_3;
    // reg [RGB_BW-1:0] rgb_out_b2_0, rgb_out_b2_1, rgb_out_b2_2, rgb_out_b2_3;
    // reg [RGB_BW-1:0] rgb_out_b3_0, rgb_out_b3_1, rgb_out_b3_2, rgb_out_b3_3;

    assign sram_wdata_r0 = {8'd0, rgb_out_r0_3, 
                            8'd0, rgb_out_r0_2,
                            8'd0, rgb_out_r0_1,
                            8'd0, rgb_out_r0_0};
    assign sram_wdata_r1 = {8'd0, rgb_out_r1_3, 
                            8'd0, rgb_out_r1_2,
                            8'd0, rgb_out_r1_1,
                            8'd0, rgb_out_r1_0};
    assign sram_wdata_r2 = {8'd0, rgb_out_r2_3, 
                            8'd0, rgb_out_r2_2,
                            8'd0, rgb_out_r2_1,
                            8'd0, rgb_out_r2_0};
    assign sram_wdata_r3 = {8'd0, rgb_out_r3_3, 
                            8'd0, rgb_out_r3_2,
                            8'd0, rgb_out_r3_1,
                            8'd0, rgb_out_r3_0};

    assign sram_wdata_gb0 = {8'd0, rgb_out_g0_3, 8'd0, rgb_out_b0_3,
                             8'd0, rgb_out_g0_2, 8'd0, rgb_out_b0_2,
                             8'd0, rgb_out_g0_1, 8'd0, rgb_out_b0_1,
                             8'd0, rgb_out_g0_0, 8'd0, rgb_out_b0_0};
    assign sram_wdata_gb1 = {8'd0, rgb_out_g1_3, 8'd0, rgb_out_b1_3,
                             8'd0, rgb_out_g1_2, 8'd0, rgb_out_b1_2,
                             8'd0, rgb_out_g1_1, 8'd0, rgb_out_b1_1,
                             8'd0, rgb_out_g1_0, 8'd0, rgb_out_b1_0};
    assign sram_wdata_gb2 = {8'd0, rgb_out_g2_3, 8'd0, rgb_out_b2_3,
                             8'd0, rgb_out_g2_2, 8'd0, rgb_out_b2_2,
                             8'd0, rgb_out_g2_1, 8'd0, rgb_out_b2_1,
                             8'd0, rgb_out_g2_0, 8'd0, rgb_out_b2_0};
    assign sram_wdata_gb3 = {8'd0, rgb_out_g3_3, 8'd0, rgb_out_b3_3,
                             8'd0, rgb_out_g3_2, 8'd0, rgb_out_b3_2,
                             8'd0, rgb_out_g3_1, 8'd0, rgb_out_b3_1,
                             8'd0, rgb_out_g3_0, 8'd0, rgb_out_b3_0};

    // width_cnt
    always @* begin
        if (state == CAL_HIST)
            if (width_cnt == WIDTH_END - 1)
                width_cnt_next = 0;
            else
                width_cnt_next = width_cnt + 1;
        else
            width_cnt_next = 0;
    end

    // row_cnt
    always @* begin
        if (state == CAL_HIST)
            if (width_cnt == WIDTH_END - 1)
                row_cnt_next = row_cnt + 1;
            else
                row_cnt_next = row_cnt;
        else
            row_cnt_next = 0;
    end

    // sram_raddr
    always @* begin
        if (state == CAL_HIST)
            if (width_cnt == WIDTH_END - 1)
                if (row_cnt == ROW_END - 1)
                    sram_raddr_gamma = 0;
                else
                    sram_raddr_gamma = sram_raddr_ff + (WIDTH + 5);
            else
                sram_raddr_gamma = sram_raddr_ff + 5;
        else if (state == NORM)
            sram_raddr_gamma = sram_raddr_ff + 1;
        else
            sram_raddr_gamma = 0;
    end

    // hist_in
    always @* begin
        if (r_pixel > g_pixel)
            if (r_pixel > b_pixel)
                hist_in = r_pixel;
            else
                hist_in = b_pixel;
        else
            if (g_pixel > b_pixel)
                hist_in = g_pixel;
            else
                hist_in = b_pixel;
    end

    // wp_inv
    always @* begin
        if (div_done)
            wp_inv_next = div_out;
        else if (state == NORM)
            wp_inv_next = wp_inv;
        else
            wp_inv_next = 0;
    end

    // FSM
    always @* begin
        case (state) // synopsys parallel_case full_case
            IDLE:
                if (enable)         state_nx = CAL_HIST;
                else                state_nx = IDLE;
            CAL_HIST:
                if (cdf_begin_next) state_nx = WAIT_CDF;
                else                state_nx = CAL_HIST;
            WAIT_CDF:
                if (wp_get)         state_nx = CAL_WP;
                else                state_nx = WAIT_CDF;
            CAL_WP:                 
                if (div_done)       state_nx = NORM;
                else                state_nx = CAL_WP;
            NORM:                   
                if (norm_done)      state_nx = WAIT_WRITE;
                else                state_nx = NORM;
            WAIT_WRITE:
                if (write_done)     state_nx = DONE;
                else                state_nx = WAIT_WRITE;
            DONE:                   state_nx = DONE;
        endcase
    end

//-----------Submodule------------//

    divider_uu # (
        .DIVIDEND_B(17),
        .DIVIDER_B(8),
        .QUOTIENT_B(QUOTIENT_B)
    ) DIV_U0 (
        .clk(clk),
        .en(state == CAL_WP),
        .dividend(17'b1_0000_0000_0000_0000),
        .divider(white_point),
        .quotient(div_out),
        .done(div_done)
    );

//--------------LUT---------------//

gamma_lut GAMMA_LUT_R0_0 ( .clk(clk), .num(norm_r0_0), .lut_out(gamma_out_r0_0));
gamma_lut GAMMA_LUT_R0_1 ( .clk(clk), .num(norm_r0_1), .lut_out(gamma_out_r0_1));
gamma_lut GAMMA_LUT_R0_2 ( .clk(clk), .num(norm_r0_2), .lut_out(gamma_out_r0_2));
gamma_lut GAMMA_LUT_R0_3 ( .clk(clk), .num(norm_r0_3), .lut_out(gamma_out_r0_3));
gamma_lut GAMMA_LUT_R1_0 ( .clk(clk), .num(norm_r1_0), .lut_out(gamma_out_r1_0));
gamma_lut GAMMA_LUT_R1_1 ( .clk(clk), .num(norm_r1_1), .lut_out(gamma_out_r1_1));
gamma_lut GAMMA_LUT_R1_2 ( .clk(clk), .num(norm_r1_2), .lut_out(gamma_out_r1_2));
gamma_lut GAMMA_LUT_R1_3 ( .clk(clk), .num(norm_r1_3), .lut_out(gamma_out_r1_3));
gamma_lut GAMMA_LUT_R2_0 ( .clk(clk), .num(norm_r2_0), .lut_out(gamma_out_r2_0));
gamma_lut GAMMA_LUT_R2_1 ( .clk(clk), .num(norm_r2_1), .lut_out(gamma_out_r2_1));
gamma_lut GAMMA_LUT_R2_2 ( .clk(clk), .num(norm_r2_2), .lut_out(gamma_out_r2_2));
gamma_lut GAMMA_LUT_R2_3 ( .clk(clk), .num(norm_r2_3), .lut_out(gamma_out_r2_3));
gamma_lut GAMMA_LUT_R3_0 ( .clk(clk), .num(norm_r3_0), .lut_out(gamma_out_r3_0));
gamma_lut GAMMA_LUT_R3_1 ( .clk(clk), .num(norm_r3_1), .lut_out(gamma_out_r3_1));
gamma_lut GAMMA_LUT_R3_2 ( .clk(clk), .num(norm_r3_2), .lut_out(gamma_out_r3_2));
gamma_lut GAMMA_LUT_R3_3 ( .clk(clk), .num(norm_r3_3), .lut_out(gamma_out_r3_3));
gamma_lut GAMMA_LUT_G0_0 ( .clk(clk), .num(norm_g0_0), .lut_out(gamma_out_g0_0));
gamma_lut GAMMA_LUT_G0_1 ( .clk(clk), .num(norm_g0_1), .lut_out(gamma_out_g0_1));
gamma_lut GAMMA_LUT_G0_2 ( .clk(clk), .num(norm_g0_2), .lut_out(gamma_out_g0_2));
gamma_lut GAMMA_LUT_G0_3 ( .clk(clk), .num(norm_g0_3), .lut_out(gamma_out_g0_3));
gamma_lut GAMMA_LUT_G1_0 ( .clk(clk), .num(norm_g1_0), .lut_out(gamma_out_g1_0));
gamma_lut GAMMA_LUT_G1_1 ( .clk(clk), .num(norm_g1_1), .lut_out(gamma_out_g1_1));
gamma_lut GAMMA_LUT_G1_2 ( .clk(clk), .num(norm_g1_2), .lut_out(gamma_out_g1_2));
gamma_lut GAMMA_LUT_G1_3 ( .clk(clk), .num(norm_g1_3), .lut_out(gamma_out_g1_3));
gamma_lut GAMMA_LUT_G2_0 ( .clk(clk), .num(norm_g2_0), .lut_out(gamma_out_g2_0));
gamma_lut GAMMA_LUT_G2_1 ( .clk(clk), .num(norm_g2_1), .lut_out(gamma_out_g2_1));
gamma_lut GAMMA_LUT_G2_2 ( .clk(clk), .num(norm_g2_2), .lut_out(gamma_out_g2_2));
gamma_lut GAMMA_LUT_G2_3 ( .clk(clk), .num(norm_g2_3), .lut_out(gamma_out_g2_3));
gamma_lut GAMMA_LUT_G3_0 ( .clk(clk), .num(norm_g3_0), .lut_out(gamma_out_g3_0));
gamma_lut GAMMA_LUT_G3_1 ( .clk(clk), .num(norm_g3_1), .lut_out(gamma_out_g3_1));
gamma_lut GAMMA_LUT_G3_2 ( .clk(clk), .num(norm_g3_2), .lut_out(gamma_out_g3_2));
gamma_lut GAMMA_LUT_G3_3 ( .clk(clk), .num(norm_g3_3), .lut_out(gamma_out_g3_3));
gamma_lut GAMMA_LUT_B0_0 ( .clk(clk), .num(norm_b0_0), .lut_out(gamma_out_b0_0));
gamma_lut GAMMA_LUT_B0_1 ( .clk(clk), .num(norm_b0_1), .lut_out(gamma_out_b0_1));
gamma_lut GAMMA_LUT_B0_2 ( .clk(clk), .num(norm_b0_2), .lut_out(gamma_out_b0_2));
gamma_lut GAMMA_LUT_B0_3 ( .clk(clk), .num(norm_b0_3), .lut_out(gamma_out_b0_3));
gamma_lut GAMMA_LUT_B1_0 ( .clk(clk), .num(norm_b1_0), .lut_out(gamma_out_b1_0));
gamma_lut GAMMA_LUT_B1_1 ( .clk(clk), .num(norm_b1_1), .lut_out(gamma_out_b1_1));
gamma_lut GAMMA_LUT_B1_2 ( .clk(clk), .num(norm_b1_2), .lut_out(gamma_out_b1_2));
gamma_lut GAMMA_LUT_B1_3 ( .clk(clk), .num(norm_b1_3), .lut_out(gamma_out_b1_3));
gamma_lut GAMMA_LUT_B2_0 ( .clk(clk), .num(norm_b2_0), .lut_out(gamma_out_b2_0));
gamma_lut GAMMA_LUT_B2_1 ( .clk(clk), .num(norm_b2_1), .lut_out(gamma_out_b2_1));
gamma_lut GAMMA_LUT_B2_2 ( .clk(clk), .num(norm_b2_2), .lut_out(gamma_out_b2_2));
gamma_lut GAMMA_LUT_B2_3 ( .clk(clk), .num(norm_b2_3), .lut_out(gamma_out_b2_3));
gamma_lut GAMMA_LUT_B3_0 ( .clk(clk), .num(norm_b3_0), .lut_out(gamma_out_b3_0));
gamma_lut GAMMA_LUT_B3_1 ( .clk(clk), .num(norm_b3_1), .lut_out(gamma_out_b3_1));
gamma_lut GAMMA_LUT_B3_2 ( .clk(clk), .num(norm_b3_2), .lut_out(gamma_out_b3_2));
gamma_lut GAMMA_LUT_B3_3 ( .clk(clk), .num(norm_b3_3), .lut_out(gamma_out_b3_3));

//-----------Sequential-----------//

    always @(posedge clk) begin
        if (~srst_n) begin
            state           <= IDLE;
        end
        else begin
            state           <= state_nx;
        end
    end

    always @(posedge clk) begin
        width_cnt           <= width_cnt_next;
        row_cnt             <= row_cnt_next;
        sram_raddr_ff       <= sram_raddr_gamma;
        cdf_begin           <= cdf_begin_next;
        wp_inv              <= wp_inv_next;
        
        wen_buf             <= {wen_buf[0], state != NORM};
        sram_wen_gamma      <= wen_buf[1];
        waddr_buf           <= {waddr_buf[17-1:0], sram_raddr_ff};
        sram_waddr_gamma    <= waddr_buf[17*2-1:17];

        norm_r0_0           <= norm_r0_0_nx;
        norm_r0_1           <= norm_r0_1_nx;
        norm_r0_2           <= norm_r0_2_nx;
        norm_r0_3           <= norm_r0_3_nx;
        norm_r1_0           <= norm_r1_0_nx;
        norm_r1_1           <= norm_r1_1_nx;
        norm_r1_2           <= norm_r1_2_nx;
        norm_r1_3           <= norm_r1_3_nx;
        norm_r2_0           <= norm_r2_0_nx;
        norm_r2_1           <= norm_r2_1_nx;
        norm_r2_2           <= norm_r2_2_nx;
        norm_r2_3           <= norm_r2_3_nx;
        norm_r3_0           <= norm_r3_0_nx;
        norm_r3_1           <= norm_r3_1_nx;
        norm_r3_2           <= norm_r3_2_nx;
        norm_r3_3           <= norm_r3_3_nx;
        norm_g0_0           <= norm_g0_0_nx;
        norm_g0_1           <= norm_g0_1_nx;
        norm_g0_2           <= norm_g0_2_nx;
        norm_g0_3           <= norm_g0_3_nx;
        norm_g1_0           <= norm_g1_0_nx;
        norm_g1_1           <= norm_g1_1_nx;
        norm_g1_2           <= norm_g1_2_nx;
        norm_g1_3           <= norm_g1_3_nx;
        norm_g2_0           <= norm_g2_0_nx;
        norm_g2_1           <= norm_g2_1_nx;
        norm_g2_2           <= norm_g2_2_nx;
        norm_g2_3           <= norm_g2_3_nx;
        norm_g3_0           <= norm_g3_0_nx;
        norm_g3_1           <= norm_g3_1_nx;
        norm_g3_2           <= norm_g3_2_nx;
        norm_g3_3           <= norm_g3_3_nx;
        norm_b0_0           <= norm_b0_0_nx;
        norm_b0_1           <= norm_b0_1_nx;
        norm_b0_2           <= norm_b0_2_nx;
        norm_b0_3           <= norm_b0_3_nx;
        norm_b1_0           <= norm_b1_0_nx;
        norm_b1_1           <= norm_b1_1_nx;
        norm_b1_2           <= norm_b1_2_nx;
        norm_b1_3           <= norm_b1_3_nx;
        norm_b2_0           <= norm_b2_0_nx;
        norm_b2_1           <= norm_b2_1_nx;
        norm_b2_2           <= norm_b2_2_nx;
        norm_b2_3           <= norm_b2_3_nx;
        norm_b3_0           <= norm_b3_0_nx;
        norm_b3_1           <= norm_b3_1_nx;
        norm_b3_2           <= norm_b3_2_nx;
        norm_b3_3           <= norm_b3_3_nx;
    end

endmodule