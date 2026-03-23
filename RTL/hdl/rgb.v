module rgb #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16,
    parameter RGB_BW = 8
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
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

    // SRAM read address outputs -> 1920*1080/16
    output reg [17-1:0] sram_raddr_rgb0123,

    // SRAM write address outputs -> 1920*1080/16
    output wire [17-1:0] sram_waddr_rgb0123,

    // SRAM write enable outputs (neg.)
    output wire sram_wen_rgb0123,

    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    output wire [CH_NUM-1:0] sram_wordmask_r0123,
    output wire [CH_NUM*2-1:0] sram_wordmask_gb0123,

    // SRAM write data outputs
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3,

    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2,
    output wire [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3
);

// FSM
localparam PRESEND0 = 2'd0;
localparam PRESEND1 = 2'd1;
localparam PROCESS  = 2'd2;
localparam DONE     = 2'd3;

reg [1:0]state, state_n;
wire done_n;

reg [17-1:0] addr_cnt, addr_cnt_n;      // 129600

// 8bit
wire [RGB_BW-1:0] Y00, Y10, Y20, Y30,
                  Y01, Y11, Y21, Y31,
                  Y02, Y12, Y22, Y32,
                  Y03, Y13, Y23, Y33;

// 8Q8
wire [LINEAR_BW-1:0] Cb00, Cb10, Cb20, Cb30,
                     Cb01, Cb11, Cb21, Cb31,
                     Cb02, Cb12, Cb22, Cb32,
                     Cb03, Cb13, Cb23, Cb33;
wire [LINEAR_BW-1:0] Cr00, Cr10, Cr20, Cr30,
                     Cr01, Cr11, Cr21, Cr31,
                     Cr02, Cr12, Cr22, Cr32,
                     Cr03, Cr13, Cr23, Cr33;

// -128 18bit
wire signed [LINEAR_BW+1-1:0] Cb00_si, Cb10_si, Cb20_si, Cb30_si,
                              Cb01_si, Cb11_si, Cb21_si, Cb31_si,
                              Cb02_si, Cb12_si, Cb22_si, Cb32_si,
                              Cb03_si, Cb13_si, Cb23_si, Cb33_si;
wire signed [LINEAR_BW+1-1:0] Cr00_si, Cr10_si, Cr20_si, Cr30_si,
                              Cr01_si, Cr11_si, Cr21_si, Cr31_si,
                              Cr02_si, Cr12_si, Cr22_si, Cr32_si,
                              Cr03_si, Cr13_si, Cr23_si, Cr33_si;

// 30bit (Q=18)
wire signed [LINEAR_BW+1+12-1:0] R00_mul, R10_mul, R20_mul, R30_mul,
                            R01_mul, R11_mul, R21_mul, R31_mul,
                            R02_mul, R12_mul, R22_mul, R32_mul,
                            R03_mul, R13_mul, R23_mul, R33_mul;
// 31
wire signed [LINEAR_BW+1+12+1-1:0] G00_mul, G10_mul, G20_mul, G30_mul,
                            G01_mul, G11_mul, G21_mul, G31_mul,
                            G02_mul, G12_mul, G22_mul, G32_mul,
                            G03_mul, G13_mul, G23_mul, G33_mul;
wire signed [LINEAR_BW+1+12-1:0] B00_mul, B10_mul, B20_mul, B30_mul,
                            B01_mul, B11_mul, B21_mul, B31_mul,
                            B02_mul, B12_mul, B22_mul, B32_mul,
                            B03_mul, B13_mul, B23_mul, B33_mul;


// 10bit
wire signed [RGB_BW+2-1:0] R00_sum, R10_sum, R20_sum, R30_sum,
                            R01_sum, R11_sum, R21_sum, R31_sum,
                            R02_sum, R12_sum, R22_sum, R32_sum,
                            R03_sum, R13_sum, R23_sum, R33_sum;
// 11
wire signed [RGB_BW+3-1:0] G00_sum, G10_sum, G20_sum, G30_sum,
                            G01_sum, G11_sum, G21_sum, G31_sum,
                            G02_sum, G12_sum, G22_sum, G32_sum,
                            G03_sum, G13_sum, G23_sum, G33_sum;
wire signed [RGB_BW+2-1:0] B00_sum, B10_sum, B20_sum, B30_sum,
                            B01_sum, B11_sum, B21_sum, B31_sum,
                            B02_sum, B12_sum, B22_sum, B32_sum,
                            B03_sum, B13_sum, B23_sum, B33_sum;

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


// assign {Y00, Y10, Y20, Y30} = sram_rdata_r0;
// assign {Y01, Y11, Y21, Y31} = sram_rdata_r1;
// assign {Y02, Y12, Y22, Y32} = sram_rdata_r2;
// assign {Y03, Y13, Y23, Y33} = sram_rdata_r3;

assign {Y00, Y10, Y20, Y30} = {sram_rdata_r0[LINEAR_BW*3 +: RGB_BW], sram_rdata_r0[LINEAR_BW*2 +: RGB_BW], sram_rdata_r0[LINEAR_BW*1 +: RGB_BW], sram_rdata_r0[LINEAR_BW*0 +: RGB_BW]};
assign {Y01, Y11, Y21, Y31} = {sram_rdata_r1[LINEAR_BW*3 +: RGB_BW], sram_rdata_r1[LINEAR_BW*2 +: RGB_BW], sram_rdata_r1[LINEAR_BW*1 +: RGB_BW], sram_rdata_r1[LINEAR_BW*0 +: RGB_BW]};
assign {Y02, Y12, Y22, Y32} = {sram_rdata_r2[LINEAR_BW*3 +: RGB_BW], sram_rdata_r2[LINEAR_BW*2 +: RGB_BW], sram_rdata_r2[LINEAR_BW*1 +: RGB_BW], sram_rdata_r2[LINEAR_BW*0 +: RGB_BW]};
assign {Y03, Y13, Y23, Y33} = {sram_rdata_r3[LINEAR_BW*3 +: RGB_BW], sram_rdata_r3[LINEAR_BW*2 +: RGB_BW], sram_rdata_r3[LINEAR_BW*1 +: RGB_BW], sram_rdata_r3[LINEAR_BW*0 +: RGB_BW]};


assign {Cb00, Cr00, Cb10, Cr10, Cb20, Cr20, Cb30, Cr30} = sram_rdata_gb0;
assign {Cb01, Cr01, Cb11, Cr11, Cb21, Cr21, Cb31, Cr31} = sram_rdata_gb1;
assign {Cb02, Cr02, Cb12, Cr12, Cb22, Cr22, Cb32, Cr32} = sram_rdata_gb2;
assign {Cb03, Cr03, Cb13, Cr13, Cb23, Cr23, Cb33, Cr33} = sram_rdata_gb3;


// Cb_si = Cb - 128.0
assign Cb00_si = $signed({2'b00, Cb00}) - $signed({10'd128, 8'd0});
assign Cb10_si = $signed({2'b00, Cb10}) - $signed({10'd128, 8'd0});
assign Cb20_si = $signed({2'b00, Cb20}) - $signed({10'd128, 8'd0});
assign Cb30_si = $signed({2'b00, Cb30}) - $signed({10'd128, 8'd0});
assign Cb01_si = $signed({2'b00, Cb01}) - $signed({10'd128, 8'd0});
assign Cb11_si = $signed({2'b00, Cb11}) - $signed({10'd128, 8'd0});
assign Cb21_si = $signed({2'b00, Cb21}) - $signed({10'd128, 8'd0});
assign Cb31_si = $signed({2'b00, Cb31}) - $signed({10'd128, 8'd0});
assign Cb02_si = $signed({2'b00, Cb02}) - $signed({10'd128, 8'd0});
assign Cb12_si = $signed({2'b00, Cb12}) - $signed({10'd128, 8'd0});
assign Cb22_si = $signed({2'b00, Cb22}) - $signed({10'd128, 8'd0});
assign Cb32_si = $signed({2'b00, Cb32}) - $signed({10'd128, 8'd0});
assign Cb03_si = $signed({2'b00, Cb03}) - $signed({10'd128, 8'd0});
assign Cb13_si = $signed({2'b00, Cb13}) - $signed({10'd128, 8'd0});
assign Cb23_si = $signed({2'b00, Cb23}) - $signed({10'd128, 8'd0});
assign Cb33_si = $signed({2'b00, Cb33}) - $signed({10'd128, 8'd0});

// Cr_si = Cr - 128.0
assign Cr00_si = $signed({2'b00, Cr00}) - $signed({10'd128, 8'd0});
assign Cr10_si = $signed({2'b00, Cr10}) - $signed({10'd128, 8'd0});
assign Cr20_si = $signed({2'b00, Cr20}) - $signed({10'd128, 8'd0});
assign Cr30_si = $signed({2'b00, Cr30}) - $signed({10'd128, 8'd0});
assign Cr01_si = $signed({2'b00, Cr01}) - $signed({10'd128, 8'd0});
assign Cr11_si = $signed({2'b00, Cr11}) - $signed({10'd128, 8'd0});
assign Cr21_si = $signed({2'b00, Cr21}) - $signed({10'd128, 8'd0});
assign Cr31_si = $signed({2'b00, Cr31}) - $signed({10'd128, 8'd0});
assign Cr02_si = $signed({2'b00, Cr02}) - $signed({10'd128, 8'd0});
assign Cr12_si = $signed({2'b00, Cr12}) - $signed({10'd128, 8'd0});
assign Cr22_si = $signed({2'b00, Cr22}) - $signed({10'd128, 8'd0});
assign Cr32_si = $signed({2'b00, Cr32}) - $signed({10'd128, 8'd0});
assign Cr03_si = $signed({2'b00, Cr03}) - $signed({10'd128, 8'd0});
assign Cr13_si = $signed({2'b00, Cr13}) - $signed({10'd128, 8'd0});
assign Cr23_si = $signed({2'b00, Cr23}) - $signed({10'd128, 8'd0});
assign Cr33_si = $signed({2'b00, Cr33}) - $signed({10'd128, 8'd0});

// mul = quan(1.402)   * Cr_si
assign R00_mul = 12'sb0101_1001_1011 * Cr00_si;
assign R10_mul = 12'sb0101_1001_1011 * Cr10_si;
assign R20_mul = 12'sb0101_1001_1011 * Cr20_si;
assign R30_mul = 12'sb0101_1001_1011 * Cr30_si;
assign R01_mul = 12'sb0101_1001_1011 * Cr01_si;
assign R11_mul = 12'sb0101_1001_1011 * Cr11_si;
assign R21_mul = 12'sb0101_1001_1011 * Cr21_si;
assign R31_mul = 12'sb0101_1001_1011 * Cr31_si;
assign R02_mul = 12'sb0101_1001_1011 * Cr02_si;
assign R12_mul = 12'sb0101_1001_1011 * Cr12_si;
assign R22_mul = 12'sb0101_1001_1011 * Cr22_si;
assign R32_mul = 12'sb0101_1001_1011 * Cr32_si;
assign R03_mul = 12'sb0101_1001_1011 * Cr03_si;
assign R13_mul = 12'sb0101_1001_1011 * Cr13_si;
assign R23_mul = 12'sb0101_1001_1011 * Cr23_si;
assign R33_mul = 12'sb0101_1001_1011 * Cr33_si;


// R = Y + quan(1.402)   * (Cr - 128)
assign R00_sum = $signed({1'b0, Y00}) + $signed(R00_mul[18 +: 9]);
assign R10_sum = $signed({1'b0, Y10}) + $signed(R10_mul[18 +: 9]);
assign R20_sum = $signed({1'b0, Y20}) + $signed(R20_mul[18 +: 9]);
assign R30_sum = $signed({1'b0, Y30}) + $signed(R30_mul[18 +: 9]);
assign R01_sum = $signed({1'b0, Y01}) + $signed(R01_mul[18 +: 9]);
assign R11_sum = $signed({1'b0, Y11}) + $signed(R11_mul[18 +: 9]);
assign R21_sum = $signed({1'b0, Y21}) + $signed(R21_mul[18 +: 9]);
assign R31_sum = $signed({1'b0, Y31}) + $signed(R31_mul[18 +: 9]);
assign R02_sum = $signed({1'b0, Y02}) + $signed(R02_mul[18 +: 9]);
assign R12_sum = $signed({1'b0, Y12}) + $signed(R12_mul[18 +: 9]);
assign R22_sum = $signed({1'b0, Y22}) + $signed(R22_mul[18 +: 9]);
assign R32_sum = $signed({1'b0, Y32}) + $signed(R32_mul[18 +: 9]);
assign R03_sum = $signed({1'b0, Y03}) + $signed(R03_mul[18 +: 9]);
assign R13_sum = $signed({1'b0, Y13}) + $signed(R13_mul[18 +: 9]);
assign R23_sum = $signed({1'b0, Y23}) + $signed(R23_mul[18 +: 9]);
assign R33_sum = $signed({1'b0, Y33}) + $signed(R33_mul[18 +: 9]);


// G_mul = - quan(0.34414) * Cb - quan(0.71414) * Cr
assign G00_mul = - 12'sb0001_0110_0000 * Cb00_si - 12'sb0010_1101_1011 * Cr00_si;
assign G10_mul = - 12'sb0001_0110_0000 * Cb10_si - 12'sb0010_1101_1011 * Cr10_si;
assign G20_mul = - 12'sb0001_0110_0000 * Cb20_si - 12'sb0010_1101_1011 * Cr20_si;
assign G30_mul = - 12'sb0001_0110_0000 * Cb30_si - 12'sb0010_1101_1011 * Cr30_si;
assign G01_mul = - 12'sb0001_0110_0000 * Cb01_si - 12'sb0010_1101_1011 * Cr01_si;
assign G11_mul = - 12'sb0001_0110_0000 * Cb11_si - 12'sb0010_1101_1011 * Cr11_si;
assign G21_mul = - 12'sb0001_0110_0000 * Cb21_si - 12'sb0010_1101_1011 * Cr21_si;
assign G31_mul = - 12'sb0001_0110_0000 * Cb31_si - 12'sb0010_1101_1011 * Cr31_si;
assign G02_mul = - 12'sb0001_0110_0000 * Cb02_si - 12'sb0010_1101_1011 * Cr02_si;
assign G12_mul = - 12'sb0001_0110_0000 * Cb12_si - 12'sb0010_1101_1011 * Cr12_si;
assign G22_mul = - 12'sb0001_0110_0000 * Cb22_si - 12'sb0010_1101_1011 * Cr22_si;
assign G32_mul = - 12'sb0001_0110_0000 * Cb32_si - 12'sb0010_1101_1011 * Cr32_si;
assign G03_mul = - 12'sb0001_0110_0000 * Cb03_si - 12'sb0010_1101_1011 * Cr03_si;
assign G13_mul = - 12'sb0001_0110_0000 * Cb13_si - 12'sb0010_1101_1011 * Cr13_si;
assign G23_mul = - 12'sb0001_0110_0000 * Cb23_si - 12'sb0010_1101_1011 * Cr23_si;
assign G33_mul = - 12'sb0001_0110_0000 * Cb33_si - 12'sb0010_1101_1011 * Cr33_si;


// G = Y - quan(0.34414) * Cb - quan(0.71414) * Cr
assign G00_sum = $signed({2'd0, Y00}) + $signed(G00_mul[18 +: 10]);
assign G10_sum = $signed({2'd0, Y10}) + $signed(G10_mul[18 +: 10]);
assign G20_sum = $signed({2'd0, Y20}) + $signed(G20_mul[18 +: 10]);
assign G30_sum = $signed({2'd0, Y30}) + $signed(G30_mul[18 +: 10]);
assign G01_sum = $signed({2'd0, Y01}) + $signed(G01_mul[18 +: 10]);
assign G11_sum = $signed({2'd0, Y11}) + $signed(G11_mul[18 +: 10]);
assign G21_sum = $signed({2'd0, Y21}) + $signed(G21_mul[18 +: 10]);
assign G31_sum = $signed({2'd0, Y31}) + $signed(G31_mul[18 +: 10]);
assign G02_sum = $signed({2'd0, Y02}) + $signed(G02_mul[18 +: 10]);
assign G12_sum = $signed({2'd0, Y12}) + $signed(G12_mul[18 +: 10]);
assign G22_sum = $signed({2'd0, Y22}) + $signed(G22_mul[18 +: 10]);
assign G32_sum = $signed({2'd0, Y32}) + $signed(G32_mul[18 +: 10]);
assign G03_sum = $signed({2'd0, Y03}) + $signed(G03_mul[18 +: 10]);
assign G13_sum = $signed({2'd0, Y13}) + $signed(G13_mul[18 +: 10]);
assign G23_sum = $signed({2'd0, Y23}) + $signed(G23_mul[18 +: 10]);
assign G33_sum = $signed({2'd0, Y33}) + $signed(G33_mul[18 +: 10]);

// B_mul = quan(1.772)   * Cb
assign B00_mul = 12'sb0111_0001_0110 * Cb00_si;
assign B10_mul = 12'sb0111_0001_0110 * Cb10_si;
assign B20_mul = 12'sb0111_0001_0110 * Cb20_si;
assign B30_mul = 12'sb0111_0001_0110 * Cb30_si;
assign B01_mul = 12'sb0111_0001_0110 * Cb01_si;
assign B11_mul = 12'sb0111_0001_0110 * Cb11_si;
assign B21_mul = 12'sb0111_0001_0110 * Cb21_si;
assign B31_mul = 12'sb0111_0001_0110 * Cb31_si;
assign B02_mul = 12'sb0111_0001_0110 * Cb02_si;
assign B12_mul = 12'sb0111_0001_0110 * Cb12_si;
assign B22_mul = 12'sb0111_0001_0110 * Cb22_si;
assign B32_mul = 12'sb0111_0001_0110 * Cb32_si;
assign B03_mul = 12'sb0111_0001_0110 * Cb03_si;
assign B13_mul = 12'sb0111_0001_0110 * Cb13_si;
assign B23_mul = 12'sb0111_0001_0110 * Cb23_si;
assign B33_mul = 12'sb0111_0001_0110 * Cb33_si;



// B = Y + quan(1.772)   * Cb
assign B00_sum = $signed({1'd0, Y00}) + $signed(B00_mul[18 +: 9]);
assign B10_sum = $signed({1'd0, Y10}) + $signed(B10_mul[18 +: 9]);
assign B20_sum = $signed({1'd0, Y20}) + $signed(B20_mul[18 +: 9]);
assign B30_sum = $signed({1'd0, Y30}) + $signed(B30_mul[18 +: 9]);
assign B01_sum = $signed({1'd0, Y01}) + $signed(B01_mul[18 +: 9]);
assign B11_sum = $signed({1'd0, Y11}) + $signed(B11_mul[18 +: 9]);
assign B21_sum = $signed({1'd0, Y21}) + $signed(B21_mul[18 +: 9]);
assign B31_sum = $signed({1'd0, Y31}) + $signed(B31_mul[18 +: 9]);
assign B02_sum = $signed({1'd0, Y02}) + $signed(B02_mul[18 +: 9]);
assign B12_sum = $signed({1'd0, Y12}) + $signed(B12_mul[18 +: 9]);
assign B22_sum = $signed({1'd0, Y22}) + $signed(B22_mul[18 +: 9]);
assign B32_sum = $signed({1'd0, Y32}) + $signed(B32_mul[18 +: 9]);
assign B03_sum = $signed({1'd0, Y03}) + $signed(B03_mul[18 +: 9]);
assign B13_sum = $signed({1'd0, Y13}) + $signed(B13_mul[18 +: 9]);
assign B23_sum = $signed({1'd0, Y23}) + $signed(B23_mul[18 +: 9]);
assign B33_sum = $signed({1'd0, Y33}) + $signed(B33_mul[18 +: 9]);


// if (R00_sum >= 21's261120)   R00 = 255;
// else if (R00_sum < 21'sd0)   R00 = 0;
// else                         R00 = R00_sum[10 +: RGB_BW];

assign R00 = (R00_sum >= 10'sd255) ? 255 : ((R00_sum < 10'sd0) ? 0 : R00_sum[0 +: RGB_BW]);
assign R10 = (R10_sum >= 10'sd255) ? 255 : ((R10_sum < 10'sd0) ? 0 : R10_sum[0 +: RGB_BW]);
assign R20 = (R20_sum >= 10'sd255) ? 255 : ((R20_sum < 10'sd0) ? 0 : R20_sum[0 +: RGB_BW]);
assign R30 = (R30_sum >= 10'sd255) ? 255 : ((R30_sum < 10'sd0) ? 0 : R30_sum[0 +: RGB_BW]);
assign R01 = (R01_sum >= 10'sd255) ? 255 : ((R01_sum < 10'sd0) ? 0 : R01_sum[0 +: RGB_BW]);
assign R11 = (R11_sum >= 10'sd255) ? 255 : ((R11_sum < 10'sd0) ? 0 : R11_sum[0 +: RGB_BW]);
assign R21 = (R21_sum >= 10'sd255) ? 255 : ((R21_sum < 10'sd0) ? 0 : R21_sum[0 +: RGB_BW]);
assign R31 = (R31_sum >= 10'sd255) ? 255 : ((R31_sum < 10'sd0) ? 0 : R31_sum[0 +: RGB_BW]);
assign R02 = (R02_sum >= 10'sd255) ? 255 : ((R02_sum < 10'sd0) ? 0 : R02_sum[0 +: RGB_BW]);
assign R12 = (R12_sum >= 10'sd255) ? 255 : ((R12_sum < 10'sd0) ? 0 : R12_sum[0 +: RGB_BW]);
assign R22 = (R22_sum >= 10'sd255) ? 255 : ((R22_sum < 10'sd0) ? 0 : R22_sum[0 +: RGB_BW]);
assign R32 = (R32_sum >= 10'sd255) ? 255 : ((R32_sum < 10'sd0) ? 0 : R32_sum[0 +: RGB_BW]);
assign R03 = (R03_sum >= 10'sd255) ? 255 : ((R03_sum < 10'sd0) ? 0 : R03_sum[0 +: RGB_BW]);
assign R13 = (R13_sum >= 10'sd255) ? 255 : ((R13_sum < 10'sd0) ? 0 : R13_sum[0 +: RGB_BW]);
assign R23 = (R23_sum >= 10'sd255) ? 255 : ((R23_sum < 10'sd0) ? 0 : R23_sum[0 +: RGB_BW]);
assign R33 = (R33_sum >= 10'sd255) ? 255 : ((R33_sum < 10'sd0) ? 0 : R33_sum[0 +: RGB_BW]);

assign G00 = (G00_sum >= 11'sd255) ? 255 : ((G00_sum < 11'sd0) ? 0 : G00_sum[0 +: RGB_BW]);
assign G10 = (G10_sum >= 11'sd255) ? 255 : ((G10_sum < 11'sd0) ? 0 : G10_sum[0 +: RGB_BW]);
assign G20 = (G20_sum >= 11'sd255) ? 255 : ((G20_sum < 11'sd0) ? 0 : G20_sum[0 +: RGB_BW]);
assign G30 = (G30_sum >= 11'sd255) ? 255 : ((G30_sum < 11'sd0) ? 0 : G30_sum[0 +: RGB_BW]);
assign G01 = (G01_sum >= 11'sd255) ? 255 : ((G01_sum < 11'sd0) ? 0 : G01_sum[0 +: RGB_BW]);
assign G11 = (G11_sum >= 11'sd255) ? 255 : ((G11_sum < 11'sd0) ? 0 : G11_sum[0 +: RGB_BW]);
assign G21 = (G21_sum >= 11'sd255) ? 255 : ((G21_sum < 11'sd0) ? 0 : G21_sum[0 +: RGB_BW]);
assign G31 = (G31_sum >= 11'sd255) ? 255 : ((G31_sum < 11'sd0) ? 0 : G31_sum[0 +: RGB_BW]);
assign G02 = (G02_sum >= 11'sd255) ? 255 : ((G02_sum < 11'sd0) ? 0 : G02_sum[0 +: RGB_BW]);
assign G12 = (G12_sum >= 11'sd255) ? 255 : ((G12_sum < 11'sd0) ? 0 : G12_sum[0 +: RGB_BW]);
assign G22 = (G22_sum >= 11'sd255) ? 255 : ((G22_sum < 11'sd0) ? 0 : G22_sum[0 +: RGB_BW]);
assign G32 = (G32_sum >= 11'sd255) ? 255 : ((G32_sum < 11'sd0) ? 0 : G32_sum[0 +: RGB_BW]);
assign G03 = (G03_sum >= 11'sd255) ? 255 : ((G03_sum < 11'sd0) ? 0 : G03_sum[0 +: RGB_BW]);
assign G13 = (G13_sum >= 11'sd255) ? 255 : ((G13_sum < 11'sd0) ? 0 : G13_sum[0 +: RGB_BW]);
assign G23 = (G23_sum >= 11'sd255) ? 255 : ((G23_sum < 11'sd0) ? 0 : G23_sum[0 +: RGB_BW]);
assign G33 = (G33_sum >= 11'sd255) ? 255 : ((G33_sum < 11'sd0) ? 0 : G33_sum[0 +: RGB_BW]);

assign B00 = (B00_sum >= 10'sd255) ? 255 : ((B00_sum < 10'sd0) ? 0 : B00_sum[0 +: RGB_BW]);
assign B10 = (B10_sum >= 10'sd255) ? 255 : ((B10_sum < 10'sd0) ? 0 : B10_sum[0 +: RGB_BW]);
assign B20 = (B20_sum >= 10'sd255) ? 255 : ((B20_sum < 10'sd0) ? 0 : B20_sum[0 +: RGB_BW]);
assign B30 = (B30_sum >= 10'sd255) ? 255 : ((B30_sum < 10'sd0) ? 0 : B30_sum[0 +: RGB_BW]);
assign B01 = (B01_sum >= 10'sd255) ? 255 : ((B01_sum < 10'sd0) ? 0 : B01_sum[0 +: RGB_BW]);
assign B11 = (B11_sum >= 10'sd255) ? 255 : ((B11_sum < 10'sd0) ? 0 : B11_sum[0 +: RGB_BW]);
assign B21 = (B21_sum >= 10'sd255) ? 255 : ((B21_sum < 10'sd0) ? 0 : B21_sum[0 +: RGB_BW]);
assign B31 = (B31_sum >= 10'sd255) ? 255 : ((B31_sum < 10'sd0) ? 0 : B31_sum[0 +: RGB_BW]);
assign B02 = (B02_sum >= 10'sd255) ? 255 : ((B02_sum < 10'sd0) ? 0 : B02_sum[0 +: RGB_BW]);
assign B12 = (B12_sum >= 10'sd255) ? 255 : ((B12_sum < 10'sd0) ? 0 : B12_sum[0 +: RGB_BW]);
assign B22 = (B22_sum >= 10'sd255) ? 255 : ((B22_sum < 10'sd0) ? 0 : B22_sum[0 +: RGB_BW]);
assign B32 = (B32_sum >= 10'sd255) ? 255 : ((B32_sum < 10'sd0) ? 0 : B32_sum[0 +: RGB_BW]);
assign B03 = (B03_sum >= 10'sd255) ? 255 : ((B03_sum < 10'sd0) ? 0 : B03_sum[0 +: RGB_BW]);
assign B13 = (B13_sum >= 10'sd255) ? 255 : ((B13_sum < 10'sd0) ? 0 : B13_sum[0 +: RGB_BW]);
assign B23 = (B23_sum >= 10'sd255) ? 255 : ((B23_sum < 10'sd0) ? 0 : B23_sum[0 +: RGB_BW]);
assign B33 = (B33_sum >= 10'sd255) ? 255 : ((B33_sum < 10'sd0) ? 0 : B33_sum[0 +: RGB_BW]);



// SRAM control
assign done_n = state == DONE;
assign sram_waddr_rgb0123 = addr_cnt;

assign sram_wen_rgb0123 = (state != PROCESS);

assign sram_wordmask_r0123 = 4'd0;
assign sram_wordmask_gb0123 = 8'd0;

assign sram_wdata_r0 = {8'd0, R00, 8'd0, R10, 8'd0, R20, 8'd0, R30};
assign sram_wdata_r1 = {8'd0, R01, 8'd0, R11, 8'd0, R21, 8'd0, R31};
assign sram_wdata_r2 = {8'd0, R02, 8'd0, R12, 8'd0, R22, 8'd0, R32};
assign sram_wdata_r3 = {8'd0, R03, 8'd0, R13, 8'd0, R23, 8'd0, R33};

assign sram_wdata_gb0 = {8'd0, G00, 8'd0, B00, 8'd0, G10, 8'd0, B10, 8'd0, G20, 8'd0, B20, 8'd0, G30, 8'd0, B30};
assign sram_wdata_gb1 = {8'd0, G01, 8'd0, B01, 8'd0, G11, 8'd0, B11, 8'd0, G21, 8'd0, B21, 8'd0, G31, 8'd0, B31};
assign sram_wdata_gb2 = {8'd0, G02, 8'd0, B02, 8'd0, G12, 8'd0, B12, 8'd0, G22, 8'd0, B22, 8'd0, G32, 8'd0, B32};
assign sram_wdata_gb3 = {8'd0, G03, 8'd0, B03, 8'd0, G13, 8'd0, B13, 8'd0, G23, 8'd0, B23, 8'd0, G33, 8'd0, B33};

always @(posedge clk) begin
    if (~srst_n) begin
        state <= PRESEND0;
        done <= 1'b0;
        addr_cnt <= 0;
    end else begin
        state <= state_n;
        done <= done_n;
        addr_cnt <= addr_cnt_n;
    end
end


always @* begin
    case (state)    //synopsys parallel_case
        PRESEND0: 
            if (enable)                 state_n = PRESEND1;
            else                        state_n = PRESEND0;
        PRESEND1: 
                                        state_n = PROCESS;
        PROCESS: begin
            if (addr_cnt == 129600-1)   state_n = DONE;
            else                        state_n = PROCESS;
        end
        DONE: begin
                                        state_n = PRESEND0;
        end
    endcase
end

// cnt
always @* begin
    if (state == PROCESS)
        addr_cnt_n = addr_cnt + 1;
    else
        addr_cnt_n = 0;
end

// raddr
always @* begin
    case (state)    //synopsys parallel_case
        PRESEND0:   sram_raddr_rgb0123 = 0;
        PRESEND1:   sram_raddr_rgb0123 = 1;
        PROCESS:    sram_raddr_rgb0123 = addr_cnt + 2;
        DONE:       sram_raddr_rgb0123 = 0;
    endcase
end
endmodule