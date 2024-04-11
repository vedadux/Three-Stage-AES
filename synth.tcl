set IN_FILES       [regexp -all -inline {\S+} $::env(IN_FILES)]
set TOP_MODULE     $::env(TOP_MODULE)
set OUT_BASE       $::env(OUT_BASE)
set LIBERTY        $::env(LIBERTY)

set VLOG_PRE_MAP   $OUT_BASE\_pre.v
set VLOG_POST_MAP  $OUT_BASE\_post.v
set JSON_PRE_MAP   $OUT_BASE\_pre.json
set JSON_POST_MAP  $OUT_BASE\_post.json
set JSON_STATS     $OUT_BASE\_stats.json

proc get_gates {filename} {
    set file [open $filename r]
    set content [read $file]
    close $file

    set result ""
    set pattern {\$_(\S+)_}
    set matches [regexp -all -inline -lineanchor -- $pattern $content]
    puts $matches
    foreach match $matches {
        if {[string first "$" $match] == -1 &&
            [string first "DFF" $match] == -1} {
           lappend result $match
        }
    }
    
    return [join $result ","]
}


foreach file $IN_FILES {
    yosys read_verilog -defer $file
}

yosys chparam -set NUM_SHARES 3 $TOP_MODULE
yosys synth -top $TOP_MODULE -flatten -noabc
yosys clean -purge
yosys tee -o "/tmp/tmp-stats.txt" stat
set gates [get_gates "/tmp/tmp-stats.txt"]
puts "Gates are $gates"
yosys abc -g $gates 
yosys clean -purge
yosys stat

yosys write_verilog $VLOG_PRE_MAP
yosys write_json    $JSON_PRE_MAP

yosys dfflibmap -liberty $LIBERTY
yosys abc -liberty $LIBERTY
yosys clean -purge

yosys write_verilog $VLOG_POST_MAP
yosys write_json    $JSON_POST_MAP
yosys tee -o $JSON_STATS stat -liberty $LIBERTY

# yosys write_json $JSON_OUT_FILE