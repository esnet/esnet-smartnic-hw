# Define clocks
create_clock -period 2.907 -name clk [get_ports core_clk]
create_clock -period 8.000 -name aclk [get_ports axil_aclk]

# Clock sources
# set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports core_clk]
# (can't set HD.CLK_SRC on core_clk because it drives no nets within application core)
set_property HD.CLK_SRC BUFGCTRL_X0Y1  [get_ports axil_aclk]
