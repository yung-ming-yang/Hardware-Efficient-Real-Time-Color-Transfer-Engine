module demosaic #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output reg done,
    // SRAM read data inputs 
    // SRAM_R for red channel 16bit*4pixel
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r0,
    // input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r1,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r2,
    // input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r3,
    // SRAM_GB for green/blue channel 16bit*4pixel 31~16:G ; 15~0:B
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb0,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb1,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb2,
    input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb3,
    // SRAM read address outputs -> 1920*1080/16 (share)
    output reg [17-1:0] sram_raddr_rgb0123,
    // SRAM write address outputs -> 1920*1080/16 (share)
    output wire [17-1:0] sram_waddr_rgb0123,
    // SRAM write enable outputs (neg.)
    output wire sram_wen_rgb01,
    output wire sram_wen_rgb23,
    // SRAM word mask outputs (01: write 31~16; 10: write 15~0) (neg.)
    output wire [CH_NUM-1:0] sram_wordmask_r02,
    output wire [CH_NUM-1:0] sram_wordmask_r13,
    output wire [CH_NUM*2-1:0] sram_wordmask_gb02,
    output wire [CH_NUM*2-1:0] sram_wordmask_gb13,
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

localparam PRESEND0 = 3'd0;
localparam PRESEND1 = 3'd1;
localparam PRESEND2 = 3'd2;
localparam PROCESS  = 3'd3;
localparam DONE     = 3'd4;

// FSM
reg [2:0] state, state_n;
reg done_n;

reg [9-1:0] h_cnt, h_cnt_n;
reg [9-1:0] v_cnt, v_cnt_n;
reg stage_cnt, stage_cnt_n;

// window (64bit)
reg [(LINEAR_BW-2)*CH_NUM-1:0] win0 [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win1 [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win2 [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win3 [0:3];
reg [(LINEAR_BW-2)*1-1:0] win4 [0:3];
reg [(LINEAR_BW-2)*1-1:0] win5 [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win0_n [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win1_n [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win2_n [0:3];
reg [(LINEAR_BW-2)*CH_NUM-1:0] win3_n [0:3];
reg [(LINEAR_BW-2)*1-1:0] win4_n [0:3];
reg [(LINEAR_BW-2)*1-1:0] win5_n [0:3];


wire [(LINEAR_BW-2)-1:0] R00, R20, R02, R22;
wire [(LINEAR_BW-2)-1:0] G10, G30, G01, G21, 
                         G12, G32, G03, G23;
wire [(LINEAR_BW-2)-1:0] B11, B31, B13, B33;

wire [(LINEAR_BW-2)-1:0] G0_up, B1_up, G2_up, B3_up;
wire [(LINEAR_BW-2)-1:0] R0_down, G1_down, R2_down, G3_down;

wire [(LINEAR_BW-2)-1:0] G0_left = (h_cnt == 9'd0) ? R00 : (stage_cnt ? win5[0] : win4[0]);
wire [(LINEAR_BW-2)-1:0] B1_left = (h_cnt == 9'd0) ? G01 : (stage_cnt ? win5[1] : win4[1]);
wire [(LINEAR_BW-2)-1:0] G2_left = (h_cnt == 9'd0) ? R02 : (stage_cnt ? win5[2] : win4[2]);
wire [(LINEAR_BW-2)-1:0] B3_left = (h_cnt == 9'd0) ? G03 : (stage_cnt ? win5[3] : win4[3]);

wire [(LINEAR_BW-2)-1:0] R0_right = (h_cnt == 9'd479) ? G30 : (stage_cnt ? win1[0][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)] : win0[0][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]);
wire [(LINEAR_BW-2)-1:0] G1_right = (h_cnt == 9'd479) ? B31 : (stage_cnt ? win1[1][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)] : win0[1][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]);
wire [(LINEAR_BW-2)-1:0] R2_right = (h_cnt == 9'd479) ? G32 : (stage_cnt ? win1[2][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)] : win0[2][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]);
wire [(LINEAR_BW-2)-1:0] G3_right = (h_cnt == 9'd479) ? B33 : (stage_cnt ? win1[3][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)] : win0[3][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]);

wire [(LINEAR_BW-2)-1:0] B_left = stage_cnt ? (h_cnt == 9'd0 ? G0_up : win4[3]) : (h_cnt == 9'd0 ? R00 : G0_left);
// wire [(LINEAR_BW-2)-1:0] G4_left = stage_cnt ? (h_cnt == 9'd0 ? G03 : B3_left) : (h_cnt == 9'd0 ? R0_down : win5[0]);
// wire [(LINEAR_BW-2)-1:0] G_right = stage_cnt ? (h_cnt == 9'd479 ? B3_up : win0[3][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]) : (h_cnt == 9'd479 ? G30 : R0_right);
wire [(LINEAR_BW-2)-1:0] RG4_right = stage_cnt ? (h_cnt == 9'd479 ? B33 : G3_right) : (h_cnt == 9'd479 ? G3_down : win1_n[0][(LINEAR_BW-2)*4-1 -: (LINEAR_BW-2)]);


assign {G0_up, B1_up, G2_up, B3_up} = stage_cnt ? win2[3] : {R00, G10, R20, G30};           // stage = 0 up is don't care
assign {R0_down, G1_down, R2_down, G3_down} = stage_cnt ? {G03, B13, G23, B33} : win3[0];   // stage = 1 down is don't care

assign {R00, G10, R20, G30} = stage_cnt ? win3[0] : win2[0];
assign {G01, B11, G21, B31} = stage_cnt ? win3[1] : win2[1];
assign {R02, G12, R22, G32} = stage_cnt ? win3[2] : win2[2];
assign {G03, B13, G23, B33} = stage_cnt ? win3[3] : win2[3];

// up clock-wise
// pos R
wire [LINEAR_BW-1:0] G00_sum = G0_up + G10 + G01 + G0_left;
wire [LINEAR_BW-1:0] G20_sum = G2_up + G30 + G21 + G10;
wire [LINEAR_BW-1:0] G02_sum = G01 + G12 + G03 + G2_left;
wire [LINEAR_BW-1:0] G22_sum = G21 + G32 + G23 + G12;

wire [LINEAR_BW-1:0] B00_sum = B_left + B1_up + B11 + B1_left;
wire [LINEAR_BW-1:0] B20_sum = B1_up + B3_up + B31 + B11;
wire [LINEAR_BW-1:0] B02_sum = B1_left + B11 + B13 + B3_left;
wire [LINEAR_BW-1:0] B22_sum = B11 + B31 + B33 + B13;

// pos B
wire [LINEAR_BW-1:0] R11_sum = R00 + R20 + R22 + R02;
wire [LINEAR_BW-1:0] R31_sum = R20 + R0_right + R2_right + R22;
wire [LINEAR_BW-1:0] R13_sum = R02 + R22 + R2_down + R0_down;
wire [LINEAR_BW-1:0] R33_sum = R22 + R2_right + RG4_right + R2_down;

wire [LINEAR_BW-1:0] G11_sum = G10 + G21 + G12 + G01;
wire [LINEAR_BW-1:0] G31_sum = G30 + G1_right + G32 + G21;
wire [LINEAR_BW-1:0] G13_sum = G12 + G23 + G1_down + G03;
wire [LINEAR_BW-1:0] G33_sum = G32 + G3_right + G3_down + G23;

// pos G at R row
wire [LINEAR_BW-1-1:0] R10_sum_2 = R00 + R20;
wire [LINEAR_BW-1-1:0] R30_sum_2 = R20 + R0_right;
wire [LINEAR_BW-1-1:0] R12_sum_2 = R02 + R22;
wire [LINEAR_BW-1-1:0] R32_sum_2 = R22 + R2_right;

wire [LINEAR_BW-1-1:0] B10_sum_2 = B1_up + B11;
wire [LINEAR_BW-1-1:0] B30_sum_2 = B3_up + B31;
wire [LINEAR_BW-1-1:0] B12_sum_2 = B11 + B13;
wire [LINEAR_BW-1-1:0] B32_sum_2 = B31 + B33;

wire [LINEAR_BW-1:0] R10_sum = {R10_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R30_sum = {R30_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R12_sum = {R12_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R32_sum = {R32_sum_2, 1'b0};

wire [LINEAR_BW-1:0] B10_sum = {B10_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B30_sum = {B30_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B12_sum = {B12_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B32_sum = {B32_sum_2, 1'b0};

// pos G at B row
wire [LINEAR_BW-1-1:0] R01_sum_2 = R00 + R02;
wire [LINEAR_BW-1-1:0] R21_sum_2 = R20 + R22;
wire [LINEAR_BW-1-1:0] R03_sum_2 = R02 + R0_down;
wire [LINEAR_BW-1-1:0] R23_sum_2 = R22 + R2_down;
wire [LINEAR_BW-1-1:0] B01_sum_2 = B1_left + B11;
wire [LINEAR_BW-1-1:0] B21_sum_2 = B11 + B31;
wire [LINEAR_BW-1-1:0] B03_sum_2 = B3_left + B13;
wire [LINEAR_BW-1-1:0] B23_sum_2 = B13 + B33;

wire [LINEAR_BW-1:0] R01_sum = {R01_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R21_sum = {R21_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R03_sum = {R03_sum_2, 1'b0};
wire [LINEAR_BW-1:0] R23_sum = {R23_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B01_sum = {B01_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B21_sum = {B21_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B03_sum = {B03_sum_2, 1'b0};
wire [LINEAR_BW-1:0] B23_sum = {B23_sum_2, 1'b0};



// SRAM
// assign sram_raddr_rgb0123 = v_cnt * 9'd480 + h_cnt + (stage_cnt ? 9'd3 : 9'd482);
assign sram_waddr_rgb0123 = v_cnt * 9'd480 + h_cnt + (stage_cnt ? 9'd480 : 9'd0);
assign sram_wen_rgb01 = (~stage_cnt && (v_cnt != 9'd0)) || (state != PROCESS);
assign sram_wen_rgb23 = (stage_cnt && (v_cnt != 9'd268)) || (state != PROCESS);
assign sram_wordmask_r02 = 4'b1010;
assign sram_wordmask_r13 = 4'b0000;
assign sram_wordmask_gb02 = 8'b0010_0010;
assign sram_wordmask_gb13 = 8'b1001_1001;

assign sram_wdata_r0 = {R00, 2'b0, R10_sum, R20, 2'b0, R30_sum};
assign sram_wdata_r1 = {R01_sum, R11_sum, R21_sum, R31_sum};
assign sram_wdata_r2 = {R02, 2'b0, R12_sum, R22, 2'b0, R32_sum};
assign sram_wdata_r3 = {R03_sum, R13_sum, R23_sum, R33_sum};

assign sram_wdata_gb0 = {G00_sum, B00_sum, G10, 2'b0, B10_sum, G20_sum, B20_sum, G30, 2'b0, B30_sum};
assign sram_wdata_gb1 = {G01, 2'b0, B01_sum, G11_sum, B11, 2'b0, G21, 2'b0, B21_sum, G31_sum, B31, 2'b0};
assign sram_wdata_gb2 = {G02_sum, B02_sum, G12, 2'b0, B12_sum, G22_sum, B22_sum, G32, 2'b0, B32_sum};
assign sram_wdata_gb3 = {G03, 2'b0, B03_sum, G13_sum, B13, 2'b0, G23, 2'b0, B23_sum, G33_sum, B33, 2'b0};

integer i;
always @(posedge clk) begin
    if (~srst_n) begin
        state <= PRESEND0;
        done <= 1'b0;
        h_cnt <= 9'd0;
        v_cnt <= 9'd0;
        stage_cnt <= 1'b1;
    end else if (enable) begin
        state <= state_n;
        done <= done_n;
        h_cnt <= h_cnt_n;
        v_cnt <= v_cnt_n;
        stage_cnt <= stage_cnt_n;
    end else begin
        state <= state;
        done <= done;
        h_cnt <= h_cnt;
        v_cnt <= v_cnt;
        stage_cnt <= stage_cnt;
    end
end

always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        win0[i] <= win0_n[i];
        win1[i] <= win1_n[i];
        win2[i] <= win2_n[i];
        win3[i] <= win3_n[i];
        win4[i] <= win4_n[i];
        win5[i] <= win5_n[i];
    end
end

integer j;
always @* begin
    stage_cnt_n = ~stage_cnt;
    h_cnt_n = h_cnt;
    v_cnt_n = v_cnt;
    done_n = 0;
    case (state)
        PRESEND0: begin
            state_n = stage_cnt ? PRESEND1 : PRESEND0;
        end
        PRESEND1: begin
            state_n = stage_cnt ? PRESEND2 : PRESEND1;
        end
        PRESEND2: begin
            state_n = stage_cnt ? PROCESS : PRESEND2;
        end
        PROCESS: begin
            state_n = (stage_cnt && h_cnt == 9'd479 && v_cnt == 9'd268) ? DONE : PROCESS;
            done_n = (stage_cnt && h_cnt == 9'd479 && v_cnt == 9'd268) ? 1 : 0;
            h_cnt_n = stage_cnt ? (h_cnt == 9'd479 ? 9'd0 : h_cnt + 9'd1) : h_cnt;
            v_cnt_n = (stage_cnt && h_cnt == 9'd479) ? v_cnt + 9'd1 : v_cnt;
        end
        DONE: begin
            state_n = PRESEND0;
            done_n = 1;
        end
        default: begin
            state_n = PRESEND0;
        end
    endcase
end

// address
always @* begin
    case (state) 
        PRESEND0: begin
            sram_raddr_rgb0123 = 9'd0;
        end
        PRESEND1: begin
            sram_raddr_rgb0123 = stage_cnt ? 9'd1 : 9'd480;
        end
        PRESEND2: begin
            sram_raddr_rgb0123 = stage_cnt ? 9'd2 : 9'd481;
        end
        default: begin
            case (h_cnt)
            9'd477: begin
                if (stage_cnt)  sram_raddr_rgb0123 = (v_cnt + 9'd1) * 9'd480;
                else            sram_raddr_rgb0123 = v_cnt * 9'd480 + h_cnt + (stage_cnt ? 9'd3 : 9'd482);
            end

            9'd478: begin
                if (stage_cnt)  sram_raddr_rgb0123 = (v_cnt + 9'd1) * 9'd480 + 9'd1;
                else            sram_raddr_rgb0123 = (v_cnt + 9'd1) * 9'd480 + 9'd480;
            end

            9'd479: begin
                if (stage_cnt)  sram_raddr_rgb0123 = (v_cnt + 9'd1) * 9'd480 + 9'd2;
                else            sram_raddr_rgb0123 = (v_cnt + 9'd1) * 9'd480 + 9'd1 + 9'd480;
            end
            default: begin
                sram_raddr_rgb0123 = v_cnt * 9'd480 + h_cnt + (stage_cnt ? 9'd3 : 9'd482);
            end
            endcase
        end
    endcase
end


// window
always @* begin
    if (stage_cnt) begin    // 1'b1
        win0_n[0] = {sram_rdata_r0[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb0[LINEAR_BW*6-1 -: LINEAR_BW-2], 
                     sram_rdata_r0[LINEAR_BW*2-1 -: LINEAR_BW-2], 
                     sram_rdata_gb0[LINEAR_BW*2-1 -: LINEAR_BW-2]};
        win0_n[1] = {sram_rdata_gb1[LINEAR_BW*8-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*5-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*1-1 -: LINEAR_BW-2]};
        win0_n[2] = {sram_rdata_r2[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb2[LINEAR_BW*6-1 -: LINEAR_BW-2], 
                     sram_rdata_r2[LINEAR_BW*2-1 -: LINEAR_BW-2], 
                     sram_rdata_gb2[LINEAR_BW*2-1 -: LINEAR_BW-2]};
        win0_n[3] = {sram_rdata_gb3[LINEAR_BW*8-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*5-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*1-1 -: LINEAR_BW-2]};

        for (j = 0; j < 4; j = j + 1) begin
            win1_n[j] = win1[j];
            win2_n[j] = win0[j];
            win3_n[j] = win1[j];
            win4_n[j] = win2[j][(LINEAR_BW-2)-1 -: LINEAR_BW-2];
            win5_n[j] = win3[j][(LINEAR_BW-2)-1 -: LINEAR_BW-2];
        end
    end else begin          // 1'b0
        win1_n[0] = {sram_rdata_r0[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb0[LINEAR_BW*6-1 -: LINEAR_BW-2], 
                     sram_rdata_r0[LINEAR_BW*2-1 -: LINEAR_BW-2], 
                     sram_rdata_gb0[LINEAR_BW*2-1 -: LINEAR_BW-2]};
        win1_n[1] = {sram_rdata_gb1[LINEAR_BW*8-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*5-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb1[LINEAR_BW*1-1 -: LINEAR_BW-2]};
        win1_n[2] = {sram_rdata_r2[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb2[LINEAR_BW*6-1 -: LINEAR_BW-2], 
                     sram_rdata_r2[LINEAR_BW*2-1 -: LINEAR_BW-2], 
                     sram_rdata_gb2[LINEAR_BW*2-1 -: LINEAR_BW-2]};
        win1_n[3] = {sram_rdata_gb3[LINEAR_BW*8-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*5-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*4-1 -: LINEAR_BW-2], 
                     sram_rdata_gb3[LINEAR_BW*1-1 -: LINEAR_BW-2]};
        for (j = 0; j < 4; j = j + 1) begin
            win0_n[j] = win0[j];
            win2_n[j] = win2[j];
            win3_n[j] = win3[j];
            win4_n[j] = win4[j];
            win5_n[j] = win5[j];
        end
    end
end


endmodule