// =========================================================================
// xilinx_alveo_usplus_shell
//
//   Implements ESnet standard shell on UltraScale+ Alveo architecture.
//
//   Supports a variety of hardware implementations (Alveo boards) using
//   the abstract xilinx_alveo_usplus_hw_intf connection to the physical layer.
//
//   Supports a variety of 'core' implementations (applications) using
//   the abstract shell_intf connection to user logic.
//
//   Uses the common xilinx_alveo_shell module for JTAG reset control,
//   the top-level hw/core AXI-L decoder, and the DMA datapath.
//
// =========================================================================
module xilinx_alveo_usplus_shell
    import shell_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0,
    parameter PRODUCT_ID = "ESnet SmartNIC",
    parameter APPLICATION_ID = "(empty)",
    parameter logic [31:0] BUILD_ID = 0,
    parameter BUILD_GIT_REPO = "(empty)",
    parameter BUILD_GIT_HASH = "(empty)",
    parameter BUILD_TIMESTAMP_STR = "(empty)"
) (
    // To/from physical layer (hardware)
    xilinx_alveo_usplus_hw_intf.alveo alveo_hw_if,
    // To/from core (application)
    shell_intf.shell shell_if
);

    // =========================================================================
    // Interfaces
    // =========================================================================

    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_hw ();
    axi4l_intf #() axil_core ();

    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_rx [shell_if.NUM_PORTS] (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_tx [shell_if.NUM_PORTS] (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(shell_if.DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(shell_if.DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_usplus_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_rx [xilinx_alveo_usplus_pkg::NUM_CMAC] (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_usplus_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_usplus_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_tx [xilinx_alveo_usplus_pkg::NUM_CMAC] (.aclk(shell_if.clk));

    // =========================================================================
    // Signals
    // =========================================================================
    logic pci_rstn;
    logic dma_aclk;
    logic dma_aresetn;

    logic clk;
    logic srst;
    logic clk_100mhz;
    logic clk_125mhz;
    logic clk_250mhz;
    logic clk_333mhz;

    logic card_info_clk;
    pci_vpd_card_info_intf card_info_if (.clk(card_info_clk));
    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(dma_aclk));

    // =========================================================================
    // Shell adaptation layer
    // (maps shell_intf signals to/from axi4l_intf / axi4s_intf)
    // axil_core carries the post-decoded core AXI-L (from xilinx_alveo_shell)
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (
        .shell_if,
        .clk,
        .srst,
        .mgmt_clk   ( axil_core.aclk    ),
        .mgmt_srst  ( !axil_core.aresetn ),
        .clk_100mhz,
        .port_clk   ( '{default: clk}  ),
        .port_srst  ( '{default: srst} ),
        .axil_if    ( axil_core ),
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // Common Alveo shell — JTAG reset control and top-level hw/core decoder
    // =========================================================================
    axi4l_intf axil_qdma_st ();
    packet_intf #(
        .DATA_BYTE_WID ( xilinx_qdma_pkg::AXIS_DATA_BYTE_WID ),
        .META_WID ( xilinx_qdma_pkg::PKT_H2C_META_WID )
    ) pkt_h2c_dma (.clk(dma_aclk));
    packet_intf #(
        .DATA_BYTE_WID ( xilinx_qdma_pkg::AXIS_DATA_BYTE_WID ),
        .META_WID ( xilinx_qdma_pkg::PKT_C2H_META_WID )
    ) pkt_c2h_dma (.clk(dma_aclk));

    xilinx_alveo_shell #(
        .QID_WID              ( xilinx_alveo_usplus_pkg::DMA_ST_QID_WID ),
        .NUM_PHYS_FUNC        ( xilinx_alveo_usplus_pkg::NUM_PHYS_FUNC ),
        .VPD_CLK_FREQ_HZ      ( xilinx_alveo_pkg::VPD_CLK_FREQ_HZ ),
        .CARD_INFO_EN         ( xilinx_alveo_usplus_pkg::CARD_INFO_EN ),
        .PRODUCT_ID           ( PRODUCT_ID ),
        .APPLICATION_ID       ( APPLICATION_ID ),
        .BUILD_ID             ( BUILD_ID ),
        .BUILD_GIT_REPO       ( BUILD_GIT_REPO ),
        .BUILD_GIT_HASH       ( BUILD_GIT_HASH ),
        .BUILD_TIMESTAMP_STR  ( BUILD_TIMESTAMP_STR )
    ) i_xilinx_alveo_shell (
        .sys_clk_100mhz ( alveo_hw_if.sys_clk_100mhz ),
        .card_info_if,
        .cfg_ext_if,
        .pci_rstn_in    ( alveo_hw_if.pcie_rstn ),
        .pci_rstn_out   ( pci_rstn ),
        .core_clk       ( clk  ),
        .core_srst      ( srst ),
        .dma_aclk       ( dma_aclk ),
        .dma_aresetn    ( dma_aresetn ),
        .axil_top,
        .axil_hw,
        .axil_core,
        .axil_qdma_st,
        .pkt_h2c_dma,
        .pkt_c2h_dma,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // UltraScale+ Alveo core — CMAC, QDMA, clocking, hw register decode
    // axil_top drives the PCIe AXI-L into the QDMA; axil_hw receives the
    // decoded hw sub-space from the top-level Alveo shell decoder.
    // =========================================================================
    xilinx_alveo_usplus #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_usplus  (
        .alveo_hw_if,
        .pci_rstn,
        .card_info_clk,
        .card_info_if,
        .cfg_ext_if,
        .clk,
        .srst,
        .clk_100mhz,
        .clk_125mhz,
        .clk_250mhz,
        .clk_333mhz,
        .axis_cmac_rx ( __axis_cmac_rx ),
        .axis_cmac_tx ( __axis_cmac_tx ),
        .dma_aclk,
        .dma_aresetn,
        .pkt_h2c_dma,
        .pkt_c2h_dma,
        .axil_qdma_st,
        .axil_top,
        .axil_hw
    );

    // =========================================================================
    // Map between shell and Alveo
    // =========================================================================
    generate
        for (genvar g_port = 0; g_port < shell_if.NUM_PORTS; g_port++) begin : g__port
            // Port (Rx)
            shell_pkg::port_axis_tid_t   axis_port_rx_tid;
            shell_pkg::port_axis_tdest_t axis_port_rx_tdest;
            shell_pkg::port_axis_tuser_t axis_port_rx_tuser;

            xilinx_alveo_usplus_pkg::cmac_axis_tid_t   __axis_cmac_rx_tid;
            xilinx_alveo_usplus_pkg::cmac_axis_tdest_t __axis_cmac_rx_tdest;
            xilinx_alveo_usplus_pkg::cmac_axis_tuser_t __axis_cmac_rx_tuser;

            assign __axis_cmac_rx_tid           = __axis_cmac_rx[g_port].tid;
            assign axis_port_rx_tid.unused      = 1'b0;

            assign __axis_cmac_rx_tdest         = __axis_cmac_rx[g_port].tdest;
            assign axis_port_rx_tdest.unused    = 1'b0;

            assign __axis_cmac_rx_tuser         = __axis_cmac_rx[g_port].tuser;
            assign axis_port_rx_tuser.err       = __axis_cmac_rx_tuser.err;

            axi4s_intf_set_meta #(
                .TID_WID    ( shell_pkg::PORT_AXIS_TID_WID ),
                .TDEST_WID  ( shell_pkg::PORT_AXIS_TDEST_WID ),
                .TUSER_WID  ( shell_pkg::PORT_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__port_rx (
                .from_tx ( __axis_cmac_rx[g_port] ),
                .to_rx   ( axis_port_rx[g_port] ),
                .tid     ( axis_port_rx_tid ),
                .tdest   ( axis_port_rx_tdest ),
                .tuser   ( axis_port_rx_tuser )
            );

            // Port (Tx)
            xilinx_alveo_usplus_pkg::cmac_axis_tid_t   __axis_cmac_tx_tid;
            xilinx_alveo_usplus_pkg::cmac_axis_tdest_t __axis_cmac_tx_tdest;
            xilinx_alveo_usplus_pkg::cmac_axis_tuser_t __axis_cmac_tx_tuser;

            shell_pkg::port_axis_tid_t   axis_port_tx_tid;
            shell_pkg::port_axis_tdest_t axis_port_tx_tdest;
            shell_pkg::port_axis_tuser_t axis_port_tx_tuser;

            assign axis_port_tx_tid               = axis_port_tx[g_port].tid;
            assign __axis_cmac_tx_tid.unused      = 1'b0;

            assign axis_port_tx_tdest             = axis_port_tx[g_port].tdest;
            assign __axis_cmac_tx_tdest.unused    = 1'b0;

            assign axis_port_tx_tuser             = axis_port_tx[g_port].tuser;
            assign __axis_cmac_tx_tuser.err       = axis_port_tx_tuser.err;

            axi4s_intf_set_meta #(
                .TID_WID    ( xilinx_alveo_usplus_pkg::CMAC_AXIS_TID_WID ),
                .TDEST_WID  ( xilinx_alveo_usplus_pkg::CMAC_AXIS_TDEST_WID ),
                .TUSER_WID  ( xilinx_alveo_usplus_pkg::CMAC_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__port_tx (
                .from_tx ( axis_port_tx[g_port] ),
                .to_rx   ( __axis_cmac_tx[g_port] ),
                .tid     ( __axis_cmac_tx_tid ),
                .tdest   ( __axis_cmac_tx_tdest ),
                .tuser   ( __axis_cmac_tx_tuser )
            );

        end : g__port
    endgenerate

endmodule : xilinx_alveo_usplus_shell
