module histogram # (
    parameter LINEAR_BW = 16,
    parameter HIST_BATCH = 16,
    parameter BIN_NUM_BW = 8,
    parameter BIN_BW = 13,
    parameter BIN_NUM = 256
) (
    input clk,
    input srst_n,
    input start,
    input cdf_begin,
    input match_done,
    input [1:0] mode,     // 00: white point, 01: read (src) , 10: search light match (ref)
    input [LINEAR_BW-1:0] hist_in,

    output wire cdf_done,
    output reg [BIN_BW-1:0] white_point,
    output reg wp_get,
    output reg light_get
);

    localparam  HIST    = 2'd0,
                CDF     = 2'd1,
                MATCH   = 2'd2,
                IDLE    = 2'd3;
    
    localparam  WHITE_PERCENT = 4976;

    integer i;

    reg [BIN_BW-1:0] hist [0:BIN_NUM-1];
    reg light_get_next;

    reg [1:0] state, state_nx;
    reg [BIN_BW-1:0] white_point_next;

    reg [BIN_NUM_BW-1:0] hist_cnt, hist_cnt_next;

    assign cdf_done = hist_cnt == BIN_NUM - 1;

    always @* begin
        if (state == CDF)
            hist_cnt_next = cdf_done ? 1 : hist_cnt + 1;
        else if (state == MATCH)
            hist_cnt_next = light_get_next ? hist_cnt : hist_cnt + 1;
        else
            hist_cnt_next = 1;
    end

    always @* begin
        wp_get = 0;
        light_get_next = 0;
        white_point_next = white_point;        
        if (state == CDF && mode == 2'b00) begin
            if (hist[hist_cnt-1] >= WHITE_PERCENT) begin
                wp_get = 1;
                white_point_next = hist_cnt - 1;
            end
            else begin
                wp_get = 0;
                white_point_next = white_point;
            end

        end else if (state == MATCH && mode == 2'b01) begin        // read src
            white_point_next = hist[hist_in[BIN_BW-1:0]];
            light_get_next = 1;

        end else if (state == MATCH && mode == 2'b10) begin        // search ref
            if (hist[hist_cnt-1] >= hist_in[BIN_BW-1:0] || hist_cnt-1 == 8'd254) begin
                light_get_next = 1;
                white_point_next = hist_cnt - 1;
            end
            else begin
                light_get_next = 0;
                white_point_next = white_point;
            end
        end else begin
            wp_get = 0;
            white_point_next = white_point;
        end
    end

    always @* begin
        case (state) // synopsys parallel_case full_case
            IDLE:
                if (start)                  state_nx = HIST;
                else                        state_nx = IDLE;
            HIST:
                if (cdf_begin)              state_nx = CDF;
                else                        state_nx = HIST;
            CDF:
                if (wp_get)                 state_nx = IDLE;
                else if (cdf_done)          state_nx = MATCH;
                else                        state_nx = CDF;
            MATCH:
                if (match_done)             state_nx = IDLE;
                else                        state_nx = MATCH;
        endcase
    end

    always @(posedge clk) begin
        case (state) // synopsys parallel_case full_case
            HIST: begin
                if (mode == 2'b00)
                    hist[hist_in[LINEAR_BW-1 -: BIN_NUM_BW]] <= hist[hist_in[LINEAR_BW-1 -: BIN_NUM_BW]] + 1;
                else
                    hist[hist_in[0 +: BIN_NUM_BW]] <= hist[hist_in[0 +: BIN_NUM_BW]] + 1;
            end
            CDF:
                hist[hist_cnt] <= hist[hist_cnt] + hist[hist_cnt - 1];
            IDLE:
                for (i = 0; i < BIN_NUM; i = i + 1)
                    hist[i] <= 0;
            MATCH:
                for (i = 0; i < BIN_NUM; i = i + 1)
                    hist[i] <= hist[i];
        endcase

        hist_cnt    <= hist_cnt_next;
    end

    always @(posedge clk) begin
        if (~srst_n) begin
            state       <= IDLE;
            white_point <= 0;
            light_get   <= 0;
        end
        else begin
            state       <= state_nx;
            white_point <= white_point_next;
            light_get   <= light_get_next;
        end
    end

endmodule