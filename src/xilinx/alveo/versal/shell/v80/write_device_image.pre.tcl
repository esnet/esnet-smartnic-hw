# UUID generation for the non-project build flow.
#
# Adapts the AVED write_device_image.pre logic for non-project DCP paths.
# build_non_proj.tcl sets ::NP_TOP and ::NP_OUT_DIR before sourcing this hook.
#
# Produces:
#   - Logic-UUID:     md5 of synth DCP, written into the uuid_rom LUT-RAM cell
#   - Interface-UUID: md5 of route_opt DCP
#   - pfm_uuid_manifest.dict in OUT_DIR (consumed by write_hw_platform)

set _top    $::NP_TOP
set _outdir $::NP_OUT_DIR

# Source update_uuid_rom.tcl directly from the AVED IP repo rather than
# going through the IP catalog (no project context needed this way).
set _script_dir [file dirname [info script]]
set _update_uuid_rom [file normalize \
    "$_script_dir/../../../../aved/hw/amd_v80_gen5x8_25.1/src/iprepo/shell_utils_uuid_rom_v2_0/tcl/update_uuid_rom.tcl"]

if {![file exists $_update_uuid_rom]} {
    return -code error "ERROR: update_uuid_rom.tcl not found at $_update_uuid_rom"
}
source $_update_uuid_rom

# Logic-UUID: md5 of the shell synth DCP (passed to Vivado via -top_dcp)
set _synth_dcp $::NP_TOP_DCP
if {![file exists $_synth_dcp]} {
    return -code error "ERROR: synth DCP not found: $_synth_dcp"
}
set _logic_uuid [lindex [exec md5sum $_synth_dcp] 0]
puts "Logic-UUID: $_logic_uuid"

# Burn Logic-UUID into the uuid_rom LUT-RAM cell before write_device_image
set _uuid_cell [get_cells -hier -quiet -filter {NAME =~ "*uuid_rom" && PARENT =~ "*base_logic"}]
if {$_uuid_cell eq ""} {
    return -code error "ERROR: UUID ROM cell not found (*uuid_rom under *base_logic)"
}
if {[update_uuid_rom $_logic_uuid $_uuid_cell] != 0} {
    return -code error "ERROR: update_uuid_rom failed"
}

# Interface-UUID: md5 of the routed checkpoint
set _route_dcp "$_outdir/${_top}.route_opt.dcp"
if {![file exists $_route_dcp]} {
    return -code error "ERROR: route_opt DCP not found: $_route_dcp"
}
set _interface_uuid [lindex [exec md5sum $_route_dcp] 0]
puts "Interface-UUID: $_interface_uuid"

# Write pfm_uuid_manifest.dict — consumed by write_hw_platform in the xsa phase
set _manifest_path "$_outdir/pfm_uuid_manifest.dict"
set _manifest [open $_manifest_path w]
puts $_manifest [dict create logic_uuid $_logic_uuid interface_uuid $_interface_uuid]
close $_manifest
puts "Wrote: $_manifest_path"

# Enable USR_ACCESS timestamp in PDI (matches AVED flow)
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
