# Common Alveo shell

`xilinx_alveo_shell` provides the top-level register decoder, DMA streaming
path, PCIe VPD service and JTAG reset/readiness control shared by Alveo
platforms.

## VPD

`xilinx_alveo_vpd` combines the VPD image builder and PCIe configuration
bridge for PF0 and PF1. Product/application identity and build metadata are
supplied as parameters. Per-function configuration registers are independent;
both PFs read the same image.

The architecture supplies a free-running `vpd_clk` and startup reset,
independent of PCIe reset. All `card_info_*` signals and initialization
control/status use this clock. The provider reports the card-info length
and validity, then returns a byte and read-valid for each requested address.
Provider errors and the initialization watchdog select static fallback VPD.
`CARD_INFO_EN=0` selects static-only operation without waiting for a provider.

Each architecture supplies its card-info stream. The US+ provider combines
static card attributes with cached CMS identity in its 50 MHz management
domain; see the [US+ VPD documentation](usplus/README.md#vpd-and-initialization-status).
Versal uses the 100 MHz system clock and disables card information. The
common shell drives JTAG readiness from VPD completion or error. PCIe reset
flushes configuration transactions while leaving the image and card
information intact.

`tests/xilinx_alveo_vpd_static` checks static metadata, checksum, per-PF
registers and PCIe reset behavior. The US+ CMS integration test checks the
provider path and fallback. `build/xilinx_alveo_vpd` provides an
out-of-context synthesis build with independent 100 MHz storage and
250 MHz configuration clocks.
