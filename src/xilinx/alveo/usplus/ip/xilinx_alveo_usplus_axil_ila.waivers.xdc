# Validation-only CDC-1 waivers scoped to xilinx_alveo_usplus_axil_ila (ILA 6.2).
# ila_v6_2/constraints/ila.xdc explicitly false-paths the arm transfer to
# advanced-trigger state enables and U_SCRST to trigger-counter enables.
# ila_impl.xdc false-paths trigger-memory data to counters and trigger flags.
# These vendor-managed control/configuration paths are not recognized by
# report_cdc. Load with read_xdc -ref so each instance is scoped separately;
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
