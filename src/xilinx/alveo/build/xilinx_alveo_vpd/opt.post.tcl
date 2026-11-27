# One configuration-domain reset must enter the free-running domain once.
set stages [get_cells -hier -filter {NAME =~ i_sync_areset__cfg/__sync_ff_reset_n_reg*}]
if {[llength $stages] != 3} {error "Expected one three-stage shared configuration reset synchronizer"}
foreach stage $stages {
    if {![get_property ASYNC_REG $stage]} {error "Missing ASYNC_REG: $stage"}
}
set first [get_pins {i_sync_areset__cfg/__sync_ff_reset_n_reg[0]/CLR}]
set drivers [get_pins -leaf -of_objects [get_nets -of_objects $first] -filter {DIRECTION == OUT}]
if {[llength $drivers] != 1 || [get_property NAME $drivers] ne "cfg_resetn_reg/Q"} {
    error "Unexpected logic before shared reset synchronization: $drivers"
}
set last [get_pins {i_sync_areset__cfg/__sync_ff_reset_n_reg[2]/Q}]
set consumers [get_property NAME [all_fanout -flat -endpoints_only -from $last]]
foreach pattern {
    */i_xilinx_pci_cfg_ext_vpd/data_srst_reg/D
    i_xilinx_jtag_reset_ctrl/i_sync_areset__rstn_out/__sync_ff_reset_n_reg*/CLR
} {
    if {![llength [lsearch -all -glob $consumers $pattern]]} {
        error "Shared reset does not reach expected consumer $pattern: $consumers"
    }
}

report_cdc -details -all_checks_per_endpoint -file vpd_reset_cdc.rpt
set unsafe [get_cdc_violations -quiet -filter {CHECK == CDC-10 || CHECK == CDC-11}]
if {[llength $unsafe]} {error "Unexpected combinational or duplicated reset crossing: $unsafe"}
set incoming [get_cdc_violations -quiet -filter {CHECK == CDC-9 && ENDPOINT_PIN =~ i_sync_areset__cfg/*}]
if {[llength $incoming] != 1 || [get_property EXCEPTION $incoming] ne "False Path"} {
    error "Expected a recognized, excepted asynchronous reset crossing at the shared boundary"
}
puts "PASS: VPD and JTAG share one normalized reset release without CDC-10 or CDC-11"
