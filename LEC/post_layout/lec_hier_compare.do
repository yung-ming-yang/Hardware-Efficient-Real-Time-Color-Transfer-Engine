
// Hierarchical compare
write hier_compare dofile hier.do \
    -prepend_string "analyze setup -verbose; \
                     analyze multiplier -cdp_info; \
                     analyze datapath -merge -share -effort medium -verbose;" \
    -append_string "analyze abort -compare" -replace


// static compare
//dofile hier.do  

// dynamic compare
run hier_compare hier.do


// Report
report verification

// Save session
save session DBS/lec_hier_compare


// Back GUI to check details
//restore session DBS/lec_hier_compare
//set system mode lec
//set gui on

