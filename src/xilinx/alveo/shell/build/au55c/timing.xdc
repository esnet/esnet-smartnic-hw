create_clock -period 10.000 -name pcie_refclk [get_ports pcie_refclk_p]
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_3_p]

set_false_path -through [get_ports pcie_rstn]
