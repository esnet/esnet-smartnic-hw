# AU55C configuration and debug settings.
# Sources:
#   https://docs.amd.com/r/en-US/ug1469-alveo-u55c/Quad-SPI-Flash-Memory
#   https://docs.amd.com/r/en-US/ug1469-alveo-u55c/MCS-File-Generation-and-Alveo-Card-Programming

# 1.8 V, four-bit SPI flash; use internal CCLK at a conservative 63.8 MHz.
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 63.8 [current_design]

# Shell image policy: recovery fallback, compression, and unused-pin pullups.
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

# FPGA power-analysis budget in watts (distinct from total card power).
set_operating_conditions -design_power_budget 100

# Debug hub clock and JTAG scan chain for the shell.
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets -filter {NAME =~ *sys_clk_100mhz}]
