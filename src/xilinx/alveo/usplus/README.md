# UltraScale+ Alveo management

SYSMON uses the free-running 100 MHz board clock and its own library
AXI-Lite CDC from the 125 MHz register bus, including reset synchronization.
Its divide-by-20 setting produces a 5 MHz ADC clock. The register window
starts at BAR2 + `0x210000` and spans 8 KiB, matching the IP address width;
addresses above this window are not forwarded to SYSMON.

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

## AXI-Lite ILA CDC waivers

[The ILA waiver file](ip/xilinx_alveo_usplus_axil_ila.waivers.xdc) is
registered through `VALIDATION_WAIVER_REFS` in
`scripts/Makefiles/shell_proj_config.mk` for the
`xilinx_alveo_usplus_axil_ila` reference. Vivado applies
it relative to each instance, including references uniquified during
synthesis, without depending on shell hierarchy or instance names.

It covers three internal path families:

- Capture-control reset or trigger-memory configuration to counter enables.
- Arm handshake to advanced-trigger state enables.
- Trigger-memory configuration to advanced-trigger flags.

The generated vendor files `ila_v6_2/constraints/ila.xdc` and `ila_impl.xdc`
explicitly false-path these transfers. Reapplying the vendor implementation
constraints after optimization leaves the CDC-1 findings unchanged. The
additional validation waivers match these reviewed source/destination pin
families, separately for each instance of this IP reference, and apply only
to CDC-1. They exclude probe inputs, paths crossing the IP boundary, other
IP references, and other CDC rules.

These waivers load only when collecting validation reports. They add no
timing exceptions and do not change the saved checkpoint. Review the
waiver coverage when changing the ILA IP version or configuration; these
waivers accept vendor-managed CDC behavior and are not an independent proof
of CDC safety. Waived paths and unused waivers are retained in the native
validation reports.
