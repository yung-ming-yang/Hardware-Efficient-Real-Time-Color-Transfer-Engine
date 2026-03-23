module mul # (
    parameter IN_BW_1 = 16,
    parameter IN_BW_2 = 16,
    parameter OUT_BW = IN_BW_1 + IN_BW_2
) (
    input [IN_BW_1-1:0] in_1_0,
    input [IN_BW_1-1:0] in_1_1,
    input [IN_BW_1-1:0] in_1_2,
    input [IN_BW_1-1:0] in_1_3,
    input [IN_BW_1-1:0] in_1_4,
    input [IN_BW_1-1:0] in_1_5,
    input [IN_BW_1-1:0] in_1_6,
    input [IN_BW_1-1:0] in_1_7,
    input [IN_BW_1-1:0] in_1_8,
    input [IN_BW_1-1:0] in_1_9,
    input [IN_BW_1-1:0] in_1_10,
    input [IN_BW_1-1:0] in_1_11,
    input [IN_BW_1-1:0] in_1_12,
    input [IN_BW_1-1:0] in_1_13,
    input [IN_BW_1-1:0] in_1_14,
    input [IN_BW_1-1:0] in_1_15,
    input [IN_BW_1-1:0] in_1_16,
    input [IN_BW_1-1:0] in_1_17,
    input [IN_BW_1-1:0] in_1_18,
    input [IN_BW_1-1:0] in_1_19,
    input [IN_BW_1-1:0] in_1_20,
    input [IN_BW_1-1:0] in_1_21,
    input [IN_BW_1-1:0] in_1_22,
    input [IN_BW_1-1:0] in_1_23,
    input [IN_BW_1-1:0] in_1_24,
    input [IN_BW_1-1:0] in_1_25,
    input [IN_BW_1-1:0] in_1_26,
    input [IN_BW_1-1:0] in_1_27,
    input [IN_BW_1-1:0] in_1_28,
    input [IN_BW_1-1:0] in_1_29,
    input [IN_BW_1-1:0] in_1_30,
    input [IN_BW_1-1:0] in_1_31,
    input [IN_BW_1-1:0] in_1_32,
    input [IN_BW_1-1:0] in_1_33,
    input [IN_BW_1-1:0] in_1_34,
    input [IN_BW_1-1:0] in_1_35,
    input [IN_BW_1-1:0] in_1_36,
    input [IN_BW_1-1:0] in_1_37,
    input [IN_BW_1-1:0] in_1_38,
    input [IN_BW_1-1:0] in_1_39,
    input [IN_BW_1-1:0] in_1_40,
    input [IN_BW_1-1:0] in_1_41,
    input [IN_BW_1-1:0] in_1_42,
    input [IN_BW_1-1:0] in_1_43,
    input [IN_BW_1-1:0] in_1_44,
    input [IN_BW_1-1:0] in_1_45,
    input [IN_BW_1-1:0] in_1_46,
    input [IN_BW_1-1:0] in_1_47,

    input [IN_BW_2-1:0] in_2_0,
    input [IN_BW_2-1:0] in_2_1,
    input [IN_BW_2-1:0] in_2_2,
    input [IN_BW_2-1:0] in_2_3,
    input [IN_BW_2-1:0] in_2_4,
    input [IN_BW_2-1:0] in_2_5,
    input [IN_BW_2-1:0] in_2_6,
    input [IN_BW_2-1:0] in_2_7,
    input [IN_BW_2-1:0] in_2_8,
    input [IN_BW_2-1:0] in_2_9,
    input [IN_BW_2-1:0] in_2_10,
    input [IN_BW_2-1:0] in_2_11,
    input [IN_BW_2-1:0] in_2_12,
    input [IN_BW_2-1:0] in_2_13,
    input [IN_BW_2-1:0] in_2_14,
    input [IN_BW_2-1:0] in_2_15,
    input [IN_BW_2-1:0] in_2_16,
    input [IN_BW_2-1:0] in_2_17,
    input [IN_BW_2-1:0] in_2_18,
    input [IN_BW_2-1:0] in_2_19,
    input [IN_BW_2-1:0] in_2_20,
    input [IN_BW_2-1:0] in_2_21,
    input [IN_BW_2-1:0] in_2_22,
    input [IN_BW_2-1:0] in_2_23,
    input [IN_BW_2-1:0] in_2_24,
    input [IN_BW_2-1:0] in_2_25,
    input [IN_BW_2-1:0] in_2_26,
    input [IN_BW_2-1:0] in_2_27,
    input [IN_BW_2-1:0] in_2_28,
    input [IN_BW_2-1:0] in_2_29,
    input [IN_BW_2-1:0] in_2_30,
    input [IN_BW_2-1:0] in_2_31,
    input [IN_BW_2-1:0] in_2_32,
    input [IN_BW_2-1:0] in_2_33,
    input [IN_BW_2-1:0] in_2_34,
    input [IN_BW_2-1:0] in_2_35,
    input [IN_BW_2-1:0] in_2_36,
    input [IN_BW_2-1:0] in_2_37,
    input [IN_BW_2-1:0] in_2_38,
    input [IN_BW_2-1:0] in_2_39,
    input [IN_BW_2-1:0] in_2_40,
    input [IN_BW_2-1:0] in_2_41,
    input [IN_BW_2-1:0] in_2_42,
    input [IN_BW_2-1:0] in_2_43,
    input [IN_BW_2-1:0] in_2_44,
    input [IN_BW_2-1:0] in_2_45,
    input [IN_BW_2-1:0] in_2_46,
    input [IN_BW_2-1:0] in_2_47,

    output wire [OUT_BW-1:0] out_0,
    output wire [OUT_BW-1:0] out_1,
    output wire [OUT_BW-1:0] out_2,
    output wire [OUT_BW-1:0] out_3,
    output wire [OUT_BW-1:0] out_4,
    output wire [OUT_BW-1:0] out_5,
    output wire [OUT_BW-1:0] out_6,
    output wire [OUT_BW-1:0] out_7,
    output wire [OUT_BW-1:0] out_8,
    output wire [OUT_BW-1:0] out_9,
    output wire [OUT_BW-1:0] out_10,
    output wire [OUT_BW-1:0] out_11,
    output wire [OUT_BW-1:0] out_12,
    output wire [OUT_BW-1:0] out_13,
    output wire [OUT_BW-1:0] out_14,
    output wire [OUT_BW-1:0] out_15,
    output wire [OUT_BW-1:0] out_16,
    output wire [OUT_BW-1:0] out_17,
    output wire [OUT_BW-1:0] out_18,
    output wire [OUT_BW-1:0] out_19,
    output wire [OUT_BW-1:0] out_20,
    output wire [OUT_BW-1:0] out_21,
    output wire [OUT_BW-1:0] out_22,
    output wire [OUT_BW-1:0] out_23,
    output wire [OUT_BW-1:0] out_24,
    output wire [OUT_BW-1:0] out_25,
    output wire [OUT_BW-1:0] out_26,
    output wire [OUT_BW-1:0] out_27,
    output wire [OUT_BW-1:0] out_28,
    output wire [OUT_BW-1:0] out_29,
    output wire [OUT_BW-1:0] out_30,
    output wire [OUT_BW-1:0] out_31,
    output wire [OUT_BW-1:0] out_32,
    output wire [OUT_BW-1:0] out_33,
    output wire [OUT_BW-1:0] out_34,
    output wire [OUT_BW-1:0] out_35,
    output wire [OUT_BW-1:0] out_36,
    output wire [OUT_BW-1:0] out_37,
    output wire [OUT_BW-1:0] out_38,
    output wire [OUT_BW-1:0] out_39,
    output wire [OUT_BW-1:0] out_40,
    output wire [OUT_BW-1:0] out_41,
    output wire [OUT_BW-1:0] out_42,
    output wire [OUT_BW-1:0] out_43,
    output wire [OUT_BW-1:0] out_44,
    output wire [OUT_BW-1:0] out_45,
    output wire [OUT_BW-1:0] out_46,
    output wire [OUT_BW-1:0] out_47
);

assign out_0    = in_1_0  * in_2_0 ;
assign out_1    = in_1_1  * in_2_1 ;
assign out_2    = in_1_2  * in_2_2 ;
assign out_3    = in_1_3  * in_2_3 ;
assign out_4    = in_1_4  * in_2_4 ;
assign out_5    = in_1_5  * in_2_5 ;
assign out_6    = in_1_6  * in_2_6 ;
assign out_7    = in_1_7  * in_2_7 ;
assign out_8    = in_1_8  * in_2_8 ;
assign out_9    = in_1_9  * in_2_9 ;
assign out_10   = in_1_10 * in_2_10;
assign out_11   = in_1_11 * in_2_11;
assign out_12   = in_1_12 * in_2_12;
assign out_13   = in_1_13 * in_2_13;
assign out_14   = in_1_14 * in_2_14;
assign out_15   = in_1_15 * in_2_15;
assign out_16   = in_1_16 * in_2_16;
assign out_17   = in_1_17 * in_2_17;
assign out_18   = in_1_18 * in_2_18;
assign out_19   = in_1_19 * in_2_19;
assign out_20   = in_1_20 * in_2_20;
assign out_21   = in_1_21 * in_2_21;
assign out_22   = in_1_22 * in_2_22;
assign out_23   = in_1_23 * in_2_23;
assign out_24   = in_1_24 * in_2_24;
assign out_25   = in_1_25 * in_2_25;
assign out_26   = in_1_26 * in_2_26;
assign out_27   = in_1_27 * in_2_27;
assign out_28   = in_1_28 * in_2_28;
assign out_29   = in_1_29 * in_2_29;
assign out_30   = in_1_30 * in_2_30;
assign out_31   = in_1_31 * in_2_31;
assign out_32   = in_1_32 * in_2_32;
assign out_33   = in_1_33 * in_2_33;
assign out_34   = in_1_34 * in_2_34;
assign out_35   = in_1_35 * in_2_35;
assign out_36   = in_1_36 * in_2_36;
assign out_37   = in_1_37 * in_2_37;
assign out_38   = in_1_38 * in_2_38;
assign out_39   = in_1_39 * in_2_39;
assign out_40   = in_1_40 * in_2_40;
assign out_41   = in_1_41 * in_2_41;
assign out_42   = in_1_42 * in_2_42;
assign out_43   = in_1_43 * in_2_43;
assign out_44   = in_1_44 * in_2_44;
assign out_45   = in_1_45 * in_2_45;
assign out_46   = in_1_46 * in_2_46;
assign out_47   = in_1_47 * in_2_47;

endmodule