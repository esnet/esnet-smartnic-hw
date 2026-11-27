# Let each DDR4 controller define its buffered input clock during BD OOC
# synthesis. Preserve every other constraint generated for the BD boundary.
set auto_xdc [get_files -all -quiet */xilinx_aved_ooc.xdc]
if {[llength $auto_xdc] != 1} {
    error "Expected exactly one xilinx_aved_ooc.xdc, found [llength $auto_xdc]"
}
set auto_xdc [lindex $auto_xdc 0]

set stream [open $auto_xdc r]
set lines [split [read $stream] \n]
close $stream
set removed [dict create]
set retained {}
foreach line $lines {
    if {[regexp {^create_clock -name (sys_clk0_([01])_clk_p) -period ([0-9.]+) \[get_ports (sys_clk0_[01]_clk_p)\]$} \
            $line -> clock_name bank period port]} {
        if {$clock_name ne $port || [dict exists $removed $bank]} {
            error "Unexpected DDR4 clock definition: $line"
        }
        # Only omit the boundary default when the enabled DDR4 IP constraint
        # supplies the same clock period. Fail if the generated IP changes.
        set ip_xdc [get_files -all -quiet */xilinx_aved_axi_noc_mc_ddr4_${bank}_0/bd_0/ip/*/hdl/par/*_ip.xdc]
        if {[llength $ip_xdc] != 1 || ![get_property IS_ENABLED $ip_xdc]
                || ![get_property USED_IN_SYNTHESIS $ip_xdc]} {
            error "Expected an enabled synthesis XDC for DDR4 bank $bank"
        }
        set ip_xdc [lindex $ip_xdc 0]
        set stream [open $ip_xdc r]
        set ip_constraints [read $stream]
        close $stream
        set clocks [regexp -all -inline -line {^create_clock -period ([0-9.]+) \[get_ports sys_clk_p\]$} $ip_constraints]
        if {[llength $clocks] != 2 || [lindex $clocks 1] != $period} {
            error "DDR4 bank $bank does not supply the expected $period ns input clock"
        }
        dict set removed $bank $clock_name
    } else {
        if {[regexp {^\s*create_clock\s.*sys_clk0_[01]_clk_p} $line]} {
            error "Unrecognized DDR4 boundary clock definition: $line"
        }
        lappend retained $line
    }
}
if {[lsort [dict keys $removed]] ne {0 1}} {
    error "Expected one generated boundary clock for each DDR4 bank"
}

# Replace the generated OOC file in this synthesis session. Do not edit
# vendor output products, or disable any DDR4 IP constraints.
set filtered_xdc [file join [pwd] xilinx_aved_ooc.filtered.xdc]
set content [join $retained \n]
set previous ""
if {[file exists $filtered_xdc]} {
    set stream [open $filtered_xdc r]
    set previous [read $stream]
    close $stream
}
if {$content ne $previous} {
    set stream [open $filtered_xdc w]
    puts -nonewline $stream $content
    close $stream
}
if {[get_property USED_IN_SYNTHESIS $auto_xdc]} {set_property USED_IN_SYNTHESIS false $auto_xdc}
if {[get_property USED_IN_SYNTHESIS $auto_xdc]} {
    error "Could not disable the generated BD OOC clocks for synthesis"
}
if {[llength [get_files -all -quiet $filtered_xdc]] == 0} {
    read_xdc -mode out_of_context $filtered_xdc
}
set filtered [get_files -all $filtered_xdc]
foreach property {PROCESSING_ORDER SCOPED_TO_REF SCOPED_TO_CELLS} {
    set value [get_property $property $auto_xdc]
    if {[get_property $property $filtered] ne $value} {
        set_property $property $value $filtered
    }
}
puts "AVED OOC clocks: DDR4 clocks supplied by IP; other generated boundary constraints retained."
