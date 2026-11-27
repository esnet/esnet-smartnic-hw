# JTAG reset control

`xilinx_jtag_reset_ctrl` combines an active-low hardware reset with an
active-high VIO reset override. It uses the free-running debug clock and
the board's generated `xilinx_jtag_reset_vio` IP.

The incoming reset is synchronized before combination because it can
originate in another fabric clock domain. A second reset synchronizer
registers release of the combined reset. Both use the common `sync_areset`
component, preserving asynchronous assertion even when the debug clock is
stopped. With three stages per synchronizer, hardware reset release takes
six debug-clock edges; releasing only the VIO override takes three once
hardware reset synchronization has completed.

The three VIO status inputs report hardware reset, outgoing reset and
readiness. Hardware reset status is sampled after input normalization,
independently of the VIO override. The status signals are synchronized for
observation; short status pulses can be missed, and readiness does not
control reset.

Run `make -C tests/xilinx_jtag_reset_ctrl/` for behavioral checks, including
stopped-clock assertion, release latency, source overlap and short pulses.
The standard OOC build at `build/xilinx_jtag_reset_ctrl/` uses the generated
VIO IP and checks both external and fabric-generated resets. Its optimized
CDC report must recognize the incoming fabric reset synchronizer without
critical reset crossings; both three-stage reset pipelines must survive
optimization.
