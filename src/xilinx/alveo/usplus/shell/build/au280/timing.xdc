# AU280 shell primary clocks.
# Board clock sources and pin connections:
#   https://github.com/Xilinx/XilinxBoardStore/tree/2020.2/boards/Xilinx/au280/production/1.1

# PCIe reference clock: 100 MHz.
create_clock -period 10.000 -name pcie_refclk [get_ports {pcie_refclk_p}]

# SYSCLK3: 100 MHz.
create_clock -period 10.000 -name sys_clk [get_ports {sys_clk_3_p}]

# CMAC IP constrains its reference and generated clocks.
# PCIe PERST# is asynchronous; QDMA synchronizes reset internally.
set_false_path -through [get_ports {pcie_rstn}]

# CMS satellite GPIO and UART are asynchronous to the FPGA clocks.
# https://docs.amd.com/r/en-US/pg348-cms-subsystem/I/O-Signal-Description
set_false_path -from [get_ports {satellite_gpio[*] satellite_uart_0_rxd}]
set_false_path -to [get_ports {satellite_uart_0_txd}]
