module top #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16,
    parameter RGB_BW = 8,
    parameter CBCR_BW = 16,
    parameter HEIGHT = 1080,
    parameter WIDTH = 1920,
    parameter BIN_BW = 13
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output wire valid,

    // SRAM read data inputs 
    // SRAM_R for red channel
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r0,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r1,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r2,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r3,
    // SRAM_GB for green/blue channel 31~16:G ; 15~0:B
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb0,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb1,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb2,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb3,
    // SRAM_FY for reference Y channel
    input wire [RGB_BW*CH_NUM-1:0] sram_rdata_fy0,
    input wire [RGB_BW*CH_NUM-1:0] sram_rdata_fy1,
    input wire [RGB_BW*CH_NUM-1:0] sram_rdata_fy2,
    input wire [RGB_BW*CH_NUM-1:0] sram_rdata_fy3,
    // SRAM_FY for reference CbCr channel
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc0,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc1,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc2,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc3,

    // SRAM read address outputs -> 1920*1080/16
    output reg [17-1:0] sram_raddr_r0,
    output reg [17-1:0] sram_raddr_r1,
    output reg [17-1:0] sram_raddr_r2,
    output reg [17-1:0] sram_raddr_r3,
   
    output reg [17-1:0] sram_raddr_gb0,
    output reg [17-1:0] sram_raddr_gb1,
    output reg [17-1:0] sram_raddr_gb2,
    output reg [17-1:0] sram_raddr_gb3,
    
    output reg [17-1:0] sram_raddr_fy0,
    output reg [17-1:0] sram_raddr_fy1,
    output reg [17-1:0] sram_raddr_fy2,
    output reg [17-1:0] sram_raddr_fy3,
   
    output reg [17-1:0] sram_raddr_fc0,
    output reg [17-1:0] sram_raddr_fc1,
    output reg [17-1:0] sram_raddr_fc2,
    output reg [17-1:0] sram_raddr_fc3,

    // SRAM write address outputs -> 1920*1080/16
    output reg [17-1:0] sram_waddr_r0,
    output reg [17-1:0] sram_waddr_r1,
    output reg [17-1:0] sram_waddr_r2,
    output reg [17-1:0] sram_waddr_r3,

    output reg [17-1:0] sram_waddr_gb0,
    output reg [17-1:0] sram_waddr_gb1,
    output reg [17-1:0] sram_waddr_gb2,
    output reg [17-1:0] sram_waddr_gb3,

    output reg [17-1:0] sram_waddr_fy0,
    output reg [17-1:0] sram_waddr_fy1,
    output reg [17-1:0] sram_waddr_fy2,
    output reg [17-1:0] sram_waddr_fy3,

    output reg [17-1:0] sram_waddr_fc0,
    output reg [17-1:0] sram_waddr_fc1,
    output reg [17-1:0] sram_waddr_fc2,
    output reg [17-1:0] sram_waddr_fc3,

    // SRAM write enable outputs (neg.)
    output reg sram_wen_r0,
    output reg sram_wen_r1,
    output reg sram_wen_r2,
    output reg sram_wen_r3,

    output reg sram_wen_gb0,
    output reg sram_wen_gb1,
    output reg sram_wen_gb2,
    output reg sram_wen_gb3,

    output reg sram_wen_fy0,
    output reg sram_wen_fy1,
    output reg sram_wen_fy2,
    output reg sram_wen_fy3,

    output reg sram_wen_fc0,
    output reg sram_wen_fc1,
    output reg sram_wen_fc2,
    output reg sram_wen_fc3,

    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    output reg [CH_NUM-1:0] sram_wordmask_r0,
    output reg [CH_NUM-1:0] sram_wordmask_r1,
    output reg [CH_NUM-1:0] sram_wordmask_r2,
    output reg [CH_NUM-1:0] sram_wordmask_r3,

    output reg [CH_NUM*2-1:0] sram_wordmask_gb0,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb1,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb2,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb3,

    output reg [CH_NUM-1:0] sram_wordmask_fy0,
    output reg [CH_NUM-1:0] sram_wordmask_fy1,
    output reg [CH_NUM-1:0] sram_wordmask_fy2,
    output reg [CH_NUM-1:0] sram_wordmask_fy3,

    output reg [CH_NUM*2-1:0] sram_wordmask_fc0,
    output reg [CH_NUM*2-1:0] sram_wordmask_fc1,
    output reg [CH_NUM*2-1:0] sram_wordmask_fc2,
    output reg [CH_NUM*2-1:0] sram_wordmask_fc3,

    // SRAM write data outputs
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0,
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1,
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2,
    output reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3,

    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3,

    output reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy0,
    output reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy1,
    output reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy2,
    output reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy3,

    output reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc0,
    output reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc1,
    output reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc2,
    output reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc3
);

// source
localparam  IDLE    = 4'd0,
            WB      = 4'd1,
            DEMOS   = 4'd2,
            GAMMA   = 4'd3,
            YCBCR   = 4'd4,
            LM      = 4'd5,
            WAIT_CM = 4'd6,
            RGB     = 4'd7,
            FINISH  = 4'd8;
// reference
localparam  IDLE_REF  = 2'd0,
            YCBCR_REF = 2'd1,
            CHROMA_STATS_REF = 2'd2;

// -------------------------------------

reg [8:0] state, state_nx;
reg [2:0] state_ref, state_ref_n;
reg cbcr_mode;
wire state_cbcr_src;
wire state_cbcr_ref;
wire state_cbcr_match;
wire wb_done;
wire demos_done;
wire gamma_done;
wire ycbcr_done;
wire lm_done;
wire cs_done;
wire cm_done;
wire rgb_done;

// input DFF
reg [LINEAR_BW*CH_NUM-1:0] sram_rdata_r0_r;
reg [LINEAR_BW*CH_NUM-1:0] sram_rdata_r1_r;
reg [LINEAR_BW*CH_NUM-1:0] sram_rdata_r2_r;
reg [LINEAR_BW*CH_NUM-1:0] sram_rdata_r3_r;
// SRAM_GB for green/blue channel 31~16:G ; 15~0:B
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb0_r;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb1_r;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb2_r;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb3_r;

// SRAM_FY for reference Y channel
reg [RGB_BW*CH_NUM-1:0] sram_rdata_fy0_r;
reg [RGB_BW*CH_NUM-1:0] sram_rdata_fy1_r;
reg [RGB_BW*CH_NUM-1:0] sram_rdata_fy2_r;
reg [RGB_BW*CH_NUM-1:0] sram_rdata_fy3_r;
// SRAM_FC for reference CbCr channel
reg [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc0_r;
reg [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc1_r;
reg [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc2_r;
reg [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc3_r;



// output nxt
reg [17-1:0] sram_raddr_r0_n;
reg [17-1:0] sram_raddr_r1_n;
reg [17-1:0] sram_raddr_r2_n;
reg [17-1:0] sram_raddr_r3_n;
reg [17-1:0] sram_raddr_gb0_n;
reg [17-1:0] sram_raddr_gb1_n;
reg [17-1:0] sram_raddr_gb2_n;
reg [17-1:0] sram_raddr_gb3_n;

reg [17-1:0] sram_raddr_fy0_n;
reg [17-1:0] sram_raddr_fy1_n;
reg [17-1:0] sram_raddr_fy2_n;
reg [17-1:0] sram_raddr_fy3_n;
reg [17-1:0] sram_raddr_fc0_n;
reg [17-1:0] sram_raddr_fc1_n;
reg [17-1:0] sram_raddr_fc2_n;
reg [17-1:0] sram_raddr_fc3_n;

reg [17-1:0] sram_waddr_r0_n;
reg [17-1:0] sram_waddr_r1_n;
reg [17-1:0] sram_waddr_r2_n;
reg [17-1:0] sram_waddr_r3_n;
reg [17-1:0] sram_waddr_gb0_n;
reg [17-1:0] sram_waddr_gb1_n;
reg [17-1:0] sram_waddr_gb2_n;
reg [17-1:0] sram_waddr_gb3_n;

reg [17-1:0] sram_waddr_fy0_n;
reg [17-1:0] sram_waddr_fy1_n;
reg [17-1:0] sram_waddr_fy2_n;
reg [17-1:0] sram_waddr_fy3_n;
reg [17-1:0] sram_waddr_fc0_n;
reg [17-1:0] sram_waddr_fc1_n;
reg [17-1:0] sram_waddr_fc2_n;
reg [17-1:0] sram_waddr_fc3_n;


reg sram_wen_r0_n;
reg sram_wen_r1_n;
reg sram_wen_r2_n;
reg sram_wen_r3_n;
reg sram_wen_gb0_n;
reg sram_wen_gb1_n;
reg sram_wen_gb2_n;
reg sram_wen_gb3_n;

reg sram_wen_fy0_n;
reg sram_wen_fy1_n;
reg sram_wen_fy2_n;
reg sram_wen_fy3_n;
reg sram_wen_fc0_n;
reg sram_wen_fc1_n;
reg sram_wen_fc2_n;
reg sram_wen_fc3_n;

reg [CH_NUM-1:0] sram_wordmask_r0_n;
reg [CH_NUM-1:0] sram_wordmask_r1_n;
reg [CH_NUM-1:0] sram_wordmask_r2_n;
reg [CH_NUM-1:0] sram_wordmask_r3_n;
reg [CH_NUM*2-1:0] sram_wordmask_gb0_n;
reg [CH_NUM*2-1:0] sram_wordmask_gb1_n;
reg [CH_NUM*2-1:0] sram_wordmask_gb2_n;
reg [CH_NUM*2-1:0] sram_wordmask_gb3_n;

reg [CH_NUM-1:0] sram_wordmask_fy0_n;
reg [CH_NUM-1:0] sram_wordmask_fy1_n;
reg [CH_NUM-1:0] sram_wordmask_fy2_n;
reg [CH_NUM-1:0] sram_wordmask_fy3_n;
reg [CH_NUM*2-1:0] sram_wordmask_fc0_n;
reg [CH_NUM*2-1:0] sram_wordmask_fc1_n;
reg [CH_NUM*2-1:0] sram_wordmask_fc2_n;
reg [CH_NUM*2-1:0] sram_wordmask_fc3_n;


reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_n;
reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1_n;
reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_n;
reg [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3_n;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_n;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_n;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_n;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_n;


reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy0_n;
reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy1_n;
reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy2_n;
reg [RGB_BW*CH_NUM-1:0] sram_wdata_fy3_n;
reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc0_n;
reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc1_n;
reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc2_n;
reg [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc3_n;

// submodule - wb
wire [17-1:0] sram_raddr_r0_wb;
wire [17-1:0] sram_raddr_r2_wb;
wire [17-1:0] sram_raddr_gb0_wb;
wire [17-1:0] sram_raddr_gb1_wb;
wire [17-1:0] sram_raddr_gb2_wb;
wire [17-1:0] sram_raddr_gb3_wb;

wire [17-1:0] sram_waddr_r0_wb;
wire [17-1:0] sram_waddr_r2_wb;
wire [17-1:0] sram_waddr_gb0_wb;
wire [17-1:0] sram_waddr_gb1_wb;
wire [17-1:0] sram_waddr_gb2_wb;
wire [17-1:0] sram_waddr_gb3_wb;

wire sram_wen_r0_wb;
wire sram_wen_r2_wb;
wire sram_wen_gb0_wb;
wire sram_wen_gb1_wb;
wire sram_wen_gb2_wb;
wire sram_wen_gb3_wb;

wire [CH_NUM-1:0] sram_wordmask_r0_wb;
wire [CH_NUM-1:0] sram_wordmask_r2_wb;
wire [CH_NUM*2-1:0] sram_wordmask_gb0_wb;
wire [CH_NUM*2-1:0] sram_wordmask_gb1_wb;
wire [CH_NUM*2-1:0] sram_wordmask_gb2_wb;
wire [CH_NUM*2-1:0] sram_wordmask_gb3_wb;

wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_wb;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_wb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_wb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_wb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_wb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_wb;


// submodule - demos
wire [17-1:0] sram_raddr_rgb0123_demos;
wire [17-1:0] sram_waddr_rgb0123_demos;

wire sram_wen_rgb01_demos;
wire sram_wen_rgb23_demos;

wire [CH_NUM-1:0] sram_wordmask_r02_demos;
wire [CH_NUM-1:0] sram_wordmask_r13_demos;
wire [CH_NUM*2-1:0] sram_wordmask_gb02_demos;
wire [CH_NUM*2-1:0] sram_wordmask_gb13_demos;

wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_demos;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1_demos;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_demos;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3_demos;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_demos;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_demos;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_demos;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_demos;

// submodule - histogram
reg hist_start;
reg cdf_begin;
reg [1:0] hist_mode;
reg light_match;
reg [LINEAR_BW-1:0] hist_in;

wire [BIN_BW-1:0] white_point;
wire cdf_done;
wire wp_get;
wire light_get;

// submodule - gamma
wire [17-1:0] sram_raddr_gamma;
wire [17-1:0] sram_waddr_gamma;
wire sram_wen_gamma;
wire [CH_NUM-1:0] sram_wordmask_gamma_r;
wire [CH_NUM*2-1:0] sram_wordmask_gamma_gb;

wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r0_gamma;
wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r1_gamma;
wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r2_gamma;
wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r3_gamma;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb0_gamma;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb1_gamma;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb2_gamma;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb3_gamma;

wire gamma_hist_start;
wire gamma_cdf_begin;
wire [LINEAR_BW-1:0] gamma_hist_in;
wire [LINEAR_BW-1:0] wp_inv;

// submodule - convert2ycbcr
wire [17-1:0] sram_raddr_rgb0123_ycbcr;
wire [17-1:0] sram_raddr_fyfc0123_ycbcr;

wire [17-1:0] sram_waddr_rgb0123_ycbcr;
wire [17-1:0] sram_waddr_fyfc0123_ycbcr;

wire sram_wen_rgb0123_ycbcr;
wire sram_wen_fyfc0123_ycbcr;

wire [CH_NUM-1:0] sram_wordmask_r0123_ycbcr;
wire [CH_NUM*2-1:0] sram_wordmask_gb0123_ycbcr;
wire [CH_NUM-1:0] sram_wordmask_fy0123_ycbcr;
wire [CH_NUM*2-1:0] sram_wordmask_fc0123_ycbcr;

wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_ycbcr;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1_ycbcr;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_ycbcr;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3_ycbcr;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_ycbcr;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_ycbcr;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_ycbcr;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_ycbcr;

wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy0_ycbcr;
wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy1_ycbcr;
wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy2_ycbcr;
wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy3_ycbcr;
wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc0_ycbcr;
wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc1_ycbcr;
wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc2_ycbcr;
wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc3_ycbcr;

// submodule - light_match
reg is_source;
wire [17-1:0] sram_raddr_r0123_lm;
wire [17-1:0] sram_raddr_fy0123_lm;
wire [17-1:0] sram_waddr_r0123_lm;

wire sram_wen_r0123_lm;
wire [CH_NUM-1:0] sram_wordmask_r0123_lm;

wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_lm;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1_lm;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_lm;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3_lm;

// histogram
// src  // ref
wire ref_cdf_done_lm;
wire [BIN_BW-1:0] ref_white_point_lm;
wire ref_light_get_lm;

wire start_lm;
wire cdf_begin_lm;
wire src_match_done_lm;
wire [1:0] src_mode_lm;     
wire [8-1:0] src_hist_in_lm;

wire ref_match_done_lm;
wire [1:0] ref_mode_lm;     
wire [BIN_BW-1:0] ref_hist_in_lm;

// submodule - chroma_stats & color_mapping
// global registers
reg [19-1:0] mu_Cb_src, mu_Cr_src;
reg [19-1:0] mu_Cb_src_nx, mu_Cr_src_nx;
reg [19-1:0] mu_Cb_ref, mu_Cr_ref;
reg [19-1:0] mu_Cb_ref_nx, mu_Cr_ref_nx;
wire [19-1:0] mu_Cb_cs, mu_Cr_cs;
reg [27-1:0] sqr_sigma_Cb_src, sqr_sigma_Cr_src;
reg [27-1:0] sqr_sigma_Cb_src_nx, sqr_sigma_Cr_src_nx;
reg [27-1:0] sqr_sigma_Cb_ref, sqr_sigma_Cr_ref;
reg [27-1:0] sqr_sigma_Cb_ref_nx, sqr_sigma_Cr_ref_nx;
wire [27-1:0] sqr_sigma_Cb_cs, sqr_sigma_Cr_cs;

// cs
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_0_cs;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_1_cs;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_2_cs;
reg [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_3_cs;

wire [17-1:0] sram_raddr_0_cs;
wire [17-1:0] sram_raddr_1_cs;
wire [17-1:0] sram_raddr_2_cs;
wire [17-1:0] sram_raddr_3_cs;

// cm
wire [17-1:0] sram_raddr_gb0_cm;
wire [17-1:0] sram_raddr_gb1_cm;
wire [17-1:0] sram_raddr_gb2_cm;
wire [17-1:0] sram_raddr_gb3_cm;

wire [17-1:0]sram_waddr_gb0_cm;
wire [17-1:0]sram_waddr_gb1_cm;
wire [17-1:0]sram_waddr_gb2_cm;
wire [17-1:0]sram_waddr_gb3_cm;

wire [CH_NUM*2-1:0] sram_wordmask_gb0_cm;
wire [CH_NUM*2-1:0] sram_wordmask_gb1_cm;
wire [CH_NUM*2-1:0] sram_wordmask_gb2_cm;
wire [CH_NUM*2-1:0] sram_wordmask_gb3_cm;

wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_cm;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_cm;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_cm;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_cm;

wire sram_wen_gb0_cm;
wire sram_wen_gb1_cm;
wire sram_wen_gb2_cm;
wire sram_wen_gb3_cm;

wire [13-1:0] sqrt_sigma_Cb, sqrt_sigma_Cr;

// submodule - rgb
wire [17-1:0] sram_raddr_rgb0123_rgb;
wire [17-1:0] sram_waddr_rgb0123_rgb;
wire sram_wen_rgb0123_rgb;

wire [CH_NUM-1:0] sram_wordmask_r0123_rgb;
wire [CH_NUM*2-1:0] sram_wordmask_gb0123_rgb;

wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0_rgb;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1_rgb;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2_rgb;
wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3_rgb;

wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0_rgb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1_rgb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2_rgb;
wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3_rgb;

// submodule - mul

localparam MUL_IN_BW_1 = 16,
           MUL_IN_BW_2 = 16,
           MUL_OUT_BW = MUL_IN_BW_1 + MUL_IN_BW_2;

reg [MUL_IN_BW_1-1:0] mul_in_1_0;
reg [MUL_IN_BW_1-1:0] mul_in_1_1;
reg [MUL_IN_BW_1-1:0] mul_in_1_2;
reg [MUL_IN_BW_1-1:0] mul_in_1_3;
reg [MUL_IN_BW_1-1:0] mul_in_1_4;
reg [MUL_IN_BW_1-1:0] mul_in_1_5;
reg [MUL_IN_BW_1-1:0] mul_in_1_6;
reg [MUL_IN_BW_1-1:0] mul_in_1_7;
reg [MUL_IN_BW_1-1:0] mul_in_1_8;
reg [MUL_IN_BW_1-1:0] mul_in_1_9;
reg [MUL_IN_BW_1-1:0] mul_in_1_10;
reg [MUL_IN_BW_1-1:0] mul_in_1_11;
reg [MUL_IN_BW_1-1:0] mul_in_1_12;
reg [MUL_IN_BW_1-1:0] mul_in_1_13;
reg [MUL_IN_BW_1-1:0] mul_in_1_14;
reg [MUL_IN_BW_1-1:0] mul_in_1_15;
reg [MUL_IN_BW_1-1:0] mul_in_1_16;
reg [MUL_IN_BW_1-1:0] mul_in_1_17;
reg [MUL_IN_BW_1-1:0] mul_in_1_18;
reg [MUL_IN_BW_1-1:0] mul_in_1_19;
reg [MUL_IN_BW_1-1:0] mul_in_1_20;
reg [MUL_IN_BW_1-1:0] mul_in_1_21;
reg [MUL_IN_BW_1-1:0] mul_in_1_22;
reg [MUL_IN_BW_1-1:0] mul_in_1_23;
reg [MUL_IN_BW_1-1:0] mul_in_1_24;
reg [MUL_IN_BW_1-1:0] mul_in_1_25;
reg [MUL_IN_BW_1-1:0] mul_in_1_26;
reg [MUL_IN_BW_1-1:0] mul_in_1_27;
reg [MUL_IN_BW_1-1:0] mul_in_1_28;
reg [MUL_IN_BW_1-1:0] mul_in_1_29;
reg [MUL_IN_BW_1-1:0] mul_in_1_30;
reg [MUL_IN_BW_1-1:0] mul_in_1_31;
reg [MUL_IN_BW_1-1:0] mul_in_1_32;
reg [MUL_IN_BW_1-1:0] mul_in_1_33;
reg [MUL_IN_BW_1-1:0] mul_in_1_34;
reg [MUL_IN_BW_1-1:0] mul_in_1_35;
reg [MUL_IN_BW_1-1:0] mul_in_1_36;
reg [MUL_IN_BW_1-1:0] mul_in_1_37;
reg [MUL_IN_BW_1-1:0] mul_in_1_38;
reg [MUL_IN_BW_1-1:0] mul_in_1_39;
reg [MUL_IN_BW_1-1:0] mul_in_1_40;
reg [MUL_IN_BW_1-1:0] mul_in_1_41;
reg [MUL_IN_BW_1-1:0] mul_in_1_42;
reg [MUL_IN_BW_1-1:0] mul_in_1_43;
reg [MUL_IN_BW_1-1:0] mul_in_1_44;
reg [MUL_IN_BW_1-1:0] mul_in_1_45;
reg [MUL_IN_BW_1-1:0] mul_in_1_46;
reg [MUL_IN_BW_1-1:0] mul_in_1_47;

reg [MUL_IN_BW_1-1:0] mul_in_2_0;
reg [MUL_IN_BW_1-1:0] mul_in_2_1;
reg [MUL_IN_BW_1-1:0] mul_in_2_2;
reg [MUL_IN_BW_1-1:0] mul_in_2_3;
reg [MUL_IN_BW_1-1:0] mul_in_2_4;
reg [MUL_IN_BW_1-1:0] mul_in_2_5;
reg [MUL_IN_BW_1-1:0] mul_in_2_6;
reg [MUL_IN_BW_1-1:0] mul_in_2_7;
reg [MUL_IN_BW_1-1:0] mul_in_2_8;
reg [MUL_IN_BW_1-1:0] mul_in_2_9;
reg [MUL_IN_BW_1-1:0] mul_in_2_10;
reg [MUL_IN_BW_1-1:0] mul_in_2_11;
reg [MUL_IN_BW_1-1:0] mul_in_2_12;
reg [MUL_IN_BW_1-1:0] mul_in_2_13;
reg [MUL_IN_BW_1-1:0] mul_in_2_14;
reg [MUL_IN_BW_1-1:0] mul_in_2_15;
reg [MUL_IN_BW_1-1:0] mul_in_2_16;
reg [MUL_IN_BW_1-1:0] mul_in_2_17;
reg [MUL_IN_BW_1-1:0] mul_in_2_18;
reg [MUL_IN_BW_1-1:0] mul_in_2_19;
reg [MUL_IN_BW_1-1:0] mul_in_2_20;
reg [MUL_IN_BW_1-1:0] mul_in_2_21;
reg [MUL_IN_BW_1-1:0] mul_in_2_22;
reg [MUL_IN_BW_1-1:0] mul_in_2_23;
reg [MUL_IN_BW_1-1:0] mul_in_2_24;
reg [MUL_IN_BW_1-1:0] mul_in_2_25;
reg [MUL_IN_BW_1-1:0] mul_in_2_26;
reg [MUL_IN_BW_1-1:0] mul_in_2_27;
reg [MUL_IN_BW_1-1:0] mul_in_2_28;
reg [MUL_IN_BW_1-1:0] mul_in_2_29;
reg [MUL_IN_BW_1-1:0] mul_in_2_30;
reg [MUL_IN_BW_1-1:0] mul_in_2_31;
reg [MUL_IN_BW_1-1:0] mul_in_2_32;
reg [MUL_IN_BW_1-1:0] mul_in_2_33;
reg [MUL_IN_BW_1-1:0] mul_in_2_34;
reg [MUL_IN_BW_1-1:0] mul_in_2_35;
reg [MUL_IN_BW_1-1:0] mul_in_2_36;
reg [MUL_IN_BW_1-1:0] mul_in_2_37;
reg [MUL_IN_BW_1-1:0] mul_in_2_38;
reg [MUL_IN_BW_1-1:0] mul_in_2_39;
reg [MUL_IN_BW_1-1:0] mul_in_2_40;
reg [MUL_IN_BW_1-1:0] mul_in_2_41;
reg [MUL_IN_BW_1-1:0] mul_in_2_42;
reg [MUL_IN_BW_1-1:0] mul_in_2_43;
reg [MUL_IN_BW_1-1:0] mul_in_2_44;
reg [MUL_IN_BW_1-1:0] mul_in_2_45;
reg [MUL_IN_BW_1-1:0] mul_in_2_46;
reg [MUL_IN_BW_1-1:0] mul_in_2_47;

wire [MUL_OUT_BW-1:0] mul_out_0;
wire [MUL_OUT_BW-1:0] mul_out_1;
wire [MUL_OUT_BW-1:0] mul_out_2;
wire [MUL_OUT_BW-1:0] mul_out_3;
wire [MUL_OUT_BW-1:0] mul_out_4;
wire [MUL_OUT_BW-1:0] mul_out_5;
wire [MUL_OUT_BW-1:0] mul_out_6;
wire [MUL_OUT_BW-1:0] mul_out_7;
wire [MUL_OUT_BW-1:0] mul_out_8;
wire [MUL_OUT_BW-1:0] mul_out_9;
wire [MUL_OUT_BW-1:0] mul_out_10;
wire [MUL_OUT_BW-1:0] mul_out_11;
wire [MUL_OUT_BW-1:0] mul_out_12;
wire [MUL_OUT_BW-1:0] mul_out_13;
wire [MUL_OUT_BW-1:0] mul_out_14;
wire [MUL_OUT_BW-1:0] mul_out_15;
wire [MUL_OUT_BW-1:0] mul_out_16;
wire [MUL_OUT_BW-1:0] mul_out_17;
wire [MUL_OUT_BW-1:0] mul_out_18;
wire [MUL_OUT_BW-1:0] mul_out_19;
wire [MUL_OUT_BW-1:0] mul_out_20;
wire [MUL_OUT_BW-1:0] mul_out_21;
wire [MUL_OUT_BW-1:0] mul_out_22;
wire [MUL_OUT_BW-1:0] mul_out_23;
wire [MUL_OUT_BW-1:0] mul_out_24;
wire [MUL_OUT_BW-1:0] mul_out_25;
wire [MUL_OUT_BW-1:0] mul_out_26;
wire [MUL_OUT_BW-1:0] mul_out_27;
wire [MUL_OUT_BW-1:0] mul_out_28;
wire [MUL_OUT_BW-1:0] mul_out_29;
wire [MUL_OUT_BW-1:0] mul_out_30;
wire [MUL_OUT_BW-1:0] mul_out_31;
wire [MUL_OUT_BW-1:0] mul_out_32;
wire [MUL_OUT_BW-1:0] mul_out_33;
wire [MUL_OUT_BW-1:0] mul_out_34;
wire [MUL_OUT_BW-1:0] mul_out_35;
wire [MUL_OUT_BW-1:0] mul_out_36;
wire [MUL_OUT_BW-1:0] mul_out_37;
wire [MUL_OUT_BW-1:0] mul_out_38;
wire [MUL_OUT_BW-1:0] mul_out_39;
wire [MUL_OUT_BW-1:0] mul_out_40;
wire [MUL_OUT_BW-1:0] mul_out_41;
wire [MUL_OUT_BW-1:0] mul_out_42;
wire [MUL_OUT_BW-1:0] mul_out_43;
wire [MUL_OUT_BW-1:0] mul_out_44;
wire [MUL_OUT_BW-1:0] mul_out_45;
wire [MUL_OUT_BW-1:0] mul_out_46;
wire [MUL_OUT_BW-1:0] mul_out_47;

//----------top connection (nxt)-----------//

// raddr_r
always @* begin
    case (1) // synopsys parallel_case 
        state[WB]: begin
            sram_raddr_r0_n = sram_raddr_r0_wb;
            sram_raddr_r1_n = 0;
            sram_raddr_r2_n = sram_raddr_r2_wb;
            sram_raddr_r3_n = 0;
        end
        state[DEMOS]: begin
            sram_raddr_r0_n = sram_raddr_rgb0123_demos;
            sram_raddr_r1_n = sram_raddr_rgb0123_demos;
            sram_raddr_r2_n = sram_raddr_rgb0123_demos;
            sram_raddr_r3_n = sram_raddr_rgb0123_demos;
        end
        state[GAMMA]: begin
            sram_raddr_r0_n = sram_raddr_gamma;
            sram_raddr_r1_n = sram_raddr_gamma;
            sram_raddr_r2_n = sram_raddr_gamma;
            sram_raddr_r3_n = sram_raddr_gamma;
        end
        state[YCBCR]: begin
            sram_raddr_r0_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_r1_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_r2_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_r3_n = sram_raddr_rgb0123_ycbcr;
        end
        state[LM]: begin
            sram_raddr_r0_n = sram_raddr_r0123_lm;
            sram_raddr_r1_n = sram_raddr_r0123_lm;
            sram_raddr_r2_n = sram_raddr_r0123_lm;
            sram_raddr_r3_n = sram_raddr_r0123_lm;
        end 
        state[RGB]: begin
            sram_raddr_r0_n = sram_raddr_rgb0123_rgb;
            sram_raddr_r1_n = sram_raddr_rgb0123_rgb;
            sram_raddr_r2_n = sram_raddr_rgb0123_rgb;
            sram_raddr_r3_n = sram_raddr_rgb0123_rgb;
        end
        default: begin
            sram_raddr_r0_n = 0;
            sram_raddr_r1_n = 0;
            sram_raddr_r2_n = 0;
            sram_raddr_r3_n = 0;
        end
    endcase
end

// raddr_gbs
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_raddr_gb0_n = sram_raddr_gb0_wb;
            sram_raddr_gb1_n = sram_raddr_gb1_wb;
            sram_raddr_gb2_n = sram_raddr_gb2_wb;
            sram_raddr_gb3_n = sram_raddr_gb3_wb;
        end
        state[DEMOS]: begin
            sram_raddr_gb0_n = sram_raddr_rgb0123_demos;
            sram_raddr_gb1_n = sram_raddr_rgb0123_demos;
            sram_raddr_gb2_n = sram_raddr_rgb0123_demos;
            sram_raddr_gb3_n = sram_raddr_rgb0123_demos;
        end
        state[GAMMA]: begin
            sram_raddr_gb0_n = sram_raddr_gamma;
            sram_raddr_gb1_n = sram_raddr_gamma;
            sram_raddr_gb2_n = sram_raddr_gamma;
            sram_raddr_gb3_n = sram_raddr_gamma;
        end
        state[YCBCR]: begin
            sram_raddr_gb0_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_gb1_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_gb2_n = sram_raddr_rgb0123_ycbcr;
            sram_raddr_gb3_n = sram_raddr_rgb0123_ycbcr;
        end  
        state_cbcr_src: begin
            sram_raddr_gb0_n = sram_raddr_0_cs;
            sram_raddr_gb1_n = sram_raddr_1_cs;
            sram_raddr_gb2_n = sram_raddr_2_cs;
            sram_raddr_gb3_n = sram_raddr_3_cs;
        end
        state_cbcr_match: begin
            sram_raddr_gb0_n = sram_raddr_gb0_cm;
            sram_raddr_gb1_n = sram_raddr_gb1_cm;
            sram_raddr_gb2_n = sram_raddr_gb2_cm;
            sram_raddr_gb3_n = sram_raddr_gb3_cm;
        end
        state[RGB]: begin
            sram_raddr_gb0_n = sram_raddr_rgb0123_rgb;
            sram_raddr_gb1_n = sram_raddr_rgb0123_rgb;
            sram_raddr_gb2_n = sram_raddr_rgb0123_rgb;
            sram_raddr_gb3_n = sram_raddr_rgb0123_rgb;
        end              
        default: begin
            sram_raddr_gb0_n = 0;
            sram_raddr_gb1_n = 0;
            sram_raddr_gb2_n = 0;
            sram_raddr_gb3_n = 0;
        end
    endcase
end

// raddr_fy
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_raddr_fy0_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fy1_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fy2_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fy3_n = sram_raddr_fyfc0123_ycbcr;
        end       
        state[LM]: begin
            sram_raddr_fy0_n = sram_raddr_fy0123_lm;
            sram_raddr_fy1_n = sram_raddr_fy0123_lm;
            sram_raddr_fy2_n = sram_raddr_fy0123_lm;
            sram_raddr_fy3_n = sram_raddr_fy0123_lm;
        end              
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_raddr_fy0_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fy1_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fy2_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fy3_n = sram_raddr_fyfc0123_ycbcr;
            end else begin
                sram_raddr_fy0_n = 0;
                sram_raddr_fy1_n = 0;
                sram_raddr_fy2_n = 0;
                sram_raddr_fy3_n = 0;
            end
        end
    endcase
end

// raddr_fc
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_raddr_fc0_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fc1_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fc2_n = sram_raddr_fyfc0123_ycbcr;
            sram_raddr_fc3_n = sram_raddr_fyfc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_raddr_fc0_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fc1_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fc2_n = sram_raddr_fyfc0123_ycbcr;
                sram_raddr_fc3_n = sram_raddr_fyfc0123_ycbcr;
            end else if (state_cbcr_ref) begin
                sram_raddr_fc0_n = sram_raddr_0_cs;
                sram_raddr_fc1_n = sram_raddr_1_cs;
                sram_raddr_fc2_n = sram_raddr_2_cs;
                sram_raddr_fc3_n = sram_raddr_3_cs;
            end else begin            
                sram_raddr_fc0_n = 0;
                sram_raddr_fc1_n = 0;
                sram_raddr_fc2_n = 0;
                sram_raddr_fc3_n = 0;
            end
        end
    endcase
end

// waddr_r
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_waddr_r0_n = sram_waddr_r0_wb;
            sram_waddr_r1_n = 0;
            sram_waddr_r2_n = sram_waddr_r2_wb;
            sram_waddr_r3_n = 0;
        end        
        state[DEMOS]: begin
            sram_waddr_r0_n = sram_waddr_rgb0123_demos;
            sram_waddr_r1_n = sram_waddr_rgb0123_demos;
            sram_waddr_r2_n = sram_waddr_rgb0123_demos;
            sram_waddr_r3_n = sram_waddr_rgb0123_demos;
        end
        state[GAMMA]: begin
            sram_waddr_r0_n = sram_waddr_gamma;
            sram_waddr_r1_n = sram_waddr_gamma;
            sram_waddr_r2_n = sram_waddr_gamma;
            sram_waddr_r3_n = sram_waddr_gamma;
        end
        state[YCBCR]: begin
            sram_waddr_r0_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_r1_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_r2_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_r3_n = sram_waddr_rgb0123_ycbcr;
        end 
        state[LM]: begin
            sram_waddr_r0_n = sram_waddr_r0123_lm;
            sram_waddr_r1_n = sram_waddr_r0123_lm;
            sram_waddr_r2_n = sram_waddr_r0123_lm;
            sram_waddr_r3_n = sram_waddr_r0123_lm;
        end       
        state[RGB]: begin
            sram_waddr_r0_n = sram_waddr_rgb0123_rgb;
            sram_waddr_r1_n = sram_waddr_rgb0123_rgb;
            sram_waddr_r2_n = sram_waddr_rgb0123_rgb;
            sram_waddr_r3_n = sram_waddr_rgb0123_rgb;
        end            
        default: begin
            sram_waddr_r0_n = 0;
            sram_waddr_r1_n = 0;
            sram_waddr_r2_n = 0;
            sram_waddr_r3_n = 0;
        end
    endcase
end

// waddr_gb
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_waddr_gb0_n = sram_waddr_gb0_wb;
            sram_waddr_gb1_n = sram_waddr_gb1_wb;
            sram_waddr_gb2_n = sram_waddr_gb2_wb;
            sram_waddr_gb3_n = sram_waddr_gb3_wb;
        end
        state[DEMOS]: begin
            sram_waddr_gb0_n = sram_waddr_rgb0123_demos;
            sram_waddr_gb1_n = sram_waddr_rgb0123_demos;
            sram_waddr_gb2_n = sram_waddr_rgb0123_demos;
            sram_waddr_gb3_n = sram_waddr_rgb0123_demos;
        end
        state[GAMMA]: begin
            sram_waddr_gb0_n = sram_waddr_gamma;
            sram_waddr_gb1_n = sram_waddr_gamma;
            sram_waddr_gb2_n = sram_waddr_gamma;
            sram_waddr_gb3_n = sram_waddr_gamma;
        end
        state[YCBCR]: begin
            sram_waddr_gb0_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_gb1_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_gb2_n = sram_waddr_rgb0123_ycbcr;
            sram_waddr_gb3_n = sram_waddr_rgb0123_ycbcr;
        end   
        state_cbcr_match: begin
            sram_waddr_gb0_n = sram_waddr_gb0_cm;
            sram_waddr_gb1_n = sram_waddr_gb1_cm;
            sram_waddr_gb2_n = sram_waddr_gb2_cm;
            sram_waddr_gb3_n = sram_waddr_gb3_cm;
        end
        state[RGB]: begin
            sram_waddr_gb0_n = sram_waddr_rgb0123_rgb;
            sram_waddr_gb1_n = sram_waddr_rgb0123_rgb;
            sram_waddr_gb2_n = sram_waddr_rgb0123_rgb;
            sram_waddr_gb3_n = sram_waddr_rgb0123_rgb;
        end                
        default: begin
            sram_waddr_gb0_n = 0;
            sram_waddr_gb1_n = 0;
            sram_waddr_gb2_n = 0;
            sram_waddr_gb3_n = 0;
        end
    endcase
end

// waddr_fy
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_waddr_fy0_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fy1_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fy2_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fy3_n = sram_waddr_fyfc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_waddr_fy0_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fy1_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fy2_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fy3_n = sram_waddr_fyfc0123_ycbcr;
            end else begin            
                sram_waddr_fy0_n = 0;
                sram_waddr_fy1_n = 0;
                sram_waddr_fy2_n = 0;
                sram_waddr_fy3_n = 0;
            end            
        end
    endcase
end

// waddr_fc
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_waddr_fc0_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fc1_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fc2_n = sram_waddr_fyfc0123_ycbcr;
            sram_waddr_fc3_n = sram_waddr_fyfc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_waddr_fc0_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fc1_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fc2_n = sram_waddr_fyfc0123_ycbcr;
                sram_waddr_fc3_n = sram_waddr_fyfc0123_ycbcr;
            end else begin            
                sram_waddr_fc0_n = 0;
                sram_waddr_fc1_n = 0;
                sram_waddr_fc2_n = 0;
                sram_waddr_fc3_n = 0;
            end       
        end
    endcase
end

// wen_r
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wen_r0_n = sram_wen_r0_wb;
            sram_wen_r1_n = 1;
            sram_wen_r2_n = sram_wen_r2_wb;
            sram_wen_r3_n = 1;
        end
        state[DEMOS]: begin
            sram_wen_r0_n = sram_wen_rgb01_demos;
            sram_wen_r1_n = sram_wen_rgb01_demos;
            sram_wen_r2_n = sram_wen_rgb23_demos;
            sram_wen_r3_n = sram_wen_rgb23_demos;
        end
        state[GAMMA]: begin
            sram_wen_r0_n = sram_wen_gamma;
            sram_wen_r1_n = sram_wen_gamma;
            sram_wen_r2_n = sram_wen_gamma;
            sram_wen_r3_n = sram_wen_gamma;
        end
        state[YCBCR]: begin
            sram_wen_r0_n = sram_wen_rgb0123_ycbcr;
            sram_wen_r1_n = sram_wen_rgb0123_ycbcr;
            sram_wen_r2_n = sram_wen_rgb0123_ycbcr;
            sram_wen_r3_n = sram_wen_rgb0123_ycbcr;
        end   
        state[LM]: begin
            sram_wen_r0_n = sram_wen_r0123_lm;
            sram_wen_r1_n = sram_wen_r0123_lm;
            sram_wen_r2_n = sram_wen_r0123_lm;
            sram_wen_r3_n = sram_wen_r0123_lm;
        end        
        state[RGB]: begin
            sram_wen_r0_n = sram_wen_rgb0123_rgb;
            sram_wen_r1_n = sram_wen_rgb0123_rgb;
            sram_wen_r2_n = sram_wen_rgb0123_rgb;
            sram_wen_r3_n = sram_wen_rgb0123_rgb;
        end              
        default: begin
            sram_wen_r0_n = 1'b1;
            sram_wen_r1_n = 1'b1;
            sram_wen_r2_n = 1'b1;
            sram_wen_r3_n = 1'b1;
        end
    endcase
end

// wen_gb
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wen_gb0_n = sram_wen_gb0_wb;
            sram_wen_gb1_n = sram_wen_gb1_wb;
            sram_wen_gb2_n = sram_wen_gb2_wb;
            sram_wen_gb3_n = sram_wen_gb3_wb;
        end    
        state[DEMOS]: begin
            sram_wen_gb0_n = sram_wen_rgb01_demos;
            sram_wen_gb1_n = sram_wen_rgb01_demos;
            sram_wen_gb2_n = sram_wen_rgb23_demos;
            sram_wen_gb3_n = sram_wen_rgb23_demos;
        end
        state[GAMMA]: begin
            sram_wen_gb0_n = sram_wen_gamma;
            sram_wen_gb1_n = sram_wen_gamma;
            sram_wen_gb2_n = sram_wen_gamma;
            sram_wen_gb3_n = sram_wen_gamma;
        end
        state[YCBCR]: begin
            sram_wen_gb0_n = sram_wen_rgb0123_ycbcr;
            sram_wen_gb1_n = sram_wen_rgb0123_ycbcr;
            sram_wen_gb2_n = sram_wen_rgb0123_ycbcr;
            sram_wen_gb3_n = sram_wen_rgb0123_ycbcr;
        end    
        state_cbcr_match: begin
            sram_wen_gb0_n = sram_wen_gb0_cm;
            sram_wen_gb1_n = sram_wen_gb1_cm;
            sram_wen_gb2_n = sram_wen_gb2_cm;
            sram_wen_gb3_n = sram_wen_gb3_cm;
        end
        state[RGB]: begin
            sram_wen_gb0_n = sram_wen_rgb0123_rgb;
            sram_wen_gb1_n = sram_wen_rgb0123_rgb;
            sram_wen_gb2_n = sram_wen_rgb0123_rgb;
            sram_wen_gb3_n = sram_wen_rgb0123_rgb;
        end              
        default: begin
            sram_wen_gb0_n = 1'b1;
            sram_wen_gb1_n = 1'b1;
            sram_wen_gb2_n = 1'b1;
            sram_wen_gb3_n = 1'b1;
        end
    endcase
end

// wen_fy
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wen_fy0_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fy1_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fy2_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fy3_n = sram_wen_fyfc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wen_fy0_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fy1_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fy2_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fy3_n = sram_wen_fyfc0123_ycbcr;
            end else begin            
                sram_wen_fy0_n = 1'b1;
                sram_wen_fy1_n = 1'b1;
                sram_wen_fy2_n = 1'b1;
                sram_wen_fy3_n = 1'b1;
            end            
        end
    endcase
end

// wen_fc
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wen_fc0_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fc1_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fc2_n = sram_wen_fyfc0123_ycbcr;
            sram_wen_fc3_n = sram_wen_fyfc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wen_fc0_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fc1_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fc2_n = sram_wen_fyfc0123_ycbcr;
                sram_wen_fc3_n = sram_wen_fyfc0123_ycbcr;
            end else begin            
                sram_wen_fc0_n = 1'b1;
                sram_wen_fc1_n = 1'b1;
                sram_wen_fc2_n = 1'b1;
                sram_wen_fc3_n = 1'b1;
            end  
        end
    endcase
end

// wordmask_r
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wordmask_r0_n = sram_wordmask_r0_wb;
            sram_wordmask_r1_n = 4'hF;
            sram_wordmask_r2_n = sram_wordmask_r2_wb;
            sram_wordmask_r3_n = 4'hF;
        end    
        state[DEMOS]: begin
            sram_wordmask_r0_n = sram_wordmask_r02_demos;
            sram_wordmask_r1_n = sram_wordmask_r13_demos;
            sram_wordmask_r2_n = sram_wordmask_r02_demos;
            sram_wordmask_r3_n = sram_wordmask_r13_demos;
        end
        state[GAMMA]: begin
            sram_wordmask_r0_n = sram_wordmask_gamma_r;
            sram_wordmask_r1_n = sram_wordmask_gamma_r;
            sram_wordmask_r2_n = sram_wordmask_gamma_r;
            sram_wordmask_r3_n = sram_wordmask_gamma_r;
        end
        state[YCBCR]: begin
            sram_wordmask_r0_n = sram_wordmask_r0123_ycbcr;
            sram_wordmask_r1_n = sram_wordmask_r0123_ycbcr;
            sram_wordmask_r2_n = sram_wordmask_r0123_ycbcr;
            sram_wordmask_r3_n = sram_wordmask_r0123_ycbcr;
        end  
        state[LM]: begin
            sram_wordmask_r0_n = sram_wordmask_r0123_lm;
            sram_wordmask_r1_n = sram_wordmask_r0123_lm;
            sram_wordmask_r2_n = sram_wordmask_r0123_lm;
            sram_wordmask_r3_n = sram_wordmask_r0123_lm;
        end     
        state[RGB]: begin
            sram_wordmask_r0_n = sram_wordmask_r0123_rgb;
            sram_wordmask_r1_n = sram_wordmask_r0123_rgb;
            sram_wordmask_r2_n = sram_wordmask_r0123_rgb;
            sram_wordmask_r3_n = sram_wordmask_r0123_rgb;
        end
        default: begin
            sram_wordmask_r0_n = 4'hF;
            sram_wordmask_r1_n = 4'hF;
            sram_wordmask_r2_n = 4'hF;
            sram_wordmask_r3_n = 4'hF;
        end
    endcase
end

// wordmask_gb
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wordmask_gb0_n = sram_wordmask_gb0_wb;
            sram_wordmask_gb1_n = sram_wordmask_gb1_wb;
            sram_wordmask_gb2_n = sram_wordmask_gb2_wb;
            sram_wordmask_gb3_n = sram_wordmask_gb3_wb;
        end
        state[DEMOS]: begin
            sram_wordmask_gb0_n = sram_wordmask_gb02_demos;
            sram_wordmask_gb1_n = sram_wordmask_gb13_demos;
            sram_wordmask_gb2_n = sram_wordmask_gb02_demos;
            sram_wordmask_gb3_n = sram_wordmask_gb13_demos;
        end        
        state[GAMMA]: begin
            sram_wordmask_gb0_n = sram_wordmask_gamma_gb;
            sram_wordmask_gb1_n = sram_wordmask_gamma_gb;
            sram_wordmask_gb2_n = sram_wordmask_gamma_gb;
            sram_wordmask_gb3_n = sram_wordmask_gamma_gb;
        end
        state[YCBCR]: begin
            sram_wordmask_gb0_n = sram_wordmask_gb0123_ycbcr;
            sram_wordmask_gb1_n = sram_wordmask_gb0123_ycbcr;
            sram_wordmask_gb2_n = sram_wordmask_gb0123_ycbcr;
            sram_wordmask_gb3_n = sram_wordmask_gb0123_ycbcr;
        end   
        state_cbcr_match: begin
            sram_wordmask_gb0_n = sram_wordmask_gb0_cm;
            sram_wordmask_gb1_n = sram_wordmask_gb1_cm;
            sram_wordmask_gb2_n = sram_wordmask_gb2_cm;
            sram_wordmask_gb3_n = sram_wordmask_gb3_cm;
        end
        state[RGB]: begin
            sram_wordmask_gb0_n = sram_wordmask_gb0123_rgb;
            sram_wordmask_gb1_n = sram_wordmask_gb0123_rgb;
            sram_wordmask_gb2_n = sram_wordmask_gb0123_rgb;
            sram_wordmask_gb3_n = sram_wordmask_gb0123_rgb;
        end             
        default: begin
            sram_wordmask_gb0_n = 8'hFF;
            sram_wordmask_gb1_n = 8'hFF;
            sram_wordmask_gb2_n = 8'hFF;
            sram_wordmask_gb3_n = 8'hFF;
        end
    endcase
end

// wordmask_fy
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wordmask_fy0_n = sram_wordmask_fy0123_ycbcr;
            sram_wordmask_fy1_n = sram_wordmask_fy0123_ycbcr;
            sram_wordmask_fy2_n = sram_wordmask_fy0123_ycbcr;
            sram_wordmask_fy3_n = sram_wordmask_fy0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wordmask_fy0_n = sram_wordmask_fy0123_ycbcr;
                sram_wordmask_fy1_n = sram_wordmask_fy0123_ycbcr;
                sram_wordmask_fy2_n = sram_wordmask_fy0123_ycbcr;
                sram_wordmask_fy3_n = sram_wordmask_fy0123_ycbcr;
            end else begin
                sram_wordmask_fy0_n = 4'hF;
                sram_wordmask_fy1_n = 4'hF;
                sram_wordmask_fy2_n = 4'hF;
                sram_wordmask_fy3_n = 4'hF;
            end
        end
    endcase
end

// wordmask_fc
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wordmask_fc0_n = sram_wordmask_fc0123_ycbcr;
            sram_wordmask_fc1_n = sram_wordmask_fc0123_ycbcr;
            sram_wordmask_fc2_n = sram_wordmask_fc0123_ycbcr;
            sram_wordmask_fc3_n = sram_wordmask_fc0123_ycbcr;
        end        
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wordmask_fc0_n = sram_wordmask_fc0123_ycbcr;
                sram_wordmask_fc1_n = sram_wordmask_fc0123_ycbcr;
                sram_wordmask_fc2_n = sram_wordmask_fc0123_ycbcr;
                sram_wordmask_fc3_n = sram_wordmask_fc0123_ycbcr;
            end else begin
                sram_wordmask_fc0_n = 8'hFF;
                sram_wordmask_fc1_n = 8'hFF;
                sram_wordmask_fc2_n = 8'hFF;
                sram_wordmask_fc3_n = 8'hFF;
            end
        end
    endcase
end

// wdata_r
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wdata_r0_n = sram_wdata_r0_wb;
            sram_wdata_r1_n = 0;
            sram_wdata_r2_n = sram_wdata_r2_wb;
            sram_wdata_r3_n = 0;
        end
        state[DEMOS]: begin
            sram_wdata_r0_n = sram_wdata_r0_demos;
            sram_wdata_r1_n = sram_wdata_r1_demos;
            sram_wdata_r2_n = sram_wdata_r2_demos;
            sram_wdata_r3_n = sram_wdata_r3_demos;
        end       
        state[GAMMA]: begin
            sram_wdata_r0_n = sram_wdata_r0_gamma;
            sram_wdata_r1_n = sram_wdata_r1_gamma;
            sram_wdata_r2_n = sram_wdata_r2_gamma;
            sram_wdata_r3_n = sram_wdata_r3_gamma;
        end 
        state[YCBCR]: begin
            sram_wdata_r0_n = sram_wdata_r0_ycbcr;
            sram_wdata_r1_n = sram_wdata_r1_ycbcr;
            sram_wdata_r2_n = sram_wdata_r2_ycbcr;
            sram_wdata_r3_n = sram_wdata_r3_ycbcr;
        end
        state[LM]: begin
            sram_wdata_r0_n = sram_wdata_r0_lm;
            sram_wdata_r1_n = sram_wdata_r1_lm;
            sram_wdata_r2_n = sram_wdata_r2_lm;
            sram_wdata_r3_n = sram_wdata_r3_lm;
        end 
        state[RGB]: begin
            sram_wdata_r0_n = sram_wdata_r0_rgb;
            sram_wdata_r1_n = sram_wdata_r1_rgb;
            sram_wdata_r2_n = sram_wdata_r2_rgb;
            sram_wdata_r3_n = sram_wdata_r3_rgb;
        end                 
        default: begin
            sram_wdata_r0_n = 0;
            sram_wdata_r1_n = 0;
            sram_wdata_r2_n = 0;
            sram_wdata_r3_n = 0;
        end
    endcase
end

// wdata_gb
always @* begin
    case (1) // synopsys parallel_case
        state[WB]: begin
            sram_wdata_gb0_n = sram_wdata_gb0_wb;
            sram_wdata_gb1_n = sram_wdata_gb1_wb;
            sram_wdata_gb2_n = sram_wdata_gb2_wb;
            sram_wdata_gb3_n = sram_wdata_gb3_wb;
        end
        state[DEMOS]: begin
            sram_wdata_gb0_n = sram_wdata_gb0_demos;
            sram_wdata_gb1_n = sram_wdata_gb1_demos;
            sram_wdata_gb2_n = sram_wdata_gb2_demos;
            sram_wdata_gb3_n = sram_wdata_gb3_demos;
        end        
        state[GAMMA]: begin
            sram_wdata_gb0_n = sram_wdata_gb0_gamma;
            sram_wdata_gb1_n = sram_wdata_gb1_gamma;
            sram_wdata_gb2_n = sram_wdata_gb2_gamma;
            sram_wdata_gb3_n = sram_wdata_gb3_gamma;
        end
        state[YCBCR]: begin
            sram_wdata_gb0_n = sram_wdata_gb0_ycbcr;
            sram_wdata_gb1_n = sram_wdata_gb1_ycbcr;
            sram_wdata_gb2_n = sram_wdata_gb2_ycbcr;
            sram_wdata_gb3_n = sram_wdata_gb3_ycbcr;
        end  
        state_cbcr_match: begin
            sram_wdata_gb0_n = sram_wdata_gb0_cm;
            sram_wdata_gb1_n = sram_wdata_gb1_cm;
            sram_wdata_gb2_n = sram_wdata_gb2_cm;
            sram_wdata_gb3_n = sram_wdata_gb3_cm;  
        end
        state[RGB]: begin
            sram_wdata_gb0_n = sram_wdata_gb0_rgb;
            sram_wdata_gb1_n = sram_wdata_gb1_rgb;
            sram_wdata_gb2_n = sram_wdata_gb2_rgb;
            sram_wdata_gb3_n = sram_wdata_gb3_rgb;
        end        
        default: begin
            sram_wdata_gb0_n = 0;
            sram_wdata_gb1_n = 0;
            sram_wdata_gb2_n = 0;
            sram_wdata_gb3_n = 0;
        end
    endcase
end

// wdata_fy
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wdata_fy0_n = sram_wdata_fy0_ycbcr;
            sram_wdata_fy1_n = sram_wdata_fy1_ycbcr;
            sram_wdata_fy2_n = sram_wdata_fy2_ycbcr;
            sram_wdata_fy3_n = sram_wdata_fy3_ycbcr;
        end  
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wdata_fy0_n = sram_wdata_fy0_ycbcr;
                sram_wdata_fy1_n = sram_wdata_fy1_ycbcr;
                sram_wdata_fy2_n = sram_wdata_fy2_ycbcr;
                sram_wdata_fy3_n = sram_wdata_fy3_ycbcr;
            end else begin
                sram_wdata_fy0_n = 0;
                sram_wdata_fy1_n = 0;
                sram_wdata_fy2_n = 0;
                sram_wdata_fy3_n = 0;
            end
        end
    endcase
end

// wdata_fc
always @* begin
    case (1) // synopsys parallel_case
        state[YCBCR]: begin
            sram_wdata_fc0_n = sram_wdata_fc0_ycbcr;
            sram_wdata_fc1_n = sram_wdata_fc1_ycbcr;
            sram_wdata_fc2_n = sram_wdata_fc2_ycbcr;
            sram_wdata_fc3_n = sram_wdata_fc3_ycbcr;
        end
        default: begin
            if (state_ref[YCBCR_REF]) begin
                sram_wdata_fc0_n = sram_wdata_fc0_ycbcr;
                sram_wdata_fc1_n = sram_wdata_fc1_ycbcr;
                sram_wdata_fc2_n = sram_wdata_fc2_ycbcr;
                sram_wdata_fc3_n = sram_wdata_fc3_ycbcr;
            end else begin
                sram_wdata_fc0_n = 0;
                sram_wdata_fc1_n = 0;
                sram_wdata_fc2_n = 0;
                sram_wdata_fc3_n = 0;
            end
        end
    endcase
end

// hist_start
always @* begin
    case (1) // synopsys parallel_case
        state[GAMMA]:   hist_start = gamma_hist_start;
        state[LM]:      hist_start = start_lm;
        default:        hist_start = 1'b0;
    endcase
end

// cdf_begin
always @* begin
    case (1) // synopsys parallel_case
        state[GAMMA]:   cdf_begin = gamma_cdf_begin;
        state[LM]:      cdf_begin = cdf_begin_lm;
        default:        cdf_begin = 1'b0;
    endcase
end

// hist_mode
always @* begin
    case (1) // synopsys parallel_case
        state[GAMMA]:   hist_mode = 2'b00;
        state[LM]:      hist_mode = 2'b01;
        default:        hist_mode = 2'b00;
    endcase
end

// light_match
always @* begin
    case (1) // synopsys parallel_case
        state[GAMMA]:   light_match = 0;
        state[LM]:      light_match = src_match_done_lm;
        default:        light_match = 0;
    endcase
end

// hist_in
always @* begin
    case (1) // synopsys parallel_case
        state[GAMMA]:   hist_in = gamma_hist_in;
        state[LM]:      hist_in = src_hist_in_lm;
        default:        hist_in = 0;
    endcase
end

// is_source
always @* begin
    if (state_ref[YCBCR_REF])
        is_source = 0;
    else
        is_source = 1;
end

// sram_rdata_cs
always @* begin
    sram_rdata_0_cs = 0;
    sram_rdata_1_cs = 0;
    sram_rdata_2_cs = 0;
    sram_rdata_3_cs = 0;  
    case (1)
        state_cbcr_src: begin
            sram_rdata_0_cs = sram_rdata_gb0_r;
            sram_rdata_1_cs = sram_rdata_gb1_r;
            sram_rdata_2_cs = sram_rdata_gb2_r;
            sram_rdata_3_cs = sram_rdata_gb3_r;
        end
        state_cbcr_ref: begin
            sram_rdata_0_cs = sram_rdata_fc0_r;
            sram_rdata_1_cs = sram_rdata_fc1_r;
            sram_rdata_2_cs = sram_rdata_fc2_r;
            sram_rdata_3_cs = sram_rdata_fc3_r;
        end
    endcase
end

always @* begin
    case (1) // synopsys parallel_case 
        state[GAMMA]: begin 
            mul_in_1_0  = sram_rdata_r0_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_1  = sram_rdata_r0_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_2  = sram_rdata_r0_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_3  = sram_rdata_r0_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_4  = sram_rdata_r1_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_5  = sram_rdata_r1_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_6  = sram_rdata_r1_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_7  = sram_rdata_r1_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_8  = sram_rdata_r2_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_9  = sram_rdata_r2_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_10 = sram_rdata_r2_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_11 = sram_rdata_r2_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_12 = sram_rdata_r3_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_13 = sram_rdata_r3_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_14 = sram_rdata_r3_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_15 = sram_rdata_r3_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_16 = sram_rdata_gb0_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_17 = sram_rdata_gb0_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_18 = sram_rdata_gb0_r[LINEAR_BW*5 +: LINEAR_BW];
            mul_in_1_19 = sram_rdata_gb0_r[LINEAR_BW*7 +: LINEAR_BW];
            mul_in_1_20 = sram_rdata_gb1_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_21 = sram_rdata_gb1_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_22 = sram_rdata_gb1_r[LINEAR_BW*5 +: LINEAR_BW];
            mul_in_1_23 = sram_rdata_gb1_r[LINEAR_BW*7 +: LINEAR_BW];
            mul_in_1_24 = sram_rdata_gb2_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_25 = sram_rdata_gb2_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_26 = sram_rdata_gb2_r[LINEAR_BW*5 +: LINEAR_BW];
            mul_in_1_27 = sram_rdata_gb2_r[LINEAR_BW*7 +: LINEAR_BW];
            mul_in_1_28 = sram_rdata_gb3_r[LINEAR_BW*1 +: LINEAR_BW];
            mul_in_1_29 = sram_rdata_gb3_r[LINEAR_BW*3 +: LINEAR_BW];
            mul_in_1_30 = sram_rdata_gb3_r[LINEAR_BW*5 +: LINEAR_BW];
            mul_in_1_31 = sram_rdata_gb3_r[LINEAR_BW*7 +: LINEAR_BW];
            mul_in_1_32 = sram_rdata_gb0_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_33 = sram_rdata_gb0_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_34 = sram_rdata_gb0_r[LINEAR_BW*4 +: LINEAR_BW];
            mul_in_1_35 = sram_rdata_gb0_r[LINEAR_BW*6 +: LINEAR_BW];
            mul_in_1_36 = sram_rdata_gb1_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_37 = sram_rdata_gb1_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_38 = sram_rdata_gb1_r[LINEAR_BW*4 +: LINEAR_BW];
            mul_in_1_39 = sram_rdata_gb1_r[LINEAR_BW*6 +: LINEAR_BW];
            mul_in_1_40 = sram_rdata_gb2_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_41 = sram_rdata_gb2_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_42 = sram_rdata_gb2_r[LINEAR_BW*4 +: LINEAR_BW];
            mul_in_1_43 = sram_rdata_gb2_r[LINEAR_BW*6 +: LINEAR_BW];
            mul_in_1_44 = sram_rdata_gb3_r[LINEAR_BW*0 +: LINEAR_BW];
            mul_in_1_45 = sram_rdata_gb3_r[LINEAR_BW*2 +: LINEAR_BW];
            mul_in_1_46 = sram_rdata_gb3_r[LINEAR_BW*4 +: LINEAR_BW];
            mul_in_1_47 = sram_rdata_gb3_r[LINEAR_BW*6 +: LINEAR_BW];

            mul_in_2_0  = wp_inv;
            mul_in_2_1  = wp_inv;
            mul_in_2_2  = wp_inv;
            mul_in_2_3  = wp_inv;
            mul_in_2_4  = wp_inv;
            mul_in_2_5  = wp_inv;
            mul_in_2_6  = wp_inv;
            mul_in_2_7  = wp_inv;
            mul_in_2_8  = wp_inv;
            mul_in_2_9  = wp_inv;
            mul_in_2_10 = wp_inv;
            mul_in_2_11 = wp_inv;
            mul_in_2_12 = wp_inv;
            mul_in_2_13 = wp_inv;
            mul_in_2_14 = wp_inv;
            mul_in_2_15 = wp_inv;
            mul_in_2_16 = wp_inv;
            mul_in_2_17 = wp_inv;
            mul_in_2_18 = wp_inv;
            mul_in_2_19 = wp_inv;
            mul_in_2_20 = wp_inv;
            mul_in_2_21 = wp_inv;
            mul_in_2_22 = wp_inv;
            mul_in_2_23 = wp_inv;
            mul_in_2_24 = wp_inv;
            mul_in_2_25 = wp_inv;
            mul_in_2_26 = wp_inv;
            mul_in_2_27 = wp_inv;
            mul_in_2_28 = wp_inv;
            mul_in_2_29 = wp_inv;
            mul_in_2_30 = wp_inv;
            mul_in_2_31 = wp_inv;
            mul_in_2_32 = wp_inv;
            mul_in_2_33 = wp_inv;
            mul_in_2_34 = wp_inv;
            mul_in_2_35 = wp_inv;
            mul_in_2_36 = wp_inv;
            mul_in_2_37 = wp_inv;
            mul_in_2_38 = wp_inv;
            mul_in_2_39 = wp_inv;
            mul_in_2_40 = wp_inv;
            mul_in_2_41 = wp_inv;
            mul_in_2_42 = wp_inv;
            mul_in_2_43 = wp_inv;
            mul_in_2_44 = wp_inv;
            mul_in_2_45 = wp_inv;
            mul_in_2_46 = wp_inv;
            mul_in_2_47 = wp_inv;
        end
        state_cbcr_ref: begin
            mul_in_1_0  = sram_rdata_fc0_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_1  = sram_rdata_fc0_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_2  = sram_rdata_fc0_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_3  = sram_rdata_fc0_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_4  = sram_rdata_fc1_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_5  = sram_rdata_fc1_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_6  = sram_rdata_fc1_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_7  = sram_rdata_fc1_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_8  = sram_rdata_fc2_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_9  = sram_rdata_fc2_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_10 = sram_rdata_fc2_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_11 = sram_rdata_fc2_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_12 = sram_rdata_fc3_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_13 = sram_rdata_fc3_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_14 = sram_rdata_fc3_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_15 = sram_rdata_fc3_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_16 = sram_rdata_fc0_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_17 = sram_rdata_fc0_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_18 = sram_rdata_fc0_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_19 = sram_rdata_fc0_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_20 = sram_rdata_fc1_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_21 = sram_rdata_fc1_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_22 = sram_rdata_fc1_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_23 = sram_rdata_fc1_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_24 = sram_rdata_fc2_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_25 = sram_rdata_fc2_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_26 = sram_rdata_fc2_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_27 = sram_rdata_fc2_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_28 = sram_rdata_fc3_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_29 = sram_rdata_fc3_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_30 = sram_rdata_fc3_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_31 = sram_rdata_fc3_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_32 = 0;
            mul_in_1_33 = 0;
            mul_in_1_34 = 0;
            mul_in_1_35 = 0;
            mul_in_1_36 = 0;
            mul_in_1_37 = 0;
            mul_in_1_38 = 0;
            mul_in_1_39 = 0;
            mul_in_1_40 = 0;
            mul_in_1_41 = 0;
            mul_in_1_42 = 0;
            mul_in_1_43 = 0;
            mul_in_1_44 = 0;
            mul_in_1_45 = 0;
            mul_in_1_46 = 0;
            mul_in_1_47 = 0;

            mul_in_2_0  = sram_rdata_fc0_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_1  = sram_rdata_fc0_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_2  = sram_rdata_fc0_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_3  = sram_rdata_fc0_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_4  = sram_rdata_fc1_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_5  = sram_rdata_fc1_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_6  = sram_rdata_fc1_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_7  = sram_rdata_fc1_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_8  = sram_rdata_fc2_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_9  = sram_rdata_fc2_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_10 = sram_rdata_fc2_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_11 = sram_rdata_fc2_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_12 = sram_rdata_fc3_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_13 = sram_rdata_fc3_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_14 = sram_rdata_fc3_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_15 = sram_rdata_fc3_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_16 = sram_rdata_fc0_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_17 = sram_rdata_fc0_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_18 = sram_rdata_fc0_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_19 = sram_rdata_fc0_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_20 = sram_rdata_fc1_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_21 = sram_rdata_fc1_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_22 = sram_rdata_fc1_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_23 = sram_rdata_fc1_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_24 = sram_rdata_fc2_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_25 = sram_rdata_fc2_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_26 = sram_rdata_fc2_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_27 = sram_rdata_fc2_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_28 = sram_rdata_fc3_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_29 = sram_rdata_fc3_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_30 = sram_rdata_fc3_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_31 = sram_rdata_fc3_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_32 = 0;
            mul_in_2_33 = 0;
            mul_in_2_34 = 0;
            mul_in_2_35 = 0;
            mul_in_2_36 = 0;
            mul_in_2_37 = 0;
            mul_in_2_38 = 0;
            mul_in_2_39 = 0;
            mul_in_2_40 = 0;
            mul_in_2_41 = 0;
            mul_in_2_42 = 0;
            mul_in_2_43 = 0;
            mul_in_2_44 = 0;
            mul_in_2_45 = 0;
            mul_in_2_46 = 0;
            mul_in_2_47 = 0;
        end

        state_cbcr_src: begin
            mul_in_1_0  = sram_rdata_gb0_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_1  = sram_rdata_gb0_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_2  = sram_rdata_gb0_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_3  = sram_rdata_gb0_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_4  = sram_rdata_gb1_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_5  = sram_rdata_gb1_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_6  = sram_rdata_gb1_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_7  = sram_rdata_gb1_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_8  = sram_rdata_gb2_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_9  = sram_rdata_gb2_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_10 = sram_rdata_gb2_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_11 = sram_rdata_gb2_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_12 = sram_rdata_gb3_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_13 = sram_rdata_gb3_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_14 = sram_rdata_gb3_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_15 = sram_rdata_gb3_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_16 = sram_rdata_gb0_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_17 = sram_rdata_gb0_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_18 = sram_rdata_gb0_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_19 = sram_rdata_gb0_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_20 = sram_rdata_gb1_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_21 = sram_rdata_gb1_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_22 = sram_rdata_gb1_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_23 = sram_rdata_gb1_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_24 = sram_rdata_gb2_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_25 = sram_rdata_gb2_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_26 = sram_rdata_gb2_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_27 = sram_rdata_gb2_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_28 = sram_rdata_gb3_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_29 = sram_rdata_gb3_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_30 = sram_rdata_gb3_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_31 = sram_rdata_gb3_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_32 = 0;
            mul_in_1_33 = 0;
            mul_in_1_34 = 0;
            mul_in_1_35 = 0;
            mul_in_1_36 = 0;
            mul_in_1_37 = 0;
            mul_in_1_38 = 0;
            mul_in_1_39 = 0;
            mul_in_1_40 = 0;
            mul_in_1_41 = 0;
            mul_in_1_42 = 0;
            mul_in_1_43 = 0;
            mul_in_1_44 = 0;
            mul_in_1_45 = 0;
            mul_in_1_46 = 0;
            mul_in_1_47 = 0;

            mul_in_2_0  = sram_rdata_gb0_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_1  = sram_rdata_gb0_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_2  = sram_rdata_gb0_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_3  = sram_rdata_gb0_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_4  = sram_rdata_gb1_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_5  = sram_rdata_gb1_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_6  = sram_rdata_gb1_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_7  = sram_rdata_gb1_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_8  = sram_rdata_gb2_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_9  = sram_rdata_gb2_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_10 = sram_rdata_gb2_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_11 = sram_rdata_gb2_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_12 = sram_rdata_gb3_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_2_13 = sram_rdata_gb3_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_2_14 = sram_rdata_gb3_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_2_15 = sram_rdata_gb3_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_2_16 = sram_rdata_gb0_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_17 = sram_rdata_gb0_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_18 = sram_rdata_gb0_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_19 = sram_rdata_gb0_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_20 = sram_rdata_gb1_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_21 = sram_rdata_gb1_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_22 = sram_rdata_gb1_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_23 = sram_rdata_gb1_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_24 = sram_rdata_gb2_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_25 = sram_rdata_gb2_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_26 = sram_rdata_gb2_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_27 = sram_rdata_gb2_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_28 = sram_rdata_gb3_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_2_29 = sram_rdata_gb3_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_2_30 = sram_rdata_gb3_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_2_31 = sram_rdata_gb3_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_2_32 = 0;
            mul_in_2_33 = 0;
            mul_in_2_34 = 0;
            mul_in_2_35 = 0;
            mul_in_2_36 = 0;
            mul_in_2_37 = 0;
            mul_in_2_38 = 0;
            mul_in_2_39 = 0;
            mul_in_2_40 = 0;
            mul_in_2_41 = 0;
            mul_in_2_42 = 0;
            mul_in_2_43 = 0;
            mul_in_2_44 = 0;
            mul_in_2_45 = 0;
            mul_in_2_46 = 0;
            mul_in_2_47 = 0;
        end

        state_cbcr_match: begin
            mul_in_1_0  = sram_rdata_gb0_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_1  = sram_rdata_gb0_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_2  = sram_rdata_gb0_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_3  = sram_rdata_gb0_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_4  = sram_rdata_gb1_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_5  = sram_rdata_gb1_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_6  = sram_rdata_gb1_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_7  = sram_rdata_gb1_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_8  = sram_rdata_gb2_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_9  = sram_rdata_gb2_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_10 = sram_rdata_gb2_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_11 = sram_rdata_gb2_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_12 = sram_rdata_gb3_r[7*LINEAR_BW +: LINEAR_BW];
            mul_in_1_13 = sram_rdata_gb3_r[5*LINEAR_BW +: LINEAR_BW];
            mul_in_1_14 = sram_rdata_gb3_r[3*LINEAR_BW +: LINEAR_BW];
            mul_in_1_15 = sram_rdata_gb3_r[1*LINEAR_BW +: LINEAR_BW];
            mul_in_1_16 = sram_rdata_gb0_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_17 = sram_rdata_gb0_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_18 = sram_rdata_gb0_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_19 = sram_rdata_gb0_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_20 = sram_rdata_gb1_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_21 = sram_rdata_gb1_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_22 = sram_rdata_gb1_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_23 = sram_rdata_gb1_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_24 = sram_rdata_gb2_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_25 = sram_rdata_gb2_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_26 = sram_rdata_gb2_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_27 = sram_rdata_gb2_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_28 = sram_rdata_gb3_r[6*LINEAR_BW +: LINEAR_BW];
            mul_in_1_29 = sram_rdata_gb3_r[4*LINEAR_BW +: LINEAR_BW];
            mul_in_1_30 = sram_rdata_gb3_r[2*LINEAR_BW +: LINEAR_BW];
            mul_in_1_31 = sram_rdata_gb3_r[0*LINEAR_BW +: LINEAR_BW];
            mul_in_1_32 = 0;
            mul_in_1_33 = 0;
            mul_in_1_34 = 0;
            mul_in_1_35 = 0;
            mul_in_1_36 = 0;
            mul_in_1_37 = 0;
            mul_in_1_38 = 0;
            mul_in_1_39 = 0;
            mul_in_1_40 = 0;
            mul_in_1_41 = 0;
            mul_in_1_42 = 0;
            mul_in_1_43 = 0;
            mul_in_1_44 = 0;
            mul_in_1_45 = 0;
            mul_in_1_46 = 0;
            mul_in_1_47 = 0;

            mul_in_2_0  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_1  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_2  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_3  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_4  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_5  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_6  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_7  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_8  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_9  = {3'd0, sqrt_sigma_Cb};
            mul_in_2_10 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_11 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_12 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_13 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_14 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_15 = {3'd0, sqrt_sigma_Cb};
            mul_in_2_16 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_17 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_18 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_19 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_20 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_21 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_22 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_23 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_24 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_25 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_26 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_27 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_28 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_29 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_30 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_31 = {3'd0, sqrt_sigma_Cr};
            mul_in_2_32 = 0;
            mul_in_2_33 = 0;
            mul_in_2_34 = 0;
            mul_in_2_35 = 0;
            mul_in_2_36 = 0;
            mul_in_2_37 = 0;
            mul_in_2_38 = 0;
            mul_in_2_39 = 0;
            mul_in_2_40 = 0;
            mul_in_2_41 = 0;
            mul_in_2_42 = 0;
            mul_in_2_43 = 0;
            mul_in_2_44 = 0;
            mul_in_2_45 = 0;
            mul_in_2_46 = 0;
            mul_in_2_47 = 0;
        end

        default: begin
            mul_in_1_0  = 0;
            mul_in_1_1  = 0;
            mul_in_1_2  = 0;
            mul_in_1_3  = 0;
            mul_in_1_4  = 0;
            mul_in_1_5  = 0;
            mul_in_1_6  = 0;
            mul_in_1_7  = 0;
            mul_in_1_8  = 0;
            mul_in_1_9  = 0;
            mul_in_1_10 = 0;
            mul_in_1_11 = 0;
            mul_in_1_12 = 0;
            mul_in_1_13 = 0;
            mul_in_1_14 = 0;
            mul_in_1_15 = 0;
            mul_in_1_16 = 0;
            mul_in_1_17 = 0;
            mul_in_1_18 = 0;
            mul_in_1_19 = 0;
            mul_in_1_20 = 0;
            mul_in_1_21 = 0;
            mul_in_1_22 = 0;
            mul_in_1_23 = 0;
            mul_in_1_24 = 0;
            mul_in_1_25 = 0;
            mul_in_1_26 = 0;
            mul_in_1_27 = 0;
            mul_in_1_28 = 0;
            mul_in_1_29 = 0;
            mul_in_1_30 = 0;
            mul_in_1_31 = 0;
            mul_in_1_32 = 0;
            mul_in_1_33 = 0;
            mul_in_1_34 = 0;
            mul_in_1_35 = 0;
            mul_in_1_36 = 0;
            mul_in_1_37 = 0;
            mul_in_1_38 = 0;
            mul_in_1_39 = 0;
            mul_in_1_40 = 0;
            mul_in_1_41 = 0;
            mul_in_1_42 = 0;
            mul_in_1_43 = 0;
            mul_in_1_44 = 0;
            mul_in_1_45 = 0;
            mul_in_1_46 = 0;
            mul_in_1_47 = 0;

            mul_in_2_0  = 0;
            mul_in_2_1  = 0;
            mul_in_2_2  = 0;
            mul_in_2_3  = 0;
            mul_in_2_4  = 0;
            mul_in_2_5  = 0;
            mul_in_2_6  = 0;
            mul_in_2_7  = 0;
            mul_in_2_8  = 0;
            mul_in_2_9  = 0;
            mul_in_2_10 = 0;
            mul_in_2_11 = 0;
            mul_in_2_12 = 0;
            mul_in_2_13 = 0;
            mul_in_2_14 = 0;
            mul_in_2_15 = 0;
            mul_in_2_16 = 0;
            mul_in_2_17 = 0;
            mul_in_2_18 = 0;
            mul_in_2_19 = 0;
            mul_in_2_20 = 0;
            mul_in_2_21 = 0;
            mul_in_2_22 = 0;
            mul_in_2_23 = 0;
            mul_in_2_24 = 0;
            mul_in_2_25 = 0;
            mul_in_2_26 = 0;
            mul_in_2_27 = 0;
            mul_in_2_28 = 0;
            mul_in_2_29 = 0;
            mul_in_2_30 = 0;
            mul_in_2_31 = 0;
            mul_in_2_32 = 0;
            mul_in_2_33 = 0;
            mul_in_2_34 = 0;
            mul_in_2_35 = 0;
            mul_in_2_36 = 0;
            mul_in_2_37 = 0;
            mul_in_2_38 = 0;
            mul_in_2_39 = 0;
            mul_in_2_40 = 0;
            mul_in_2_41 = 0;
            mul_in_2_42 = 0;
            mul_in_2_43 = 0;
            mul_in_2_44 = 0;
            mul_in_2_45 = 0;
            mul_in_2_46 = 0;
            mul_in_2_47 = 0;
        end
    endcase
end

//------submodule_connection------//
wb #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW)
) wb_U0 (
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[WB]),
    .done(wb_done),

    .sram_rdata_r0(sram_rdata_r0_r),
    // .sram_rdata_r1(sram_rdata_r1_r),
    .sram_rdata_r2(sram_rdata_r2_r),
    // .sram_rdata_r3(sram_rdata_r3_r),
    .sram_rdata_gb0(sram_rdata_gb0_r),
    .sram_rdata_gb1(sram_rdata_gb1_r),
    .sram_rdata_gb2(sram_rdata_gb2_r),
    .sram_rdata_gb3(sram_rdata_gb3_r),

    .sram_raddr_r0(sram_raddr_r0_wb),
    .sram_raddr_r2(sram_raddr_r2_wb),
    .sram_raddr_gb0(sram_raddr_gb0_wb),
    .sram_raddr_gb1(sram_raddr_gb1_wb),
    .sram_raddr_gb2(sram_raddr_gb2_wb),
    .sram_raddr_gb3(sram_raddr_gb3_wb),

    .sram_waddr_r0(sram_waddr_r0_wb),
    .sram_waddr_r2(sram_waddr_r2_wb),
    .sram_waddr_gb0(sram_waddr_gb0_wb),
    .sram_waddr_gb1(sram_waddr_gb1_wb),
    .sram_waddr_gb2(sram_waddr_gb2_wb),
    .sram_waddr_gb3(sram_waddr_gb3_wb),

    .sram_wen_r0(sram_wen_r0_wb),
    .sram_wen_r2(sram_wen_r2_wb),
    .sram_wen_gb0(sram_wen_gb0_wb),
    .sram_wen_gb1(sram_wen_gb1_wb),
    .sram_wen_gb2(sram_wen_gb2_wb),
    .sram_wen_gb3(sram_wen_gb3_wb),

    .sram_wordmask_r0(sram_wordmask_r0_wb),
    .sram_wordmask_r2(sram_wordmask_r2_wb),
    .sram_wordmask_gb0(sram_wordmask_gb0_wb),
    .sram_wordmask_gb1(sram_wordmask_gb1_wb),
    .sram_wordmask_gb2(sram_wordmask_gb2_wb),
    .sram_wordmask_gb3(sram_wordmask_gb3_wb),

    .sram_wdata_r0(sram_wdata_r0_wb),
    .sram_wdata_r2(sram_wdata_r2_wb),
    .sram_wdata_gb0(sram_wdata_gb0_wb),
    .sram_wdata_gb1(sram_wdata_gb1_wb),
    .sram_wdata_gb2(sram_wdata_gb2_wb),
    .sram_wdata_gb3(sram_wdata_gb3_wb)
);



demosaic #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW)
) demosaic_U0(
    // Control signals
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[DEMOS]),
    .done(demos_done),
    // SRAM read data inputs 
    .sram_rdata_r0(sram_rdata_r0_r),
    .sram_rdata_r2(sram_rdata_r2_r),
    .sram_rdata_gb0(sram_rdata_gb0_r),
    .sram_rdata_gb1(sram_rdata_gb1_r),
    .sram_rdata_gb2(sram_rdata_gb2_r),
    .sram_rdata_gb3(sram_rdata_gb3_r),

    // SRAM read write address outputs -> 1920*1080/16 (share)
    .sram_raddr_rgb0123(sram_raddr_rgb0123_demos),
    .sram_waddr_rgb0123(sram_waddr_rgb0123_demos),
    // SRAM write enable outputs (neg.)
    .sram_wen_rgb01(sram_wen_rgb01_demos),
    .sram_wen_rgb23(sram_wen_rgb23_demos),
    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    .sram_wordmask_r02(sram_wordmask_r02_demos),
    .sram_wordmask_r13(sram_wordmask_r13_demos),
    .sram_wordmask_gb02(sram_wordmask_gb02_demos),
    .sram_wordmask_gb13(sram_wordmask_gb13_demos),
    // SRAM write data outputs
    .sram_wdata_r0(sram_wdata_r0_demos),
    .sram_wdata_r1(sram_wdata_r1_demos),
    .sram_wdata_r2(sram_wdata_r2_demos),
    .sram_wdata_r3(sram_wdata_r3_demos),
    .sram_wdata_gb0(sram_wdata_gb0_demos),
    .sram_wdata_gb1(sram_wdata_gb1_demos),
    .sram_wdata_gb2(sram_wdata_gb2_demos),
    .sram_wdata_gb3(sram_wdata_gb3_demos)
);

// gamma & src
histogram # (
    .LINEAR_BW(LINEAR_BW),
    .BIN_BW(BIN_BW)   
) HIST_U0 (
    .clk(clk),
    .srst_n(srst_n),
    .start(hist_start),
    .cdf_begin(cdf_begin),
    .match_done(light_match),
    .mode(hist_mode),
    .hist_in(hist_in),
    .cdf_done(cdf_done),
    .white_point(white_point),
    .wp_get(wp_get),
    .light_get(light_get)
);

// ref
histogram # (
    .LINEAR_BW(BIN_BW),
    .BIN_BW(BIN_BW)   
) HIST_U1 (
    .clk(clk),
    .srst_n(srst_n),
    .start(start_lm),
    .cdf_begin(cdf_begin_lm),

    .match_done(ref_match_done_lm),
    .mode(2'b10),
    .hist_in(ref_hist_in_lm),
    .cdf_done(ref_cdf_done_lm),
    .white_point(ref_white_point_lm),
    .wp_get(),
    .light_get(ref_light_get_lm)
);


gamma # (
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW),
    .RGB_BW(RGB_BW),
    .HEIGHT(HEIGHT),
    .WIDTH(WIDTH)
) gamma_U0 (
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[GAMMA]),
    .done(gamma_done),

    .sram_rdata_r0(sram_rdata_r0_r),
    // .sram_rdata_r1(sram_rdata_r1_r),
    // .sram_rdata_r2(sram_rdata_r2_r),
    // .sram_rdata_r3(sram_rdata_r3_r),
    .sram_rdata_gb0(sram_rdata_gb0_r),
    // .sram_rdata_gb1(sram_rdata_gb1_r),
    // .sram_rdata_gb2(sram_rdata_gb2_r),
    // .sram_rdata_gb3(sram_rdata_gb3_r),

    .sram_raddr_gamma(sram_raddr_gamma),
    .sram_waddr_gamma(sram_waddr_gamma),

    .sram_wen_gamma(sram_wen_gamma),

    .sram_wordmask_gamma_r(sram_wordmask_gamma_r),
    .sram_wordmask_gamma_gb(sram_wordmask_gamma_gb),

    .sram_wdata_r0(sram_wdata_r0_gamma),
    .sram_wdata_r1(sram_wdata_r1_gamma),
    .sram_wdata_r2(sram_wdata_r2_gamma),
    .sram_wdata_r3(sram_wdata_r3_gamma),
    .sram_wdata_gb0(sram_wdata_gb0_gamma),
    .sram_wdata_gb1(sram_wdata_gb1_gamma),
    .sram_wdata_gb2(sram_wdata_gb2_gamma),
    .sram_wdata_gb3(sram_wdata_gb3_gamma),

    .white_point(white_point[7:0]),
    .wp_get(wp_get),
    .gamma_hist_start(gamma_hist_start),
    .gamma_cdf_begin(gamma_cdf_begin),
    .gamma_hist_in(gamma_hist_in),

    .norm_r0_0_nx_tmp(mul_out_0[27:0]),
    .norm_r0_1_nx_tmp(mul_out_1[27:0]),
    .norm_r0_2_nx_tmp(mul_out_2[27:0]),
    .norm_r0_3_nx_tmp(mul_out_3[27:0]),
    .norm_r1_0_nx_tmp(mul_out_4[27:0]),
    .norm_r1_1_nx_tmp(mul_out_5[27:0]),
    .norm_r1_2_nx_tmp(mul_out_6[27:0]),
    .norm_r1_3_nx_tmp(mul_out_7[27:0]),
    .norm_r2_0_nx_tmp(mul_out_8[27:0]),
    .norm_r2_1_nx_tmp(mul_out_9[27:0]),
    .norm_r2_2_nx_tmp(mul_out_10[27:0]),
    .norm_r2_3_nx_tmp(mul_out_11[27:0]),
    .norm_r3_0_nx_tmp(mul_out_12[27:0]),
    .norm_r3_1_nx_tmp(mul_out_13[27:0]),
    .norm_r3_2_nx_tmp(mul_out_14[27:0]),
    .norm_r3_3_nx_tmp(mul_out_15[27:0]),
    .norm_g0_0_nx_tmp(mul_out_16[27:0]),
    .norm_g0_1_nx_tmp(mul_out_17[27:0]),
    .norm_g0_2_nx_tmp(mul_out_18[27:0]),
    .norm_g0_3_nx_tmp(mul_out_19[27:0]),
    .norm_g1_0_nx_tmp(mul_out_20[27:0]),
    .norm_g1_1_nx_tmp(mul_out_21[27:0]),
    .norm_g1_2_nx_tmp(mul_out_22[27:0]),
    .norm_g1_3_nx_tmp(mul_out_23[27:0]),
    .norm_g2_0_nx_tmp(mul_out_24[27:0]),
    .norm_g2_1_nx_tmp(mul_out_25[27:0]),
    .norm_g2_2_nx_tmp(mul_out_26[27:0]),
    .norm_g2_3_nx_tmp(mul_out_27[27:0]),
    .norm_g3_0_nx_tmp(mul_out_28[27:0]),
    .norm_g3_1_nx_tmp(mul_out_29[27:0]),
    .norm_g3_2_nx_tmp(mul_out_30[27:0]),
    .norm_g3_3_nx_tmp(mul_out_31[27:0]),
    .norm_b0_0_nx_tmp(mul_out_32[27:0]),
    .norm_b0_1_nx_tmp(mul_out_33[27:0]),
    .norm_b0_2_nx_tmp(mul_out_34[27:0]),
    .norm_b0_3_nx_tmp(mul_out_35[27:0]),
    .norm_b1_0_nx_tmp(mul_out_36[27:0]),
    .norm_b1_1_nx_tmp(mul_out_37[27:0]),
    .norm_b1_2_nx_tmp(mul_out_38[27:0]),
    .norm_b1_3_nx_tmp(mul_out_39[27:0]),
    .norm_b2_0_nx_tmp(mul_out_40[27:0]),
    .norm_b2_1_nx_tmp(mul_out_41[27:0]),
    .norm_b2_2_nx_tmp(mul_out_42[27:0]),
    .norm_b2_3_nx_tmp(mul_out_43[27:0]),
    .norm_b3_0_nx_tmp(mul_out_44[27:0]),
    .norm_b3_1_nx_tmp(mul_out_45[27:0]),
    .norm_b3_2_nx_tmp(mul_out_46[27:0]),
    .norm_b3_3_nx_tmp(mul_out_47[27:0]),
    .wp_inv(wp_inv)
);


ycbcr #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW),
    .RGB_BW(RGB_BW),
    .CBCR_BW(CBCR_BW)
) ycbcr_U0(
    // Control signals
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[YCBCR] || state_ref[YCBCR_REF]),
    .is_source(is_source),               // ref = 0; source = 1
    .done(ycbcr_done),
    // SRAM read data inputs 
    .sram_rdata_r0(sram_rdata_r0_r),
    .sram_rdata_r1(sram_rdata_r1_r),
    .sram_rdata_r2(sram_rdata_r2_r),
    .sram_rdata_r3(sram_rdata_r3_r),
    .sram_rdata_gb0(sram_rdata_gb0_r),
    .sram_rdata_gb1(sram_rdata_gb1_r),
    .sram_rdata_gb2(sram_rdata_gb2_r),
    .sram_rdata_gb3(sram_rdata_gb3_r),
    // SRAM_FY for reference Y channel
    .sram_rdata_fy0(sram_rdata_fy0_r),
    .sram_rdata_fy1(sram_rdata_fy1_r),
    .sram_rdata_fy2(sram_rdata_fy2_r),
    .sram_rdata_fy3(sram_rdata_fy3_r),
    // SRAM_FC for reference CbCr channel
    .sram_rdata_fc0(sram_rdata_fc0_r),
    .sram_rdata_fc1(sram_rdata_fc1_r),
    .sram_rdata_fc2(sram_rdata_fc2_r),
    .sram_rdata_fc3(sram_rdata_fc3_r),
    // SRAM read address outputs -> 1920*1080/16
    .sram_raddr_rgb0123(sram_raddr_rgb0123_ycbcr),
    .sram_raddr_fyfc0123(sram_raddr_fyfc0123_ycbcr),
    // SRAM write address outputs -> 1920*1080/16
    .sram_waddr_rgb0123(sram_waddr_rgb0123_ycbcr),
    .sram_waddr_fyfc0123(sram_waddr_fyfc0123_ycbcr),
    // SRAM write enable outputs (neg.)
    .sram_wen_rgb0123(sram_wen_rgb0123_ycbcr),
    .sram_wen_fyfc0123(sram_wen_fyfc0123_ycbcr),
    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    .sram_wordmask_r0123(sram_wordmask_r0123_ycbcr),
    .sram_wordmask_gb0123(sram_wordmask_gb0123_ycbcr),
    .sram_wordmask_fy0123(sram_wordmask_fy0123_ycbcr),
    .sram_wordmask_fc0123(sram_wordmask_fc0123_ycbcr),
    // SRAM write data outputs
    .sram_wdata_r0(sram_wdata_r0_ycbcr),
    .sram_wdata_r1(sram_wdata_r1_ycbcr),
    .sram_wdata_r2(sram_wdata_r2_ycbcr),
    .sram_wdata_r3(sram_wdata_r3_ycbcr),

    .sram_wdata_gb0(sram_wdata_gb0_ycbcr),
    .sram_wdata_gb1(sram_wdata_gb1_ycbcr),
    .sram_wdata_gb2(sram_wdata_gb2_ycbcr),
    .sram_wdata_gb3(sram_wdata_gb3_ycbcr),

    .sram_wdata_fy0(sram_wdata_fy0_ycbcr),
    .sram_wdata_fy1(sram_wdata_fy1_ycbcr),
    .sram_wdata_fy2(sram_wdata_fy2_ycbcr),
    .sram_wdata_fy3(sram_wdata_fy3_ycbcr),

    .sram_wdata_fc0(sram_wdata_fc0_ycbcr),
    .sram_wdata_fc1(sram_wdata_fc1_ycbcr),
    .sram_wdata_fc2(sram_wdata_fc2_ycbcr),
    .sram_wdata_fc3(sram_wdata_fc3_ycbcr)
);

light_match #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW),
    .RGB_BW(RGB_BW),    
    .HEIGHT(HEIGHT),
    .WIDTH(WIDTH),
    .BIN_BW(BIN_BW)
) light_match_U0 (
    // Control signals
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[LM]),
    .done(lm_done),
    // SRAM
    .sram_rdata_r0(sram_rdata_r0_r),
    .sram_rdata_r1(sram_rdata_r1_r),
    .sram_rdata_r2(sram_rdata_r2_r),
    .sram_rdata_r3(sram_rdata_r3_r),
    .sram_rdata_fy0(sram_rdata_fy0_r),

    .sram_raddr_r0123(sram_raddr_r0123_lm),
    .sram_raddr_fy0123(sram_raddr_fy0123_lm),
    .sram_waddr_r0123(sram_waddr_r0123_lm),

    .sram_wen_r0123(sram_wen_r0123_lm),
    .sram_wordmask_r0123(sram_wordmask_r0123_lm),

    .sram_wdata_r0(sram_wdata_r0_lm),
    .sram_wdata_r1(sram_wdata_r1_lm),
    .sram_wdata_r2(sram_wdata_r2_lm),
    .sram_wdata_r3(sram_wdata_r3_lm),

    // histogram
    // 00: white point, 01: read (src) , 10: search light match (ref)
    .src_cdf_done(cdf_done),
    .src_white_point(white_point),
    .src_light_get(light_get),
    .ref_cdf_done(ref_cdf_done_lm),
    .ref_white_point(ref_white_point_lm),
    .ref_light_get(ref_light_get_lm),

    .start(start_lm),
    .cdf_begin(cdf_begin_lm),

    .src_match_done(src_match_done_lm),
    .src_hist_in(src_hist_in_lm),
    .ref_match_done(ref_match_done_lm),
    .ref_hist_in(ref_hist_in_lm)
);

// chroma_stats
chroma_stats #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW)
) chroma_stats (
    .clk(clk),
    .srst_n(srst_n),
    .enable(state_cbcr_src || state_cbcr_ref),
    .done(cs_done),

    .sram_rdata_0(sram_rdata_0_cs),
    .sram_rdata_1(sram_rdata_1_cs),
    .sram_rdata_2(sram_rdata_2_cs),
    .sram_rdata_3(sram_rdata_3_cs),

    .sram_raddr_0(sram_raddr_0_cs),
    .sram_raddr_1(sram_raddr_1_cs),
    .sram_raddr_2(sram_raddr_2_cs),
    .sram_raddr_3(sram_raddr_3_cs),

    .mu_Cb(mu_Cb_cs),
    .mu_Cr(mu_Cr_cs),
    .sqr_sigma_Cb(sqr_sigma_Cb_cs),
    .sqr_sigma_Cr(sqr_sigma_Cr_cs),

    .cb_sqr_0(mul_out_0),
    .cb_sqr_1(mul_out_1),
    .cb_sqr_2(mul_out_2),
    .cb_sqr_3(mul_out_3),
    .cb_sqr_4(mul_out_4),
    .cb_sqr_5(mul_out_5),
    .cb_sqr_6(mul_out_6),
    .cb_sqr_7(mul_out_7),
    .cb_sqr_8(mul_out_8),
    .cb_sqr_9(mul_out_9),
    .cb_sqr_10(mul_out_10),
    .cb_sqr_11(mul_out_11),
    .cb_sqr_12(mul_out_12),
    .cb_sqr_13(mul_out_13),
    .cb_sqr_14(mul_out_14),
    .cb_sqr_15(mul_out_15),
    .cr_sqr_0(mul_out_16),
    .cr_sqr_1(mul_out_17),
    .cr_sqr_2(mul_out_18),
    .cr_sqr_3(mul_out_19),
    .cr_sqr_4(mul_out_20),
    .cr_sqr_5(mul_out_21),
    .cr_sqr_6(mul_out_22),
    .cr_sqr_7(mul_out_23),
    .cr_sqr_8(mul_out_24),
    .cr_sqr_9(mul_out_25),
    .cr_sqr_10(mul_out_26),
    .cr_sqr_11(mul_out_27),
    .cr_sqr_12(mul_out_28),
    .cr_sqr_13(mul_out_29),
    .cr_sqr_14(mul_out_30),
    .cr_sqr_15(mul_out_31)
);

// color_match
color_mapping #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW)
) color_mapping (
    .clk(clk),
    .srst_n(srst_n),
    .enable(state_cbcr_match),
    .done(cm_done),

    .mu_Cb_src(mu_Cb_src),
    .mu_Cr_src(mu_Cr_src),
    .sqr_sigma_Cb_src(sqr_sigma_Cb_src),
    .sqr_sigma_Cr_src(sqr_sigma_Cr_src),

    .mu_Cb_ref(mu_Cb_ref),
    .mu_Cr_ref(mu_Cr_ref),
    .sqr_sigma_Cb_ref(sqr_sigma_Cb_ref),
    .sqr_sigma_Cr_ref(sqr_sigma_Cr_ref),

    // .sram_rdata_gb0(sram_rdata_gb0_r),
    // .sram_rdata_gb1(sram_rdata_gb1_r),
    // .sram_rdata_gb2(sram_rdata_gb2_r),
    // .sram_rdata_gb3(sram_rdata_gb3_r),

    .sram_raddr_gb0(sram_raddr_gb0_cm),
    .sram_raddr_gb1(sram_raddr_gb1_cm),
    .sram_raddr_gb2(sram_raddr_gb2_cm),
    .sram_raddr_gb3(sram_raddr_gb3_cm),

    .sram_waddr_gb0(sram_waddr_gb0_cm),
    .sram_waddr_gb1(sram_waddr_gb1_cm),
    .sram_waddr_gb2(sram_waddr_gb2_cm),
    .sram_waddr_gb3(sram_waddr_gb3_cm),

    .sram_wordmask_gb0(sram_wordmask_gb0_cm),
    .sram_wordmask_gb1(sram_wordmask_gb1_cm),
    .sram_wordmask_gb2(sram_wordmask_gb2_cm),
    .sram_wordmask_gb3(sram_wordmask_gb3_cm),

    .sram_wdata_gb0(sram_wdata_gb0_cm),
    .sram_wdata_gb1(sram_wdata_gb1_cm),
    .sram_wdata_gb2(sram_wdata_gb2_cm),
    .sram_wdata_gb3(sram_wdata_gb3_cm),

    .sram_wen_gb0(sram_wen_gb0_cm),
    .sram_wen_gb1(sram_wen_gb1_cm),
    .sram_wen_gb2(sram_wen_gb2_cm),
    .sram_wen_gb3(sram_wen_gb3_cm),

    .mul_out_cb_0(mul_out_0[28:0]),
    .mul_out_cb_1(mul_out_1[28:0]),
    .mul_out_cb_2(mul_out_2[28:0]),
    .mul_out_cb_3(mul_out_3[28:0]),
    .mul_out_cb_4(mul_out_4[28:0]),
    .mul_out_cb_5(mul_out_5[28:0]),
    .mul_out_cb_6(mul_out_6[28:0]),
    .mul_out_cb_7(mul_out_7[28:0]),
    .mul_out_cb_8(mul_out_8[28:0]),
    .mul_out_cb_9(mul_out_9[28:0]),
    .mul_out_cb_10(mul_out_10[28:0]),
    .mul_out_cb_11(mul_out_11[28:0]),
    .mul_out_cb_12(mul_out_12[28:0]),
    .mul_out_cb_13(mul_out_13[28:0]),
    .mul_out_cb_14(mul_out_14[28:0]),
    .mul_out_cb_15(mul_out_15[28:0]),
    .mul_out_cr_0(mul_out_16[28:0]),
    .mul_out_cr_1(mul_out_17[28:0]),
    .mul_out_cr_2(mul_out_18[28:0]),
    .mul_out_cr_3(mul_out_19[28:0]),
    .mul_out_cr_4(mul_out_20[28:0]),
    .mul_out_cr_5(mul_out_21[28:0]),
    .mul_out_cr_6(mul_out_22[28:0]),
    .mul_out_cr_7(mul_out_23[28:0]),
    .mul_out_cr_8(mul_out_24[28:0]),
    .mul_out_cr_9(mul_out_25[28:0]),
    .mul_out_cr_10(mul_out_26[28:0]),
    .mul_out_cr_11(mul_out_27[28:0]),
    .mul_out_cr_12(mul_out_28[28:0]),
    .mul_out_cr_13(mul_out_29[28:0]),
    .mul_out_cr_14(mul_out_30[28:0]),
    .mul_out_cr_15(mul_out_31[28:0]),
    .sqrt_sigma_Cb(sqrt_sigma_Cb),
    .sqrt_sigma_Cr(sqrt_sigma_Cr)
);

rgb #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW),
    .RGB_BW(RGB_BW)
) rgb_U0 (
    // Control signals
    .clk(clk),
    .srst_n(srst_n),
    .enable(state[RGB]),
    .done(rgb_done),

    // SRAM read data inputs 
    .sram_rdata_r0(sram_rdata_r0_r),
    .sram_rdata_r1(sram_rdata_r1_r),
    .sram_rdata_r2(sram_rdata_r2_r),
    .sram_rdata_r3(sram_rdata_r3_r),
    .sram_rdata_gb0(sram_rdata_gb0_r),
    .sram_rdata_gb1(sram_rdata_gb1_r),
    .sram_rdata_gb2(sram_rdata_gb2_r),
    .sram_rdata_gb3(sram_rdata_gb3_r),
    // SRAM read address outputs -> 1920*1080/16
    .sram_raddr_rgb0123(sram_raddr_rgb0123_rgb),
    .sram_waddr_rgb0123(sram_waddr_rgb0123_rgb),
    .sram_wen_rgb0123(sram_wen_rgb0123_rgb),
    .sram_wordmask_r0123(sram_wordmask_r0123_rgb),
    .sram_wordmask_gb0123(sram_wordmask_gb0123_rgb),
    .sram_wdata_r0(sram_wdata_r0_rgb),
    .sram_wdata_r1(sram_wdata_r1_rgb),
    .sram_wdata_r2(sram_wdata_r2_rgb),
    .sram_wdata_r3(sram_wdata_r3_rgb),
    .sram_wdata_gb0(sram_wdata_gb0_rgb),
    .sram_wdata_gb1(sram_wdata_gb1_rgb),
    .sram_wdata_gb2(sram_wdata_gb2_rgb),
    .sram_wdata_gb3(sram_wdata_gb3_rgb)
);

mul # (
    .IN_BW_1(MUL_IN_BW_1),
    .IN_BW_2(MUL_IN_BW_2)
) MUL (
    .in_1_0(mul_in_1_0),
    .in_1_1(mul_in_1_1),
    .in_1_2(mul_in_1_2),
    .in_1_3(mul_in_1_3),
    .in_1_4(mul_in_1_4),
    .in_1_5(mul_in_1_5),
    .in_1_6(mul_in_1_6),
    .in_1_7(mul_in_1_7),
    .in_1_8(mul_in_1_8),
    .in_1_9(mul_in_1_9),
    .in_1_10(mul_in_1_10),
    .in_1_11(mul_in_1_11),
    .in_1_12(mul_in_1_12),
    .in_1_13(mul_in_1_13),
    .in_1_14(mul_in_1_14),
    .in_1_15(mul_in_1_15),
    .in_1_16(mul_in_1_16),
    .in_1_17(mul_in_1_17),
    .in_1_18(mul_in_1_18),
    .in_1_19(mul_in_1_19),
    .in_1_20(mul_in_1_20),
    .in_1_21(mul_in_1_21),
    .in_1_22(mul_in_1_22),
    .in_1_23(mul_in_1_23),
    .in_1_24(mul_in_1_24),
    .in_1_25(mul_in_1_25),
    .in_1_26(mul_in_1_26),
    .in_1_27(mul_in_1_27),
    .in_1_28(mul_in_1_28),
    .in_1_29(mul_in_1_29),
    .in_1_30(mul_in_1_30),
    .in_1_31(mul_in_1_31),
    .in_1_32(mul_in_1_32),
    .in_1_33(mul_in_1_33),
    .in_1_34(mul_in_1_34),
    .in_1_35(mul_in_1_35),
    .in_1_36(mul_in_1_36),
    .in_1_37(mul_in_1_37),
    .in_1_38(mul_in_1_38),
    .in_1_39(mul_in_1_39),
    .in_1_40(mul_in_1_40),
    .in_1_41(mul_in_1_41),
    .in_1_42(mul_in_1_42),
    .in_1_43(mul_in_1_43),
    .in_1_44(mul_in_1_44),
    .in_1_45(mul_in_1_45),
    .in_1_46(mul_in_1_46),
    .in_1_47(mul_in_1_47),

    .in_2_0(mul_in_2_0),
    .in_2_1(mul_in_2_1),
    .in_2_2(mul_in_2_2),
    .in_2_3(mul_in_2_3),
    .in_2_4(mul_in_2_4),
    .in_2_5(mul_in_2_5),
    .in_2_6(mul_in_2_6),
    .in_2_7(mul_in_2_7),
    .in_2_8(mul_in_2_8),
    .in_2_9(mul_in_2_9),
    .in_2_10(mul_in_2_10),
    .in_2_11(mul_in_2_11),
    .in_2_12(mul_in_2_12),
    .in_2_13(mul_in_2_13),
    .in_2_14(mul_in_2_14),
    .in_2_15(mul_in_2_15),
    .in_2_16(mul_in_2_16),
    .in_2_17(mul_in_2_17),
    .in_2_18(mul_in_2_18),
    .in_2_19(mul_in_2_19),
    .in_2_20(mul_in_2_20),
    .in_2_21(mul_in_2_21),
    .in_2_22(mul_in_2_22),
    .in_2_23(mul_in_2_23),
    .in_2_24(mul_in_2_24),
    .in_2_25(mul_in_2_25),
    .in_2_26(mul_in_2_26),
    .in_2_27(mul_in_2_27),
    .in_2_28(mul_in_2_28),
    .in_2_29(mul_in_2_29),
    .in_2_30(mul_in_2_30),
    .in_2_31(mul_in_2_31),
    .in_2_32(mul_in_2_32),
    .in_2_33(mul_in_2_33),
    .in_2_34(mul_in_2_34),
    .in_2_35(mul_in_2_35),
    .in_2_36(mul_in_2_36),
    .in_2_37(mul_in_2_37),
    .in_2_38(mul_in_2_38),
    .in_2_39(mul_in_2_39),
    .in_2_40(mul_in_2_40),
    .in_2_41(mul_in_2_41),
    .in_2_42(mul_in_2_42),
    .in_2_43(mul_in_2_43),
    .in_2_44(mul_in_2_44),
    .in_2_45(mul_in_2_45),
    .in_2_46(mul_in_2_46),
    .in_2_47(mul_in_2_47),

    .out_0(mul_out_0),
    .out_1(mul_out_1),
    .out_2(mul_out_2),
    .out_3(mul_out_3),
    .out_4(mul_out_4),
    .out_5(mul_out_5),
    .out_6(mul_out_6),
    .out_7(mul_out_7),
    .out_8(mul_out_8),
    .out_9(mul_out_9),
    .out_10(mul_out_10),
    .out_11(mul_out_11),
    .out_12(mul_out_12),
    .out_13(mul_out_13),
    .out_14(mul_out_14),
    .out_15(mul_out_15),
    .out_16(mul_out_16),
    .out_17(mul_out_17),
    .out_18(mul_out_18),
    .out_19(mul_out_19),
    .out_20(mul_out_20),
    .out_21(mul_out_21),
    .out_22(mul_out_22),
    .out_23(mul_out_23),
    .out_24(mul_out_24),
    .out_25(mul_out_25),
    .out_26(mul_out_26),
    .out_27(mul_out_27),
    .out_28(mul_out_28),
    .out_29(mul_out_29),
    .out_30(mul_out_30),
    .out_31(mul_out_31),
    .out_32(mul_out_32),
    .out_33(mul_out_33),
    .out_34(mul_out_34),
    .out_35(mul_out_35),
    .out_36(mul_out_36),
    .out_37(mul_out_37),
    .out_38(mul_out_38),
    .out_39(mul_out_39),
    .out_40(mul_out_40),
    .out_41(mul_out_41),
    .out_42(mul_out_42),
    .out_43(mul_out_43),
    .out_44(mul_out_44),
    .out_45(mul_out_45),
    .out_46(mul_out_46),
    .out_47(mul_out_47)
);



//-------------Sequential--------------//
always @(posedge clk) begin
    sram_rdata_r0_r <= sram_rdata_r0;
    sram_rdata_r1_r <= sram_rdata_r1;
    sram_rdata_r2_r <= sram_rdata_r2;
    sram_rdata_r3_r <= sram_rdata_r3;
    sram_rdata_gb0_r <= sram_rdata_gb0;
    sram_rdata_gb1_r <= sram_rdata_gb1;
    sram_rdata_gb2_r <= sram_rdata_gb2;
    sram_rdata_gb3_r <= sram_rdata_gb3;

    sram_rdata_fy0_r <= sram_rdata_fy0;
    sram_rdata_fy1_r <= sram_rdata_fy1;
    sram_rdata_fy2_r <= sram_rdata_fy2;
    sram_rdata_fy3_r <= sram_rdata_fy3;
    sram_rdata_fc0_r <= sram_rdata_fc0;
    sram_rdata_fc1_r <= sram_rdata_fc1;
    sram_rdata_fc2_r <= sram_rdata_fc2;
    sram_rdata_fc3_r <= sram_rdata_fc3;

    sram_raddr_r0 <= sram_raddr_r0_n;
    sram_raddr_r1 <= sram_raddr_r1_n;
    sram_raddr_r2 <= sram_raddr_r2_n;
    sram_raddr_r3 <= sram_raddr_r3_n;
    sram_raddr_gb0 <= sram_raddr_gb0_n;
    sram_raddr_gb1 <= sram_raddr_gb1_n;
    sram_raddr_gb2 <= sram_raddr_gb2_n;
    sram_raddr_gb3 <= sram_raddr_gb3_n;

    sram_raddr_fy0 <= sram_raddr_fy0_n;
    sram_raddr_fy1 <= sram_raddr_fy1_n;
    sram_raddr_fy2 <= sram_raddr_fy2_n;
    sram_raddr_fy3 <= sram_raddr_fy3_n;
    sram_raddr_fc0 <= sram_raddr_fc0_n;
    sram_raddr_fc1 <= sram_raddr_fc1_n;
    sram_raddr_fc2 <= sram_raddr_fc2_n;
    sram_raddr_fc3 <= sram_raddr_fc3_n;

    sram_waddr_r0 <= sram_waddr_r0_n;
    sram_waddr_r1 <= sram_waddr_r1_n;
    sram_waddr_r2 <= sram_waddr_r2_n;
    sram_waddr_r3 <= sram_waddr_r3_n;
    sram_waddr_gb0 <= sram_waddr_gb0_n;
    sram_waddr_gb1 <= sram_waddr_gb1_n;
    sram_waddr_gb2 <= sram_waddr_gb2_n;
    sram_waddr_gb3 <= sram_waddr_gb3_n;

    sram_waddr_fy0 <= sram_waddr_fy0_n;
    sram_waddr_fy1 <= sram_waddr_fy1_n;
    sram_waddr_fy2 <= sram_waddr_fy2_n;
    sram_waddr_fy3 <= sram_waddr_fy3_n;
    sram_waddr_fc0 <= sram_waddr_fc0_n;
    sram_waddr_fc1 <= sram_waddr_fc1_n;
    sram_waddr_fc2 <= sram_waddr_fc2_n;
    sram_waddr_fc3 <= sram_waddr_fc3_n;

    sram_wordmask_r0 <= sram_wordmask_r0_n;
    sram_wordmask_r1 <= sram_wordmask_r1_n;
    sram_wordmask_r2 <= sram_wordmask_r2_n;
    sram_wordmask_r3 <= sram_wordmask_r3_n;
    sram_wordmask_gb0 <= sram_wordmask_gb0_n;
    sram_wordmask_gb1 <= sram_wordmask_gb1_n;
    sram_wordmask_gb2 <= sram_wordmask_gb2_n;
    sram_wordmask_gb3 <= sram_wordmask_gb3_n;

    sram_wordmask_fy0 <= sram_wordmask_fy0_n;
    sram_wordmask_fy1 <= sram_wordmask_fy1_n;
    sram_wordmask_fy2 <= sram_wordmask_fy2_n;
    sram_wordmask_fy3 <= sram_wordmask_fy3_n;
    sram_wordmask_fc0 <= sram_wordmask_fc0_n;
    sram_wordmask_fc1 <= sram_wordmask_fc1_n;
    sram_wordmask_fc2 <= sram_wordmask_fc2_n;
    sram_wordmask_fc3 <= sram_wordmask_fc3_n;

    sram_wdata_r0 <= sram_wdata_r0_n;
    sram_wdata_r1 <= sram_wdata_r1_n;
    sram_wdata_r2 <= sram_wdata_r2_n;
    sram_wdata_r3 <= sram_wdata_r3_n;
    sram_wdata_gb0 <= sram_wdata_gb0_n;
    sram_wdata_gb1 <= sram_wdata_gb1_n;
    sram_wdata_gb2 <= sram_wdata_gb2_n;
    sram_wdata_gb3 <= sram_wdata_gb3_n;

    sram_wdata_fy0 <= sram_wdata_fy0_n;
    sram_wdata_fy1 <= sram_wdata_fy1_n;
    sram_wdata_fy2 <= sram_wdata_fy2_n;
    sram_wdata_fy3 <= sram_wdata_fy3_n;
    sram_wdata_fc0 <= sram_wdata_fc0_n;
    sram_wdata_fc1 <= sram_wdata_fc1_n;
    sram_wdata_fc2 <= sram_wdata_fc2_n;
    sram_wdata_fc3 <= sram_wdata_fc3_n;
end

always @(posedge clk) begin
    if (!srst_n) begin
        sram_wen_r0 <= 1'b1;
        sram_wen_r1 <= 1'b1;
        sram_wen_r2 <= 1'b1;
        sram_wen_r3 <= 1'b1;
        sram_wen_gb0 <= 1'b1;
        sram_wen_gb1 <= 1'b1;
        sram_wen_gb2 <= 1'b1;
        sram_wen_gb3 <= 1'b1;

        sram_wen_fy0 <= 1'b1;
        sram_wen_fy1 <= 1'b1;
        sram_wen_fy2 <= 1'b1;
        sram_wen_fy3 <= 1'b1;
        sram_wen_fc0 <= 1'b1;
        sram_wen_fc1 <= 1'b1;
        sram_wen_fc2 <= 1'b1;
        sram_wen_fc3 <= 1'b1;
    end else begin
        sram_wen_r0 <= sram_wen_r0_n;
        sram_wen_r1 <= sram_wen_r1_n;
        sram_wen_r2 <= sram_wen_r2_n;
        sram_wen_r3 <= sram_wen_r3_n;
        sram_wen_gb0 <= sram_wen_gb0_n;
        sram_wen_gb1 <= sram_wen_gb1_n;
        sram_wen_gb2 <= sram_wen_gb2_n;
        sram_wen_gb3 <= sram_wen_gb3_n;

        sram_wen_fy0 <= sram_wen_fy0_n;
        sram_wen_fy1 <= sram_wen_fy1_n;
        sram_wen_fy2 <= sram_wen_fy2_n;
        sram_wen_fy3 <= sram_wen_fy3_n;
        sram_wen_fc0 <= sram_wen_fc0_n;
        sram_wen_fc1 <= sram_wen_fc1_n;
        sram_wen_fc2 <= sram_wen_fc2_n;
        sram_wen_fc3 <= sram_wen_fc3_n;
    end
end

// global mu && sqr_sigma

always @* begin
    mu_Cb_src_nx = (state_cbcr_src) ? mu_Cb_cs : mu_Cb_src;
    mu_Cr_src_nx = (state_cbcr_src) ? mu_Cr_cs : mu_Cr_src;
    sqr_sigma_Cb_src_nx = (state_cbcr_src) ? sqr_sigma_Cb_cs : sqr_sigma_Cb_src;
    sqr_sigma_Cr_src_nx = (state_cbcr_src) ? sqr_sigma_Cr_cs : sqr_sigma_Cr_src;

    mu_Cb_ref_nx = (state_cbcr_ref) ? mu_Cb_cs : mu_Cb_ref;
    mu_Cr_ref_nx = (state_cbcr_ref) ? mu_Cr_cs : mu_Cr_ref;
    sqr_sigma_Cb_ref_nx = (state_cbcr_ref) ? sqr_sigma_Cb_cs : sqr_sigma_Cb_ref;
    sqr_sigma_Cr_ref_nx = (state_cbcr_ref) ? sqr_sigma_Cr_cs : sqr_sigma_Cr_ref;
end

always @(posedge clk) begin
    mu_Cb_src <= mu_Cb_src_nx;
    mu_Cr_src <= mu_Cr_src_nx;
    sqr_sigma_Cb_src <= sqr_sigma_Cb_src_nx;
    sqr_sigma_Cr_src <= sqr_sigma_Cr_src_nx;

    mu_Cb_ref <= mu_Cb_ref_nx;
    mu_Cr_ref <= mu_Cr_ref_nx;
    sqr_sigma_Cb_ref <= sqr_sigma_Cb_ref_nx;
    sqr_sigma_Cr_ref <= sqr_sigma_Cr_ref_nx;
end

// FSM
// src
localparam  IDLE_1HOT    = 9'b0_0000_0001,
            WB_1HOT      = 9'b0_0000_0010,
            DEMOS_1HOT   = 9'b0_0000_0100,
            GAMMA_1HOT   = 9'b0_0000_1000,
            YCBCR_1HOT   = 9'b0_0001_0000,
            LM_1HOT      = 9'b0_0010_0000,
            WAIT_CM_1HOT = 9'b0_0100_0000,
            RGB_1HOT     = 9'b0_1000_0000,
            FINISH_1HOT  = 9'b1_0000_0000;
//ref
localparam  IDLE_REF_1HOT  = 3'b001,
            YCBCR_REF_1HOT = 3'b010,
            CHROMA_STATS_REF_1HOT = 3'b100;

assign state_cbcr_src = ((state[LM] || state[WAIT_CM]) && ~cbcr_mode);
assign state_cbcr_ref = state_ref[CHROMA_STATS_REF];
assign state_cbcr_match = ((state[LM] || state[WAIT_CM]) && cbcr_mode);

always @(posedge clk) begin
    if (!srst_n) begin
        state <= IDLE_1HOT;
        state_ref <= IDLE_REF_1HOT;
        cbcr_mode <= 1'b0;
    end else begin
        state <= state_nx;
        state_ref <= state_ref_n;
        cbcr_mode <= ((state[LM] || state[WAIT_CM]) && cs_done) ? 1'b1 : cbcr_mode;
    end
end

// src
always @* begin
    state_nx = state;
    case (1) // synopsys parallel_case
        state[IDLE]: begin
            if (enable) begin
                state_nx = WB_1HOT;
                // state_nx = RGB_1HOT;
            end else begin
                state_nx = IDLE_1HOT;
            end
        end
        state[WB]: begin
            if (wb_done) begin
                state_nx = DEMOS_1HOT;
            end else begin
                state_nx = WB_1HOT;
            end
        end
        state[DEMOS]: begin
            if (demos_done) begin
                state_nx = GAMMA_1HOT;
            end else begin
                state_nx = DEMOS_1HOT;
            end
        end 
        state[GAMMA]: begin
            if (gamma_done) begin
                state_nx = YCBCR_1HOT;
                // state_nx = FINISH_1HOT;
            end else begin
                state_nx = GAMMA_1HOT;
            end
        end
        state[YCBCR]: begin
            if (ycbcr_done) begin
                state_nx = LM_1HOT;
                // state_nx = FINISH_1HOT;
            end else begin
                state_nx = YCBCR_1HOT;
            end
        end
        state[LM]: begin
            if (lm_done) begin
                state_nx = WAIT_CM_1HOT;
                // state_nx = FINISH_1HOT;
            end else begin
                state_nx = LM_1HOT;
            end
        end
        state[WAIT_CM]: begin
            if (cm_done) begin
                state_nx = RGB_1HOT;
            end else begin
                state_nx = WAIT_CM_1HOT;
            end
        end
        state[RGB]: begin
            if (rgb_done) begin
                state_nx = FINISH_1HOT;
            end else begin
                state_nx = RGB_1HOT;
            end
        end        
        state[FINISH]: begin
            state_nx = IDLE_1HOT;
        end
    endcase
end

// ref
always @* begin
    state_ref_n = state_ref;
    case (1) // synopsys parallel_case
        state_ref[IDLE_REF]: begin
            if (enable) begin
                state_ref_n = YCBCR_REF_1HOT;
            end else begin
                state_ref_n = IDLE_REF_1HOT;
            end
        end
        state_ref[YCBCR_REF]: begin
            if (ycbcr_done) begin
                state_ref_n = CHROMA_STATS_REF_1HOT;
            end else begin
                state_ref_n = YCBCR_REF_1HOT;
            end
        end
        state_ref[CHROMA_STATS_REF]: begin
            if (cs_done) begin
                state_ref_n = IDLE_REF_1HOT;
            end else begin
                state_ref_n = CHROMA_STATS_REF_1HOT;
            end
        end
    endcase
end

assign valid = (state[FINISH]);



//---------------------------------//


endmodule