`timescale 1ns/100ps

`define PAT_L 0
`define PAT_U 1
`define NUM_PAT (`PAT_U-`PAT_L+1)
`define MAX_PAT 30
`define PAT_NAME_LENGTH 2

`define CYCLE 20
`define END_CYCLES 2000000
`define FLAG_VERBOSE 1  
`define FLAG_DUMPWV 1
`define TEST_ALL 1
`define REF 0
`define COMPARE 0

module test_top;

localparam CH_NUM = 4;
localparam LINEAR_BW = 16;
localparam RGB_BW = 8;
localparam CBCR_BW = 16;

localparam WIDTH = 1920;
localparam HEIGHT = 1080;

localparam WB = 5'd0, DEMOSAIC = 5'd1, GAMMA = 5'd2, YCBCR_REF = 5'd3, YCBCR_SRC = 5'd4, LIGHT_MATCH = 5'd5;
localparam COLOR_MATCH = 5'd6, FINAL = 5'd7;

localparam R0 = 4'd0, R1 = 4'd1, R2 = 4'd2, R3 = 4'd3, GB0 = 4'd4, GB1 = 4'd5, GB2 = 4'd6, GB3 = 4'd7;
localparam FY0 = 4'd8, FY1 = 4'd9, FY2 = 4'd10, FY3 = 4'd11, FC0 = 4'd12, FC1 = 4'd13, FC2 = 4'd14, FC3 = 4'd15;
integer test_layer;

reg [8*26-1:0] layer_str;

initial begin
    layer_str = 0;
    `ifdef WB
        test_layer = WB;
        layer_str = "       White Balance      ";
    `elsif DEMOSAIC
        test_layer = DEMOSAIC;
        layer_str = "  demosaic_rggb_bilinear  ";
    `elsif GAMMA
        test_layer = GAMMA;
        layer_str = "        apply_gamma       ";
    `elsif YCBCR_REF
        test_layer = YCBCR_REF;
        layer_str = "reference_YCbCr_transform ";
    `elsif YCBCR_SRC
        test_layer = YCBCR_SRC;
        layer_str = "  source_YCbCr_transform  ";
    `elsif LIGHT_MATCH
        test_layer = LIGHT_MATCH;
        layer_str = "  y-channel_light_match   ";
    `elsif COLOR_MATCH
        test_layer = COLOR_MATCH;
        layer_str = " CbCr-channel_color_match ";
    `elsif FINAL
        test_layer = FINAL;
        layer_str = "  YCbCr_to_RGB_transform  ";
    `endif
end

integer i;

// ===== pattern files ===== // 
reg [23*8-1:0] pattern_r0_file, pattern_r1_file, pattern_r2_file, pattern_r3_file;
reg [24*8-1:0] pattern_gb0_file, pattern_gb1_file, pattern_gb2_file, pattern_gb3_file;
reg [26*8-1:0] wb_r0_golden_file, wb_r1_golden_file, wb_r2_golden_file, wb_r3_golden_file;
reg [27*8-1:0] wb_gb0_golden_file, wb_gb1_golden_file, wb_gb2_golden_file, wb_gb3_golden_file;
reg [38*8-1:0] demosaic_r0_golden_file, demosaic_r1_golden_file, demosaic_r2_golden_file, demosaic_r3_golden_file;
reg [39*8-1:0] demosaic_gb0_golden_file, demosaic_gb1_golden_file, demosaic_gb2_golden_file, demosaic_gb3_golden_file;
reg [32*8-1:0] gamma_r0_golden_file, gamma_r1_golden_file, gamma_r2_golden_file, gamma_r3_golden_file;
reg [33*8-1:0] gamma_gb0_golden_file, gamma_gb1_golden_file, gamma_gb2_golden_file, gamma_gb3_golden_file;
reg [23*8-1:0] ref_pat_r0_file, ref_pat_r1_file, ref_pat_r2_file, ref_pat_r3_file;
reg [24*8-1:0] ref_pat_gb0_file, ref_pat_gb1_file, ref_pat_gb2_file, ref_pat_gb3_file;
reg [39*8-1:0] src_fy0_golden_file, src_fy1_golden_file, src_fy2_golden_file, src_fy3_golden_file;
reg [45*8-1:0] src_fc0_golden_file, src_fc1_golden_file, src_fc2_golden_file, src_fc3_golden_file;
reg [39*8-1:0] ref_fy0_golden_file, ref_fy1_golden_file, ref_fy2_golden_file, ref_fy3_golden_file;
reg [45*8-1:0] ref_fc0_golden_file, ref_fc1_golden_file, ref_fc2_golden_file, ref_fc3_golden_file;
reg [41*8-1:0] light_fy0_golden_file, light_fy1_golden_file, light_fy2_golden_file, light_fy3_golden_file;
reg [41*8-1:0] color_fc0_golden_file, color_fc1_golden_file, color_fc2_golden_file, color_fc3_golden_file;
reg [31*8-1:0] final_fy0_golden_file, final_fy1_golden_file, final_fy2_golden_file, final_fy3_golden_file;
reg [31*8-1:0] final_fc0_golden_file, final_fc1_golden_file, final_fc2_golden_file, final_fc3_golden_file;

// ===== module I/O ===== //
reg clk;
reg srst_n;
reg enable;
wire valid;

wire sram_wen_r0, sram_wen_r1, sram_wen_r2, sram_wen_r3;
wire sram_wen_gb0, sram_wen_gb1, sram_wen_gb2, sram_wen_gb3;
wire sram_wen_fy0, sram_wen_fy1, sram_wen_fy2, sram_wen_fy3;
wire sram_wen_fc0, sram_wen_fc1, sram_wen_fc2, sram_wen_fc3;

wire [CH_NUM*LINEAR_BW-1:0] sram_rdata_r0, sram_rdata_r1, sram_rdata_r2, sram_rdata_r3;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_rdata_gb0, sram_rdata_gb1, sram_rdata_gb2, sram_rdata_gb3;
wire [CH_NUM*RGB_BW-1:0] sram_rdata_fy0, sram_rdata_fy1, sram_rdata_fy2, sram_rdata_fy3;
wire [CH_NUM*CBCR_BW*2-1:0] sram_rdata_fc0, sram_rdata_fc1, sram_rdata_fc2, sram_rdata_fc3;

wire [17-1:0] sram_raddr_r0, sram_raddr_r1, sram_raddr_r2, sram_raddr_r3;  
wire [17-1:0] sram_raddr_gb0, sram_raddr_gb1, sram_raddr_gb2, sram_raddr_gb3;
wire [17-1:0] sram_raddr_fy0, sram_raddr_fy1, sram_raddr_fy2, sram_raddr_fy3;
wire [17-1:0] sram_raddr_fc0, sram_raddr_fc1, sram_raddr_fc2, sram_raddr_fc3;

wire [17-1:0] sram_waddr_r0, sram_waddr_r1, sram_waddr_r2, sram_waddr_r3;  
wire [17-1:0] sram_waddr_gb0, sram_waddr_gb1, sram_waddr_gb2, sram_waddr_gb3;
wire [17-1:0] sram_waddr_fy0, sram_waddr_fy1, sram_waddr_fy2, sram_waddr_fy3;
wire [17-1:0] sram_waddr_fc0, sram_waddr_fc1, sram_waddr_fc2, sram_waddr_fc3;

wire [CH_NUM-1:0] sram_wordmask_r0, sram_wordmask_r1, sram_wordmask_r2, sram_wordmask_r3;
wire [CH_NUM*2-1:0] sram_wordmask_gb0, sram_wordmask_gb1, sram_wordmask_gb2, sram_wordmask_gb3;
wire [CH_NUM-1:0] sram_wordmask_fy0, sram_wordmask_fy1, sram_wordmask_fy2, sram_wordmask_fy3;
wire [CH_NUM*2-1:0] sram_wordmask_fc0, sram_wordmask_fc1, sram_wordmask_fc2, sram_wordmask_fc3;

wire [CH_NUM*LINEAR_BW-1:0] sram_wdata_r0, sram_wdata_r1, sram_wdata_r2, sram_wdata_r3;
wire [CH_NUM*LINEAR_BW*2-1:0] sram_wdata_gb0, sram_wdata_gb1, sram_wdata_gb2, sram_wdata_gb3;
wire [CH_NUM*RGB_BW-1:0] sram_wdata_fy0, sram_wdata_fy1, sram_wdata_fy2, sram_wdata_fy3;
wire [CH_NUM*CBCR_BW*2-1:0] sram_wdata_fc0, sram_wdata_fc1, sram_wdata_fc2, sram_wdata_fc3;


top #(
    .CH_NUM(CH_NUM),
    .LINEAR_BW(LINEAR_BW),
    .RGB_BW(RGB_BW),
    .CBCR_BW(CBCR_BW)
) uut (
    .clk(clk),
    .srst_n(srst_n),
    .enable(enable),
    .valid(valid),

    .sram_rdata_r0(sram_rdata_r0),
    .sram_rdata_r1(sram_rdata_r1),
    .sram_rdata_r2(sram_rdata_r2),
    .sram_rdata_r3(sram_rdata_r3),
    .sram_rdata_gb0(sram_rdata_gb0),
    .sram_rdata_gb1(sram_rdata_gb1),
    .sram_rdata_gb2(sram_rdata_gb2),
    .sram_rdata_gb3(sram_rdata_gb3),
    .sram_rdata_fy0(sram_rdata_fy0),
    .sram_rdata_fy1(sram_rdata_fy1),
    .sram_rdata_fy2(sram_rdata_fy2),
    .sram_rdata_fy3(sram_rdata_fy3),
    .sram_rdata_fc0(sram_rdata_fc0),
    .sram_rdata_fc1(sram_rdata_fc1),
    .sram_rdata_fc2(sram_rdata_fc2),
    .sram_rdata_fc3(sram_rdata_fc3),

    .sram_raddr_r0(sram_raddr_r0),
    .sram_raddr_r1(sram_raddr_r1),
    .sram_raddr_r2(sram_raddr_r2),
    .sram_raddr_r3(sram_raddr_r3),
    .sram_raddr_gb0(sram_raddr_gb0),
    .sram_raddr_gb1(sram_raddr_gb1),
    .sram_raddr_gb2(sram_raddr_gb2),
    .sram_raddr_gb3(sram_raddr_gb3),
    .sram_raddr_fy0(sram_raddr_fy0),
    .sram_raddr_fy1(sram_raddr_fy1),
    .sram_raddr_fy2(sram_raddr_fy2),
    .sram_raddr_fy3(sram_raddr_fy3),
    .sram_raddr_fc0(sram_raddr_fc0),
    .sram_raddr_fc1(sram_raddr_fc1),
    .sram_raddr_fc2(sram_raddr_fc2),
    .sram_raddr_fc3(sram_raddr_fc3),

    .sram_waddr_r0(sram_waddr_r0),
    .sram_waddr_r1(sram_waddr_r1),
    .sram_waddr_r2(sram_waddr_r2),
    .sram_waddr_r3(sram_waddr_r3),
    .sram_waddr_gb0(sram_waddr_gb0),
    .sram_waddr_gb1(sram_waddr_gb1),
    .sram_waddr_gb2(sram_waddr_gb2),
    .sram_waddr_gb3(sram_waddr_gb3),
    .sram_waddr_fy0(sram_waddr_fy0),
    .sram_waddr_fy1(sram_waddr_fy1),
    .sram_waddr_fy2(sram_waddr_fy2),
    .sram_waddr_fy3(sram_waddr_fy3),
    .sram_waddr_fc0(sram_waddr_fc0),
    .sram_waddr_fc1(sram_waddr_fc1),
    .sram_waddr_fc2(sram_waddr_fc2),
    .sram_waddr_fc3(sram_waddr_fc3),

    .sram_wen_r0(sram_wen_r0),
    .sram_wen_r1(sram_wen_r1),
    .sram_wen_r2(sram_wen_r2),
    .sram_wen_r3(sram_wen_r3),
    .sram_wen_gb0(sram_wen_gb0),
    .sram_wen_gb1(sram_wen_gb1),
    .sram_wen_gb2(sram_wen_gb2),
    .sram_wen_gb3(sram_wen_gb3),
    .sram_wen_fy0(sram_wen_fy0),
    .sram_wen_fy1(sram_wen_fy1),
    .sram_wen_fy2(sram_wen_fy2),
    .sram_wen_fy3(sram_wen_fy3),
    .sram_wen_fc0(sram_wen_fc0),
    .sram_wen_fc1(sram_wen_fc1),
    .sram_wen_fc2(sram_wen_fc2),
    .sram_wen_fc3(sram_wen_fc3),

    .sram_wordmask_r0(sram_wordmask_r0),
    .sram_wordmask_r1(sram_wordmask_r1),
    .sram_wordmask_r2(sram_wordmask_r2),
    .sram_wordmask_r3(sram_wordmask_r3),
    .sram_wordmask_gb0(sram_wordmask_gb0),
    .sram_wordmask_gb1(sram_wordmask_gb1),
    .sram_wordmask_gb2(sram_wordmask_gb2),
    .sram_wordmask_gb3(sram_wordmask_gb3),
    .sram_wordmask_fy0(sram_wordmask_fy0),
    .sram_wordmask_fy1(sram_wordmask_fy1),
    .sram_wordmask_fy2(sram_wordmask_fy2),
    .sram_wordmask_fy3(sram_wordmask_fy3),
    .sram_wordmask_fc0(sram_wordmask_fc0),
    .sram_wordmask_fc1(sram_wordmask_fc1),
    .sram_wordmask_fc2(sram_wordmask_fc2),
    .sram_wordmask_fc3(sram_wordmask_fc3),

    .sram_wdata_r0(sram_wdata_r0),
    .sram_wdata_r1(sram_wdata_r1),
    .sram_wdata_r2(sram_wdata_r2),
    .sram_wdata_r3(sram_wdata_r3),
    .sram_wdata_gb0(sram_wdata_gb0),
    .sram_wdata_gb1(sram_wdata_gb1),
    .sram_wdata_gb2(sram_wdata_gb2),
    .sram_wdata_gb3(sram_wdata_gb3),
    .sram_wdata_fy0(sram_wdata_fy0),
    .sram_wdata_fy1(sram_wdata_fy1),
    .sram_wdata_fy2(sram_wdata_fy2),
    .sram_wdata_fy3(sram_wdata_fy3),
    .sram_wdata_fc0(sram_wdata_fc0),
    .sram_wdata_fc1(sram_wdata_fc1),
    .sram_wdata_fc2(sram_wdata_fc2),
    .sram_wdata_fc3(sram_wdata_fc3)
);

// ===== sram connection ===== //

// SRAM R
sram_r sram_r0(.clk(clk), .wordmask(sram_wordmask_r0), .csb(1'b0), .wsb(sram_wen_r0), .wdata(sram_wdata_r0),  .waddr(sram_waddr_r0),  .raddr(sram_raddr_r0),  .rdata(sram_rdata_r0));
sram_r sram_r1(.clk(clk), .wordmask(sram_wordmask_r1), .csb(1'b0), .wsb(sram_wen_r1), .wdata(sram_wdata_r1),  .waddr(sram_waddr_r1),  .raddr(sram_raddr_r1),  .rdata(sram_rdata_r1));
sram_r sram_r2(.clk(clk), .wordmask(sram_wordmask_r2), .csb(1'b0), .wsb(sram_wen_r2), .wdata(sram_wdata_r2),  .waddr(sram_waddr_r2),  .raddr(sram_raddr_r2),  .rdata(sram_rdata_r2));
sram_r sram_r3(.clk(clk), .wordmask(sram_wordmask_r3), .csb(1'b0), .wsb(sram_wen_r3), .wdata(sram_wdata_r3),  .waddr(sram_waddr_r3),  .raddr(sram_raddr_r3),  .rdata(sram_rdata_r3));

// SRAM GB
sram_gb sram_gb0(.clk(clk), .wordmask(sram_wordmask_gb0), .csb(1'b0), .wsb(sram_wen_gb0), .wdata(sram_wdata_gb0),  .waddr(sram_waddr_gb0),  .raddr(sram_raddr_gb0),  .rdata(sram_rdata_gb0));
sram_gb sram_gb1(.clk(clk), .wordmask(sram_wordmask_gb1), .csb(1'b0), .wsb(sram_wen_gb1), .wdata(sram_wdata_gb1),  .waddr(sram_waddr_gb1),  .raddr(sram_raddr_gb1),  .rdata(sram_rdata_gb1));
sram_gb sram_gb2(.clk(clk), .wordmask(sram_wordmask_gb2), .csb(1'b0), .wsb(sram_wen_gb2), .wdata(sram_wdata_gb2),  .waddr(sram_waddr_gb2),  .raddr(sram_raddr_gb2),  .rdata(sram_rdata_gb2));
sram_gb sram_gb3(.clk(clk), .wordmask(sram_wordmask_gb3), .csb(1'b0), .wsb(sram_wen_gb3), .wdata(sram_wdata_gb3),  .waddr(sram_waddr_gb3),  .raddr(sram_raddr_gb3),  .rdata(sram_rdata_gb3));

// SRAM reference Y-channel
sram_fy sram_fy0(.clk(clk), .wordmask(sram_wordmask_fy0), .csb(1'b0), .wsb(sram_wen_fy0), .wdata(sram_wdata_fy0),  .waddr(sram_waddr_fy0),  .raddr(sram_raddr_fy0),  .rdata(sram_rdata_fy0));
sram_fy sram_fy1(.clk(clk), .wordmask(sram_wordmask_fy1), .csb(1'b0), .wsb(sram_wen_fy1), .wdata(sram_wdata_fy1),  .waddr(sram_waddr_fy1),  .raddr(sram_raddr_fy1),  .rdata(sram_rdata_fy1));
sram_fy sram_fy2(.clk(clk), .wordmask(sram_wordmask_fy2), .csb(1'b0), .wsb(sram_wen_fy2), .wdata(sram_wdata_fy2),  .waddr(sram_waddr_fy2),  .raddr(sram_raddr_fy2),  .rdata(sram_rdata_fy2));
sram_fy sram_fy3(.clk(clk), .wordmask(sram_wordmask_fy3), .csb(1'b0), .wsb(sram_wen_fy3), .wdata(sram_wdata_fy3),  .waddr(sram_waddr_fy3),  .raddr(sram_raddr_fy3),  .rdata(sram_rdata_fy3));

// SRAM reference CbCr-channel
sram_fc sram_fc0(.clk(clk), .wordmask(sram_wordmask_fc0), .csb(1'b0), .wsb(sram_wen_fc0), .wdata(sram_wdata_fc0),  .waddr(sram_waddr_fc0),  .raddr(sram_raddr_fc0),  .rdata(sram_rdata_fc0));
sram_fc sram_fc1(.clk(clk), .wordmask(sram_wordmask_fc1), .csb(1'b0), .wsb(sram_wen_fc1), .wdata(sram_wdata_fc1),  .waddr(sram_waddr_fc1),  .raddr(sram_raddr_fc1),  .rdata(sram_rdata_fc1));
sram_fc sram_fc2(.clk(clk), .wordmask(sram_wordmask_fc2), .csb(1'b0), .wsb(sram_wen_fc2), .wdata(sram_wdata_fc2),  .waddr(sram_waddr_fc2),  .raddr(sram_raddr_fc2),  .rdata(sram_rdata_fc2));
sram_fc sram_fc3(.clk(clk), .wordmask(sram_wordmask_fc3), .csb(1'b0), .wsb(sram_wen_fc3), .wdata(sram_wdata_fc3),  .waddr(sram_waddr_fc3),  .raddr(sram_raddr_fc3),  .rdata(sram_rdata_fc3));

reg [15*8-1:0] fsdb_file;

initial begin
    `ifdef GATESIM 
        if(`FLAG_DUMPWV) begin
            $fsdbDumpfile("gatesim.fsdb");
            $fsdbDumpvars;
        end
        $sdf_annotate("../syn/netlist/top_syn.sdf",uut);
    `elsif POSTSIM
        if (`FLAG_DUMPWV) begin
            $fsdbDumpfile("postsim.fsdb");
            $fsdbDumpvars;
        end
        $sdf_annotate("../innovus/post_layout/CHIP.sdf",uut);
    `else
        // $sformat(fsdb_file, "waveform_%0d.fsdb", test_layer);
        if (`FLAG_DUMPWV) begin
            $fsdbDumpfile("presim.fsdb");
            $fsdbDumpvars("+mda");
        end
    `endif 
end

// ===== parameter & golden answers ===== //
reg [CH_NUM*LINEAR_BW-1:0] input_sram_value_r0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] input_sram_value_r1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] input_sram_value_r2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] input_sram_value_r3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] input_sram_value_gb0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] input_sram_value_gb1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] input_sram_value_gb2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] input_sram_value_gb3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] input_sram_value_fy0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] input_sram_value_fy1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] input_sram_value_fy2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] input_sram_value_fy3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] input_sram_value_fc0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] input_sram_value_fc1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] input_sram_value_fc2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] input_sram_value_fc3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] golden_sram_value_r0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] golden_sram_value_r1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] golden_sram_value_r2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW-1:0] golden_sram_value_r3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] golden_sram_value_gb0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] golden_sram_value_gb1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] golden_sram_value_gb2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*LINEAR_BW*2-1:0] golden_sram_value_gb3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] golden_sram_value_fy0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] golden_sram_value_fy1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] golden_sram_value_fy2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*RGB_BW-1:0] golden_sram_value_fy3 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] golden_sram_value_fc0 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] golden_sram_value_fc1 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] golden_sram_value_fc2 [0:WIDTH*HEIGHT/16-1];
reg [CH_NUM*CBCR_BW*2-1:0] golden_sram_value_fc3 [0:WIDTH*HEIGHT/16-1];


// ===== system reset ===== //
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
  #(`CYCLE * `END_CYCLES);
    $display("\n========================================================");
    $display("   Error!!! Simulation time is too long...            ");
    $display("========================================================");
    $finish;
end

// ===== cycle counter ===== //
integer cycle_cnt;
integer aver_cycle_cnt;
initial begin
    cycle_cnt = 0;
    aver_cycle_cnt = 0;
    while(1) begin 
        cycle_cnt = cycle_cnt + 1;
        @(negedge clk);
    end
end

// ===== output comparision ===== //
integer m, l;
integer error_r0, error_r1, error_r2, error_r3;
integer error_gb0, error_gb1, error_gb2, error_gb3;
integer error_fy0, error_fy1, error_fy2, error_fy3;
integer error_fc0, error_fc1, error_fc2, error_fc3;
integer error_total;
integer error_tmp;
integer pat_idx;
integer total_err_pat;

initial begin
    // check if PAT_L and PAT_U are both valid
    if((`PAT_L < 0) || (`PAT_L > `MAX_PAT-1) || (`PAT_U < 0) || (`PAT_U > `MAX_PAT-1)) begin
        $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $display("X                                                                             X");
        $display("X   Error!!! PAT_L and PAT_U should be within the range [0, %3d]              X", `MAX_PAT-1);
        $display("X                                                                             X");
        $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $finish;
    end
    else if(`PAT_L > `PAT_U) begin
        $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $display("X                                                        X");
        $display("X   Error!!! PAT_L should be smaller or equal to PAT_U   X");
        $display("X                                                        X");
        $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $finish;    
    end

    $display("\n%c[1;36mStart checking %s layer ... %c[0m\n", 27, layer_str, 27);
    
    total_err_pat = 0;
    for(pat_idx=`PAT_L; pat_idx<=`PAT_U; pat_idx=pat_idx+1)begin
        sram_r0.reset_sram;
        sram_r1.reset_sram;
        sram_r2.reset_sram;
        sram_r3.reset_sram;

        sram_gb0.reset_sram;
        sram_gb1.reset_sram;
        sram_gb2.reset_sram;
        sram_gb3.reset_sram;

        sram_fy0.reset_sram;
        sram_fy1.reset_sram;
        sram_fy2.reset_sram;
        sram_fy3.reset_sram;

        sram_fc0.reset_sram;
        sram_fc1.reset_sram;
        sram_fc2.reset_sram;
        sram_fc3.reset_sram;

        load_golden(pat_idx, test_layer);

        error_r0 = 0;
        error_r1 = 0;
        error_r2 = 0;
        error_r3 = 0;
        error_gb0 = 0;
        error_gb1 = 0;
        error_gb2 = 0;
        error_gb3 = 0;
        error_fy0 = 0;
        error_fy1 = 0;
        error_fy2 = 0;
        error_fy3 = 0;
        error_fc0 = 0;
        error_fc1 = 0;
        error_fc2 = 0;
        error_fc3 = 0;

        $display("\n========================================================================");
        $display("======================== Pattern No. %02d ========================", pat_idx);
        $display("========================================================================");
        $display();

        srst_n = 1;
        enable = 0;
        @(negedge clk); #(1); srst_n = 1'b0;
        @(negedge clk); #(1); srst_n = 1'b1;
        @(negedge clk); #(1); enable = 1'b1;
        @(negedge clk); #(1); enable = 1'b0;

        wait(valid);

        if (`COMPARE) compare_output();
    end

    if (`COMPARE) begin
        aver_cycle_cnt = cycle_cnt / `NUM_PAT;
        $display("\n\n\n                   Summary of all pattern: ");
        if(total_err_pat == 0) begin 
            $display("------------------------------------------------------------\n");
            $write("%c[1;32mCongratulations! %c[0m",27, 27);
            $display("Your %s layer is correct!", layer_str);
            $display("Total cycle count = %0d", cycle_cnt);
            $display("Average cycle count per pattern = %0d", aver_cycle_cnt);
            $display("-----------------------------PASS---------------------------\n");
            
        end else begin
            $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
            $display("X                                                            X");
            $display("X        %c[1;31mFAIL%c[0m in %-26s layer!!!         X",27,27, layer_str);
            $display("X              %3d patterns are failed... (T ~ T)            X", total_err_pat);
            $display("X                                                            X");
            $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
            $display("Total cycle count = %0d", cycle_cnt);
            $display("Average cycle count per pattern = %0d", aver_cycle_cnt);
        end
    end
    $finish;
end

task load_golden(
    input integer index,
    input integer layer
);
    reg [8-1:0] index_digit_1, index_digit_0, index_ref;
    begin
        index_digit_1 = (index % 100 ) / 10 + 48;
        index_digit_0 = (index % 10  ) + 48;
        index_ref = `REF + 48;

        pattern_r0_file = "pat/src_raw_00_r0.dat";                                  // 23 char
        pattern_r1_file = "pat/src_raw_00_r1.dat";                                  // 23 char
        pattern_r2_file = "pat/src_raw_00_r2.dat";                                  // 23 char
        pattern_r3_file = "pat/src_raw_00_r3.dat";                                  // 23 char
        pattern_gb0_file = "pat/src_raw_00_gb0.dat";                                // 24 char
        pattern_gb1_file = "pat/src_raw_00_gb1.dat";                                // 24 char
        pattern_gb2_file = "pat/src_raw_00_gb2.dat";                                // 24 char
        pattern_gb3_file = "pat/src_raw_00_gb3.dat";                                // 24 char
        wb_r0_golden_file = "golden/wb/src_wb_00_r0.dat";                           // 26 char
        wb_r1_golden_file = "golden/wb/src_wb_00_r1.dat";                           // 26 char
        wb_r2_golden_file = "golden/wb/src_wb_00_r2.dat";                           // 26 char
        wb_r3_golden_file = "golden/wb/src_wb_00_r3.dat";                           // 26 char
        wb_gb0_golden_file = "golden/wb/src_wb_00_gb0.dat";                         // 27 char
        wb_gb1_golden_file = "golden/wb/src_wb_00_gb1.dat";                         // 27 char
        wb_gb2_golden_file = "golden/wb/src_wb_00_gb2.dat";                         // 27 char
        wb_gb3_golden_file = "golden/wb/src_wb_00_gb3.dat";                         // 27 char
        demosaic_r0_golden_file = "golden/demosaic/src_demosaic_00_r0.dat";         // 38 char
        demosaic_r1_golden_file = "golden/demosaic/src_demosaic_00_r1.dat";         // 38 char
        demosaic_r2_golden_file = "golden/demosaic/src_demosaic_00_r2.dat";         // 38 char
        demosaic_r3_golden_file = "golden/demosaic/src_demosaic_00_r3.dat";         // 38 char
        demosaic_gb0_golden_file = "golden/demosaic/src_demosaic_00_gb0.dat";       // 39 char
        demosaic_gb1_golden_file = "golden/demosaic/src_demosaic_00_gb1.dat";       // 39 char
        demosaic_gb2_golden_file = "golden/demosaic/src_demosaic_00_gb2.dat";       // 39 char
        demosaic_gb3_golden_file = "golden/demosaic/src_demosaic_00_gb3.dat";       // 39 char
        gamma_r0_golden_file = "golden/gamma/src_gamma_00_r0.dat";                  // 32 char
        gamma_r1_golden_file = "golden/gamma/src_gamma_00_r1.dat";                  // 32 char
        gamma_r2_golden_file = "golden/gamma/src_gamma_00_r2.dat";                  // 32 char
        gamma_r3_golden_file = "golden/gamma/src_gamma_00_r3.dat";                  // 32 char
        gamma_gb0_golden_file = "golden/gamma/src_gamma_00_gb0.dat";                // 33 char
        gamma_gb1_golden_file = "golden/gamma/src_gamma_00_gb1.dat";                // 33 char
        gamma_gb2_golden_file = "golden/gamma/src_gamma_00_gb2.dat";                // 33 char
        gamma_gb3_golden_file = "golden/gamma/src_gamma_00_gb3.dat";                // 33 char
        ref_pat_r0_file = "pat/ref_pat_00_r0.dat";                                  // 23 char
        ref_pat_r1_file = "pat/ref_pat_00_r1.dat";                                  // 23 char
        ref_pat_r2_file = "pat/ref_pat_00_r2.dat";                                  // 23 char
        ref_pat_r3_file = "pat/ref_pat_00_r3.dat";                                  // 23 char
        ref_pat_gb0_file = "pat/ref_pat_00_gb0.dat";                                // 24 char
        ref_pat_gb1_file = "pat/ref_pat_00_gb1.dat";                                // 24 char
        ref_pat_gb2_file = "pat/ref_pat_00_gb2.dat";                                // 24 char
        ref_pat_gb3_file = "pat/ref_pat_00_gb3.dat";                                // 24 char
        src_fy0_golden_file = "golden/src_y_channel/src_ych_00_fy0.dat";            // 39 char
        src_fy1_golden_file = "golden/src_y_channel/src_ych_00_fy1.dat";            // 39 char
        src_fy2_golden_file = "golden/src_y_channel/src_ych_00_fy2.dat";            // 39 char
        src_fy3_golden_file = "golden/src_y_channel/src_ych_00_fy3.dat";            // 39 char
        src_fc0_golden_file = "golden/src_cbcr_channel/src_cbcrch_00_fc0.dat";      // 45 char
        src_fc1_golden_file = "golden/src_cbcr_channel/src_cbcrch_00_fc1.dat";      // 45 char
        src_fc2_golden_file = "golden/src_cbcr_channel/src_cbcrch_00_fc2.dat";      // 45 char
        src_fc3_golden_file = "golden/src_cbcr_channel/src_cbcrch_00_fc3.dat";      // 45 char
        ref_fy0_golden_file = "golden/ref_y_channel/ref_ych_00_fy0.dat";            // 39 char
        ref_fy1_golden_file = "golden/ref_y_channel/ref_ych_00_fy1.dat";            // 39 char
        ref_fy2_golden_file = "golden/ref_y_channel/ref_ych_00_fy2.dat";            // 39 char
        ref_fy3_golden_file = "golden/ref_y_channel/ref_ych_00_fy3.dat";            // 39 char
        ref_fc0_golden_file = "golden/ref_cbcr_channel/ref_cbcrch_00_fc0.dat";      // 45 char
        ref_fc1_golden_file = "golden/ref_cbcr_channel/ref_cbcrch_00_fc1.dat";      // 45 char
        ref_fc2_golden_file = "golden/ref_cbcr_channel/ref_cbcrch_00_fc2.dat";      // 45 char
        ref_fc3_golden_file = "golden/ref_cbcr_channel/ref_cbcrch_00_fc3.dat";      // 45 char
        light_fy0_golden_file = "golden/light_match/light_match_00_fy0.dat";        // 41 char
        light_fy1_golden_file = "golden/light_match/light_match_00_fy1.dat";        // 41 char
        light_fy2_golden_file = "golden/light_match/light_match_00_fy2.dat";        // 41 char
        light_fy3_golden_file = "golden/light_match/light_match_00_fy3.dat";        // 41 char
        color_fc0_golden_file = "golden/color_match/color_match_00_fc0.dat";        // 41 char
        color_fc1_golden_file = "golden/color_match/color_match_00_fc1.dat";        // 41 char
        color_fc2_golden_file = "golden/color_match/color_match_00_fc2.dat";        // 41 char
        color_fc3_golden_file = "golden/color_match/color_match_00_fc3.dat";        // 41 char
        final_fy0_golden_file = "golden/final_0/final_00_fy0.dat";                  // 31 char
        final_fy1_golden_file = "golden/final_0/final_00_fy1.dat";                  // 31 char
        final_fy2_golden_file = "golden/final_0/final_00_fy2.dat";                  // 31 char
        final_fy3_golden_file = "golden/final_0/final_00_fy3.dat";                  // 31 char
        final_fc0_golden_file = "golden/final_0/final_00_fc0.dat";                  // 31 char
        final_fc1_golden_file = "golden/final_0/final_00_fc1.dat";                  // 31 char
        final_fc2_golden_file = "golden/final_0/final_00_fc2.dat";                  // 31 char
        final_fc3_golden_file = "golden/final_0/final_00_fc3.dat";                  // 31 char

        pattern_r0_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_r1_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_r2_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_r3_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_gb0_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_gb1_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_gb2_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        pattern_gb3_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_r0_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_r1_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_r2_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_r3_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_gb0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_gb1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_gb2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        wb_gb3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_r0_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_r1_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_r2_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_r3_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_gb0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_gb1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_gb2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        demosaic_gb3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_r0_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_r1_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_r2_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_r3_golden_file[7*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_gb0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_gb1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_gb2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        gamma_gb3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        ref_pat_r0_file[7*8 +: 1*8] = index_ref;
        ref_pat_r1_file[7*8 +: 1*8] = index_ref;
        ref_pat_r2_file[7*8 +: 1*8] = index_ref;
        ref_pat_r3_file[7*8 +: 1*8] = index_ref;
        ref_pat_gb0_file[8*8 +: 1*8] = index_ref;
        ref_pat_gb1_file[8*8 +: 1*8] = index_ref;
        ref_pat_gb2_file[8*8 +: 1*8] = index_ref;
        ref_pat_gb3_file[8*8 +: 1*8] = index_ref;
        src_fy0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fy1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fy2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fy3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fc0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fc1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fc2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        src_fc3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fy0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fy1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fy2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fy3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fc0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fc1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fc2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        // ref_fc3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        light_fy0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        light_fy1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        light_fy2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        light_fy3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        color_fc0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        color_fc1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        color_fc2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        color_fc3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fy0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fy1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fy2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fy3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fc0_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fc1_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fc2_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fc3_golden_file[8*8 +: `PAT_NAME_LENGTH*8] = {index_digit_1, index_digit_0};
        final_fy0_golden_file[17*8 +: 1*8] = index_ref;
        final_fy1_golden_file[17*8 +: 1*8] = index_ref;
        final_fy2_golden_file[17*8 +: 1*8] = index_ref;
        final_fy3_golden_file[17*8 +: 1*8] = index_ref;
        final_fc0_golden_file[17*8 +: 1*8] = index_ref;
        final_fc1_golden_file[17*8 +: 1*8] = index_ref;
        final_fc2_golden_file[17*8 +: 1*8] = index_ref;
        final_fc3_golden_file[17*8 +: 1*8] = index_ref;


        if (`TEST_ALL) begin
            $readmemh(pattern_r0_file, input_sram_value_r0);
            $readmemh(pattern_r1_file, input_sram_value_r1);
            $readmemh(pattern_r2_file, input_sram_value_r2);
            $readmemh(pattern_r3_file, input_sram_value_r3);
            $readmemh(pattern_gb0_file, input_sram_value_gb0);
            $readmemh(pattern_gb1_file, input_sram_value_gb1);
            $readmemh(pattern_gb2_file, input_sram_value_gb2);
            $readmemh(pattern_gb3_file, input_sram_value_gb3);
            $readmemh(ref_pat_r0_file, input_sram_value_fy0);
            $readmemh(ref_pat_r1_file, input_sram_value_fy1);
            $readmemh(ref_pat_r2_file, input_sram_value_fy2);
            $readmemh(ref_pat_r3_file, input_sram_value_fy3);
            $readmemh(ref_pat_gb0_file, input_sram_value_fc0);
            $readmemh(ref_pat_gb1_file, input_sram_value_fc1);
            $readmemh(ref_pat_gb2_file, input_sram_value_fc2);
            $readmemh(ref_pat_gb3_file, input_sram_value_fc3);
        end
        else begin
            case (test_layer)
                WB: begin
                    $readmemh(pattern_r0_file, input_sram_value_r0);
                    $readmemh(pattern_r1_file, input_sram_value_r1);
                    $readmemh(pattern_r2_file, input_sram_value_r2);
                    $readmemh(pattern_r3_file, input_sram_value_r3);
                    $readmemh(pattern_gb0_file, input_sram_value_gb0);
                    $readmemh(pattern_gb1_file, input_sram_value_gb1);
                    $readmemh(pattern_gb2_file, input_sram_value_gb2);
                    $readmemh(pattern_gb3_file, input_sram_value_gb3);
                end
                DEMOSAIC: begin
                    $readmemh(wb_r0_golden_file, input_sram_value_r0);
                    $readmemh(wb_r1_golden_file, input_sram_value_r1);
                    $readmemh(wb_r2_golden_file, input_sram_value_r2);
                    $readmemh(wb_r3_golden_file, input_sram_value_r3);
                    $readmemh(wb_gb0_golden_file, input_sram_value_gb0);
                    $readmemh(wb_gb1_golden_file, input_sram_value_gb1);
                    $readmemh(wb_gb2_golden_file, input_sram_value_gb2);
                    $readmemh(wb_gb3_golden_file, input_sram_value_gb3);
                end
                GAMMA: begin
                    $readmemh(demosaic_r0_golden_file, input_sram_value_r0);
                    $readmemh(demosaic_r1_golden_file, input_sram_value_r1);
                    $readmemh(demosaic_r2_golden_file, input_sram_value_r2);
                    $readmemh(demosaic_r3_golden_file, input_sram_value_r3);
                    $readmemh(demosaic_gb0_golden_file, input_sram_value_gb0);
                    $readmemh(demosaic_gb1_golden_file, input_sram_value_gb1);
                    $readmemh(demosaic_gb2_golden_file, input_sram_value_gb2);
                    $readmemh(demosaic_gb3_golden_file, input_sram_value_gb3);
                end
                YCBCR_SRC: begin
                    $readmemh(gamma_r0_golden_file, input_sram_value_r0);
                    $readmemh(gamma_r1_golden_file, input_sram_value_r1);
                    $readmemh(gamma_r2_golden_file, input_sram_value_r2);
                    $readmemh(gamma_r3_golden_file, input_sram_value_r3);
                    $readmemh(gamma_gb0_golden_file, input_sram_value_gb0);
                    $readmemh(gamma_gb1_golden_file, input_sram_value_gb1);
                    $readmemh(gamma_gb2_golden_file, input_sram_value_gb2);
                    $readmemh(gamma_gb3_golden_file, input_sram_value_gb3);
                end
                YCBCR_REF: begin
                    $readmemh(ref_pat_r0_file, input_sram_value_fy0);
                    $readmemh(ref_pat_r1_file, input_sram_value_fy1);
                    $readmemh(ref_pat_r2_file, input_sram_value_fy2);
                    $readmemh(ref_pat_r3_file, input_sram_value_fy3);
                    $readmemh(ref_pat_gb0_file, input_sram_value_fc0);
                    $readmemh(ref_pat_gb1_file, input_sram_value_fc1);
                    $readmemh(ref_pat_gb2_file, input_sram_value_fc2);
                    $readmemh(ref_pat_gb3_file, input_sram_value_fc3);
                end
                LIGHT_MATCH: begin
                    $readmemh(src_fy0_golden_file, input_sram_value_r0);
                    $readmemh(src_fy1_golden_file, input_sram_value_r1);
                    $readmemh(src_fy2_golden_file, input_sram_value_r2);
                    $readmemh(src_fy3_golden_file, input_sram_value_r3);
                    $readmemh(src_fc0_golden_file, input_sram_value_gb0);
                    $readmemh(src_fc1_golden_file, input_sram_value_gb1);
                    $readmemh(src_fc2_golden_file, input_sram_value_gb2);
                    $readmemh(src_fc3_golden_file, input_sram_value_gb3);
                    $readmemh(ref_fy0_golden_file, input_sram_value_fy0);
                    $readmemh(ref_fy1_golden_file, input_sram_value_fy1);
                    $readmemh(ref_fy2_golden_file, input_sram_value_fy2);
                    $readmemh(ref_fy3_golden_file, input_sram_value_fy3);
                    $readmemh(ref_fc0_golden_file, input_sram_value_fc0);
                    $readmemh(ref_fc1_golden_file, input_sram_value_fc1);
                    $readmemh(ref_fc2_golden_file, input_sram_value_fc2);
                    $readmemh(ref_fc3_golden_file, input_sram_value_fc3);
                end
                COLOR_MATCH: begin
                    $readmemh(src_fy0_golden_file, input_sram_value_r0);
                    $readmemh(src_fy1_golden_file, input_sram_value_r1);
                    $readmemh(src_fy2_golden_file, input_sram_value_r2);
                    $readmemh(src_fy3_golden_file, input_sram_value_r3);
                    $readmemh(src_fc0_golden_file, input_sram_value_gb0);
                    $readmemh(src_fc1_golden_file, input_sram_value_gb1);
                    $readmemh(src_fc2_golden_file, input_sram_value_gb2);
                    $readmemh(src_fc3_golden_file, input_sram_value_gb3);
                    $readmemh(ref_fy0_golden_file, input_sram_value_fy0);
                    $readmemh(ref_fy1_golden_file, input_sram_value_fy1);
                    $readmemh(ref_fy2_golden_file, input_sram_value_fy2);
                    $readmemh(ref_fy3_golden_file, input_sram_value_fy3);
                    $readmemh(ref_fc0_golden_file, input_sram_value_fc0);
                    $readmemh(ref_fc1_golden_file, input_sram_value_fc1);
                    $readmemh(ref_fc2_golden_file, input_sram_value_fc2);
                    $readmemh(ref_fc3_golden_file, input_sram_value_fc3);
                end
                FINAL: begin
                    $readmemh(light_fy0_golden_file, input_sram_value_r0);
                    $readmemh(light_fy1_golden_file, input_sram_value_r1);
                    $readmemh(light_fy2_golden_file, input_sram_value_r2);
                    $readmemh(light_fy3_golden_file, input_sram_value_r3);
                    $readmemh(color_fc0_golden_file, input_sram_value_gb0);
                    $readmemh(color_fc1_golden_file, input_sram_value_gb1);
                    $readmemh(color_fc2_golden_file, input_sram_value_gb2);
                    $readmemh(color_fc3_golden_file, input_sram_value_gb3);
                end
            endcase
        end

        case (test_layer)
            WB: begin
                $readmemh(wb_r0_golden_file, golden_sram_value_r0);
                $readmemh(wb_r1_golden_file, golden_sram_value_r1);
                $readmemh(wb_r2_golden_file, golden_sram_value_r2);
                $readmemh(wb_r3_golden_file, golden_sram_value_r3);
                $readmemh(wb_gb0_golden_file, golden_sram_value_gb0);
                $readmemh(wb_gb1_golden_file, golden_sram_value_gb1);
                $readmemh(wb_gb2_golden_file, golden_sram_value_gb2);
                $readmemh(wb_gb3_golden_file, golden_sram_value_gb3);
            end
            DEMOSAIC: begin
                $readmemh(demosaic_r0_golden_file, golden_sram_value_r0);
                $readmemh(demosaic_r1_golden_file, golden_sram_value_r1);
                $readmemh(demosaic_r2_golden_file, golden_sram_value_r2);
                $readmemh(demosaic_r3_golden_file, golden_sram_value_r3);
                $readmemh(demosaic_gb0_golden_file, golden_sram_value_gb0);
                $readmemh(demosaic_gb1_golden_file, golden_sram_value_gb1);
                $readmemh(demosaic_gb2_golden_file, golden_sram_value_gb2);
                $readmemh(demosaic_gb3_golden_file, golden_sram_value_gb3);
            end
            GAMMA: begin
                $readmemh(gamma_r0_golden_file, golden_sram_value_r0);
                $readmemh(gamma_r1_golden_file, golden_sram_value_r1);
                $readmemh(gamma_r2_golden_file, golden_sram_value_r2);
                $readmemh(gamma_r3_golden_file, golden_sram_value_r3);
                $readmemh(gamma_gb0_golden_file, golden_sram_value_gb0);
                $readmemh(gamma_gb1_golden_file, golden_sram_value_gb1);
                $readmemh(gamma_gb2_golden_file, golden_sram_value_gb2);
                $readmemh(gamma_gb3_golden_file, golden_sram_value_gb3);
            end
            YCBCR_REF: begin
                $readmemh(ref_fy0_golden_file, golden_sram_value_fy0);
                $readmemh(ref_fy1_golden_file, golden_sram_value_fy1);
                $readmemh(ref_fy2_golden_file, golden_sram_value_fy2);
                $readmemh(ref_fy3_golden_file, golden_sram_value_fy3);
                $readmemh(ref_fc0_golden_file, golden_sram_value_fc0);
                $readmemh(ref_fc1_golden_file, golden_sram_value_fc1);
                $readmemh(ref_fc2_golden_file, golden_sram_value_fc2);
                $readmemh(ref_fc3_golden_file, golden_sram_value_fc3);
            end
            YCBCR_SRC: begin
                $readmemh(src_fy0_golden_file, golden_sram_value_r0);
                $readmemh(src_fy1_golden_file, golden_sram_value_r1);
                $readmemh(src_fy2_golden_file, golden_sram_value_r2);
                $readmemh(src_fy3_golden_file, golden_sram_value_r3);
                $readmemh(src_fc0_golden_file, golden_sram_value_gb0);
                $readmemh(src_fc1_golden_file, golden_sram_value_gb1);
                $readmemh(src_fc2_golden_file, golden_sram_value_gb2);
                $readmemh(src_fc3_golden_file, golden_sram_value_gb3);
            end
            LIGHT_MATCH: begin
                $readmemh(light_fy0_golden_file, golden_sram_value_r0);
                $readmemh(light_fy1_golden_file, golden_sram_value_r1);
                $readmemh(light_fy2_golden_file, golden_sram_value_r2);
                $readmemh(light_fy3_golden_file, golden_sram_value_r3);
            end
            COLOR_MATCH: begin
                $readmemh(color_fc0_golden_file, golden_sram_value_gb0);
                $readmemh(color_fc1_golden_file, golden_sram_value_gb1);
                $readmemh(color_fc2_golden_file, golden_sram_value_gb2);
                $readmemh(color_fc3_golden_file, golden_sram_value_gb3);
            end
            FINAL: begin
                $readmemh(final_fy0_golden_file, golden_sram_value_r0);
                $readmemh(final_fy1_golden_file, golden_sram_value_r1);
                $readmemh(final_fy2_golden_file, golden_sram_value_r2);
                $readmemh(final_fy3_golden_file, golden_sram_value_r3);
                $readmemh(final_fc0_golden_file, golden_sram_value_gb0);
                $readmemh(final_fc1_golden_file, golden_sram_value_gb1);
                $readmemh(final_fc2_golden_file, golden_sram_value_gb2);
                $readmemh(final_fc3_golden_file, golden_sram_value_gb3);
            end
        endcase

        // r0
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_r0.load_pixel(i, input_sram_value_r0[i]);
        end
        // r1
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_r1.load_pixel(i, input_sram_value_r1[i]);
        end
        // r2
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_r2.load_pixel(i, input_sram_value_r2[i]);
        end
        // r3
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_r3.load_pixel(i, input_sram_value_r3[i]);
        end
        // gb0
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_gb0.load_pixel(i, input_sram_value_gb0[i]);
        end
        // gb1
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_gb1.load_pixel(i, input_sram_value_gb1[i]);
        end
        // gb2
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_gb2.load_pixel(i, input_sram_value_gb2[i]);
        end
        // gb3
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_gb3.load_pixel(i, input_sram_value_gb3[i]);
        end
        // fy0
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fy0.load_pixel(i, input_sram_value_fy0[i]);
        end
        // fy1
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fy1.load_pixel(i, input_sram_value_fy1[i]);
        end
        // fy2
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fy2.load_pixel(i, input_sram_value_fy2[i]);
        end
        // fy3
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fy3.load_pixel(i, input_sram_value_fy3[i]);
        end
        // fc0
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fc0.load_pixel(i, input_sram_value_fc0[i]);
        end
        // fc1
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fc1.load_pixel(i, input_sram_value_fc1[i]);
        end
        // fc2
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fc2.load_pixel(i, input_sram_value_fc2[i]);
        end
        // fc3
        for(i=0; i<HEIGHT*WIDTH/16; i=i+1)begin
            sram_fc3.load_pixel(i, input_sram_value_fc3[i]);
        end
    end
endtask

task compare_output();
    integer m, l;
    integer error_tmp;
    begin 
        if (test_layer != YCBCR_REF && test_layer != COLOR_MATCH) begin
            // R match
            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_r0[m][l*LINEAR_BW+:LINEAR_BW] !== sram_r0.mem[m][l*LINEAR_BW+:LINEAR_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #R0 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(R0, m);
                    error_r0 = error_r0 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #R0 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_r0 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #R0 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #R0 have %0d errors!", layer_str, error_r0);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_r1[m][l*LINEAR_BW+:LINEAR_BW] !== sram_r1.mem[m][l*LINEAR_BW+:LINEAR_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #R1 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(R1, m);
                    error_r1 = error_r1 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #R1 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_r1 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #R1 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #R1 have %0d errors!", layer_str, error_r1);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_r2[m][l*LINEAR_BW+:LINEAR_BW] !== sram_r2.mem[m][l*LINEAR_BW+:LINEAR_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #R2 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(R2, m);
                    error_r2 = error_r2 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #R2 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_r2 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #R2 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #R2 have %0d errors!", layer_str, error_r2);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_r3[m][l*LINEAR_BW+:LINEAR_BW] !== sram_r3.mem[m][l*LINEAR_BW+:LINEAR_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #R3 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(R3, m);
                    error_r3 = error_r3 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #R3 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_r3 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #R3 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #R3 have %0d errors!", layer_str, error_r3);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");
        end

        if (test_layer != YCBCR_REF && test_layer != LIGHT_MATCH) begin
            // GB match
            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_gb0[m][l*LINEAR_BW*2+:LINEAR_BW*2] !== sram_gb0.mem[m][l*LINEAR_BW*2+:LINEAR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #GB0 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(GB0, m);
                    error_gb0 = error_gb0 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #GB0 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_gb0 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #GB0 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #GB0 have %0d errors!", layer_str, error_gb0);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_gb1[m][l*LINEAR_BW*2+:LINEAR_BW*2] !== sram_gb1.mem[m][l*LINEAR_BW*2+:LINEAR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #GB1 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(GB1, m);
                    error_gb1 = error_gb1 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #GB1 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_gb1 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #GB1 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #GB1 have %0d errors!", layer_str, error_gb1);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_gb2[m][l*LINEAR_BW*2+:LINEAR_BW*2] !== sram_gb2.mem[m][l*LINEAR_BW*2+:LINEAR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #GB2 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(GB2, m);
                    error_gb2 = error_gb2 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #GB2 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_gb2 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #GB2 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #GB2 have %0d errors!", layer_str, error_gb2);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_gb3[m][l*LINEAR_BW*2+:LINEAR_BW*2] !== sram_gb3.mem[m][l*LINEAR_BW*2+:LINEAR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #GB3 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(GB3, m);
                    error_gb3 = error_gb3 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #GB3 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_gb3 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #GB3 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #GB3 have %0d errors!", layer_str, error_gb3);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");
        end

        if (test_layer == YCBCR_REF) begin
            // Y match
            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fy0[m][l*RGB_BW+:RGB_BW] !== sram_fy0.mem[m][l*RGB_BW+:RGB_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FY0 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FY0, m);
                    error_fy0 = error_fy0 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FY0 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fy0 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FY0 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FY0 have %0d errors!", layer_str, error_fy0);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fy1[m][l*RGB_BW+:RGB_BW] !== sram_fy1.mem[m][l*RGB_BW+:RGB_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FY1 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FY1, m);
                    error_fy1 = error_fy1 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FY1 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fy1 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FY1 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FY1 have %0d errors!", layer_str, error_fy1);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fy2[m][l*RGB_BW+:RGB_BW] !== sram_fy2.mem[m][l*RGB_BW+:RGB_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FY2 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FY2, m);
                    error_fy2 = error_fy2 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FY2 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fy2 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FY2 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FY2 have %0d errors!", layer_str, error_fy2);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fy3[m][l*RGB_BW+:RGB_BW] !== sram_fy3.mem[m][l*RGB_BW+:RGB_BW]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FY3 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FY3, m);
                    error_fy3 = error_fy3 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FY3 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fy3 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FY3 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FY3 have %0d errors!", layer_str, error_fy3);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fc0[m][l*CBCR_BW*2+:CBCR_BW*2] !== sram_fc0.mem[m][l*CBCR_BW*2+:CBCR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FC0 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FC0, m);
                    error_fc0 = error_fc0 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FC0 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fc0 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FC0 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FC0 have %0d errors!", layer_str, error_fc0);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fc1[m][l*CBCR_BW*2+:CBCR_BW*2] !== sram_fc1.mem[m][l*CBCR_BW*2+:CBCR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FC1 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FC1, m);
                    error_fc1 = error_fc1 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FC1 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fc1 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FC1 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FC1 have %0d errors!", layer_str, error_fc1);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fc2[m][l*CBCR_BW*2+:CBCR_BW*2] !== sram_fc2.mem[m][l*CBCR_BW*2+:CBCR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FC2 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FC2, m);
                    error_fc2 = error_fc2 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FC2 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fc2 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FC2 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FC2 have %0d errors!", layer_str, error_fc2);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");

            for(m=0; m<WIDTH*HEIGHT/16; m=m+1) begin
                error_tmp = 0;
                for(l=0; l<4; l=l+1) begin
                    if((golden_sram_value_fc3[m][l*CBCR_BW*2+:CBCR_BW*2] !== sram_fc3.mem[m][l*CBCR_BW*2+:CBCR_BW*2]))
                        error_tmp = error_tmp + 1;
                end
                if (error_tmp != 0) begin
                    if(`FLAG_VERBOSE) $display("Sram #FC3 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(FC0, m);
                    error_fc3 = error_fc3 + 1;
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #FC3 address %0d PASS!", m);
                end
            end

            if(`FLAG_VERBOSE) $display("========================================================================");
            if(error_fc3 == 0) begin
                if(`FLAG_VERBOSE) $display("%s results in sram #FC3 are successfully passed!", layer_str);
            end else begin
                $display("%s results in sram #FC3 have %0d errors!", layer_str, error_fc3);
            end
            if(`FLAG_VERBOSE) $display("========================================================================\n");
        end
        
        error_total = error_r0 + error_r1 + error_r2 + error_r3 + error_gb0 + error_gb1 + error_gb2 + error_gb3 + error_fy0 + error_fy1 + error_fy2 + error_fy3 + error_fc0 + error_fc1 + error_fc2 + error_fc3; 

        // summary of this pattern
        if(`FLAG_VERBOSE) $display("\n========================================================================");
        if(error_total == 0) begin
            if(`FLAG_VERBOSE) $display("Congratulations! Your %s layer is correct!", layer_str);
            if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
            else              $write("%c[1;32mPASS! %c[0m",27, 27);
        end else begin
            if(`FLAG_VERBOSE) $display("There are total %0d errors in your %s layer.", error_total, layer_str);
            if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
            else              $write("%c[1;31mFAIL! %c[0m",27, 27);
            total_err_pat = total_err_pat + 1;
        end
        if(`FLAG_VERBOSE) $display("========================================================================");
        // $finish;
    end
endtask

task display_error(
    input [3:0] which_sram,
    input integer addr_offset
);
    begin
        case(which_sram)
            R0: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_r0.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (sram_r0.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_r0.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (sram_r0.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_r0[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r0[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r0[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r0[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            R1: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_r1.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (sram_r1.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_r1.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (sram_r1.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_r1[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r1[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r1[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r1[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            R2: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_r2.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (sram_r2.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_r2.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (sram_r2.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_r2[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r2[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r2[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r2[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            R3: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_r3.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (sram_r3.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_r3.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (sram_r3.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_r3[addr_offset][3*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r3[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r3[addr_offset][1*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_r3[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            GB0: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_gb0.mem[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (sram_gb0.mem[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb0.mem[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (sram_gb0.mem[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb0.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (sram_gb0.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb0.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (sram_gb0.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_gb0[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb0[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb0[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb0[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb0[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb0[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb0[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb0[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            GB1: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_gb1.mem[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (sram_gb1.mem[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb1.mem[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (sram_gb1.mem[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb1.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (sram_gb1.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb1.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (sram_gb1.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_gb1[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb1[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb1[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb1[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb1[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb1[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb1[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb1[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            GB2: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_gb2.mem[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (sram_gb2.mem[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb2.mem[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (sram_gb2.mem[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb2.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (sram_gb2.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb2.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (sram_gb2.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_gb2[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb2[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb2[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb2[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb2[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb2[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb2[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb2[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            GB3: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_gb3.mem[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (sram_gb3.mem[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb3.mem[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (sram_gb3.mem[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb3.mem[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (sram_gb3.mem[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (sram_gb3.mem[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (sram_gb3.mem[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_gb3[addr_offset][7*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb3[addr_offset][6*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb3[addr_offset][5*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb3[addr_offset][4*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb3[addr_offset][3*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb3[addr_offset][2*LINEAR_BW +: LINEAR_BW]),
                    (golden_sram_value_gb3[addr_offset][1*LINEAR_BW +: LINEAR_BW]), (golden_sram_value_gb3[addr_offset][0*LINEAR_BW +: LINEAR_BW]));
            end
            FY0: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_fy0.mem[addr_offset][3*RGB_BW +: RGB_BW]),
                    (sram_fy0.mem[addr_offset][2*RGB_BW +: RGB_BW]),
                    (sram_fy0.mem[addr_offset][1*RGB_BW +: RGB_BW]),
                    (sram_fy0.mem[addr_offset][0*RGB_BW +: RGB_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_fy0[addr_offset][3*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy0[addr_offset][2*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy0[addr_offset][1*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy0[addr_offset][0*RGB_BW +: RGB_BW]));
            end
            FY1: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_fy1.mem[addr_offset][3*RGB_BW +: RGB_BW]),
                    (sram_fy1.mem[addr_offset][2*RGB_BW +: RGB_BW]),
                    (sram_fy1.mem[addr_offset][1*RGB_BW +: RGB_BW]),
                    (sram_fy1.mem[addr_offset][0*RGB_BW +: RGB_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_fy1[addr_offset][3*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy1[addr_offset][2*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy1[addr_offset][1*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy1[addr_offset][0*RGB_BW +: RGB_BW]));
            end
            FY2: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_fy2.mem[addr_offset][3*RGB_BW +: RGB_BW]),
                    (sram_fy2.mem[addr_offset][2*RGB_BW +: RGB_BW]),
                    (sram_fy2.mem[addr_offset][1*RGB_BW +: RGB_BW]),
                    (sram_fy2.mem[addr_offset][0*RGB_BW +: RGB_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_fy2[addr_offset][3*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy2[addr_offset][2*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy2[addr_offset][1*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy2[addr_offset][0*RGB_BW +: RGB_BW]));
            end
            FY3: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (sram_fy3.mem[addr_offset][3*RGB_BW +: RGB_BW]),
                    (sram_fy3.mem[addr_offset][2*RGB_BW +: RGB_BW]),
                    (sram_fy3.mem[addr_offset][1*RGB_BW +: RGB_BW]),
                    (sram_fy3.mem[addr_offset][0*RGB_BW +: RGB_BW]));
                $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3) \n", 
                    (golden_sram_value_fy3[addr_offset][3*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy3[addr_offset][2*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy3[addr_offset][1*RGB_BW +: RGB_BW]),
                    (golden_sram_value_fy3[addr_offset][0*RGB_BW +: RGB_BW]));
            end
            FC0: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_fc0.mem[addr_offset][7*CBCR_BW +: CBCR_BW]), (sram_fc0.mem[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (sram_fc0.mem[addr_offset][5*CBCR_BW +: CBCR_BW]), (sram_fc0.mem[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (sram_fc0.mem[addr_offset][3*CBCR_BW +: CBCR_BW]), (sram_fc0.mem[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (sram_fc0.mem[addr_offset][1*CBCR_BW +: CBCR_BW]), (sram_fc0.mem[addr_offset][0*CBCR_BW +: CBCR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_fc0[addr_offset][7*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc0[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc0[addr_offset][5*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc0[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc0[addr_offset][3*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc0[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc0[addr_offset][1*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc0[addr_offset][0*CBCR_BW +: CBCR_BW]));
            end
            FC1: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_fc1.mem[addr_offset][7*CBCR_BW +: CBCR_BW]), (sram_fc1.mem[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (sram_fc1.mem[addr_offset][5*CBCR_BW +: CBCR_BW]), (sram_fc1.mem[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (sram_fc1.mem[addr_offset][3*CBCR_BW +: CBCR_BW]), (sram_fc1.mem[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (sram_fc1.mem[addr_offset][1*CBCR_BW +: CBCR_BW]), (sram_fc1.mem[addr_offset][0*CBCR_BW +: CBCR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_fc1[addr_offset][7*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc1[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc1[addr_offset][5*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc1[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc1[addr_offset][3*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc1[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc1[addr_offset][1*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc1[addr_offset][0*CBCR_BW +: CBCR_BW]));
            end
            FC2: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_fc2.mem[addr_offset][7*CBCR_BW +: CBCR_BW]), (sram_fc2.mem[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (sram_fc2.mem[addr_offset][5*CBCR_BW +: CBCR_BW]), (sram_fc2.mem[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (sram_fc2.mem[addr_offset][3*CBCR_BW +: CBCR_BW]), (sram_fc2.mem[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (sram_fc2.mem[addr_offset][1*CBCR_BW +: CBCR_BW]), (sram_fc2.mem[addr_offset][0*CBCR_BW +: CBCR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_fc2[addr_offset][7*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc2[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc2[addr_offset][5*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc2[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc2[addr_offset][3*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc2[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc2[addr_offset][1*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc2[addr_offset][0*CBCR_BW +: CBCR_BW]));
            end
            FC3: begin
                $write("Your answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (sram_fc3.mem[addr_offset][7*CBCR_BW +: CBCR_BW]), (sram_fc3.mem[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (sram_fc3.mem[addr_offset][5*CBCR_BW +: CBCR_BW]), (sram_fc3.mem[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (sram_fc3.mem[addr_offset][3*CBCR_BW +: CBCR_BW]), (sram_fc3.mem[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (sram_fc3.mem[addr_offset][1*CBCR_BW +: CBCR_BW]), (sram_fc3.mem[addr_offset][0*CBCR_BW +: CBCR_BW]));
                $write("But the golden answer is \n%d %d (ch0)\n%d %d (ch1)\n%d %d (ch2)\n%d %d (ch3) \n", 
                    (golden_sram_value_fc3[addr_offset][7*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc3[addr_offset][6*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc3[addr_offset][5*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc3[addr_offset][4*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc3[addr_offset][3*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc3[addr_offset][2*CBCR_BW +: CBCR_BW]),
                    (golden_sram_value_fc3[addr_offset][1*CBCR_BW +: CBCR_BW]), (golden_sram_value_fc3[addr_offset][0*CBCR_BW +: CBCR_BW]));
            end
        endcase
    end
endtask

endmodule
