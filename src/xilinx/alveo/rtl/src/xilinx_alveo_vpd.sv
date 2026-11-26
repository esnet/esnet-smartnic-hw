// PCIe VPD image construction and configuration-space access.
module xilinx_alveo_vpd
#(
    parameter int          CLK_FREQ_HZ         = 50_000_000,
    parameter bit          CARD_INFO_EN        = 1'b1,
    parameter logic [31:0] FLASH_REG_OFFSET    = '1,
    parameter logic [31:0] CMS_REG_OFFSET      = '1,
    parameter              PRODUCT_ID          = "ESnet SmartNIC",
    parameter              APPLICATION_ID      = "(empty)",
    parameter logic [31:0] BUILD_ID            = 0,
    parameter              BUILD_GIT_REPO      = "(empty)",
    parameter              BUILD_GIT_HASH      = "(empty)",
    parameter              BUILD_TIMESTAMP_STR = "(empty)"
) (
    // Clock/reset
    input  logic                       clk,
    input  logic                       srst,
    // PCIe configuration access
    input  logic                       cfg_aresetn,
    xilinx_pci_cfg_ext_intf.peripheral cfg_ext_if,
    // Card information provider (clk domain)
    input  logic                       card_info_vld,
    input  logic [7:0]                 card_info_len,
    output logic                       card_info_rd,
    output logic [7:0]                 card_info_rd_addr,
    input  logic [7:0]                 card_info_rd_data,
    input  logic                       card_info_rd_vld,
    input  logic                       card_info_error,
    // Initialization control/status (clk domain)
    input  logic                       init_done_mask,
    output logic                       init_done,
    output logic                       init_error,
    output logic                       init_timeout,
    output logic                       init_early_read,
    output logic [13:0]                init_time_ms
);

    // =========================================================================
    // Signals and interfaces
    // =========================================================================
    pci_vpd_intf vpd_if (.clk(clk));

    // =========================================================================
    // VPD image construction
    // =========================================================================
    xilinx_pci_vpd #(
        .CLK_FREQ_HZ          ( CLK_FREQ_HZ ),
        .CARD_INFO_EN         ( CARD_INFO_EN ),
        .FLASH_REG_OFFSET     ( FLASH_REG_OFFSET ),
        .CMS_REG_OFFSET       ( CMS_REG_OFFSET ),
        .PRODUCT_ID           ( PRODUCT_ID ),
        .APPLICATION_ID       ( APPLICATION_ID ),
        .BUILD_ID             ( BUILD_ID ),
        .BUILD_GIT_REPO       ( BUILD_GIT_REPO ),
        .BUILD_GIT_HASH       ( BUILD_GIT_HASH ),
        .BUILD_TIMESTAMP_STR  ( BUILD_TIMESTAMP_STR )
    ) i_xilinx_pci_vpd (
        .vpd_if,
        .srst,
        .init_done,
        .init_error,
        .init_timeout,
        .init_early_read,
        .init_time_ms,
        .init_done_mask,
        .card_info_vld,
        .card_info_len,
        .card_info_rd,
        .card_info_rd_addr,
        .card_info_rd_data,
        .card_info_rd_vld,
        .card_info_error
    );

    // =========================================================================
    // PCIe configuration bridge
    // =========================================================================
    xilinx_pci_cfg_ext_vpd #(
        .NUM_PHYS_FUNC ( 2 )
    ) i_xilinx_pci_cfg_ext_vpd (
        .aresetn  ( cfg_aresetn ),
        .cfg_ext_if,
        .vpd_srst ( srst ),
        .vpd_if
    );

endmodule : xilinx_alveo_vpd
