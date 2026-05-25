# Core OOC boundary clocks.
# The core module's single port (shell_intf.core shell_if) is flattened by
# Vivado synthesis; clock signals appear as shell_if_clk, shell_if_mgmt_clk.
foreach {port period} {
    shell_if_clk      3.100
    shell_if_mgmt_clk 8.000
} {
    set p [get_ports -quiet $port]
    if {[llength $p]} {
        create_clock -period $period $p
    }
}
