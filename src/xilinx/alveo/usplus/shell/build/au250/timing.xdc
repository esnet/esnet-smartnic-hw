# AU250 shell primary clocks.
# Board clock sources and pin connections:
#   https://download.amd.com/opendownload/xlnx/alveo-u250-xdc_20210909.zip

# PCIe reference clock: 100 MHz.
create_clock -period 10.000 -name pcie_refclk [get_ports {pcie_refclk_p}]

# The shell derives its 100 MHz clock from the QDMA 250 MHz clock;
# the clock-wizard IP supplies the generated-clock constraints.

# CMAC IP constrains its reference and generated clocks.
# PCIe PERST# is asynchronous; QDMA synchronizes reset internally.
set_false_path -through [get_ports {pcie_rstn}]
