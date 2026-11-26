// Card identity acquisition and PCIe VPD service in the free-running 50 MHz domain.
module xilinx_alveo_usplus_vpd
#(
    parameter              PRODUCT_ID          = "ESnet SmartNIC",
    parameter              APPLICATION_ID      = "(empty)",
    parameter logic [31:0] BUILD_ID            = 0,
    parameter              BUILD_GIT_REPO      = "(empty)",
    parameter              BUILD_GIT_HASH      = "(empty)",
    parameter              BUILD_TIMESTAMP_STR = "(empty)"
) (
    // Clock/reset
    input  logic                      clk,
    input  logic                      srst,
    // PCIe configuration access
    input  logic                      cfg_aresetn,
    xilinx_pci_cfg_ext_intf.peripheral cfg_ext_if,
    // CMS register access
    axi4l_intf.peripheral              cms_axil_from_controller,
    axi4l_intf.controller              cms_axil_to_peripheral,
    // Initialization control/status
    input  logic                      init_done_mask,
    output logic                      ready,
    output logic [31:0]               status
);

    // =========================================================================
    // Signals
    // =========================================================================
    logic        init_done;
    logic        init_error;
    logic        init_timeout;
    logic        init_early_read;
    logic [13:0] init_time_ms;

    logic        card_info_vld;
    logic        card_info_rd;
    logic        card_info_rd_vld;
    logic [7:0]  card_info_len;
    logic [7:0]  card_info_rd_addr;
    logic [7:0]  card_info_rd_data;

    logic        error_boot_timeout;
    logic        error_bad_axil_transaction;
    logic        error_card_info_length;

    // =========================================================================
    // Interfaces
    // =========================================================================
    pci_vpd_intf vpd_if (.clk(clk));

    // =========================================================================
    // Card information acquisition
    // =========================================================================
    xilinx_cms_cardinfo_fetch_fsm i_xilinx_cms_cardinfo_fetch_fsm (
        .cms_clk              ( clk ),
        .cms_srst             ( srst ),
        .abort                ( init_error || init_timeout ),
        .axil_from_controller ( cms_axil_from_controller ),
        .axil_to_cms          ( cms_axil_to_peripheral ),
        .card_info_vld,
        .card_info_len,
        .card_info_rd,
        .card_info_rd_addr,
        .card_info_rd_data,
        .card_info_rd_vld,
        .error_boot_timeout,
        .error_bad_axil_transaction,
        .error_card_info_length
    );

    // =========================================================================
    // VPD image construction
    // =========================================================================
    xilinx_pci_vpd #(
        .CLK_FREQ_HZ          ( 50_000_000 ),
        .PRODUCT_ID           ( PRODUCT_ID ),
        .APPLICATION_ID       ( APPLICATION_ID ),
        .BUILD_ID             ( BUILD_ID ),
        .BUILD_GIT_REPO       ( BUILD_GIT_REPO ),
        .BUILD_GIT_HASH       ( BUILD_GIT_HASH ),
        .BUILD_TIMESTAMP_STR  ( BUILD_TIMESTAMP_STR ),
        .FLASH_REG_OFFSET     ( 32'h00220000 ),
        .CMS_REG_OFFSET       ( 32'h00240000 )
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
        .card_info_error ( error_boot_timeout || error_bad_axil_transaction || error_card_info_length )
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

    // =========================================================================
    // Initialization status
    // =========================================================================
    assign ready = init_done || init_error;
    assign status = {
        2'b0,
        init_timeout,
        error_boot_timeout,
        error_bad_axil_transaction,
        error_card_info_length,
        card_info_len,
        card_info_vld,
        init_time_ms,
        init_early_read,
        init_error,
        init_done
    };

endmodule : xilinx_alveo_usplus_vpd
