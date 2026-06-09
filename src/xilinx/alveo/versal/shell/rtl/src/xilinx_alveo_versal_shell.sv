// =========================================================================
// xilinx_alveo_versal_shell
//
// Versal-specific Alveo shell layer.  Sits between the AVED block design
// (via xilinx_aved_adapter) and the platform-agnostic ESnet shell-core
// boundary (shell_intf).
//
// Responsibilities:
//   - Instantiate xilinx_alveo for common Alveo platform functionality
//     (PCIe reset control with JTAG VIO override)
//   - Adapt the management AXI4-Lite interface to the shell-core boundary
//   - Terminate network port and DMA streaming interfaces pending
//     DCMAC and QDMA subsystem implementation
// =========================================================================
module xilinx_alveo_versal_shell
    import shell_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // System clock — sourced from the PMC crystal oscillator via the CRP.
    // Independent of PCIe, HBM, and PS state; available immediately after
    // device power-on.  Used as the free-running clock for the JTAG VIO.
    input  wire logic       sys_clk,

    // PCIe interface clock
    input  wire logic       pcie_clk,

    // PCIe reset — pre-JTAG synthesis input (active-low, all sources ANDed)
    input  wire logic       pcie_rstn_in,

    // PCIe reset — post-JTAG synthesis output (active-low)
    output wire logic       pcie_rstn,

    // Management AXI4-Lite from xilinx_aved_adapter
    axi4l_intf.peripheral   axil_if,

    // To/from application core — standard ESnet shell-core boundary
    shell_intf.shell        shell_if
);

    // =========================================================================
    // Common Alveo platform — PCIe reset control with JTAG VIO override
    // =========================================================================
    xilinx_alveo i_xilinx_alveo (
        .sys_clk_100mhz ( sys_clk      ),
        .pci_clk        ( pcie_clk     ),
        .pci_rstn_in    ( pcie_rstn_in ),
        .pci_rstn_out   ( pcie_rstn    )
    );

    // =========================================================================
    // Clock/reset — derived from the AXI4-Lite clock/reset
    // =========================================================================
    assign shell_if.clk        = axil_if.aclk;
    assign shell_if.srst       = ~axil_if.aresetn;
    assign shell_if.mgmt_clk   = axil_if.aclk;
    assign shell_if.mgmt_srst  = ~axil_if.aresetn;
    assign shell_if.clk_100mhz = axil_if.aclk;  // placeholder until 100 MHz export added

    // =========================================================================
    // Network port interfaces (CMAC) — terminated pending DCMAC wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID           ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID          ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID          )
    ) axis_port_rx [shell_if.NUM_PORTS] (.aclk(axil_if.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID           ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID          ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID          )
    ) axis_port_tx [shell_if.NUM_PORTS] (.aclk(axil_if.aclk));

    generate
        for (genvar g_port = 0; g_port < shell_if.NUM_PORTS; g_port++) begin : g__port
            axi4s_intf_tx_term i_axi4s_intf_tx_term__port_rx (
                .to_rx ( axis_port_rx[g_port] )
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__port_tx (
                .from_tx ( axis_port_tx[g_port] )
            );
        end : g__port
    endgenerate

    // =========================================================================
    // DMA streaming interfaces — terminated pending QDMA subsystem
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID           ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID          ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID          )
    ) axis_h2c (.aclk(axil_if.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID           ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID          ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID          )
    ) axis_c2h (.aclk(axil_if.aclk));

    axi4s_intf_tx_term i_axi4s_intf_tx_term__h2c (.to_rx   (axis_h2c));
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__c2h (.from_tx (axis_c2h));

    // =========================================================================
    // Convert SV interfaces to flat shell_intf representation
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (
        .shell_if,
        .axil_if,
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

endmodule : xilinx_alveo_versal_shell
