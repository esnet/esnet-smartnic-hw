# Both the input and combined output reset must retain three ASYNC_REG stages.
foreach instance {fabric_reset external_reset} {
    foreach boundary {rstn_in rstn_out} {
        set registers [get_cells -hier -filter "NAME =~ $instance/i_sync_areset__$boundary/__sync_ff_reset_n_reg*"]
        if {[llength $registers] != 3} {error "Missing reset synchronizer stages in $instance/$boundary"}
        foreach cell $registers {
            if {![get_property ASYNC_REG $cell]} {error "Missing ASYNC_REG: $cell"}
        }
    }
}

# The fabric reset must directly drive the first reset synchronizer's clear;
# combining it with VIO before this boundary reintroduces the CDC-10 finding.
set first [get_pins {fabric_reset/i_sync_areset__rstn_in/__sync_ff_reset_n_reg[0]/CLR}]
set drivers [get_pins -leaf -of_objects [get_nets -of_objects $first] -filter {DIRECTION == OUT}]
if {[llength $drivers] != 1 || [get_property NAME $drivers] ne "fabric_resetn_reg/Q"} {
    error "Unexpected logic before incoming-reset synchronization: $drivers"
}

report_cdc -details -all_checks_per_endpoint -file reset_cdc.rpt
set reset_crossings [get_cdc_violations -quiet -filter {ENDPOINT_PIN =~ */i_sync_areset__rstn_in/* || ENDPOINT_PIN =~ */i_sync_areset__rstn_out/*}]
foreach crossing $reset_crossings {
    if {[get_property SEVERITY $crossing] eq "Critical"} {error "Unsafe reset crossing: $crossing"}
}
set incoming [get_cdc_violations -quiet -filter {CHECK == CDC-9 && ENDPOINT_PIN =~ fabric_reset/i_sync_areset__rstn_in/*}]
if {[llength $incoming] != 1 || [get_property EXCEPTION $incoming] ne "False Path"} {
    error "Expected a recognized, excepted asynchronous reset crossing at the input boundary"
}
puts "PASS: fabric reset synchronized before VIO combination; both reset pipelines retained without critical CDC findings"
