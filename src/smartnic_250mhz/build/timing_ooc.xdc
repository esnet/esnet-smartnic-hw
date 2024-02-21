create_clock -period 8.000 -name aclk [get_ports axil_aclk]
create_clock -period 3.103 -name clk  [get_ports axis_aclk]

