set app_root $env(APP_ROOT)

# Import core sources
source read_core_sources.tcl

# Import app netlist
read_checkpoint -cell box_322mhz_inst/smartnic_322mhz/smartnic_322mhz_app $app_root/app_if/smartnic_322mhz_app.dcp
