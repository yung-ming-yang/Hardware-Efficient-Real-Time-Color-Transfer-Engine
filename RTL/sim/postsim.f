// testbench
test_top.v

// sram behavior model
sram_model/sram_r.v
sram_model/sram_gb.v
sram_model/sram_fy.v
sram_model/sram_fc.v

// layout
../innovus/post_layout/CHIP.v

# Logic Gate models
-v /usr/cadtool/GPDK45/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v2_basicCells.v

+define
+maxdelays
+neg_tchk