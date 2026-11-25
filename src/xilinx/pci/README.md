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

These tests currently use the ONS VPD image builder and the CMS model to check
the bridge against the existing VPD format. They also exercise byte enables,
function isolation, unsupported functions and reset recovery.
