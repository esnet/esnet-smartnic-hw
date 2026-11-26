// =============================================================================
// xilinx_alveo_shell
//
// Common platform module for Alveo cards (UltraScale+ and Versal).
// Instantiated once per top-level design to collect functionality that is
// shared across all Alveo platform variants.
// =============================================================================
module xilinx_alveo_shell
#(
    parameter int          QID_WID             = 11, // DMA queue identifier width
    parameter int          MAX_PKT_LEN         = 9100, // DMA FIFO maximum packet length (bytes)
    parameter int          VPD_CLK_FREQ_HZ     = 50_000_000,
    parameter bit          CARD_INFO_EN        = 1'b1,
    parameter              PRODUCT_ID          = "ESnet SmartNIC",
    parameter              APPLICATION_ID      = "(empty)",
    parameter logic [31:0] BUILD_ID            = 0,
    parameter              BUILD_GIT_REPO      = "(empty)",
    parameter              BUILD_GIT_HASH      = "(empty)",
    parameter              BUILD_TIMESTAMP_STR = "(empty)"
) (
    input  wire logic sys_clk_100mhz,     // Free-running debug clock for VIO

    // VPD storage and card information provider, independent of PCIe reset
    input  logic                       vpd_clk,
    input  logic                       vpd_srst,
    xilinx_pci_cfg_ext_intf.peripheral cfg_ext_if,
    input  logic                       card_info_vld,
    input  logic [8:0]                 card_info_len,
    output logic                       card_info_rd,
    output logic [8:0]                 card_info_rd_addr,
    input  logic [7:0]                 card_info_rd_data,
    input  logic                       card_info_rd_vld,
    input  logic                       card_info_error,
    input  logic                       vpd_init_done_mask,
    output logic                       vpd_init_done,
    output logic                       vpd_init_error,
    output logic                       vpd_init_timeout,
    output logic                       vpd_init_early_read,
    output logic [13:0]                vpd_init_time_ms,

    input  wire logic pci_rstn_in,        // Raw incoming reset (active-low)

    output wire logic pci_rstn_out,       // Reset output (active-low, JTAG-overridable)

    // Core clock and synchronous reset, supplied by the platform shell which
    // owns the clock source.  The DMA streams are handed to the core in this
    // domain; the crossing from the QDMA clock happens here, in
    // xilinx_alveo_qdma_st.
    input  wire logic core_clk,
    input  wire logic core_srst,

    // QDMA clock and reset — the domain of the dma_* packet interfaces below.
    // Passed explicitly rather than taken from packet_intf.clk so the domain
    // is visible in the port list.
    input  wire logic dma_aclk,
    input  wire logic dma_aresetn,

    axi4l_intf.peripheral axil_top,     // AXI-L interface from PCIe core
    axi4l_intf.controller axil_hw,      // AXI-L interface to hardware (shell) components
    axi4l_intf.controller axil_core,    // AXI-L interface to core
    axi4l_intf.peripheral axil_qdma_st, // DMA streaming registers, decoded per platform

    // -----------------------------------------------------------------------
    // DMA streams, QDMA clock domain — toward the platform's QDMA adapter
    // -----------------------------------------------------------------------
    packet_intf.rx pkt_h2c_dma,  // H2C: from the adapter; META_WID = PKT_H2C_META_WID
    packet_intf.tx pkt_c2h_dma,  // C2H: to the adapter;   META_WID = PKT_C2H_META_WID

    // -----------------------------------------------------------------------
    // DMA streams, core clock domain — shell-typed axi4s toward the core
    // -----------------------------------------------------------------------
    axi4s_intf.tx axis_h2c,  // H2C: drives toward core
    axi4s_intf.rx axis_c2h   // C2H: receives from core
);

    // =========================================================================
    // VPD service
    // =========================================================================
    xilinx_alveo_vpd #(
        .CLK_FREQ_HZ          ( VPD_CLK_FREQ_HZ ),
        .CARD_INFO_EN         ( CARD_INFO_EN ),
        .PRODUCT_ID           ( PRODUCT_ID ),
        .APPLICATION_ID       ( APPLICATION_ID ),
        .BUILD_ID             ( BUILD_ID ),
        .BUILD_GIT_REPO       ( BUILD_GIT_REPO ),
        .BUILD_GIT_HASH       ( BUILD_GIT_HASH ),
        .BUILD_TIMESTAMP_STR  ( BUILD_TIMESTAMP_STR )
    ) i_xilinx_alveo_vpd (
        .clk                  ( vpd_clk ),
        .srst                 ( vpd_srst ),
        .cfg_aresetn          ( dma_aresetn ),
        .cfg_ext_if,
        .card_info_vld,
        .card_info_len,
        .card_info_rd,
        .card_info_rd_addr,
        .card_info_rd_data,
        .card_info_rd_vld,
        .card_info_error,
        .init_done_mask       ( vpd_init_done_mask ),
        .init_done            ( vpd_init_done ),
        .init_error           ( vpd_init_error ),
        .init_timeout         ( vpd_init_timeout ),
        .init_early_read      ( vpd_init_early_read ),
        .init_time_ms         ( vpd_init_time_ms )
    );

    // =========================================================================
    // PCIe reset control
    //
    // Exposes a JTAG VIO (on sys_clk_100mhz) that allows the reset to be
    // independently asserted or released per endpoint without a board power
    // cycle. Reset asserts asynchronously and releases on sys_clk_100mhz.
    // VIO probes: in0=raw reset, in1=output reset, in2=ready;
    //             out0=jtag_reset (active-high override).
    // =========================================================================
    xilinx_jtag_reset_ctrl i_xilinx_jtag_reset_ctrl (
        .debug_clk ( sys_clk_100mhz ),
        .ready     ( vpd_init_done || vpd_init_error ),
        .rstn_in   ( pci_rstn_in    ),
        .rstn_out  ( pci_rstn_out   )
    );

    // =========================================================================
    // Top-level decoder
    //
    // Splits the incoming AXI-L interface into shell_cfg, hw, and core
    // sub-spaces.  The address map is defined in
    // src/shell/regio/shell_decoder.yaml.
    // =========================================================================
    axi4l_intf #() axil_shell_cfg ();

    shell_decoder i_shell_decoder (
        .axil_if           ( axil_top       ),
        .shell_cfg_axil_if ( axil_shell_cfg ),
        .hw_axil_if        ( axil_hw        ),
        .core_axil_if      ( axil_core      )
    );

    // =========================================================================
    // Shell config register block
    //
    // id is a fixed RO constant; tie off update inputs so it holds INIT_VALUE.
    // =========================================================================
    shell_cfg_reg_intf shell_cfg_reg_if ();

    assign shell_cfg_reg_if.id_nxt_v = 1'b0;
    assign shell_cfg_reg_if.id_nxt   = '0;

    shell_cfg_reg_blk i_shell_cfg_reg_blk (
        .axil_if     ( axil_shell_cfg  ),
        .reg_blk_if  ( shell_cfg_reg_if )
    );

    // =========================================================================
    // DMA streaming datapath
    //
    // Owns the QDMA-clock to core-clock crossing, the loopback switch and the
    // DMA counters.  Placing it here keeps the clock domain boundary in the
    // shell: the platform adapter below stays entirely in the QDMA domain, and
    // the platform shell above receives the streams already in the core domain.
    //
    // =========================================================================
    xilinx_alveo_qdma_st #(
        .QID_WID     ( QID_WID     ),
        .MAX_PKT_LEN ( MAX_PKT_LEN )
    ) i_xilinx_alveo_qdma_st (
        .aclk             ( dma_aclk         ),
        .aresetn          ( dma_aresetn      ),
        .core_clk         ( core_clk         ),
        .core_srst        ( core_srst        ),
        .axil_if          ( axil_qdma_st     ),
        .pkt_h2c_dma      ( pkt_h2c_dma ),
        .pkt_c2h_dma      ( pkt_c2h_dma ),
        .axis_h2c         ( axis_h2c   ),
        .axis_c2h         ( axis_c2h         )
    );

endmodule : xilinx_alveo_shell
