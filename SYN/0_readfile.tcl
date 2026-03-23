set TOP_DIR $TOPLEVEL
set RPT_DIR report
set NET_DIR netlist

sh rm -rf ./$TOP_DIR
sh rm -rf ./$RPT_DIR
sh rm -rf ./$NET_DIR
sh mkdir ./$TOP_DIR
sh mkdir ./$RPT_DIR
sh mkdir ./$NET_DIR

# define a lib path here
define_design_lib $TOPLEVEL -path ./$TOPLEVEL

# Read Design File (add your files here)
set HDL_DIR "../hdl"
analyze -library $TOPLEVEL -format verilog "$HDL_DIR/top.v \
                                            $HDL_DIR/divider_uu.v \
                                            $HDL_DIR/histogram.v \
                                            $HDL_DIR/gamma_lut.v \
                                            $HDL_DIR/gamma.v \
                                            $HDL_DIR/adder4to1.v \
                                            $HDL_DIR/chroma_stats.v \
                                            $HDL_DIR/demosaic.v \
                                            $HDL_DIR/color_mapping.v \
                                            $HDL_DIR/light_match.v \
                                            $HDL_DIR/mul.v \
                                            $HDL_DIR/rgb.v \
                                            $HDL_DIR/ycbcr.v \
                                            $HDL_DIR/sqrt_lut.v \
                                            $HDL_DIR/wb.v \
                                           "

# analyze -library $TOPLEVEL -format verilog "$HDL_DIR/top_huang.v \
#                                             $HDL_DIR/demosaic.v \
#                                            "

# elaborate your design
elaborate $TOPLEVEL -architecture verilog -library $TOPLEVEL

# Solve Multiple Instance
set uniquify_naming_style "%s_mydesign_%d"
uniquify

# link the design
current_design $TOPLEVEL
link
