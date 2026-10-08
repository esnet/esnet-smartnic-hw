# Core OOC boundary clocks.
# The core module's single port (shell_intf.core shell_if) is flattened by
# Vivado synthesis; clock signals appear as shell_if_clk, shell_if_mgmt_clk,
# shell_if_clk_100mhz, and shell_if_port_clk[N].
set p [get_ports -quiet shell_if_clk]
if {[llength $p]} { create_clock -period 2.857 $p }

set p [get_ports -quiet shell_if_mgmt_clk]
if {[llength $p]} { create_clock -period 8.000 $p }

set p [get_ports -quiet shell_if_clk_100mhz]
if {[llength $p]} { create_clock -period 8.000 $p }

# MAC clocks (322.265625 MHz). Mutually asynchronous in the real design;
# treated as one clock for OOC synthesis.
set p [get_ports -quiet {shell_if_port_clk[*]}]
if {[llength $p]} { create_clock -period 3.103 $p }
