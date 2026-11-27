// PCIe VPD image construction and configuration-space access.
module xilinx_alveo_vpd
#(
    parameter int          CLK_FREQ_HZ         = xilinx_alveo_pkg::VPD_CLK_FREQ_HZ,
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
    xilinx_pci_cfg_ext_intf.peripheral cfg_ext_if,
    // Free-running initialization and software access
    input  logic                       clk,
    input  logic                       srst,
    input  logic                       cfg_srst, // Configuration reset, released on clk
    output logic                       ready,
    axi4l_intf.peripheral              axil_if,
    // Card information in the initialization clock domain
    pci_vpd_card_info_intf.consumer    card_info_if
);

    // =========================================================================
    // Signals and interfaces
    // =========================================================================
    pci_vpd_intf vpd_if (.clk(clk));
    axi4l_intf axil_regs ();
    xilinx_alveo_vpd_reg_intf reg_if ();
    logic init_done;
    logic init_error;
    logic init_timeout;
    logic init_early_read;
    logic [13:0] init_time_ms;

    // Keep readiness registered in the free-running clock domain.
    initial ready = 1'b0;
    always @(posedge clk) begin
        if (srst) ready <= 1'b0;
        else      ready <= init_done || init_error;
    end

    // =========================================================================
    // VPD registers; host reset clears controls independently of initialization
    // =========================================================================
    axi4l_intf_cdc i_axi4l_intf_cdc (
        .axi4l_if_from_controller ( axil_if ),
        .clk_to_peripheral        ( clk ),
        .axi4l_if_to_peripheral   ( axil_regs )
    );

    xilinx_alveo_vpd_reg_blk i_xilinx_alveo_vpd_reg_blk (
        .axil_if    ( axil_regs ),
        .reg_blk_if ( reg_if )
    );

    assign reg_if.status_nxt_v = 1'b1;
    assign reg_if.status_nxt = {14'b0, init_timeout, init_time_ms,
                               init_early_read, init_error, init_done};
    assign reg_if.card_info_nxt_v = 1'b1;
    assign reg_if.card_info_nxt = {21'b0, card_info_if.len,
                                  card_info_if.error, card_info_if.vld};

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
        .srst                 ( srst ),
        .init_done            ( init_done ),
        .init_error           ( init_error ),
        .init_timeout         ( init_timeout ),
        .init_early_read      ( init_early_read ),
        .init_time_ms         ( init_time_ms ),
        .init_done_mask       ( reg_if.control.init_done_mask ),
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
        .cfg_ext_if,
        .vpd_cfg_srst ( cfg_srst ),
        .vpd_srst     ( srst ),
        .vpd_if
    );

endmodule : xilinx_alveo_vpd
