module light_match #(
    parameter CH_NUM = 4,
    parameter LINEAR_BW = 16,
    parameter RGB_BW = 8,
    parameter HEIGHT = 1080,
    parameter WIDTH = 1920,
    parameter BIN_NUM_BW = 8,
    parameter BIN_BW = 13
) (
    // Control signals
    input wire clk,
    input wire srst_n,
    input wire enable,
    output reg done,
    // SRAM
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r0,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r1,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r2,
    input wire [LINEAR_BW*CH_NUM-1:0] sram_rdata_r3,
    input wire [RGB_BW*CH_NUM-1:0] sram_rdata_fy0,

    output reg [17-1:0] sram_raddr_r0123,
    output reg [17-1:0] sram_raddr_fy0123,
    output wire [17-1:0] sram_waddr_r0123,

    output wire sram_wen_r0123,
    output wire [CH_NUM-1:0] sram_wordmask_r0123,

    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r0,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r1,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r2,
    output wire [LINEAR_BW*CH_NUM-1:0] sram_wdata_r3,

    // histogram
    // src  // ref
    input wire src_cdf_done,
    input wire [BIN_BW-1:0] src_white_point,
    input wire src_light_get,
    
    input wire ref_cdf_done,
    input wire [BIN_BW-1:0] ref_white_point,
    input wire ref_light_get,

    output wire start,
    output reg cdf_begin,
    output wire src_match_done,
    output reg [BIN_NUM_BW-1:0] src_hist_in,

    // output wire ref_start,
    // output reg ref_cdf_begin,
    output wire ref_match_done,
    output reg [BIN_BW-1:0] ref_hist_in
);


localparam STEP = 20;
localparam WIDTH_END = WIDTH / STEP;
localparam ROW_END = HEIGHT / STEP;
localparam BIN_NUM = 256;
// localparam BIN_BW = 13;                 // 1920*1080/400
// localparam BIN_NUM_BW = 8;              // 256

// FSM
localparam IDLE        = 3'd0;
localparam CAL_HIST    = 3'd1;
localparam WAIT_CDF    = 3'd2;
localparam LUT_SEND    = 3'd3;
localparam LUT_RECEIVE = 3'd4;
localparam LUT_WAIT    = 3'd5;
localparam LOOKUP      = 3'd6;
localparam DONE        = 3'd7;

reg [2:0] state, state_n;
wire done_n;
wire lut_done;

reg [BIN_NUM_BW-1:0] light_lut [0:BIN_NUM-1];
reg [BIN_NUM_BW-1:0] light_lut_n [0:BIN_NUM-1];

wire cdf_begin_n;

reg [9-1:0] h_cnt, h_cnt_n;     // 480
reg [9-1:0] v_cnt, v_cnt_n;     // 270


wire [RGB_BW-1:0] Y00_src, Y10_src, Y20_src, Y30_src,
                  Y01_src, Y11_src, Y21_src, Y31_src,
                  Y02_src, Y12_src, Y22_src, Y32_src,
                  Y03_src, Y13_src, Y23_src, Y33_src;

wire [RGB_BW-1:0] Y00_ref;

wire [RGB_BW-1:0] Y00_match, Y10_match, Y20_match, Y30_match,
                  Y01_match, Y11_match, Y21_match, Y31_match,
                  Y02_match, Y12_match, Y22_match, Y32_match,
                  Y03_match, Y13_match, Y23_match, Y33_match;

assign done_n = state == DONE;

assign start = state == CAL_HIST;
assign src_match_done = state == LOOKUP;
assign ref_match_done = state == LOOKUP;


assign cdf_begin_n = (h_cnt == WIDTH / 4 - 5 && v_cnt == HEIGHT / 4 - 5);
assign lut_done = ref_light_get && h_cnt == 255;

assign {Y00_src, Y10_src, Y20_src, Y30_src} = {sram_rdata_r0[LINEAR_BW*3 +: RGB_BW], sram_rdata_r0[LINEAR_BW*2 +: RGB_BW], sram_rdata_r0[LINEAR_BW*1 +: RGB_BW], sram_rdata_r0[LINEAR_BW*0 +: RGB_BW]};
assign {Y01_src, Y11_src, Y21_src, Y31_src} = {sram_rdata_r1[LINEAR_BW*3 +: RGB_BW], sram_rdata_r1[LINEAR_BW*2 +: RGB_BW], sram_rdata_r1[LINEAR_BW*1 +: RGB_BW], sram_rdata_r1[LINEAR_BW*0 +: RGB_BW]};
assign {Y02_src, Y12_src, Y22_src, Y32_src} = {sram_rdata_r2[LINEAR_BW*3 +: RGB_BW], sram_rdata_r2[LINEAR_BW*2 +: RGB_BW], sram_rdata_r2[LINEAR_BW*1 +: RGB_BW], sram_rdata_r2[LINEAR_BW*0 +: RGB_BW]};
assign {Y03_src, Y13_src, Y23_src, Y33_src} = {sram_rdata_r3[LINEAR_BW*3 +: RGB_BW], sram_rdata_r3[LINEAR_BW*2 +: RGB_BW], sram_rdata_r3[LINEAR_BW*1 +: RGB_BW], sram_rdata_r3[LINEAR_BW*0 +: RGB_BW]};

assign Y00_ref = sram_rdata_fy0[RGB_BW*3 +: RGB_BW];


assign Y00_match = light_lut[Y00_src];
assign Y10_match = light_lut[Y10_src];
assign Y20_match = light_lut[Y20_src];
assign Y30_match = light_lut[Y30_src];

assign Y01_match = light_lut[Y01_src];
assign Y11_match = light_lut[Y11_src];
assign Y21_match = light_lut[Y21_src];
assign Y31_match = light_lut[Y31_src];

assign Y02_match = light_lut[Y02_src];
assign Y12_match = light_lut[Y12_src];
assign Y22_match = light_lut[Y22_src];
assign Y32_match = light_lut[Y32_src];

assign Y03_match = light_lut[Y03_src];
assign Y13_match = light_lut[Y13_src];
assign Y23_match = light_lut[Y23_src];
assign Y33_match = light_lut[Y33_src];

// SRAM
assign sram_waddr_r0123 = sram_raddr_r0123 - 2;
assign sram_wen_r0123 = state != LOOKUP;
assign sram_wordmask_r0123 = 4'h0;

assign sram_wdata_r0 = {8'b0, Y00_match, 8'b0, Y10_match, 8'b0, Y20_match, 8'b0, Y30_match};
assign sram_wdata_r1 = {8'b0, Y01_match, 8'b0, Y11_match, 8'b0, Y21_match, 8'b0, Y31_match};
assign sram_wdata_r2 = {8'b0, Y02_match, 8'b0, Y12_match, 8'b0, Y22_match, 8'b0, Y32_match};
assign sram_wdata_r3 = {8'b0, Y03_match, 8'b0, Y13_match, 8'b0, Y23_match, 8'b0, Y33_match};


always @(posedge clk) begin
    if (~srst_n) begin
        state  <= IDLE;
        done   <= 0;
        h_cnt  <= 0;
        v_cnt  <= 0;
        cdf_begin <= 0;
    end else begin
        state  <= state_n;
        done   <= done_n;
        h_cnt  <= h_cnt_n;
        v_cnt  <= v_cnt_n;
        cdf_begin <= cdf_begin_n;
    end
end

integer i;
always @(posedge clk) begin
    for (i = 0; i < BIN_NUM; i = i + 1)
        light_lut[i] <= light_lut_n[i];
end

// FSM
always @* begin
    case (state)
    IDLE: 
        if (enable)                         state_n = CAL_HIST;
        else                                state_n = IDLE;
    CAL_HIST:               
        if (cdf_begin_n)                    state_n = WAIT_CDF;
        else                                state_n = CAL_HIST;
    WAIT_CDF:   
        if (src_cdf_done && ref_cdf_done)   state_n = LUT_SEND;
        else                                state_n = WAIT_CDF;
    LUT_SEND:                                                           
        if (src_light_get)                  state_n = LUT_RECEIVE;
        else                                state_n = LUT_SEND;
    LUT_RECEIVE:                
                                            state_n = LUT_WAIT;
    LUT_WAIT:           
        if (lut_done)                       state_n = LOOKUP;
        else if (ref_light_get)             state_n = LUT_SEND;
        else                                state_n = LUT_WAIT;
    LOOKUP: 
        if (sram_waddr_r0123 == 129600-1)   state_n = DONE;
        else                                state_n = LOOKUP;
    DONE:
        state_n = IDLE;
    endcase
end


// h_cnt, v_cnt
always @* begin
    h_cnt_n = 0;
    v_cnt_n = 0;    
    if (state == CAL_HIST) begin
        if (h_cnt == WIDTH / 4 - 5) begin
            h_cnt_n = 0;
            if (v_cnt == HEIGHT / 4 - 5)
                v_cnt_n = 0;
            else
                v_cnt_n = v_cnt + 5;
        end else begin
            h_cnt_n = h_cnt + 5;
            v_cnt_n = v_cnt;
        end
    end else if (state == LUT_SEND || state == LUT_RECEIVE) begin
        h_cnt_n = h_cnt;
    end else if (state == LUT_WAIT) begin
        if (ref_light_get)
            h_cnt_n = (h_cnt == 255) ? 0 : h_cnt + 1;
        else
            h_cnt_n = h_cnt;
    end else if (state == LOOKUP) begin
        {v_cnt_n, h_cnt_n} = {v_cnt, h_cnt} + 1;
    end else begin
        h_cnt_n = 0;
        v_cnt_n = 0;
    end
end
// addr
always @* begin
    if (state == CAL_HIST) begin
        sram_raddr_r0123 = v_cnt_n * 480 + h_cnt_n;
        sram_raddr_fy0123 = v_cnt_n * 480 + h_cnt_n;
    end else if (state == LOOKUP) begin
        sram_raddr_r0123 = {v_cnt, h_cnt};
        sram_raddr_fy0123 = 0;
    end else begin
        sram_raddr_r0123 = 0;
        sram_raddr_fy0123 = 0;
    end
end

// histogram
always @* begin
    if (state == CAL_HIST || state == WAIT_CDF) begin
        src_hist_in = Y00_src;
        ref_hist_in = Y00_ref;
    end else if (state == LUT_SEND) begin
        src_hist_in = h_cnt;
        ref_hist_in = 0;
    end else if (state == LUT_RECEIVE) begin
        src_hist_in = h_cnt;
        ref_hist_in = src_white_point;
    end else if (state == LUT_WAIT) begin
        src_hist_in = h_cnt;
        ref_hist_in = src_white_point;
    end else begin
        src_hist_in = 0;
        ref_hist_in = 0;
    end
end


// lut
always @* begin
    for (i = 0; i < BIN_NUM; i = i + 1)
        light_lut_n[i] = light_lut[i];

    if (state == LUT_WAIT && ref_light_get)
        light_lut_n[h_cnt] = ref_white_point[BIN_NUM_BW-1:0];
end




endmodule