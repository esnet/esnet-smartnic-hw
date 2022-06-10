# Create SDNet IP (sdnet_0)
create_ip -force -name vitis_net_p4 -vendor xilinx.com -library ip -version 1.0 -module_name sdnet_0 -dir .

set default_props [list \
    CONFIG.P4_FILE   $env(P4_FILE) \
    CONFIG.PKT_RATE  150
]

if {[info exists env(P4_OPTS)]} {
    set p4_opts $env(P4_OPTS)
} else {
    set p4_opts {}
}

set props [concat $default_props $p4_opts]

# Convenience function for printing property list
proc print_props {props} {
    puts "======================================================="
    puts "P4 Config Properties:"
    puts "======================================================="
    set i 0
    while {$i < [llength $props]} {
        #puts -nonewline [join [lindex $props $i] :]
        puts [concat [lindex $props $i] : [lindex $props $i+1]]
        incr i
        incr i
    }
    puts "======================================================="
}

print_props $props

set_property -dict [concat $default_props $p4_opts] [get_ips sdnet_0]
