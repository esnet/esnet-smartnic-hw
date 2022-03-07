# Define clocks
create_clock -period 2.907 -name clk [get_ports core_clk]
create_clock -period 8.000 -name aclk [get_ports axil_aclk]

# Async groups
set_clock_groups -name aclk_to_core_clk -asynchronous -group {aclk} -group {clk}
set_clock_groups -name core_clk_to_aclk -asynchronous -group {clk} -group {aclk}

# Clock sources
# set_property HD.CLK_SRC BUFGCE_X0Y186 [get_ports core_clk]
# (can't set HD.CLK_SRC on core_clk because it drives no nets within application core)
set_property HD.CLK_SRC BUFGCE_X0Y72  [get_ports axil_aclk]
