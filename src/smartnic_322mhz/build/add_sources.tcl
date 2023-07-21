source sources.tcl

read_verilog -sv ../app_if/smartnic_322mhz_app.sv

# Constraints
read_xdc -mode out_of_context constraints/timing_ooc.xdc
read_xdc -mode out_of_context constraints/place_ooc.xdc
