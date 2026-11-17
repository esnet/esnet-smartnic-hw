# Runtime configuration-flash access at 25 MHz SCK (50 MHz IP reference).
# UltraScale+ STARTUPE3 timing model and SCK-ratio-2 receive pipeline:
# https://docs.amd.com/r/en-US/pg153-axi-quad-spi/Constraining-the-IP
# Micron MT25QU01GBBB data sheet, AC characteristics, STR mode:
# https://www.micron.com/products/storage/nor-flash/serial-nor/part-catalog/part-detail/mt25qu01gbbb8e12-0sit
#   tCLQV <= 6 ns, tDVCH >= 1.75 ns, tCHDX >= 2 ns,
#   tSLCH/tCHSL/tCHSH/tSHCH >= 2.7 ns.
# Use conservative 7 ns clock-to-output and 3 ns setup/hold requirements.
# Board propagation is budgeted independently at 0..2 ns for clock, data,
# and select. These are bounds to validate, not measured board trace delays.

set qspi_ip [get_cells -hierarchical -filter {REF_NAME == xilinx_axi_quad_spi}]
set qspi_startup [get_cells -hierarchical -filter {REF_NAME == STARTUPE3 && NAME =~ *i_xilinx_qspi/*}]
set qspi_ref_pin [get_pins -of_objects $qspi_ip -filter {REF_PIN_NAME == ext_spi_clk}]
set qspi_ref_clk [get_clocks -of_objects $qspi_ref_pin]
set qspi_cclk [get_pins -of_objects $qspi_startup -filter {REF_PIN_NAME == CCLK}]
set qspi_data_in [get_pins -of_objects $qspi_startup -filter {REF_PIN_NAME =~ DATA_IN*}]
set qspi_data_out [get_pins -of_objects $qspi_startup -filter {REF_PIN_NAME =~ DATA_OUT*}]
set qspi_select [get_pins -of_objects $qspi_startup -filter {REF_PIN_NAME == FCS_B}]

create_generated_clock -name qspi_sck -source $qspi_ref_pin -edges {3 5 7} $qspi_cclk

# Round-trip clock/data propagation plus flash clock-to-output (7 + 2 + 2).
set_input_delay -clock qspi_sck -clock_fall -max 11.000 $qspi_data_in
set_input_delay -clock qspi_sck -clock_fall -min 0.000 $qspi_data_in

# Flash setup/hold plus worst-case data/select-to-clock skew (3 + 2 - 0).
set_output_delay -clock qspi_sck -max 5.000 $qspi_data_out
set_output_delay -clock qspi_sck -min -5.000 $qspi_data_out
set_output_delay -clock qspi_sck -max 5.000 $qspi_select
set_output_delay -clock qspi_sck -min -5.000 $qspi_select

set_multicycle_path 2 -setup -from [get_clocks qspi_sck] -to $qspi_ref_clk
set_multicycle_path 1 -hold -end -from [get_clocks qspi_sck] -to $qspi_ref_clk

# Transmit data changes on the SCK falling-edge cycle. The flash captures
# it on the following rising edge, one reference-clock cycle later (20 ns).
# Keep single-cycle setup; for hold, skip the inactive source edge at that
# capture edge and check the next possible change on the following fall.
set_multicycle_path 1 -setup -start -from $qspi_ref_clk -to [get_clocks qspi_sck]
set_multicycle_path 1 -hold -start -from $qspi_ref_clk -to [get_clocks qspi_sck]

# The IP supplies the internal STARTUP max-delay constraints.
