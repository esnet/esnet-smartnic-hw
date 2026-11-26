# Versal Alveo RTL

`xilinx_aved_adapter` converts the AVED application endpoint's AXI, DMA and
configuration-extension signals into the shell interfaces.

The common shell's `xilinx_alveo_vpd` serves a read-only VPD image on
PCIE0 PF0 and PF1.
The image contains the product, application and build metadata, including
the build ID, Git repository/hash and UTC timestamp. It runs from the
free-running 100 MHz system clock and initializes independently of PCIe
reset. PCIe reset clears pending configuration transactions while preserving the
image. Completion drives the shell's JTAG
initialization-ready indication.

Card identity records are not included. The flash and CMS register offsets
are `0xffffffff`, indicating that these interfaces are not exposed through
the application's BAR2 register map.

The native V80 build generates `shell_build_info.svh` from the build
identity. `SHELL_VPD_*` variables provide metadata overrides; unchanged
build identities preserve the generated timestamp and source contents.

## Verification

The common Alveo `tests/xilinx_alveo_vpd_static` simulation checks the static
metadata, checksum, both PFs, independent function registers and PCIe reset
behavior.
The `tests/xilinx_aved_adapter` simulation also checks that wider CPM5
function numbers cannot alias PF0 or PF1 through the adapter.

The common Alveo `build/xilinx_alveo_vpd` provides an out-of-context synthesis build
with 100 MHz storage and 250 MHz configuration clocks.
