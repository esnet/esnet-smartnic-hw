# Name the core clock so the SMBus constraints below can reference it.
# Vivado derives the MMCM output clock automatically; this only attaches the
# name.  The path must track the wizard instance inside the Versal shell.
create_generated_clock -name core_clk \
    [get_pins i_xilinx_alveo_versal_shell/i_xilinx_versal_core_clk/inst/clock_primitive_inst/MMCME5_inst/CLKOUT0]

# DCMAC clk_wiz output clocks derived from qsfp0_322mhz_clk via IBUFDS_GTME5/BUFG_GT/MMCME5
#create_generated_clock -name dcmac_core_clk \
#    [get_pins i_xilinx_alveo_versal_shell/dcmac_wrapper_0/i_clk_wiz/inst/clock_primitive_inst/MMCME5_inst/CLKOUT0]
#create_generated_clock -name dcmac_axis_clk \
#    [get_pins i_xilinx_alveo_versal_shell/dcmac_wrapper_0/i_clk_wiz/inst/clock_primitive_inst/MMCME5_inst/CLKOUT1]
#create_generated_clock -name dcmac_ts_clk \
#    [get_pins i_xilinx_alveo_versal_shell/dcmac_wrapper_0/i_clk_wiz/inst/clock_primitive_inst/MMCME5_inst/CLKOUT2]

# QSFP0 GT reference clock (322.265625 MHz)
create_clock -period 3.102 -name qsfp0_322mhz_clk [get_ports qsfp0_322mhz_clk_p]

# SMBus SCL/SDA are asynchronous to the internal clocks; synchronization is handled internally by smbus_v1_1_0 IP.
set_false_path -from [get_ports {smbus_0_scl_io smbus_0_sda_io}]
set_false_path -to   [get_ports {smbus_0_scl_io smbus_0_sda_io}]

# Nominal delays satisfy check_timing; false paths above prevent any actual timing analysis on these ports.
set_input_delay  -clock [get_clocks core_clk] 0 [get_ports {smbus_0_scl_io smbus_0_sda_io}]
set_output_delay -clock [get_clocks core_clk] 0 [get_ports {smbus_0_scl_io smbus_0_sda_io}]
