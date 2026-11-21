# AVED block design integration

`xilinx_aved.tcl` imports and configures the AVED block design for the native
Versal shell, including the CPM5 PCIe application endpoint.

## CPM5 dedicated GT coverage waiver

The V80 [validation policy](../../../../../cfg/validation/av80.json) accepts
one specific `unconstrained_internal_endpoints` section from `check_timing`:
112 GTYP control pins reported under constant clocks, with zero ordinary
unconstrained maximum-delay endpoints. The scope is seven pin families on
four channels in each of the four quads under
`top_i/cips/inst/cpm_0/inst/gt_quad_inst[0-3]/inst/quad_inst`:

- `CH[0-3]_PHYESMADAPTSAVE`
- `CH[0-3]_RXDLYALIGNREQ`
- `CH[0-3]_RXMLDCHAINDONE`
- `CH[0-3]_RXMLDCHAINREQ`
- `CH[0-3]_RXPHALIGNREQ`
- `CH[0-3]_RXPHSETINITREQ`
- `CH[0-3]_RXPHSHIFT180`

These are direct connections from the CPM hard primitive, not tied-off
signals or application RTL. AMD documents that the four CPM5 GTYP quads
have [dedicated connectivity](https://docs.amd.com/r/en-US/pg346-cpm-pcie/GT-Selection-and-Pin-Planning-for-CPM5)
and cannot be bypassed to programmable logic. The generated CPM5 vendor
constraints, `ip_cpm5.xdc`, explicitly apply `set_case_analysis 0` to
`gt_quad_inst?/inst/quad_inst/CH?_?XUSRCLK` (and the latency clocks).

In the reviewed Vivado 2025.1 routed netlist, all 112 endpoints are driven
by `CPM_INST`: 16 have setup/hold checks against `TXUSRCLK`, and 96 against
`RXUSRCLK`. All 224 checks are already disabled by the vendor constant-clock
analysis. Reasserting the vendor clock case analysis leaves the coverage
finding and routed timing unchanged. The exception accepts reporting of
these dedicated hard-block connections; it does not establish that the
signals are inactive in hardware.

The JSON waiver changes validation accounting only. It adds no clocks,
case analysis, false paths, or timing-arc disables. It requires the complete
112-entry constant-clock section, the reviewed hierarchy/pin families,
and zero ordinary unconstrained endpoints. Additional endpoints, different
pin families, other GT instances, and ordinary unconstrained paths remain
unwaived, as do the separate DCMAC clock-coverage findings.

Revisit this exception when updating the CIPS/CPM IP, the CPM GT topology,
or the vendor timing constraints. The rationale relies on AMD's dedicated
CPM-to-GT integration contract; it is not an independent hardware timing
proof. Full original coverage reports remain available in validation outputs.
