# Usage: vivado -mode batch -source write_bitstream.tcl -tclargs \
#            <routed-checkpoint> <output-prefix> <build-id>
if {$argc != 3} {
    error "Expected routed checkpoint, output prefix, and build ID"
}
lassign $argv checkpoint output_prefix build_id

open_checkpoint $checkpoint
set_property BITSTREAM.CONFIG.USERID $build_id [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS $build_id [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

write_bitstream -force -bin_file ${output_prefix}.bit
write_debug_probes -force ${output_prefix}.ltx
