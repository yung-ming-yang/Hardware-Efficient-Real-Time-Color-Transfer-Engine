module color_mapping #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output wire done,

    input wire [19-1:0] mu_Cb_src, mu_Cr_src,
    input wire [19-1:0] mu_Cb_ref, mu_Cr_ref,
    input wire [27-1:0] sqr_sigma_Cb_src, sqr_sigma_Cr_src,
    input wire [27-1:0] sqr_sigma_Cb_ref, sqr_sigma_Cr_ref,

    // input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb0,
    // input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb1,
    // input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb2,
    // input wire [LINEAR_BW*2*CH_NUM-1:0] sram_rdata_gb3,

    output reg [17-1:0] sram_raddr_gb0,
    output reg [17-1:0] sram_raddr_gb1,
    output reg [17-1:0] sram_raddr_gb2,
    output reg [17-1:0] sram_raddr_gb3,

    output reg [17-1:0]sram_waddr_gb0,
    output reg [17-1:0]sram_waddr_gb1,
    output reg [17-1:0]sram_waddr_gb2,
    output reg [17-1:0]sram_waddr_gb3,

    output reg [CH_NUM*2-1:0] sram_wordmask_gb0,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb1,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb2,
    output reg [CH_NUM*2-1:0] sram_wordmask_gb3,

    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb0,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb1,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb2,
    output reg [LINEAR_BW*2*CH_NUM-1:0] sram_wdata_gb3,

    output reg sram_wen_gb0,
    output reg sram_wen_gb1,
    output reg sram_wen_gb2,
    output reg sram_wen_gb3,

    input [29-1:0] mul_out_cb_0,
    input [29-1:0] mul_out_cb_1,
    input [29-1:0] mul_out_cb_2,
    input [29-1:0] mul_out_cb_3,
    input [29-1:0] mul_out_cb_4,
    input [29-1:0] mul_out_cb_5,
    input [29-1:0] mul_out_cb_6,
    input [29-1:0] mul_out_cb_7,
    input [29-1:0] mul_out_cb_8,
    input [29-1:0] mul_out_cb_9,
    input [29-1:0] mul_out_cb_10,
    input [29-1:0] mul_out_cb_11,
    input [29-1:0] mul_out_cb_12,
    input [29-1:0] mul_out_cb_13,
    input [29-1:0] mul_out_cb_14,
    input [29-1:0] mul_out_cb_15,
    input [29-1:0] mul_out_cr_0,
    input [29-1:0] mul_out_cr_1,
    input [29-1:0] mul_out_cr_2,
    input [29-1:0] mul_out_cr_3,
    input [29-1:0] mul_out_cr_4,
    input [29-1:0] mul_out_cr_5,
    input [29-1:0] mul_out_cr_6,
    input [29-1:0] mul_out_cr_7,
    input [29-1:0] mul_out_cr_8,
    input [29-1:0] mul_out_cr_9,
    input [29-1:0] mul_out_cr_10,
    input [29-1:0] mul_out_cr_11,
    input [29-1:0] mul_out_cr_12,
    input [29-1:0] mul_out_cr_13,
    input [29-1:0] mul_out_cr_14,
    input [29-1:0] mul_out_cr_15,
    output reg [13-1:0] sqrt_sigma_Cb, sqrt_sigma_Cr
);

//---------------------------
// Variable Definitions
//---------------------------

// FSM 
parameter IDLE =            7'b000_0001,
          DIV_SIGMA =       7'b000_0010,    
          SQRT_SIGMA =      7'b000_0100,
          OFFSET =          7'b000_1000,
          MAPPING_PRE =     7'b001_0000,  // preload
          MAPPING =         7'b010_0000,
          FINISH =          7'b100_0000;

reg [7-1:0] state, state_nx;
reg cnt1, cnt1_nx;
reg [17-1:0] cnt131071, cnt131071_nx;
wire [17-1:0] cnt131071_add2 = cnt131071 + 2;
wire [17-1:0] cnt131071_sub1 = cnt131071 - 1;

// Input Data Reorganization
// wire [LINEAR_BW-1:0] Cb [0:16-1];
// wire [LINEAR_BW-1:0] Cr [0:16-1];

// signal
wire div_sigma_done;

// local reg for offset
wire [12-1:0] lut_in;
wire [13-1:0] lut_out;
reg [12-1:0] div_sigma_Cb, div_sigma_Cr;
wire [12-1:0] div_out_Cb, div_out_Cr;
wire [12-1:0] div_sigma_Cb_nx, div_sigma_Cr_nx;
wire [13-1:0] sqrt_sigma_Cb_nx, sqrt_sigma_Cr_nx;
reg [32-1:0] offset_Cb_tem, offset_Cr_tem;
wire [32-1:0] offset_Cb_tem_nx, offset_Cr_tem_nx;
reg [32-1:0] offset_Cb, offset_Cr;
wire [32-1:0] offset_Cb_nx, offset_Cr_nx;

// reg for mapping stage 1 to 2
reg [29-1:0] Cb_scaled [0:16-1];
reg [29-1:0] Cb_scaled_nx [0:16-1];
reg [29-1:0] Cr_scaled [0:16-1];
reg [29-1:0] Cr_scaled_nx [0:16-1];

// reg for mapping result
reg [32-1:0] Cb_mapped[0:16-1];
reg [32-1:0] Cr_mapped[0:16-1];
reg [16-1:0] Cb_out[0:16-1];
reg [16-1:0] Cr_out[0:16-1];


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
            if (enable) state_nx = DIV_SIGMA;
        end

        DIV_SIGMA: begin
            if (div_sigma_done) state_nx = SQRT_SIGMA;
        end

        SQRT_SIGMA: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = OFFSET;
        end 

        OFFSET: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = MAPPING_PRE; 
        end

        MAPPING_PRE: begin
            cnt1_nx = cnt1 + 1;
            if (cnt1) state_nx = MAPPING;
        end

        MAPPING: begin
            cnt131071_nx = cnt131071 + 1;
            if (cnt131071 == 17'd129599 + 17'd1) state_nx = FINISH;
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
// assign {Cb[0], Cr[0], Cb[1], Cr[1], Cb[2], Cr[2], Cb[3], Cr[3]}         = sram_rdata_gb0;
// assign {Cb[4], Cr[4], Cb[5], Cr[5], Cb[6], Cr[6], Cb[7], Cr[7]}         = sram_rdata_gb1;
// assign {Cb[8], Cr[8], Cb[9], Cr[9], Cb[10], Cr[10], Cb[11], Cr[11]}     = sram_rdata_gb2;
// assign {Cb[12], Cr[12], Cb[13], Cr[13], Cb[14], Cr[14], Cb[15], Cr[15]} = sram_rdata_gb3;

// Output
always @*begin
    sram_raddr_gb0 = 0;
    sram_raddr_gb1 = 0;
    sram_raddr_gb2 = 0;
    sram_raddr_gb3 = 0;

    sram_waddr_gb0 = 1'b0;
    sram_waddr_gb1 = 1'b0;
    sram_waddr_gb2 = 1'b0;
    sram_waddr_gb3 = 1'b0;
    sram_wen_gb0 = 1'b1;
    sram_wen_gb1 = 1'b1;
    sram_wen_gb2 = 1'b1;
    sram_wen_gb3 = 1'b1;
    sram_wordmask_gb0 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb1 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb2 = {CH_NUM*2{1'b1}};
    sram_wordmask_gb3 = {CH_NUM*2{1'b1}};
    sram_wdata_gb0 = {LINEAR_BW*2*CH_NUM{1'b0}};
    sram_wdata_gb1 = {LINEAR_BW*2*CH_NUM{1'b0}};             
    sram_wdata_gb2 = {LINEAR_BW*2*CH_NUM{1'b0}};             
    sram_wdata_gb3 = {LINEAR_BW*2*CH_NUM{1'b0}};

    case (state)   
        MAPPING_PRE: begin
            sram_raddr_gb0 = cnt1;
            sram_raddr_gb1 = cnt1;
            sram_raddr_gb2 = cnt1;
            sram_raddr_gb3 = cnt1;
        end
        MAPPING: begin
            sram_raddr_gb0 = cnt131071_add2;
            sram_raddr_gb1 = cnt131071_add2;
            sram_raddr_gb2 = cnt131071_add2;
            sram_raddr_gb3 = cnt131071_add2;

            sram_waddr_gb0 = (cnt131071 != 1'b0) ? cnt131071_sub1 : 17'b0;
            sram_waddr_gb1 = (cnt131071 != 1'b0) ? cnt131071_sub1 : 17'b0;
            sram_waddr_gb2 = (cnt131071 != 1'b0) ? cnt131071_sub1 : 17'b0;
            sram_waddr_gb3 = (cnt131071 != 1'b0) ? cnt131071_sub1 : 17'b0;

            sram_wen_gb0 = (cnt131071 != 1'b0) ? 1'b0 : 1'b1;
            sram_wen_gb1 = (cnt131071 != 1'b0) ? 1'b0 : 1'b1;
            sram_wen_gb2 = (cnt131071 != 1'b0) ? 1'b0 : 1'b1;
            sram_wen_gb3 = (cnt131071 != 1'b0) ? 1'b0 : 1'b1;

            sram_wordmask_gb0 = (cnt131071 != 1'b0) ? {CH_NUM*2{1'b0}} : {CH_NUM*2{1'b1}};
            sram_wordmask_gb1 = (cnt131071 != 1'b0) ? {CH_NUM*2{1'b0}} : {CH_NUM*2{1'b1}};
            sram_wordmask_gb2 = (cnt131071 != 1'b0) ? {CH_NUM*2{1'b0}} : {CH_NUM*2{1'b1}};
            sram_wordmask_gb3 = (cnt131071 != 1'b0) ? {CH_NUM*2{1'b0}} : {CH_NUM*2{1'b1}};

            sram_wdata_gb0 = (cnt131071 != 1'b0) ? {Cb_out[0], Cr_out[0], Cb_out[1], Cr_out[1]
                                                , Cb_out[2], Cr_out[2], Cb_out[3], Cr_out[3]} : {LINEAR_BW*2*CH_NUM{1'b0}};
            sram_wdata_gb1 = (cnt131071 != 1'b0) ? {Cb_out[4], Cr_out[4], Cb_out[5], Cr_out[5]
                                                , Cb_out[6], Cr_out[6], Cb_out[7], Cr_out[7]} : {LINEAR_BW*2*CH_NUM{1'b0}};
            sram_wdata_gb2 = (cnt131071 != 1'b0) ? {Cb_out[8], Cr_out[8], Cb_out[9], Cr_out[9]
                                                , Cb_out[10], Cr_out[10], Cb_out[11], Cr_out[11]} : {LINEAR_BW*2*CH_NUM{1'b0}};
            sram_wdata_gb3 = (cnt131071 != 1'b0) ? {Cb_out[12], Cr_out[12], Cb_out[13], Cr_out[13]
                                                , Cb_out[14], Cr_out[14], Cb_out[15], Cr_out[15]} : {LINEAR_BW*2*CH_NUM{1'b0}};
        end
    endcase
end

//---------------------------
// Data Path
//---------------------------

// sigma division
divider_uu #(
    .DIVIDEND_B(33),
    .DIVIDER_B(27),
    .QUOTIENT_B(12)
) divider_uu_Cb (
    .clk(clk),
    .en(state[1]),
    .dividend({sqr_sigma_Cb_ref, 6'b0}),
    .divider(sqr_sigma_Cb_src),
    .quotient(div_out_Cb),
    .done(div_sigma_done)
);

divider_uu #(
    .DIVIDEND_B(33),
    .DIVIDER_B(27),
    .QUOTIENT_B(12)
) divider_uu_Cr (
    .clk(clk),
    .en(state[1]),
    .dividend({sqr_sigma_Cr_ref, 6'b0}),
    .divider(sqr_sigma_Cr_src),
    .quotient(div_out_Cr),
    .done()
);

assign div_sigma_Cb_nx = (state[1]) ? div_out_Cb : div_sigma_Cb;
assign div_sigma_Cr_nx = (state[1]) ? div_out_Cr : div_sigma_Cr;

// sigma square root
assign lut_in = (state[2] && ~cnt1) ? div_sigma_Cb : div_sigma_Cr;

sqrt_lut sqrt_lut (
    .lut_in(lut_in),
    .lut_out(lut_out)
);

assign sqrt_sigma_Cb_nx = (state[2] && ~cnt1) ? lut_out : sqrt_sigma_Cb;
assign sqrt_sigma_Cr_nx = (state[2] && cnt1) ? lut_out : sqrt_sigma_Cr;

// offset calculation
assign offset_Cb_tem_nx = (state[3] && ~cnt1) ? mu_Cb_src * sqrt_sigma_Cb : 0;
assign offset_Cr_tem_nx = (state[3] && ~cnt1) ? mu_Cr_src * sqrt_sigma_Cr : 0;

assign offset_Cb_nx = (state[3] && cnt1) ? offset_Cb_tem - {3'b0, mu_Cb_ref, 10'b0} : offset_Cb;
assign offset_Cr_nx = (state[3] && cnt1) ? offset_Cr_tem - {3'b0, mu_Cr_ref, 10'b0} : offset_Cr;

// Mapping pipeline
always @* begin
    Cb_scaled_nx[0]  = (state[5]) ? mul_out_cb_0  : 0;
    Cb_scaled_nx[1]  = (state[5]) ? mul_out_cb_1  : 0;
    Cb_scaled_nx[2]  = (state[5]) ? mul_out_cb_2  : 0;
    Cb_scaled_nx[3]  = (state[5]) ? mul_out_cb_3  : 0;
    Cb_scaled_nx[4]  = (state[5]) ? mul_out_cb_4  : 0;
    Cb_scaled_nx[5]  = (state[5]) ? mul_out_cb_5  : 0;
    Cb_scaled_nx[6]  = (state[5]) ? mul_out_cb_6  : 0;
    Cb_scaled_nx[7]  = (state[5]) ? mul_out_cb_7  : 0;
    Cb_scaled_nx[8]  = (state[5]) ? mul_out_cb_8  : 0;
    Cb_scaled_nx[9]  = (state[5]) ? mul_out_cb_9  : 0;
    Cb_scaled_nx[10] = (state[5]) ? mul_out_cb_10 : 0;
    Cb_scaled_nx[11] = (state[5]) ? mul_out_cb_11 : 0;
    Cb_scaled_nx[12] = (state[5]) ? mul_out_cb_12 : 0;
    Cb_scaled_nx[13] = (state[5]) ? mul_out_cb_13 : 0;
    Cb_scaled_nx[14] = (state[5]) ? mul_out_cb_14 : 0;
    Cb_scaled_nx[15] = (state[5]) ? mul_out_cb_15 : 0;

    Cr_scaled_nx[0]  = (state[5]) ? mul_out_cr_0  : 0;
    Cr_scaled_nx[1]  = (state[5]) ? mul_out_cr_1  : 0;
    Cr_scaled_nx[2]  = (state[5]) ? mul_out_cr_2  : 0;
    Cr_scaled_nx[3]  = (state[5]) ? mul_out_cr_3  : 0;
    Cr_scaled_nx[4]  = (state[5]) ? mul_out_cr_4  : 0;
    Cr_scaled_nx[5]  = (state[5]) ? mul_out_cr_5  : 0;
    Cr_scaled_nx[6]  = (state[5]) ? mul_out_cr_6  : 0;
    Cr_scaled_nx[7]  = (state[5]) ? mul_out_cr_7  : 0;
    Cr_scaled_nx[8]  = (state[5]) ? mul_out_cr_8  : 0;
    Cr_scaled_nx[9]  = (state[5]) ? mul_out_cr_9  : 0;
    Cr_scaled_nx[10] = (state[5]) ? mul_out_cr_10 : 0;
    Cr_scaled_nx[11] = (state[5]) ? mul_out_cr_11 : 0;
    Cr_scaled_nx[12] = (state[5]) ? mul_out_cr_12 : 0;
    Cr_scaled_nx[13] = (state[5]) ? mul_out_cr_13 : 0;
    Cr_scaled_nx[14] = (state[5]) ? mul_out_cr_14 : 0;
    Cr_scaled_nx[15] = (state[5]) ? mul_out_cr_15 : 0;
end

always @* begin
    for (i = 0; i < 16; i = i + 1) begin
        Cb_mapped[i] = (state[5] && cnt131071 != 0) ? {1'b0, Cb_scaled[i], 2'b0} - offset_Cb : 0;
        Cr_mapped[i] = (state[5] && cnt131071 != 0) ? {1'b0, Cr_scaled[i], 2'b0} - offset_Cr : 0;

        Cb_out[i] = (&Cb_mapped[i][31:28]) ? 16'd0 : ((Cb_mapped[i][28:12] > 65280) ? 16'd65280 : Cb_mapped[i][27:12]);
        Cr_out[i] = (&Cr_mapped[i][31:28]) ? 16'd0 : ((Cr_mapped[i][28:12] > 65280) ? 16'd65280 : Cr_mapped[i][27:12]);
    end
end

//---------------------------
// Sequential Logic
//---------------------------

// sigma division
always @(posedge clk) begin
    div_sigma_Cb <= div_sigma_Cb_nx;
    div_sigma_Cr <= div_sigma_Cr_nx;
end

// sigma square root
always @(posedge clk) begin
    sqrt_sigma_Cb <= sqrt_sigma_Cb_nx;
    sqrt_sigma_Cr <= sqrt_sigma_Cr_nx;
end

// offset calculation
always @(posedge clk) begin
    offset_Cb_tem <= offset_Cb_tem_nx;
    offset_Cr_tem <= offset_Cr_tem_nx;
    offset_Cb <= offset_Cb_nx;
    offset_Cr <= offset_Cr_nx;
end

// mapping pipeline
always @(posedge clk) begin
    for (i = 0; i < 16; i = i + 1) begin
        Cb_scaled[i] <= Cb_scaled_nx[i];
        Cr_scaled[i] <= Cr_scaled_nx[i];
    end
end

endmodule