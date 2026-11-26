# Common Alveo shell

`xilinx_alveo_shell` provides the top-level register decoder, DMA streaming
path, PCIe VPD service and JTAG reset/readiness control shared by Alveo
platforms.

## VPD

`xilinx_alveo_vpd` owns the VPD image builder, PCIe configuration bridge,
software register block, AXI-Lite clock crossing and registered readiness
output. Product/application identity and build metadata are supplied as
parameters. Per-function configuration registers are independent; all
supported PFs read the same image.

The Alveo shell decoder connects its dedicated `vpd_axil_if` to this service.
Initialization clock/reset and card information are supplied separately;
initialization status and mask signals remain internal to the VPD block.

VPD runs from the free-running 100 MHz system clock on both US+ and Versal.
The common shell generates a registered startup reset. The VPD service
registers initialization readiness in the same domain. PCIe reset flushes
configuration transactions but does not rebuild the image or restart
card-info acquisition.

`NUM_PHYS_FUNC`, `VPD_CLK_FREQ_HZ` (`CLK_FREQ_HZ` on `xilinx_alveo_vpd`) and
`CARD_INFO_EN` remain module parameters. The Alveo layers supply the frequency
from `xilinx_alveo_pkg` and the function count/provider enablement from their
architecture packages. Both architectures enable two physical functions.

The architecture supplies `pci_vpd_card_info_intf` in its provider clock domain.
`pci_vpd_card_info_intf_cdc` transfers coherent cache status and byte reads into
the 100 MHz VPD domain. US+ supplies cached CMS identity and static card
attributes at 50 MHz. Versal disables card information and serves static
metadata. Providers own acquisition timeouts, cleanup and resource release;
the VPD watchdog selects static fallback independently if a provider does
not respond. There is no consumer cancellation signal.

## Registers

The Alveo VPD register block occupies BAR2 + `0x1000` on both architectures:

| Offset | Register | Contents |
|--------|----------|----------|
| `0x1000` | `control` | Bit 0 masks completion and selects static VPD reads |
| `0x1004` | `status` | Completion, error, early read, elapsed milliseconds and timeout |
| `0x1008` | `card_info` | Provider valid/error and nine-bit cache length |

AXI-Lite accesses cross into the VPD clock domain. Host reset clears software
control registers independently of VPD initialization. Readiness is asserted
on initialization completion or error. Provider errors and the six-second
watchdog select static fallback without card-specific records.

## Verification

`tests/xilinx_alveo_vpd_static` checks static metadata, checksum, per-PF
registers, unsupported functions, AXI-Lite controls and PCIe reset. The
Versal adapter suite checks the VPD registers through the PCIe AXI adapter,
top-level decoder and register clock crossing.
`NUM_FUNCS=1`, `2` and `4` exercise function-count parameterization.
The US+ management suite covers CMS acquisition, cross-clock cache reads,
fallback and host access. `build/xilinx_alveo_vpd` provides an out-of-context
synthesis build with independent 100 MHz VPD and 250 MHz configuration clocks.
