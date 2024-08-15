set module_name xilinx_aved

set AVED_ROOT $env(AVED_ROOT)
set AVED_BASE_DESIGN $env(AVED_BASE_DESIGN)

# Create BD
create_bd_design ${module_name} -dir .
current_bd_design ${module_name}

source "${AVED_ROOT}/hw/${AVED_BASE_DESIGN}/src/bd/create_bd_design.tcl"
create_root_design ""

save_bd_design
