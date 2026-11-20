# OOC synthesis timing constraints for esnet_smartnic (Versal V80 shell)
# Defines board reference clocks not supplied by IP constraints.
# Derived clocks (pl0_ref_clk, clk_usr_0/1) are inferred from CIPS and
# clock wizard configuration within the AVED BD.

# DDR4 reference clocks (200 MHz) are defined by the DDR4 controller IP.

# HBM reference clocks (200 MHz)
create_clock -period 5.000 [get_ports hbm_ref_clk_0_clk_p]
create_clock -period 5.000 [get_ports hbm_ref_clk_1_clk_p]

# PCIe reference clock (100 MHz)
create_clock -period 10.000 [get_ports gt_pcie_refclk_clk_p]
