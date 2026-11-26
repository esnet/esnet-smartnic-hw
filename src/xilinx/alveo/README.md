# Common Alveo shell

`xilinx_alveo_shell` provides the top-level register decoder, DMA streaming
path, PCIe VPD service and JTAG reset/readiness control shared by Alveo
platforms.

## VPD

`xilinx_alveo_vpd` combines the VPD image builder and PCIe configuration
bridge for PF0 and PF1. Product/application identity and build metadata are
supplied as parameters. Per-function configuration registers are independent;
both PFs read the same image.

The shell exposes `pci_vpd_ctrl_intf` for the free-running clock/reset,
initialization mask and status, and `pci_vpd_card_info_intf` for card-info
cache accesses. The architecture drives the control interface's clock,
reset and mask; the VPD service drives its initialization status. The
card-info interface uses the same clock. PCIe reset independently flushes
configuration transactions.

Configuration remains explicit on modules: `NUM_PHYS_FUNC`,
`VPD_CLK_FREQ_HZ` (`CLK_FREQ_HZ` on `xilinx_alveo_vpd`) and `CARD_INFO_EN`.
The US+ and Versal shell layers supply these from their architecture
packages:

| Architecture | VPD clock | Physical functions | Card information |
|--------------|-----------|--------------------|------------------|
| US+ | 50 MHz | 2 | Enabled |
| Versal | 100 MHz | 2 | Disabled |

The interfaces contain no configuration parameters. Provider errors and
the initialization watchdog select static fallback VPD. `CARD_INFO_EN=0`
selects static-only operation without waiting for a provider.

Each architecture supplies its card-info stream. The US+ provider combines
static card attributes with cached CMS identity in its 50 MHz management
domain; see the [US+ VPD documentation](usplus/README.md#vpd-and-initialization-status).
Versal uses the 100 MHz system clock and disables card information. The
common shell drives JTAG readiness from VPD completion or error. PCIe reset
flushes configuration transactions while leaving the image and card
information intact.

`tests/xilinx_alveo_vpd_static` checks static metadata, checksum, per-PF
registers, unsupported functions and PCIe reset behavior. `NUM_FUNCS=1`,
`NUM_FUNCS=2` and `NUM_FUNCS=4` exercise function-count parameterization. The US+ CMS integration test checks the
provider path and fallback. `build/xilinx_alveo_vpd` provides an
out-of-context synthesis build with independent 100 MHz storage and
250 MHz configuration clocks.
