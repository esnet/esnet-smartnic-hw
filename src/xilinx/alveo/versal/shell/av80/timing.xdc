create_generated_clock -name core_clk [get_pins i_core/i_smartnic_wrapper/smartnic/reset_inst/axi_to_core_clk/inst/clock_primitive_inst/MMCME5_inst/CLKOUT0]


# SMBus SCL/SDA are asynchronous to the internal clocks; synchronization is handled internally by smbus_v1_1_0 IP.
set_false_path -from [get_ports {smbus_0_scl_io smbus_0_sda_io}]
set_false_path -to   [get_ports {smbus_0_scl_io smbus_0_sda_io}]

# Nominal delays satisfy check_timing; false paths above prevent any actual timing analysis on these ports.
set_input_delay  -clock [get_clocks core_clk] 0 [get_ports {smbus_0_scl_io smbus_0_sda_io}]
set_output_delay -clock [get_clocks core_clk] 0 [get_ports {smbus_0_scl_io smbus_0_sda_io}]
