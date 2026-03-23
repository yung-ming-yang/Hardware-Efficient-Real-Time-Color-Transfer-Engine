
//=== Setup mode ===
set system mode setup

set log file lec.log -replace
set parallel option -threads 1
//---------------------------------------------------------------------------------//
// Top level
setenv TOP_DESIGN top

// Resource file (MDP flow)
setenv RESRC_FILE ../../syn/report/report_resources_top.out

// Blackbox (before reading design!!!)
//add notranslate module xxx -library -both

read design -file golden.f -golden -verilog2k
read design -file revised.f -revised
report design data
report black box -detail

// Specify module renaming rule 
// (correspond to DC 'set uniquify_naming_style "%s_mydesign_%d"')
// (%w, %d) <-- (@1, @2)
add renaming rule rule1 "%w_mydesign_%d$" "@1" -module -revised

// Software renames golden design instances to be the same as revised design
uniquify -nolib -all -use_renaming_rule


// Specify modeling directives for clock-gating & constant optimization 
set flatten model -gated_clock
set flatten model -seq_constant

set root module $TOP_DESIGN -golden
set root module $TOP_DESIGN -revised

