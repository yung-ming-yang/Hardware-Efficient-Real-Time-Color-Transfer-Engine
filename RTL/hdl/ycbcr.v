module ycbcr #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16,
    parameter RGB_BW = 8,
    parameter CBCR_BW = 16
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    input wire is_source,       // ref = 0; source = 1
    output reg done,

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
    // SRAM_FC for reference CbCr channel
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc0,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc1,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc2,
    input wire [CBCR_BW*2*CH_NUM-1:0] sram_rdata_fc3,

    // SRAM read address outputs -> 1920*1080/16
    output wire [17-1:0] sram_raddr_rgb0123,
    output wire [17-1:0] sram_raddr_fyfc0123,

    // SRAM write address outputs -> 1920*1080/16
    output wire [17-1:0] sram_waddr_rgb0123,
    output wire [17-1:0] sram_waddr_fyfc0123,

    // SRAM write enable outputs (neg.)
    output wire sram_wen_rgb0123,
    output wire sram_wen_fyfc0123,

    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    output wire [CH_NUM-1:0] sram_wordmask_r0123,
    output wire [CH_NUM*2-1:0] sram_wordmask_gb0123,

    output wire [CH_NUM-1:0] sram_wordmask_fy0123,
    output wire [CH_NUM*2-1:0] sram_wordmask_fc0123,

    // SRAM write data outputs
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3,

    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3,

    output wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy0,
    output wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy1,
    output wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy2,
    output wire [RGB_BW*CH_NUM-1:0] sram_wdata_fy3,

    output wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc0,
    output wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc1,
    output wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc2,
    output wire [CBCR_BW*2*CH_NUM-1:0] sram_wdata_fc3
);

// FSM
localparam PRESEND0 = 2'd0;
localparam PRESEND1 = 2'd1;
localparam PROCESS  = 2'd2;
localparam DONE     = 2'd3;

reg [1:0]state, state_n;
reg done_n;

reg [9-1:0] r_h_cnt, r_h_cnt_n;
reg [9-1:0] r_v_cnt, r_v_cnt_n;
reg [9-1:0] w_h_cnt, w_h_cnt_n;
reg [9-1:0] w_v_cnt, w_v_cnt_n;

wire [RGB_BW-1:0] R00, R10, R20, R30,
                  R01, R11, R21, R31,
                  R02, R12, R22, R32,
                  R03, R13, R23, R33;
wire [RGB_BW-1:0] G00, G10, G20, G30,
                  G01, G11, G21, G31,
                  G02, G12, G22, G32,
                  G03, G13, G23, G33;
wire [RGB_BW-1:0] B00, B10, B20, B30,
                  B01, B11, B21, B31,
                  B02, B12, B22, B32,
                  B03, B13, B23, B33;
// 18bit
wire [RGB_BW+10-1:0] Y00_sum, Y10_sum, Y20_sum, Y30_sum,
                     Y01_sum, Y11_sum, Y21_sum, Y31_sum,
                     Y02_sum, Y12_sum, Y22_sum, Y32_sum,
                     Y03_sum, Y13_sum, Y23_sum, Y33_sum;
wire [RGB_BW+10-1:0] Cb00_sum, Cb10_sum, Cb20_sum, Cb30_sum,
                     Cb01_sum, Cb11_sum, Cb21_sum, Cb31_sum,
                     Cb02_sum, Cb12_sum, Cb22_sum, Cb32_sum,
                     Cb03_sum, Cb13_sum, Cb23_sum, Cb33_sum;
wire [RGB_BW+10-1:0] Cr00_sum, Cr10_sum, Cr20_sum, Cr30_sum,
                     Cr01_sum, Cr11_sum, Cr21_sum, Cr31_sum,
                     Cr02_sum, Cr12_sum, Cr22_sum, Cr32_sum,
                     Cr03_sum, Cr13_sum, Cr23_sum, Cr33_sum;


assign {R00, R10, R20, R30} = is_source ? {sram_rdata_r0[LINEAR_BW*3 +: RGB_BW], sram_rdata_r0[LINEAR_BW*2 +: RGB_BW], sram_rdata_r0[LINEAR_BW*1 +: RGB_BW], sram_rdata_r0[LINEAR_BW*0 +: RGB_BW]} :
                                          sram_rdata_fy0;
assign {R01, R11, R21, R31} = is_source ? {sram_rdata_r1[LINEAR_BW*3 +: RGB_BW], sram_rdata_r1[LINEAR_BW*2 +: RGB_BW], sram_rdata_r1[LINEAR_BW*1 +: RGB_BW], sram_rdata_r1[LINEAR_BW*0 +: RGB_BW]} :
                                          sram_rdata_fy1;
assign {R02, R12, R22, R32} = is_source ? {sram_rdata_r2[LINEAR_BW*3 +: RGB_BW], sram_rdata_r2[LINEAR_BW*2 +: RGB_BW], sram_rdata_r2[LINEAR_BW*1 +: RGB_BW], sram_rdata_r2[LINEAR_BW*0 +: RGB_BW]} :
                                          sram_rdata_fy2;
assign {R03, R13, R23, R33} = is_source ? {sram_rdata_r3[LINEAR_BW*3 +: RGB_BW], sram_rdata_r3[LINEAR_BW*2 +: RGB_BW], sram_rdata_r3[LINEAR_BW*1 +: RGB_BW], sram_rdata_r3[LINEAR_BW*0 +: RGB_BW]} :
                                          sram_rdata_fy3;

assign {G00, G10, G20, G30} = is_source ? {sram_rdata_gb0[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*2-8-1 -: RGB_BW]} :
                                          {sram_rdata_fc0[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*2-8-1 -: RGB_BW]} ;
assign {G01, G11, G21, G31} = is_source ? {sram_rdata_gb1[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*2-8-1 -: RGB_BW]} :
                                          {sram_rdata_fc1[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*2-8-1 -: RGB_BW]} ;
assign {G02, G12, G22, G32} = is_source ? {sram_rdata_gb2[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*2-8-1 -: RGB_BW]} :
                                          {sram_rdata_fc2[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*2-8-1 -: RGB_BW]} ;
assign {G03, G13, G23, G33} = is_source ? {sram_rdata_gb3[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*2-8-1 -: RGB_BW]} :
                                          {sram_rdata_fc3[LINEAR_BW*8-8-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*6-8-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*4-8-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*2-8-1 -: RGB_BW]} ;

assign {B00, B10, B20, B30} = is_source ? {sram_rdata_gb0[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_gb0[LINEAR_BW*2-24-1 -: RGB_BW]} :
                                          {sram_rdata_fc0[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_fc0[LINEAR_BW*2-24-1 -: RGB_BW]} ;
assign {B01, B11, B21, B31} = is_source ? {sram_rdata_gb1[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_gb1[LINEAR_BW*2-24-1 -: RGB_BW]} :
                                          {sram_rdata_fc1[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_fc1[LINEAR_BW*2-24-1 -: RGB_BW]} ;
assign {B02, B12, B22, B32} = is_source ? {sram_rdata_gb2[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_gb2[LINEAR_BW*2-24-1 -: RGB_BW]} :
                                          {sram_rdata_fc2[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_fc2[LINEAR_BW*2-24-1 -: RGB_BW]} ;
assign {B03, B13, B23, B33} = is_source ? {sram_rdata_gb3[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_gb3[LINEAR_BW*2-24-1 -: RGB_BW]} :
                                          {sram_rdata_fc3[LINEAR_BW*8-24-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*6-24-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*4-24-1 -: RGB_BW], sram_rdata_fc3[LINEAR_BW*2-24-1 -: RGB_BW]} ;

// Y  = quan(0.299) * R + quan(0.587) * G + quan(0.114)  * B
assign Y00_sum = 10'b01_0011_0010 * R00 + 10'b10_0101_1001 * G00 + 10'b00_0111_0100 * B00;
assign Y10_sum = 10'b01_0011_0010 * R10 + 10'b10_0101_1001 * G10 + 10'b00_0111_0100 * B10;
assign Y20_sum = 10'b01_0011_0010 * R20 + 10'b10_0101_1001 * G20 + 10'b00_0111_0100 * B20;
assign Y30_sum = 10'b01_0011_0010 * R30 + 10'b10_0101_1001 * G30 + 10'b00_0111_0100 * B30;

assign Y01_sum = 10'b01_0011_0010 * R01 + 10'b10_0101_1001 * G01 + 10'b00_0111_0100 * B01;
assign Y11_sum = 10'b01_0011_0010 * R11 + 10'b10_0101_1001 * G11 + 10'b00_0111_0100 * B11;
assign Y21_sum = 10'b01_0011_0010 * R21 + 10'b10_0101_1001 * G21 + 10'b00_0111_0100 * B21;
assign Y31_sum = 10'b01_0011_0010 * R31 + 10'b10_0101_1001 * G31 + 10'b00_0111_0100 * B31;

assign Y02_sum = 10'b01_0011_0010 * R02 + 10'b10_0101_1001 * G02 + 10'b00_0111_0100 * B02;
assign Y12_sum = 10'b01_0011_0010 * R12 + 10'b10_0101_1001 * G12 + 10'b00_0111_0100 * B12;
assign Y22_sum = 10'b01_0011_0010 * R22 + 10'b10_0101_1001 * G22 + 10'b00_0111_0100 * B22;
assign Y32_sum = 10'b01_0011_0010 * R32 + 10'b10_0101_1001 * G32 + 10'b00_0111_0100 * B32;

assign Y03_sum = 10'b01_0011_0010 * R03 + 10'b10_0101_1001 * G03 + 10'b00_0111_0100 * B03;
assign Y13_sum = 10'b01_0011_0010 * R13 + 10'b10_0101_1001 * G13 + 10'b00_0111_0100 * B13;
assign Y23_sum = 10'b01_0011_0010 * R23 + 10'b10_0101_1001 * G23 + 10'b00_0111_0100 * B23;
assign Y33_sum = 10'b01_0011_0010 * R33 + 10'b10_0101_1001 * G33 + 10'b00_0111_0100 * B33;

// Cb = quan(-0.1687) * R + quan(-0.3313) * G + quan(0.5)    * B + 128.0
assign Cb00_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R00 - 10'b01_0101_0011 * G00 + 10'b10_0000_0000 * B00;
assign Cb10_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R10 - 10'b01_0101_0011 * G10 + 10'b10_0000_0000 * B10;
assign Cb20_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R20 - 10'b01_0101_0011 * G20 + 10'b10_0000_0000 * B20;
assign Cb30_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R30 - 10'b01_0101_0011 * G30 + 10'b10_0000_0000 * B30;

assign Cb01_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R01 - 10'b01_0101_0011 * G01 + 10'b10_0000_0000 * B01;
assign Cb11_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R11 - 10'b01_0101_0011 * G11 + 10'b10_0000_0000 * B11;
assign Cb21_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R21 - 10'b01_0101_0011 * G21 + 10'b10_0000_0000 * B21;
assign Cb31_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R31 - 10'b01_0101_0011 * G31 + 10'b10_0000_0000 * B31;

assign Cb02_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R02 - 10'b01_0101_0011 * G02 + 10'b10_0000_0000 * B02;
assign Cb12_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R12 - 10'b01_0101_0011 * G12 + 10'b10_0000_0000 * B12;
assign Cb22_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R22 - 10'b01_0101_0011 * G22 + 10'b10_0000_0000 * B22;
assign Cb32_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R32 - 10'b01_0101_0011 * G32 + 10'b10_0000_0000 * B32;

assign Cb03_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R03 - 10'b01_0101_0011 * G03 + 10'b10_0000_0000 * B03;
assign Cb13_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R13 - 10'b01_0101_0011 * G13 + 10'b10_0000_0000 * B13;
assign Cb23_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R23 - 10'b01_0101_0011 * G23 + 10'b10_0000_0000 * B23;
assign Cb33_sum = {8'd128, 10'd0} - 10'b00_1010_1100 * R33 - 10'b01_0101_0011 * G33 + 10'b10_0000_0000 * B33;

// Cr = quan(0.5) * R + quan(-0.4187) * G + quan(-0.0813) * B + 128.0
assign Cr00_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R00 - 10'b01_1010_1100 * G00 - 10'b00_0101_0011 * B00;
assign Cr10_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R10 - 10'b01_1010_1100 * G10 - 10'b00_0101_0011 * B10;
assign Cr20_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R20 - 10'b01_1010_1100 * G20 - 10'b00_0101_0011 * B20;
assign Cr30_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R30 - 10'b01_1010_1100 * G30 - 10'b00_0101_0011 * B30;

assign Cr01_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R01 - 10'b01_1010_1100 * G01 - 10'b00_0101_0011 * B01;
assign Cr11_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R11 - 10'b01_1010_1100 * G11 - 10'b00_0101_0011 * B11;
assign Cr21_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R21 - 10'b01_1010_1100 * G21 - 10'b00_0101_0011 * B21;
assign Cr31_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R31 - 10'b01_1010_1100 * G31 - 10'b00_0101_0011 * B31;

assign Cr02_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R02 - 10'b01_1010_1100 * G02 - 10'b00_0101_0011 * B02;
assign Cr12_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R12 - 10'b01_1010_1100 * G12 - 10'b00_0101_0011 * B12;
assign Cr22_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R22 - 10'b01_1010_1100 * G22 - 10'b00_0101_0011 * B22;
assign Cr32_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R32 - 10'b01_1010_1100 * G32 - 10'b00_0101_0011 * B32;

assign Cr03_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R03 - 10'b01_1010_1100 * G03 - 10'b00_0101_0011 * B03;
assign Cr13_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R13 - 10'b01_1010_1100 * G13 - 10'b00_0101_0011 * B13;
assign Cr23_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R23 - 10'b01_1010_1100 * G23 - 10'b00_0101_0011 * B23;
assign Cr33_sum = {8'd128, 10'd0} + 10'b10_0000_0000 * R33 - 10'b01_1010_1100 * G33 - 10'b00_0101_0011 * B33;



// SRAM
assign sram_raddr_rgb0123 = r_v_cnt * 9'd480 + r_h_cnt;
assign sram_raddr_fyfc0123 = r_v_cnt * 9'd480 + r_h_cnt;
assign sram_waddr_rgb0123 = w_v_cnt * 9'd480 + w_h_cnt;
assign sram_waddr_fyfc0123 = w_v_cnt * 9'd480 + w_h_cnt;

assign sram_wen_rgb0123 = !is_source || (state != PROCESS);
assign sram_wen_fyfc0123 = is_source || (state != PROCESS);

assign sram_wordmask_r0123 = 4'd0;
assign sram_wordmask_gb0123 = 8'd0;
assign sram_wordmask_fy0123 = 4'd0;
assign sram_wordmask_fc0123 = 8'd0;

assign sram_wdata_r0 = {8'd0, Y00_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y10_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y20_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y30_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_r1 = {8'd0, Y01_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y11_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y21_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y31_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_r2 = {8'd0, Y02_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y12_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y22_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y32_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_r3 = {8'd0, Y03_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y13_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y23_sum[RGB_BW+10-1 -: RGB_BW], 8'd0, Y33_sum[RGB_BW+10-1 -: RGB_BW]};

assign sram_wdata_gb0 = {Cb00_sum[RGB_BW+10-1 -: CBCR_BW], Cr00_sum[RGB_BW+10-1 -: CBCR_BW], Cb10_sum[RGB_BW+10-1 -: CBCR_BW], Cr10_sum[RGB_BW+10-1 -: CBCR_BW], Cb20_sum[RGB_BW+10-1 -: CBCR_BW], Cr20_sum[RGB_BW+10-1 -: CBCR_BW], Cb30_sum[RGB_BW+10-1 -: CBCR_BW], Cr30_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_gb1 = {Cb01_sum[RGB_BW+10-1 -: CBCR_BW], Cr01_sum[RGB_BW+10-1 -: CBCR_BW], Cb11_sum[RGB_BW+10-1 -: CBCR_BW], Cr11_sum[RGB_BW+10-1 -: CBCR_BW], Cb21_sum[RGB_BW+10-1 -: CBCR_BW], Cr21_sum[RGB_BW+10-1 -: CBCR_BW], Cb31_sum[RGB_BW+10-1 -: CBCR_BW], Cr31_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_gb2 = {Cb02_sum[RGB_BW+10-1 -: CBCR_BW], Cr02_sum[RGB_BW+10-1 -: CBCR_BW], Cb12_sum[RGB_BW+10-1 -: CBCR_BW], Cr12_sum[RGB_BW+10-1 -: CBCR_BW], Cb22_sum[RGB_BW+10-1 -: CBCR_BW], Cr22_sum[RGB_BW+10-1 -: CBCR_BW], Cb32_sum[RGB_BW+10-1 -: CBCR_BW], Cr32_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_gb3 = {Cb03_sum[RGB_BW+10-1 -: CBCR_BW], Cr03_sum[RGB_BW+10-1 -: CBCR_BW], Cb13_sum[RGB_BW+10-1 -: CBCR_BW], Cr13_sum[RGB_BW+10-1 -: CBCR_BW], Cb23_sum[RGB_BW+10-1 -: CBCR_BW], Cr23_sum[RGB_BW+10-1 -: CBCR_BW], Cb33_sum[RGB_BW+10-1 -: CBCR_BW], Cr33_sum[RGB_BW+10-1 -: CBCR_BW]};

assign sram_wdata_fy0 = {Y00_sum[RGB_BW+10-1 -: RGB_BW], Y10_sum[RGB_BW+10-1 -: RGB_BW], Y20_sum[RGB_BW+10-1 -: RGB_BW], Y30_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_fy1 = {Y01_sum[RGB_BW+10-1 -: RGB_BW], Y11_sum[RGB_BW+10-1 -: RGB_BW], Y21_sum[RGB_BW+10-1 -: RGB_BW], Y31_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_fy2 = {Y02_sum[RGB_BW+10-1 -: RGB_BW], Y12_sum[RGB_BW+10-1 -: RGB_BW], Y22_sum[RGB_BW+10-1 -: RGB_BW], Y32_sum[RGB_BW+10-1 -: RGB_BW]};
assign sram_wdata_fy3 = {Y03_sum[RGB_BW+10-1 -: RGB_BW], Y13_sum[RGB_BW+10-1 -: RGB_BW], Y23_sum[RGB_BW+10-1 -: RGB_BW], Y33_sum[RGB_BW+10-1 -: RGB_BW]};

assign sram_wdata_fc0 = {Cb00_sum[RGB_BW+10-1 -: CBCR_BW], Cr00_sum[RGB_BW+10-1 -: CBCR_BW], Cb10_sum[RGB_BW+10-1 -: CBCR_BW], Cr10_sum[RGB_BW+10-1 -: CBCR_BW], Cb20_sum[RGB_BW+10-1 -: CBCR_BW], Cr20_sum[RGB_BW+10-1 -: CBCR_BW], Cb30_sum[RGB_BW+10-1 -: CBCR_BW], Cr30_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_fc1 = {Cb01_sum[RGB_BW+10-1 -: CBCR_BW], Cr01_sum[RGB_BW+10-1 -: CBCR_BW], Cb11_sum[RGB_BW+10-1 -: CBCR_BW], Cr11_sum[RGB_BW+10-1 -: CBCR_BW], Cb21_sum[RGB_BW+10-1 -: CBCR_BW], Cr21_sum[RGB_BW+10-1 -: CBCR_BW], Cb31_sum[RGB_BW+10-1 -: CBCR_BW], Cr31_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_fc2 = {Cb02_sum[RGB_BW+10-1 -: CBCR_BW], Cr02_sum[RGB_BW+10-1 -: CBCR_BW], Cb12_sum[RGB_BW+10-1 -: CBCR_BW], Cr12_sum[RGB_BW+10-1 -: CBCR_BW], Cb22_sum[RGB_BW+10-1 -: CBCR_BW], Cr22_sum[RGB_BW+10-1 -: CBCR_BW], Cb32_sum[RGB_BW+10-1 -: CBCR_BW], Cr32_sum[RGB_BW+10-1 -: CBCR_BW]};
assign sram_wdata_fc3 = {Cb03_sum[RGB_BW+10-1 -: CBCR_BW], Cr03_sum[RGB_BW+10-1 -: CBCR_BW], Cb13_sum[RGB_BW+10-1 -: CBCR_BW], Cr13_sum[RGB_BW+10-1 -: CBCR_BW], Cb23_sum[RGB_BW+10-1 -: CBCR_BW], Cr23_sum[RGB_BW+10-1 -: CBCR_BW], Cb33_sum[RGB_BW+10-1 -: CBCR_BW], Cr33_sum[RGB_BW+10-1 -: CBCR_BW]};


always @(posedge clk) begin
    if (~srst_n) begin
        state <= PRESEND0;
        done <= 1'b0;
        r_h_cnt <= 9'd0;
        r_v_cnt <= 9'd0;
        w_h_cnt <= 9'd0;
        w_v_cnt <= 9'd0;
    end else if (enable) begin
        state <= state_n;
        done <= done_n;
        r_h_cnt <= r_h_cnt_n;
        r_v_cnt <= r_v_cnt_n;
        w_h_cnt <= w_h_cnt_n;
        w_v_cnt <= w_v_cnt_n;    
    end else begin
        state <= state;
        done <= done;
        r_h_cnt <= r_h_cnt;
        r_v_cnt <= r_v_cnt;
        w_h_cnt <= w_h_cnt;
        w_v_cnt <= w_v_cnt;    
    end
end



always @* begin
    done_n = 0;
    r_h_cnt_n = (r_h_cnt == 9'd479) ? 9'd0 : r_h_cnt + 9'd1;
    r_v_cnt_n = (r_h_cnt == 9'd479) ? r_v_cnt + 9'd1 : r_v_cnt;

    w_h_cnt_n = w_h_cnt;
    w_v_cnt_n = w_v_cnt;

    case (state)
        PRESEND0: begin
            state_n = PRESEND1;
        end
        PRESEND1: begin
            state_n = PROCESS;
        end
        PROCESS: begin
            state_n = (w_h_cnt == 9'd479 && w_v_cnt == 9'd269) ? DONE : PROCESS;
            done_n = (w_h_cnt == 9'd479 && w_v_cnt == 9'd269) ? 1'b1 : 1'b0;

            w_h_cnt_n = (w_h_cnt == 9'd479) ? 9'd0 : w_h_cnt + 9'd1;
            w_v_cnt_n = (w_h_cnt == 9'd479) ? w_v_cnt + 9'd1 : w_v_cnt;
        end
        DONE: begin
            state_n = PRESEND0;
            r_h_cnt_n = 0;
            r_v_cnt_n = 0;
            w_h_cnt_n = 0;
            w_v_cnt_n = 0;
        end
    endcase
end
endmodule