// PCIe VPD image construction and configuration-space access.
module xilinx_alveo_vpd
#(
    parameter int          CLK_FREQ_HZ         = 50_000_000,
    parameter int          NUM_PHYS_FUNC       = 2,
    parameter bit          CARD_INFO_EN        = 1'b1,
    parameter              PRODUCT_ID          = "ESnet SmartNIC",
    parameter              APPLICATION_ID      = "(empty)",
    parameter logic [31:0] BUILD_ID            = 0,
    parameter              BUILD_GIT_REPO      = "(empty)",
    parameter              BUILD_GIT_HASH      = "(empty)",
    parameter              BUILD_TIMESTAMP_STR = "(empty)"
) (
    // PCIe configuration access
    input logic                        cfg_aresetn,
    xilinx_pci_cfg_ext_intf.peripheral cfg_ext_if,
    // Free-running initialization control/status and card information
    pci_vpd_ctrl_intf.peripheral       vpd_ctrl_if,
    pci_vpd_card_info_intf.consumer    card_info_if
);

    // =========================================================================
    // Signals and interfaces
    // =========================================================================
    pci_vpd_intf vpd_if (.clk(vpd_ctrl_if.clk));

    // =========================================================================
    // VPD image construction
    // =========================================================================
    xilinx_pci_vpd #(
        .CLK_FREQ_HZ          ( CLK_FREQ_HZ ),
        .CARD_INFO_EN         ( CARD_INFO_EN ),
        .PRODUCT_ID           ( PRODUCT_ID ),
        .APPLICATION_ID       ( APPLICATION_ID ),
        .BUILD_ID             ( BUILD_ID ),
        .BUILD_GIT_REPO       ( BUILD_GIT_REPO ),
        .BUILD_GIT_HASH       ( BUILD_GIT_HASH ),
        .BUILD_TIMESTAMP_STR  ( BUILD_TIMESTAMP_STR )
    ) i_xilinx_pci_vpd (
        .vpd_if,
        .srst                 ( vpd_ctrl_if.srst ),
        .init_done            ( vpd_ctrl_if.init_done ),
        .init_error           ( vpd_ctrl_if.init_error ),
        .init_timeout         ( vpd_ctrl_if.init_timeout ),
        .init_early_read      ( vpd_ctrl_if.init_early_read ),
        .init_time_ms         ( vpd_ctrl_if.init_time_ms ),
        .init_done_mask       ( vpd_ctrl_if.init_done_mask ),
        .card_info_vld        ( card_info_if.vld ),
        .card_info_len        ( card_info_if.len ),
        .card_info_rd         ( card_info_if.rd ),
        .card_info_rd_addr    ( card_info_if.rd_addr ),
        .card_info_rd_data    ( card_info_if.rd_data ),
        .card_info_rd_vld     ( card_info_if.rd_vld ),
        .card_info_error      ( card_info_if.error )
    );

    // =========================================================================
    // PCIe configuration bridge
    // =========================================================================
    xilinx_pci_cfg_ext_vpd #(
        .NUM_PHYS_FUNC ( NUM_PHYS_FUNC )
    ) i_xilinx_pci_cfg_ext_vpd (
        .aresetn  ( cfg_aresetn ),
        .cfg_ext_if,
        .vpd_srst ( vpd_ctrl_if.srst ),
        .vpd_if
    );

endmodule : xilinx_alveo_vpd
