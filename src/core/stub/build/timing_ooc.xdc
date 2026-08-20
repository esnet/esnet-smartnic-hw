# Core OOC boundary clocks.
# The core module's single port (shell_intf.core shell_if) is flattened by
# Vivado synthesis; clock signals appear as shell_if_clk, shell_if_mgmt_clk.
# Constraints are applied conditionally: a stub implementation has no clock
# fanout so the optimizer removes the ports, in which case the constraint is
# silently skipped rather than failing the build.
set p [get_ports -quiet shell_if_clk]
if {[llength $p]} { create_clock -period 3.100 $p }

set p [get_ports -quiet shell_if_mgmt_clk]
if {[llength $p]} { create_clock -period 8.000 $p }
