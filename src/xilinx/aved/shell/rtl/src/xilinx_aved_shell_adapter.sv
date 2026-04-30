// =========================================================================
// Xilinx AVED shell adapter
//
//   Adapts Xilinx AVED application interface to the ESnet standard
//   shell-core boundary (flat packed struct representation).
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
    // To/from hardware top-level (AVED)
    xilinx_aved_app_intf.app app_if,

    // To/from core (application) — identical boundary to xilinx_alveo_shell
    output wire logic clk,
    output wire logic srst,
    output wire logic mgmt_clk,
    output wire logic mgmt_srst,
    output wire logic clk_100mhz,
    output wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    input  wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell
);
    // =========================================================================
    // Clock/reset
    // =========================================================================
    assign clk       = app_if.clk;
    assign srst      = app_if.srst;
    assign mgmt_clk  = app_if.clk;
    assign mgmt_srst = app_if.srst;
    assign clk_100mhz = app_if.clk;  // placeholder until 100MHz export added

    // =========================================================================
    // AXI-L
    // =========================================================================
    axi4l_intf axil_if ();

    axi4l_intf_connector i_axil_connector (
        .axi4l_if_from_controller ( app_if.axil_if ),
        .axi4l_if_to_peripheral   ( axil_if )
    );

    // =========================================================================
    // Network port interfaces (CMAC) — terminated pending AVED DCMAC wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_WID       ( CMAC_AXIS_TID_WID  ),
        .TDEST_WID     ( CMAC_AXIS_TDEST_WID ),
        .TUSER_WID     ( CMAC_AXIS_TUSER_WID )
    ) axis_cmac_rx [NUM_CMAC] (.aclk(clk));

    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_WID       ( CMAC_AXIS_TID_WID  ),
        .TDEST_WID     ( CMAC_AXIS_TDEST_WID ),
        .TUSER_WID     ( CMAC_AXIS_TUSER_WID )
    ) axis_cmac_tx [NUM_CMAC] (.aclk(clk));

    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac_rx (
                .to_rx ( axis_cmac_rx[g_cmac] )
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac_tx (
                .from_tx ( axis_cmac_tx[g_cmac] )
            );
        end : g__cmac
    endgenerate

    // =========================================================================
    // DMA streaming interfaces — terminated pending AVED DMA wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) axis_h2c (.aclk(clk));

    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) axis_c2h (.aclk(clk));

    axi4s_intf_tx_term i_axi4s_intf_tx_term__h2c (.to_rx   (axis_h2c));
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__c2h (.from_tx (axis_c2h));

    // =========================================================================
    // Convert SV interfaces to flat shell-core packed struct representation
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (.*);

endmodule : xilinx_aved_shell_adapter

