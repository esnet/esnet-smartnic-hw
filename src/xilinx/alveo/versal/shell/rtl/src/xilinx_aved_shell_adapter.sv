// =========================================================================
// Xilinx AVED shell adapter
//
//   Adapts the management AXI4-Lite interface produced by xilinx_aved_adapter
//   to the ESnet standard shell-core boundary (shell_intf).
//
//   Mirrors the port signature of xilinx_alveo_shell so that the same
//   core module can be instantiated on both Alveo and AVED platforms.
//
//   NOTE: CMAC and DMA data paths are not yet connected.  All network
//   and host-DMA signals are terminated here as placeholders until the
//   AVED block design exposes those interfaces (Phase 5).
//
// =========================================================================
module xilinx_aved_shell_adapter
    import shell_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // Management AXI4-Lite from AVED adapter (aclk/aresetn carry clock/reset)
    axi4l_intf.peripheral axil_if,

    // To/from core (application) — identical boundary to xilinx_alveo_shell
    shell_intf.shell shell_if
);
    // =========================================================================
    // Clock/reset — derived from the AXI4-Lite clock/reset
    // =========================================================================
    assign shell_if.clk        = axil_if.aclk;
    assign shell_if.srst       = ~axil_if.aresetn;
    assign shell_if.mgmt_clk   = axil_if.aclk;
    assign shell_if.mgmt_srst  = ~axil_if.aresetn;
    assign shell_if.clk_100mhz = axil_if.aclk;  // placeholder until 100MHz export added

    // =========================================================================
    // Network port interfaces (CMAC) — terminated pending AVED DCMAC wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID  ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID )
    ) axis_port_rx [shell_if.NUM_PORTS] (.aclk(axil_if.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID  ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID )
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
    // DMA streaming interfaces — terminated pending AVED DMA wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) axis_h2c (.aclk(axil_if.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
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

endmodule : xilinx_aved_shell_adapter
