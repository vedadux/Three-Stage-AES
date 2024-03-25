set VLOG_IN_FILES   [regexp -all -inline {\S+} $::env(IN_FILES)]
set VLOG_OUT_FILE   [file rootname $::env(OUT_FILE)].v
set JSON_OUT_FILE   [file rootname $::env(OUT_FILE)].json
set VLOG_TOP_MODULE $::env(TOP_MODULE)

foreach file $VLOG_IN_FILES {
    yosys read_verilog -defer $file
}
yosys chparam -set NUM_SHARES 3 -set BIT_WIDTH 1 $VLOG_TOP_MODULE
yosys synth -top $VLOG_TOP_MODULE -flatten
yosys clean -purge
yosys write_verilog $VLOG_OUT_FILE
# yosys write_json $JSON_OUT_FILE