# Validation-only CDC waivers scoped to xilinx_alveo_usplus_axil_ila (ILA 6.2).
# ila_v6_2/constraints/ila.xdc explicitly false-paths the arm transfer to
# advanced-trigger state enables and U_SCRST to trigger-counter enables.
# ila_impl.xdc false-paths trigger-memory data to counters and trigger flags.
# These vendor-managed control/configuration/status protocols are not proved
# safe by report_cdc. Load with read_xdc -ref to scope each instance separately;
# restrict both endpoints and the rule. Probe inputs and other CDCs remain
# subject to validation. This file adds no timing exceptions or RTL changes.

# Capture-control/configuration to advanced-trigger counter enables.
create_waiver -scoped -type CDC -id CDC-1 -user esnet \
    -description {ILA vendor-excepted capture-control and trigger-memory transfers to counter enables} \
    -from [get_pins -hierarchical -filter { \
        NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCRST/I_YESLUT6.U_SRL32*/CLK || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/fsm_mem_data_reg*/RAM*/CLK \
    }] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/COUNTER.u_count/G_COUNTER*.U_COUNTER/counter_reg*/CE}]

# Arm handshake to advanced-trigger state enables.
create_waiver -scoped -type CDC -id CDC-1 -user esnet \
    -description {ILA vendor-excepted arm handshake to advanced-trigger state enables} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_out_transfer_inst/dout_reg1_reg/C}] \
    -to [get_pins -hierarchical -filter { \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/cntcmpsel_reg*/CE || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/current_state_reg*/CE || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/trigger_reg/CE || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/CAPTURE_O_reg/CE || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/SEQUENCER_STATE_O_reg*/CE \
    }]

# Trigger-memory configuration to advanced-trigger flags.
create_waiver -scoped -type CDC -id CDC-1 -user esnet \
    -description {ILA vendor-excepted trigger-memory configuration to advanced-trigger flags} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/fsm_mem_data_reg*/RAM*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/FLAG*_O_reg/D}]

# Vendor configuration transfers; ila.xdc false-paths both two-stage buses.
create_waiver -scoped -type CDC -id CDC-6 -user esnet \
    -description {ILA vendor-excepted debug configuration bus transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_stream_ffd/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/debug_data_in_sync1_reg*/D}]

create_waiver -scoped -type CDC -id CDC-6 -user esnet \
    -description {ILA vendor-excepted capture-address configuration bus transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/*.cfg_data_vec_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/cfg_data_vec_sync1_reg*/D}]

# CDC-15 families below are explicitly excepted by ila.xdc/ila_impl.xdc.
# These are vendor control/configuration and status-readback protocols, not
# user probe-data crossings. Keep source and destination families paired.

# Trigger-memory programming to advanced-trigger state/counter data.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted trigger-memory configuration to sequencer state data} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/fsm_mem_data_reg*/RAM*/CLK}] \
    -to [get_pins -hierarchical -filter { \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/current_state_reg*/D || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/cntcmpsel_reg*/D || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/trigger_reg/D || \
        NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/CAPTURE_O_reg/D || \
        NAME =~ *ila_core_inst/COUNTER.u_count/G_COUNTER*.U_COUNTER/counter_reg*/D \
    }]

# Counter-load configuration to counter data (ila.xdc). These registered
# sources may be absent before routing; quiet makes that case a no-op.
create_waiver -quiet -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted counter-load configuration transfer} \
    -from [get_pins -quiet -hierarchical -filter {NAME =~ *ila_core_inst/COUNTER.u_count/G_COUNTER*.U_COUNTER/counter_load_i_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/COUNTER.u_count/G_COUNTER*.U_COUNTER/counter_reg*/D}]

# Arm handshake to advanced-trigger state resets and capture/trigger data.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted arm transfer to sequencer resets and capture/trigger state} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_out_transfer_inst/dout_reg1_reg/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/current_state_reg*/R || NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/cntcmpsel_reg*/R || NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/SEQUENCER_STATE_O_reg*/R || NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/CAPTURE_O_reg/D || NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/trigger_reg/D}]

# Sample-counter reset configuration to counter data and local resets.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted sample-counter reset transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCRST/I_YESLUT6.U_SRL32*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/COUNTER.u_count/G_COUNTER*.U_COUNTER/counter_reg*/D || NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/iscnt_reg*/R}]

# Comparator reset configuration to sample/window comparator result resets.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted comparator reset transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/U_CMPRESET/I_YESLUT6.U_SRL32*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q/R || NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q/R || NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q/R}]

# Programmed u_scnt_cmp comparison to its sampled result.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted u_scnt_cmp match configuration transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX*.U_ALL_SRL_SLICE/u_srl*/S*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q/D}]

# Programmed u_wcnt_lcmp comparison to its sampled result.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted u_wcnt_lcmp match configuration transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX*.U_ALL_SRL_SLICE/u_srl*/S*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q/D}]

# Programmed u_wcnt_hcmp comparison to its sampled result.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted u_wcnt_hcmp match configuration transfer} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX*.U_ALL_SRL_SLICE/u_srl*/S*/CLK}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q/D}]

# Captured-sample status readback.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted captured-sample status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/captured_samples_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_9/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]

# Advanced-trigger enable and sequencer-state status readback.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted advanced-trigger and sequencer status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/en_adv_trigger_reg/C || NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/SEQUENCER_STATE_O_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_88f/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]

# Advanced-trigger flag status readback.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted trigger-flag status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/ADV_TRIG.u_adv_trig/FLAG*_O_reg/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_892/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]

# Advanced-trigger enable readback through the flag-status register.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted advanced-trigger enable status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/en_adv_trigger_reg/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_892/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]

# Capture completion and trigger status readback.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted capture/trigger status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/CAP_DONE_O_reg/C || NAME =~ *ila_core_inst/u_ila_cap_ctrl/CAP_TRIGGER_O_reg/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_8/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]

# Latched capture-configuration status readback.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {ILA vendor-excepted latched capture-configuration status readback} \
    -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_cap_ctrl/U_NS*/I_YESLUT6.I_YES_OREG.O_reg_reg/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_ila_regs/reg_88d/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg*/D}]
