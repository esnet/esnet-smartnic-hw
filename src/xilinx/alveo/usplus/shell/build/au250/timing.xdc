# AU250 shell primary clocks.
# Board clock sources and pin connections:
#   https://download.amd.com/opendownload/xlnx/alveo-u250-xdc_20210909.zip

# PCIe reference clock: 100 MHz.
create_clock -period 10.000 -name pcie_refclk [get_ports {pcie_refclk_p}]

# SYSCLK1_300: 300 MHz, used to generate the free-running 100 MHz system clock.
create_clock -period 3.333 -name sys_clk_300mhz [get_ports {clk1_300mhz_p}]

# The shell derives its 100 MHz clock from the board's 300 MHz oscillator;
# the clock-wizard IP supplies the generated-clock constraints.

# CMAC IP constrains its reference and generated clocks.
# PCIe PERST# is asynchronous; QDMA synchronizes reset internally.
set_false_path -through [get_ports {pcie_rstn}]

# CMS satellite GPIO and UART are asynchronous to the FPGA clocks.
# https://docs.amd.com/r/en-US/pg348-cms-subsystem/I/O-Signal-Description
set_false_path -from [get_ports {satellite_gpio[*] satellite_uart_0_rxd}]
set_false_path -to [get_ports {satellite_uart_0_txd}]
