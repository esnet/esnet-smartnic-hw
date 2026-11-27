# Validation-only waiver; load with read_xdc -ref xilinx_alveo_usplus_qdma.
# The GT Wizard CPLL calibration frequency counter disables test-clock counting
# and waits in HOLD_STATE before capturing the result in the reference domain.
# The generated PCIe GT XDC explicitly false-paths this 18-bit transfer.
# Cover only the TXOUTCLK calibration result, not QDMA queues, payload or reset
# crossings. This file adds no timing exceptions and changes no IP behavior.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {QDMA GT Wizard vendor-excepted held CPLL calibration frequency result} \
    -from [get_pins -hierarchical -filter {NAME =~ *U_TXOUTCLK_FREQ_COUNTER/testclk_cnt_reg*/C}] \
    -to [get_pins -hierarchical -filter {NAME =~ *U_TXOUTCLK_FREQ_COUNTER/freq_cnt_o_reg*/D}]
