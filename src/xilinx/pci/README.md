# Xilinx PCIe support

`xilinx_pci_cfg_ext_vpd` implements the VPD capability at configuration-space
byte offset `0xb0`, with independent address, flag and data registers for each
physical function. `CFG_EXT_NXT_CAP` supplies the next capability pointer.
Unsupported function numbers read as zero and writes are ignored. The PCIe IP
must be configured to route the legacy configuration window to this component;
the bridge does not enable the capability in the IP configuration itself.

The configuration side uses `xilinx_pci_cfg_ext_intf` and active-low `aresetn`.
The byte-wide storage side uses `pci_vpd_intf` and active-high `vpd_srst`.
Requests are arbitrated between physical functions and cross clock domains
through common-library asynchronous FIFOs. The storage peripheral must return
one `rd_vld` response per byte read. Writes have no storage response; persistence
and write protection are properties of the storage peripheral.

Either reset flushes both FIFOs and resets the configuration state, with reset
deassertion synchronized in each domain. Reset aborts in-flight operations;
the controller must restart them after reset. Storage initialization is managed
separately by the storage peripheral.

Run the integration tests with:

```sh
make -C src/xilinx/pci/tests/xilinx_pci_vpd_cfg_ext
```

Run the same tests against the ONS bridge with:

```sh
make -C src/xilinx/pci/tests/xilinx_pci_vpd_cfg_ext ONS_VPD=1
```

The default tests use `xilinx_pci_vpd` and the CMS model. `ONS_VPD=1` selects
both the ONS bridge and image builder. The suites exercise byte enables,
function isolation, unsupported functions, burst writes, concurrent reads
and reset recovery.

## VPD image construction

`xilinx_pci_vpd` serves a shared, read-only image through `pci_vpd_intf` in
that interface's clock domain. The image contains the product ID resource,
build records (`VA`, `VB`, `VR`, `VH`, `VT`), flash/CMS register offsets
(`VF`, `VC`), optional card name (`PN`),
serial number (`SN`), controller version (`RM`), checksum (`RV`) and end tag.
The shell supplies metadata and its register offsets through parameters.
External writes are ignored; out-of-range byte reads return `0xff`.

`CLK_FREQ_HZ` must match the interface clock and be a positive multiple of
1000 Hz (default 50 MHz). Both elapsed initialization time and the watchdog
use this frequency in synthesis and simulation.

With `CARD_INFO_EN=1` (the default), initialization consumes the CMS-format
card-info byte stream. `card_info_vld` indicates that the supplied length and
buffer are available; each `card_info_rd` requests one byte and requires a
`card_info_rd_vld` response. A valid static image is available while fetching
or parsing that buffer. Successful construction publishes the completed image
and asserts `init_done`.

`card_info_error`, malformed/oversized data, or expiry of
`CARD_INFO_TIMEOUT_MS` terminates initialization with `init_error` and retains
the static image. The watchdog bounds the complete initialization, including
missing byte responses, and also asserts sticky `init_timeout` on expiry.
The default is 6000 ms; supported values are 1 through 16383 ms. Completion
and error are terminal until `srst`, so late provider results cannot replace
the selected image. A host reading across successful initialization should
wait for readiness first or retry if its checksum check fails, since the
static-to-complete transition can occur between byte accesses.

Set `CARD_INFO_EN=0` for static-only operation, including a shell without a
board-identity provider. Initialization completes with `init_done`; provider
inputs are ignored and no card-info requests are issued. Tie the unused
provider inputs low. `init_done_mask` masks completion and forces static
reads after dynamic initialization. It does not restart initialization.
`init_early_read` records reads before initialization reaches a terminal state.

Run the image and initialization suites with:

```sh
make -C src/xilinx/pci/tests/xilinx_pci_vpd
make -C src/xilinx/pci/tests/xilinx_pci_vpd_init
```
