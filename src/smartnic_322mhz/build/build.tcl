proc main {} {
    global env
    # -----------------------------------------------
    # Defines
    # -----------------------------------------------
    set lib_root $env(LIB_ROOT)
    set app_root $env(APP_ROOT)
    set out_dir  $env(OUT_DIR)
    set part     xcu280-fsvh2892-2L-e
    set top      smartnic_322mhz

    # -----------------------------------------------
    # Vivado synthesis flow
    # -----------------------------------------------
    # Set board/part
    set_part $part
    set_property board_part xilinx.com:au280:part0:1.1 [current_project]

    # Design sources
    source read_reg_sources.tcl
    source read_core_sources.tcl

    # Import app netlist
    read_checkpoint -cell smartnic_322mhz_app $app_root/app_if/smartnic_322mhz_app.dcp

    # Read timing constraints
    read_xdc -unmanaged synth_timing_ooc.xdc
    
    # Synthesize top level
    synth_design -top $top -mode out_of_context

    # Read timing constraints
    read_xdc -unmanaged opt_timing_ooc.xdc
    read_xdc -unmanaged $lib_root/src/sync/build/sync.xdc

    opt_design

    # Checkpoint
    write_checkpoint -force $out_dir/synth

    # Generate reports
    report_timing -max_paths 1000 -file $out_dir/$top.timing.synth.rpt
    report_timing_summary -file $out_dir/$top.timing.summary.synth.rpt
    report_utilization -file $out_dir/$top.utilization.synth.rpt
    report_utilization -hierarchical -file $out_dir/$top.utilization.hier.synth.rpt
    report_design_analysis -logic_level_distribution -file $out_dir/$top.logic_levels.synth.rpt

    save_project $top -force $out_dir

    exit 0
}

if {[catch {main} msg options]} {
    puts stderr "unexpected script error: $msg"
    if {[info exist env(DEBUG)]} {
        puts stderr "---- BEGIN TRACE ----"
        puts stderr [dict get $options -errorinfo]
        puts stderr "---- END TRACE ----"
    }

    # Reserve code 1 for "expected" error exits...
    exit 2
}
