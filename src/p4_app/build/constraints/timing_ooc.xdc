# Define clocks
create_clock -period 2.907 -name clk [get_ports core_clk]
create_clock -period 8.000 -name aclk [get_ports axil_aclk]

# Clock sources
set_property HD.CLK_SRC BUFGCE_X0Y186 [get_ports core_clk]
set_property HD.CLK_SRC BUFGCE_X0Y72  [get_ports axil_aclk]
