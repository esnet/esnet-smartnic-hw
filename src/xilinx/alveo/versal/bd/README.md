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

## DDR4 clock ownership during BD synthesis

Each DDR4 controller's generated `*_ip.xdc` defines its 200 MHz input clock.
Vivado 2025.1 also emits the same input clocks in `xilinx_aved_ooc.xdc`,
producing `Constraints 18-1056` in standalone BD synthesis. The duplication
also occurs with Vivado's native `create_ip_run` OOC flow, without the
library's manual synthesis-run setup or automatic reference constraints.

The component registers `xilinx_aved.synth.setup.tcl` using the library's
optional `BD_SYNTH_SETUP_TCL` setting. The manager sources it in the BD
project after generating products and before launching synthesis. This is
a project-configuration step: Vivado's run `TCL.PRE` hook is too early,
before the run has added its source files.

The setup checks that both DDR4 IP XDCs are enabled for synthesis and define
the same periods as the two generated boundary defaults. It writes a local
filtered OOC XDC omitting only those two defaults, disables the original BD
OOC file, and registers the filtered file for OOC processing with the same
processing order. Every other generated line, including the HBM and PCIe
clock definitions, is retained. Vendor files and DDR4 IP constraints are
not modified. Unrecognized or missing clock definitions fail the setup.

The setup is idempotent, so repeating an unchanged preparation does not
rewrite its output. Its source timestamp is a synthesis dependency.
Like other project configuration, file-property changes persist in the
managed BD project; explicitly undo them or recreate that project if the
setup is removed. This configuration does not change how the parent shell
imports the BD or its IP constraints.

The CI IP-preparation job still explicitly refreshes the BD for each build
ID. `BUILD_ID` is exported as `BITSTREAM_USERID`, and `xilinx_aved.tcl` embeds
it as CIPS `JTAG_USERCODE`. A different ID changes the BD and requires fresh
synthesis. The unchanged-output checks apply only when the generated BD
and its synthesis setup are unchanged; they do not permit reuse across
JTAG USERCODE changes.
