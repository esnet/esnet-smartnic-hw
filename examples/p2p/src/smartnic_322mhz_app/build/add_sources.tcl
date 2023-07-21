source sources.tcl

# Constraints
read_xdc -unmanaged -mode out_of_context constraints/timing_ooc.xdc
read_xdc -unmanaged -mode out_of_context constraints/place_ooc.xdc
