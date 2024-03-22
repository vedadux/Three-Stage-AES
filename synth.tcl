set VLOG_IN_FILES   [regexp -all -inline {\S+} $::env(IN_FILES)]
set VLOG_OUT_FILE   $::env(OUT_FILE)
set VLOG_TOP_MODULE $::env(TOP_MODULE)

foreach file $VLOG_IN_FILES {
    yosys read_verilog -defer $file
}
yosys chparam -set NUM_SHARES 4 $VLOG_TOP_MODULE
yosys synth -top $VLOG_TOP_MODULE
yosys flatten
yosys write_verilog $VLOG_OUT_FILE