# Core OOC boundary clocks.
# The core module's single port (shell_intf.core shell_if) is flattened by
# Vivado synthesis; clock signals appear as shell_if_clk, shell_if_mgmt_clk,
# shell_if_clk_100mhz, and shell_if_port_clk[N].
create_clock -quiet -period 2.857 [get_ports -quiet shell_if_clk]
create_clock -quiet -period 8.000 [get_ports -quiet shell_if_mgmt_clk]
create_clock -quiet -period 8.000 [get_ports -quiet shell_if_clk_100mhz]

# MAC clocks (322.265625 MHz). Mutually asynchronous in the real design;
# treated as one clock for OOC synthesis.
create_clock -quiet -period 3.103 [get_ports -quiet {shell_if_port_clk[*]}]
