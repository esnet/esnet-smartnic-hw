# UltraScale+ Alveo management

SYSMON uses the free-running 100 MHz board clock and its own library
AXI-Lite CDC from the 125 MHz register bus, including reset synchronization.
Its divide-by-20 setting produces a 5 MHz ADC clock. The register window
starts at BAR2 + `0x210000` and spans 8 KiB, matching the IP address width;
addresses above this window are not forwarded to SYSMON. Only on-chip
sensors are enabled; the wrapper has no external VP/VN analog inputs.

`xilinx_alveo_usplus_cms` connects the board-specific CMS Subsystem 4.0 IP,
`xilinx_usplus_cms_subsystem`, to a 32-bit AXI-Lite interface and the card's
satellite UART/GPIO. The IP selects its bundled MicroBlaze firmware from
the target FPGA device: U55C, U280, or U200/U250.

The common US+ module shares a free-running 50 MHz clock between CMS and
QSPI. Each peripheral has its own library AXI-Lite CDC from the shell's
125 MHz register bus, including reset synchronization. The CMS interface
presented to the board module is already in the 50 MHz domain. Host
software uses polling; the CMS watchdog interrupt is not routed to PCIe.

The CMS window starts at BAR2 + `0x240000` and spans 256 KiB. The MicroBlaze
is held in reset until software starts it. A minimal startup sequence is:

1. Write `1` to `MB_RESETN_REG`, CMS offset `0x20000` (BAR2 + `0x260000`).
2. Wait for `REG_MAP_ID_REG`, CMS offset `0x28000`, to become `0x74736574`.
3. Wait for bit 0 of `HOST_STATUS2_REG`, CMS offset `0x2830c`, to become `1`.

See [PG348: Register Space](https://docs.amd.com/r/en-US/pg348-cms-subsystem/Register-Space)
for the firmware register map. Automatic card-information fetching and PCIe
VPD are separate functions; neither is instantiated in this path.

U55C and U280 expose the CMS HBM-monitor inputs. These inputs are tied to
zero until HBM controllers supply temperature and trip information; leave
HBM temperature monitoring disabled in software. The external HBM_CATTRIP
output retains its existing drive-low connection.

On U250, CMS owns the two QSFP management interfaces. Its native reset
defaults release module reset, disable low-power mode, and assert both
active-low module selects. Satellite GPIO and UART, and the U250 QSFP
inputs, use the native subsystem's input synchronization. The internal
`XILINX_USPLUS_CMS_QSFP_IO` build define selects the U250 port binding;
the RTL component has no configuration parameters.

The IP simulation build exports a flattened functional model from the
synthesized checkpoint, including the firmware-initialized memories.
This avoids dependencies on generated block-design names and tests the
native hardware without the card-information fetch FSM or its model.

PCIe reset is buffered by the board wrappers, which also constrain its
package pin. QDMA therefore uses a custom reset board interface and receives
the buffered logic signal.

## AXI-Lite ILA CDC waivers

[The ILA waiver file](ip/xilinx_alveo_usplus_axil_ila.waivers.xdc) is
registered through `VALIDATION_WAIVER_REFS` in
`scripts/Makefiles/shell_proj_config.mk` for the
`xilinx_alveo_usplus_axil_ila` reference. Vivado applies
it relative to each instance, including references uniquified during
synthesis, without depending on shell hierarchy or instance names.

Its CDC-1 waivers cover three internal path families:

- Capture-control reset or trigger-memory configuration to counter enables.
- Arm handshake to advanced-trigger state enables.
- Trigger-memory configuration to advanced-trigger flags.

The generated vendor files `ila_v6_2/constraints/ila.xdc` and `ila_impl.xdc`
explicitly false-path these transfers. Reapplying the vendor implementation
constraints after optimization leaves the CDC-1 findings unchanged. The
additional validation waivers match these reviewed source/destination pin
families separately for each instance of this IP reference. Additional
CDC-6 waivers cover the vendor-excepted debug-data and capture-address
configuration buses, each with two destination synchronizer stages. These
waivers exclude probe inputs, paths crossing the IP boundary, other IP
references, and other CDC rules.

CDC-15 waivers additionally cover vendor-excepted trigger-memory state
data, counter-load configuration, arm-handshake resets and capture/trigger
state, sample-counter and comparator configuration, and status readback
into the XSDB registers.
The status families are captured-sample counts, advanced-trigger enable
and sequencer state, trigger flags, capture/trigger status, and latched
capture configuration. Each waiver pairs reviewed source and destination
families within one ILA instance. The generated `ila.xdc` and
`ila_impl.xdc` explicitly except these transfers; the paths remain reported
by `report_cdc` despite their active timing exceptions.

A CDC-10 waiver covers the internal trigger-match calibration transfer from
`u_trig/N_DDR_TC.N_DDR_TC_INST*.U_TC/.../DUT/u_srl_drive/CLK` to
`I_WHOLE_SLICE.G_SLICE_IDX*.U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg/D`
under the same trigger-match circuitry. This variant was observed in the
routed U280 125 MHz ILA and has an active false-path exception. Vendor
`ila.xdc` contains a commented CDC-10 waiver matching this hierarchy variant;
the reason it is disabled is unknown, so its presence is supporting context,
not vendor approval. The additional waiver records acceptance of this
vendor-managed calibration path and is limited to CDC-10 and these internal
endpoint families. Probe inputs and other synchronizers remain checked.

These waivers load only when collecting validation reports. They add no
timing exceptions and do not change the saved checkpoint. Review the
waiver coverage when changing the ILA IP version or configuration; these
waivers accept vendor-managed CDC behavior and are not an independent proof
of CDC safety. Waived paths and unused waivers are retained in the native
validation reports.

## QDMA calibration CDC waiver

[The QDMA waiver file](ip/xilinx_alveo_usplus_qdma.waivers.xdc) is scoped to
the generated `xilinx_alveo_usplus_qdma` IP reference. It covers only the
CDC-15 transfer from `U_TXOUTCLK_FREQ_COUNTER/testclk_cnt_reg` to
`freq_cnt_o_reg` inside the PCIe GT Wizard's CPLL calibration logic.

In the reviewed QDMA 5.1 / GT Wizard 1.7.22 implementation, the counter
enable is synchronized into the measured-clock domain. The reference-domain
FSM stops the measurement, waits in `HOLD_STATE` until its hold count reaches
15, then captures the frequency result in `UPDATE_STATE`. The generated
`*_pcie4c_ip_gt.xdc` explicitly false-paths this held-result transfer. The
waiver excludes other GT controls, resets, QDMA queues, and packet data.
Review the protocol and generated exceptions again when changing IP version
or configuration.

## Debug-hub FIFO CDC waiver

[The debug-hub waiver file](ip/dbg_hub.waivers.xdc) is scoped to Vivado's
automatically inserted `dbg_hub` reference. The reviewed XSDB 3.0.5 hub
uses FIFO Generator 13.1.5 for its command read/write FIFOs. Their
dual-clock RAM payloads are protected by the vendor FIFO pointer protocol;
the affected RAM write-clock to output-register paths already have active
false-path exceptions in the checkpoint.

The CDC-15 waiver covers only the `U_CMD6_RD/U_RD_FIFO` and
`U_CMD6_WR/U_WR_FIFO` distributed RAM to `gpr1.dout_i_reg` transfers.
It excludes FIFO controls, other debug-hub logic, and application FIFOs.
The QDMA and debug-hub waivers are registered only for native UltraScale+
validation and, like the ILA waivers, do not change RTL or timing exceptions.
Reassess their endpoint coverage when changing Vivado or IP versions.
These waivers accept the vendor CDC contracts; they are not independent
proofs of the internal protocols.

## FIFO pointer CDC waivers

Native shell validation also registers the common library's
`src/sync/build/sync_ctr/waivers.xdc` for the `sync_ctr` reference. The FIFO
controllers increment their binary pointers by one per accepted operation;
`sync_ctr` registers their Gray encoding before the three-stage destination
synchronizer. The component-owned CDC-6 waiver covers only that transfer.
It does not waive arbitrary changing buses passing through `sync_meta`.
Source-period max-delay and minimum-clock-period bus-skew constraints still
bound the physical crossing. Both FIFO domains must be initialized before
use, and reset flushes the FIFO through its coordinated reset handling.
