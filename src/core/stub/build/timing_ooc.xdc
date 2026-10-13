# Core OOC boundary clocks.
# The core module's single port (shell_intf.core shell_if) is flattened by
# Vivado synthesis; clock signals appear as shell_if_clk, shell_if_mgmt_clk.
# The stub has no clock fanout so the optimizer may remove these ports;
# -quiet suppresses the error if get_ports returns empty.
create_clock -quiet -period 2.857 [get_ports -quiet shell_if_clk]
create_clock -quiet -period 8.000 [get_ports -quiet shell_if_mgmt_clk]
